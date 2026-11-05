note
	description: "The Library tab, as LibraryScreen.kt has it: favorites, highlights, notes, journal, tags, history."
	author: "Larry Rix"

class
	SB_LIBRARY_TAB

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL)
		local
			l_top: PHONE_ROW
			l_names: ARRAY [STRING_32]
		do
			shell := a_shell
			state := a_shell.state
			theme := a_shell.theme
			ui := a_shell.ui
			controls := a_shell.controls
			create body.make (controls)
			create tab_body.make (controls)
			create speak_room.make (controls)
			create open_folders.make (8)
			create closed_folders.make (8)
			l_names := <<{STRING_32} "Favorites", {STRING_32} "Highlights", {STRING_32} "Notes", {STRING_32} "Journal", {STRING_32} "Tags", {STRING_32} "History">>
			tab_names := l_names
			create tabs.make_scrollable (ui, l_names)
			tabs.set_on_tab (agent tab_tapped)
			tab := 1
			highlight_color := -1
			l_top := ui.row
			l_top.extend_growing (tabs.root, 1)
			l_top.extend (speak_room)
			body.extend (l_top)
			body.extend_growing (tab_body, 1)
			refresh
		end

feature -- Access

	body: PHONE_COLUMN

feature -- Refreshing

	refresh
		do
			speak_room.clear
			speak_room.extend (shell.speak_button ("library:" + (tab - 1).out, {STRING_32} "Library %/183/ " + tab_names [tab], agent spoken))
			tab_body.clear
			inspect tab
			when 1 then
				show_favorites
			when 2 then
				show_highlights
			when 3 then
				show_notes
			when 4 then
				show_journal
			when 5 then
				show_tags
			else
				show_history
			end
		end

feature {NONE} -- Shared

	tab_tapped (a_tab: INTEGER)
		do
			tab := a_tab
			refresh
		end

	verse_row (a_page: PHONE_COLUMN; a_title, a_detail, a_preview: READABLE_STRING_32; a_action: PROCEDURE [TUPLE]; a_trailing: detachable PHONE_CONTROL)
			-- VerseRow: a title, a detail at its end, a preview, and perhaps a button.
		local
			l_row, l_top: PHONE_ROW
			l_text: PHONE_COLUMN
		do
			l_row := ui.row
			l_row.set_padding_each (20, 8, 4, 8)
			l_row.set_on_tap (a_action)
			l_text := ui.column
			l_top := ui.row
			l_top.extend_growing (ui.label (a_title, theme.Title_small, theme.primary), 1)
			if not (create {SB_KOTLIN_TEXT}.make).is_blank (a_detail) then
				l_top.extend (ui.padded (a_detail, theme.Label_small, theme.on_surface_variant, 0, 0, 12, 0))
			end
			l_text.extend (l_top)
			l_text.extend (ui.limited (ui.label (a_preview, theme.Body_small, theme.on_surface_variant), 2))
			l_row.extend_growing (l_text, 1)
			if attached a_trailing as al_trailing then
				l_row.extend (al_trailing)
			end
			a_page.extend (l_row)
			a_page.extend (ui.divider)
		end

	preview (a_key: INTEGER): STRING_32
		do
			Result := state.bible.preview_text (create {SB_REF}.make_from_key (a_key), state.version)
		end

	ref_of (a_key: INTEGER): SB_REF
		do
			create Result.make_from_key (a_key)
		end

	page_in_scroll: PHONE_COLUMN
			-- A new page, scrolling in the tab.
		do
			Result := ui.column
			tab_body.extend_growing (ui.scroller (Result), 1)
		end

feature {NONE} -- Favorites

	show_favorites
		local
			l_page: PHONE_COLUMN
			l_row: PHONE_ROW
			l_open: BOOLEAN
			l_items: ARRAYED_LIST [SB_FAVORITE]
			l_ref, l_shown: SB_REF
			l_icons: SB_ICONS
			l_last: PHONE_ROW
		do
			create l_icons
			l_page := page_in_scroll
			across state.user.folders as ic loop
				l_open := open_folders.has (ic.id) or (ic.id = 1 and not closed_folders.has (ic.id))
				l_row := ui.row
				l_row.set_padding_each (20, 6, 0, 6)
				l_row.set_on_tap (agent folder_tapped (ic.id, l_open))
				l_row.extend_growing (ui.label (if l_open then {STRING_32} "%/9662/  " + ic.name else {STRING_32} "%/9656/  " + ic.name end, theme.Title_medium, theme.on_background), 1)
				l_row.extend (ui.label (ic.count.out.to_string_32, theme.Label_large, theme.on_surface_variant))
				l_row.extend (ui.icon_button (l_icons.More_vert, theme.on_background, agent rename_folder (ic)))
				l_page.extend (l_row)
				if l_open then
					l_items := state.user.favorites (ic.id)
					if l_items.is_empty then
						l_page.extend (ui.padded (if ic.id = 1 then {STRING_32} "Tap %/9734/ on a verse to add it here." else {STRING_32} "Empty. Add verses with %/8942/ %/8594/ Add to a folder." end,
							theme.Body_small, theme.on_surface_variant, 40, 0, 0, 8))
					end
					across l_items as jc loop
						l_ref := ref_of (jc.key)
						if jc.whole_chapter then
							create l_shown.make (l_ref.book, l_ref.chapter, 0, 0)
						elseif jc.key_end > jc.key then
							create l_shown.make (l_ref.book, l_ref.chapter, l_ref.verse, jc.key_end \\ 1000)
						else
							l_shown := l_ref
						end
						verse_row (l_page, {STRING_32} "%/9733/  " + l_shown.label, {STRING_32} "",
							if jc.whole_chapter then {STRING_32} "Whole chapter" else state.bible.preview_text (l_shown, state.version) end,
							agent shell.go_to (l_shown), ui.icon_button (l_icons.Close, theme.on_background, agent remove_favorite (jc.id)))
					end
				end
			end
			l_last := ui.top_row
			l_last.set_padding (12, 12)
			l_last.extend (ui.text_button ({STRING_32} "+ New folder", agent new_folder))
			l_page.extend (l_last)
		end

	folder_tapped (a_id: INTEGER_64; a_was_open: BOOLEAN)
		do
			open_folders.prune_all (a_id)
			closed_folders.prune_all (a_id)
			if a_was_open then
				closed_folders.extend (a_id)
			else
				open_folders.extend (a_id)
			end
			refresh
		end

	remove_favorite (a_id: INTEGER_64)
		do
			state.user.remove_favorite (a_id)
			shell.touched
		end

	rename_folder (a_folder: SB_FOLDER)
		do
			shell.show_dialog (create {SB_FOLDER_NAME_DIALOG}.make (shell, a_folder))
		end

	new_folder
		do
			shell.show_dialog (create {SB_FOLDER_NAME_DIALOG}.make (shell, Void))
		end

feature {NONE} -- Highlights

	show_highlights
		local
			l_chips: PHONE_ROW
			l_gap: PHONE_COLUMN
			l_page: PHONE_COLUMN
			l_found: BOOLEAN
			l_names: ARRAY [STRING_32]
			i: INTEGER
			l_item: PHONE_ROW
			l_dot: PHONE_LABEL
			l_hold: PHONE_COLUMN
			l_text: STRING_32
		do
			l_names := theme.highlight_names
			l_chips := ui.row
			l_chips.set_padding (12, 0)
			l_chips.set_least_height (48)
			l_chips.extend (padded_chip (ui.filter_chip ({STRING_32} "All", highlight_color < 0, agent highlight_chip (-1))))
			from i := 0 until i > 3 loop
				l_chips.extend (padded_chip (ui.filter_chip (l_names [i + 1], highlight_color = i, agent highlight_chip (i))))
				i := i + 1
			end
			tab_body.extend (l_chips)
			l_page := page_in_scroll
			across state.user.highlights as ic loop
				if highlight_color < 0 or ic.color = highlight_color then
					l_found := True
					l_item := ui.row
					create l_dot.make (controls, {STRING_32} "")
					l_dot.set_height (12)
					l_dot.set_least_width (12)
					l_dot.set_surface (theme.with_alpha (theme.highlight (ic.color), 255), 6)
					l_gap := ui.column
					l_gap.set_padding_each (12, 0, 0, 0)
					l_gap.extend (l_dot)
					l_item.extend (l_gap)
					l_hold := ui.column
					l_text := if (create {SB_KOTLIN_TEXT}.make).is_blank (ic.reason) then l_names [ic.color + 1] else ic.reason end
					verse_row (l_hold, ref_of (ic.key).label, l_text, preview (ic.key), agent shell.go_to (ref_of (ic.key)), Void)
					l_item.extend_growing (l_hold, 1)
					l_page.extend (l_item)
				end
			end
			if not l_found then
				l_text := {STRING_32} "No highlights"
				if highlight_color >= 0 then
					l_text.append ({STRING_32} " in " + l_names [highlight_color + 1].as_lower)
				end
				l_page.extend (ui.empty (l_text + {STRING_32} " yet. Tap a verse, then a colour."))
			end
		end

	padded_chip (a_chip: PHONE_CONTROL): PHONE_ROW
		do
			Result := ui.top_row
			Result.set_padding_each (0, 0, 6, 0)
			Result.extend (a_chip)
		end

	highlight_chip (a_color: INTEGER)
		do
			highlight_color := a_color
			refresh
		end

	highlight_color: INTEGER
			-- The color shown, or -1 for all.

feature {NONE} -- Notes

	show_notes
		local
			l_page, l_box: PHONE_COLUMN
			l_list: ARRAYED_LIST [SB_NOTE]
			l_deleted: INTEGER
			l_top, l_room: PHONE_ROW
		do
			l_page := page_in_scroll
			l_deleted := state.user.deleted_notes.count
			l_list := if notes_deleted then state.user.deleted_notes else state.user.notes end
			if l_deleted > 0 or notes_deleted then
				l_room := ui.top_row
				l_room.set_padding (8, 0)
				l_room.extend (ui.text_button (if notes_deleted then {STRING_32} "%/8592/ Back to notes" else {STRING_32} "Deleted notes (" + l_deleted.out.to_string_32 + {STRING_32} ")" end, agent toggle_deleted_notes))
				l_page.extend (l_room)
			end
			if l_list.is_empty then
				l_page.extend (ui.empty (if notes_deleted then {STRING_32} "No deleted notes." else {STRING_32} "No notes yet. Tap a verse, then the pencil." end))
			end
			across l_list as ic loop
				l_box := ui.column
				l_box.set_padding_each (20, 10, 8, 10)
				if not notes_deleted then
					l_box.set_on_tap (agent open_note (ic.key))
				end
				l_top := ui.row
				l_top.extend_growing (ui.label (ref_of (ic.key).label, theme.Title_small, theme.primary), 1)
				if notes_deleted then
					l_top.extend (ui.text_button ({STRING_32} "Restore", agent restore_note (ic.id)))
				else
					l_top.extend (ui.label (shell.dates.medium (ic.updated), theme.Label_small, theme.on_surface_variant))
				end
				l_box.extend (l_top)
				l_box.extend (ui.limited (ui.label (ic.text, theme.Body_medium, theme.on_background), 4))
				l_box.extend (ui.limited (ui.label (preview (ic.key), theme.Body_small, theme.on_surface_variant), 2))
				l_page.extend (l_box)
				l_page.extend (ui.divider)
			end
		end

	toggle_deleted_notes
		do
			notes_deleted := not notes_deleted
			refresh
		end

	open_note (a_key: INTEGER)
		do
			shell.open (create {SB_NOTE_PAGE}.make (shell, a_key))
		end

	restore_note (a_id: INTEGER_64)
		do
			state.user.restore_note (a_id)
			shell.touched
		end

feature {NONE} -- Journal

	show_journal
		local
			l_page, l_box: PHONE_COLUMN
			l_entries: ARRAYED_LIST [SB_JOURNAL_ENTRY]
			l_deleted: INTEGER
			l_room, l_top: PHONE_ROW
			l_text: SB_KOTLIN_TEXT
		do
			create l_text.make
			l_page := page_in_scroll
			l_entries := state.user.journal (journal_deleted)
			l_deleted := state.user.journal (True).count
			l_room := ui.top_row
			l_room.set_padding (8, 0)
			if not journal_deleted then
				l_room.extend (ui.text_button ({STRING_32} "+ New entry", agent new_entry))
			end
			if l_deleted > 0 or journal_deleted then
				l_room.extend (ui.text_button (if journal_deleted then {STRING_32} "%/8592/ Back to journal" else {STRING_32} "Deleted (" + l_deleted.out.to_string_32 + {STRING_32} ")" end, agent toggle_deleted_journal))
			end
			l_page.extend (l_room)
			if l_entries.is_empty then
				l_page.extend (ui.empty (if journal_deleted then {STRING_32} "Nothing deleted." else {STRING_32} "A journal is for notes on a subject rather than one verse. References you write in it become links." end))
			end
			across l_entries as ic loop
				l_box := ui.column
				l_box.set_padding_each (20, 10, 8, 10)
				if not journal_deleted then
					l_box.set_on_tap (agent open_entry (ic.id))
				end
				l_top := ui.row
				l_top.extend_growing (ui.label (if l_text.is_blank (ic.title) then {STRING_32} "(untitled)" else ic.title end, theme.Title_small, theme.on_background), 1)
				if journal_deleted then
					l_top.extend (ui.text_button ({STRING_32} "Restore", agent restore_entry (ic.id)))
				else
					l_top.extend (ui.label (shell.dates.medium (ic.updated), theme.Label_small, theme.on_surface_variant))
				end
				l_box.extend (l_top)
				l_box.extend (ui.limited (ui.label (ic.body, theme.Body_small, theme.on_surface_variant), 2))
				l_page.extend (l_box)
				l_page.extend (ui.divider)
			end
		end

	toggle_deleted_journal
		do
			journal_deleted := not journal_deleted
			refresh
		end

	new_entry
		do
			shell.open (create {SB_JOURNAL_PAGE}.make (shell, state.user.new_journal_entry))
		end

	open_entry (a_id: INTEGER_64)
		do
			shell.open (create {SB_JOURNAL_PAGE}.make (shell, a_id))
		end

	restore_entry (a_id: INTEGER_64)
		do
			state.user.set_journal_deleted (a_id, False)
			shell.touched
		end

feature {NONE} -- Tags and history

	show_tags
		local
			l_tags: ARRAYED_LIST [SB_TAG]
			l_page: PHONE_COLUMN
			l_row: PHONE_ROW
		do
			l_tags := state.user.tags
			if l_tags.is_empty then
				tab_body.extend (ui.empty ({STRING_32} "No tags yet. Tap a verse, then %/8942/ %/8594/ Tag."))
			else
				l_page := page_in_scroll
				across l_tags as ic loop
					l_row := ui.top_row
					l_row.set_padding (20, 14)
					l_row.set_on_tap (agent open_tag (ic))
					l_row.extend_growing (ui.label ({STRING_32} "# " + ic.name, theme.Title_medium, theme.on_background), 1)
					l_row.extend (ui.label (ic.count.out.to_string_32, theme.Label_large, theme.on_surface_variant))
					l_page.extend (l_row)
					l_page.extend (ui.divider)
				end
			end
		end

	open_tag (a_tag: SB_TAG)
		do
			shell.open (create {SB_TAG_PAGE}.make (shell, a_tag.id, a_tag.name))
		end

	show_history
		local
			l_items: ARRAYED_LIST [SB_VISIT]
			l_page: PHONE_COLUMN
		do
			l_items := state.user.history
			if l_items.is_empty then
				tab_body.extend (ui.empty ({STRING_32} "Verses you open appear here."))
			else
				l_page := page_in_scroll
				across l_items as ic loop
					verse_row (l_page, ref_of (ic.key).label, shell.dates.medium (ic.at) + {STRING_32} "  %/183/  " + ic.version, preview (ic.key), agent shell.go_to (ref_of (ic.key)), Void)
				end
			end
		end

feature {NONE} -- Speech

	spoken: SB_BATCH
			-- A Library tab read aloud, in the order it is listed.
		local
			l_spoken: SB_SPOKEN
			l_text: SB_KOTLIN_TEXT
			l_ref, l_chapter: SB_REF
			l_names: ARRAY [STRING_32]
			l_title: STRING_32
		do
			create l_spoken.make (state)
			create l_text.make
			create Result.make ({STRING_32} "")
			inspect tab
			when 1 then
				across state.user.folders as ic loop
					Result.add ({STRING_32} "Folder: " + ic.name + {STRING_32} ", " + ic.count.out.to_string_32 + {STRING_32} ".", ic.name)
					across state.user.favorites (ic.id) as jc loop
						if jc.whole_chapter then
							l_ref := ref_of (jc.key)
							create l_chapter.make (l_ref.book, l_ref.chapter, 0, 0)
							Result.add (l_spoken.spoken_of (l_chapter) + {STRING_32} ", the whole chapter.", l_chapter.label)
						else
							Result.add_item (l_spoken.verse_speech (jc.key, state.version, l_spoken.verse_lead (jc.key)))
						end
					end
				end
			when 2 then
				l_names := theme.highlight_names
				across state.user.highlights as ic loop
					Result.add_item (l_spoken.verse_speech (ic.key, state.version, l_spoken.spoken_ref (ic.key) + {STRING_32} ", "
						+ if l_text.is_blank (ic.reason) then l_names [ic.color + 1] else ic.reason end + {STRING_32} ". "))
				end
			when 3 then
				across state.user.notes as ic loop
					Result.add (l_spoken.spoken_ref (ic.key) + {STRING_32} ". " + ic.text, ref_of (ic.key).label)
				end
			when 4 then
				across state.user.journal (False) as ic loop
					l_title := if l_text.is_blank (ic.title) then {STRING_32} "Untitled" else ic.title end
					Result.add (l_title + {STRING_32} ". " + ic.body, if l_text.is_blank (ic.title) then {STRING_32} "(untitled)" else ic.title end)
				end
			when 5 then
				across state.user.tags as ic loop
					Result.add (ic.name + {STRING_32} ", " + ic.count.out.to_string_32 + {STRING_32} ".", ic.name)
				end
			else
				across state.user.history as ic loop
					Result.add_item (l_spoken.verse_speech (ic.key, ic.version, l_spoken.verse_lead (ic.key)))
				end
			end
		end

feature {NONE} -- Implementation

	shell: SB_SHELL

	state: SB_STATE

	theme: SB_THEME

	ui: SB_UI

	controls: PHONE_CONTROLS

	tabs: SB_TABS

	tab_names: ARRAY [STRING_32]

	tab: INTEGER

	tab_body, speak_room: PHONE_COLUMN

	open_folders, closed_folders: ARRAYED_LIST [INTEGER_64]

	notes_deleted, journal_deleted: BOOLEAN

end
