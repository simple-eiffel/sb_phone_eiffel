note
	description: "[
		The tests of the fold port. The first group is FoldTest.kt, one Eiffel test per Kotlin
		@Test, in the same order, with every assertion. The second group holds the cases the port
		had to get right that FoldTest does not reach; their expected values were read from the
		real Kotlin module.

		Deferred on `check_that' only, so that the very same test bodies run under simple_testing
		on the PC (LIB_TESTS) and under gec on the emulator (spikes/s_fold, which cannot use the
		EQA testing library). Non-ASCII text is written as %/code/ escapes, so that ISE and gec
		read these sources alike.
	]"
	author: "Larry Rix"
	testing: "covers"

deferred class
	SB_FOLD_CASES

feature -- Access

	all_cases: ARRAYED_LIST [TUPLE [name: STRING_8; test: PROCEDURE]]
			-- Every test with its name, for the runners.
		do
			create Result.make (40)
			Result.extend (["test_hebrew_points_and_cantillation_drop", agent test_hebrew_points_and_cantillation_drop])
			Result.extend (["test_hebrew_finals_and_sof_pasuq", agent test_hebrew_finals_and_sof_pasuq])
			Result.extend (["test_hebrew_maqaf_splits_words", agent test_hebrew_maqaf_splits_words])
			Result.extend (["test_greek_accents_breathings_and_final_sigma", agent test_greek_accents_breathings_and_final_sigma])
			Result.extend (["test_english_punctuation_and_apostrophes", agent test_english_punctuation_and_apostrophes])
			Result.extend (["test_latin_ligature_kept", agent test_latin_ligature_kept])
			Result.extend (["test_refs_loose", agent test_refs_loose])
			Result.extend (["test_ambiguous_book_gives_choice", agent test_ambiguous_book_gives_choice])
			Result.extend (["test_plain_words_are_not_refs", agent test_plain_words_are_not_refs])
			Result.extend (["test_query_and_or_not", agent test_query_and_or_not])
			Result.extend (["test_query_parentheses", agent test_query_parentheses])
			Result.extend (["test_query_prefix_and_hebrew", agent test_query_prefix_and_hebrew])
			Result.extend (["test_query_word_terms", agent test_query_word_terms])
			Result.extend (["test_query_error_positions", agent test_query_error_positions])
			Result.extend (["test_hebrew_pointing_levels", agent test_hebrew_pointing_levels])
			Result.extend (["test_strongs_lookup", agent test_strongs_lookup])
			Result.extend (["test_query_errors_are_named", agent test_query_errors_are_named])
			Result.extend (["test_fold_java_letter_or_digit", agent test_fold_java_letter_or_digit])
			Result.extend (["test_fold_marks_format_and_decomposition", agent test_fold_marks_format_and_decomposition])
			Result.extend (["test_fold_words", agent test_fold_words])
			Result.extend (["test_ref_labels_and_keys", agent test_ref_labels_and_keys])
			Result.extend (["test_books_table", agent test_books_table])
			Result.extend (["test_ref_pattern_backtracking", agent test_ref_pattern_backtracking])
			Result.extend (["test_ref_numbers_too_large", agent test_ref_numbers_too_large])
			Result.extend (["test_ref_case_mapping", agent test_ref_case_mapping])
			Result.extend (["test_finder_pattern_backtracking", agent test_finder_pattern_backtracking])
			Result.extend (["test_finder_positions_are_utf16", agent test_finder_positions_are_utf16])
			Result.extend (["test_query_tree_edges", agent test_query_tree_edges])
			Result.extend (["test_query_every_message", agent test_query_every_message])
			Result.extend (["test_query_positions_are_utf16", agent test_query_positions_are_utf16])
			Result.extend (["test_query_matches_and_fts", agent test_query_matches_and_fts])
			Result.extend (["test_strongs_backtracking", agent test_strongs_backtracking])
			Result.extend (["test_android_and_jvm_rules_differ", agent test_android_and_jvm_rules_differ])
		ensure
			every_case_named: not Result.is_empty
		end

feature -- FoldTest.kt, one to one

	test_hebrew_points_and_cantillation_drop
			-- hebrewPointsAndCantillationDrop.
			-- Final mem folds to mem, so a typed final or ordinary form both match.
		do
			check_same ("points", {STRING_32} "%/1489/%/1512/%/1488/%/1513/%/1497/%/1514/ %/1489/%/1512/%/1488/ %/1488/%/1500/%/1492/%/1497/%/1502/",
				folded ({STRING_32} "%/1489/%/1456/%/1468/%/1512/%/1461/%/1488/%/1513/%/1460/%/1473/%/1430/%/1497/%/1514/ %/1489/%/1464/%/1468/%/1512/%/1464/%/1443/%/1488/ %/1488/%/1457/%/1500/%/1465/%/1492/%/1460/%/1425/%/1497/%/1501/"))
		end

	test_hebrew_finals_and_sof_pasuq
			-- hebrewFinalsAndSofPasuq.
		do
			check_same ("final tsade, sof pasuq", {STRING_32} "%/1492/%/1488/%/1512/%/1510/", folded ({STRING_32} "%/1492/%/1464/%/1488/%/1464/%/1469/%/1512/%/1462/%/1509/%/1475/"))
			check_same ("pointed equals unpointed", folded ({STRING_32} "%/1513/%/1500/%/1493/%/1501/"), folded ({STRING_32} "%/1513/%/1464/%/1473/%/1500/%/1493/%/1465/%/1501/"))
		end

	test_hebrew_maqaf_splits_words
			-- hebrewMaqafSplitsWords.
		do
			check_same ("maqaf", {STRING_32} "%/1499/%/1500/ %/1488/%/1513/%/1512/", folded ({STRING_32} "%/1499/%/1464/%/1468/%/1500/%/1470/%/1488/%/1458/%/1513/%/1462/%/1473/%/1512/"))
		end

	test_greek_accents_breathings_and_final_sigma
			-- greekAccentsBreathingsAndFinalSigma.
		do
			check_same ("John 3:16", {STRING_32} "%/959/%/965/%/964/%/969/%/963/ %/947/%/945/%/961/ %/951/%/947/%/945/%/960/%/951/%/963/%/949/%/957/ %/959/ %/952/%/949/%/959/%/963/",
				folded ({STRING_32} "%/927/%/8021/%/964/%/969/%/962/ %/947/%/8048/%/961/ %/7968/%/947/%/940/%/960/%/951/%/963/%/949/%/957/ %/8001/ %/952/%/949/%/8056/%/962/"))
			check_same ("accented equals plain", folded ({STRING_32} "%/952/%/949/%/959/%/962/"), folded ({STRING_32} "%/952/%/949/%/8056/%/962/"))
		end

	test_english_punctuation_and_apostrophes
			-- englishPunctuationAndApostrophes.
		do
			check_same ("YLT", {STRING_32} "in the beginning of gods preparing the heavens and the earth",
				folded ({STRING_32} "In the beginning of God's preparing the heavens and the earth--"))
			check_same ("brackets", {STRING_32} "is", folded ({STRING_32} "[is]"))
			check_same ("backtick", {STRING_32} "oon bigetun", folded ({STRING_32} "`oon bigetun"))
		end

	test_latin_ligature_kept
			-- latinLigatureKept.
		do
			check_same ("ae", {STRING_32} "vitam %/230/ternam", folded ({STRING_32} "vitam %/230/ternam."))
		end

	test_refs_loose
			-- refsLoose.
		do
			check_one ("jn 3 16", {STRING_32} "jn 3 16", create {SB_REF}.make_verse (43, 3, 16))
			check_one ("John 3:16", {STRING_32} "John 3:16", create {SB_REF}.make_verse (43, 3, 16))
			check_one ("1pet 1:3", {STRING_32} "1pet 1:3", create {SB_REF}.make_verse (60, 1, 3))
			check_one ("1 Peter 1", {STRING_32} "1 Peter 1", create {SB_REF}.make_verse (60, 1, 0))
			check_one ("ps 23", {STRING_32} "ps 23", create {SB_REF}.make_verse (19, 23, 0))
			check_one ("Rom 8:28-30", {STRING_32} "Rom 8:28-30", create {SB_REF}.make (45, 8, 28, 30))
			check_one ("song of songs 2:1", {STRING_32} "song of songs 2:1", create {SB_REF}.make_verse (22, 2, 1))
			check_one ("genesis", {STRING_32} "genesis", create {SB_REF}.make_verse (1, 1, 0))
		end

	test_ambiguous_book_gives_choice
			-- ambiguousBookGivesChoice.
		do
			if attached {SB_REF_PARSE_CHOICE} ref_parser.parse ({STRING_32} "ju 1") as al_choice then
				check_that ("two books", al_choice.refs.count = 2)
				check_that ("Judges and Jude", al_choice.refs [1].book = 7 and al_choice.refs [2].book = 65)
			else
				check_that ("a choice", False)
			end
		end

	test_plain_words_are_not_refs
			-- plainWordsAreNotRefs.
		do
			check_not_a_ref ("love", {STRING_32} "love")
			check_not_a_ref ("grace and peace", {STRING_32} "grace and peace")
		end

	test_query_and_or_not
			-- queryAndOrNot.
			-- OR binds the words beside it: love AND "one another" AND NOT hate AND faith, OR hope.
		do
			check_tree ("the tree", {STRING_32} "love %"one another%" -hate faith OR hope",
				or_of (<<and_of (<<text ({STRING_32} "love"), phrase ({STRING_32} "one", {STRING_32} "another"), not_of (text ({STRING_32} "hate")), text ({STRING_32} "faith")>>), text ({STRING_32} "hope")>>))
			check_same ("fts of a phrase", {STRING_32} "%"one another%"", match_of_two ({STRING_32} "one", {STRING_32} "another").fts)
		end

	test_query_parentheses
			-- queryParentheses.
		do
			check_tree ("group first", {STRING_32} "(faith OR hope) love",
				and_of (<<or_of (<<text ({STRING_32} "faith"), text ({STRING_32} "hope")>>), text ({STRING_32} "love")>>))
			check_tree ("group left out", {STRING_32} "grace NOT (law | works)",
				and_of (<<text ({STRING_32} "grace"), not_of (or_of (<<text ({STRING_32} "law"), text ({STRING_32} "works")>>))>>))
		end

	test_query_prefix_and_hebrew
			-- queryPrefixAndHebrew.
		do
			check_tree ("prefix and Hebrew", {STRING_32} "%/956/%/953/%/956/* %/1489/%/1464/%/1468/%/1512/%/1464/%/1488/",
				and_of (<<prefix_text ({STRING_32} "%/956/%/953/%/956/"), text ({STRING_32} "%/1489/%/1512/%/1488/")>>))
		end

	test_query_word_terms
			-- queryWordTerms.
		do
			check_tree ("bare number", {STRING_32} "H1254 heaven", and_of (<<term ({STRING_32} "strongs", {STRING_32} "H1254"), text ({STRING_32} "heaven")>>))
			check_tree ("Greek morph", {STRING_32} "morph:V-AAI-3S", term ({STRING_32} "morph", {STRING_32} "V-AAI-3S"))
			check_tree ("morph star, Hebrew lemma", {STRING_32} "morph:Vqp* lemma:%/1489/%/1512/%/1488/",
				and_of (<<term ({STRING_32} "morph", {STRING_32} "Vqp*"), term ({STRING_32} "lemma", {STRING_32} "%/1489/%/1512/%/1488/")>>))
			check_tree ("Latin lemma", {STRING_32} "lemma:logos", term ({STRING_32} "lemma", {STRING_32} "logos"))
			check_that ("has word terms", attached {SB_QUERY_PARSE_TEXT} query_parser.parse ({STRING_32} "morph:Vqp3ms") as al_text and then al_text.query.has_word_terms)
		end

	test_query_error_positions
			-- queryErrorPositions.
		do
			check_error ("open group", {STRING_32} "(faith OR hope", {STRING_32} "This ( is never closed.", 0)
			check_error ("stray close", {STRING_32} "faith) hope", {STRING_32} "This ) has no ( before it.", 5)
			check_error ("open quote", {STRING_32} "grace %"open", {STRING_32} "This quotation mark is never closed.", 6)
			check_that ("OR at its place", attached {SB_QUERY_PARSE_ERROR} query_parser.parse ({STRING_32} "faith OR") as al_e and then al_e.position = 6)
			check_that ("at the colon", attached {SB_QUERY_PARSE_ERROR} query_parser.parse ({STRING_32} "morph:") as al_e and then al_e.position = 5)
		end

	test_hebrew_pointing_levels
			-- hebrewPointingLevels.
		local
			l_pointing: SB_POINTING
			l_full: STRING_32
		do
			create l_pointing
			l_full := {STRING_32} "%/1489/%/1456/%/1468/%/1512/%/1461/%/1488/%/1513/%/1460/%/1473/%/1430/%/1497/%/1514/ %/1489/%/1464/%/1468/%/1512/%/1464/%/1443/%/1488/"
			check_same ("vowels", {STRING_32} "%/1489/%/1456/%/1468/%/1512/%/1461/%/1488/%/1513/%/1460/%/1473/%/1497/%/1514/ %/1489/%/1464/%/1468/%/1512/%/1464/%/1488/", l_pointing.apply (l_full, l_pointing.Level_vowels))
			check_same ("consonants", {STRING_32} "%/1489/%/1512/%/1488/%/1513/%/1497/%/1514/ %/1489/%/1512/%/1488/", l_pointing.apply (l_full, l_pointing.Level_consonants))
			check_same ("full", l_full, l_pointing.apply (l_full, l_pointing.Level_full))
			check_same ("punctuation stays", {STRING_32} "%/1499/%/1500/%/1470/%/1488/%/1513/%/1512/%/1475/",
				l_pointing.apply ({STRING_32} "%/1499/%/1464/%/1468/%/1500/%/1470/%/1488/%/1458/%/1513/%/1462/%/1473/%/1445/%/1512/%/1475/", l_pointing.Level_consonants))
		end

	test_strongs_lookup
			-- strongsLookup.
		do
			check_strongs ("H7225", {STRING_32} "H7225", {STRING_32} "hbo", {STRING_32} "H7225")
			check_strongs ("g03056", {STRING_32} "g03056", {STRING_32} "grc", {STRING_32} "G3056")
			check_strongs ("strongs:H1254", {STRING_32} "strongs:H1254", {STRING_32} "hbo", {STRING_32} "H1254")
		end

	test_query_errors_are_named
			-- queryErrorsAreNamed.
		do
			check_that ("open quote", attached {SB_QUERY_PARSE_ERROR} query_parser.parse ({STRING_32} "%"open"))
			check_that ("OR first", attached {SB_QUERY_PARSE_ERROR} query_parser.parse ({STRING_32} "OR love"))
			check_that ("only left out", attached {SB_QUERY_PARSE_ERROR} query_parser.parse ({STRING_32} "-hate"))
			check_that ("empty group", attached {SB_QUERY_PARSE_ERROR} query_parser.parse ({STRING_32} "()"))
			check_that ("names the side", attached {SB_QUERY_PARSE_ERROR} query_parser.parse ({STRING_32} "love OR") as al_e and then al_e.message.has_substring ({STRING_32} "after"))
		end

feature -- Beyond FoldTest: fold

	test_fold_java_letter_or_digit
			-- Character.isLetterOrDigit is L* and Nd alone: Nl and No separate words, unlike
			-- SIMPLE_UNICODE's `is_letter_or_digit'.
		do
			check_same ("No, superscript two", {STRING_32} "x y", folded ({STRING_32} "x%/178/y"))
			check_same ("Nl, Roman numeral eight", {STRING_32} "a b", folded ({STRING_32} "a%/8551/b"))
			check_same ("Nd beyond ASCII stays", {STRING_32} "a%/1633/b", folded ({STRING_32} "a%/1633/b"))
			check_same ("modifier letter apostrophe goes", {STRING_32} "ab", folded ({STRING_32} "a%/700/b"))
			check_same ("curly apostrophes go", {STRING_32} "abc", folded ({STRING_32} "a%/8216/b%/8217/c"))
		end

	test_fold_marks_format_and_decomposition
			-- Marks and format characters leave nothing; decomposition reaches compatibility-free
			-- forms; the capital sigma lowers to sigma; Hangul decomposes by arithmetic.
		do
			check_same ("soft hyphen joins", {STRING_32} "ab", folded ({STRING_32} "a%/173/b"))
			check_same ("zero width joiner joins", {STRING_32} "ab", folded ({STRING_32} "a%/8205/b"))
			check_same ("e acute", {STRING_32} "e", folded ({STRING_32} "%/233/"))
			check_same ("dotted capital I", {STRING_32} "i", folded ({STRING_32} "%/304/"))
			check_same ("presentation form, final kaf with dagesh", {STRING_32} "%/1499/", folded ({STRING_32} "%/64314/"))
			check_same ("capital sigma", {STRING_32} "%/963/%/945/%/963/", folded ({STRING_32} "%/931/%/913/%/931/"))
			check_same ("Hangul", {STRING_32} "%/4370/%/4449/%/4523/", folded ({STRING_32} "%/54620/"))
			check_same ("Deseret capital lowers", {STRING_32} "%/66600/", folded ({STRING_32} "%/66560/"))
			check_same ("emoji is no letter", {STRING_32} "a b", folded ({STRING_32} "a%/128512/b"))
			check_same ("only punctuation", {STRING_32} "", folded ({STRING_32} " -- ! "))
		end

	test_fold_words
			-- Fold.words.
		local
			l_words: ARRAYED_LIST [STRING_32]
		do
			l_words := (create {SB_FOLD}.make).words ({STRING_32} "  God's, grace--peace! ")
			check_that ("three words", l_words.count = 3)
			check_same ("first", {STRING_32} "gods", l_words [1])
			check_same ("second", {STRING_32} "grace", l_words [2])
			check_same ("third", {STRING_32} "peace", l_words [3])
			check_that ("no words", (create {SB_FOLD}.make).words ({STRING_32} " ... ").is_empty)
		end

feature -- Beyond FoldTest: books and references

	test_ref_labels_and_keys
			-- label, short_label, key, from_key.
		local
			l_ref: SB_REF
		do
			l_ref := create {SB_REF}.make (45, 8, 28, 30)
			check_same ("range", {STRING_32} "Romans 8:28-30", l_ref.label)
			check_same ("short range", {STRING_32} "Rom 8:28-30", l_ref.short_label)
			check_that ("key", l_ref.key = 45008028)
			check_same ("whole chapter", {STRING_32} "1 John 2", (create {SB_REF}.make_verse (62, 2, 0)).label)
			check_same ("verse", {STRING_32} "Ps 23:1", (create {SB_REF}.make_verse (19, 23, 1)).short_label)
			check_same ("end not after verse", {STRING_32} "John 3:16", (create {SB_REF}.make (43, 3, 16, 16)).label)
			check_same ("end with no verse is a chapter", {STRING_32} "Romans 8", (create {SB_REF}.make (45, 8, 0, 9)).label)
			check_that ("from key", create {SB_REF}.make_from_key (45008028) ~ create {SB_REF}.make_verse (45, 8, 28))
			check_that ("key drops the end", create {SB_REF}.make_from_key (l_ref.key) ~ create {SB_REF}.make_verse (45, 8, 28))
			check_that ("key wraps like an Int", (create {SB_REF}.make_verse (43, 2147483647, 0)).key = 43000000 + (-1000))
		end

	test_books_table
			-- The table and its lookups.
		local
			l_books: SB_BOOKS
		do
			create l_books
			check_that ("66", l_books.all_books.count = 66)
			check_that ("Genesis is OT", l_books.by_id (39).is_old_testament and not l_books.by_id (40).is_old_testament)
			check_that ("no book 67", l_books.by_id_or_void (67) = Void and l_books.by_id_or_void (0) = Void)
			check_that ("by code", attached l_books.by_code ({STRING_32} "gEn") as al_b and then al_b.id = 1)
			check_that ("no such code", l_books.by_code ({STRING_32} "zzz") = Void)
			check_that ("long s uppercases", attached l_books.by_code ({STRING_32} "%/383/ng") as al_b and then al_b.id = 22)
			check_that ("st ligature uppercases to two", attached l_books.by_code ({STRING_32} "e%/64262/") as al_b and then al_b.id = 17)
			check_same ("no aliases", (create {SB_BOOKS}).by_id (51).debug_output, {STRING_32} "Book(id=51, code=COL, name=Colossians, short=Col, aliases=[])")
		end

	test_ref_pattern_backtracking
			-- What RefParser.pattern's greedy and lazy parts make of the unusual.
		do
			check_one ("the dot takes the verse, no chapter", {STRING_32} "john.3", create {SB_REF}.make_verse (43, 1, 3))
			check_one ("colon first", {STRING_32} "john :3", create {SB_REF}.make_verse (43, 1, 3))
			check_one ("dash first", {STRING_32} "john -3", create {SB_REF}.make (43, 1, 0, 3))
			check_one ("spaces then dot", {STRING_32} "john . 3", create {SB_REF}.make_verse (43, 1, 3))
			check_one ("the book may end in a dot", {STRING_32} "john .", create {SB_REF}.make_verse (43, 1, 0))
			check_one ("space is the separator", {STRING_32} "john 3 16-18", create {SB_REF}.make (43, 3, 16, 18))
			check_one ("spaces before the number", {STRING_32} "1  john 3", create {SB_REF}.make_verse (62, 3, 0))
			check_one ("end not after verse is dropped", {STRING_32} "john 3:16-5", create {SB_REF}.make_verse (43, 3, 16))
			check_one ("chapter range", {STRING_32} "rom 8-9", create {SB_REF}.make (45, 8, 0, 9))
			check_one ("en dash", {STRING_32} "John 3:16 %/8211/ 18", create {SB_REF}.make (43, 3, 16, 18))
			check_not_a_ref ("three numbers", {STRING_32} "john 3 16 18")
			check_not_a_ref ("two dashes", {STRING_32} "john 3-16-18")
			check_not_a_ref ("trailing dash", {STRING_32} "john 3-")
			check_not_a_ref ("trailing colon", {STRING_32} "john 3:")
			check_not_a_ref ("two numbers, no book", {STRING_32} "1 2")
			check_not_a_ref ("a number before the book number", {STRING_32} "12 john")
			check_not_a_ref ("empty", {STRING_32} "")
			check_not_a_ref ("no book by that name", {STRING_32} "zz")
			check_that ("nine books start with j", attached {SB_REF_PARSE_CHOICE} ref_parser.parse ({STRING_32} "j") as al_c and then al_c.refs.count = 9)
			check_that ("exact alias beats prefixes", attached {SB_REF_PARSE_ONE} ref_parser.parse ({STRING_32} "je") as al_o and then al_o.ref.book = 24)
			check_one ("one book by prefix", {STRING_32} "1 j", create {SB_REF}.make_verse (62, 1, 0))
			check_not_a_ref ("text past U+0FFF never reaches the name table", {STRING_32} "john%/66560/qoh gn")
			check_that ("nor as a typed book", ref_parser.books_matching ({STRING_32} "john%/66560/qoh%/31/%/8195/gn").is_empty)
		end

	test_ref_numbers_too_large
			-- toIntOrNull gives null past Int.MAX_VALUE, and the default stands.
		do
			check_one ("largest chapter", {STRING_32} "john 2147483647", create {SB_REF}.make_verse (43, 2147483647, 0))
			check_one ("chapter too large", {STRING_32} "john 2147483648", create {SB_REF}.make_verse (43, 1, 0))
			check_one ("verse too large", {STRING_32} "john 1:2147483648", create {SB_REF}.make_verse (43, 1, 0))
			check_one ("end too large", {STRING_32} "john 1:2-2147483648", create {SB_REF}.make_verse (43, 1, 2))
		end

	test_ref_case_mapping
			-- lowercase () on the whole input: the Kelvin sign is a k; dotted capital I is two
			-- characters and breaks the pattern; dotless i is not lowered to anything ASCII.
		do
			check_one ("Kelvin sign", {STRING_32} "1 %/8490/ings 2", create {SB_REF}.make_verse (11, 2, 0))
			check_not_a_ref ("dotted capital I", {STRING_32} "%/304/sa 1")
			check_not_a_ref ("dotless i", {STRING_32} "%/305/sa 1")
		end

	test_finder_pattern_backtracking
			-- What RefFinder.pattern finds, and does not, in running text.
		do
			check_found ("list", {STRING_32} "John 3:16; Rom 8:28-30, 1 Cor 13:4", {STRING_32} "John 3:16|Rom 8:28-30|1 Cor 13:4")
			check_found ("Song of Songs", {STRING_32} "see Song of Songs 2:1 there", {STRING_32} "Song of Songs 2:1")
			check_found ("no boundary before the number", {STRING_32} "abc1 John 3:16", {STRING_32} "1 John 3:16")
			check_found ("a digit that is no book number", {STRING_32} "4 John 1:2", {STRING_32} "John 1:2")
			check_found ("verse stops at three digits", {STRING_32} "John 3:1234", {STRING_32} "John 3:123")
			check_found ("chapter of four digits fails", {STRING_32} "John 1234:5", {STRING_32} "")
			check_found ("dangling dash left out", {STRING_32} "John 3:16 -", {STRING_32} "John 3:16")
			check_found ("en dash and spaces", {STRING_32} "John 3:16 %/8211/ 18", {STRING_32} "John 3:16 %/8211/ 18")
			check_found ("dot after book", {STRING_32} "John. 3:16", {STRING_32} "John. 3:16")
			check_found ("verse 0 is no verse", {STRING_32} "John 3:0", {STRING_32} "")
			check_found ("a choice is not a finding", {STRING_32} "ju 3:16", {STRING_32} "")
			check_found ("no such book", {STRING_32} "In 3:16", {STRING_32} "")
			check_found ("a failed reading still uses up its text", {STRING_32} "Song Song 1:1", {STRING_32} "")
			check_found ("after a dash, a new match", {STRING_32} "Gen 1:1%/8211/Gen 2:3", {STRING_32} "Gen 1:1|Gen 2:3")
		end

	test_finder_positions_are_utf16
			-- Found.range counts UTF-16 units, so each emoji before a match counts twice.
		local
			l_found: ARRAYED_LIST [SB_REF_FOUND]
		do
			l_found := (create {SB_REF_FINDER}.make).find_all ({STRING_32} "%/128512/%/128512/ Rom 8:28-30 x")
			check_that ("one", l_found.count = 1)
			check_that ("first", l_found.first.first = 5)
			check_that ("last", l_found.first.last = 15)
			check_same ("text", {STRING_32} "Rom 8:28-30", l_found.first.text)
			check_that ("ref", l_found.first.ref ~ create {SB_REF}.make (45, 8, 28, 30))
			check_same ("as Kotlin prints it", {STRING_32} "Found(range=5..15, text=Rom 8:28-30, ref=Ref(book=45, chapter=8, verse=28, verseEnd=30))", l_found.first.debug_output)
		end

feature -- Beyond FoldTest: queries

	test_query_tree_edges
			-- Trees from the corners of the tokenizer and the grammar.
		do
			check_tree ("hyphen inside a word", {STRING_32} "a-b", phrase ({STRING_32} "a", {STRING_32} "b"))
			check_tree ("hyphen after a bar is no NOT", {STRING_32} "a|-b", or_of (<<text ({STRING_32} "a"), text ({STRING_32} "b")>>))
			check_tree ("NOT inside a group", {STRING_32} "a (NOT b)", and_of (<<text ({STRING_32} "a"), not_of (text ({STRING_32} "b"))>>))
			check_tree ("NOT a group", {STRING_32} "a -(b c)", and_of (<<text ({STRING_32} "a"), not_of (and_of (<<text ({STRING_32} "b"), text ({STRING_32} "c")>>))>>))
			check_tree ("curly quotes", {STRING_32} "%/8220/a b%/8221/", phrase ({STRING_32} "a", {STRING_32} "b"))
			check_tree ("closing curly quote inside a word", {STRING_32} "a%/8221/b", phrase ({STRING_32} "a", {STRING_32} "b"))
			check_tree ("star on a phrase", {STRING_32} "%"a%"*", prefix_text ({STRING_32} "a"))
			check_tree ("many stars are one prefix", {STRING_32} "a**", prefix_text ({STRING_32} "a"))
			check_tree ("number with a star is still the number", {STRING_32} "H1 x", and_of (<<term ({STRING_32} "strongs", {STRING_32} "H1"), text ({STRING_32} "x")>>))
			check_tree ("capital suffix", {STRING_32} "H1254A", term ({STRING_32} "strongs", {STRING_32} "H1254A"))
			check_tree ("field in capitals", {STRING_32} "STRONGS:x", term ({STRING_32} "strongs", {STRING_32} "x"))
			check_tree ("lemma stars trimmed to nothing", {STRING_32} "lemma:**", term ({STRING_32} "lemma", {STRING_32} ""))
			check_tree ("morph stars kept", {STRING_32} "morph:**", term ({STRING_32} "morph", {STRING_32} "**"))
			check_tree ("unknown field is text", {STRING_32} "other:thing", phrase ({STRING_32} "other", {STRING_32} "thing"))
			check_tree ("colon first is text", {STRING_32} ":a", text ({STRING_32} "a"))
			check_tree ("colon stops the prefix", {STRING_32} "a:b*", phrase ({STRING_32} "a", {STRING_32} "b"))
			check_tree ("an OR may hold an AND", {STRING_32} "a OR (b NOT c)", or_of (<<text ({STRING_32} "a"), and_of (<<text ({STRING_32} "b"), not_of (text ({STRING_32} "c"))>>)>>))
		end

	test_query_every_message
			-- Every message the parser has, with its position. "Unexpected" and "NOT is misplaced"
			-- cannot be reached in Kotlin either; both are ported all the same.
		do
			check_error ("nothing typed", {STRING_32} "", {STRING_32} "Type a word to search for.", -1)
			check_error ("only spaces", {STRING_32} "   ", {STRING_32} "Type a word to search for.", -1)
			check_error ("only left out", {STRING_32} "NOT a", {STRING_32} "Add a word to look for, not only words to leave out.", -1)
			check_error ("an OR with a side left out", {STRING_32} "a OR NOT b", {STRING_32} "Add a word to look for, not only words to leave out.", -1)
			check_error ("nothing after NOT", {STRING_32} "a NOT", {STRING_32} "NOT needs a word after it.", 2)
			check_error ("nothing after the inner NOT", {STRING_32} "NOT NOT", {STRING_32} "NOT needs a word after it.", 4)
			check_error ("nothing after AND", {STRING_32} "a AND", {STRING_32} "AND needs a word after it.", 2)
			check_error ("AND before OR", {STRING_32} "a AND OR b", {STRING_32} "AND needs a word after it.", 2)
			check_error ("OR twice", {STRING_32} "a OR OR b", {STRING_32} "OR needs a word after it.", 2)
			check_error ("OR before a close", {STRING_32} "(a OR)", {STRING_32} "OR needs a word after it.", 3)
			check_error ("OR first", {STRING_32} "OR a", {STRING_32} "OR needs a word before it.", 0)
			check_error ("bar first", {STRING_32} "| a", {STRING_32} "OR needs a word before it.", 0)
			check_error ("AND after OR", {STRING_32} "a OR AND b", {STRING_32} "AND needs a word before it.", 5)
			check_error ("AND twice", {STRING_32} "a AND AND b", {STRING_32} "AND needs a word before it.", 6)
			check_error ("open at the end", {STRING_32} "(", {STRING_32} "A word is missing here.", 1)
			check_error ("close alone", {STRING_32} ")", {STRING_32} "This ) has no ( before it.", 0)
			check_error ("NOT before a close", {STRING_32} "(NOT)", {STRING_32} "This ) has no ( before it.", 4)
			check_error ("close too many", {STRING_32} "(a))", {STRING_32} "This ) has no ( before it.", 3)
			check_error ("inner group closed only", {STRING_32} "((a)", {STRING_32} "This ( is never closed.", 0)
			check_error ("empty group", {STRING_32} "( )", {STRING_32} "These parentheses are empty.", 0)
			check_error ("a lone hyphen", {STRING_32} "a - b", {STRING_32} "Nothing searchable in %"-%".", 2)
			check_error ("a lone star", {STRING_32} "*", {STRING_32} "Nothing searchable in %"%".", 0)
			check_error ("punctuation in quotes", {STRING_32} "%"!%"", {STRING_32} "Nothing searchable in %"!%".", 0)
			check_error ("second star after a phrase", {STRING_32} "%"a b%"**", {STRING_32} "Nothing searchable in %"%".", 6)
			check_error ("field in lower case in the message", {STRING_32} "MORPH:*", {STRING_32} "morph: needs something after the colon.", 5)
			check_error ("strongs field", {STRING_32} "strongs:", {STRING_32} "strongs: needs something after the colon.", 7)
			check_error ("lemma field later on", {STRING_32} "a lemma:", {STRING_32} "lemma: needs something after the colon.", 7)
		end

	test_query_positions_are_utf16
			-- Kotlin's positions count UTF-16 units, so each emoji before the mistake counts twice.
		do
			check_error ("close after an emoji word", {STRING_32} "a%/128512/ b)", {STRING_32} "This ) has no ( before it.", 5)
			check_error ("end of text counts units", {STRING_32} "a%/128512/ (", {STRING_32} "A word is missing here.", 5)
			check_error ("quote after an emoji", {STRING_32} "%/128512/a %"b", {STRING_32} "This quotation mark is never closed.", 4)
			check_error ("field after an emoji", {STRING_32} "a%/128512/ morph:", {STRING_32} "morph: needs something after the colon.", 9)
			check_error ("text naming an emoji", {STRING_32} "%/128512/", {STRING_32} "Nothing searchable in %"%/128512/%".", 0)
		end

	test_query_matches_and_fts
			-- text_matches, has_word_terms and the fts text.
		local
			l_matches: ARRAYED_LIST [SB_MATCH]
		do
			if attached {SB_QUERY_PARSE_TEXT} query_parser.parse ({STRING_32} "a %"b c%"* -d (e NOT f) g* H1") as al_parse then
				l_matches := al_parse.query.text_matches
				check_that ("left out words are not matches", l_matches.count = 4)
				check_same ("word", {STRING_32} "a", l_matches [1].fts)
				check_same ("phrase with a star", {STRING_32} "%"b c*%"", l_matches [2].fts)
				check_same ("in a group", {STRING_32} "e", l_matches [3].fts)
				check_same ("prefix", {STRING_32} "g*", l_matches [4].fts)
				check_that ("the number is a word term", al_parse.query.has_word_terms)
			else
				check_that ("parsed", False)
			end
			check_that ("no word terms", attached {SB_QUERY_PARSE_TEXT} query_parser.parse ({STRING_32} "a b") as al_p and then not al_p.query.has_word_terms)
			check_that ("a word term left out still counts", attached {SB_QUERY_PARSE_TEXT} query_parser.parse ({STRING_32} "a -lemma:b") as al_p and then al_p.query.has_word_terms)
		end

	test_strongs_backtracking
			-- What 0* and \d{1,5} make of zeros, and the difference between the two patterns.
		do
			check_strongs ("all zeros keep one", {STRING_32} "H00000", {STRING_32} "hbo", {STRING_32} "H0")
			check_strongs ("zeros go", {STRING_32} "H000001", {STRING_32} "hbo", {STRING_32} "H1")
			check_strongs ("five digits after zeros", {STRING_32} "H00012345", {STRING_32} "hbo", {STRING_32} "H12345")
			check_strongs ("suffix kept", {STRING_32} "G007a", {STRING_32} "grc", {STRING_32} "G7a")
			check_strongs ("spaces around", {STRING_32} "  H1  ", {STRING_32} "hbo", {STRING_32} "H1")
			check_tree ("six digits are a word", {STRING_32} "H123456", text ({STRING_32} "h123456"))
			check_tree ("zero then six digits are a word", {STRING_32} "H0123456", text ({STRING_32} "h0123456"))
			check_tree ("capital suffix is no lookup", {STRING_32} "G3056B", term ({STRING_32} "strongs", {STRING_32} "G3056B"))
			check_tree ("prefix in capitals is no lookup", {STRING_32} "STRONGS:h1", term ({STRING_32} "strongs", {STRING_32} "H1"))
		end

	test_android_and_jvm_rules_differ
			-- The one Kotlin source, two behaviors: see SB_KOTLIN_RULES.
		local
			l_jvm: SB_KOTLIN_RULES
		do
			create l_jvm.make_jvm
			check_one ("no-break space on Android", {STRING_32} "Gen%/160/23", create {SB_REF}.make_verse (1, 23, 0))
			check_that ("no-break space on the JVM", attached {SB_REF_PARSE_NOT_A_REF} (create {SB_REF_PARSER}.make_with_rules (l_jvm)).parse ({STRING_32} "Gen%/160/23"))
			check_one ("Arabic digits count on Android", {STRING_32} "john %/1635/:%/1633/%/1638/", create {SB_REF}.make_verse (43, 3, 16))
			check_not_a_ref ("a digit beyond the basic plane is two units to toIntOrNull", {STRING_32} "john 1%/120792/%/128512/")
			check_one ("and so the default stands", {STRING_32} "john %/120792/", create {SB_REF}.make_verse (43, 1, 0))
			check_strongs ("Arabic digit in a number", {STRING_32} "G%/1635/", {STRING_32} "grc", {STRING_32} "G%/1635/")
			check_tree ("the st ligature on Android", {STRING_32} "%/64262/rongs:H1a x", and_of (<<term ({STRING_32} "strongs", {STRING_32} "H1a"), text ({STRING_32} "x")>>))
			check_that ("long s on the JVM", attached {SB_QUERY_PARSE_TEXT} (create {SB_QUERY_PARSER}.make_with_rules (l_jvm)).parse ({STRING_32} "%/383/trongs:H1 x") as al_p and then al_p.query.has_word_terms)
			check_that ("the st ligature is folded text on the JVM", attached {SB_QUERY_PARSE_TEXT} (create {SB_QUERY_PARSER}.make_with_rules (l_jvm)).parse ({STRING_32} "%/64262/rongs:H1 x") as al_p and then not al_p.query.has_word_terms)
			check_that ("U+180E is whitespace on Android alone", (create {SB_KOTLIN_RULES}.make_android).is_whitespace (0x180E) and not l_jvm.is_whitespace (0x180E))
		end

feature {NONE} -- The check

	check_that (a_tag: STRING_8; a_condition: BOOLEAN)
			-- Report a failure unless `a_condition'.
		deferred
		end

feature {NONE} -- Checks

	check_same (a_tag: STRING_8; a_expected, a_actual: READABLE_STRING_32)
			-- Are the two texts the same?
		do
			check_that (a_tag, a_expected.same_string (a_actual))
		end

	check_one (a_tag: STRING_8; a_input: STRING_32; a_expected: SB_REF)
			-- Does `a_input' read as `a_expected' alone?
		do
			check_that (a_tag, attached {SB_REF_PARSE_ONE} ref_parser.parse (a_input) as al_one and then al_one.ref ~ a_expected)
		end

	check_not_a_ref (a_tag: STRING_8; a_input: STRING_32)
			-- Is `a_input' no reference?
		do
			check_that (a_tag, attached {SB_REF_PARSE_NOT_A_REF} ref_parser.parse (a_input))
		end

	check_found (a_tag: STRING_8; a_input, a_expected: STRING_32)
			-- Does the finder find the texts `a_expected', joined by bars, in `a_input'?
		local
			l_texts: STRING_32
			i: INTEGER
			l_found: ARRAYED_LIST [SB_REF_FOUND]
		do
			l_found := (create {SB_REF_FINDER}.make).find_all (a_input)
			create l_texts.make (32)
			from
				i := 1
			until
				i > l_found.count
			loop
				if i > 1 then
					l_texts.append_character ('|')
				end
				l_texts.append (l_found [i].text)
				i := i + 1
			end
			check_same (a_tag, a_expected, l_texts)
		end

	check_tree (a_tag: STRING_8; a_input: STRING_32; a_expected: SB_QUERY_NODE)
			-- Does `a_input' read as the tree `a_expected'?
		do
			check_that (a_tag, attached {SB_QUERY_PARSE_TEXT} query_parser.parse (a_input) as al_text and then al_text.query.root ~ a_expected)
		end

	check_error (a_tag: STRING_8; a_input, a_message: STRING_32; a_position: INTEGER)
			-- Does `a_input' give the mistake `a_message' at `a_position'?
		do
			check_that (a_tag, attached {SB_QUERY_PARSE_ERROR} query_parser.parse (a_input) as al_error
				and then al_error.message.same_string (a_message) and then al_error.position = a_position)
		end

	check_strongs (a_tag: STRING_8; a_input, a_language, a_number: STRING_32)
			-- Is `a_input' a lookup of `a_number' in `a_language'?
		do
			check_that (a_tag, attached {SB_QUERY_PARSE_STRONGS} query_parser.parse (a_input) as al_strongs
				and then al_strongs.language.same_string (a_language) and then al_strongs.number.same_string (a_number))
		end

feature {NONE} -- Helpers

	folded (a_text: STRING_32): STRING_32
			-- `a_text' folded.
		do
			Result := (create {SB_FOLD}.make).fold (a_text)
		end

	ref_parser: SB_REF_PARSER
			-- A reference parser with the default rules.
		do
			create Result.make
		end

	query_parser: SB_QUERY_PARSER
			-- A query parser with the default rules.
		do
			create Result.make
		end

	words_of (a_words: ARRAY [STRING_32]): ARRAYED_LIST [STRING_32]
			-- `a_words' as a list.
		do
			create Result.make_from_array (a_words)
		end

	match_of_two (a_first, a_second: STRING_32): SB_MATCH
			-- The phrase of the two words.
		do
			create Result.make (words_of (<<a_first, a_second>>), False)
		end

	text (a_word: STRING_32): SB_QUERY_NODE
			-- Kotlin's text ("word").
		do
			create {SB_TEXT_NODE} Result.make (create {SB_MATCH}.make (words_of (<<a_word>>), False))
		end

	phrase (a_first, a_second: STRING_32): SB_QUERY_NODE
			-- Kotlin's text ("first", "second").
		do
			create {SB_TEXT_NODE} Result.make (match_of_two (a_first, a_second))
		end

	prefix_text (a_word: STRING_32): SB_QUERY_NODE
			-- Kotlin's text ("word", prefix = true).
		do
			create {SB_TEXT_NODE} Result.make (create {SB_MATCH}.make (words_of (<<a_word>>), True))
		end

	term (a_field, a_value: STRING_32): SB_QUERY_NODE
			-- Node.WordTerm.
		do
			create {SB_WORD_TERM_NODE} Result.make (a_field, a_value)
		end

	and_of (a_items: ARRAY [SB_QUERY_NODE]): SB_QUERY_NODE
			-- Node.And.
		do
			create {SB_AND_NODE} Result.make (create {ARRAYED_LIST [SB_QUERY_NODE]}.make_from_array (a_items))
		end

	or_of (a_items: ARRAY [SB_QUERY_NODE]): SB_QUERY_NODE
			-- Node.Or.
		do
			create {SB_OR_NODE} Result.make (create {ARRAYED_LIST [SB_QUERY_NODE]}.make_from_array (a_items))
		end

	not_of (a_item: SB_QUERY_NODE): SB_QUERY_NODE
			-- Node.Not.
		do
			create {SB_NOT_NODE} Result.make (a_item)
		end

end
