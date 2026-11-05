note
	description: "Edits the note on one verse. It saves when you leave; every saved text is kept, and a deleted note can be restored. NoteEditScreen."
	author: "Larry Rix"

class
	SB_NOTE_PAGE

inherit
	SB_OVERLAY
		redefine
			closing
		end

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL; a_key: INTEGER)
		local
			l_ref: SB_REF
			l_room: PHONE_COLUMN
		do
			create l_ref.make_from_key (a_key)
			make_overlay (a_shell, {STRING_32} "Note %/183/ " + l_ref.short_label)
			key := a_key
			create field.make (controls, {STRING_32} "Your note", theme.primary, theme.outline, theme.on_surface_variant, theme.on_background)
			if attached state.user.note_for (a_key) as al_note then
				initial := al_note.text
			else
				initial := {STRING_32} ""
			end
			actions.extend (shell.speak_button ("note:" + a_key.out, {STRING_32} "Note %/183/ " + l_ref.short_label, agent spoken))
			actions.extend (ui.text_button ({STRING_32} "Open verse", agent shell.go_to (l_ref)))
			if not initial.is_empty then
				actions.extend (ui.text_button ({STRING_32} "Delete", agent delete))
			end
			l_room := ui.column
			l_room.set_padding (16, 16)
			l_room.extend (ui.padded (state.bible.preview_text (l_ref, state.version), theme.Body_medium, theme.on_surface_variant, 0, 0, 0, 12))
			field.set_multi_line (6)
			field.set_text (initial)
			l_room.extend_growing (field, 1)
			l_room.extend (ui.padded ({STRING_32} "Saved when you leave this page. Earlier versions are kept. A deleted note can be restored from Library %/8594/ Notes.", theme.Body_small, theme.on_surface_variant, 0, 8, 0, 0))
			content.extend_growing (l_room, 1)
		end

feature -- Closing

	closing
		do
			if not deleted then
				state.user.save_note (key, field.text)
			end
			shell.touched
		end

feature {NONE} -- Implementation

	delete
		do
			state.user.save_note (key, {STRING_32} "")
			deleted := True
			shell.back
		end

	spoken: SB_BATCH
		local
			l_spoken: SB_SPOKEN
		do
			create l_spoken.make (state)
			create Result.make ({STRING_32} "")
			Result.add_item (l_spoken.verse_speech (key, state.version, l_spoken.verse_lead (key)))
			Result.add ({STRING_32} "Your note. " + field.text, {STRING_32} "Your note")
		end

	key: INTEGER

	field: PHONE_FIELD

	initial: READABLE_STRING_32

	deleted: BOOLEAN

end
