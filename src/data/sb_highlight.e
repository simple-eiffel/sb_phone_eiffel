note
	description: "A highlighted verse: color 0 to 3, with an optional reason."
	author: "Larry Rix"

class
	SB_HIGHLIGHT

create
	make

feature {NONE} -- Initialization

	make (a_key, a_color: INTEGER; a_reason: STRING_32; a_created: INTEGER_64)
			-- Create the highlight.
		do
			key := a_key
			color := a_color
			reason := a_reason
			created := a_created
		ensure
			key_set: key = a_key
			color_set: color = a_color
			reason_set: reason = a_reason
			created_set: created = a_created
		end

feature -- Access

	key, color: INTEGER
			-- The verse and the color.

	reason: STRING_32
			-- Why, if said.

	created: INTEGER_64
			-- When, in ms.

end
