note
	description: "Adds or edits a prayer. PrayerDialog in PersonalScreens.kt."
	author: "Larry Rix"

class
	SB_PRAYER_DIALOG

inherit
	SB_DIALOG
		rename
			make as make_dialog
		end

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL; a_prayer: detachable SB_PRAYER)
		local
			l_ui: SB_UI
			l_gap: PHONE_COLUMN
		do
			make_dialog (a_shell, if attached a_prayer then {STRING_32} "Prayer" else {STRING_32} "New prayer" end)
			the_shell := a_shell
			prayer := a_prayer
			l_ui := a_shell.ui
			title_field := l_ui.field ({STRING_32} "For")
			details_field := l_ui.field ({STRING_32} "Details (optional)")
			ref_field := l_ui.field ({STRING_32} "A verse to pray (optional)")
			warning := l_ui.label ({STRING_32} "That doesn't read as one verse.", a_shell.theme.Body_small, a_shell.theme.error)
			warning.set_visible (False)
			details_field.set_multi_line (3)
			details_field.set_box_height (112)
			title_field.set_on_change (agent check_ref)
			ref_field.set_placeholder ({STRING_32} "phil 4 6")
			ref_field.set_on_change (agent check_ref)
			if attached a_prayer as al_prayer then
				title_field.set_text (al_prayer.title)
				details_field.set_text (al_prayer.details)
				if al_prayer.key /= 0 then
					ref_field.set_text ((create {SB_REF}.make_from_key (al_prayer.key)).short_label)
				end
				add_button ({STRING_32} "Delete", agent delete)
			end
			content.extend (title_field)
			l_gap := l_ui.column
			l_gap.set_padding_each (0, 8, 0, 8)
			l_gap.extend (details_field)
			content.extend (l_gap)
			content.extend (ref_field)
			content.extend (warning)
			add_close ({STRING_32} "Cancel")
			add_button ({STRING_32} "Save", agent save)
			save_button := last_button
			check_ref
		end

feature {NONE} -- Implementation

	ref_ok: BOOLEAN
		do
			Result := (create {SB_KOTLIN_TEXT}.make).is_blank (ref_field.text)
				or else attached {SB_REF_PARSE_ONE} (create {SB_REF_PARSER}.make).parse (ref_field.text)
		end

	check_ref
		do
			warning.set_visible (not ref_ok)
			show_enabled (save_button, ref_ok and not (create {SB_KOTLIN_TEXT}.make).is_blank (title_field.text))
		end

	save
		local
			l_key: INTEGER
			l_id: detachable INTEGER_64_REF
		do
			if ref_ok and not (create {SB_KOTLIN_TEXT}.make).is_blank (title_field.text) then
				if attached {SB_REF_PARSE_ONE} (create {SB_REF_PARSER}.make).parse (ref_field.text) as al_one then
					l_key := (create {SB_REF}.make (al_one.ref.book, al_one.ref.chapter, al_one.ref.verse.max (1), 0)).key
				end
				if attached prayer as al_prayer then
					l_id := al_prayer.id
				end
				the_shell.state.user.save_prayer (l_id, title_field.text, details_field.text, l_key)
				the_shell.close_dialog
				the_shell.touched
			end
		end

	delete
		do
			if attached prayer as al_prayer then
				the_shell.state.user.delete_prayer (al_prayer.id)
			end
			the_shell.close_dialog
			the_shell.touched
		end

	the_shell: SB_SHELL

	prayer: detachable SB_PRAYER

	title_field, details_field, ref_field: PHONE_FIELD

	warning: PHONE_LABEL

	save_button: PHONE_LABEL
		attribute
			Result := last_button
		end

end
