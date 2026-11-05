note
	description: "One Hebrew or Greek word of a verse."
	author: "Larry Rix"

class
	SB_WORD

create
	make

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_eng_key, a_book, a_chapter, a_verse, a_pos: INTEGER; a_surface, a_after, a_translit, a_gloss: STRING_32; a_lemma: INTEGER; a_morph, a_parse: STRING_32)
			-- Create the word.
		do
			id := a_id
			eng_key := a_eng_key
			book := a_book
			chapter := a_chapter
			verse := a_verse
			pos := a_pos
			surface := a_surface
			after := a_after
			translit := a_translit
			gloss := a_gloss
			lemma := a_lemma
			morph := a_morph
			parse := a_parse
		ensure
			id_set: id = a_id
			eng_key_set: eng_key = a_eng_key
			book_set: book = a_book
			chapter_set: chapter = a_chapter
			verse_set: verse = a_verse
			pos_set: pos = a_pos
			surface_set: surface = a_surface
			after_set: after = a_after
			translit_set: translit = a_translit
			gloss_set: gloss = a_gloss
			lemma_set: lemma = a_lemma
			morph_set: morph = a_morph
			parse_set: parse = a_parse
		end

feature -- Access

	id: INTEGER_64
			-- The row id.

	eng_key, book, chapter, verse, pos: INTEGER
			-- Where it stands.

	surface, after, translit, gloss: STRING_32
			-- The word as written, what follows it, its transliteration and its gloss.

	lemma: INTEGER
			-- The id of its dictionary form.

	morph, parse: STRING_32
			-- Its morphology code and the same in words.

end
