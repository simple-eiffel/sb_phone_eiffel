note
	description: "[
		The Unicode facts the fold module needs, stated the way java.lang.Character and
		String.lowercase state them, over simple_encoding's SIMPLE_UNICODE (Unicode 15.1.0,
		every code point).

		SIMPLE_UNICODE is used for its tables, not for its idea of "letter or digit": its
		`is_letter_or_digit' takes all of N*, where Java takes Nd alone. So x-squared must fold
		to two words here, and `is_letter_or_digit' below is the Java rule.
	]"
	author: "Larry Rix"

class
	SB_UNICODE

create
	make

feature {NONE} -- Initialization

	make
			-- Create the service. The tables decode on first use, once per process.
		do
			create unicode.make
		end

feature -- Normalization

	nfd (a_text: READABLE_STRING_32): STRING_32
			-- Canonical decomposition of `a_text', as java.text.Normalizer gives it (form NFD).
		do
			Result := unicode.nfd (a_text)
		end

feature -- Character properties

	general_category (a_code: NATURAL_32): STRING_8
			-- The two-letter general category of `a_code'.
		do
			Result := unicode.general_category (a_code.to_character_32)
		ensure
			two_letters: Result.count = 2
		end

	is_mark_or_format (a_code: NATURAL_32): BOOLEAN
			-- Is `a_code' of category Mn, Me, Mc or Cf?
		local
			l_char: CHARACTER_32
		do
			l_char := a_code.to_character_32
			Result := unicode.is_combining_mark (l_char) or else unicode.is_format_character (l_char)
		end

	is_letter_or_digit (a_code: NATURAL_32): BOOLEAN
			-- Character.isLetterOrDigit: category L*, or Nd. Nl and No are not included.
		do
			Result := unicode.is_letter (a_code.to_character_32) or else is_decimal_digit (a_code)
		end

	is_decimal_digit (a_code: NATURAL_32): BOOLEAN
			-- Is `a_code' of category Nd?
		local
			l_char: CHARACTER_32
		do
			l_char := a_code.to_character_32
			Result := unicode.is_in_category (l_char, 'N') and then unicode.general_category (l_char).same_string ("Nd")
		end

	digit_value (a_code: NATURAL_32): INTEGER
			-- What Kotlin's toIntOrNull reads from the UTF-16 unit `a_code': the value of a decimal
			-- digit of the basic plane, -1 for anything else. A digit beyond the basic plane is
			-- two units in Kotlin, neither of them a digit, so it too gives -1.
		local
			l_zero: NATURAL_32
		do
			Result := -1
			if a_code <= 0xFFFF and then is_decimal_digit (a_code) then
				from
					l_zero := a_code
				until
					l_zero = 0 or else not is_decimal_digit (l_zero - 1)
				loop
					l_zero := l_zero - 1
				end
				Result := ((a_code - l_zero) \\ 10).to_integer_32
			end
		ensure
			in_range: Result >= -1 and Result <= 9
		end

feature -- Case

	lower_code (a_code: NATURAL_32): NATURAL_32
			-- The one-code-point lowercase of `a_code'.
		do
			Result := unicode.simple_lower (a_code.to_character_32).natural_32_code
		end

	lowercase (a_text: READABLE_STRING_32): STRING_32
			-- `a_text' as Kotlin's lowercase () gives it, for matching against ASCII words:
			-- dotted capital I becomes two code points, every other mapping is one. The final
			-- sigma rule is left out on purpose: the two sigmas differ only in non-ASCII text,
			-- and no caller of this feature can match non-ASCII text either way.
		local
			i: INTEGER
			l_code: NATURAL_32
		do
			create Result.make (a_text.count)
			from
				i := 1
			until
				i > a_text.count
			loop
				l_code := a_text.code (i)
				if l_code = Dotted_capital_i then
					Result.append_code (0x69)
					Result.append_code (0x307)
				else
					Result.append_code (lower_code (l_code))
				end
				i := i + 1
			end
		ensure
			no_shorter: Result.count >= a_text.count
		end

feature {NONE} -- Implementation

	unicode: SIMPLE_UNICODE
			-- simple_encoding's tables.

	Dotted_capital_i: NATURAL_32 = 0x130
			-- The one code point whose lowercase is two (SpecialCasing.txt, no condition).

end
