note
	description: "A verse address. `verse' 0 means the whole chapter."
	author: "Larry Rix"

class
	SB_REF

create
	make,
	make_verse,
	make_from_key

feature {NONE} -- Initialization

	make (a_book, a_chapter, a_verse, a_verse_end: INTEGER)
			-- Create the address, with its last verse.
		do
			book := a_book
			chapter := a_chapter
			verse := a_verse
			verse_end := a_verse_end
		ensure
			book_set: book = a_book
			chapter_set: chapter = a_chapter
			verse_set: verse = a_verse
			verse_end_set: verse_end = a_verse_end
		end

	make_verse (a_book, a_chapter, a_verse: INTEGER)
			-- Create the address of one verse.
		do
			make (a_book, a_chapter, a_verse, 0)
		ensure
			no_end: verse_end = 0
		end

	make_from_key (a_key: INTEGER)
			-- Create the address from its `key'.
		do
			make (a_key // 1_000_000, (a_key // 1_000) \\ 1_000, a_key \\ 1_000, 0)
		ensure
			no_end: verse_end = 0
		end

feature -- Access

	book, chapter, verse, verse_end: INTEGER
			-- The address.

	key: INTEGER
			-- One integer per verse: book * 1,000,000 + chapter * 1,000 + verse.
		do
			Result := key_of (book, chapter, verse)
		end

	key_of (a_book, a_chapter, a_verse: INTEGER): INTEGER
			-- The key of an address. It wraps as a Kotlin Int does, for a chapter too large to fit.
		do
			Result := (a_book.to_integer_64 * 1_000_000 + a_chapter.to_integer_64 * 1_000 + a_verse.to_integer_64).as_integer_32
		end

feature -- Status

	has_known_book: BOOLEAN
			-- Is `book' a book of the canon?
		do
			Result := books.has_id (book)
		end

feature -- Labels

	label: STRING_32
			-- The address with the book's full name.
		require
			known_book: has_known_book
		do
			Result := label_with (books.by_id (book).name)
		end

	short_label: STRING_32
			-- The address with the book's short name.
		require
			known_book: has_known_book
		do
			Result := label_with (books.by_id (book).short)
		end

feature -- Output

	debug_output: STRING_32
			-- The same text as Kotlin's toString on the data class.
		do
			create Result.make (48)
			Result.append_string_general ("Ref(book=" + book.out + ", chapter=" + chapter.out + ", verse=" + verse.out + ", verseEnd=" + verse_end.out + ")")
		end

feature {NONE} -- Implementation

	books: SB_BOOKS
			-- The canon.
		once
			create Result
		end

	label_with (a_name: STRING_32): STRING_32
			-- The address after the book name `a_name'.
		do
			create Result.make (a_name.count + 12)
			Result.append (a_name)
			Result.append_string_general (" " + chapter.out)
			if verse /= 0 then
				Result.append_string_general (":" + verse.out)
				if verse_end > verse then
					Result.append_string_general ("-" + verse_end.out)
				end
			end
		end

end
