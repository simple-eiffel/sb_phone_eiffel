note
	description: "[
		org.json.JSONTokener, as Android has it, with all its leniency: comments, single quotes,
		unquoted strings, = and => for :, ; for a comma, a value left out of an array.

		Java works in UTF-16 units and its messages count them, so the input is held here as one
		code per unit (`in'), and strings are put back together when they leave.
	]"
	author: "Larry Rix"

class
	SB_JSON_TOKENER

inherit
	SB_FAILURE

create
	make

feature {NONE} -- Initialization

	make (a_text: READABLE_STRING_32)
			-- Read `a_text', without a byte order mark at its start.
		local
			i: INTEGER
			l_code: NATURAL_32
		do
			create in.make (a_text.count)
			from
				i := 1
				if not a_text.is_empty and then a_text.code (1) = 0xFEFF then
					i := 2
				end
			until
				i > a_text.count
			loop
				l_code := a_text.code (i)
				if l_code > 0xFFFF then
					in.append_code (0xD800 + ((l_code - 0x10000) |>> 10))
					in.append_code (0xDC00 + ((l_code - 0x10000) & 0x3FF))
				else
					in.append_code (l_code)
				end
				i := i + 1
			end
		end

feature -- Reading

	root_object: SB_JSON_OBJECT
			-- new JSONObject (text).
		local
			l_value: SB_JSON_VALUE
			l_message: STRING_32
		do
			l_value := next_value
			if attached {SB_JSON_OBJECT} l_value as al_object then
				Result := al_object
			else
				create l_message.make (64)
				l_message.append_string_general ("Value ")
				if attached l_value.java_text as al_text then
					l_message.append (al_text)
				else
					l_message.append_string_general ("null")
				end
				l_message.append_string_general (" of type " + l_value.class_name + " cannot be converted to JSONObject")
				fail (l_message)
				create Result.make
			end
		end

	next_value: SB_JSON_VALUE
			-- JSONTokener.nextValue.
		local
			c: INTEGER
		do
			c := next_clean
			if c = -1 then
				syntax_error ({STRING_32} "End of input")
				create {SB_JSON_NULL} Result
			elseif c = 0x7B then
				Result := read_object
			elseif c = 0x5B then
				Result := read_array
			elseif c = 0x27 or c = 0x22 then
				create {SB_JSON_STRING} Result.make (next_string (c.to_natural_32))
			else
				pos := pos - 1
				Result := read_literal
			end
		end

feature {NONE} -- Implementation

	in: STRING_32
			-- The input, one code per UTF-16 unit.

	pos: INTEGER
			-- How many units have been read.

	numbers: SB_JAVA_NUMBERS
			-- Java's number rules.
		once
			create Result
		end

	unit (a_index: INTEGER): NATURAL_32
			-- in.charAt (a_index), from 0.
		do
			Result := in.code (a_index + 1)
		end

	from_units (a_units: READABLE_STRING_32): STRING_32
			-- `a_units' with each surrogate pair made one character again.
		local
			i: INTEGER
			c, d: NATURAL_32
		do
			create Result.make (a_units.count)
			from
				i := 1
			until
				i > a_units.count
			loop
				c := a_units.code (i)
				if c >= 0xD800 and c <= 0xDBFF and i < a_units.count then
					d := a_units.code (i + 1)
					if d >= 0xDC00 and d <= 0xDFFF then
						Result.append_code (0x10000 + ((c - 0xD800) |<< 10) + (d - 0xDC00))
						i := i + 1
					else
						Result.append_code (c)
					end
				else
					Result.append_code (c)
				end
				i := i + 1
			end
		end

	syntax_error (a_message: READABLE_STRING_32)
			-- JSONTokener.syntaxError.
		local
			l_message: STRING_32
		do
			create l_message.make (a_message.count + in.count + 32)
			l_message.append (a_message)
			l_message.append_string_general (" at character " + pos.out + " of ")
			l_message.append (from_units (in))
			fail (l_message)
		end

	next_clean: INTEGER
			-- JSONTokener.nextCleanInternal: the next unit that counts, -1 at the end.
		local
			c: INTEGER
			l_peek: NATURAL_32
			l_found: BOOLEAN
			l_end: INTEGER
		do
			Result := -1
			from
			until
				l_found or else pos >= in.count
			loop
				c := unit (pos).to_integer_32
				pos := pos + 1
				if c = 0x09 or c = 0x20 or c = 0x0A or c = 0x0D then
					-- Skipped.
				elseif c = 0x2F then
					if pos = in.count then
						Result := c
						l_found := True
					else
						l_peek := unit (pos)
						if l_peek = 0x2A then
							pos := pos + 1
							l_end := in.substring_index ({STRING_32} "*/", pos + 1)
							if l_end = 0 then
								syntax_error ({STRING_32} "Unterminated comment")
							end
							pos := l_end - 1 + 2
						elseif l_peek = 0x2F then
							pos := pos + 1
							skip_to_end_of_line
						else
							Result := c
							l_found := True
						end
					end
				elseif c = 0x23 then
					skip_to_end_of_line
				else
					Result := c
					l_found := True
				end
			end
		end

	skip_to_end_of_line
			-- JSONTokener.skipToEndOfLine.
		local
			c: NATURAL_32
			l_done: BOOLEAN
		do
			from
			until
				l_done or else pos >= in.count
			loop
				c := unit (pos)
				if c = 0x0D or c = 0x0A then
					l_done := True
				end
				pos := pos + 1
			end
		end

	next_string (a_quote: NATURAL_32): STRING_32
			-- JSONTokener.nextString.
		local
			l_units: STRING_32
			l_start: INTEGER
			c: NATURAL_32
			l_done: BOOLEAN
		do
			create l_units.make (32)
			from
				l_start := pos
			until
				l_done or else pos >= in.count
			loop
				c := unit (pos)
				pos := pos + 1
				if c = a_quote then
					l_units.append (in.substring (l_start + 1, pos - 1))
					l_done := True
				elseif c = 0x5C then
					if pos = in.count then
						syntax_error ({STRING_32} "Unterminated escape sequence")
					end
					l_units.append (in.substring (l_start + 1, pos - 1))
					l_units.append_code (read_escape)
					l_start := pos
				end
			end
			if not l_done then
				syntax_error ({STRING_32} "Unterminated string")
			end
			Result := from_units (l_units)
		end

	read_escape: NATURAL_32
			-- JSONTokener.readEscapeCharacter.
		local
			l_hex: STRING_32
			l_value: detachable INTEGER_64_REF
		do
			Result := unit (pos)
			pos := pos + 1
			inspect
				Result
			when 0x75 then
				if pos + 4 > in.count then
					syntax_error ({STRING_32} "Unterminated escape sequence")
				end
				l_hex := in.substring (pos + 1, pos + 4)
				pos := pos + 4
				l_value := numbers.parsed_long (l_hex, 16)
				if attached l_value as al_value then
					Result := (al_value.item & 0xFFFF).to_natural_32
				else
					syntax_error ({STRING_32} "Invalid escape sequence: " + from_units (l_hex))
				end
			when 0x74 then
				Result := 0x09
			when 0x62 then
				Result := 0x08
			when 0x6E then
				Result := 0x0A
			when 0x72 then
				Result := 0x0D
			when 0x66 then
				Result := 0x0C
			else
				-- The character itself.
			end
		end

	next_to_literal_end: STRING_32
			-- JSONTokener.nextToInternal for the characters that end a literal.
		local
			l_start: INTEGER
			l_done: BOOLEAN
			c: NATURAL_32
		do
			from
				l_start := pos
			until
				l_done or else pos >= in.count
			loop
				c := unit (pos)
				if c = 0x0D or c = 0x0A or is_literal_end (c) then
					l_done := True
				else
					pos := pos + 1
				end
			end
			Result := in.substring (l_start + 1, pos)
		end

	is_literal_end (a_code: NATURAL_32): BOOLEAN
			-- Is `a_code' one of {}[]/\:,=;# tab space formfeed?
		do
			inspect
				a_code
			when 0x7B, 0x7D, 0x5B, 0x5D, 0x2F, 0x5C, 0x3A, 0x2C, 0x3D, 0x3B, 0x23, 0x20, 0x09, 0x0C then
				Result := True
			else
				Result := False
			end
		end

	read_literal: SB_JSON_VALUE
			-- JSONTokener.readLiteral.
		local
			l_literal, l_number: STRING_32
			l_radix: INTEGER
			l_value: detachable INTEGER_64_REF
			l_text: STRING_32
		do
			l_literal := next_to_literal_end
			if l_literal.is_empty then
				syntax_error ({STRING_32} "Expected literal value")
				create {SB_JSON_NULL} Result
			elseif numbers.text_rules.equal_ignoring_case (l_literal, {STRING_32} "null") then
				create {SB_JSON_NULL} Result
			elseif numbers.text_rules.equal_ignoring_case (l_literal, {STRING_32} "true") then
				create {SB_JSON_BOOLEAN} Result.make (True)
			elseif numbers.text_rules.equal_ignoring_case (l_literal, {STRING_32} "false") then
				create {SB_JSON_BOOLEAN} Result.make (False)
			else
				if not l_literal.has ('.') then
					l_radix := 10
					l_number := l_literal
					if l_number.count >= 2 and then l_number.code (1) = 0x30 and then (l_number.code (2) = 0x78 or l_number.code (2) = 0x58) then
						l_number := l_number.substring (3, l_number.count)
						l_radix := 16
					elseif l_number.count > 1 and then l_number.code (1) = 0x30 then
						l_number := l_number.substring (2, l_number.count)
						l_radix := 8
					end
					l_value := numbers.parsed_long (l_number, l_radix)
				end
				if attached l_value as al_value then
					if al_value.item <= {INTEGER_32}.max_value and al_value.item >= {INTEGER_32}.min_value then
						create {SB_JSON_INTEGER} Result.make (al_value.item.as_integer_32)
					else
						create {SB_JSON_INTEGER} Result.make_long (al_value.item)
					end
				elseif attached numbers.parsed_double (l_literal) as al_double then
					create {SB_JSON_DOUBLE} Result.make (al_double.item)
				else
					l_text := from_units (l_literal)
					create {SB_JSON_STRING} Result.make (l_text)
				end
			end
		end

	read_object: SB_JSON_OBJECT
			-- JSONTokener.readObject.
		local
			c, l_first, l_separator: INTEGER
			l_name: SB_JSON_VALUE
			l_message: STRING_32
			l_done: BOOLEAN
		do
			create Result.make
			l_first := next_clean
			if l_first = 0x7D then
				l_done := True
			elseif l_first /= -1 then
				pos := pos - 1
			end
			from
			until
				l_done
			loop
				l_name := next_value
				if attached {SB_JSON_STRING} l_name as al_name then
					l_separator := next_clean
					if l_separator /= 0x3A and l_separator /= 0x3D then
						syntax_error ({STRING_32} "Expected ':' after " + al_name.text)
					end
					if pos < in.count and then unit (pos) = 0x3E then
						pos := pos + 1
					end
					Result.put (al_name.text, next_value)
					c := next_clean
					if c = 0x7D then
						l_done := True
					elseif c /= 0x3B and c /= 0x2C then
						syntax_error ({STRING_32} "Unterminated object")
					end
				else
					create l_message.make (64)
					l_message.append_string_general ("Names must be strings, but ")
					if attached l_name.java_text as al_text then
						l_message.append (al_text)
					else
						l_message.append_string_general ("null")
					end
					l_message.append_string_general (" is of type " + l_name.class_name)
					syntax_error (l_message)
				end
			end
		end

	read_array: SB_JSON_ARRAY
			-- JSONTokener.readArray.
		local
			c: INTEGER
			l_trailing, l_done, l_skip: BOOLEAN
		do
			create Result.make
			from
			until
				l_done
			loop
				l_skip := False
				c := next_clean
				if c = -1 then
					syntax_error ({STRING_32} "Unterminated array")
				elseif c = 0x5D then
					if l_trailing then
						Result.put (Void)
					end
					l_done := True
				elseif c = 0x2C or c = 0x3B then
					Result.put (Void)
					l_trailing := True
					l_skip := True
				else
					pos := pos - 1
				end
				if not l_done and not l_skip then
					Result.put (next_value)
					c := next_clean
					if c = 0x5D then
						l_done := True
					elseif c = 0x2C or c = 0x3B then
						l_trailing := True
					else
						syntax_error ({STRING_32} "Unterminated array")
					end
				end
			end
		end

end
