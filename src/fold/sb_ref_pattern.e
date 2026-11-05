note
	description: "[
		RefParser.pattern by hand, with its groups:
			^\s*([1-3]?\s*[a-z][a-z .]*?)\s*(\d+)?(?:\s*[:. ]\s*(\d+))?(?:\s*[-\u2013]\s*(\d+))?\s*$
		used as matchEntire on lowercased text.

		Each `try_' feature is one element of the regex. It tries the element's choices in the
		regex's own order (greedy longest first, the lazy book part shortest first) and passes
		each to the next element, so the first complete match is the one the regex finds, and
		the groups hold what they hold there. "john.3" is the book "john", no chapter, verse 3.
		The ^ and $ add nothing to matchEntire, which needs the whole text anyway.
	]"
	author: "Larry Rix"

class
	SB_REF_PATTERN

create
	make

feature {NONE} -- Initialization

	make (a_rules: SB_KOTLIN_RULES)
			-- Create the pattern under `a_rules'.
		do
			rules := a_rules
			create text.make_empty
		ensure
			rules_set: rules = a_rules
			nothing_matched: not is_matched
		end

feature -- Status

	is_matched: BOOLEAN
			-- Did the whole of the last text match?

feature -- Groups

	book_part: STRING_32
			-- Group 1.
		require
			matched: is_matched
		do
			Result := text.substring (book_from, book_to - 1)
		ensure
			not_empty: not Result.is_empty
		end

	chapter_text: STRING_32
			-- Group 2, empty if it took no part.
		require
			matched: is_matched
		do
			Result := group (chapter_from, chapter_to)
		end

	verse_text: STRING_32
			-- Group 3, empty if it took no part.
		require
			matched: is_matched
		do
			Result := group (verse_from, verse_to)
		end

	verse_end_text: STRING_32
			-- Group 4, empty if it took no part.
		require
			matched: is_matched
		do
			Result := group (end_from, end_to)
		end

feature -- Matching

	match (a_text: STRING_32)
			-- Try to match the whole of `a_text'.
		local
			p: INTEGER
		do
			text := a_text
			is_matched := False
			from
				p := spaces_end (1)
			until
				p < 1 or is_matched
			loop
				try_book (p)
				p := p - 1
			end
		end

feature {NONE} -- The regex, element by element

	try_book (a_start: INTEGER)
			-- [1-3]? at `a_start', the first element of group 1.
		do
			book_from := a_start
			if a_start <= text.count and then text.code (a_start) >= 0x31 and then text.code (a_start) <= 0x33 then
				try_first_letter (a_start + 1)
			end
			if not is_matched then
				try_first_letter (a_start)
			end
		end

	try_first_letter (a_from: INTEGER)
			-- \s*[a-z] at `a_from'.
		local
			q: INTEGER
		do
			from
				q := spaces_end (a_from)
			until
				q < a_from or is_matched
			loop
				if q <= text.count and then rules.is_lower_ascii (text.code (q)) then
					try_more_letters (q + 1)
				end
				q := q - 1
			end
		end

	try_more_letters (a_from: INTEGER)
			-- [a-z .]*? at `a_from': the shortest first, one more character at a time.
		local
			t: INTEGER
			l_stop: BOOLEAN
		do
			from
				t := a_from
			until
				l_stop or is_matched
			loop
				book_to := t
				try_chapter (t)
				if not is_matched then
					if t <= text.count and then is_book_character (text.code (t)) then
						t := t + 1
					else
						l_stop := True
					end
				end
			end
		end

	try_chapter (a_from: INTEGER)
			-- \s*(\d+)? at `a_from'.
		local
			u, v: INTEGER
		do
			from
				u := spaces_end (a_from)
			until
				u < a_from or is_matched
			loop
				from
					v := digits_end (u)
				until
					v <= u or is_matched
				loop
					chapter_from := u
					chapter_to := v
					try_verse (v)
					v := v - 1
				end
				if not is_matched then
					chapter_from := 0
					try_verse (u)
				end
				u := u - 1
			end
		end

	try_verse (a_from: INTEGER)
			-- (?:\s*[:. ]\s*(\d+))? at `a_from'.
		local
			w: INTEGER
		do
			from
				w := spaces_end (a_from)
			until
				w < a_from or is_matched
			loop
				if w <= text.count and then is_verse_separator (text.code (w)) then
					try_verse_digits (w + 1)
				end
				w := w - 1
			end
			if not is_matched then
				verse_from := 0
				try_range (a_from)
			end
		end

	try_verse_digits (a_from: INTEGER)
			-- \s*(\d+) at `a_from', inside the verse part.
		local
			x, y: INTEGER
		do
			from
				x := spaces_end (a_from)
			until
				x < a_from or is_matched
			loop
				from
					y := digits_end (x)
				until
					y <= x or is_matched
				loop
					verse_from := x
					verse_to := y
					try_range (y)
					y := y - 1
				end
				x := x - 1
			end
		end

	try_range (a_from: INTEGER)
			-- (?:\s*[-\u2013]\s*(\d+))? at `a_from'.
		local
			w: INTEGER
		do
			from
				w := spaces_end (a_from)
			until
				w < a_from or is_matched
			loop
				if w <= text.count and then (text.code (w) = 0x2D or else text.code (w) = En_dash) then
					try_range_digits (w + 1)
				end
				w := w - 1
			end
			if not is_matched then
				end_from := 0
				try_finish (a_from)
			end
		end

	try_range_digits (a_from: INTEGER)
			-- \s*(\d+) at `a_from', inside the range part.
		local
			x, y: INTEGER
		do
			from
				x := spaces_end (a_from)
			until
				x < a_from or is_matched
			loop
				from
					y := digits_end (x)
				until
					y <= x or is_matched
				loop
					end_from := x
					end_to := y
					try_finish (y)
					y := y - 1
				end
				x := x - 1
			end
		end

	try_finish (a_from: INTEGER)
			-- \s*$ at `a_from'. Backing off the spaces could never reach the end, so one try is all.
		do
			is_matched := spaces_end (a_from) = text.count + 1
		end

feature {NONE} -- Implementation

	rules: SB_KOTLIN_RULES
			-- What \s and \d accept.

	text: STRING_32
			-- The text being matched.

	book_from, book_to, chapter_from, chapter_to, verse_from, verse_to, end_from, end_to: INTEGER
			-- Where the groups are: from the first index up to, not including, the second.
			-- A first index of 0 is a group that took no part.

	En_dash: NATURAL_32 = 0x2013
			-- The dash the pattern accepts beside the hyphen.

	group (a_from, a_to: INTEGER): STRING_32
			-- The group at `a_from', `a_to'.
		do
			if a_from > 0 then
				Result := text.substring (a_from, a_to - 1)
			else
				create Result.make_empty
			end
		end

	spaces_end (a_from: INTEGER): INTEGER
			-- The index after the \s* at `a_from'.
		do
			Result := rules.skip_spaces (text, a_from)
		end

	digits_end (a_from: INTEGER): INTEGER
			-- The index after the \d+ at `a_from', `a_from' itself if there is no digit.
		do
			Result := rules.skip_digits (text, a_from, text.count + 1)
		end

	is_book_character (a_code: NATURAL_32): BOOLEAN
			-- Does [a-z .] accept `a_code'?
		do
			Result := rules.is_lower_ascii (a_code) or else a_code = 0x20 or else a_code = 0x2E
		end

	is_verse_separator (a_code: NATURAL_32): BOOLEAN
			-- Does [:. ] accept `a_code'?
		do
			Result := a_code = 0x3A or else a_code = 0x2E or else a_code = 0x20
		end

end
