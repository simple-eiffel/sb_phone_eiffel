note
	description: "A note on a verse."
	author: "Larry Rix"

class
	SB_NOTE

create
	make

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_key: INTEGER; a_text: STRING_32; a_created, a_updated: INTEGER_64)
			-- Create the note.
		do
			id := a_id
			key := a_key
			text := a_text
			created := a_created
			updated := a_updated
		ensure
			id_set: id = a_id
			key_set: key = a_key
			text_set: text = a_text
			created_set: created = a_created
			updated_set: updated = a_updated
		end

feature -- Access

	id: INTEGER_64
			-- The row id.

	key: INTEGER
			-- The verse.

	text: STRING_32
			-- What it says.

	created, updated: INTEGER_64
			-- When, in ms.

end
