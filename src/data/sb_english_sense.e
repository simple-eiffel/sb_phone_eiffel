note
	description: "What a period or modern dictionary says of an English word."
	author: "Larry Rix"

class
	SB_ENGLISH_SENSE

create
	make

feature {NONE} -- Initialization

	make (a_source, a_year, a_sense_no, a_pos, a_text, a_cite: STRING_32)
			-- Create the sense.
		do
			source := a_source
			year := a_year
			sense_no := a_sense_no
			pos := a_pos
			text := a_text
			cite := a_cite
		ensure
			source_set: source = a_source
			year_set: year = a_year
			sense_no_set: sense_no = a_sense_no
			pos_set: pos = a_pos
			text_set: text = a_text
			cite_set: cite = a_cite
		end

feature -- Access

	source, year, sense_no, pos, text, cite: STRING_32
			-- What it says, and where.

end
