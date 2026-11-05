note
	description: "[
		Search folding. The same rules as Fold.kt, which built the index in app.db, so an index
		built by the Kotlin data builder and a query folded here can never disagree.

		NFD, then every combining mark and format character is dropped (Hebrew points and
		cantillation, Greek accents and breathings, Latin diacritics). Lower case; Greek final
		sigma becomes sigma; Hebrew final letters become their ordinary forms. Apostrophes are
		removed; any other character that is not a letter or digit becomes a space, and runs
		of spaces collapse to one.
	]"
	author: "Larry Rix"

class
	SB_FOLD

create
	make

feature {NONE} -- Initialization

	make
			-- Create the folder.
		do
			create unicode.make
		end

feature -- Folding

	fold (a_text: READABLE_STRING_32): STRING_32
			-- `a_text' folded.
		local
			l_decomposed: STRING_32
			i: INTEGER
			l_code: NATURAL_32
			l_pending_space: BOOLEAN
		do
			l_decomposed := unicode.nfd (a_text)
			create Result.make (l_decomposed.count)
			from
				i := 1
			until
				i > l_decomposed.count
			loop
				l_code := l_decomposed.code (i)
				if unicode.is_mark_or_format (l_code) or else is_apostrophe (l_code) then
					-- Dropped, leaving no space behind.
				elseif unicode.is_letter_or_digit (l_code) then
					if l_pending_space and then not Result.is_empty then
						Result.append_code (Space)
					end
					l_pending_space := False
					Result.append_code (ordinary_form (unicode.lower_code (l_code)))
				else
					l_pending_space := True
				end
				i := i + 1
			end
		ensure
			no_leading_space: not Result.is_empty implies Result.code (1) /= Space
			no_trailing_space: not Result.is_empty implies Result.code (Result.count) /= Space
			single_spaces: not Result.has_substring ({STRING_32} "  ")
		end

	words (a_text: READABLE_STRING_32): ARRAYED_LIST [STRING_32]
			-- The folded words of `a_text', in order.
		local
			l_folded: STRING_32
			i, l_start: INTEGER
		do
			l_folded := fold (a_text)
			create Result.make (8)
			from
				i := 1
				l_start := 1
			until
				i > l_folded.count + 1
			loop
				if i > l_folded.count or else l_folded.code (i) = Space then
					if i > l_start then
						Result.extend (l_folded.substring (l_start, i - 1))
					end
					l_start := i + 1
				end
				i := i + 1
			end
		ensure
			no_empty_word: across Result as ic all not ic.is_empty end
		end

feature {NONE} -- Implementation

	unicode: SB_UNICODE
			-- The Unicode facts.

	Space: NATURAL_32 = 0x20
			-- The one separator in folded text.

	is_apostrophe (a_code: NATURAL_32): BOOLEAN
			-- Is `a_code' one of the five marks removed outright?
			-- Straight, right and left quote, modifier letter apostrophe, backtick.
		do
			Result := a_code = 0x27 or else a_code = 0x2019 or else a_code = 0x2018
				or else a_code = 0x2BC or else a_code = 0x60
		end

	ordinary_form (a_code: NATURAL_32): NATURAL_32
			-- `a_code', with Greek final sigma and the Hebrew final letters made ordinary.
		do
			inspect
				a_code
			when 0x3C2 then
				Result := 0x3C3
			when 0x5DA then
				Result := 0x5DB
			when 0x5DD then
				Result := 0x5DE
			when 0x5DF then
				Result := 0x5E0
			when 0x5E3 then
				Result := 0x5E4
			when 0x5E5 then
				Result := 0x5E6
			else
				Result := a_code
			end
		end

end
