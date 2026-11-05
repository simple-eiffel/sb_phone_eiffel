note
	description: "The 66 books, as listed in Books.kt, with every alias."
	author: "Larry Rix"

class
	SB_BOOKS

feature -- Access

	all_books: ARRAYED_LIST [SB_BOOK]
			-- All the books, in canon order.
		once
			create Result.make (66)
			add (Result, 1, "GEN", "Genesis", "Gen", <<"ge", "gn">>)
			add (Result, 2, "EXO", "Exodus", "Exod", <<"ex", "exo">>)
			add (Result, 3, "LEV", "Leviticus", "Lev", <<"le", "lv">>)
			add (Result, 4, "NUM", "Numbers", "Num", <<"nu", "nm", "nb">>)
			add (Result, 5, "DEU", "Deuteronomy", "Deut", <<"dt", "de">>)
			add (Result, 6, "JOS", "Joshua", "Josh", <<"jsh">>)
			add (Result, 7, "JDG", "Judges", "Judg", <<"jdgs", "jg">>)
			add (Result, 8, "RUT", "Ruth", "Ruth", <<"rth", "ru">>)
			add (Result, 9, "1SA", "1 Samuel", "1 Sam", <<"1sm", "1s", "isam", "1sam">>)
			add (Result, 10, "2SA", "2 Samuel", "2 Sam", <<"2sm", "2s", "iisam", "2sam">>)
			add (Result, 11, "1KI", "1 Kings", "1 Kgs", <<"1kg", "1k", "ikgs", "1kgs">>)
			add (Result, 12, "2KI", "2 Kings", "2 Kgs", <<"2kg", "2k", "iikgs", "2kgs">>)
			add (Result, 13, "1CH", "1 Chronicles", "1 Chr", <<"1chron", "ichr">>)
			add (Result, 14, "2CH", "2 Chronicles", "2 Chr", <<"2chron", "iichr">>)
			add (Result, 15, "EZR", "Ezra", "Ezra", <<"ezr">>)
			add (Result, 16, "NEH", "Nehemiah", "Neh", <<"ne">>)
			add (Result, 17, "EST", "Esther", "Esth", <<"es">>)
			add (Result, 18, "JOB", "Job", "Job", <<"jb">>)
			add (Result, 19, "PSA", "Psalms", "Ps", <<"psalm", "pslm", "psa", "psm", "pss">>)
			add (Result, 20, "PRO", "Proverbs", "Prov", <<"pr", "prv">>)
			add (Result, 21, "ECC", "Ecclesiastes", "Eccl", <<"ec", "eccles", "qoh">>)
			add (Result, 22, "SNG", "Song of Songs", "Song", <<"song of solomon", "sos", "so", "canticles", "cant">>)
			add (Result, 23, "ISA", "Isaiah", "Isa", <<"is">>)
			add (Result, 24, "JER", "Jeremiah", "Jer", <<"je", "jr">>)
			add (Result, 25, "LAM", "Lamentations", "Lam", <<"la">>)
			add (Result, 26, "EZK", "Ezekiel", "Ezek", <<"eze", "ezk">>)
			add (Result, 27, "DAN", "Daniel", "Dan", <<"da", "dn">>)
			add (Result, 28, "HOS", "Hosea", "Hos", <<"ho">>)
			add (Result, 29, "JOL", "Joel", "Joel", <<"jl">>)
			add (Result, 30, "AMO", "Amos", "Amos", <<"am">>)
			add (Result, 31, "OBA", "Obadiah", "Obad", <<"ob">>)
			add (Result, 32, "JON", "Jonah", "Jonah", <<"jnh">>)
			add (Result, 33, "MIC", "Micah", "Mic", <<"mc">>)
			add (Result, 34, "NAM", "Nahum", "Nah", <<"na">>)
			add (Result, 35, "HAB", "Habakkuk", "Hab", <<"hb">>)
			add (Result, 36, "ZEP", "Zephaniah", "Zeph", <<"zp">>)
			add (Result, 37, "HAG", "Haggai", "Hag", <<"hg">>)
			add (Result, 38, "ZEC", "Zechariah", "Zech", <<"zc">>)
			add (Result, 39, "MAL", "Malachi", "Mal", <<"ml">>)
			add (Result, 40, "MAT", "Matthew", "Matt", <<"mt">>)
			add (Result, 41, "MRK", "Mark", "Mark", <<"mk", "mrk", "mr">>)
			add (Result, 42, "LUK", "Luke", "Luke", <<"lk", "lu">>)
			add (Result, 43, "JHN", "John", "John", <<"jn", "jhn", "joh">>)
			add (Result, 44, "ACT", "Acts", "Acts", <<"ac">>)
			add (Result, 45, "ROM", "Romans", "Rom", <<"ro", "rm">>)
			add (Result, 46, "1CO", "1 Corinthians", "1 Cor", <<"icor", "1cor">>)
			add (Result, 47, "2CO", "2 Corinthians", "2 Cor", <<"iicor", "2cor">>)
			add (Result, 48, "GAL", "Galatians", "Gal", <<"ga">>)
			add (Result, 49, "EPH", "Ephesians", "Eph", <<"ephes">>)
			add (Result, 50, "PHP", "Philippians", "Phil", <<"php", "pp">>)
			add (Result, 51, "COL", "Colossians", "Col", {ARRAY [STRING_8]} <<>>)
			add (Result, 52, "1TH", "1 Thessalonians", "1 Thess", <<"1th", "ithess", "1thes">>)
			add (Result, 53, "2TH", "2 Thessalonians", "2 Thess", <<"2th", "iithess", "2thes">>)
			add (Result, 54, "1TI", "1 Timothy", "1 Tim", <<"1tm", "itim">>)
			add (Result, 55, "2TI", "2 Timothy", "2 Tim", <<"2tm", "iitim">>)
			add (Result, 56, "TIT", "Titus", "Titus", <<"ti">>)
			add (Result, 57, "PHM", "Philemon", "Phlm", <<"philem", "phm", "pm">>)
			add (Result, 58, "HEB", "Hebrews", "Heb", <<"he">>)
			add (Result, 59, "JAS", "James", "Jas", <<"jm", "ja">>)
			add (Result, 60, "1PE", "1 Peter", "1 Pet", <<"1pt", "1p", "ipet", "1pet">>)
			add (Result, 61, "2PE", "2 Peter", "2 Pet", <<"2pt", "2p", "iipet", "2pet">>)
			add (Result, 62, "1JN", "1 John", "1 John", <<"1jn", "1jhn", "ijn", "1jo">>)
			add (Result, 63, "2JN", "2 John", "2 John", <<"2jn", "2jhn", "iijn", "2jo">>)
			add (Result, 64, "3JN", "3 John", "3 John", <<"3jn", "3jhn", "iiijn", "3jo">>)
			add (Result, 65, "JUD", "Jude", "Jude", <<"jud", "jd">>)
			add (Result, 66, "REV", "Revelation", "Rev", <<"re", "rv", "apocalypse", "revelations">>)
		ensure
			all_there: Result.count = 66
		end

	by_id (a_id: INTEGER): SB_BOOK
			-- The book numbered `a_id'.
		require
			known: has_id (a_id)
		do
			Result := all_books [a_id]
		ensure
			right_book: Result.id = a_id
		end

	by_id_or_void (a_id: INTEGER): detachable SB_BOOK
			-- The book numbered `a_id', if there is one.
		do
			if has_id (a_id) then
				Result := by_id (a_id)
			end
		end

	by_code (a_code: READABLE_STRING_32): detachable SB_BOOK
			-- The book with the code `a_code', in any case.
		local
			l_code: STRING_32
			i: INTEGER
		do
			l_code := code_uppercase (a_code)
			from
				i := 1
			until
				i > all_books.count or Result /= Void
			loop
				if all_books [i].code.same_string (l_code) then
					Result := all_books [i]
				end
				i := i + 1
			end
		end

feature -- Status

	has_id (a_id: INTEGER): BOOLEAN
			-- Is `a_id' a book number?
		do
			Result := a_id >= 1 and a_id <= 66
		end

feature {NONE} -- Implementation

	add (a_list: ARRAYED_LIST [SB_BOOK]; a_id: INTEGER; a_code, a_name, a_short: STRING_8; a_aliases: ARRAY [STRING_8])
			-- Add a book to `a_list'.
		do
			a_list.extend (create {SB_BOOK}.make (a_id, a_code, a_name, a_short, a_aliases))
		end

	code_uppercase (a_text: READABLE_STRING_32): STRING_32
			-- `a_text' as Kotlin's uppercase () gives it, for comparing with an ASCII book code.
			-- Only text that ends up all ASCII can match, so only the characters whose uppercase
			-- is all ASCII are mapped: a to z, dotless i, long s, sharp s and the Latin ligatures.
			-- Any other character stays, and fails the comparison as its uppercase would.
		local
			i: INTEGER
			l_code: NATURAL_32
		do
			create Result.make (a_text.count)
			from
				i := 1
			until
				i > a_text.count
			loop
				l_code := a_text.code (i)
				if l_code >= 0x61 and l_code <= 0x7A then
					Result.append_code (l_code - 32)
				else
					inspect
						l_code
					when 0x131 then
						Result.append_string_general ("I")
					when 0x17F then
						Result.append_string_general ("S")
					when 0xDF then
						Result.append_string_general ("SS")
					when 0xFB00 then
						Result.append_string_general ("FF")
					when 0xFB01 then
						Result.append_string_general ("FI")
					when 0xFB02 then
						Result.append_string_general ("FL")
					when 0xFB03 then
						Result.append_string_general ("FFI")
					when 0xFB04 then
						Result.append_string_general ("FFL")
					when 0xFB05, 0xFB06 then
						Result.append_string_general ("ST")
					else
						Result.append_code (l_code)
					end
				end
				i := i + 1
			end
		end

end
