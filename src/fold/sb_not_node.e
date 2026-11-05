note
	description: "Leave out what the item matches."
	author: "Larry Rix"

class
	SB_NOT_NODE

inherit
	SB_QUERY_NODE
		redefine
			is_equal
		end

create
	make

feature {NONE} -- Initialization

	make (a_item: SB_QUERY_NODE)
			-- Create the node.
		do
			item := a_item
		ensure
			item_set: item = a_item
		end

feature -- Access

	item: SB_QUERY_NODE
			-- What is left out.

feature -- Status

	has_positive: BOOLEAN
			-- <Precursor>
		do
			Result := False
		end

	has_word_term: BOOLEAN
			-- <Precursor>
		do
			Result := item.has_word_term
		end

feature -- Collection

	append_text_matches (a_list: ARRAYED_LIST [SB_MATCH]; a_negated: BOOLEAN)
			-- <Precursor>
		do
			item.append_text_matches (a_list, True)
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same item?
		do
			Result := item ~ a_other.item
		end

feature -- Output

	debug_output: STRING_32
			-- <Precursor>
		do
			create Result.make (64)
			Result.append_string_general ("Not(item=")
			Result.append (item.debug_output)
			Result.append_string_general (")")
		end

end
