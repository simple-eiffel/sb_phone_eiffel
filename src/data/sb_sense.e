note
	description: "[
		One sense of a lemma in one dictionary. Kotlin's `note' is `note_text' here: `note' is a
		reserved word in Eiffel.
	]"
	author: "Larry Rix"

class
	SB_SENSE

create
	make

feature {NONE} -- Initialization

	make (a_source, a_entry: STRING_32; a_depth: INTEGER; a_label, a_gloss, a_text, a_domain, a_note: STRING_32)
			-- Create the sense.
		do
			source := a_source
			entry := a_entry
			depth := a_depth
			label := a_label
			gloss := a_gloss
			text := a_text
			domain := a_domain
			note_text := a_note
		ensure
			source_set: source = a_source
			entry_set: entry = a_entry
			depth_set: depth = a_depth
			label_set: label = a_label
			gloss_set: gloss = a_gloss
			text_set: text = a_text
			domain_set: domain = a_domain
			note_text_set: note_text = a_note
		end

feature -- Access

	source, entry: STRING_32
			-- The dictionary and its entry.

	depth: INTEGER
			-- How deep it is in the entry's outline.

	label, gloss, text, domain, note_text: STRING_32
			-- What the dictionary says.

end
