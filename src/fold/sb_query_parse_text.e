note
	description: "A typed search that is a query."
	author: "Larry Rix"

class
	SB_QUERY_PARSE_TEXT

inherit
	SB_QUERY_PARSE

create
	make

feature {NONE} -- Initialization

	make (a_query: SB_SEARCH_QUERY)
			-- Create the outcome.
		do
			query := a_query
		ensure
			query_set: query = a_query
		end

feature -- Access

	query: SB_SEARCH_QUERY
			-- The query.

feature -- Output

	debug_output: STRING_32
			-- <Precursor>
		do
			create Result.make (64)
			Result.append_string_general ("Text(query=SearchQuery(root=")
			Result.append (query.root.debug_output)
			Result.append_string_general ("))")
		end

end
