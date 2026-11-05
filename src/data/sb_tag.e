note
	description: "A tag, with how many verses carry it."
	author: "Larry Rix"

class
	SB_TAG

create
	make

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_name: STRING_32; a_count: INTEGER)
			-- Create the tag.
		do
			id := a_id
			name := a_name
			count := a_count
		ensure
			id_set: id = a_id
			name_set: name = a_name
			count_set: count = a_count
		end

feature -- Access

	id: INTEGER_64
			-- The row id.

	name: STRING_32
			-- Its name.

	count: INTEGER
			-- How many verses carry it.

end
