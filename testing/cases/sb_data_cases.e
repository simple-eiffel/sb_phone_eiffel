note
	description: "[
		The tests of the data layer: every public feature of SB_APP_DB, SB_USER_DB, SB_PACK_DB,
		SB_PACKS, the JSON classes and SB_KOTLIN_TEXT. Expected values were read from app.db and
		from the real Kotlin classes on the emulator; the wide comparisons with those are in
		testing/diff.

		Deferred on `check_that', `app_database' and `scratch_folder', so that the very same bodies run
		under simple_testing on the PC (LIB_TESTS) and under gec on the emulator (spikes/s_data).
		Non-ASCII text is written as %/code/ escapes, so that ISE and gec read these sources alike.
	]"
	author: "Larry Rix"
	testing: "covers"

deferred class
	SB_DATA_CASES

feature -- Access

	all_data_cases: ARRAYED_LIST [TUPLE [name: STRING_8; test: PROCEDURE]]
			-- Every test with its name, for the runners.
		do
			create Result.make (60)
			Result.extend (["test_versions", agent test_versions])
			Result.extend (["test_books_and_pages", agent test_books_and_pages])
			Result.extend (["test_verses", agent test_verses])
			Result.extend (["test_verse_own_numbering", agent test_verse_own_numbering])
			Result.extend (["test_preview_text", agent test_preview_text])
			Result.extend (["test_words", agent test_words])
			Result.extend (["test_lemma", agent test_lemma])
			Result.extend (["test_lemmas_by_strongs", agent test_lemmas_by_strongs])
			Result.extend (["test_lemmas_matching", agent test_lemmas_matching])
			Result.extend (["test_senses_renderings_occurrences", agent test_senses_renderings_occurrences])
			Result.extend (["test_kjv_links", agent test_kjv_links])
			Result.extend (["test_english_entry", agent test_english_entry])
			Result.extend (["test_timeline", agent test_timeline])
			Result.extend (["test_atlas", agent test_atlas])
			Result.extend (["test_xrefs", agent test_xrefs])
			Result.extend (["test_sources_and_meta", agent test_sources_and_meta])
			Result.extend (["test_search_text", agent test_search_text])
			Result.extend (["test_search_operators", agent test_search_operators])
			Result.extend (["test_search_limit", agent test_search_limit])
			Result.extend (["test_search_by_verse", agent test_search_by_verse])
			Result.extend (["test_search_word_hits", agent test_search_word_hits])
			Result.extend (["test_id_set", agent test_id_set])
			Result.extend (["test_user_file", agent test_user_file])
			Result.extend (["test_user_upgrade_from_1", agent test_user_upgrade_from_1])
			Result.extend (["test_user_refuses_a_newer_file", agent test_user_refuses_a_newer_file])
			Result.extend (["test_settings", agent test_settings])
			Result.extend (["test_folders_and_favorites", agent test_folders_and_favorites])
			Result.extend (["test_star", agent test_star])
			Result.extend (["test_highlights", agent test_highlights])
			Result.extend (["test_notes", agent test_notes])
			Result.extend (["test_note_restore", agent test_note_restore])
			Result.extend (["test_journal", agent test_journal])
			Result.extend (["test_tags", agent test_tags])
			Result.extend (["test_cards", agent test_cards])
			Result.extend (["test_prayers", agent test_prayers])
			Result.extend (["test_history", agent test_history])
			Result.extend (["test_export_empty", agent test_export_empty])
			Result.extend (["test_export_escaping", agent test_export_escaping])
			Result.extend (["test_import_merge", agent test_import_merge])
			Result.extend (["test_import_format_1", agent test_import_format_1])
			Result.extend (["test_import_errors", agent test_import_errors])
			Result.extend (["test_import_rolls_back", agent test_import_rolls_back])
			Result.extend (["test_export_import_round_trip", agent test_export_import_round_trip])
			Result.extend (["test_json_tokener", agent test_json_tokener])
			Result.extend (["test_json_conversions", agent test_json_conversions])
			Result.extend (["test_java_numbers", agent test_java_numbers])
			Result.extend (["test_kotlin_text", agent test_kotlin_text])
			Result.extend (["test_kotlin_case", agent test_kotlin_case])
			Result.extend (["test_pack", agent test_pack])
			Result.extend (["test_pack_search", agent test_pack_search])
			Result.extend (["test_packs_folder", agent test_packs_folder])
			Result.extend (["test_sql_text", agent test_sql_text])
		ensure
			every_case_named: not Result.is_empty
		end

feature {NONE} -- The environment

	check_that (a_tag: STRING_8; a_condition: BOOLEAN)
			-- Fail the test with `a_tag' unless `a_condition'.
		deferred
		end

	app_database: STRING_32
			-- Where a copy of the real app.db is.
		deferred
		end

	scratch_folder: STRING_32
			-- A folder for files made by the tests.
		deferred
		end

feature -- Tests: the Bible database

	test_versions
			-- Versions in version order; an unknown code gives the first.
		local
			l_db: SB_APP_DB
		do
			l_db := bible
			check_that ("eleven", l_db.versions.count = 11)
			check_that ("first", same (l_db.versions.first.code, "KJV"))
			check_that ("second", same (l_db.versions [2].code, "BSB"))
			check_that ("wlc right to left", l_db.version ("WLC").rtl)
			check_that ("wlc hebrew", same (l_db.version ("WLC").language, "he"))
			check_that ("wlc numbering", same (l_db.version ("WLC").versification, "heb"))
			check_that ("kjv left to right", not l_db.version ("KJV").rtl)
			check_that ("unknown is first", l_db.version ("NOPE") = l_db.versions.first)
			check_that ("ids in order", l_db.version ("KJV").first_id < l_db.version ("KJV").last_id)
			check_that ("code by value", same (l_db.version ({STRING_32} "WH").code, "WH"))
			l_db.close
		end

	test_books_and_pages
			-- 66 books, 1189 pages from 1.
		local
			l_db: SB_APP_DB
		do
			l_db := bible
			check_that ("books", l_db.books.count = 66)
			check_that ("john", same (l_db.book (43).name, "John"))
			check_that ("code", same (l_db.book (1).code, "GEN"))
			check_that ("has book", l_db.has_book (66) and not l_db.has_book (67))
			check_that ("chapters", l_db.chapters.count = 1189)
			check_that ("first chapter", l_db.chapters [1].book = 1 and l_db.chapters [1].chapter = 1)
			check_that ("last chapter", l_db.chapters [1189].book = 66 and l_db.chapters [1189].chapter = 22)
			check_that ("first page", l_db.page_of (1, 1) = 1)
			check_that ("last page", l_db.page_of (66, 22) = 1189)
			check_that ("exodus", l_db.page_of (2, 1) = 51)
			check_that ("no such chapter gives the first", l_db.page_of (2, 99) = 51)
			check_that ("no such book gives page 1", l_db.page_of (67, 1) = 1)
			check_that ("page and chapter agree", l_db.chapters [l_db.page_of (43, 3)].book = 43 and l_db.chapters [l_db.page_of (43, 3)].chapter = 3)
			l_db.close
		end

	test_verses
			-- A chapter, a key in one version and in all.
		local
			l_db: SB_APP_DB
			l_verses: ARRAYED_LIST [SB_VERSE]
		do
			l_db := bible
			l_verses := l_db.verses_in_chapter ("KJV", 43, 3)
			check_that ("36 verses", l_verses.count = 36)
			check_that ("in order", l_verses [16].eng_key = 43003016 and l_verses [16].verse = 16)
			check_that ("text", l_verses [16].text.starts_with ({STRING_32} "For God so loved the world"))
			check_that ("no such chapter", l_db.verses_in_chapter ("KJV", 1, 51).is_empty)
			l_verses := l_db.verses_at (43003016, Void)
			check_that ("eight versions", l_verses.count = 8)
			check_that ("version order", same (l_verses.first.version, "KJV") and same (l_verses [5].version, "WH"))
			l_verses := l_db.verses_at (43003016, "BSB")
			check_that ("one version", l_verses.count = 1 and same (l_verses.first.version, "BSB"))
			check_that ("not in hebrew", l_db.verses_at (43003016, "WLC").is_empty)
			check_that ("hebrew text", l_db.verses_at (1001001, "WLC").first.text.code (1) = 1489)
			l_db.close
		end

	test_verse_own_numbering
			-- A Hebrew verse numbered apart from the English.
		local
			l_db: SB_APP_DB
			l_verses: ARRAYED_LIST [SB_VERSE]
		do
			l_db := bible
			l_verses := l_db.verses_at (19051001, "WLC")
			check_that ("three rows on one key", l_verses.count = 3)
			check_that ("own label", same (l_verses [2].own_label, "51:2"))
			check_that ("differs", l_verses [2].differs_from_english)
			check_that ("same in the first", not l_verses [1].differs_from_english)
			check_that ("english does not differ", not l_db.verses_at (19051001, "KJV").first.differs_from_english)
			l_db.close
		end

	test_preview_text
			-- One verse, a range, a chapter key with no verse.
		local
			l_db: SB_APP_DB
		do
			l_db := bible
			check_that ("one verse", l_db.preview_text (create {SB_REF}.make_verse (43, 11, 35), "KJV").same_string_general ("Jesus wept."))
			check_that ("range joined by a space", l_db.preview_text (create {SB_REF}.make (43, 11, 35, 36), "KJV").starts_with ({STRING_32} "Jesus wept. Then said the Jews"))
			check_that ("range end not after start", l_db.preview_text (create {SB_REF}.make (43, 11, 35, 35), "KJV").same_string_general ("Jesus wept."))
			check_that ("chapter key is empty", l_db.preview_text (create {SB_REF}.make_verse (43, 11, 0), "KJV").is_empty)
			l_db.close
		end

	test_words
			-- The Hebrew words of Genesis 1:1.
		local
			l_db: SB_APP_DB
			l_words: ARRAYED_LIST [SB_WORD]
		do
			l_db := bible
			l_words := l_db.words (1001001)
			check_that ("eleven", l_words.count = 11)
			check_that ("gloss", same (l_words [2].gloss, "beginning"))
			check_that ("morph", same (l_words [3].morph, "Vqp3ms"))
			check_that ("lemma", l_words [3].lemma = 3)
			check_that ("address", l_words [1].book = 1 and l_words [1].chapter = 1 and l_words [1].verse = 1 and l_words [1].eng_key = 1001001)
			check_that ("surface", l_words [1].surface.code (1) = 1489)
			check_that ("none", l_db.words (1).is_empty)
			l_db.close
		end

	test_lemma
			-- By id, and its language.
		local
			l_db: SB_APP_DB
		do
			l_db := bible
			check_that ("none", l_db.lemma (0) = Void)
			if attached l_db.lemma (9875) as al_lemma then
				check_that ("strongs", same (al_lemma.strongs, "G3056"))
				check_that ("count", al_lemma.count = 331)
				check_that ("greek", same (al_lemma.language_name, "Greek") and not al_lemma.is_hebrew)
			else
				check_that ("logos", False)
			end
			if attached l_db.lemma (3) as al_lemma then
				check_that ("hebrew", same (al_lemma.language_name, "Hebrew") and al_lemma.is_hebrew)
				check_that ("number", same (al_lemma.number, "H1254"))
			else
				check_that ("bara", False)
			end
			l_db.close
		end

	test_lemmas_by_strongs
			-- The extended number, the exact one, then the homographs.
		local
			l_db: SB_APP_DB
			l_lemmas: ARRAYED_LIST [SB_LEMMA]
		do
			l_db := bible
			l_lemmas := l_db.lemmas_by_strongs ("H1254a")
			check_that ("extended", l_lemmas.count = 1 and then l_lemmas.first.id = 4222)
			l_lemmas := l_db.lemmas_by_strongs ("H1254")
			check_that ("exact, by count", l_lemmas.count >= 3 and then l_lemmas.first.id = 3)
			l_lemmas := l_db.lemmas_by_strongs ("G3056")
			check_that ("greek", l_lemmas.count = 1 and then l_lemmas.first.id = 9875)
			l_lemmas := l_db.lemmas_by_strongs ("H1254z")
			check_that ("homographs of a number with no such letter", l_lemmas.count >= 3)
			check_that ("nothing", l_db.lemmas_by_strongs ("H99999").is_empty)
			l_db.close
		end

	test_lemmas_matching
			-- Exact first, then by count, up to 30; LIKE folds case as ICU does on Android.
		local
			l_db: SB_APP_DB
			l_lemmas: ARRAYED_LIST [SB_LEMMA]
		do
			l_db := bible
			l_lemmas := l_db.lemmas_matching ("logos", "logos")
			check_that ("by ascii", not l_lemmas.is_empty and then l_lemmas.first.id = 9875)
			l_lemmas := l_db.lemmas_matching ({STRING_32} "%/955/%/959/%/947/%/959/%/963/", {STRING_32} "%/955/%/959/%/947/%/959/%/963/")
			check_that ("by fold", not l_lemmas.is_empty and then l_lemmas.first.id = 9875)
			l_lemmas := l_db.lemmas_matching ({STRING_32} "%/923/%/927/%/915/%/927/", {STRING_32} "%/923/%/927/%/915/%/927/")
			check_that ("capitals by LIKE", not l_lemmas.is_empty)
			l_lemmas := l_db.lemmas_matching ("a", "a")
			check_that ("limit", l_lemmas.count = 30)
			check_that ("nothing", l_db.lemmas_matching ("zzzzzz", "zzzzzz").is_empty)
			l_db.close
		end

	test_senses_renderings_occurrences
			-- What is known of logos.
		local
			l_db: SB_APP_DB
			l_renderings: ARRAYED_LIST [SB_RENDERING]
			l_places: like {SB_APP_DB}.occurrences
		do
			l_db := bible
			check_that ("senses", l_db.senses (9875).count = 92)
			check_that ("no senses", l_db.senses (0).is_empty)
			l_renderings := l_db.renderings (9875)
			check_that ("first rendering", same (l_renderings.first.english, "word") and l_renderings.first.n = 223)
			check_that ("second rendering", same (l_renderings [2].english, "say") and l_renderings [2].n = 34)
			l_places := l_db.occurrences (9875)
			check_that ("occurrences", l_places.count = 331)
			check_that ("canon order", l_places.first.eng_key < l_places.last.eng_key)
			l_db.close
		end

	test_kjv_links
			-- A KJV word to its original, and the set of linked words.
		local
			l_db: SB_APP_DB
			l_linked: like {SB_APP_DB}.kjv_linked
		do
			l_db := bible
			check_that ("loved", l_db.kjv_lemmas (43003016, "loved", 1).first.id = 9905)
			check_that ("no such word", l_db.kjv_lemmas (43003016, "nope", 1).is_empty)
			l_linked := l_db.kjv_linked (43003016)
			check_that ("linked", l_db.has_kjv_link (l_linked, "god", 1))
			check_that ("not that nth", not l_db.has_kjv_link (l_linked, "god", 9))
			check_that ("shifted", l_db.shifted_in (3027018).has ({STRING_32} "abate"))
			check_that ("not shifted", l_db.shifted_in (1001001).is_empty)
			l_db.close
		end

	test_english_entry
			-- The word love and its forms; a word the database does not have.
		local
			l_db: SB_APP_DB
			l_entry: SB_ENGLISH_ENTRY
		do
			l_db := bible
			l_entry := l_db.english_entry ("loved")
			check_that ("dictionary form", same (l_entry.lemma, "love"))
			check_that ("forms", l_entry.forms.count = 6 and then same (l_entry.forms.first, "love"))
			check_that ("behind", not l_entry.behind.is_empty and then l_entry.behind.first.n >= l_entry.behind.last.n)
			check_that ("senses", not l_entry.senses.is_empty)
			l_entry := l_db.english_entry ("zzzz")
			check_that ("unknown keeps itself", same (l_entry.lemma, "zzzz") and l_entry.forms.count = 1)
			check_that ("nothing behind", l_entry.behind.is_empty and l_entry.senses.is_empty and l_entry.shifts.is_empty)
			check_that ("shifts", not l_db.english_entry ("abate").shifts.is_empty)
			l_db.close
		end

	test_timeline
			-- Lanes, events, claims, places.
		local
			l_db: SB_APP_DB
			l_events: ARRAYED_LIST [SB_TL_EVENT]
		do
			l_db := bible
			check_that ("lanes", l_db.lanes.count = 7 and then same (l_db.lanes.first.id, "prehistory") and then same (l_db.lanes.first.group, "World"))
			l_events := l_db.events (Void)
			check_that ("events", l_events.count = 140)
			check_that ("by time", same (l_events.first.id, "denisovanoldest") and l_events.first.earliest <= l_events [2].earliest)
			check_that ("by lane", not l_db.events ("egypt").is_empty and then same (l_db.events ("egypt").first.lane, "egypt"))
			check_that ("no lane", l_db.events ("nope").is_empty)
			check_that ("claims", l_db.claims ("babylonsack").count = 5)
			check_that ("all places", l_db.places (Void).count = 76)
			check_that ("first place", same (l_db.places (Void).first.id, "jerusalem") and l_db.places (Void).first.min_zoom = 1)
			check_that ("event places", l_db.places ("irongates").count = 3)
			l_db.close
		end

	test_atlas
			-- Land outlines and the empires of a year; rings are little-endian floats.
		local
			l_db: SB_APP_DB
			l_areas: ARRAYED_LIST [SB_AREA]
		do
			l_db := bible
			check_that ("land", l_db.land.count = 262)
			check_that ("read once", l_db.land = l_db.land)
			l_areas := l_db.areas (100)
			check_that ("areas", l_areas.count = 120)
			check_that ("years", l_areas.first.year_from <= 100 and l_areas.first.year_to >= 100)
			check_that ("ring pairs", l_areas.first.ring.count > 0 and l_areas.first.ring.count \\ 2 = 0)
			check_that ("longitude", l_areas.first.ring [1] >= -180.0 and l_areas.first.ring [1] <= 180.0)
			check_that ("latitude", l_areas.first.ring [2] >= -90.0 and l_areas.first.ring [2] <= 90.0)
			l_db.close
		end

	test_xrefs
			-- By votes, with a range.
		local
			l_db: SB_APP_DB
			l_list: ARRAYED_LIST [SB_XREF]
		do
			l_db := bible
			l_list := l_db.xrefs (43003016)
			check_that ("count", l_list.count = 23)
			check_that ("by votes", l_list.first.to_key = 45005008 and l_list.first.votes = 950)
			check_that ("one verse", l_list.first.ref.verse_end = 0)
			check_that ("a range", l_list [2].to_end = 62004010 and l_list [2].ref.verse_end = 10 and l_list [2].ref.book = 62)
			check_that ("none", l_db.xrefs (1).is_empty)
			l_db.close
		end

	test_sources_and_meta
			-- The credits.
		local
			l_db: SB_APP_DB
		do
			l_db := bible
			check_that ("sources", l_db.sources.count = 32 and then same (l_db.sources.first.code, "KJV"))
			check_that ("read once", l_db.sources = l_db.sources)
			check_that ("one source", attached l_db.source ("BSB") as al_source and then same (al_source.name, "Berean Standard Bible"))
			check_that ("no source", l_db.source ("NOPE") = Void)
			check_that ("meta", attached l_db.meta ("schema") as al_meta and then same (al_meta, "1"))
			check_that ("no meta", l_db.meta ("nope") = Void)
			l_db.close
		end

	test_search_text
			-- One word, in one version and in all.
		local
			l_db: SB_APP_DB
			l_result: SB_SEARCH_RESULT
		do
			l_db := bible
			l_result := l_db.search (query ("love"), "KJV")
			check_that ("total", l_result.total = 280)
			check_that ("shown", l_result.verses.count = 280)
			check_that ("not by verse", not l_result.by_verse)
			check_that ("matches", l_result.matches.count = 1)
			check_that ("in order", l_result.verses.first.id < l_result.verses.last.id)
			check_that ("all versions", l_db.search (query ("love"), Void).total = 1360)
			check_that ("phrase", l_db.search (query ("%"one another%""), "KJV").total = 50)
			check_that ("prefix", l_db.search (query ("love*"), "KJV").total > 280)
			check_that ("unknown version is the first", l_db.search (query ("love"), "NOPE").total = 280)
			check_that ("greek prefix", l_db.search (query ({STRING_32} "%/956/%/953/%/956/*"), Void).total = 12)
			l_db.close
		end

	test_search_operators
			-- AND, OR, NOT, parentheses.
		local
			l_db: SB_APP_DB
			l_faith, l_hope, l_both, l_either, l_only: INTEGER
		do
			l_db := bible
			l_faith := l_db.search (query ("faith"), "KJV").total
			l_hope := l_db.search (query ("hope"), "KJV").total
			l_both := l_db.search (query ("faith hope"), "KJV").total
			l_either := l_db.search (query ("faith OR hope"), "KJV").total
			l_only := l_db.search (query ("faith -hope"), "KJV").total
			check_that ("words", l_faith = 231 and l_hope = 121)
			check_that ("union", l_either = l_faith + l_hope - l_both)
			check_that ("difference", l_only = l_faith - l_both)
			check_that ("and spelled out", l_db.search (query ("faith AND hope"), "KJV").total = l_both)
			check_that ("not spelled out", l_db.search (query ("faith NOT hope"), "KJV").total = l_only)
			check_that ("grouping", l_db.search (query ("(faith OR hope) love"), "KJV").total = l_db.search (query ("faith love OR hope love"), "KJV").total)
			check_that ("a not under an or is empty", l_db.search (query ("love OR (zzzz -love)"), "KJV").total = 280)
			check_that ("the empty side stops", l_db.search (query ("zzzzz love"), "KJV").total = 0)
			check_that ("negated matches are not highlighted", l_db.search (query ("faith -hope"), "KJV").matches.count = 1)
			l_db.close
		end

	test_search_limit
			-- The limit cuts what is shown, not the total.
		local
			l_db: SB_APP_DB
			l_result: SB_SEARCH_RESULT
		do
			l_db := bible
			l_result := l_db.search_limited (query ("love"), "KJV", 10)
			check_that ("total", l_result.total = 280)
			check_that ("shown", l_result.verses.count = 10)
			l_result := l_db.search_limited (query ("love"), Void, 501)
			check_that ("chunks", l_result.verses.count = 501 and l_result.total = 1360)
			check_that ("chunks stay in order", l_result.verses [500].id < l_result.verses [501].id)
			l_result := l_db.search (query ("love"), Void)
			check_that ("default", l_result.verses.count = 400)
			l_result := l_db.search_limited (query ("love"), "KJV", 0)
			check_that ("text keeps its total at limit 0", l_result.total = 280 and l_result.verses.is_empty)
			l_result := l_db.search_limited (query ("(H1254)"), "KJV", 0)
			check_that ("word terms lose it", l_result.total = 0 and l_result.by_verse)
			l_db.close
		end

	test_search_by_verse
			-- Word terms: strongs, lemma, morph; a verse missing from the version falls back.
		local
			l_db: SB_APP_DB
			l_result: SB_SEARCH_RESULT
		do
			l_db := bible
			l_result := l_db.search (query ("(strongs:H1254)"), "KJV")
			check_that ("strongs", l_result.total = 46 and l_result.by_verse)
			check_that ("shown in the version", same (l_result.verses.first.version, "KJV"))
			check_that ("no version means KJV", same (l_db.search (query ("(strongs:H1254)"), Void).verses.first.version, "KJV"))
			check_that ("morph", l_db.search (query ("morph:V-AAI-3S"), "KJV").total = 1036)
			check_that ("morph glob", l_db.search (query ("morph:V-AAI-*"), "KJV").total >= 1036)
			check_that ("lemma", l_db.search (query ("lemma:logos"), "KJV").total > 0)
			check_that ("with text", l_db.search (query ("H1254 heaven"), "KJV").total > 0)
			check_that ("left out", l_db.search (query ("H1254 -heaven"), "KJV").total < 46)
			check_that ("nothing", l_db.search (query ("strongs:H9999 love"), "KJV").total = 0)
			l_result := l_db.search (query ("(strongs:H1254)"), "WH")
			check_that ("falls back to the original", same (l_result.verses.first.version, "WLC"))
			l_db.close
		end

	test_search_word_hits
			-- The Hebrew words that matched, once each, by verse.
		local
			l_db: SB_APP_DB
			l_result: SB_SEARCH_RESULT
		do
			l_db := bible
			l_result := l_db.search (query ("(strongs:H1254)"), "KJV")
			check_that ("genesis 1:1", l_result.word_hits.has (1001001))
			if attached l_result.word_hits [1001001] as al_hits then
				check_that ("one surface", al_hits.count = 1 and then al_hits.first.code (1) = 1489)
			end
			check_that ("none for text", l_db.search (query ("love"), "KJV").word_hits.is_empty)
			l_db.close
		end

	test_id_set
			-- Sorting, repeats and the three operations.
		local
			l_one, l_other: SB_ID_SET
		do
			l_one := id_set (<<5, 1, 3, 3, 9>>)
			l_other := id_set (<<3, 4, 9, 10>>)
			check_that ("sorted without repeats", l_one.count = 4 and l_one [1] = 1 and l_one [4] = 9)
			check_that ("has", l_one.has (3) and not l_one.has (4))
			check_that ("intersection", id_text (l_one.intersection (l_other)).same_string ("3 9 "))
			check_that ("union", id_text (l_one.union (l_other)).same_string ("1 3 4 5 9 10 "))
			check_that ("difference", id_text (l_one.difference (l_other)).same_string ("1 5 "))
			check_that ("empty", (create {SB_ID_SET}.make_empty).is_empty and l_one.difference (l_one).is_empty)
			check_that ("already sorted", id_set (<<1, 2, 3>>).count = 3)
		end

feature -- Tests: the user's data

	test_user_file
			-- A new file is what SQLiteOpenHelper leaves.
		local
			l_db: SB_USER_DB
			l_sql: SB_SQL
			l_path: STRING_32
		do
			l_path := fresh_path ("file.db")
			create l_db.make (l_path)
			l_db.close
			create l_sql.make (l_path)
			check_that ("user_version", l_sql.first_integer ("PRAGMA user_version", no_args) = 2)
			check_that ("auto_vacuum", l_sql.first_integer ("PRAGMA auto_vacuum", no_args) = 1)
			check_that ("locale", same (l_sql.text (l_sql.rows ("SELECT locale FROM android_metadata", no_args).first, 1), "en_US"))
			check_that ("no bookmark", l_sql.first_integer ("SELECT count(*) FROM sqlite_master WHERE name = 'bookmark'", no_args) = 0)
			check_that ("reason column", l_sql.first_integer ("SELECT count(*) FROM pragma_table_info('highlight') WHERE name = 'reason'", no_args) = 1)
			l_sql.close
			create l_db.make (l_path)
			check_that ("reopens with one folder", l_db.folders.count = 1)
			l_db.close
		end

	test_user_upgrade_from_1
			-- Bookmarks become favorites in folder 1.
		local
			l_db: SB_USER_DB
			l_sql: SB_SQL
			l_path: STRING_32
		do
			l_path := fresh_path ("v1.db")
			create l_sql.make (l_path)
			l_sql.run ("CREATE TABLE bookmark(key INTEGER PRIMARY KEY, version TEXT NOT NULL, created INTEGER NOT NULL)", no_args)
			l_sql.run ("CREATE TABLE highlight(key INTEGER PRIMARY KEY, color INTEGER NOT NULL, created INTEGER NOT NULL)", no_args)
			l_sql.run ("INSERT INTO bookmark VALUES (43003016, 'KJV', 11), (1001001, 'WLC', 12)", no_args)
			l_sql.run ("INSERT INTO highlight VALUES (43003016, 2, 13)", no_args)
			l_sql.run ("PRAGMA user_version = 1", no_args)
			l_sql.close
			create l_db.make (l_path)
			check_that ("favorites", l_db.favorites (1).count = 2)
			check_that ("sorted by key", l_db.favorites (1).first.key = 1001001 and same (l_db.favorites (1).first.version, "WLC"))
			check_that ("created kept", l_db.favorites (1).first.created = 12)
			if attached l_db.highlight (43003016) as al_highlight then
				check_that ("highlight kept", al_highlight.color = 2 and al_highlight.reason.is_empty)
			else
				check_that ("highlight there", False)
			end
			l_db.close
			create l_sql.make (l_path)
			check_that ("now version 2", l_sql.first_integer ("PRAGMA user_version", no_args) = 2)
			l_sql.close
		end

	test_user_refuses_a_newer_file
			-- As SQLiteOpenHelper refuses to go down.
		local
			l_sql: SB_SQL
			l_path: STRING_32
			l_retried: BOOLEAN
			l_db: detachable SB_USER_DB
		do
			if not l_retried then
				l_path := fresh_path ("v3.db")
				create l_sql.make (l_path)
				l_sql.run ("CREATE TABLE t(x)", no_args)
				l_sql.run ("PRAGMA user_version = 3", no_args)
				l_sql.close
				create l_db.make (l_path)
				check_that ("refused", False)
			else
				check_that ("message", same ((create {SB_FAILURE}).last_message, "Can't downgrade database from version 3 to 2"))
			end
		rescue
			l_retried := True
			retry
		end

	test_settings
			-- INSERT OR REPLACE.
		local
			l_db: SB_USER_DB
		do
			l_db := fresh_user
			check_that ("none", l_db.setting ("book") = Void)
			l_db.set_setting ("book", "43")
			l_db.set_setting ("book", "44")
			check_that ("replaced", attached l_db.setting ("book") as al_value and then same (al_value, "44"))
			l_db.set_setting ({STRING_32} "%/1488/", {STRING_32} "%/955/ '%"")
			check_that ("any text", attached l_db.setting ({STRING_32} "%/1488/") as al_value and then al_value.same_string ({STRING_32} "%/955/ '%""))
			l_db.close
		end

	test_folders_and_favorites
			-- Folders by order; a favorite once per folder.
		local
			l_db: SB_USER_DB
			l_id: INTEGER_64
		do
			l_db := fresh_user
			check_that ("seeded", l_db.folders.count = 1 and then same (l_db.folders.first.name, "Favorites") and then l_db.folders.first.id = 1)
			l_id := l_db.add_folder ({STRING_32} "  Psalms  ")
			check_that ("trimmed", same (l_db.folders [2].name, "Psalms") and l_db.folders [2].id = l_id)
			l_db.rename_folder (l_id, {STRING_32} " Songs ")
			check_that ("renamed", same (l_db.folders [2].name, "Songs"))
			l_db.add_favorite (l_id, 19023001, "KJV", 0, False)
			l_db.add_favorite (l_id, 19023001, "BSB", 0, False)
			check_that ("once per folder", l_db.favorites (l_id).count = 1 and then same (l_db.favorites (l_id).first.version, "KJV"))
			l_db.add_favorite (l_id, 19023002, "KJV", 19023004, False)
			l_db.add_favorite (1, 19023000, "KJV", 0, True)
			check_that ("count", l_db.folders [2].count = 2)
			check_that ("of a key", l_db.favorites_of (19023001).count = 1)
			check_that ("range stars each verse", l_db.starred_keys.has (19023003) and l_db.starred_keys.has (19023004) and l_db.starred_keys.count = 4)
			check_that ("chapter is apart", l_db.starred_chapters.has (19023000) and not l_db.starred_keys.has (19023000))
			l_db.remove_favorite (l_db.favorites (l_id).first.id)
			check_that ("removed", l_db.favorites (l_id).count = 1)
			l_db.delete_folder (1)
			check_that ("first stays", l_db.folders.count = 2)
			l_db.delete_folder (l_id)
			check_that ("deleted with its favorites", l_db.folders.count = 1 and l_db.favorites (l_id).is_empty)
			l_db.close
		end

	test_star
			-- In folder 1, or out of every folder; a whole chapter does not count.
		local
			l_db: SB_USER_DB
			l_id: INTEGER_64
		do
			l_db := fresh_user
			l_id := l_db.add_folder ({STRING_32} "Other")
			check_that ("on", l_db.toggle_star (43003016, "KJV"))
			l_db.add_favorite (l_id, 43003016, "KJV", 0, False)
			l_db.add_favorite (l_id, 43003016, "KJV", 0, True)
			check_that ("off", not l_db.toggle_star (43003016, "KJV"))
			check_that ("out of every folder", l_db.favorites_of (43003016).count = 1 and then l_db.favorites_of (43003016).first.whole_chapter)
			l_db.close
		end

	test_highlights
			-- Color in place; reason trimmed; cleared.
		local
			l_db: SB_USER_DB
		do
			l_db := fresh_user
			l_db.set_highlight (1, 2)
			l_db.set_highlight_reason (1, {STRING_32} "  why  ")
			l_db.set_highlight (1, 3)
			if attached l_db.highlight (1) as al_highlight then
				check_that ("kept", al_highlight.color = 3 and same (al_highlight.reason, "why"))
			else
				check_that ("there", False)
			end
			check_that ("map", l_db.highlight_map [1] = 3)
			l_db.set_highlight (2, 0)
			check_that ("color 0 is on the map", l_db.highlight_map.has (2) and l_db.highlights.count = 2)
			l_db.set_highlight (1, Void)
			check_that ("cleared", l_db.highlight (1) = Void)
			l_db.close
		end

	test_notes
			-- Saved, versioned, deleted by a blank text, the early returns.
		local
			l_db: SB_USER_DB
		do
			l_db := fresh_user
			l_db.save_note (1, {STRING_32} "   ")
			check_that ("no new blank note", l_db.notes.is_empty and l_db.deleted_notes.is_empty)
			l_db.save_note (1, {STRING_32} "first")
			l_db.save_note (1, {STRING_32} "first")
			check_that ("one note", l_db.notes.count = 1 and l_db.noted_keys.has (1))
			check_that ("no version for no change", note_versions (l_db) = 1)
			l_db.save_note (1, {STRING_32} "second")
			check_that ("new text", attached l_db.note_for (1) as al_note and then same (al_note.text, "second"))
			check_that ("versions", note_versions (l_db) = 2)
			l_db.save_note (1, {STRING_32} "")
			check_that ("deleted", l_db.note_for (1) = Void and l_db.notes.is_empty and not l_db.noted_keys.has (1))
			check_that ("restorable with its last text", l_db.deleted_notes.count = 1 and then same (l_db.deleted_notes.first.text, "second"))
			l_db.close
		end

	test_note_restore
			-- Back alone, or appended to the verse's newer note.
		local
			l_db: SB_USER_DB
			l_id: INTEGER_64
		do
			l_db := fresh_user
			l_db.save_note (1, {STRING_32} "old")
			l_db.save_note (1, {STRING_32} "")
			l_id := l_db.deleted_notes.first.id
			l_db.restore_note (l_id)
			check_that ("back", attached l_db.note_for (1) as al_note and then same (al_note.text, "old") and l_db.deleted_notes.is_empty)
			l_db.save_note (1, {STRING_32} "")
			l_db.save_note (1, {STRING_32} "new")
			check_that ("two rows", l_db.deleted_notes.count = 1)
			l_db.restore_note (l_db.deleted_notes.first.id)
			check_that ("appended", attached l_db.note_for (1) as al_note and then al_note.text.same_string ({STRING_32} "new%N%Nold"))
			check_that ("old row gone", l_db.deleted_notes.is_empty and l_db.notes.count = 1)
			l_db.restore_note (9999)
			check_that ("no such note", l_db.notes.count = 1)
			l_db.close
		end

	test_journal
			-- New, saved, versioned, soft deleted, removed when empty.
		local
			l_db: SB_USER_DB
			l_id: INTEGER_64
		do
			l_db := fresh_user
			l_id := l_db.new_journal_entry
			check_that ("empty row", attached l_db.journal_entry (l_id) as al_entry and then al_entry.title.is_empty and l_db.journal (False).count = 1)
			l_db.save_journal (l_id, {STRING_32} " ", {STRING_32} "")
			check_that ("removed when left empty", l_db.journal_entry (l_id) = Void)
			l_id := l_db.new_journal_entry
			l_db.save_journal (l_id, {STRING_32} "T", {STRING_32} "B")
			check_that ("saved", attached l_db.journal_entry (l_id) as al_entry and then same (al_entry.body, "B"))
			l_db.save_journal (l_id, {STRING_32} "T", {STRING_32} "B")
			l_db.save_journal (l_id, {STRING_32} "", {STRING_32} "")
			check_that ("emptied but kept, old text was not blank", attached l_db.journal_entry (l_id) as al_entry and then al_entry.title.is_empty)
			l_db.set_journal_deleted (l_id, True)
			check_that ("soft deleted", l_db.journal (False).is_empty and l_db.journal (True).count = 1)
			l_db.set_journal_deleted (l_id, False)
			check_that ("back", l_db.journal (False).count = 1)
			l_db.save_journal (9999, {STRING_32} "x", {STRING_32} "y")
			check_that ("no such entry", l_db.journal (False).count = 1)
			l_db.close
		end

	test_tags
			-- Case does not matter, for ASCII as SQLite's NOCASE has it.
		local
			l_db: SB_USER_DB
			l_id: INTEGER_64
		do
			l_db := fresh_user
			l_id := l_db.tag_id ({STRING_32} " Grace ")
			check_that ("found", l_db.tag_id ({STRING_32} "GRACE") = l_id)
			check_that ("name", same (l_db.tags.first.name, "Grace"))
			check_that ("non-ASCII case is apart", l_db.tag_id ({STRING_32} "%/201/") /= l_db.tag_id ({STRING_32} "%/233/"))
			l_db.set_tagged (1, l_id, True)
			l_db.set_tagged (1, l_id, True)
			l_db.set_tagged (2, l_id, True)
			check_that ("count", l_db.tags.first.count = 2)
			check_that ("keys", l_db.tagged_keys (l_id).count = 2 and then l_db.tagged_keys (l_id).first = 1)
			check_that ("of a verse", l_db.tags_of (1).has (l_id))
			l_db.set_tagged (1, l_id, False)
			check_that ("off", not l_db.tags_of (1).has (l_id))
			l_db.delete_tag (l_id)
			check_that ("gone", l_db.tagged_keys (l_id).is_empty and l_db.tags.count = 2)
			l_db.close
		end

	test_cards
			-- Due now; doubling to 180; lapses.
		local
			l_db: SB_USER_DB
			l_before: INTEGER_64
			i: INTEGER
		do
			l_db := fresh_user
			check_that ("no next", l_db.next_due = Void)
			l_db.add_card (1, 0)
			l_db.add_card (1, 0)
			check_that ("once", l_db.cards.count = 1 and l_db.has_card (1) and not l_db.has_card (2))
			check_that ("due", l_db.due_cards.count = 1)
			l_before := l_db.now
			l_db.card_got_it (l_db.cards.first)
			check_that ("one day", l_db.cards.first.interval_days = 1 and l_db.cards.first.reps = 1)
			check_that ("due tomorrow", l_db.cards.first.due >= l_before + 86_400_000 and l_db.due_cards.is_empty)
			from
				i := 1
			until
				i > 9
			loop
				l_db.card_got_it (l_db.cards.first)
				i := i + 1
			end
			check_that ("capped", l_db.cards.first.interval_days = 180 and l_db.cards.first.reps = 10)
			l_db.card_again (l_db.cards.first)
			check_that ("again", l_db.cards.first.interval_days = 0 and l_db.cards.first.lapses = 1 and l_db.due_cards.count = 1)
			check_that ("next", attached l_db.next_due as al_due and then al_due.item = l_db.cards.first.due)
			l_db.remove_card (l_db.cards.first.id)
			check_that ("removed", l_db.cards.is_empty)
			l_db.close
		end

	test_prayers
			-- Open, answered, reopened, deleted.
		local
			l_db: SB_USER_DB
			l_id: INTEGER_64
		do
			l_db := fresh_user
			l_db.save_prayer (Void, {STRING_32} " For ", {STRING_32} " Details ", 43003016)
			l_id := l_db.prayers (False).first.id
			check_that ("trimmed", same (l_db.prayers (False).first.title, "For") and same (l_db.prayers (False).first.details, "Details") and l_db.prayers (False).first.key = 43003016)
			l_db.save_prayer (l_id, {STRING_32} "New", {STRING_32} "", 0)
			check_that ("changed", same (l_db.prayers (False).first.title, "New") and l_db.prayers (False).count = 1)
			l_db.answer_prayer (l_id, {STRING_32} " Yes ")
			check_that ("answered", l_db.prayers (False).is_empty and l_db.prayers (True).count = 1 and same (l_db.prayers (True).first.answer, "Yes"))
			l_db.reopen_prayer (l_id)
			check_that ("reopened", l_db.prayers (False).count = 1 and l_db.prayers (False).first.answered = 0)
			l_db.delete_prayer (l_id)
			check_that ("deleted", l_db.prayers (False).is_empty and l_db.prayers (True).is_empty)
			l_db.close
		end

	test_history
			-- No repeat of the last verse; newest 200 shown, newest 500 kept.
		local
			l_db: SB_USER_DB
			i: INTEGER
		do
			l_db := fresh_user
			l_db.record_visit (1, "KJV")
			l_db.record_visit (1, "BSB")
			check_that ("no repeat", l_db.history.count = 1 and then same (l_db.history.first.version, "KJV"))
			from
				i := 1
			until
				i > 210
			loop
				l_db.record_visit (i + 1, "KJV")
				i := i + 1
			end
			check_that ("200 shown", l_db.history.count = 200)
			l_db.close
		end

	test_export_empty
			-- The whole of an export with no data, as the real org.json wrote it.
		local
			l_db: SB_USER_DB
			l_text: STRING_32
		do
			l_db := fresh_user
			l_text := l_db.export_json_at (1700000000000)
			check_that ("empty export", l_text.same_string_general ("{%N  %"format%": %"sb_phone user data%",%N  %"formatVersion%": 2,%N  %"exported%": 1700000000000,%N  %"verseKeys%": %"book*1000000 + chapter*1000 + verse, English (KJV) numbering%",%N  %"folders%": [%N    {%N      %"name%": %"Favorites%",%N      %"favorites%": []%N    }%N  ],%N  %"highlights%": [],%N  %"notes%": [],%N  %"journal%": [],%N  %"tags%": [],%N  %"cards%": [],%N  %"prayers%": [],%N  %"history%": []%N}"))
			l_db.close
		end

	test_export_escaping
			-- Slashes, quotes, control characters; everything else as it is.
		local
			l_db: SB_USER_DB
			l_text: STRING_32
		do
			l_db := fresh_user
			l_db.save_note (1, {STRING_32} "a/b %"c%" \d%Ne%Tf%/8/g%/12/h%/13/i%/1/j%/31/k%/127/l%/1488/m%/128512/n")
			l_text := l_db.export_json_at (0)
			check_that ("escaped", l_text.has_substring ({STRING_32} "%"text%": %"a\/b \%"c\%" \\d\ne\tf\bg\fh\ri\u0001j\u001fk%/127/l%/1488/m%/128512/n%""))
			check_that ("deleted is a boolean", l_text.has_substring ({STRING_32} "%"deleted%": false"))
			check_that ("utf-8", l_db.export_json_utf_8.has_substring ("m%/240/%/159/%/152/%/128/n"))
			l_db.close
		end

	test_import_merge
			-- Folders matched ignoring case, favorites once, notes always added.
		local
			l_db: SB_USER_DB
			l_text: STRING_32
		do
			l_db := fresh_user
			l_text := {STRING_32} "{%"format%":%"sb_phone user data%",%"folders%":[{%"name%":%"FAVORITES%",%"favorites%":[{%"key%":1,%"version%":%"KJV%"},{%"key%":1}]},{%"name%":%"New%",%"favorites%":[{%"key%":2,%"keyEnd%":3,%"wholeChapter%":false}]}],%"highlights%":[{%"key%":1,%"color%":2,%"reason%":%"r%",%"created%":5}],%"notes%":[{%"key%":1,%"text%":%"t%",%"created%":1,%"updated%":2,%"versions%":[{%"text%":%"t%",%"saved%":2}]}],%"journal%":[{%"title%":%"a%",%"body%":%"b%",%"created%":1,%"updated%":2}],%"tags%":[{%"name%":%"T%",%"keys%":[1,2]}],%"cards%":[{%"key%":1,%"due%":7}],%"prayers%":[{%"title%":%"p%"}]}"
			check_that ("summary", same (l_db.import_json (l_text), "Imported 3 favorites, 1 highlights, 1 notes, 1 journal entries, 1 tags, 1 memory cards and 1 prayers."))
			check_that ("not failed", not l_db.has_import_failed)
			check_that ("one folder more", l_db.folders.count = 2)
			check_that ("once", l_db.favorites (1).count = 1)
			check_that ("default version", same (l_db.favorites (2).first.version, "KJV"))
			check_that ("again", same (l_db.import_json (l_text), "Imported 3 favorites, 1 highlights, 1 notes, 1 journal entries, 1 tags, 1 memory cards and 1 prayers."))
			check_that ("notes twice", l_db.notes.count = 2)
			check_that ("journal twice", l_db.journal (False).count = 2)
			check_that ("prayers twice", l_db.prayers (False).count = 2)
			check_that ("cards once", l_db.cards.count = 1)
			check_that ("favorites once", l_db.favorites (2).count = 1)
			l_db.close
		end

	test_import_format_1
			-- Bookmarks go into Favorites.
		local
			l_db: SB_USER_DB
		do
			l_db := fresh_user
			check_that ("summary", same (l_db.import_json ({STRING_32} "{%"format%":%"sb_phone user data%",%"formatVersion%":1,%"bookmarks%":[{%"key%":1,%"version%":%"KJV%"},{%"key%":2,%"version%":%"WH%"}]}"), "Imported 2 favorites, 0 highlights, 0 notes, 0 journal entries, 0 tags, 0 memory cards and 0 prayers."))
			check_that ("in folder 1", l_db.favorites (1).count = 2)
			check_that ("from the bytes of a file", l_db.import_json_utf_8 ("%/239/%/187/%/191/{%"format%":%"sb_phone user data%",%"tags%":[{%"name%":%"%/206/%/187/%"}]}").starts_with ({STRING_32} "Imported 0 favorites, 0 highlights, 0 notes, 0 journal entries, 1 tags"))
			check_that ("decoded", l_db.tags.first.name.same_string ({STRING_32} "%/955/"))
			l_db.close
		end

	test_import_errors
			-- The messages of org.json and of the Kotlin code.
		local
			l_db: SB_USER_DB
		do
			l_db := fresh_user
			check_that ("not ours", same (l_db.import_json ({STRING_32} "{}"), "This file is not an SB Phone export.") and l_db.has_import_failed)
			check_that ("empty", same (l_db.import_json ({STRING_32} ""), "End of input at character 0 of "))
			check_that ("array", same (l_db.import_json ({STRING_32} "[]"), "Value [] of type org.json.JSONArray cannot be converted to JSONObject"))
			check_that ("missing value", same (l_db.import_json ({STRING_32} "{%"format%":%"sb_phone user data%",%"notes%":[{%"key%":1}]}"), "No value for text"))
			check_that ("wrong type", same (l_db.import_json ({STRING_32} "{%"format%":%"sb_phone user data%",%"notes%":[1]}"), "Value 1 at 0 of type java.lang.Integer cannot be converted to JSONObject"))
			check_that ("not a number", same (l_db.import_json ({STRING_32} "{%"format%":%"sb_phone user data%",%"cards%":[{%"key%":%"x%"}]}"), "Value x at key of type java.lang.String cannot be converted to int"))
			check_that ("recovers", l_db.import_json ({STRING_32} "{%"format%":%"sb_phone user data%"}").starts_with ({STRING_32} "Imported 0") and not l_db.has_import_failed)
			l_db.close
		end

	test_import_rolls_back
			-- A failure in the middle leaves nothing behind.
		local
			l_db: SB_USER_DB
			l_text: STRING_32
		do
			l_db := fresh_user
			l_text := l_db.import_json ({STRING_32} "{%"format%":%"sb_phone user data%",%"folders%":[{%"name%":%"F%",%"favorites%":[{%"key%":1}]}],%"highlights%":[{%"key%":1,%"color%":2,%"created%":5}],%"notes%":[{%"key%":1}]}")
			check_that ("failed", l_db.has_import_failed and same (l_text, "No value for text"))
			check_that ("no folder", l_db.folders.count = 1)
			check_that ("no highlight", l_db.highlights.is_empty)
			l_db.close
		end

	test_export_import_round_trip
			-- What is exported comes back in another file.
		local
			l_one, l_other: SB_USER_DB
			l_text: STRING_32
		do
			l_one := fresh_user
			l_one.save_note (1, {STRING_32} "%/1488/ %"q%" /")
			l_one.set_highlight (2, 1)
			l_one.set_highlight_reason (2, {STRING_32} "r")
			l_text := l_one.export_json
			l_one.close
			create l_other.make (fresh_path ("other.db"))
			check_that ("imported", l_other.import_json (l_text).starts_with ({STRING_32} "Imported 0 favorites, 1 highlights, 1 notes"))
			check_that ("same text", attached l_other.note_for (1) as al_note and then al_note.text.same_string ({STRING_32} "%/1488/ %"q%" /"))
			check_that ("same reason", attached l_other.highlight (2) as al_highlight and then same (al_highlight.reason, "r"))
			l_other.close
		end

feature -- Tests: JSON and Kotlin's rules

	test_json_tokener
			-- org.json's leniency.
		local
			l_object: SB_JSON_OBJECT
		do
			l_object := (create {SB_JSON_TOKENER}.make ({STRING_32} "// c%N{a=1;'b'=>[1,,2,];/* c */%"c%":{},#x%N%"d%":%"\u0041\/\n\ud83d\ude00%"}")).root_object
			check_that ("unquoted name", l_object.integer_at ("a") = 1)
			if attached l_object.opt_array ("b") as al_array then
				check_that ("left out values", al_array.length = 4 and al_array.values [2] = Void and al_array.values [4] = Void)
			else
				check_that ("array", False)
			end
			check_that ("object", attached {SB_JSON_OBJECT} l_object.opt ("c"))
			check_that ("escapes and a surrogate pair", l_object.string_at ("d").same_string ({STRING_32} "A/%N%/128512/"))
			l_object := (create {SB_JSON_TOKENER}.make ({STRING_32} "%/65279/{%"a%":1}")).root_object
			check_that ("byte order mark", l_object.integer_at ("a") = 1)
		end

	test_json_conversions
			-- JSON.toInteger and its kin.
		local
			l_object: SB_JSON_OBJECT
		do
			l_object := (create {SB_JSON_TOKENER}.make ({STRING_32} "{%"s%":%"12.7%",%"d%":1e3,%"o%":010,%"h%":0x10,%"l%":5000000000,%"t%":%"TRUE%",%"n%":null,%"x%":[1]}")).root_object
			check_that ("string to int", l_object.integer_at ("s") = 12)
			check_that ("double to int", l_object.integer_at ("d") = 1000)
			check_that ("octal", l_object.integer_at ("o") = 8)
			check_that ("hex", l_object.integer_at ("h") = 16)
			check_that ("long", l_object.long_at ("l") = 5000000000)
			check_that ("long cut to int", l_object.integer_at ("l") = 705032704)
			check_that ("boolean from text", l_object.opt_boolean ("t"))
			check_that ("null text", same (l_object.opt_string ("n", {STRING_32} "f"), "null"))
			check_that ("array text", same (l_object.opt_string ("x", {STRING_32} "f"), "[1]"))
			check_that ("missing text", same (l_object.opt_string ("m", {STRING_32} "f"), "f"))
			check_that ("missing int", l_object.opt_integer ("m") = 0)
			check_that ("missing long", l_object.opt_long ("m", 7) = 7)
			check_that ("not an array", l_object.opt_array ("s") = Void)
		end

	test_java_numbers
			-- Long.parseLong, Double.parseDouble, Double.toString, the casts.
		local
			l_numbers: SB_JAVA_NUMBERS
		do
			create l_numbers
			check_that ("long", attached l_numbers.parsed_long ({STRING_32} "-12", 10) as al_long and then al_long.item = -12)
			check_that ("limit", attached l_numbers.parsed_long ({STRING_32} "-9223372036854775808", 10) as al_long and then al_long.item = {INTEGER_64}.min_value)
			check_that ("too large", l_numbers.parsed_long ({STRING_32} "9223372036854775808", 10) = Void)
			check_that ("radix", attached l_numbers.parsed_long ({STRING_32} "fF", 16) as al_long and then al_long.item = 255)
			check_that ("not a number", l_numbers.parsed_long ({STRING_32} "", 10) = Void and l_numbers.parsed_long ({STRING_32} "-", 10) = Void and l_numbers.parsed_long ({STRING_32} "9", 8) = Void)
			check_that ("double", attached l_numbers.parsed_double ({STRING_32} " 1.5e1f ") as al_double and then al_double.item = 15.0)
			check_that ("hex double", attached l_numbers.parsed_double ({STRING_32} "0x1.8p1") as al_double and then al_double.item = 3.0)
			check_that ("not a double", l_numbers.parsed_double ({STRING_32} "1e") = Void and l_numbers.parsed_double ({STRING_32} "") = Void and l_numbers.parsed_double ({STRING_32} "x") = Void)
			check_that ("nan", attached l_numbers.parsed_double ({STRING_32} "NaN") as al_double and then not l_numbers.is_finite (al_double.item))
			check_that ("saturates", l_numbers.to_int (1.0e300) = {INTEGER_32}.max_value and l_numbers.to_long (-1.0e300) = {INTEGER_64}.min_value)
			check_that ("truncates", l_numbers.to_int (-1.9) = -1)
			check_that ("text", l_numbers.double_text (1.5).same_string ("1.5") and l_numbers.double_text (100.0).same_string ("100.0"))
			check_that ("text limits", l_numbers.double_text (1.0e7).same_string ("1.0E7") and l_numbers.double_text (0.001).same_string ("0.001") and l_numbers.double_text (0.0001).same_string ("1.0E-4"))
			check_that ("negative", l_numbers.double_text (-0.5).same_string ("-0.5"))
		end

	test_kotlin_text
			-- trim, isBlank and their kin.
		local
			l_text: SB_KOTLIN_TEXT
		do
			create l_text.make
			check_that ("trim", same (l_text.trimmed ({STRING_32} " %T%Nx y%/12288/%/160/"), "x y"))
			check_that ("control not trimmed", l_text.trimmed ({STRING_32} "%/133/x").count = 2)
			check_that ("blank", l_text.is_blank ({STRING_32} " %/8195/%N") and l_text.is_blank ({STRING_32} ""))
			check_that ("not blank", not l_text.is_blank ({STRING_32} " x"))
			check_that ("lower letters", same (l_text.without_lower_letters_at_end ({STRING_32} "H1254ab"), "H1254"))
			check_that ("all letters", l_text.is_all_letters ({STRING_32} "ab") and not l_text.is_all_letters ({STRING_32} "a1") and l_text.is_all_letters ({STRING_32} ""))
			check_that ("prefix", same (l_text.without_prefix ({STRING_32} "H12a", {STRING_32} "H12"), "a") and same (l_text.without_prefix ({STRING_32} "G1", {STRING_32} "H"), "G1"))
			check_that ("first word", same (l_text.first_word ({STRING_32} "  one two"), "one"))
			check_that ("quotes and stars", same (l_text.without_quotes_and_stars ({STRING_32} "%"*love*%""), "love"))
			check_that ("spaces", same (l_text.with_spaces_collapsed ({STRING_32} "a %N %T b"), "a b"))
			check_that ("file name", same (l_text.file_name_of ({STRING_32} "/x/y.db"), "y.db") and same (l_text.file_name_of ({STRING_32} "y.db"), "y.db"))
			check_that ("utf-16 order", l_text.is_before_in_utf_16 ({STRING_32} "%/65536/", {STRING_32} "%/65535/") and l_text.is_before_in_utf_16 ({STRING_32} "a", {STRING_32} "ab"))
		end

	test_kotlin_case
			-- Android's two lowercases, its case folding and equalsIgnoreCase.
		local
			l_text: SB_KOTLIN_TEXT
		do
			create l_text.make
			check_that ("final sigma", l_text.lowercase ({STRING_32} "%/923/%/927/%/915/%/927/%/931/").same_string ({STRING_32} "%/955/%/959/%/947/%/959/%/962/"))
			check_that ("java looks only next door", l_text.lowercase ({STRING_32} "%/927/%/769/%/931/").same_string ({STRING_32} "%/959/%/769/%/963/"))
			check_that ("icu skips marks", l_text.icu_lowercase ({STRING_32} "%/927/%/769/%/931/").same_string ({STRING_32} "%/959/%/769/%/962/"))
			check_that ("dotted capital", l_text.lowercase ({STRING_32} "%/304/").same_string ({STRING_32} "i%/775/"))
			check_that ("fold sigma", l_text.folded_code (0x3C2) = 0x3C3 and l_text.folded_code (0x3A3) = 0x3C3)
			check_that ("fold long s", l_text.folded_code (0x17F) = 0x73)
			check_that ("cherokee folds up", l_text.folded_code (0xAB70) = 0x13A0)
			check_that ("ignoring case", l_text.equal_ignoring_case ({STRING_32} "Abc", {STRING_32} "aBC"))
			check_that ("sigmas", l_text.equal_ignoring_case ({STRING_32} "%/962/", {STRING_32} "%/963/"))
			check_that ("not beyond the basic plane", not l_text.equal_ignoring_case ({STRING_32} "%/66560/", {STRING_32} "%/66600/"))
			check_that ("different", not l_text.equal_ignoring_case ({STRING_32} "a", {STRING_32} "ab"))
			check_that ("letter", l_text.is_letter (0x5D0) and not l_text.is_letter (0x31) and not l_text.is_letter (0x10400))
			check_that ("letter or digit", l_text.is_letter_or_digit (0x31) and not l_text.is_letter_or_digit (0x2D))
			check_that ("cased", l_text.is_cased (0x41) and l_text.is_cased (0xAA) and not l_text.is_cased (0x5D0))
			check_that ("case ignorable", l_text.is_case_ignorable (0x301) and l_text.is_case_ignorable (0x27) and not l_text.is_case_ignorable (0x41))
		end

feature -- Tests: packs

	test_pack
			-- Meta, kinds, documents, a verse.
		local
			l_pack: SB_PACK_DB
			l_hits: ARRAYED_LIST [SB_PACK_HIT]
		do
			create l_pack.make (made_pack ("pack.db", "pack-one", {STRING_32} "The Pack"))
			check_that ("title", same (l_pack.title, "The Pack"))
			check_that ("meta", attached l_pack.meta_value ("id") as al_id and then same (al_id, "pack-one"))
			check_that ("no meta", l_pack.meta_value ("nope") = Void)
			check_that ("kinds", l_pack.kinds.count = 2 and then same (l_pack.kinds.first.kind, "commentary") and then l_pack.kinds.first.n = 2)
			check_that ("docs in order", l_pack.docs ("commentary").count = 2 and then same (l_pack.docs ("commentary").first.title, "Alpha"))
			check_that ("doc", attached l_pack.doc (3) as al_doc and then same (al_doc.kind, "essay") and then al_doc.words = 30)
			check_that ("no doc", l_pack.doc (99) = Void)
			check_that ("body", l_pack.body (1).starts_with ({STRING_32} "Love is") and l_pack.body (99).is_empty)
			l_hits := l_pack.for_verse (43003016)
			check_that ("commentary first", l_hits.count = 2 and then same (l_hits.first.doc.kind, "commentary"))
			check_that ("start of the body", l_hits.first.excerpt.starts_with ({STRING_32} "Love is"))
			check_that ("no verse", l_pack.for_verse (1).is_empty)
			check_that ("refs", l_pack.refs_of (1).count = 1 and then l_pack.refs_of (1).first.key = 43003016)
			check_that ("open", l_pack.is_open)
			l_pack.close
			check_that ("closed", not l_pack.is_open)
		end

	test_pack_search
			-- Every word required; the excerpt is cut around the first typed word.
		local
			l_pack: SB_PACK_DB
			l_hits: ARRAYED_LIST [SB_PACK_HIT]
		do
			create l_pack.make (made_pack ("search.db", "s", {STRING_32} "S"))
			check_that ("nothing to find", l_pack.search ({STRING_32} " . ").is_empty)
			check_that ("no hit", l_pack.search ({STRING_32} "zzzz").is_empty)
			l_hits := l_pack.search ({STRING_32} "love")
			check_that ("found", l_hits.count = 1 and then l_hits.first.doc.id = 1)
			check_that ("near the start", l_hits.first.excerpt.starts_with ({STRING_32} "Love is"))
			l_hits := l_pack.search ({STRING_32} "needle")
			check_that ("cut", l_hits.count = 1 and then l_hits.first.excerpt.code (1) = 0x2026)
			check_that ("around the word", l_hits.first.excerpt.has_substring ({STRING_32} "needle"))
			check_that ("spaces collapsed", not l_hits.first.excerpt.has_substring ({STRING_32} "  "))
			check_that ("limit", l_pack.search_limited ({STRING_32} "love", 0).is_empty)
			l_pack.close
		end

	test_packs_folder
			-- Load, replace by id, skip what is not a pack, remove.
		local
			l_packs: SB_PACKS
			l_list: ARRAYED_LIST [SB_PACK_DB]
			l_folder, l_junk: STRING_32
			l_file: PLAIN_TEXT_FILE
			l_directory: DIRECTORY
		do
			l_folder := scratch_folder + {STRING_32} "/packfiles"
			create l_directory.make_with_name (l_folder + {STRING_32} "/packs")
			if l_directory.exists then
				l_directory.delete_content
			end
			create l_packs.make (l_folder)
			check_that ("empty", l_packs.open_all.is_empty)
			l_junk := scratch_folder + {STRING_32} "/junk.bin"
			create l_file.make_create_read_write (l_junk)
			l_file.put_string ("this is no database at all")
			l_file.close
			check_that ("refused", l_packs.load (l_junk) = Void)
			check_that ("message", same (l_packs.load_failure, "This file is not an SB Phone pack."))
			check_that ("nothing left", not (create {RAW_FILE}.make_with_name (l_packs.incoming_path)).exists)
			if attached l_packs.load (made_pack ("load.db", "my-pack_1!", {STRING_32} "One")) as al_pack then
				check_that ("named by id", al_pack.path.ends_with ({STRING_32} "/my-pack_1.db"))
				al_pack.close
			else
				check_that ("loaded", False)
			end
			if attached l_packs.load (made_pack ("load2.db", "my-pack_1", {STRING_32} "Two")) as al_pack then
				check_that ("replaced", same (al_pack.title, "Two"))
				al_pack.close
			else
				check_that ("loaded again", False)
			end
			if attached l_packs.load (made_pack ("load3.db", "zzz", {STRING_32} "Three")) as al_pack then
				al_pack.close
			end
			create l_file.make_create_read_write (l_packs.folder + {STRING_32} "/bad.db")
			l_file.put_string ("junk")
			l_file.close
			l_list := l_packs.open_all
			check_that ("sorted, bad one skipped", l_list.count = 2 and then same (l_list.first.title, "Two") and then same (l_list.last.title, "Three"))
			l_list.last.close
			l_packs.remove (l_list.first)
			check_that ("removed", l_packs.open_all.count = 1)
		end

	test_sql_text
			-- Literals: quotes, non-ASCII, a NUL.
		local
			l_sql: SB_SQL
			l_row: SIMPLE_SQL_ROW
		do
			create l_sql.make (fresh_path ("literal.db"))
			check_that ("literal", l_sql.sql_text ({STRING_32} "it's").same_string ("'it''s'"))
			check_that ("nul as a cast", l_sql.sql_text ({STRING_32} "a%/0/b").same_string ("CAST(X'610062' AS TEXT)"))
			check_that ("placeholder in quotes stays", l_sql.bound ("SELECT '?', ?", <<1>>).same_string ("SELECT '?', 1"))
			l_sql.run ("CREATE TABLE t(x TEXT)", no_args)
			l_sql.run ("INSERT INTO t VALUES (?)", <<{STRING_32} "a%/0/b%/1488/'">>)
			l_row := l_sql.rows ("SELECT x, hex(x) FROM t", no_args).first
			check_that ("nul kept", l_sql.text (l_row, 1).same_string ({STRING_32} "a%/0/b%/1488/'"))
			check_that ("bytes", same (l_sql.text (l_row, 2), "610062D79027"))
			l_sql.close
		end

feature {NONE} -- Implementation

	fresh_count: INTEGER
			-- How many paths `fresh_path' has given.

	bible: SB_APP_DB
			-- The real database.
		do
			create Result.make (app_database)
		end

	no_args: ARRAY [detachable ANY]
			-- No arguments.
		do
			create Result.make_empty
		end

	same (a_text: READABLE_STRING_32; a_expected: READABLE_STRING_8): BOOLEAN
			-- Is `a_text' `a_expected'?
		do
			Result := a_text.same_string_general (a_expected)
		end

	query (a_text: READABLE_STRING_32): SB_SEARCH_QUERY
			-- `a_text' read as a search.
		do
			check attached {SB_QUERY_PARSE_TEXT} (create {SB_QUERY_PARSER}.make).parse (a_text) as al_text then
				Result := al_text.query
			end
		end

	id_set (a_items: ARRAY [INTEGER_32]): SB_ID_SET
			-- The set of `a_items'.
		local
			l_list: ARRAYED_LIST [INTEGER_64]
			i: INTEGER
		do
			create l_list.make (a_items.count)
			from
				i := a_items.lower
			until
				i > a_items.upper
			loop
				l_list.extend (a_items [i])
				i := i + 1
			end
			create Result.make_from_list (l_list)
		end

	id_text (a_set: SB_ID_SET): STRING_8
			-- The items of `a_set', each followed by a space.
		local
			i: INTEGER
		do
			create Result.make (32)
			from
				i := 1
			until
				i > a_set.count
			loop
				Result.append (a_set [i].out + " ")
				i := i + 1
			end
		end

	fresh_path (a_name: READABLE_STRING_32): STRING_32
			-- A path in the scratch folder where no file is, a new one each time: a failed test may
			-- leave its file open, and Windows will not delete that.
		local
			l_file: RAW_FILE
		do
			fresh_count := fresh_count + 1
			Result := scratch_folder + {STRING_32} "/" + fresh_count.out.to_string_32 + {STRING_32} "_" + a_name
			create l_file.make_with_name (Result)
			if l_file.exists then
				l_file.delete
			end
		end

	fresh_user: SB_USER_DB
			-- A new user.db.
		do
			create Result.make (fresh_path ("user.db"))
		end

	note_versions (a_db: SB_USER_DB): INTEGER
			-- How many versions of notes `a_db' exports.
		local
			l_text: STRING_32
			l_at: INTEGER
		do
			l_text := a_db.export_json_at (0)
			from
				l_at := l_text.substring_index ({STRING_32} "%"saved%"", 1)
			until
				l_at = 0
			loop
				Result := Result + 1
				l_at := l_text.substring_index ({STRING_32} "%"saved%"", l_at + 1)
			end
		end

	made_pack (a_name: READABLE_STRING_32; a_id: READABLE_STRING_8; a_title: READABLE_STRING_32): STRING_32
			-- The path of a small pack made for a test.
		local
			l_sql: SB_SQL
			l_filler: STRING_32
		do
			Result := fresh_path (a_name)
			create l_sql.make (Result)
			l_sql.run ("CREATE TABLE pack_meta(key TEXT PRIMARY KEY, value TEXT NOT NULL)", no_args)
			l_sql.run ("CREATE TABLE doc(id INTEGER PRIMARY KEY, kind TEXT NOT NULL, title TEXT NOT NULL, collection TEXT NOT NULL, status TEXT NOT NULL, path TEXT NOT NULL, words INTEGER NOT NULL, sort INTEGER NOT NULL, body TEXT NOT NULL)", no_args)
			l_sql.run ("CREATE TABLE doc_ref(doc INTEGER NOT NULL, eng_key INTEGER NOT NULL, covers INTEGER NOT NULL)", no_args)
			l_sql.run ("CREATE VIRTUAL TABLE doc_fts USING fts4(content=%"%", folded)", no_args)
			l_sql.run ("INSERT INTO pack_meta VALUES ('format', 'sb_phone pack'), ('id', ?), ('title', ?)", <<a_id, a_title>>)
			create l_filler.make (900)
			from
			until
				l_filler.count > 700
			loop
				l_filler.append ({STRING_32} "some  filler%Nwords here ")
			end
			l_sql.run ("INSERT INTO doc VALUES (1, 'commentary', 'Beta', 'C', 'ok', 'p/1', 10, 2, 'Love is patient')", no_args)
			l_sql.run ("INSERT INTO doc VALUES (2, 'commentary', 'Alpha', 'C', 'ok', 'p/2', 20, 1, ?)", <<l_filler + {STRING_32} " needle " + l_filler>>)
			l_sql.run ("INSERT INTO doc VALUES (3, 'essay', 'Gamma', 'E', 'draft', 'p/3', 30, 1, 'An essay')", no_args)
			l_sql.run ("INSERT INTO doc_ref VALUES (1, 43003016, 1), (3, 43003016, 0)", no_args)
			l_sql.run ("INSERT INTO doc_fts(docid, folded) VALUES (1, 'love is patient'), (2, 'some filler words here needle'), (3, 'an essay')", no_args)
			l_sql.close
		end

end
