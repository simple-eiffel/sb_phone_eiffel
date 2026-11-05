note
	description: "[
		The character rules of the Kotlin text code, where they cannot be read off Kotlin's
		source alone.

		The same Kotlin regex behaves differently on the two runtimes. The JVM's java.util.regex
		takes \s and \d as ASCII. Android's is ICU, where \s is White_Space and \d is all of Nd.
		IGNORE_CASE differs too (Kotlin adds UNICODE_CASE on the JVM; ICU does full case folding).
		Char.isWhitespace differs by one character, U+180E.

		`make_android' is what the Kotlin app does on the phone, and is what this port is
		for. `make_jvm' is what FoldTest.kt sees on the PC, kept so that the port can be
		compared with the real module on both. Every set below was read from Kotlin's own Regex,
		tried on every code point on both runtimes (testing/diff/KotlinOracle.java, regexsets).
	]"
	author: "Larry Rix"

class
	SB_KOTLIN_RULES

create
	make_android,
	make_jvm

feature {NONE} -- Initialization

	make_android
			-- The rules of Kotlin on Android.
		do
			is_android := True
			create unicode.make
		ensure
			android: is_android
		end

	make_jvm
			-- The rules of Kotlin on the JVM.
		do
			create unicode.make
		ensure
			jvm: not is_android
		end

feature -- Access

	is_android: BOOLEAN
			-- Android's rules, rather than the JVM's?

	unicode: SB_UNICODE
			-- The Unicode facts.

feature -- Regex character classes

	is_regex_space (a_code: NATURAL_32): BOOLEAN
			-- Does \s accept `a_code'?
		do
			Result := a_code = 0x20 or else (a_code >= 0x9 and a_code <= 0xD)
			if is_android and not Result then
				Result := a_code = 0x85 or else a_code = 0xA0 or else a_code = 0x1680
					or else (a_code >= 0x2000 and a_code <= 0x200A)
					or else a_code = 0x2028 or else a_code = 0x2029 or else a_code = 0x202F
					or else a_code = 0x205F or else a_code = 0x3000
			end
		end

	is_regex_digit (a_code: NATURAL_32): BOOLEAN
			-- Does \d accept `a_code'?
		do
			Result := is_ascii_digit (a_code)
			if is_android and not Result then
				Result := unicode.is_decimal_digit (a_code)
			end
		end

	is_ascii_digit (a_code: NATURAL_32): BOOLEAN
			-- Is `a_code' one of 0 to 9?
		do
			Result := a_code >= 0x30 and a_code <= 0x39
		end

	is_lower_ascii (a_code: NATURAL_32): BOOLEAN
			-- Does [a-z] accept `a_code', case sensitive?
		do
			Result := a_code >= 0x61 and a_code <= 0x7A
		end

	is_letter_ignoring_case (a_code: NATURAL_32): BOOLEAN
			-- Does [a-z] accept `a_code' under IGNORE_CASE?
		do
			Result := is_lower_ascii (a_code) or else (a_code >= 0x41 and a_code <= 0x5A)
				or else a_code = Long_s or else a_code = 0x212A
			if not is_android and not Result then
				Result := a_code = 0x130 or else a_code = 0x131
			end
		end

	strongs_prefix_end (a_text: READABLE_STRING_32; a_start: INTEGER): INTEGER
			-- Where the literal "strongs:" under IGNORE_CASE ends, if it begins at `a_start' in
			-- `a_text' (the index after it), or 0 if it does not begin there.
			-- Long s stands for s on both runtimes; ICU's full folding also lets the st ligatures
			-- stand for "st".
		require
			start_in_range: a_start >= 1
		local
			i: INTEGER
		do
			i := a_start
			if is_android and then i <= a_text.count and then (a_text.code (i) = 0xFB05 or else a_text.code (i) = 0xFB06) then
				i := i + 1
			elseif i + 1 <= a_text.count and then is_letter_s (a_text.code (i)) and then is_same_letter (a_text.code (i + 1), 0x74) then
				i := i + 2
			else
				i := 0
			end
			if i > 0 and then i + 5 <= a_text.count and then is_same_letter (a_text.code (i), 0x72) and then is_same_letter (a_text.code (i + 1), 0x6F)
				and then is_same_letter (a_text.code (i + 2), 0x6E) and then is_same_letter (a_text.code (i + 3), 0x67)
				and then is_letter_s (a_text.code (i + 4)) and then a_text.code (i + 5) = 0x3A
			then
				Result := i + 6
			end
		ensure
			after_start_or_none: Result = 0 or Result > a_start
		end

feature -- Kotlin characters

	is_whitespace (a_code: NATURAL_32): BOOLEAN
			-- Kotlin's Char.isWhitespace.
		do
			Result := a_code = 0x20 or else (a_code >= 0x9 and a_code <= 0xD) or else (a_code >= 0x1C and a_code <= 0x1F)
				or else a_code = 0xA0 or else a_code = 0x1680 or else (a_code >= 0x2000 and a_code <= 0x200A)
				or else a_code = 0x2028 or else a_code = 0x2029 or else a_code = 0x202F
				or else a_code = 0x205F or else a_code = 0x3000
			if is_android and not Result then
				Result := a_code = 0x180E
			end
		end

feature -- Kotlin positions

	utf16_offset (a_text: READABLE_STRING_32; a_index: INTEGER): INTEGER
			-- The 0-based Kotlin string index of the character at `a_index' in `a_text'. Kotlin counts
			-- UTF-16 units, so each character beyond the basic plane before it counts twice.
		require
			index_in_range: a_index >= 1 and a_index <= a_text.count + 1
		local
			i: INTEGER
		do
			Result := a_index - 1
			from
				i := 1
			until
				i >= a_index
			loop
				if a_text.code (i) > 0xFFFF then
					Result := Result + 1
				end
				i := i + 1
			end
		ensure
			at_least_the_index: Result >= a_index - 1
		end

	int_or (a_digits: READABLE_STRING_32; a_default: INTEGER): INTEGER
			-- `a_digits' as toIntOrNull reads it, or `a_default' where that gives null: when empty,
			-- when over 2147483647, or when holding a digit beyond the basic plane.
		local
			i, l_digit: INTEGER
			l_value: INTEGER_64
			l_ok: BOOLEAN
		do
			l_ok := not a_digits.is_empty
			from
				i := 1
			until
				i > a_digits.count or not l_ok
			loop
				l_digit := unicode.digit_value (a_digits.code (i))
				if l_digit < 0 then
					l_ok := False
				else
					l_value := l_value * 10 + l_digit
					l_ok := l_value <= {INTEGER_32}.max_value
				end
				i := i + 1
			end
			if l_ok then
				Result := l_value.to_integer_32
			else
				Result := a_default
			end
		end

	trim_stars (a_text: STRING_32)
			-- trimEnd ('*') on `a_text'.
		do
			from
			until
				a_text.is_empty or else a_text.code (a_text.count) /= 0x2A
			loop
				a_text.remove_tail (1)
			end
		ensure
			no_star_at_end: not a_text.is_empty implies a_text.code (a_text.count) /= 0x2A
		end

feature -- Scanning

	skip_spaces (a_text: READABLE_STRING_32; a_from: INTEGER): INTEGER
			-- The index after the run of \s in `a_text' starting at `a_from'.
		require
			from_in_range: a_from >= 1 and a_from <= a_text.count + 1
		do
			from
				Result := a_from
			until
				Result > a_text.count or else not is_regex_space (a_text.code (Result))
			loop
				Result := Result + 1
			end
		ensure
			not_before: Result >= a_from
			in_range: Result <= a_text.count + 1
		end

	skip_digits (a_text: READABLE_STRING_32; a_from, a_limit: INTEGER): INTEGER
			-- The index after the run of \d in `a_text' starting at `a_from', at most `a_limit' long.
		require
			from_in_range: a_from >= 1 and a_from <= a_text.count + 1
			limit_positive: a_limit > 0
		do
			from
				Result := a_from
			until
				Result > a_text.count or else Result - a_from >= a_limit or else not is_regex_digit (a_text.code (Result))
			loop
				Result := Result + 1
			end
		ensure
			not_before: Result >= a_from
			in_limit: Result - a_from <= a_limit
		end

feature {NONE} -- Implementation

	is_letter_s (a_code: NATURAL_32): BOOLEAN
			-- Is `a_code' s under IGNORE_CASE?
		do
			Result := is_same_letter (a_code, 0x73) or else a_code = Long_s
		end

	is_same_letter (a_code, a_lower: NATURAL_32): BOOLEAN
			-- Is `a_code' the ASCII letter `a_lower' in either case?
		do
			Result := a_code = a_lower or else a_code = a_lower - 32
		end

	Long_s: NATURAL_32 = 0x17F
			-- Latin small letter long s.

end
