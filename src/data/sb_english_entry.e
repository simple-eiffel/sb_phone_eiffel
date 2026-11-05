note
	description: "An English word: its dictionary form, the KJV forms of it, the words behind it, its meanings, and Wright's citations."
	author: "Larry Rix"

class
	SB_ENGLISH_ENTRY

create
	make

feature {NONE} -- Initialization

	make (a_lemma: STRING_32; a_forms: ARRAYED_LIST [STRING_32]; a_behind: ARRAYED_LIST [SB_BEHIND]; a_senses: ARRAYED_LIST [SB_ENGLISH_SENSE]; a_shifts: ARRAYED_LIST [INTEGER])
			-- Create the entry.
		do
			lemma := a_lemma
			forms := a_forms
			behind := a_behind
			senses := a_senses
			shifts := a_shifts
		ensure
			lemma_set: lemma = a_lemma
			forms_set: forms = a_forms
			behind_set: behind = a_behind
			senses_set: senses = a_senses
			shifts_set: shifts = a_shifts
		end

feature -- Access

	lemma: STRING_32
			-- The dictionary form.

	forms: ARRAYED_LIST [STRING_32]
			-- The forms of it in the KJV.

	behind: ARRAYED_LIST [SB_BEHIND]
			-- The Hebrew and Greek words behind it.

	senses: ARRAYED_LIST [SB_ENGLISH_SENSE]
			-- What the dictionaries say.

	shifts: ARRAYED_LIST [INTEGER]
			-- The verse keys Wright cites for it.

end
