note
	description: "[
		Finds Bible references written in running text: "John 3:16", "Rom 8:28-30", "1 John 1:1-3",
		"Song of Songs 2:1". Only references that read as exactly one book are returned.

		RefFinder.pattern by hand:
			((?:[1-3]\s?)?[A-Za-z]{2,}\.?(?:\s(?:of\s)?Songs?)?)\s(\d{1,3}):(\d{1,3})(?:\s?[-\u2013]\s?(\d{1,3}))?
		Each `try_' feature is one element, trying its choices in the regex's own order, as in
		SB_REF_PATTERN. The search moves on from the end of each match, also when the match
		then fails to read as one book: "Song Song 1:1" consumes itself and yields nothing.
	]"
	author: "Larry Rix"

class
	SB_REF_FINDER

create
	make,
	make_with_rules

feature {NONE} -- Initialization

	make
			-- Create the finder with the rules of Kotlin on Android.
		do
			make_with_rules (create {SB_KOTLIN_RULES}.make_android)
		end

	make_with_rules (a_rules: SB_KOTLIN_RULES)
			-- Create the finder under `a_rules'.
		do
			rules := a_rules
			create parser.make_with_rules (a_rules)
			text := {STRING_32} ""
		ensure
			rules_set: rules = a_rules
		end

feature -- Search

	find_all (a_text: READABLE_STRING_32): ARRAYED_LIST [SB_REF_FOUND]
			-- The references in `a_text', in order.
		local
			i: INTEGER
			l_value: STRING_32
		do
			text := a_text
			create Result.make (2)
			from
				i := 1
			until
				i > a_text.count
			loop
				match_end := 0
				try_book (i)
				if match_end > 0 then
					l_value := a_text.substring (i, match_end - 1).to_string_32
					if attached {SB_REF_PARSE_ONE} parser.parse (l_value) as al_one and then al_one.ref.verse > 0 then
						Result.extend (create {SB_REF_FOUND}.make (rules.utf16_offset (a_text, i), rules.utf16_offset (a_text, match_end) - 1, l_value, al_one.ref))
					end
					i := match_end
				else
					i := i + 1
				end
			end
		ensure
			every_finding_has_a_verse: across Result as ic all ic.ref.verse > 0 end
		end

feature {NONE} -- The regex, element by element

	try_book (a_start: INTEGER)
			-- (?:[1-3]\s?)? at `a_start'.
		do
			if is_book_number (a_start) then
				if is_space_at (a_start + 1) then
					try_letters (a_start + 2)
				end
				if match_end = 0 then
					try_letters (a_start + 1)
				end
			end
			if match_end = 0 then
				try_letters (a_start)
			end
		end

	try_letters (a_from: INTEGER)
			-- [A-Za-z]{2,} at `a_from'.
		local
			q, l_last: INTEGER
		do
			from
				q := a_from
			until
				q > text.count or else not is_ascii_letter (text.code (q))
			loop
				q := q + 1
			end
			l_last := q
			from
				q := l_last
			until
				q < a_from + 2 or match_end > 0
			loop
				try_dot (q)
				q := q - 1
			end
		end

	try_dot (a_from: INTEGER)
			-- \.? at `a_from'.
		do
			if a_from <= text.count and then text.code (a_from) = 0x2E then
				try_song (a_from + 1)
			end
			if match_end = 0 then
				try_song (a_from)
			end
		end

	try_song (a_from: INTEGER)
			-- (?:\s(?:of\s)?Songs?)? at `a_from'.
		do
			if is_space_at (a_from) then
				if a_from + 3 <= text.count and then text.code (a_from + 1) = 0x6F and then text.code (a_from + 2) = 0x66 and then is_space_at (a_from + 3) then
					try_song_word (a_from + 4)
				end
				if match_end = 0 then
					try_song_word (a_from + 1)
				end
			end
			if match_end = 0 then
				try_chapter (a_from)
			end
		end

	try_song_word (a_from: INTEGER)
			-- Songs? at `a_from'.
		do
			if a_from + 3 <= text.count and then text.code (a_from) = 0x53 and then text.code (a_from + 1) = 0x6F
				and then text.code (a_from + 2) = 0x6E and then text.code (a_from + 3) = 0x67
			then
				if a_from + 4 <= text.count and then text.code (a_from + 4) = 0x73 then
					try_chapter (a_from + 5)
				end
				if match_end = 0 then
					try_chapter (a_from + 4)
				end
			end
		end

	try_chapter (a_from: INTEGER)
			-- \s(\d{1,3}): at `a_from'.
		local
			e: INTEGER
		do
			if is_space_at (a_from) then
				from
					e := digits_end (a_from + 1)
				until
					e <= a_from + 1 or match_end > 0
				loop
					if e <= text.count and then text.code (e) = 0x3A then
						try_verse (e + 1)
					end
					e := e - 1
				end
			end
		end

	try_verse (a_from: INTEGER)
			-- (\d{1,3}) at `a_from'. What follows is optional, so the longest run always stands.
		local
			e: INTEGER
		do
			e := digits_end (a_from)
			if e > a_from then
				try_range (e)
				if match_end = 0 then
					match_end := e
				end
			end
		end

	try_range (a_from: INTEGER)
			-- (?:\s?[-\u2013]\s?(\d{1,3}))? at `a_from'; `match_end' stays 0 if it takes no part.
		do
			if is_space_at (a_from) then
				try_dash (a_from + 1)
			end
			if match_end = 0 then
				try_dash (a_from)
			end
		end

	try_dash (a_from: INTEGER)
			-- [-\u2013]\s?(\d{1,3}) at `a_from'.
		do
			if a_from <= text.count and then (text.code (a_from) = 0x2D or else text.code (a_from) = 0x2013) then
				if is_space_at (a_from + 1) then
					try_end_digits (a_from + 2)
				end
				if match_end = 0 then
					try_end_digits (a_from + 1)
				end
			end
		end

	try_end_digits (a_from: INTEGER)
			-- (\d{1,3}) at `a_from', the last element.
		local
			e: INTEGER
		do
			e := digits_end (a_from)
			if e > a_from then
				match_end := e
			end
		end

feature {NONE} -- Implementation

	rules: SB_KOTLIN_RULES
			-- What \s and \d accept.

	parser: SB_REF_PARSER
			-- Reads what the pattern finds.

	text: READABLE_STRING_32
			-- The text being searched.

	match_end: INTEGER
			-- The index after the match being tried, 0 until there is one.

	is_book_number (a_index: INTEGER): BOOLEAN
			-- Does [1-3] accept the character at `a_index'?
		do
			Result := a_index <= text.count and then text.code (a_index) >= 0x31 and then text.code (a_index) <= 0x33
		end

	is_space_at (a_index: INTEGER): BOOLEAN
			-- Does \s accept the character at `a_index'?
		do
			Result := a_index <= text.count and then rules.is_regex_space (text.code (a_index))
		end

	is_ascii_letter (a_code: NATURAL_32): BOOLEAN
			-- Does [A-Za-z] accept `a_code'?
		do
			Result := rules.is_lower_ascii (a_code) or else (a_code >= 0x41 and a_code <= 0x5A)
		end

	digits_end (a_from: INTEGER): INTEGER
			-- The index after the \d{1,3} at `a_from', `a_from' itself if there is no digit.
		do
			Result := rules.skip_digits (text, a_from, 3)
		end

end
