note
	description: "One FTS match: a folded word, a folded phrase, or a folded prefix."
	author: "Larry Rix"

class
	SB_MATCH

inherit
	ANY
		redefine
			is_equal
		end

create
	make

feature {NONE} -- Initialization

	make (a_words: ARRAYED_LIST [STRING_32]; a_prefix: BOOLEAN)
			-- Create the match.
		do
			words := a_words
			is_prefix := a_prefix
		ensure
			words_set: words = a_words
			prefix_set: is_prefix = a_prefix
		end

feature -- Access

	words: ARRAYED_LIST [STRING_32]
			-- The folded words.

	is_prefix: BOOLEAN
			-- Does the last word match as a prefix?

feature -- Conversion

	fts: STRING_32
			-- The FTS4 MATCH expression for this match alone (standard query syntax only).
		require
			has_words: not words.is_empty
		local
			i: INTEGER
		do
			create Result.make (32)
			if words.count > 1 then
				Result.append_character ('"')
				from
					i := 1
				until
					i > words.count
				loop
					if i > 1 then
						Result.append_character (' ')
					end
					Result.append (words [i])
					i := i + 1
				end
				if is_prefix then
					Result.append_character ('*')
				end
				Result.append_character ('"')
			else
				Result.append (words.first)
				if is_prefix then
					Result.append_character ('*')
				end
			end
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same words, same prefix setting?
		local
			i: INTEGER
		do
			Result := is_prefix = a_other.is_prefix and words.count = a_other.words.count
			from
				i := 1
			until
				i > words.count or not Result
			loop
				Result := words [i].same_string (a_other.words [i])
				i := i + 1
			end
		end

feature -- Output

	debug_output: STRING_32
			-- The same text as Kotlin's toString on the data class.
		local
			i: INTEGER
		do
			create Result.make (32)
			Result.append_string_general ("Match(words=[")
			from
				i := 1
			until
				i > words.count
			loop
				if i > 1 then
					Result.append_string_general (", ")
				end
				Result.append (words [i])
				i := i + 1
			end
			Result.append_string_general ("], prefix=" + is_prefix.out.as_lower + ")")
		end

end
