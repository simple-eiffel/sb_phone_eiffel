note
	description: "A journal entry."
	author: "Larry Rix"

class
	SB_JOURNAL_ENTRY

create
	make

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_title, a_body: STRING_32; a_created, a_updated: INTEGER_64)
			-- Create the entry.
		do
			id := a_id
			title := a_title
			body := a_body
			created := a_created
			updated := a_updated
		ensure
			id_set: id = a_id
			title_set: title = a_title
			body_set: body = a_body
			created_set: created = a_created
			updated_set: updated = a_updated
		end

feature -- Access

	id: INTEGER_64
			-- The row id.

	title, body: STRING_32
			-- What it says.

	created, updated: INTEGER_64
			-- When, in ms.

end
