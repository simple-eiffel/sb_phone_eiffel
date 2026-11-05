note
	description: "[
		The words of a KJV verse, as pickAt and kjvTappable in EnglishScreen.kt find them.
		Text positions count from 0, in the characters of the verse.
	]"
	author: "Larry Rix"

class
	SB_KJV_WORDS

create
	make

feature {NONE} -- Initialization

	make (a_key: INTEGER; a_text: READABLE_STRING_32)
			-- Find the words of `a_text', verse `a_key'.
		local
			i, l_start: INTEGER
		do
			key := a_key
			text := a_text
			create starts.make (32)
			create stops.make (32)
			from i := 1 until i > a_text.count loop
				if is_word_character (a_text [i]) then
					l_start := i
					from until i > a_text.count or else not is_word_character (a_text [i]) loop
						i := i + 1
					end
					starts.extend (l_start)
					stops.extend (i - 1)
				else
					i := i + 1
				end
			end
		ensure
			matched: starts.count = stops.count
		end

feature -- Access

	key: INTEGER

	text: READABLE_STRING_32

	starts, stops: ARRAYED_LIST [INTEGER]
			-- Where each word begins and ends in `text', from 1.

	word (a_index: INTEGER): STRING_32
		do
			Result := text.substring (starts [a_index], stops [a_index]).to_string_32
		end

	first_fold (a_index: INTEGER): detachable STRING_32
			-- The first word of the fold of word `a_index', if any.
		do
			across fold.fold (word (a_index)).split (' ') as ic until Result /= Void loop
				if not ic.is_empty then
					Result := ic.to_string_32
				end
			end
		end

	pick (a_index: INTEGER; a_nth: INTEGER; a_fold: STRING_32): SB_WORD_PICK
			-- Word `a_index', the `a_nth' place of `a_fold' in the verse.
		do
			create Result.make (key, trimmed (word (a_index)), a_fold, a_nth)
		end

	pick_at (a_offset: INTEGER): detachable SB_WORD_PICK
			-- The word at `a_offset' from 0: pickAt.
		local
			i, l_hit, l_nth, j: INTEGER
		do
			from i := 1 until l_hit /= 0 or i > starts.count loop
				if a_offset >= starts [i] - 1 and a_offset <= stops [i] then
					l_hit := i
				end
				i := i + 1
			end
			if l_hit /= 0 and then attached first_fold (l_hit) as al_fold then
				l_nth := 1
				from j := 1 until j = l_hit loop
					across fold.words (word (j)) as ic loop
						if ic.same_string (al_fold) then
							l_nth := l_nth + 1
						end
					end
					j := j + 1
				end
				Result := pick (l_hit, l_nth, al_fold)
			end
		end

feature {NONE} -- Implementation

	trimmed (a_word: STRING_32): STRING_32
			-- `a_word' without apostrophes at its ends.
		do
			Result := a_word
			from until Result.is_empty or else not is_apostrophe (Result [1]) loop
				Result := Result.substring (2, Result.count)
			end
			from until Result.is_empty or else not is_apostrophe (Result [Result.count]) loop
				Result := Result.substring (1, Result.count - 1)
			end
		end

	is_apostrophe (a_character: CHARACTER_32): BOOLEAN
		do
			Result := a_character = '%'' or a_character = '%/8217/'
		end

	is_word_character (a_character: CHARACTER_32): BOOLEAN
			-- [\p{L}\p{M}'’]
		local
			l_category: STRING_8
		do
			if is_apostrophe (a_character) then
				Result := True
			else
				l_category := (create {SB_UNICODE}.make).general_category (a_character.natural_32_code)
				Result := l_category [1] = 'L' or l_category [1] = 'M'
			end
		end

	fold: SB_FOLD
		once
			create Result.make
		end

end
