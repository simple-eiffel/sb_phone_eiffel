note
	description: "One entry of the prayer list."
	author: "Larry Rix"

class
	SB_PRAYER

create
	make

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_title, a_details: STRING_32; a_key: INTEGER; a_created, a_answered: INTEGER_64; a_answer: STRING_32)
			-- Create the entry.
		do
			id := a_id
			title := a_title
			details := a_details
			key := a_key
			created := a_created
			answered := a_answered
			answer := a_answer
		ensure
			id_set: id = a_id
			title_set: title = a_title
			details_set: details = a_details
			key_set: key = a_key
			created_set: created = a_created
			answered_set: answered = a_answered
			answer_set: answer = a_answer
		end

feature -- Access

	id: INTEGER_64
			-- The row id.

	title, details: STRING_32
			-- What it says.

	key: INTEGER
			-- A verse to pray, 0 for none.

	created, answered: INTEGER_64
			-- When, in ms; `answered' is 0 while it is open.

	answer: STRING_32
			-- How it was answered.

end
