note
	description: "[
		One dating claim for a timeline event. Kotlin's `note' is `note_text' here: `note' is a
		reserved word in Eiffel.
	]"
	author: "Larry Rix"

class
	SB_TL_CLAIM

create
	make

feature {NONE} -- Initialization

	make (a_label, a_chronology, a_held_by, a_basis: STRING_32; a_lean: BOOLEAN; a_note, a_citation: STRING_32)
			-- Create the claim.
		do
			label := a_label
			chronology := a_chronology
			held_by := a_held_by
			basis := a_basis
			lean := a_lean
			note_text := a_note
			citation := a_citation
		ensure
			label_set: label = a_label
			chronology_set: chronology = a_chronology
			held_by_set: held_by = a_held_by
			basis_set: basis = a_basis
			lean_set: lean = a_lean
			note_text_set: note_text = a_note
			citation_set: citation = a_citation
		end

feature -- Access

	label, chronology, held_by, basis: STRING_32
			-- What is claimed, by whom and why.

	lean: BOOLEAN
			-- Is this the preferred dating?

	note_text, citation: STRING_32
			-- What goes with it.

end
