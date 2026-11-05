note
	description: "[
		Reads loose references: "jn 3 16", "John 3:16", "1pet 1:3", "1 Peter 1", "ps 23",
		"Rom 8:28-30", "song 2". An ambiguous book ("ju 1": Judges or Jude) gives a choice,
		never a guess.
	]"
	author: "Larry Rix"

class
	SB_REF_PARSER

create
	make,
	make_with_rules

feature {NONE} -- Initialization

	make
			-- Create the parser with the rules of Kotlin on Android.
		do
			make_with_rules (create {SB_KOTLIN_RULES}.make_android)
		end

	make_with_rules (a_rules: SB_KOTLIN_RULES)
			-- Create the parser under `a_rules'.
		do
			rules := a_rules
			create pattern.make (a_rules)
			create books
		ensure
			rules_set: rules = a_rules
		end

feature -- Parsing

	parse (a_input: READABLE_STRING_32): SB_REF_PARSE
			-- `a_input' read as a reference.
		local
			l_books: ARRAYED_LIST [SB_BOOK]
			l_refs: ARRAYED_LIST [SB_REF]
			l_chapter, l_verse, l_verse_end, i: INTEGER
		do
			pattern.match (rules.unicode.lowercase (a_input))
			if pattern.is_matched then
				l_books := books_matching (pattern.book_part)
			else
				create l_books.make (0)
			end
			if l_books.is_empty then
				create {SB_REF_PARSE_NOT_A_REF} Result
			else
				l_chapter := rules.int_or (pattern.chapter_text, 1)
				l_verse := rules.int_or (pattern.verse_text, 0)
				l_verse_end := rules.int_or (pattern.verse_end_text, 0)
				if l_verse_end <= l_verse then
					l_verse_end := 0
				end
				create l_refs.make (l_books.count)
				from
					i := 1
				until
					i > l_books.count
				loop
					l_refs.extend (create {SB_REF}.make (l_books [i].id, l_chapter, l_verse, l_verse_end))
					i := i + 1
				end
				if l_refs.count = 1 then
					create {SB_REF_PARSE_ONE} Result.make (l_refs.first)
				else
					create {SB_REF_PARSE_CHOICE} Result.make (l_refs)
				end
			end
		end

	books_matching (a_typed: READABLE_STRING_32): ARRAYED_LIST [SB_BOOK]
			-- The book `a_typed' names exactly, or else every book whose name starts with it.
		local
			l_key: STRING_32
			i: INTEGER
		do
			l_key := normalized (a_typed)
			create Result.make (2)
			if not l_key.is_empty then
				if l_key.is_valid_as_string_8 and then attached exact_names.item (l_key.to_string_8) as al_book then
					Result.extend (al_book)
				else
					from
						i := 1
					until
						i > books.all_books.count
					loop
						if normalized (books.all_books [i].name).starts_with (l_key) then
							Result.extend (books.all_books [i])
						end
						i := i + 1
					end
				end
			end
		ensure
			nothing_for_nothing: normalized (a_typed).is_empty implies Result.is_empty
		end

feature {NONE} -- Implementation

	rules: SB_KOTLIN_RULES
			-- The character rules.

	pattern: SB_REF_PATTERN
			-- The reference pattern.

	books: SB_BOOKS
			-- The canon.

	normalized (a_text: READABLE_STRING_32): STRING_32
			-- `a_text' lowercased, without its dots and spaces.
		do
			Result := rules.unicode.lowercase (a_text)
			Result.prune_all ('.')
			Result.prune_all (' ')
		end

	exact_names: HASH_TABLE [SB_BOOK, STRING_8]
			-- Every name, short name, code and alias, normalized. A name given twice keeps the
			-- later book, as the Kotlin map does.
			-- The keys are STRING_8 on purpose: {STRING_32}.hash_code goes negative for text with
			-- characters past U+0FFF, and HASH_TABLE then reads outside its arrays. A typed emoji
			-- stopped the program that way. No name here has such a character, so text that is not
			-- valid as STRING_8 never needs to look.
		local
			l_book: SB_BOOK
			i, j: INTEGER
		once
			create Result.make (400)
			from
				i := 1
			until
				i > books.all_books.count
			loop
				l_book := books.all_books [i]
				Result.force (l_book, normalized (l_book.name).to_string_8)
				Result.force (l_book, normalized (l_book.short).to_string_8)
				Result.force (l_book, normalized (l_book.code).to_string_8)
				from
					j := 1
				until
					j > l_book.aliases.count
				loop
					Result.force (l_book, normalized (l_book.aliases [j]).to_string_8)
					j := j + 1
				end
				i := i + 1
			end
		end

end
