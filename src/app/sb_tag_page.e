note
	description: "The verses carrying a tag. TagVersesScreen in PersonalScreens.kt."
	author: "Larry Rix"

class
	SB_TAG_PAGE

inherit
	SB_OVERLAY
		redefine
			refresh
		end

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL; a_tag: INTEGER_64; a_name: READABLE_STRING_32)
		do
			make_overlay (a_shell, {STRING_32} "Tag %/183/ " + a_name)
			tag := a_tag
			name := a_name
			actions.extend (shell.speak_button ("tag:" + a_tag.out, {STRING_32} "Tag %/183/ " + a_name, agent spoken))
			actions.extend (ui.text_button ({STRING_32} "Delete tag", agent ask_delete))
			refresh
		end

feature -- Refreshing

	refresh
		local
			l_keys: ARRAYED_LIST [INTEGER]
			l_page, l_text: PHONE_COLUMN
			l_row: PHONE_ROW
			l_ref: SB_REF
			l_icons: SB_ICONS
		do
			create l_icons
			content.clear
			l_keys := state.user.tagged_keys (tag)
			if l_keys.is_empty then
				content.extend (ui.empty ({STRING_32} "No verses carry this tag."))
			else
				l_page := ui.column
				across l_keys as ic loop
					create l_ref.make_from_key (ic)
					l_row := ui.row
					l_row.set_padding_each (20, 8, 0, 8)
					l_row.set_on_tap (agent shell.go_to (l_ref))
					l_text := ui.column
					l_text.extend (ui.label (l_ref.label, theme.Title_small, theme.primary))
					l_text.extend (ui.limited (ui.label (state.bible.preview_text (l_ref, state.version), theme.Body_medium, theme.on_background), 3))
					l_row.extend_growing (l_text, 1)
					l_row.extend (ui.icon_button (l_icons.Close, theme.on_background, agent remove (ic)))
					l_page.extend (l_row)
					l_page.extend (ui.divider)
				end
				content.extend_growing (ui.scroller (l_page), 1)
			end
		end

feature {NONE} -- Implementation

	remove (a_key: INTEGER)
		do
			state.user.set_tagged (a_key, tag, False)
			shell.touched
		end

	ask_delete
		local
			l_ask: SB_DIALOG
		do
			create l_ask.make (shell, {STRING_32} "Delete the tag %/8220/" + name + {STRING_32} "%/8221/?")
			l_ask.content.extend (ui.label ({STRING_32} "The verses stay; only the tag is removed from them.", theme.Body_medium, theme.on_surface_variant))
			l_ask.add_close ({STRING_32} "Keep")
			l_ask.add_button ({STRING_32} "Delete tag", agent delete)
			shell.show_dialog (l_ask)
		end

	delete
		do
			state.user.delete_tag (tag)
			shell.close_dialog
			shell.touched
			shell.back
		end

	spoken: SB_BATCH
		do
			Result := (create {SB_SPOKEN}.make (state)).verses_batch (state.user.tagged_keys (tag))
		end

	tag: INTEGER_64

	name: READABLE_STRING_32

end
