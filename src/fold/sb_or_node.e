note
	description: "Any item will do."
	author: "Larry Rix"

class
	SB_OR_NODE

inherit
	SB_LIST_NODE

create
	make

feature -- Status

	has_positive: BOOLEAN
			-- Does every item ask for something?
		local
			i: INTEGER
		do
			Result := True
			from
				i := 1
			until
				i > items.count or not Result
			loop
				Result := items [i].has_positive
				i := i + 1
			end
		end

feature {NONE} -- Implementation

	kind_name: STRING_8 = "Or"
			-- <Precursor>

end
