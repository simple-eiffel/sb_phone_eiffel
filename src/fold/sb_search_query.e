note
	description: "[
		A typed search, read into a tree.

		Syntax:
		- words (all required): grace peace; AND may be written but is the default
		- "exact phrases", prefixes: believ*
		- either: faith OR hope, also faith | hope
		- leave out: -hate, also NOT hate
		- grouping: (faith OR hope) love
		- original-language terms, matched on the Hebrew and Greek words of a verse:
		  strongs:H1254 (or a bare H1254, G3056 inside a longer search),
		  lemma:logos, morph:Vqp3ms, morph:V-AAI-3S, morph:Vqp*

		A Strong's number alone (H7225) is a word lookup, not a verse search.
		Mistakes are reported with the character position where they occur.
	]"
	author: "Larry Rix"

class
	SB_SEARCH_QUERY

create
	make

feature {NONE} -- Initialization

	make (a_root: SB_QUERY_NODE)
			-- Create the query.
		do
			root := a_root
		ensure
			root_set: root = a_root
		end

feature -- Access

	root: SB_QUERY_NODE
			-- The tree.

	text_matches: ARRAYED_LIST [SB_MATCH]
			-- Every text match in the tree that is not left out, for highlighting found words.
		do
			create Result.make (4)
			root.append_text_matches (Result, False)
		end

feature -- Status

	has_word_terms: BOOLEAN
			-- Must any term be matched against the Hebrew and Greek words rather than a version's text?
		do
			Result := root.has_word_term
		end

end
