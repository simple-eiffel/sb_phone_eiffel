note
	description: "[
		The shipped Bible database (app.db), read only. One to one with AppDb.kt: the same SQL in the
		same order. The app shell puts the file in place; this class only reads it.

		Android's SQLite is built with ICU, and the SQLite here is not. That changes one thing the
		Kotlin code relies on: LIKE ignores case for all of Unicode there. The columns matched
		with LIKE hold case-folded text, so folding the pattern here (`like_prefix') gives the same
		rows.
	]"
	author: "Larry Rix"

class
	SB_APP_DB

create
	make

feature {NONE} -- Initialization

	make (a_path: READABLE_STRING_GENERAL)
			-- Open the database at `a_path' and read the versions and the books.
		require
			path_not_empty: not a_path.is_empty
			exists: (create {RAW_FILE}.make_with_name (a_path)).exists
		do
			create sql.make_read_only (a_path)
			create fold.make
			create kotlin.make
			create versions.make (12)
			create books.make (66)
			create chapters.make (1189)
			create chapter_index.make (1189)
			read_versions
			read_books
			read_chapters
		end

	read_versions
			-- Fill `versions'.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_row: SIMPLE_SQL_ROW
			i: INTEGER
		do
			l_rows := sql.rows ("SELECT code, name, language, rtl, versification, coverage, first_id, last_id FROM version ORDER BY ord", no_args)
			from
				i := 1
			until
				i > l_rows.count
			loop
				l_row := l_rows [i]
				versions.extend (create {SB_VERSION}.make (sql.text (l_row, 1), sql.text (l_row, 2), sql.text (l_row, 3), sql.flag (l_row, 4),
					sql.text (l_row, 5), sql.text (l_row, 6), sql.long (l_row, 7), sql.long (l_row, 8)))
				i := i + 1
			end
		end

	read_books
			-- Fill `books'.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_row: SIMPLE_SQL_ROW
			i: INTEGER
		do
			l_rows := sql.rows ("SELECT id, code, name, short, chapters FROM book ORDER BY id", no_args)
			from
				i := 1
			until
				i > l_rows.count
			loop
				l_row := l_rows [i]
				books.extend (create {SB_BOOK_INFO}.make (sql.integer (l_row, 1), sql.text (l_row, 2), sql.text (l_row, 3), sql.text (l_row, 4), sql.integer (l_row, 5)))
				i := i + 1
			end
		end

	read_chapters
			-- Fill `chapters' and `chapter_index'.
		local
			i, j: INTEGER
			l_book: SB_BOOK_INFO
		do
			from
				i := 1
			until
				i > books.count
			loop
				l_book := books [i]
				from
					j := 1
				until
					j > l_book.chapters
				loop
					chapters.extend ([l_book.id, j])
					chapter_index.force (chapters.count, chapter_key (l_book.id, j))
					j := j + 1
				end
				i := i + 1
			end
		end

feature -- Access

	versions: ARRAYED_LIST [SB_VERSION]
			-- Every version, in version order.

	books: ARRAYED_LIST [SB_BOOK_INFO]
			-- Every book, in canon order.

	chapters: ARRAYED_LIST [TUPLE [book, chapter: INTEGER]]
			-- Every chapter in canon order: the pages of the reader, from page 1.

	version (a_code: READABLE_STRING_GENERAL): SB_VERSION
			-- The version with code `a_code', or the first if there is none.
		local
			i: INTEGER
			l_found: detachable SB_VERSION
		do
			from
				i := 1
			until
				i > versions.count or l_found /= Void
			loop
				if versions [i].code.same_string_general (a_code) then
					l_found := versions [i]
				end
				i := i + 1
			end
			if attached l_found as al_found then
				Result := al_found
			else
				Result := versions.first
			end
		end

	has_book (a_id: INTEGER): BOOLEAN
			-- Is there a book with id `a_id'?
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > books.count or Result
			loop
				Result := books [i].id = a_id
				i := i + 1
			end
		end

	book (a_id: INTEGER): SB_BOOK_INFO
			-- The book with id `a_id'.
		require
			known: has_book (a_id)
		local
			i: INTEGER
			l_found: detachable SB_BOOK_INFO
		do
			from
				i := 1
			until
				i > books.count or l_found /= Void
			loop
				if books [i].id = a_id then
					l_found := books [i]
				end
				i := i + 1
			end
			check found: attached l_found as al_found then
				Result := al_found
			end
		end

	page_of (a_book, a_chapter: INTEGER): INTEGER
			-- The page (from 1) of a chapter, else of the book's first chapter, else 1.
		do
			Result := chapter_index [chapter_key (a_book, a_chapter)]
			if Result = 0 then
				Result := chapter_index [chapter_key (a_book, 1)]
			end
			if Result = 0 then
				Result := 1
			end
		ensure
			a_page: Result >= 1 and Result <= chapters.count.max (1)
		end

feature -- Verses

	verses_in_chapter (a_version: READABLE_STRING_GENERAL; a_book, a_chapter: INTEGER): ARRAYED_LIST [SB_VERSE]
			-- The verses of a chapter (English numbering) in one version.
		local
			l_ref: SB_REF
		do
			create l_ref.make_verse (a_book, a_chapter, 0)
			Result := verses (Verse_columns + " FROM verse WHERE eng_key BETWEEN ? AND ? AND version = ? ORDER BY eng_key, id",
				<<l_ref.key_of (a_book, a_chapter, 0), l_ref.key_of (a_book, a_chapter, 999), a_version>>)
		end

	verses_at (a_eng_key: INTEGER; a_version: detachable READABLE_STRING_GENERAL): ARRAYED_LIST [SB_VERSE]
			-- The verses at one key in `a_version', or in every version when it is Void.
		do
			if attached a_version as al_version then
				Result := verses (Verse_columns + " FROM verse WHERE eng_key = ? AND version = ? ORDER BY id", <<a_eng_key, al_version>>)
			else
				Result := verses ("SELECT v.id, v.version, v.book, v.chapter, v.verse, v.eng_key, v.text FROM verse v JOIN version n ON n.code = v.version WHERE v.eng_key = ? ORDER BY n.ord, v.id", <<a_eng_key>>)
			end
		end

	preview_text (a_ref: SB_REF; a_version: READABLE_STRING_GENERAL): STRING_32
			-- The text of a reference (a verse or a range) in one version, for previews.
		local
			l_low, l_high, i: INTEGER
			l_verses: ARRAYED_LIST [SB_VERSE]
		do
			l_low := a_ref.key_of (a_ref.book, a_ref.chapter, a_ref.verse)
			if a_ref.verse_end > a_ref.verse then
				l_high := a_ref.key_of (a_ref.book, a_ref.chapter, a_ref.verse_end)
			else
				l_high := l_low
			end
			l_verses := verses (Verse_columns + " FROM verse WHERE eng_key BETWEEN ? AND ? AND version = ? ORDER BY eng_key, id", <<l_low, l_high, a_version>>)
			create Result.make (256)
			from
				i := 1
			until
				i > l_verses.count
			loop
				if i > 1 then
					Result.append_code (32)
				end
				Result.append (l_verses [i].text)
				i := i + 1
			end
		end

feature -- Words

	words (a_eng_key: INTEGER): ARRAYED_LIST [SB_WORD]
			-- The Hebrew or Greek words of a verse.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_row: SIMPLE_SQL_ROW
			i: INTEGER
		do
			l_rows := sql.rows ("SELECT id, eng_key, book, chapter, verse, pos, surface, after, translit, gloss, lemma, morph, parse FROM word WHERE eng_key = ? ORDER BY id", <<a_eng_key>>)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				l_row := l_rows [i]
				Result.extend (create {SB_WORD}.make (sql.long (l_row, 1), sql.integer (l_row, 2), sql.integer (l_row, 3), sql.integer (l_row, 4), sql.integer (l_row, 5), sql.integer (l_row, 6),
					sql.text (l_row, 7), sql.text (l_row, 8), sql.text (l_row, 9), sql.text (l_row, 10), sql.integer (l_row, 11), sql.text (l_row, 12), sql.text (l_row, 13)))
				i := i + 1
			end
		end

	lemma (a_id: INTEGER): detachable SB_LEMMA
			-- The lemma with id `a_id', if any.
		local
			l_lemmas: ARRAYED_LIST [SB_LEMMA]
		do
			l_lemmas := lemmas (Lemma_columns + " FROM lemma WHERE id = ?", <<a_id>>)
			if not l_lemmas.is_empty then
				Result := l_lemmas.first
			end
		end

	lemmas_by_strongs (a_number: READABLE_STRING_GENERAL): ARRAYED_LIST [SB_LEMMA]
			-- The lemmas with a Strong's number: by the extended number, else exactly, else its
			-- homographs (H1254 finds H1254a, H1254b).
		local
			l_bare: STRING_32
			l_found: ARRAYED_LIST [SB_LEMMA]
			i: INTEGER
		do
			Result := lemmas (Lemma_columns + " FROM lemma WHERE number = ? AND number <> strongs ORDER BY count DESC", <<a_number>>)
			if Result.is_empty then
				Result := lemmas (Lemma_columns + " FROM lemma WHERE strongs = ? ORDER BY count DESC", <<a_number>>)
			end
			if Result.is_empty then
				l_bare := kotlin.without_lower_letters_at_end (a_number.to_string_32)
				l_found := lemmas (Lemma_columns + " FROM lemma WHERE strongs = ? OR strongs LIKE ? ORDER BY count DESC", <<l_bare, like_prefix (l_bare)>>)
				create Result.make (l_found.count)
				from
					i := 1
				until
					i > l_found.count
				loop
					if kotlin.is_all_letters (kotlin.without_prefix (l_found [i].strongs, l_bare)) then
						Result.extend (l_found [i])
					end
					i := i + 1
				end
			end
		end

	lemmas_matching (a_folded, a_ascii: READABLE_STRING_GENERAL): ARRAYED_LIST [SB_LEMMA]
			-- Original words whose dictionary form matches what was typed, in Hebrew or Greek
			-- letters or in plain Latin letters ("bara", "logos").
		do
			Result := lemmas (Lemma_columns + " FROM lemma WHERE fold = ? OR ascii = ? OR fold LIKE ? OR ascii LIKE ? ORDER BY (fold = ? OR ascii = ?) DESC, count DESC LIMIT 30",
				<<a_folded, a_ascii, like_prefix (a_folded), like_prefix (a_ascii), a_folded, a_ascii>>)
		end

	senses (a_lemma: INTEGER): ARRAYED_LIST [SB_SENSE]
			-- What the dictionaries say of a lemma.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_row: SIMPLE_SQL_ROW
			i: INTEGER
		do
			l_rows := sql.rows ("SELECT source, entry, depth, label, gloss, text, domain, note FROM sense WHERE lemma = ? ORDER BY rowid", <<a_lemma>>)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				l_row := l_rows [i]
				Result.extend (create {SB_SENSE}.make (sql.text (l_row, 1), sql.text (l_row, 2), sql.integer (l_row, 3), sql.text (l_row, 4), sql.text (l_row, 5), sql.text (l_row, 6), sql.text (l_row, 7), sql.text (l_row, 8)))
				i := i + 1
			end
		end

	renderings (a_lemma: INTEGER): ARRAYED_LIST [SB_RENDERING]
			-- How the KJV translates a word: English dictionary forms with how many times.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			i: INTEGER
		do
			l_rows := sql.rows ("SELECT coalesce(f.lemma, k.fold) AS w, COUNT(*) AS n FROM kjv_word k LEFT JOIN eng_form f ON f.fold = k.fold WHERE k.lemma = ? GROUP BY w ORDER BY n DESC", <<a_lemma>>)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				Result.extend (create {SB_RENDERING}.make (sql.text (l_rows [i], 1), sql.integer (l_rows [i], 2)))
				i := i + 1
			end
		end

	occurrences (a_lemma: INTEGER): ARRAYED_LIST [TUPLE [eng_key: INTEGER; gloss: STRING_32]]
			-- Every place a word occurs: English verse key and the word's gloss there, in canon order.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			i: INTEGER
		do
			l_rows := sql.rows ("SELECT eng_key, gloss FROM word WHERE lemma = ? ORDER BY id", <<a_lemma>>)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				Result.extend ([sql.integer (l_rows [i], 1), sql.text (l_rows [i], 2)])
				i := i + 1
			end
		end

	kjv_lemmas (a_eng_key: INTEGER; a_fold: READABLE_STRING_GENERAL; a_nth: INTEGER): ARRAYED_LIST [SB_LEMMA]
			-- The Hebrew or Greek words a KJV word translates: the `a_nth' occurrence of folded word `a_fold' in the verse.
		do
			Result := lemmas (Lemma_columns + " FROM lemma WHERE id IN (SELECT lemma FROM kjv_word WHERE eng_key = ? AND fold = ? AND nth = ?) ORDER BY count DESC", <<a_eng_key, a_fold, a_nth>>)
		end

	kjv_linked (a_eng_key: INTEGER): ARRAYED_LIST [TUPLE [fold: STRING_32; nth: INTEGER]]
			-- Fold and nth of every KJV word in a verse that links to an original word.
			-- Kotlin has a set; `has_kjv_link' asks what `in' asks there.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			i: INTEGER
		do
			l_rows := sql.rows ("SELECT DISTINCT fold, nth FROM kjv_word WHERE eng_key = ?", <<a_eng_key>>)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				Result.extend ([sql.text (l_rows [i], 1), sql.integer (l_rows [i], 2)])
				i := i + 1
			end
		end

	has_kjv_link (a_linked: like kjv_linked; a_fold: READABLE_STRING_GENERAL; a_nth: INTEGER): BOOLEAN
			-- Does `a_linked' hold the `a_nth' occurrence of `a_fold'?
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_linked.count or Result
			loop
				Result := a_linked [i].nth = a_nth and then a_linked [i].fold.same_string_general (a_fold)
				i := i + 1
			end
		end

	shifted_in (a_eng_key: INTEGER): ARRAYED_LIST [STRING_32]
			-- Words in this verse that Wright (1884) lists as having changed meaning since the KJV,
			-- each once, and compared by value.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			i: INTEGER
			l_word: STRING_32
		do
			l_rows := sql.rows ("SELECT fold FROM eng_shift WHERE eng_key = ?", <<a_eng_key>>)
			create Result.make (l_rows.count)
			Result.compare_objects
			from
				i := 1
			until
				i > l_rows.count
			loop
				l_word := sql.text (l_rows [i], 1)
				if not Result.has (l_word) then
					Result.extend (l_word)
				end
				i := i + 1
			end
		end

	english_entry (a_fold: READABLE_STRING_GENERAL): SB_ENGLISH_ENTRY
			-- An English word with all its KJV forms ("love": love, loved, loveth), from the folded form typed or tapped.
		local
			l_fold, l_lemma: STRING_32
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_forms: ARRAYED_LIST [STRING_32]
			l_lookups: ARRAYED_LIST [STRING_32]
			l_behind: ARRAYED_LIST [SB_BEHIND]
			l_senses: ARRAYED_LIST [SB_ENGLISH_SENSE]
			l_shifts: ARRAYED_LIST [INTEGER]
			l_seen: HASH_TABLE [BOOLEAN, STRING_8]
			l_sense: SB_ENGLISH_SENSE
			l_row: SIMPLE_SQL_ROW
			l_marks, l_key: STRING_8
			i, j: INTEGER
		do
			l_fold := a_fold.to_string_32
			l_rows := sql.rows ("SELECT lemma FROM eng_form WHERE fold = ?", <<l_fold>>)
			if l_rows.is_empty then
				l_lemma := l_fold
			else
				l_lemma := sql.text (l_rows.first, 1)
			end
			l_rows := sql.rows ("SELECT fold FROM eng_form WHERE lemma = ? ORDER BY fold", <<l_lemma>>)
			create l_forms.make (l_rows.count + 1)
			l_forms.compare_objects
			from
				i := 1
			until
				i > l_rows.count
			loop
				extend_once (l_forms, sql.text (l_rows [i], 1))
				i := i + 1
			end
			extend_once (l_forms, l_fold)
			l_marks := sql_list (l_forms)
			l_rows := sql.rows ("SELECT l.id, l.language, l.headword, l.translit, l.pron, l.strongs, l.pos, l.count, l.number, l.hint, COUNT(*) AS n FROM kjv_word k JOIN lemma l ON l.id = k.lemma WHERE k.fold IN (" + l_marks + ") GROUP BY l.id ORDER BY n DESC", no_args)
			create l_behind.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				l_behind.extend (create {SB_BEHIND}.make (lemma_from (l_rows [i]), sql.integer (l_rows [i], 11)))
				i := i + 1
			end
				-- Dictionaries are keyed by headword, so look up the dictionary form first, then the forms.
			create l_lookups.make (l_forms.count + 1)
			l_lookups.compare_objects
			l_lookups.extend (l_lemma)
			from
				i := 1
			until
				i > l_forms.count
			loop
				extend_once (l_lookups, l_forms [i])
				i := i + 1
			end
			create l_senses.make (16)
			create l_seen.make (64)
			from
				i := 1
			until
				i > l_lookups.count
			loop
				l_rows := sql.rows ("SELECT source, year, sense_no, pos, text, cite FROM eng_sense WHERE fold = ? ORDER BY rowid", <<l_lookups [i]>>)
				from
					j := 1
				until
					j > l_rows.count
				loop
					l_row := l_rows [j]
					create l_sense.make (sql.text (l_row, 1), sql.text (l_row, 2), sql.text (l_row, 3), sql.text (l_row, 4), sql.text (l_row, 5), sql.text (l_row, 6))
					l_key := sense_key (l_sense)
					if not l_seen.has (l_key) then
						l_seen.force (True, l_key)
						l_senses.extend (l_sense)
					end
					j := j + 1
				end
				i := i + 1
			end
			l_rows := sql.rows ("SELECT DISTINCT eng_key FROM eng_shift WHERE fold IN (" + l_marks + ") ORDER BY eng_key", no_args)
			create l_shifts.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				l_shifts.extend (sql.integer (l_rows [i], 1))
				i := i + 1
			end
			create Result.make (l_lemma, l_forms, l_behind, l_senses, l_shifts)
		end

feature -- Timeline and atlas

	lanes: ARRAYED_LIST [SB_LANE]
			-- The lanes of the timeline.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			i: INTEGER
		do
			l_rows := sql.rows ("SELECT id, title, grp FROM tl_lane ORDER BY sort", no_args)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				Result.extend (create {SB_LANE}.make (sql.text (l_rows [i], 1), sql.text (l_rows [i], 2), sql.text (l_rows [i], 3)))
				i := i + 1
			end
		end

	events (a_lane: detachable READABLE_STRING_GENERAL): ARRAYED_LIST [SB_TL_EVENT]
			-- The events of `a_lane', or of every lane when it is Void.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_row: SIMPLE_SQL_ROW
			i: INTEGER
		do
			if attached a_lane as al_lane then
				l_rows := sql.rows ("SELECT id, lane, title, kind, importance, summary, status, earliest, latest, label FROM tl_event WHERE lane = ? ORDER BY earliest, latest", <<al_lane>>)
			else
				l_rows := sql.rows ("SELECT id, lane, title, kind, importance, summary, status, earliest, latest, label FROM tl_event ORDER BY earliest, latest", no_args)
			end
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				l_row := l_rows [i]
				Result.extend (create {SB_TL_EVENT}.make (sql.text (l_row, 1), sql.text (l_row, 2), sql.text (l_row, 3), sql.text (l_row, 4), sql.integer (l_row, 5),
					sql.text (l_row, 6), sql.text (l_row, 7), sql.integer (l_row, 8), sql.integer (l_row, 9), sql.text (l_row, 10)))
				i := i + 1
			end
		end

	claims (a_event: READABLE_STRING_GENERAL): ARRAYED_LIST [SB_TL_CLAIM]
			-- The dating claims of an event.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_row: SIMPLE_SQL_ROW
			i: INTEGER
		do
			l_rows := sql.rows ("SELECT c.label, c.chronology, c.held_by, c.basis, c.lean, c.note, COALESCE(t.text, '') FROM tl_claim c LEFT JOIN tl_citation t ON t.id = c.citation WHERE c.event = ? ORDER BY c.ordinal", <<a_event>>)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				l_row := l_rows [i]
				Result.extend (create {SB_TL_CLAIM}.make (sql.text (l_row, 1), sql.text (l_row, 2), sql.text (l_row, 3), sql.text (l_row, 4), sql.flag (l_row, 5), sql.text (l_row, 6), sql.text (l_row, 7)))
				i := i + 1
			end
		end

	places (a_event: detachable READABLE_STRING_GENERAL): ARRAYED_LIST [SB_PLACE]
			-- The places of `a_event', or every place when it is Void.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_row: SIMPLE_SQL_ROW
			i: INTEGER
		do
			if attached a_event as al_event then
				l_rows := sql.rows ("SELECT p.id, p.name, p.kind, p.min_zoom, p.lon, p.lat FROM tl_place p JOIN tl_event_place e ON e.place = p.id WHERE e.event = ?", <<al_event>>)
			else
				l_rows := sql.rows ("SELECT id, name, kind, min_zoom, lon, lat FROM tl_place", no_args)
			end
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				l_row := l_rows [i]
				Result.extend (create {SB_PLACE}.make (sql.text (l_row, 1), sql.text (l_row, 2), sql.text (l_row, 3), sql.integer (l_row, 4),
					sql.real (l_row, 5).truncated_to_real, sql.real (l_row, 6).truncated_to_real))
				i := i + 1
			end
		end

	land: ARRAYED_LIST [TUPLE [kind: STRING_32; ring: ARRAY [REAL_32]]]
			-- Land and lake outlines for the base map, decoded once.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_land: like land
			i: INTEGER
		do
			if attached land_cache as al_land then
				Result := al_land
			else
				l_rows := sql.rows ("SELECT kind, ring FROM atlas_land", no_args)
				create l_land.make (l_rows.count)
				from
					i := 1
				until
					i > l_rows.count
				loop
					l_land.extend ([sql.text (l_rows [i], 1), sql.floats (l_rows [i], 2)])
					i := i + 1
				end
				land_cache := l_land
				Result := l_land
			end
		end

	areas (a_year: INTEGER): ARRAYED_LIST [SB_AREA]
			-- The empires standing in an astronomical year.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_row: SIMPLE_SQL_ROW
			i: INTEGER
		do
			l_rows := sql.rows ("SELECT name, year_from, year_to, ring FROM atlas_area WHERE year_from <= ? AND year_to >= ?", <<a_year, a_year>>)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				l_row := l_rows [i]
				Result.extend (create {SB_AREA}.make (sql.text (l_row, 1), sql.integer (l_row, 2), sql.integer (l_row, 3), sql.floats (l_row, 4)))
				i := i + 1
			end
		end

feature -- Cross-references and sources

	xrefs (a_eng_key: INTEGER): ARRAYED_LIST [SB_XREF]
			-- The cross-references of a verse, up to 80, by votes.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			i: INTEGER
		do
			l_rows := sql.rows ("SELECT to_key, to_end, votes FROM xref WHERE from_key = ? ORDER BY votes DESC LIMIT 80", <<a_eng_key>>)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				Result.extend (create {SB_XREF}.make (sql.integer (l_rows [i], 1), sql.integer (l_rows [i], 2), sql.integer (l_rows [i], 3)))
				i := i + 1
			end
		end

	sources: ARRAYED_LIST [SB_SOURCE_INFO]
			-- Every source, in order, read once.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_row: SIMPLE_SQL_ROW
			l_sources: like sources
			i: INTEGER
		do
			if attached sources_cache as al_sources then
				Result := al_sources
			else
				l_rows := sql.rows ("SELECT code, name, kind, license, credit, url, share_alike FROM source ORDER BY ord", no_args)
				create l_sources.make (l_rows.count)
				from
					i := 1
				until
					i > l_rows.count
				loop
					l_row := l_rows [i]
					l_sources.extend (create {SB_SOURCE_INFO}.make (sql.text (l_row, 1), sql.text (l_row, 2), sql.text (l_row, 3), sql.text (l_row, 4), sql.text (l_row, 5), sql.text (l_row, 6), sql.flag (l_row, 7)))
					i := i + 1
				end
				sources_cache := l_sources
				Result := l_sources
			end
		end

	source (a_code: READABLE_STRING_GENERAL): detachable SB_SOURCE_INFO
			-- The source with code `a_code', if any.
		local
			l_sources: like sources
			i: INTEGER
		do
			l_sources := sources
			from
				i := 1
			until
				i > l_sources.count or Result /= Void
			loop
				if l_sources [i].code.same_string_general (a_code) then
					Result := l_sources [i]
				end
				i := i + 1
			end
		end

	meta (a_key: READABLE_STRING_GENERAL): detachable STRING_32
			-- The value of `a_key' in table meta, if any.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
		do
			l_rows := sql.rows ("SELECT value FROM meta WHERE key = ?", <<a_key>>)
			if not l_rows.is_empty then
				Result := sql.text (l_rows.first, 1)
			end
		end

feature -- Search

	Default_limit: INTEGER = 400
			-- How many results `search' shows.

	search (a_query: SB_SEARCH_QUERY; a_version: detachable READABLE_STRING_GENERAL): SB_SEARCH_RESULT
			-- `search_limited' with the default limit.
		do
			Result := search_limited (a_query, a_version, Default_limit)
		end

	search_limited (a_query: SB_SEARCH_QUERY; a_version: detachable READABLE_STRING_GENERAL; a_limit: INTEGER): SB_SEARCH_RESULT
			-- Run a search in `a_version', or in every version when it is Void. Each match is its own
			-- FTS query; the AND, OR and NOT logic is done here.
		require
			limit_not_negative: a_limit >= 0
		do
			if a_query.has_word_terms then
				if attached a_version as al_version then
					Result := search_by_verse (a_query, al_version.to_string_32, a_limit)
				else
					Result := search_by_verse (a_query, {STRING_32} "KJV", a_limit)
				end
			else
				Result := search_text (a_query, a_version, a_limit)
			end
		end

feature -- Closing

	close
			-- Close the database.
		do
			sql.close
		end

feature {NONE} -- Search implementation

	search_text (a_query: SB_SEARCH_QUERY; a_version: detachable READABLE_STRING_GENERAL; a_limit: INTEGER): SB_SEARCH_RESULT
			-- A text-only search: results are verse rows of one version, or of every version.
		local
			l_found: SB_ID_SET
			l_first, l_last: INTEGER_64
			l_ids: STRING_8
			l_verses: ARRAYED_LIST [SB_VERSE]
			l_shown, i: INTEGER
		do
			if attached a_version as al_version then
				l_first := version (al_version).first_id
				l_last := version (al_version).last_id
			else
				l_first := {INTEGER_64}.min_value
				l_last := {INTEGER_64}.max_value
			end
			l_found := evaluate (a_query.root, agent text_leaf (?, l_first, l_last))
			create l_verses.make (a_limit.min (l_found.count))
			l_shown := a_limit.min (l_found.count)
			from
				i := 1
				create l_ids.make (4096)
			until
				i > l_shown
			loop
				if not l_ids.is_empty then
					l_ids.append_character (',')
				end
				l_ids.append (l_found [i].out)
				if i \\ 500 = 0 or else i = l_shown then
					l_verses.append (verses (Verse_columns + " FROM verse WHERE id IN (" + l_ids + ") ORDER BY id", no_args))
					l_ids.wipe_out
				end
				i := i + 1
			end
			create Result.make (l_found.count, l_verses, a_query.text_matches)
		end

	text_leaf (a_node: SB_QUERY_NODE; a_first, a_last: INTEGER_64): SB_ID_SET
			-- The ids of the verses a text leaf finds, between `a_first' and `a_last'.
		local
			l_all: SB_ID_SET
			l_kept: ARRAYED_LIST [INTEGER_64]
			i: INTEGER
		do
			if attached {SB_TEXT_NODE} a_node as al_text then
				l_all := sql.integer_set ("SELECT docid FROM verse_fts WHERE verse_fts MATCH ?", <<al_text.match.fts>>)
				if a_first = {INTEGER_64}.min_value then
					Result := l_all
				else
					create l_kept.make (l_all.count)
					from
						i := 1
					until
						i > l_all.count
					loop
						if l_all [i] >= a_first and l_all [i] <= a_last then
							l_kept.extend (l_all [i])
						end
						i := i + 1
					end
					create Result.make_from_list (l_kept)
				end
			else
				create Result.make_empty
			end
		end

	search_by_verse (a_query: SB_SEARCH_QUERY; a_version: STRING_32; a_limit: INTEGER): SB_SEARCH_RESULT
			-- A search with original-language terms (strongs:, lemma:, morph:). Every term yields a set
			-- of verses in English numbering: text terms from `a_version''s text, word terms from the
			-- Hebrew and Greek words. The verses are shown in `a_version', with the original words that matched.
		local
			l_terms: ARRAYED_LIST [TUPLE [condition: STRING_8; args: ARRAY [detachable ANY]; key: STRING_32]]
			l_found: SB_ID_SET
			l_keys: STRING_8
			l_shown, i: INTEGER
			l_verses: ARRAYED_LIST [SB_VERSE]
			l_hits: HASH_TABLE [ARRAYED_LIST [STRING_32], INTEGER]
		do
			create l_terms.make (4)
			l_found := evaluate (a_query.root, agent verse_leaf (?, a_version, l_terms))
			create l_hits.make (0)
			l_shown := a_limit.min (l_found.count)
			if l_shown = 0 then
				create l_verses.make (0)
				create Result.make_by_verse (0, l_verses, a_query.text_matches, l_hits)
			else
				create l_keys.make (l_shown * 9)
				from
					i := 1
				until
					i > l_shown
				loop
					if i > 1 then
						l_keys.append_character (',')
					end
					l_keys.append (l_found [i].out)
					i := i + 1
				end
				l_verses := verses (Verse_columns + " FROM verse WHERE eng_key IN (" + l_keys + ") AND version = ? ORDER BY eng_key, id", <<a_version>>)
				if l_verses.is_empty then
					l_verses := verses ("SELECT v.id, v.version, v.book, v.chapter, v.verse, v.eng_key, v.text FROM verse v JOIN version n ON n.code = v.version WHERE v.eng_key IN (" + l_keys + ") AND n.code = (CASE WHEN v.book <= 39 THEN 'WLC' ELSE 'WH' END) ORDER BY v.eng_key, v.id", no_args)
				end
				l_hits := word_hits (l_terms, l_keys)
				create Result.make_by_verse (l_found.count, l_verses, a_query.text_matches, l_hits)
			end
		end

	verse_leaf (a_node: SB_QUERY_NODE; a_version: STRING_32; a_terms: ARRAYED_LIST [TUPLE [condition: STRING_8; args: ARRAY [detachable ANY]; key: STRING_32]]): SB_ID_SET
			-- The English keys a leaf finds; a word term is also added to `a_terms'.
		local
			l_term: like word_condition
		do
			if attached {SB_TEXT_NODE} a_node as al_text then
				Result := sql.integer_set ("SELECT v.eng_key FROM verse_fts JOIN verse v ON v.id = verse_fts.docid WHERE verse_fts MATCH ? AND v.version = ?", <<al_text.match.fts, a_version>>)
			elseif attached {SB_WORD_TERM_NODE} a_node as al_word then
				l_term := word_condition (al_word)
				a_terms.extend (l_term)
				Result := sql.integer_set ("SELECT DISTINCT eng_key FROM word WHERE " + l_term.condition, l_term.args)
			else
				create Result.make_empty
			end
		end

	word_condition (a_term: SB_WORD_TERM_NODE): TUPLE [condition: STRING_8; args: ARRAY [detachable ANY]; key: STRING_32]
			-- The SQL condition of a word term, its arguments, and what tells it from other conditions.
		local
			l_value, l_folded, l_lower, l_key: STRING_32
			l_condition: STRING_8
			l_args: ARRAY [detachable ANY]
		do
			l_value := a_term.value
			create l_key.make (l_value.count * 2 + 40)
			if a_term.field.same_string_general ("strongs") then
				l_condition := "lemma IN (SELECT id FROM lemma WHERE number = ? OR strongs = ?)"
				l_args := <<l_value, l_value>>
				l_key.append_string_general (l_condition)
				l_key.append (l_value)
				l_key.append_string_general (", ")
				l_key.append (l_value)
			elseif a_term.field.same_string_general ("lemma") then
				l_folded := fold.fold (l_value)
				l_lower := kotlin.unicode.lowercase (l_value)
				l_condition := "lemma IN (SELECT id FROM lemma WHERE fold = ? OR ascii = ?)"
				l_args := <<l_folded, l_lower>>
				l_key.append_string_general (l_condition)
				l_key.append (l_folded)
				l_key.append_string_general (", ")
				l_key.append (l_lower)
			else
				if l_value.has ('*') or else l_value.has ('?') then
					l_condition := "morph GLOB ?"
				else
					l_condition := "morph = ?"
				end
				l_args := <<l_value>>
				l_key.append_string_general (l_condition)
				l_key.append (l_value)
			end
			Result := [l_condition, l_args, l_key]
		end

	word_hits (a_terms: ARRAYED_LIST [TUPLE [condition: STRING_8; args: ARRAY [detachable ANY]; key: STRING_32]]; a_keys: STRING_8): HASH_TABLE [ARRAYED_LIST [STRING_32], INTEGER]
			-- The original words that matched, per verse, for display under each result.
		local
			l_done: ARRAYED_LIST [STRING_32]
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_list: ARRAYED_LIST [STRING_32]
			l_key, i, j: INTEGER
			l_surface: STRING_32
		do
			create Result.make (64)
			create l_done.make (a_terms.count)
			l_done.compare_objects
			from
				i := 1
			until
				i > a_terms.count
			loop
				if not l_done.has (a_terms [i].key) then
					l_done.extend (a_terms [i].key)
					l_rows := sql.rows ("SELECT eng_key, surface FROM word WHERE eng_key IN (" + a_keys + ") AND (" + a_terms [i].condition + ") ORDER BY id", a_terms [i].args)
					from
						j := 1
					until
						j > l_rows.count
					loop
						l_key := sql.integer (l_rows [j], 1)
						l_surface := sql.text (l_rows [j], 2)
						if attached Result [l_key] as al_list then
							l_list := al_list
						else
							create l_list.make (4)
							l_list.compare_objects
							Result.force (l_list, l_key)
						end
						if not l_list.has (l_surface) then
							l_list.extend (l_surface)
						end
						j := j + 1
					end
				end
				i := i + 1
			end
		end

	evaluate (a_node: SB_QUERY_NODE; a_leaf: FUNCTION [SB_QUERY_NODE, SB_ID_SET]): SB_ID_SET
			-- AND, OR and NOT over the sets of `a_leaf'. A NOT only ever narrows the AND it stands in.
		local
			i: INTEGER
			l_result: detachable SB_ID_SET
			l_stop: BOOLEAN
			l_found: SB_ID_SET
		do
			if attached {SB_OR_NODE} a_node as al_or then
				create Result.make_empty
				from
					i := 1
				until
					i > al_or.items.count
				loop
					Result := Result.union (evaluate (al_or.items [i], a_leaf))
					i := i + 1
				end
			elseif attached {SB_AND_NODE} a_node as al_and then
				from
					i := 1
				until
					i > al_and.items.count or l_stop
				loop
					if not attached {SB_NOT_NODE} al_and.items [i] then
						l_found := evaluate (al_and.items [i], a_leaf)
						if attached l_result as al_result then
							l_found := al_result.intersection (l_found)
						end
						l_result := l_found
						l_stop := l_found.is_empty
					end
					i := i + 1
				end
				if attached l_result as al_result then
					Result := al_result
				else
					create Result.make_empty
				end
				from
					i := 1
				until
					i > al_and.items.count
				loop
					if attached {SB_NOT_NODE} al_and.items [i] as al_not and then not Result.is_empty then
						Result := Result.difference (evaluate (al_not.item, a_leaf))
					end
					i := i + 1
				end
			elseif attached {SB_NOT_NODE} a_node then
				create Result.make_empty
			else
				Result := a_leaf.item ([a_node])
			end
		end

feature {NONE} -- Implementation

	sql: SB_SQL
			-- The connection.

	fold: SB_FOLD
			-- Search folding.

	kotlin: SB_KOTLIN_TEXT
			-- Kotlin's text rules.

	chapter_index: HASH_TABLE [INTEGER, INTEGER_64]
			-- The page of each chapter, by `chapter_key'.

	land_cache: detachable like land
			-- `land' once read.

	sources_cache: detachable like sources
			-- `sources' once read.

	chapter_key (a_book, a_chapter: INTEGER): INTEGER_64
			-- One number for a book and a chapter.
		do
			Result := a_book.to_integer_64 * 0x1_0000_0000 + a_chapter.to_integer_64
		end

	no_args: ARRAY [detachable ANY]
			-- No arguments.
		do
			create Result.make_empty
		end

	verses (a_sql: READABLE_STRING_8; a_args: ARRAY [detachable ANY]): ARRAYED_LIST [SB_VERSE]
			-- The verses `a_sql' selects.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_row: SIMPLE_SQL_ROW
			i: INTEGER
		do
			l_rows := sql.rows (a_sql, a_args)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				l_row := l_rows [i]
				Result.extend (create {SB_VERSE}.make (sql.long (l_row, 1), sql.text (l_row, 2), sql.integer (l_row, 3), sql.integer (l_row, 4), sql.integer (l_row, 5), sql.integer (l_row, 6), sql.text (l_row, 7)))
				i := i + 1
			end
		end

	lemmas (a_sql: READABLE_STRING_8; a_args: ARRAY [detachable ANY]): ARRAYED_LIST [SB_LEMMA]
			-- The lemmas `a_sql' selects.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			i: INTEGER
		do
			l_rows := sql.rows (a_sql, a_args)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				Result.extend (lemma_from (l_rows [i]))
				i := i + 1
			end
		end

	lemma_from (a_row: SIMPLE_SQL_ROW): SB_LEMMA
			-- The lemma in the first ten columns of `a_row'.
		do
			create Result.make (sql.integer (a_row, 1), sql.text (a_row, 2), sql.text (a_row, 3), sql.text (a_row, 4), sql.text (a_row, 5), sql.text (a_row, 6), sql.text (a_row, 7),
				sql.integer (a_row, 8), sql.text (a_row, 9), sql.text (a_row, 10))
		end

	like_prefix (a_text: READABLE_STRING_GENERAL): STRING_32
			-- The LIKE pattern for what starts with `a_text', case-folded as Android's ICU LIKE folds it.
		do
			Result := kotlin.case_folded (a_text.to_string_32)
			Result.append_code (0x25)
		end

	extend_once (a_list: ARRAYED_LIST [STRING_32]; a_text: STRING_32)
			-- Add `a_text' to `a_list' unless it is there.
		require
			compares_objects: a_list.object_comparison
		do
			if not a_list.has (a_text) then
				a_list.extend (a_text)
			end
		end

	sql_list (a_texts: ARRAYED_LIST [STRING_32]): STRING_8
			-- `a_texts' as a list of SQL literals.
		local
			i: INTEGER
		do
			create Result.make (a_texts.count * 12)
			from
				i := 1
			until
				i > a_texts.count
			loop
				if i > 1 then
					Result.append_character (',')
				end
				Result.append (sql.sql_text (a_texts [i]))
				i := i + 1
			end
		end

	sense_key (a_sense: SB_ENGLISH_SENSE): STRING_8
			-- What tells `a_sense' from any other, in UTF-8.
		local
			l_key: STRING_32
		do
			create l_key.make (a_sense.text.count + 64)
			l_key.append (a_sense.source)
			l_key.append_code (1)
			l_key.append (a_sense.year)
			l_key.append_code (1)
			l_key.append (a_sense.sense_no)
			l_key.append_code (1)
			l_key.append (a_sense.pos)
			l_key.append_code (1)
			l_key.append (a_sense.text)
			l_key.append_code (1)
			l_key.append (a_sense.cite)
			Result := {UTF_CONVERTER}.string_32_to_utf_8_string_8 (l_key)
		end

	Verse_columns: STRING_8 = "SELECT id, version, book, chapter, verse, eng_key, text"
			-- The start of a query for verses.

	Lemma_columns: STRING_8 = "SELECT id, language, headword, translit, pron, strongs, pos, count, number, hint"
			-- The start of a query for lemmas.

end
