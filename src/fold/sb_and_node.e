note
	description: "Every item is required."
	author: "Larry Rix"

class
	SB_AND_NODE

inherit
	SB_LIST_NODE

create
	make

feature -- Status

	has_positive: BOOLEAN
			-- Does any item ask for something?
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > items.count or Result
			loop
				Result := items [i].has_positive
				i := i + 1
			end
		end

feature {NONE} -- Implementation

	kind_name: STRING_8 = "And"
			-- <Precursor>

end
