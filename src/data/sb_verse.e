note
	description: "One verse of one version."
	author: "Larry Rix"

class
	SB_VERSE

create
	make

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_version: STRING_32; a_book, a_chapter, a_verse, a_eng_key: INTEGER; a_text: STRING_32)
			-- Create the verse.
		do
			id := a_id
			version := a_version
			book := a_book
			chapter := a_chapter
			verse := a_verse
			eng_key := a_eng_key
			text := a_text
		ensure
			id_set: id = a_id
			version_set: version = a_version
			book_set: book = a_book
			chapter_set: chapter = a_chapter
			verse_set: verse = a_verse
			eng_key_set: eng_key = a_eng_key
			text_set: text = a_text
		end

feature -- Access

	id: INTEGER_64
			-- The row id.

	version: STRING_32
			-- The version's code.

	book, chapter, verse: INTEGER
			-- Its own address, in the numbering of its version.

	eng_key: INTEGER
			-- The key of the same verse in English numbering.

	text: STRING_32
			-- The text.

	own_label: STRING_32
			-- Its own number, shown when it differs from the English numbering (Hebrew versification).
		do
			create Result.make (8)
			Result.append_string_general (chapter.out + ":" + verse.out)
		end

feature -- Status

	differs_from_english: BOOLEAN
			-- Does its own address differ from its English key?
		do
			Result := (create {SB_REF}.make_verse (book, chapter, verse)).key /= eng_key
		end

end
