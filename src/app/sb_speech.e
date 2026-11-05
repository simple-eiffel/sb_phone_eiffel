note
	description: "One thing to read: a verse, a heading, a dictionary sense. A verse key lets the reader follow along."
	author: "Larry Rix"

class
	SB_SPEECH

create
	make, make_in, make_verse

feature {NONE} -- Initialization

	make (a_text, a_label: READABLE_STRING_32)
		do
			create text.make_from_string (a_text)
			create label.make_from_string (a_label)
			lang := Lang_english
		end

	make_in (a_text: READABLE_STRING_32; a_lang: INTEGER; a_label: READABLE_STRING_32)
		do
			make (a_text, a_label)
			lang := a_lang
		end

	make_verse (a_text: READABLE_STRING_32; a_lang, a_book, a_chapter, a_key: INTEGER; a_label: READABLE_STRING_32)
		do
			make_in (a_text, a_lang, a_label)
			is_verse := True
			book := a_book
			chapter := a_chapter
			key := a_key
		end

feature -- Access

	text, label: STRING_32

	lang: INTEGER

	is_verse: BOOLEAN

	book, chapter, key: INTEGER

feature -- Constants

	Lang_english: INTEGER = 1

	Lang_hebrew: INTEGER = 2

	Lang_greek: INTEGER = 3

	Lang_latin: INTEGER = 4

end
