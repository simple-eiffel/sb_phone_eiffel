note
	description: "[
		The string rules of Kotlin on Android that the data classes need, and of Android's ICU SQLite.

		Two lowercases, because Android has two. String.lowercase () keeps a final sigma by looking
		only at the two neighbouring UTF-16 units, and hands the whole string to ICU if it holds a
		dotted capital I or anything beyond the basic plane. SQL lower () is ICU itself, whose final
		sigma rule skips case-ignorable characters. Every table below was read from the emulator
		(Android 15, android.icu.lang.UCharacter).
	]"
	author: "Larry Rix"

class
	SB_KOTLIN_TEXT

create
	make

feature {NONE} -- Initialization

	make
			-- Create with the rules of Kotlin on Android.
		do
			create rules.make_android
			unicode := rules.unicode
			create tables.make
		end

feature -- Access

	rules: SB_KOTLIN_RULES
			-- The character rules.

	unicode: SB_UNICODE
			-- The Unicode facts.

	tables: SIMPLE_UNICODE
			-- simple_encoding's tables, for what SB_UNICODE does not state.

feature -- Trimming

	trimmed (a_text: READABLE_STRING_32): STRING_32
			-- String.trim ().
		local
			l_start, l_end: INTEGER
		do
			from
				l_start := 1
			until
				l_start > a_text.count or else not rules.is_whitespace (a_text.code (l_start))
			loop
				l_start := l_start + 1
			end
			from
				l_end := a_text.count
			until
				l_end < l_start or else not rules.is_whitespace (a_text.code (l_end))
			loop
				l_end := l_end - 1
			end
			Result := a_text.substring (l_start, l_end).to_string_32
		ensure
			no_longer: Result.count <= a_text.count
		end

	is_blank (a_text: READABLE_STRING_32): BOOLEAN
			-- CharSequence.isBlank ().
		local
			i: INTEGER
		do
			Result := True
			from
				i := 1
			until
				i > a_text.count or not Result
			loop
				Result := rules.is_whitespace (a_text.code (i))
				i := i + 1
			end
		end

	without_lower_letters_at_end (a_text: READABLE_STRING_32): STRING_32
			-- trimEnd { it.isLetter () && it.isLowerCase () }.
		local
			l_end: INTEGER
		do
			from
				l_end := a_text.count
			until
				l_end < 1 or else not is_lower_letter (a_text.code (l_end))
			loop
				l_end := l_end - 1
			end
			Result := a_text.substring (1, l_end).to_string_32
		end

	is_all_letters (a_text: READABLE_STRING_32): BOOLEAN
			-- all { it.isLetter () }.
		local
			i: INTEGER
		do
			Result := True
			from
				i := 1
			until
				i > a_text.count or not Result
			loop
				Result := is_letter (a_text.code (i))
				i := i + 1
			end
		end

	without_prefix (a_text, a_prefix: READABLE_STRING_32): STRING_32
			-- removePrefix.
		do
			if a_text.starts_with (a_prefix) then
				Result := a_text.substring (a_prefix.count + 1, a_text.count).to_string_32
			else
				Result := a_text.to_string_32
			end
		end

	first_word (a_text: READABLE_STRING_32): STRING_32
			-- trim ().split (Regex ("\\s+")).first ().
		local
			l_text: STRING_32
			i: INTEGER
		do
			l_text := trimmed (a_text)
			from
				i := 1
			until
				i > l_text.count or else rules.is_regex_space (l_text.code (i))
			loop
				i := i + 1
			end
			Result := l_text.substring (1, i - 1)
		end

	without_quotes_and_stars (a_text: READABLE_STRING_32): STRING_32
			-- trim ('"', '*').
		local
			l_start, l_end: INTEGER
		do
			from
				l_start := 1
			until
				l_start > a_text.count or else not is_quote_or_star (a_text.code (l_start))
			loop
				l_start := l_start + 1
			end
			from
				l_end := a_text.count
			until
				l_end < l_start or else not is_quote_or_star (a_text.code (l_end))
			loop
				l_end := l_end - 1
			end
			Result := a_text.substring (l_start, l_end).to_string_32
		end

	with_spaces_collapsed (a_text: READABLE_STRING_32): STRING_32
			-- replace (Regex ("\\s+"), " ").
		local
			i: INTEGER
			l_in_space: BOOLEAN
		do
			create Result.make (a_text.count)
			from
				i := 1
			until
				i > a_text.count
			loop
				if rules.is_regex_space (a_text.code (i)) then
					if not l_in_space then
						Result.append_code (32)
					end
					l_in_space := True
				else
					Result.append_code (a_text.code (i))
					l_in_space := False
				end
				i := i + 1
			end
		end

feature -- Case

	lowercase (a_text: READABLE_STRING_32): STRING_32
			-- String.lowercase () on Android.
		local
			i: INTEGER
			l_code: NATURAL_32
			l_hard: BOOLEAN
		do
			from
				i := 1
			until
				i > a_text.count or l_hard
			loop
				l_code := a_text.code (i)
				l_hard := l_code = Dotted_capital_i or else l_code > 0xFFFF
				i := i + 1
			end
			if l_hard then
				Result := icu_lowercase (a_text)
			else
				create Result.make (a_text.count)
				from
					i := 1
				until
					i > a_text.count
				loop
					l_code := a_text.code (i)
					if l_code = Capital_sigma and then is_final_by_neighbours (a_text, i) then
						Result.append_code (Final_sigma)
					else
						Result.append_code (unicode.lower_code (l_code))
					end
					i := i + 1
				end
			end
		end

	icu_lowercase (a_text: READABLE_STRING_32): STRING_32
			-- SQL lower () on Android: ICU's u_strToLower for the root locale.
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
				if l_code < 0x80 then
					if l_code >= 0x41 and l_code <= 0x5A then
						Result.append_code (l_code + 32)
					else
						Result.append_code (l_code)
					end
				elseif l_code = Dotted_capital_i then
					Result.append_code (0x69)
					Result.append_code (0x307)
				elseif l_code = Capital_sigma and then is_final_by_context (a_text, i) then
					Result.append_code (Final_sigma)
				else
					Result.append_code (unicode.lower_code (l_code))
				end
				i := i + 1
			end
		end

	case_folded (a_text: READABLE_STRING_32): STRING_32
			-- `a_text' with each character folded as u_foldCase folds it.
		local
			i: INTEGER
		do
			create Result.make (a_text.count + 1)
			from
				i := 1
			until
				i > a_text.count
			loop
				Result.append_code (folded_code (a_text.code (i)))
				i := i + 1
			end
		ensure
			same_count: Result.count = a_text.count
		end

	folded_code (a_code: NATURAL_32): NATURAL_32
			-- u_foldCase (a_code, U_FOLD_CASE_DEFAULT).
		do
			if a_code < 0x80 then
				Result := unicode.lower_code (a_code)
			elseif a_code >= 0x13A0 and a_code <= 0x13F5 then
				Result := a_code
			elseif a_code >= 0x13F8 and a_code <= 0x13FD then
				Result := a_code - 8
			elseif a_code >= 0xAB70 and a_code <= 0xABBF then
				Result := a_code - 0xAB70 + 0x13A0
			else
				inspect
					a_code
				when 0xB5 then
					Result := 0x3BC
				when 0x130 then
					Result := 0x130
				when 0x17F then
					Result := 0x73
				when 0x345, 0x1FBE then
					Result := 0x3B9
				when 0x3C2 then
					Result := 0x3C3
				when 0x3D0 then
					Result := 0x3B2
				when 0x3D1 then
					Result := 0x3B8
				when 0x3D5 then
					Result := 0x3C6
				when 0x3D6 then
					Result := 0x3C0
				when 0x3F0 then
					Result := 0x3BA
				when 0x3F1 then
					Result := 0x3C1
				when 0x3F5 then
					Result := 0x3B5
				when 0x1C80 then
					Result := 0x432
				when 0x1C81 then
					Result := 0x434
				when 0x1C82 then
					Result := 0x43E
				when 0x1C83 then
					Result := 0x441
				when 0x1C84, 0x1C85 then
					Result := 0x442
				when 0x1C86 then
					Result := 0x44A
				when 0x1C87 then
					Result := 0x463
				when 0x1C88 then
					Result := 0xA64B
				when 0x1E9B then
					Result := 0x1E61
				when 0x1FD3 then
					Result := 0x390
				when 0x1FE3 then
					Result := 0x3B0
				when 0xFB05 then
					Result := 0xFB06
				else
					Result := unicode.lower_code (a_code)
				end
			end
		end

	equal_ignoring_case (a_one, a_other: READABLE_STRING_32): BOOLEAN
			-- String.equals (other, ignoreCase = true): unit by unit, so beyond the basic plane only
			-- identical characters match.
		local
			i: INTEGER
			c, d: NATURAL_32
		do
			Result := a_one.count = a_other.count
			from
				i := 1
			until
				i > a_one.count or not Result
			loop
				c := a_one.code (i)
				d := a_other.code (i)
				if c /= d then
					Result := c <= 0xFFFF and then d <= 0xFFFF and then (upper_code (c) = upper_code (d)
						or else unicode.lower_code (upper_code (c)) = unicode.lower_code (upper_code (d)))
				end
				i := i + 1
			end
		end

	upper_code (a_code: NATURAL_32): NATURAL_32
			-- Character.toUpperCase.
		do
			Result := tables.simple_upper (a_code.to_character_32).natural_32_code
		end

	is_letter (a_code: NATURAL_32): BOOLEAN
			-- Char.isLetter (): one UTF-16 unit, so nothing beyond the basic plane.
		do
			Result := a_code <= 0xFFFF and then unicode.general_category (a_code) [1] = 'L'
		end

	is_letter_or_digit (a_code: NATURAL_32): BOOLEAN
			-- Char.isLetterOrDigit (): one UTF-16 unit, so nothing beyond the basic plane.
		do
			Result := a_code <= 0xFFFF and then unicode.is_letter_or_digit (a_code)
		end

	is_lower_letter (a_code: NATURAL_32): BOOLEAN
			-- Char.isLetter () and Char.isLowerCase ().
		do
			Result := a_code <= 0xFFFF and then unicode.general_category (a_code).same_string ("Ll")
		end

	is_cased (a_code: NATURAL_32): BOOLEAN
			-- Unicode's Cased property.
		local
			l_category: STRING_8
		do
			l_category := unicode.general_category (a_code)
			Result := l_category.same_string ("Lu") or else l_category.same_string ("Ll") or else l_category.same_string ("Lt")
				or else in_ranges (a_code, Other_cased)
		end

	is_case_ignorable (a_code: NATURAL_32): BOOLEAN
			-- Unicode's Case_Ignorable property.
		local
			l_category: STRING_8
		do
			l_category := unicode.general_category (a_code)
			Result := l_category.same_string ("Mn") or else l_category.same_string ("Me") or else l_category.same_string ("Cf")
				or else l_category.same_string ("Lm") or else l_category.same_string ("Sk")
				or else in_ranges (a_code, Other_case_ignorable)
		end

feature -- Paths

	file_name_of (a_path: READABLE_STRING_32): STRING_32
			-- File.name: the last part of `a_path'.
		local
			i: INTEGER
		do
			from
				i := a_path.count
			until
				i < 1 or else a_path.code (i) = 0x2F or else a_path.code (i) = 0x5C
			loop
				i := i - 1
			end
			Result := a_path.substring (i + 1, a_path.count).to_string_32
		end

feature -- Ordering

	is_before_in_utf_16 (a_one, a_other: READABLE_STRING_32): BOOLEAN
			-- Does `a_one' sort before `a_other' as String.compareTo sorts, by UTF-16 unit?
		local
			i, l_count: INTEGER
			c, d: NATURAL_32
			l_decided: BOOLEAN
		do
			l_count := a_one.count.min (a_other.count)
			from
				i := 1
			until
				i > l_count or l_decided
			loop
				c := a_one.code (i)
				d := a_other.code (i)
				if c /= d then
					l_decided := True
					Result := utf_16_rank (c) < utf_16_rank (d)
				end
				i := i + 1
			end
			if not l_decided then
				Result := a_one.count < a_other.count
			end
		end

feature {NONE} -- Implementation

	is_quote_or_star (a_code: NATURAL_32): BOOLEAN
			-- Is `a_code' a double quote or a star?
		do
			Result := a_code = 0x22 or else a_code = 0x2A
		end

	is_cased_unit (a_code: NATURAL_32): BOOLEAN
			-- Is `a_code' lower, upper or title case, as CaseMapper asks of a neighbour?
		local
			l_category: STRING_8
		do
			l_category := unicode.general_category (a_code)
			Result := l_category.same_string ("Lu") or else l_category.same_string ("Ll") or else l_category.same_string ("Lt")
		end

	is_final_by_neighbours (a_text: READABLE_STRING_32; a_index: INTEGER): BOOLEAN
			-- Android's CaseMapper: is the sigma at `a_index' final?
		do
			if a_index > 1 and then is_cased_unit (a_text.code (a_index - 1)) then
				Result := a_index = a_text.count or else not is_cased_unit (a_text.code (a_index + 1))
			end
		end

	is_final_by_context (a_text: READABLE_STRING_32; a_index: INTEGER): BOOLEAN
			-- ICU: is the sigma at `a_index' after a cased letter and before none, case-ignorable
			-- characters aside?
		local
			i: INTEGER
		do
			from
				i := a_index - 1
			until
				i < 1 or else not is_case_ignorable (a_text.code (i))
			loop
				i := i - 1
			end
			if i >= 1 and then is_cased (a_text.code (i)) then
				from
					i := a_index + 1
				until
					i > a_text.count or else not is_case_ignorable (a_text.code (i))
				loop
					i := i + 1
				end
				Result := i > a_text.count or else not is_cased (a_text.code (i))
			end
		end

	utf_16_rank (a_code: NATURAL_32): NATURAL_64
			-- A number that sorts code points as UTF-16 sorts them: a character beyond the basic
			-- plane starts with a surrogate, which comes before U+E000.
		do
			if a_code > 0xFFFF then
				Result := {NATURAL_64} 0xD800 * 0x200000 + a_code.to_natural_64
			else
				Result := a_code.to_natural_64 * 0x200000
			end
		end

	in_ranges (a_code: NATURAL_32; a_ranges: ARRAY [NATURAL_32]): BOOLEAN
			-- Is `a_code' in one of the ranges, given as first and last, ascending?
		local
			i: INTEGER
		do
			from
				i := a_ranges.lower
			until
				i >= a_ranges.upper or else Result or else a_ranges [i] > a_code
			loop
				Result := a_code >= a_ranges [i] and a_code <= a_ranges [i + 1]
				i := i + 2
			end
		end

	Other_cased: ARRAY [NATURAL_32]
			-- Cased characters outside Lu, Ll and Lt.
		once
			Result := <<0xAA, 0xAA, 0xBA, 0xBA, 0x2B0, 0x2B8, 0x2C0, 0x2C1, 0x2E0, 0x2E4, 0x345, 0x345, 0x37A, 0x37A, 0x10FC, 0x10FC,
				0x1D2C, 0x1D6A, 0x1D78, 0x1D78, 0x1D9B, 0x1DBF, 0x2071, 0x2071, 0x207F, 0x207F, 0x2090, 0x209C, 0x2160, 0x217F,
				0x24B6, 0x24E9, 0x2C7C, 0x2C7D, 0xA69C, 0xA69D, 0xA770, 0xA770, 0xA7F2, 0xA7F4, 0xA7F8, 0xA7F9, 0xAB5C, 0xAB5F,
				0xAB69, 0xAB69, 0x10780, 0x10780, 0x10783, 0x10785, 0x10787, 0x107B0, 0x107B2, 0x107BA, 0x1E030, 0x1E06D,
				0x1F130, 0x1F149, 0x1F150, 0x1F169, 0x1F170, 0x1F189>>
		end

	Other_case_ignorable: ARRAY [NATURAL_32]
			-- Case-ignorable characters outside Mn, Me, Cf, Lm and Sk.
		once
			Result := <<0x27, 0x27, 0x2E, 0x2E, 0x3A, 0x3A, 0xB7, 0xB7, 0x387, 0x387, 0x55F, 0x55F, 0x5F4, 0x5F4, 0x2018, 0x2019,
				0x2024, 0x2024, 0x2027, 0x2027, 0xFE13, 0xFE13, 0xFE52, 0xFE52, 0xFE55, 0xFE55, 0xFF07, 0xFF07, 0xFF0E, 0xFF0E,
				0xFF1A, 0xFF1A>>
		end

	Capital_sigma: NATURAL_32 = 0x3A3
			-- Greek capital sigma.

	Final_sigma: NATURAL_32 = 0x3C2
			-- Greek small final sigma.

	Dotted_capital_i: NATURAL_32 = 0x130
			-- Latin capital I with dot above.

end
