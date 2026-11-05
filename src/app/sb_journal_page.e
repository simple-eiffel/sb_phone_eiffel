note
	description: "A journal entry: writing with references in it, each opening its verse. JournalScreen in PersonalScreens.kt."
	author: "Larry Rix"

class
	SB_JOURNAL_PAGE

inherit
	SB_OVERLAY
		redefine
			closing
		end

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL; a_id: INTEGER_64)
		local
			l_text: SB_KOTLIN_TEXT
		do
			make_overlay (a_shell, {STRING_32} "Journal entry")
			id := a_id
			create l_text.make
			entry := state.user.journal_entry (a_id)
			create title.make_empty
			create entry_body.make_empty
			if attached entry as al_entry then
				title := al_entry.title.twin
				entry_body := al_entry.body.twin
			end
			is_editing := l_text.is_blank (entry_body)
			create title_field.make (controls, {STRING_32} "Title", theme.primary, theme.outline, theme.on_surface_variant, theme.on_background)
			create body_field.make (controls, {STRING_32} "Entry", theme.primary, theme.outline, theme.on_surface_variant, theme.on_background)
			title_field.set_on_change (agent title_typed)
			body_field.set_multi_line (6)
			show
		end

feature -- Closing

	closing
		do
			read_fields
			if not deleted then
				state.user.save_journal (id, title, entry_body)
				shell.touched
			end
		end

feature {NONE} -- Showing

	show
		local
			l_room, l_page: PHONE_COLUMN
			l_text: SB_KOTLIN_TEXT
			l_gap: PHONE_COLUMN
			l_header: STRING_32
			l_links: SB_REF_LINKS
		do
			create l_text.make
			l_header := if l_text.is_blank (title) then {STRING_32} "Journal entry" else title end
			set_title (l_header)
			actions.clear
			actions.extend (shell.speak_button ("journal:" + id.out, l_header, agent spoken))
			actions.extend (ui.text_button (if is_editing then {STRING_32} "Done" else {STRING_32} "Edit" end, agent toggle))
			actions.extend (ui.text_button ({STRING_32} "Delete", agent delete))
			content.clear
			l_room := ui.column
			l_room.set_padding (16, 16)
			if is_editing then
				create title_field.make (controls, {STRING_32} "Title", theme.primary, theme.outline, theme.on_surface_variant, theme.on_background)
				create body_field.make (controls, {STRING_32} "Entry", theme.primary, theme.outline, theme.on_surface_variant, theme.on_background)
				title_field.set_on_change (agent title_typed)
				body_field.set_multi_line (6)
				title_field.set_text (title)
				body_field.set_text (entry_body)
				l_room.extend (title_field)
				l_gap := ui.column
				l_gap.set_padding_each (0, 8, 0, 0)
				l_gap.extend_growing (body_field, 1)
				l_room.extend_growing (l_gap, 1)
				l_room.extend (ui.padded ({STRING_32} "Write references like John 3:16 or Rom 8:28-30; in reading view they open the verse. Every saved version is kept.", theme.Body_small, theme.on_surface_variant, 0, 6, 0, 0))
				content.extend_growing (l_room, 1)
			else
				l_page := ui.column
				if not l_text.is_blank (title) then
					l_page.extend (ui.padded (title, theme.Headline_small, theme.on_background, 0, 0, 0, 8))
				end
				if attached entry as al_entry then
					l_page.extend (ui.label ({STRING_32} "Started " + shell.dates.medium (al_entry.created), theme.Label_medium, theme.on_surface_variant))
				end
				create l_links.make (shell, entry_body)
				l_page.extend (l_links.text)
				l_room.extend (l_page)
				content.extend_growing (ui.scroller (l_room), 1)
			end
		end

	title_typed
		do
			title := title_field.text.to_string_32
			set_title (if (create {SB_KOTLIN_TEXT}.make).is_blank (title) then {STRING_32} "Journal entry" else title end)
		end

	read_fields
		do
			if is_editing then
				title := title_field.text.to_string_32
				entry_body := body_field.text.to_string_32
			end
		end

	toggle
		do
			read_fields
			if is_editing then
				state.user.save_journal (id, title, entry_body)
				shell.touched
			end
			is_editing := not is_editing
			show
		end

	delete
		do
			read_fields
			state.user.save_journal (id, title, entry_body)
			state.user.set_journal_deleted (id, True)
			deleted := True
			shell.touched
			shell.back
		end

	spoken: SB_BATCH
		do
			read_fields
			create Result.make ({STRING_32} "")
			Result.add (if (create {SB_KOTLIN_TEXT}.make).is_blank (title) then {STRING_32} "Journal entry." else title + {STRING_32} "." end, {STRING_32} "Title")
			(create {SB_SPOKEN}.make (state)).add_paragraphs (Result, entry_body)
		end

feature {NONE} -- Implementation

	id: INTEGER_64

	entry: detachable SB_JOURNAL_ENTRY

	title, entry_body: STRING_32

	is_editing, deleted: BOOLEAN

	title_field, body_field: PHONE_FIELD

end
