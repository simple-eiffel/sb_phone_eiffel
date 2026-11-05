note
	description: "A node of a typed search, read into a tree."
	author: "Larry Rix"

deferred class
	SB_QUERY_NODE

feature -- Status

	has_positive: BOOLEAN
			-- Does this node ask for something, rather than only leave things out?
		deferred
		end

	has_word_term: BOOLEAN
			-- Is any term here matched against the Hebrew and Greek words?
		deferred
		end

feature -- Collection

	append_text_matches (a_list: ARRAYED_LIST [SB_MATCH]; a_negated: BOOLEAN)
			-- Add to `a_list' every text match here that is not left out,
			-- all of them being left out when `a_negated'.
		deferred
		end

feature -- Output

	debug_output: STRING_32
			-- The same text as Kotlin's toString on the data class.
		deferred
		end

end
