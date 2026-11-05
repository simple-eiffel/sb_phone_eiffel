note
	description: "[
		What a search found. When `by_verse', the search had original-language terms, so `total'
		counts verses (English numbering) and `word_hits' lists the Hebrew or Greek words that
		matched in each verse, by verse key.
	]"
	author: "Larry Rix"

class
	SB_SEARCH_RESULT

create
	make,
	make_by_verse

feature {NONE} -- Initialization

	make (a_total: INTEGER; a_verses: ARRAYED_LIST [SB_VERSE]; a_matches: ARRAYED_LIST [SB_MATCH])
			-- Create a result of a text search.
		do
			total := a_total
			verses := a_verses
			matches := a_matches
			create word_hits.make (0)
		ensure
			total_set: total = a_total
			verses_set: verses = a_verses
			matches_set: matches = a_matches
			not_by_verse: not by_verse
			no_word_hits: word_hits.is_empty
		end

	make_by_verse (a_total: INTEGER; a_verses: ARRAYED_LIST [SB_VERSE]; a_matches: ARRAYED_LIST [SB_MATCH]; a_word_hits: HASH_TABLE [ARRAYED_LIST [STRING_32], INTEGER])
			-- Create a result of a search with original-language terms.
		do
			total := a_total
			verses := a_verses
			matches := a_matches
			by_verse := True
			word_hits := a_word_hits
		ensure
			total_set: total = a_total
			verses_set: verses = a_verses
			matches_set: matches = a_matches
			is_by_verse: by_verse
			word_hits_set: word_hits = a_word_hits
		end

feature -- Access

	total: INTEGER
			-- How many were found, shown or not.

	verses: ARRAYED_LIST [SB_VERSE]
			-- The verses shown.

	matches: ARRAYED_LIST [SB_MATCH]
			-- The text matches, for highlighting.

	word_hits: HASH_TABLE [ARRAYED_LIST [STRING_32], INTEGER]
			-- The original words that matched, by verse key.

feature -- Status

	by_verse: BOOLEAN
			-- Had the search original-language terms?

end
