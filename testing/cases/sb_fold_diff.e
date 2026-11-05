note
	description: "[
		Writes, for each input line, the same canonical line that KotlinOracle.java writes from
		the real Kotlin module, so that the two can be compared byte for byte. The output goes
		through `emit': to a file on the PC (SB_FOLD_DIFF_APP), into a hash on the emulator
		(spikes/s_fold), where the same code runs compiled by gec.

		Modes: fold refs query pointing books allcp regexsets
		Input: one text per line, as hexadecimal code points separated by spaces.
		Output: printable ASCII, everything else as \u{hex}.
	]"
	author: "Larry Rix"

deferred class
	SB_FOLD_DIFF

feature {NONE} -- Initialization

	make_parts (a_rules: SB_KOTLIN_RULES)
			-- Create the classes under test, with `a_rules'.
		do
			rules := a_rules
			create fold.make
			create pointing
			create books
			create ref_parser.make_with_rules (rules)
			create ref_finder.make_with_rules (rules)
			create query_parser.make_with_rules (rules)
		end

feature -- Running

	run (a_mode, a_input: READABLE_STRING_32)
			-- Run the mode `a_mode'; all but books, allcp and regexsets read `a_input'.
		do
			if a_mode.same_string ({STRING_32} "books") then
				write_books
			elseif a_mode.same_string ({STRING_32} "allcp") then
				write_all_code_points
			elseif a_mode.same_string ({STRING_32} "regexsets") then
				write_regex_sets
			else
				write_lines (a_mode, a_input)
			end
		end

feature {NONE} -- Output

	emit (a_text: READABLE_STRING_8)
			-- Send out `a_text'.
		deferred
		end

	emit_character (a_character: CHARACTER_8)
			-- Send out `a_character'.
		deferred
		end

feature {NONE} -- Modes

	write_lines (a_mode, a_input: READABLE_STRING_32)
			-- One line of output per line of `a_input'.
		local
			l_file: RAW_FILE
			l_text: STRING_32
		do
			create l_file.make_with_name (a_input)
			l_file.open_read
			from
				l_file.read_line
			until
				l_file.end_of_file and l_file.last_string.is_empty
			loop
				l_text := decoded (l_file.last_string)
				if a_mode.same_string ({STRING_32} "fold") then
					write_fold (l_text)
				elseif a_mode.same_string ({STRING_32} "refs") then
					write_refs (l_text)
				elseif a_mode.same_string ({STRING_32} "query") then
					write_query (l_text)
				else
					write_pointing (l_text)
				end
				emit_character ('%N')
				if l_file.end_of_file then
					l_file.last_string.wipe_out
				else
					l_file.read_line
				end
			end
			l_file.close
		end

	write_fold (a_text: STRING_32)
			-- The fold and the words of `a_text'.
		local
			l_words: ARRAYED_LIST [STRING_32]
			l_joined: STRING_32
			i: INTEGER
		do
			put (fold.fold (a_text))
			emit (" # ")
			l_words := fold.words (a_text)
			create l_joined.make (a_text.count)
			from
				i := 1
			until
				i > l_words.count
			loop
				if i > 1 then
					l_joined.append_character ('|')
				end
				l_joined.append (l_words [i])
				i := i + 1
			end
			put (l_joined)
		end

	write_refs (a_text: STRING_32)
			-- All that the reference classes say of `a_text'.
		local
			l_parse: SB_REF_PARSE
			l_matching: ARRAYED_LIST [SB_BOOK]
			l_found: ARRAYED_LIST [SB_REF_FOUND]
			i: INTEGER
		do
			l_parse := ref_parser.parse (a_text)
			put (l_parse.debug_output)
			if attached {SB_REF_PARSE_ONE} l_parse as al_one then
				put_ref (al_one.ref)
			elseif attached {SB_REF_PARSE_CHOICE} l_parse as al_choice then
				from
					i := 1
				until
					i > al_choice.refs.count
				loop
					put_ref (al_choice.refs [i])
					i := i + 1
				end
			end
			emit (" # matching")
			l_matching := ref_parser.books_matching (a_text)
			from
				i := 1
			until
				i > l_matching.count
			loop
				emit (" " + l_matching [i].id.out)
				i := i + 1
			end
			emit (" # code ")
			if attached books.by_code (a_text) as al_book then
				emit (al_book.id.out)
			else
				emit ("none")
			end
			emit (" # found")
			l_found := ref_finder.find_all (a_text)
			from
				i := 1
			until
				i > l_found.count
			loop
				emit_character (' ')
				put (l_found [i].debug_output)
				i := i + 1
			end
		end

	put_ref (a_ref: SB_REF)
			-- All that a reference says of itself.
		do
			emit (" {")
			put (a_ref.debug_output)
			emit_character (' ')
			put (a_ref.label)
			emit (" | ")
			put (a_ref.short_label)
			emit (" | " + a_ref.key.out + " | ")
			put ((create {SB_REF}.make_from_key (a_ref.key)).debug_output)
			emit_character ('}')
		end

	write_query (a_text: STRING_32)
			-- All that the query classes say of `a_text'.
		local
			l_parse: SB_QUERY_PARSE
			l_matches: ARRAYED_LIST [SB_MATCH]
			i: INTEGER
		do
			l_parse := query_parser.parse (a_text)
			put (l_parse.debug_output)
			if attached {SB_QUERY_PARSE_TEXT} l_parse as al_text then
				emit (" # words " + al_text.query.has_word_terms.out.as_lower + " # matches")
				l_matches := al_text.query.text_matches
				from
					i := 1
				until
					i > l_matches.count
				loop
					emit (" [")
					put (l_matches [i].fts)
					emit_character (']')
					i := i + 1
				end
			end
		end

	write_pointing (a_text: STRING_32)
			-- `a_text' at the three levels.
		do
			put (pointing.apply (a_text, pointing.Level_full))
			emit (" # ")
			put (pointing.apply (a_text, pointing.Level_vowels))
			emit (" # ")
			put (pointing.apply (a_text, pointing.Level_consonants))
		end

	write_books
			-- The book table.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > books.all_books.count
			loop
				put (books.all_books [i].debug_output)
				emit (" " + books.all_books [i].is_old_testament.out.as_lower + "%N")
				i := i + 1
			end
		end

	write_all_code_points
			-- For every code point alone: its fold, NFD, category, letter-or-digit, lowercase, whitespace.
		local
			l_code: NATURAL_32
			l_text: STRING_32
		do
			from
				l_code := 0
			until
				l_code > 0x10FFFF
			loop
				create l_text.make (1)
				l_text.append_code (l_code)
				emit (hex_text (l_code))
				emit_character (' ')
				put (fold.fold (l_text))
				emit_character (' ')
				put (rules.unicode.nfd (l_text))
				emit (" " + rules.unicode.general_category (l_code) + " " + rules.unicode.is_letter_or_digit (l_code).out.as_lower + " ")
				put (rules.unicode.lowercase (l_text))
				emit (" " + (l_code < 0x10000 and then rules.is_whitespace (l_code)).out.as_lower + "%N")
				l_code := l_code + 1
			end
		end

	write_regex_sets
			-- What each hand-written regex atom accepts, in KotlinOracle's regexsets format.
		local
			l_code: NATURAL_32
			l_line, l_literal: STRING_8
			l_alone: SB_STRONGS_PATTERN
			l_text: STRING_32
			k: INTEGER
		do
			create l_alone.make (rules)
			l_literal := "strongs:"
			from
				l_code := 0
			until
				l_code > 0x10FFFF
			loop
				if l_code < 0xD800 or l_code > 0xDFFF then
					create l_line.make (16)
					if rules.is_regex_space (l_code) then
						l_line.append (" space")
					end
					if rules.is_regex_digit (l_code) then
						l_line.append (" digit")
					end
					if rules.unicode.digit_value (l_code) >= 0 then
						l_line.append (" value=" + rules.unicode.digit_value (l_code).out)
					end
					if rules.is_letter_ignoring_case (l_code) then
						l_line.append (" letter")
					end
					create l_text.make (12)
					l_text.append_code (l_code)
					l_text.append_string_general ("1")
					l_alone.match_term (l_text)
					if l_alone.is_matched then
						l_line.append (" hg")
					end
					from
						k := 1
					until
						k > l_literal.count
					loop
						create l_text.make (12)
						l_text.append_string_general (l_literal.substring (1, k - 1))
						l_text.append_code (l_code)
						l_text.append_string_general (l_literal.substring (k + 1, l_literal.count))
						l_text.append_string_general ("H1")
						l_alone.match_term (l_text)
						if l_alone.is_matched then
							l_line.append (" lit" + (k - 1).out)
						end
						if k < l_literal.count then
							create l_text.make (12)
							l_text.append_string_general (l_literal.substring (1, k - 1))
							l_text.append_code (l_code)
							l_text.append_string_general (l_literal.substring (k + 2, l_literal.count))
							l_text.append_string_general ("H1")
							l_alone.match_term (l_text)
							if l_alone.is_matched then
								l_line.append (" pair" + (k - 1).out)
							end
						end
						k := k + 1
					end
					if not l_line.is_empty then
						emit (hex_text (l_code) + l_line + "%N")
					end
				end
				l_code := l_code + 1
			end
		end

feature {NONE} -- Implementation

	rules: SB_KOTLIN_RULES
	fold: SB_FOLD
	pointing: SB_POINTING
	books: SB_BOOKS
	ref_parser: SB_REF_PARSER
	ref_finder: SB_REF_FINDER
	query_parser: SB_QUERY_PARSER
			-- The classes under test.

	decoded (a_line: STRING_8): STRING_32
			-- The text of a line of hexadecimal code points.
		local
			i: INTEGER
			l_value: NATURAL_32
			l_digits: BOOLEAN
			c: CHARACTER_8
		do
			create Result.make (a_line.count // 3)
			from
				i := 1
			until
				i > a_line.count + 1
			loop
				if i <= a_line.count then
					c := a_line [i]
				else
					c := ' '
				end
				if c.is_hexa_digit then
					l_value := l_value * 16 + hex_value (c)
					l_digits := True
				elseif l_digits then
					Result.append_code (l_value)
					l_value := 0
					l_digits := False
				end
				i := i + 1
			end
		end

	hex_value (a_digit: CHARACTER_8): NATURAL_32
			-- The value of the lowercase hexadecimal digit `a_digit'.
		do
			if a_digit >= 'a' then
				Result := (a_digit.code - ('a').code + 10).to_natural_32
			else
				Result := (a_digit.code - ('0').code).to_natural_32
			end
		end

	put (a_text: READABLE_STRING_32)
			-- Write `a_text' as KotlinOracle.esc does.
		local
			i: INTEGER
			l_code: NATURAL_32
		do
			from
				i := 1
			until
				i > a_text.count
			loop
				l_code := a_text.code (i)
				if l_code >= 0x20 and l_code <= 0x7E and l_code /= 0x5C then
					emit_character (l_code.to_character_8)
				else
					emit ("\u{" + hex_text (l_code) + "}")
				end
				i := i + 1
			end
		end

	hex_text (a_code: NATURAL_32): STRING_8
			-- `a_code' in lowercase hexadecimal, without leading zeros.
		do
			Result := a_code.to_hex_string.as_lower
			from
			until
				Result.count = 1 or else Result [1] /= '0'
			loop
				Result.remove_head (1)
			end
		end

end
