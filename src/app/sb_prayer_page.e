note
	description: "The prayer list: praying and answered. PrayerScreen in PersonalScreens.kt."
	author: "Larry Rix"

class
	SB_PRAYER_PAGE

inherit
	SB_OVERLAY
		redefine
			refresh
		end

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL)
		do
			make_overlay (a_shell, {STRING_32} "Prayer list")
			create tab_body.make (controls)
			create tabs.make (ui, <<{STRING_32} "Praying", {STRING_32} "Answered">>)
			tabs.set_on_tab (agent tab_tapped)
			tab := 1
			content.extend (tabs.root)
			content.extend_growing (tab_body, 1)
			refresh
		end

feature -- Refreshing

	refresh
		local
			l_list: ARRAYED_LIST [SB_PRAYER]
			l_page, l_box: PHONE_COLUMN
			l_row: PHONE_ROW
			l_ref: SB_REF
			l_link: PHONE_LABEL
			l_icons: SB_ICONS
			l_text: SB_KOTLIN_TEXT
		do
			create l_icons
			create l_text.make
			actions.clear
			actions.extend (shell.speak_button ("prayers:" + (tab - 1).out, if tab = 1 then {STRING_32} "Prayer list" else {STRING_32} "Answered prayers" end, agent spoken))
			actions.extend (ui.icon_button (l_icons.Add, theme.on_surface_variant, agent add))
			tab_body.clear
			l_list := state.user.prayers (tab = 2)
			if l_list.is_empty then
				tab_body.extend (ui.empty (if tab = 1 then {STRING_32} "Nothing on the list. Tap + to add a prayer." else {STRING_32} "Answered prayers appear here." end))
			else
				l_page := ui.column
				across l_list as ic loop
					l_box := ui.tappable_column (agent edit (ic), 20, 10)
					l_box.extend (ui.label (ic.title, theme.Title_medium, theme.on_background))
					if not l_text.is_blank (ic.details) then
						l_box.extend (ui.limited (ui.label (ic.details, theme.Body_medium, theme.on_background), 3))
					end
					if ic.key /= 0 then
						create l_ref.make_from_key (ic.key)
						l_link := ui.label (l_ref.label + {STRING_32} "  %/8594/", theme.Body_large, theme.primary)
						l_link.set_padding (0, 4)
						l_link.set_on_tap (agent shell.go_to (l_ref))
						l_box.extend (l_link)
					end
					l_row := ui.row
					l_row.extend_growing (ui.label (if ic.answered > 0 then {STRING_32} "Answered " + shell.dates.medium (ic.answered) else {STRING_32} "Since " + shell.dates.medium (ic.created) end, theme.Label_medium, theme.on_surface_variant), 1)
					if ic.answered = 0 then
						l_row.extend (ui.text_button ({STRING_32} "Answered%/8230/", agent answer (ic)))
					else
						l_row.extend (ui.text_button ({STRING_32} "Pray again", agent reopen (ic.id)))
					end
					l_box.extend (l_row)
					if not l_text.is_blank (ic.answer) then
						l_box.extend (ui.semi_bold (ic.answer, theme.Body_medium, theme.secondary))
					end
					l_page.extend (l_box)
					l_page.extend (ui.divider)
				end
				tab_body.extend_growing (ui.scroller (l_page), 1)
			end
		end

feature {NONE} -- Implementation

	tab_tapped (a_tab: INTEGER)
		do
			tab := a_tab
			refresh
		end

	add
		do
			shell.show_dialog (create {SB_PRAYER_DIALOG}.make (shell, Void))
		end

	edit (a_prayer: SB_PRAYER)
		do
			shell.show_dialog (create {SB_PRAYER_DIALOG}.make (shell, a_prayer))
		end

	answer (a_prayer: SB_PRAYER)
		local
			l_ask: SB_DIALOG
			l_field: PHONE_FIELD
		do
			create l_ask.make (shell, {STRING_32} "Answered: " + a_prayer.title)
			l_field := ui.field ({STRING_32} "How it was answered (optional)")
			l_field.set_multi_line (4)
			l_field.set_box_height (132)
			l_ask.content.extend (l_field)
			l_ask.add_close ({STRING_32} "Cancel")
			l_ask.add_button ({STRING_32} "Mark answered", agent mark_answered (a_prayer, l_field))
			shell.show_dialog (l_ask)
		end

	mark_answered (a_prayer: SB_PRAYER; a_field: PHONE_FIELD)
		do
			state.user.answer_prayer (a_prayer.id, a_field.text)
			shell.close_dialog
			shell.touched
		end

	reopen (a_id: INTEGER_64)
		do
			state.user.reopen_prayer (a_id)
			shell.touched
		end

	spoken: SB_BATCH
		local
			l_parts: ARRAYED_LIST [READABLE_STRING_32]
			l_spoken: SB_SPOKEN
			l_ref: SB_REF
			l_text: SB_KOTLIN_TEXT
		do
			create l_spoken.make (state)
			create l_text.make
			create Result.make ({STRING_32} "")
			across state.user.prayers (tab = 2) as ic loop
				create l_parts.make (4)
				if not l_text.is_blank (ic.title) then
					l_parts.extend (ic.title)
				end
				if not l_text.is_blank (ic.details) then
					l_parts.extend (ic.details)
				end
				if ic.key /= 0 then
					create l_ref.make_from_key (ic.key)
					l_parts.extend (l_spoken.spoken_of (l_ref) + {STRING_32} ". " + state.bible.preview_text (l_ref, state.version))
				end
				if not l_text.is_blank (ic.answer) then
					l_parts.extend ({STRING_32} "Answered: " + ic.answer)
				end
				Result.add (l_spoken.joined (l_parts, {STRING_32} ". "), ic.title)
			end
		end

	tabs: SB_TABS

	tab: INTEGER

	tab_body: PHONE_COLUMN

end
