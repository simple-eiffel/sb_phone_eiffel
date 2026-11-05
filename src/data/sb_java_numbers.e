note
	description: "[
		Java's number rules, where org.json leans on them: Long.parseLong, Double.parseDouble,
		Double.toString and the casts. Only ASCII text reaches `parsed_double'; the C library
		does the correctly rounded conversion once the Java grammar has been checked.

		`double_text' gives the shortest digits that read back the same. Android's Double.toString
		(FloatingDecimal) gives one digit more for a few values, such as 2 to the power -44.
	]"
	author: "Larry Rix"

class
	SB_JAVA_NUMBERS

feature -- Parsing

	parsed_long (a_text: READABLE_STRING_32; a_radix: INTEGER): detachable INTEGER_64_REF
			-- Long.parseLong (a_text, a_radix), Void where that throws NumberFormatException.
		require
			radix_in_range: a_radix >= 2 and a_radix <= 36
		local
			i, l_digit: INTEGER
			l_value: NATURAL_64
			l_limit: NATURAL_64
			l_negative, l_ok: BOOLEAN
		do
			if not a_text.is_empty then
				i := 1
				if a_text.code (1) = 0x2D then
					l_negative := True
					i := 2
				elseif a_text.code (1) = 0x2B then
					i := 2
				end
				l_ok := i <= a_text.count
				if l_negative then
					l_limit := {NATURAL_64} 0x8000000000000000
				else
					l_limit := {NATURAL_64} 0x7FFFFFFFFFFFFFFF
				end
				from
				until
					i > a_text.count or not l_ok
				loop
					l_digit := digit_of (a_text.code (i), a_radix)
					if l_digit < 0 or else l_value > (l_limit - l_digit.to_natural_64) // a_radix.to_natural_64 then
						l_ok := False
					else
						l_value := l_value * a_radix.to_natural_64 + l_digit.to_natural_64
					end
					i := i + 1
				end
				if l_ok then
					if l_negative then
						Result := (l_value.bit_not + 1).as_integer_64
					else
						Result := l_value.as_integer_64
					end
				end
			end
		end

	parsed_double (a_text: READABLE_STRING_32): detachable REAL_64_REF
			-- Double.parseDouble (a_text), Void where that throws NumberFormatException.
		local
			l_text: STRING_8
			l_start, l_end, i: INTEGER
			l_ok: BOOLEAN
			l_sign_end: INTEGER
		do
			from
				l_start := 1
			until
				l_start > a_text.count or else a_text.code (l_start) > 0x20
			loop
				l_start := l_start + 1
			end
			from
				l_end := a_text.count
			until
				l_end < l_start or else a_text.code (l_end) > 0x20
			loop
				l_end := l_end - 1
			end
			l_ok := l_end >= l_start
			create l_text.make (l_end - l_start + 1)
			from
				i := l_start
			until
				i > l_end or not l_ok
			loop
				if a_text.code (i) > 0x7E then
					l_ok := False
				else
					l_text.append_character (a_text.code (i).to_character_8)
				end
				i := i + 1
			end
			if l_ok then
				l_sign_end := 0
				if l_text [1] = '+' or l_text [1] = '-' then
					l_sign_end := 1
				end
				if l_text.substring (l_sign_end + 1, l_text.count).same_string ("NaN") then
					Result := nan
				elseif l_text.substring (l_sign_end + 1, l_text.count).same_string ("Infinity") then
					if l_text [1] = '-' then
						Result := -positive_infinity
					else
						Result := positive_infinity
					end
				elseif is_java_double (l_text, l_sign_end + 1) then
					if l_text [l_text.count].as_lower = 'd' or l_text [l_text.count].as_lower = 'f' then
						l_text.remove_tail (1)
					end
					Result := c_string_to_double (l_text)
				end
			end
		end

feature -- Conversion

	to_int (a_value: REAL_64): INTEGER
			-- The Java cast (int) a_value.
		do
			if c_is_nan (a_value) /= 0 then
				Result := 0
			elseif a_value >= {INTEGER_32}.max_value.to_double then
				Result := {INTEGER_32}.max_value
			elseif a_value <= {INTEGER_32}.min_value.to_double then
				Result := {INTEGER_32}.min_value
			else
				Result := a_value.truncated_to_integer
			end
		end

	to_long (a_value: REAL_64): INTEGER_64
			-- The Java cast (long) a_value.
		do
			if c_is_nan (a_value) /= 0 then
				Result := 0
			elseif a_value >= {INTEGER_64}.max_value.to_double then
				Result := {INTEGER_64}.max_value
			elseif a_value <= {INTEGER_64}.min_value.to_double then
				Result := {INTEGER_64}.min_value
			else
				Result := a_value.truncated_to_integer_64
			end
		end

	double_text (a_value: REAL_64): STRING_8
			-- Double.toString (a_value).
		local
			l_digits: STRING_8
			l_exponent: INTEGER
			l_shortest: TUPLE [digits: STRING_8; exponent: INTEGER]
		do
			if c_is_nan (a_value) /= 0 then
				Result := "NaN"
			elseif a_value = positive_infinity then
				Result := "Infinity"
			elseif a_value = -positive_infinity then
				Result := "-Infinity"
			elseif a_value = 0.0 then
				if is_negative_zero (a_value) then
					Result := "-0.0"
				else
					Result := "0.0"
				end
			else
				create Result.make (24)
				if a_value < 0.0 then
					Result.append_character ('-')
				end
				l_shortest := shortest_digits (a_value.abs)
				l_digits := l_shortest.digits
				l_exponent := l_shortest.exponent
				if l_exponent >= -3 and l_exponent < 7 then
					if l_exponent >= 0 then
						if l_digits.count <= l_exponent + 1 then
							Result.append (l_digits)
							Result.append (create {STRING_8}.make_filled ('0', l_exponent + 1 - l_digits.count))
							Result.append (".0")
						else
							Result.append (l_digits.substring (1, l_exponent + 1))
							Result.append_character ('.')
							Result.append (l_digits.substring (l_exponent + 2, l_digits.count))
						end
					else
						Result.append ("0.")
						Result.append (create {STRING_8}.make_filled ('0', -l_exponent - 1))
						Result.append (l_digits)
					end
				else
					Result.append_character (l_digits [1])
					Result.append_character ('.')
					if l_digits.count > 1 then
						Result.append (l_digits.substring (2, l_digits.count))
					else
						Result.append_character ('0')
					end
					Result.append_character ('E')
					Result.append (l_exponent.out)
				end
			end
		end

feature -- Status

	is_finite (a_value: REAL_64): BOOLEAN
			-- Is `a_value' neither NaN nor an infinity?
		do
			Result := c_is_nan (a_value) = 0 and then a_value /= positive_infinity and then a_value /= -positive_infinity
		end

	is_negative_zero (a_value: REAL_64): BOOLEAN
			-- Is `a_value' minus zero?
		do
			Result := a_value = 0.0 and then c_sign_bit (a_value) /= 0
		end

feature -- Access

	text_rules: SB_KOTLIN_TEXT
			-- Kotlin's text rules.
		once
			create Result.make
		end

feature {NONE} -- Implementation

	nan: REAL_64
			-- A NaN.
		do
			Result := c_string_to_double ("nan")
		end

	positive_infinity: REAL_64
			-- Plus infinity.
		do
			Result := c_string_to_double ("inf")
		end

	digit_of (a_code: NATURAL_32; a_radix: INTEGER): INTEGER
			-- Character.digit: the value of `a_code' in `a_radix', -1 if it has none.
		local
			l_value: INTEGER
		do
			l_value := -1
			if a_code >= 0x30 and a_code <= 0x39 then
				l_value := (a_code - 0x30).to_integer_32
			elseif a_code >= 0x41 and a_code <= 0x5A then
				l_value := (a_code - 0x41).to_integer_32 + 10
			elseif a_code >= 0x61 and a_code <= 0x7A then
				l_value := (a_code - 0x61).to_integer_32 + 10
			elseif a_code >= 0xFF21 and a_code <= 0xFF3A then
				l_value := (a_code - 0xFF21).to_integer_32 + 10
			elseif a_code >= 0xFF41 and a_code <= 0xFF5A then
				l_value := (a_code - 0xFF41).to_integer_32 + 10
			elseif a_code > 0x7F then
				l_value := unicode.digit_value (a_code)
			end
			if l_value < a_radix then
				Result := l_value
			else
				Result := -1
			end
		end

	unicode: SB_UNICODE
			-- The Unicode facts.
		once
			create Result.make
		end

	is_hex_prefix (a_text: READABLE_STRING_8; a_start: INTEGER): BOOLEAN
			-- Does a hexadecimal number start at `a_start'?
		do
			Result := a_start + 1 <= a_text.count and then a_text [a_start] = '0' and then a_text [a_start + 1].as_lower = 'x'
		end

	is_java_double (a_text: READABLE_STRING_8; a_start: INTEGER): BOOLEAN
			-- Is `a_text' from `a_start' a Java floating point literal, type suffix allowed?
		local
			i, l_digits, l_exponent_digits: INTEGER
			l_hex: BOOLEAN
		do
			i := a_start
			l_hex := is_hex_prefix (a_text, a_start)
			if l_hex then
				i := i + 2
			end
			from
			until
				i > a_text.count or else not is_digit (a_text [i], l_hex)
			loop
				i := i + 1
				l_digits := l_digits + 1
			end
			if i <= a_text.count and then a_text [i] = '.' then
				from
					i := i + 1
				until
					i > a_text.count or else not is_digit (a_text [i], l_hex)
				loop
					i := i + 1
					l_digits := l_digits + 1
				end
			end
			if l_digits > 0 then
				if i <= a_text.count and then ((l_hex and a_text [i].as_lower = 'p') or (not l_hex and a_text [i].as_lower = 'e')) then
					i := i + 1
					if i <= a_text.count and then (a_text [i] = '+' or a_text [i] = '-') then
						i := i + 1
					end
					from
					until
						i > a_text.count or else not a_text [i].is_digit
					loop
						i := i + 1
						l_exponent_digits := l_exponent_digits + 1
					end
					Result := l_exponent_digits > 0
				else
					Result := not l_hex
				end
				if Result and then i <= a_text.count then
					Result := i = a_text.count and then (a_text [i].as_lower = 'd' or a_text [i].as_lower = 'f')
				end
			end
		end

	is_digit (a_character: CHARACTER_8; a_hex: BOOLEAN): BOOLEAN
			-- Is `a_character' a digit?
		do
			Result := a_character.is_digit or else (a_hex and then a_character.is_hexa_digit)
		end

	shortest_digits (a_value: REAL_64): TUPLE [digits: STRING_8; exponent: INTEGER]
			-- The fewest significant digits of the positive `a_value' that read back the same, and
			-- the decimal exponent of the first.
		require
			positive: a_value > 0.0
		local
			l_buffer: C_STRING
			l_precision, l_exponent_at: INTEGER
			l_text: STRING_8
			l_digits: STRING_8
			l_done: BOOLEAN
		do
			create l_buffer.make_empty (64)
			create l_text.make_empty
			from
				l_precision := 1
			until
				l_done
			loop
				c_format_e (a_value, l_precision, l_buffer.item)
				l_text := l_buffer.string
				l_done := l_precision >= 16 or else c_string_to_double (l_text) = a_value
				l_precision := l_precision + 1
			end
			l_exponent_at := l_text.index_of ('e', 1)
			create l_digits.make (20)
			l_digits.append_character (l_text [1])
			if l_exponent_at > 3 then
				l_digits.append (l_text.substring (3, l_exponent_at - 1))
			end
			from
			until
				l_digits.count <= 1 or else l_digits [l_digits.count] /= '0'
			loop
				l_digits.remove_tail (1)
			end
			Result := [l_digits, l_text.substring (l_exponent_at + 1, l_text.count).to_integer]
		end

	c_string_to_double (a_text: READABLE_STRING_8): REAL_64
			-- strtod.
		local
			l_text: C_STRING
		do
			create l_text.make (a_text)
			Result := c_strtod (l_text.item)
		end

	c_strtod (a_text: POINTER): REAL_64
			-- strtod on the C string `a_text'.
		external
			"C inline use <stdlib.h>"
		alias
			"return (EIF_REAL_64) strtod ((const char *) $a_text, NULL);"
		end

	c_format_e (a_value: REAL_64; a_precision: INTEGER; a_buffer: POINTER)
			-- Write `a_value' into `a_buffer' as %.*e.
		external
			"C inline use <stdio.h>"
		alias
			"snprintf ((char *) $a_buffer, 64, %"%%.*e%", (int) $a_precision, (double) $a_value);"
		end

	c_is_nan (a_value: REAL_64): INTEGER
			-- 1 if `a_value' is a NaN.
		external
			"C inline use <math.h>"
		alias
			"return (EIF_INTEGER_32) (isnan ((double) $a_value) ? 1 : 0);"
		end

	c_sign_bit (a_value: REAL_64): INTEGER
			-- 1 if the sign bit of `a_value' is set.
		external
			"C inline use <math.h>"
		alias
			"return (EIF_INTEGER_32) (signbit ((double) $a_value) ? 1 : 0);"
		end

end
