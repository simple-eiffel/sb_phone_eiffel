note
	description: "One lane of the timeline."
	author: "Larry Rix"

class
	SB_LANE

create
	make

feature {NONE} -- Initialization

	make (a_id, a_title, a_group: STRING_32)
			-- Create the lane.
		do
			id := a_id
			title := a_title
			group := a_group
		ensure
			id_set: id = a_id
			title_set: title = a_title
			group_set: group = a_group
		end

feature -- Access

	id, title, group: STRING_32
			-- What it is.

end
