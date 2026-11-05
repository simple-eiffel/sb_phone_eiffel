note
	description: "A node over a list of nodes."
	author: "Larry Rix"

deferred class
	SB_LIST_NODE

inherit
	SB_QUERY_NODE
		redefine
			is_equal
		end

feature {NONE} -- Initialization

	make (a_items: ARRAYED_LIST [SB_QUERY_NODE])
			-- Create the node.
		do
			items := a_items
		ensure
			items_set: items = a_items
		end

feature -- Access

	items: ARRAYED_LIST [SB_QUERY_NODE]
			-- The nodes, in the order typed.

feature -- Status

	has_word_term: BOOLEAN
			-- <Precursor>
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > items.count or Result
			loop
				Result := items [i].has_word_term
				i := i + 1
			end
		end

feature -- Collection

	append_text_matches (a_list: ARRAYED_LIST [SB_MATCH]; a_negated: BOOLEAN)
			-- <Precursor>
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > items.count
			loop
				items [i].append_text_matches (a_list, a_negated)
				i := i + 1
			end
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same nodes in the same order?
		local
			i: INTEGER
		do
			Result := items.count = a_other.items.count
			from
				i := 1
			until
				i > items.count or not Result
			loop
				Result := items [i] ~ a_other.items [i]
				i := i + 1
			end
		end

feature -- Output

	debug_output: STRING_32
			-- <Precursor>
		local
			i: INTEGER
		do
			create Result.make (64)
			Result.append_string_general (kind_name + "(items=[")
			from
				i := 1
			until
				i > items.count
			loop
				if i > 1 then
					Result.append_string_general (", ")
				end
				Result.append (items [i].debug_output)
				i := i + 1
			end
			Result.append_string_general ("])")
		end

feature {NONE} -- Implementation

	kind_name: STRING_8
			-- The Kotlin class name.
		deferred
		end

end
