note
	description: "A folder of favorites, with how many it holds."
	author: "Larry Rix"

class
	SB_FOLDER

create
	make

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_name: STRING_32; a_count: INTEGER)
			-- Create the folder.
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
			-- How many favorites it holds.

end
