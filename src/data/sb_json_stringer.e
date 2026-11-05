note
	description: "[
		org.json.JSONStringer, as Android has it: `make_compact' for toString (), `make_indented'
		for toString (n). Escapes quote, backslash and slash; \t \b \n \r \f by name; every other
		control character as \u00xx in lower case; everything else as it is. Empty containers
		are [] and {} with nothing inside.
	]"
	author: "Larry Rix"

class
	SB_JSON_STRINGER

create
	make_compact,
	make_indented

feature {NONE} -- Initialization

	make_compact
			-- Write without spaces.
		do
			create text.make (256)
			create indent.make_empty
			create stack.make (8)
		end

	make_indented (a_spaces: INTEGER)
			-- Write with `a_spaces' spaces per level.
		require
			spaces_positive: a_spaces > 0
		do
			make_compact
			create indent.make_filled (' ', a_spaces)
			is_indented := True
		end

feature -- Access

	text: STRING_32
			-- What has been written.

feature -- Status

	has_failed: BOOLEAN
			-- Was a value met that JSON cannot hold (NaN or an infinity)?

feature -- Writing

	begin_object
			-- JSONStringer.object.
		do
			before_value
			text.append_code (0x7B)
			stack.extend (Empty_object)
		end

	end_object
			-- JSONStringer.endObject.
		do
			close (Nonempty_object, 0x7D)
		end

	begin_array
			-- JSONStringer.array.
		do
			before_value
			text.append_code (0x5B)
			stack.extend (Empty_array)
		end

	end_array
			-- JSONStringer.endArray.
		do
			close (Nonempty_array, 0x5D)
		end

	put_key (a_name: READABLE_STRING_32)
			-- JSONStringer.key.
		do
			if stack.last = Nonempty_object then
				text.append_code (0x2C)
			end
			new_line
			stack [stack.count] := Dangling_key
			append_string (a_name)
		end

	put_string (a_value: READABLE_STRING_32)
			-- Write a string value.
		do
			before_value
			append_string (a_value)
		end

	put_integer (a_value: INTEGER_64)
			-- Write an integer value.
		do
			before_value
			text.append_string_general (a_value.out)
		end

	put_double (a_value: REAL_64)
			-- Write a double value, by JSONObject.numberToString.
		local
			l_long: INTEGER_64
		do
			before_value
			if not numbers.is_finite (a_value) then
				has_failed := True
			elseif a_value = 0.0 and then numbers.is_negative_zero (a_value) then
				text.append_string_general ("-0")
			else
				l_long := numbers.to_long (a_value)
				if a_value = l_long.to_double then
					text.append_string_general (l_long.out)
				else
					text.append_string_general (numbers.double_text (a_value))
				end
			end
		end

	put_literal (a_literal: READABLE_STRING_8)
			-- Write true, false or null.
		do
			before_value
			text.append_string_general (a_literal)
		end

feature {NONE} -- Implementation

	indent: STRING_8
			-- One level of indentation.

	is_indented: BOOLEAN
			-- Is the output indented?

	stack: ARRAYED_LIST [INTEGER]
			-- The scopes that are open.

	numbers: SB_JAVA_NUMBERS
			-- Java's number rules.
		once
			create Result
		end

	Empty_array: INTEGER = 1
	Nonempty_array: INTEGER = 2
	Empty_object: INTEGER = 3
	Nonempty_object: INTEGER = 4
	Dangling_key: INTEGER = 5
			-- The scopes.

	close (a_nonempty: INTEGER; a_bracket: NATURAL_32)
			-- JSONStringer.close.
		local
			l_scope: INTEGER
		do
			l_scope := stack.last
			stack.finish
			stack.remove
			if l_scope = a_nonempty then
				new_line
			end
			text.append_code (a_bracket)
		end

	before_value
			-- JSONStringer.beforeValue.
		local
			l_scope: INTEGER
		do
			if not stack.is_empty then
				l_scope := stack.last
				if l_scope = Empty_array then
					stack [stack.count] := Nonempty_array
					new_line
				elseif l_scope = Nonempty_array then
					text.append_code (0x2C)
					new_line
				elseif l_scope = Dangling_key then
					text.append_code (0x3A)
					if is_indented then
						text.append_code (0x20)
					end
					stack [stack.count] := Nonempty_object
				end
			end
		end

	new_line
			-- JSONStringer.newline.
		local
			i: INTEGER
		do
			if is_indented then
				text.append_code (0x0A)
				from
					i := 1
				until
					i > stack.count
				loop
					text.append_string_general (indent)
					i := i + 1
				end
			end
		end

	append_string (a_value: READABLE_STRING_32)
			-- JSONStringer.string.
		local
			i: INTEGER
			c: NATURAL_32
		do
			text.append_code (0x22)
			from
				i := 1
			until
				i > a_value.count
			loop
				c := a_value.code (i)
				inspect
					c
				when 0x22, 0x5C, 0x2F then
					text.append_code (0x5C)
					text.append_code (c)
				when 0x09 then
					text.append_string_general ("\t")
				when 0x08 then
					text.append_string_general ("\b")
				when 0x0A then
					text.append_string_general ("\n")
				when 0x0D then
					text.append_string_general ("\r")
				when 0x0C then
					text.append_string_general ("\f")
				else
					if c <= 0x1F then
						text.append_string_general ("\u00")
						text.append_string_general (c.to_hex_string.substring (7, 8).as_lower)
					else
						text.append_code (c)
					end
				end
				i := i + 1
			end
			text.append_code (0x22)
		end

end
