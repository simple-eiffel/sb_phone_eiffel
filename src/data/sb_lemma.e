note
	description: "A Hebrew, Aramaic or Greek dictionary form."
	author: "Larry Rix"

class
	SB_LEMMA

create
	make

feature {NONE} -- Initialization

	make (a_id: INTEGER; a_language, a_headword, a_translit, a_pron, a_strongs, a_pos: STRING_32; a_count: INTEGER; a_number, a_hint: STRING_32)
			-- Create the lemma.
		do
			id := a_id
			language := a_language
			headword := a_headword
			translit := a_translit
			pron := a_pron
			strongs := a_strongs
			pos := a_pos
			count := a_count
			number := a_number
			hint := a_hint
		ensure
			id_set: id = a_id
			language_set: language = a_language
			headword_set: headword = a_headword
			translit_set: translit = a_translit
			pron_set: pron = a_pron
			strongs_set: strongs = a_strongs
			pos_set: pos = a_pos
			count_set: count = a_count
			number_set: number = a_number
			hint_set: hint = a_hint
		end

feature -- Access

	id: INTEGER
			-- The row id.

	language, headword, translit, pron, strongs, pos: STRING_32
			-- What it is.

	count: INTEGER
			-- How many times it occurs.

	number: STRING_32
			-- H1254a style for Hebrew (keeps homographs apart), Strong's for Greek.

	hint: STRING_32
			-- First gloss of the first lexicon, to tell homographs apart in lists.

	language_name: STRING_32
			-- The language, in words.
		do
			if language.same_string_general ("hbo") then
				Result := {STRING_32} "Hebrew"
			elseif language.same_string_general ("arc") then
				Result := {STRING_32} "Aramaic"
			else
				Result := {STRING_32} "Greek"
			end
		end

feature -- Status

	is_hebrew: BOOLEAN
			-- Is it Hebrew or Aramaic?
		do
			Result := language.same_string_general ("hbo") or else language.same_string_general ("arc")
		end

end
