note
	description: "[
		The sheet a tapped verse opens, as VerseSheet.kt has it: its marks and actions, then
		tabs for the original words, the cross-references, the versions and the user's packs.
	]"
	author: "Larry Rix"

class
	SB_VERSE_SHEET

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL; a_key: INTEGER)
		do
			shell := a_shell
			key := a_key
			state := a_shell.state
			theme := a_shell.theme
			ui := a_shell.ui
			controls := a_shell.controls
			create root.make (controls, theme.surface_container_low, theme.on_surface_variant)
			create holder.make (controls)
			create marks_row.make (controls)
			create tabs.make (ui, if a_shell.packs.is_empty then <<{STRING_32} "Original", {STRING_32} "Cross-refs", {STRING_32} "Compare">> else <<{STRING_32} "Original", {STRING_32} "Cross-refs", {STRING_32} "Compare", {STRING_32} "Mine">> end)
			create tab_body.make (controls)
			create reason_room.make (controls)
			create star_icon.make (controls, (create {SB_ICONS}).Star_outline, theme.on_background)
			create more_icon.make (controls, (create {SB_ICONS}).More_vert, theme.on_background)
			root.set_on_gone (agent gone)
			tabs.set_on_tab (agent tab_tapped)
			holder.extend (ui.padded (ref.label, theme.Title_large, theme.on_background, 20, 0, 20, 0))
			holder.extend (marks_row)
			holder.extend (reason_room)
			holder.extend (tabs.root)
			holder.extend_growing (tab_body, 1)
			root.extend (holder)
			show_marks
			show_tab
		ensure
			key_set: key = a_key
		end

feature -- Access

	root: PHONE_SHEET

	key: INTEGER

feature -- Refreshing

	refresh
			-- The user's marks have changed.
		do
			show_marks
		end

	dismiss
			-- Slide away.
		do
			root.dismiss
		end

feature {NONE} -- Marks and actions

	show_marks
		local
			l_highlight: detachable SB_HIGHLIGHT
			i: INTEGER
			l_on: BOOLEAN
			l_dot: PHONE_LABEL
			l_room: PHONE_LABEL
			l_star: BOOLEAN
			l_icons: SB_ICONS
		do
			create l_icons
			l_highlight := state.user.highlight (key)
			l_star := state.user.starred_keys.has (key)
			marks_row.clear
			marks_row.set_padding (12, 4)
			marks_row.call_integer ("setGravity", 16)
			from i := 0 until i > 3 loop
				l_on := attached l_highlight as al_highlight and then al_highlight.color = i
				create l_dot.make (controls, {STRING_32} "")
				l_dot.set_height (28)
				l_dot.set_least_width (28)
				if l_on then
					l_dot.set_bordered_surface (theme.with_alpha (theme.highlight (i), 230), 14, theme.on_background, 2)
				else
					l_dot.set_surface (theme.with_alpha (theme.highlight (i), 230), 14)
				end
				l_dot.set_on_tap (agent highlight_tapped (i, l_on))
				marks_row.extend (spaced (l_dot))
				i := i + 1
			end
			create l_room.make (controls, {STRING_32} "")
			marks_row.extend_growing (l_room, 1)
			create star_icon.make (controls, if l_star then l_icons.Star else l_icons.Star_outline end, if l_star then theme.primary else theme.on_background end)
			star_icon.set_padding (12, 12)
			star_icon.set_on_tap (agent star_tapped)
			marks_row.extend (star_icon)
			marks_row.extend (ui.icon_button (l_icons.Note_icon, theme.on_background, agent note_tapped))
			marks_row.extend (shell.speak_button ("sheet:" + key.out + ":" + tab.out, ref.label, agent sheet_speech))
			create more_icon.make (controls, l_icons.More_vert, theme.on_background)
			more_icon.set_padding (12, 12)
			more_icon.set_on_tap (agent menu_tapped)
			marks_row.extend (more_icon)
			show_reason (l_highlight)
		end

	spaced (a_child: PHONE_CONTROL): PHONE_ROW
			-- `a_child' with 3 around it.
		do
			create Result.make (controls)
			Result.set_padding (3, 3)
			Result.extend (a_child)
		end

	show_reason (a_highlight: detachable SB_HIGHLIGHT)
		local
			l_names: ARRAY [STRING_32]
			l_field: PHONE_FIELD
		do
			reason_room.clear
			reason_field := Void
			if attached a_highlight as al_highlight then
				l_names := theme.highlight_names
				l_field := ui.field (l_names [al_highlight.color + 1] + {STRING_32} " highlight %/183/ reason (optional)")
				l_field.set_keyboard_action (l_field.Action_done)
				l_field.set_text (al_highlight.reason)
				saved_reason := al_highlight.reason
				l_field.set_on_action (agent reason_done)
				l_field.set_on_left (agent reason_done)
				reason_room.set_padding (16, 0)
				reason_room.extend (l_field)
				reason_field := l_field
			end
		end

	reason_done
		do
			if attached reason_field as al_field and then not al_field.text.same_string (saved_reason) then
				saved_reason := al_field.text
				state.user.set_highlight_reason (key, al_field.text)
				shell.touched
			end
		end

	highlight_tapped (a_index: INTEGER; a_chosen: BOOLEAN)
		do
			if a_chosen then
				state.user.set_highlight (key, Void)
			else
				state.user.set_highlight (key, a_index)
			end
			shell.touched
		end

	star_tapped
		local
			l_added: BOOLEAN
		do
			l_added := state.user.toggle_star (key, state.version)
			shell.touched
			controls.toast (if l_added then {STRING_32} "Added to Favorites" else {STRING_32} "Removed from favorites" end)
		end

	note_tapped
		do
			shell.dismiss_sheet
			shell.open (create {SB_NOTE_PAGE}.make (shell, key))
		end

	menu_tapped
		local
			l_rows: ARRAY [PHONE_RICH_ROW]
			l_tags: INTEGER
			l_card: BOOLEAN
		do
			l_tags := state.user.tags_of (key).count
			l_card := state.user.has_card (key)
			l_rows := <<menu_row ({STRING_32} "Add to a folder%/8230/"),
				menu_row (if l_tags > 0 then {STRING_32} "Tags (" + l_tags.out.to_string_32 + {STRING_32} ")%/8230/" else {STRING_32} "Tag%/8230/" end),
				menu_row (if l_card then {STRING_32} "Memory card %/10003/" else {STRING_32} "Add to memory cards" end),
				menu_row ({STRING_32} "Read the chapter aloud from here"),
				menu_row ({STRING_32} "Copy with credit"),
				menu_row ({STRING_32} "Share%/8230/")>>
			controls.show_dropdown (more_icon, l_rows, theme.surface_container, agent menu_chosen (?, l_card))
		end

	menu_row (a_text: READABLE_STRING_32): PHONE_RICH_ROW
		do
			create Result.make (0, 12, 14)
			theme.add_style (Result, theme.Label_large, theme.on_background)
			Result.add_text (a_text)
		end

	menu_chosen (a_index: INTEGER; a_card: BOOLEAN)
		do
			inspect a_index
			when 1 then
				shell.show_dialog (create {SB_FOLDER_DIALOG}.make (shell, key))
			when 2 then
				shell.show_dialog (create {SB_TAG_DIALOG}.make (shell, key))
			when 3 then
				if not a_card then
					state.user.add_card (key, 0)
					shell.touched
					controls.toast ({STRING_32} "Added to memory cards")
				end
			when 4 then
				shell.dismiss_sheet
				shell.read_chapter (state.bible.page_of (ref.book, ref.chapter), key)
			when 5 then
				shell.services.copy_text (with_credit)
				controls.toast ({STRING_32} "Copied with its credit")
			when 6 then
				shell.services.share_text (with_credit)
			else
			end
		end

	with_credit: STRING_32
			-- The verse with its reference, version and the version's credit line.
		local
			l_text: STRING_32
		do
			create l_text.make (120)
			across state.bible.verses_at (key, state.version) as ic loop
				if not l_text.is_empty then
					l_text.append_character (' ')
				end
				l_text.append (ic.text)
			end
			Result := {STRING_32} "%/8220/" + l_text + {STRING_32} "%/8221/ %/8212/ " + ref.label + {STRING_32} " (" + state.version + {STRING_32} ")%N"
			if attached state.bible.source (state.version) as al_source then
				Result.append (al_source.credit)
			end
		end

feature {NONE} -- Tabs

	tab_tapped (a_tab: INTEGER)
		do
			tab := a_tab - 1
			show_tab
			show_marks
		end

	show_tab
		do
			tab_body.clear
			inspect tab
			when 0 then
				show_original
			when 1 then
				show_cross_refs
			when 2 then
				show_compare
			else
				show_mine
			end
		end

	show_original
		local
			l_page, l_kjv_part: PHONE_COLUMN
			l_words: ARRAYED_LIST [SB_WORD]
			l_hebrew: BOOLEAN
			l_flow: PHONE_FLOW
			l_kjv: STRING_32
			l_label: PHONE_LABEL
		do
			l_words := state.bible.words (key)
			l_hebrew := ref.book <= 39
			l_kjv := kjv_text
			l_page := ui.column
			l_page.set_padding (12, 12)
			if not l_kjv.is_empty then
				l_kjv_part := ui.column
				l_kjv_part.set_padding_each (8, 0, 8, 0)
				l_kjv_part.extend (ui.label ({STRING_32} "KJV  %/183/  tap a word", theme.Label_medium, theme.secondary))
				l_kjv_part.extend (kjv_tappable (l_kjv))
				if not state.bible.shifted_in (key).is_empty then
					l_kjv_part.extend (ui.padded ({STRING_32} "%/8224/ Wright (1884) lists this word as changed in meaning since the KJV.", theme.Label_small, theme.primary, 0, 0, 0, 8))
				end
				l_page.extend (l_kjv_part)
				l_page.extend (spaced_divider)
			end
			if l_words.is_empty then
				l_label := ui.body ({STRING_32} "No Hebrew or Greek word data for this verse.")
				l_label.set_padding (8, 8)
				l_page.extend (l_label)
			else
				show_numbering (l_page, l_words, l_hebrew)
				create l_flow.make (controls)
				l_flow.set_flow_gap (6)
				l_flow.set_right_to_left (l_hebrew)
				across l_words as ic loop
					l_flow.extend (word_chip (ic, l_hebrew))
				end
				l_page.extend (l_flow)
				l_page.extend (ui.padded ({STRING_32} "Tap a word for its dictionary entries and every place it occurs.", theme.Body_small, theme.on_surface_variant, 8, 12, 0, 0))
				if attached state.bible.source (if l_hebrew then {STRING_32} "macula_hebrew" else {STRING_32} "macula_greek" end) as al_source then
					l_page.extend (ui.source_line (al_source.credit))
				end
			end
			tab_body.extend_growing (ui.scroller (l_page), 1)
		end

	spaced_divider: PHONE_COLUMN
		do
			Result := ui.column
			Result.set_padding (0, 8)
			Result.extend (ui.divider)
		end

	show_numbering (a_page: PHONE_COLUMN; a_words: ARRAYED_LIST [SB_WORD]; a_hebrew: BOOLEAN)
			-- Where the original numbers this verse differently, say so.
		local
			l_own: ARRAYED_LIST [STRING_32]
			l_text, l_one: STRING_32
		do
			create l_own.make (2)
			l_own.compare_objects
			across a_words as ic loop
				l_one := ic.chapter.out.to_string_32 + {STRING_32} ":" + ic.verse.out.to_string_32
				if not l_own.has (l_one) then
					l_own.extend (l_one)
				end
			end
			if l_own.count > 1 or else not l_own.first.same_string (ref.chapter.out.to_string_32 + {STRING_32} ":" + ref.verse.out.to_string_32) then
				l_text := if a_hebrew then {STRING_32} "Hebrew numbering: " else {STRING_32} "Greek numbering: " end
				across l_own as ic loop
					if @ic.cursor_index > 1 then
						l_text.append ({STRING_32} ", ")
					end
					l_text.append (ic)
				end
				a_page.extend (ui.padded (l_text, theme.Label_medium, theme.on_surface_variant, 8, 0, 0, 8))
			end
		end

	word_chip (a_word: SB_WORD; a_hebrew: BOOLEAN): PHONE_COLUMN
		local
			l_row: PHONE_RICH_ROW
		do
			create Result.make (controls)
			Result.call_integer ("setGravity", 1)
			Result.set_surface (theme.surface_container_high, 8)
			Result.set_padding (10, 6)
			create l_row.make (0, 0, 0)
			if a_hebrew then
				theme.add_style_in (l_row, theme.Headline_small, theme.Hebrew, theme.on_background)
				l_row.add_text (state.hebrew (a_word.surface))
			else
				theme.add_style (l_row, theme.Title_medium, theme.on_background)
				l_row.add_text (a_word.surface)
			end
			Result.extend (wrapped (ui.rich (l_row)))
			Result.extend (wrapped (ui.italic (a_word.translit, theme.Body_small, theme.on_surface_variant)))
			Result.extend (wrapped (ui.semi_bold (a_word.gloss, theme.Body_small, theme.primary)))
			Result.extend (wrapped (ui.label (a_word.morph, theme.Label_small, theme.on_surface_variant)))
			Result.set_on_tap (agent word_tapped (a_word.lemma))
		end

	wrapped (a_label: PHONE_LABEL): PHONE_LABEL
			-- `a_label' centered in the chip.
		do
			a_label.call_integer ("setGravity", 1)
			Result := a_label
		end

	word_tapped (a_lemma: INTEGER)
		do
			shell.open (create {SB_WORD_PAGE}.make (shell, a_lemma))
		end

	kjv_text: STRING_32
		do
			create Result.make (120)
			across state.bible.verses_at (key, {STRING_32} "KJV") as ic loop
				if not Result.is_empty then
					Result.append_character (' ')
				end
				Result.append (ic.text)
			end
		end

	kjv_tappable (a_text: STRING_32): PHONE_TAPPABLE_TEXT
			-- The KJV with every word tappable: linked words underlined, shifted ones daggered.
		local
			l_words: SB_KJV_WORDS
			l_linked: like {SB_APP_DB}.kjv_linked
			l_shifted: ARRAYED_LIST [STRING_32]
			l_row: PHONE_RICH_ROW
			l_seen: HASH_TABLE [INTEGER, STRING_8]
			l_last, i, l_nth, l_flags: INTEGER
			l_is_shifted: BOOLEAN
			l_utf: UTF_CONVERTER
			l_key: STRING_8
		do
			create l_words.make (key, a_text)
			l_linked := state.bible.kjv_linked (key)
			l_shifted := state.bible.shifted_in (key)
			l_shifted.compare_objects
			create Result.make (controls)
			create l_row.make (0, 0, 0)
			create picks.make (32)
			create l_seen.make (32)
			l_row.add_block (theme.Serif, state.base_size, state.base_size * 1.5, theme.on_background, False, 0)
			l_last := 1
			from i := 1 until i > l_words.starts.count loop
				if l_words.starts [i] > l_last then
					l_row.add_text (a_text.substring (l_last, l_words.starts [i] - 1))
					picks.extend (Void)
				end
				if attached l_words.first_fold (i) as al_fold then
					l_key := l_utf.utf_32_string_to_utf_8_string_8 (al_fold)
					l_nth := l_seen.item (l_key) + 1
					l_seen.force (l_nth, l_key)
					l_is_shifted := l_shifted.has (al_fold)
					l_flags := l_row.Tappable
					if state.bible.has_kjv_link (l_linked, al_fold, l_nth) then
						l_flags := l_flags + l_row.Underlined
					end
					l_row.add_run (l_words.word (i), l_flags, if l_is_shifted then theme.primary else theme.on_background end, 0.0)
					picks.extend (l_words.pick (i, l_nth, al_fold))
					if l_is_shifted then
						l_row.add_run ({STRING_32} "%/8224/", 0, theme.primary, 0.0)
						picks.extend (Void)
					end
				else
					l_row.add_text (l_words.word (i))
					picks.extend (Void)
				end
				l_last := l_words.stops [i] + 1
				i := i + 1
			end
			if l_last <= a_text.count then
				l_row.add_text (a_text.substring (l_last, a_text.count))
				picks.extend (Void)
			end
			Result.set_rich (l_row)
			Result.set_on_run (agent run_tapped)
			Result.set_padding_each (0, 2, 0, 4)
		end

	picks: ARRAYED_LIST [detachable SB_WORD_PICK]
			-- What each run of the KJV stands for.
		attribute
			create Result.make (0)
		end

	run_tapped (a_run: INTEGER)
		do
			if a_run >= 1 and a_run <= picks.count and then attached picks [a_run] as al_pick then
				shell.show_dialog (create {SB_WORD_PICK_DIALOG}.make (shell, al_pick))
			end
		end

	show_cross_refs
		local
			l_list: ARRAYED_LIST [SB_XREF]
			l_page, l_item: PHONE_COLUMN
			l_top: PHONE_ROW
		do
			l_list := state.bible.xrefs (key)
			if l_list.is_empty then
				tab_body.extend (ui.empty ({STRING_32} "No cross-references for this verse."))
			else
				l_page := ui.column
				across l_list as ic loop
					l_item := ui.tappable_column (agent go (ic.ref), 20, 10)
					l_top := ui.top_row
					l_top.extend_growing (ui.label (ic.ref.label, theme.Title_small, theme.primary), 1)
					l_top.extend (ui.label (ic.votes.out.to_string_32 + {STRING_32} " votes", theme.Label_small, theme.on_surface_variant))
					l_item.extend (l_top)
					l_item.extend (ui.limited (ui.label (state.bible.preview_text (ic.ref, state.version), theme.Body_medium, theme.on_background), 3))
					l_page.extend (l_item)
					l_page.extend (ui.divider)
				end
				if attached state.bible.source ({STRING_32} "cross_references") as al_source then
					l_page.extend (ui.source_line (al_source.credit))
				end
				tab_body.extend_growing (ui.scroller (l_page), 1)
			end
		end

	go (a_ref: SB_REF)
		do
			shell.dismiss_sheet
			shell.go_to (a_ref)
		end

	show_compare
		local
			l_page, l_item: PHONE_COLUMN
			l_verses: ARRAYED_LIST [SB_VERSE]
			i, j: INTEGER
			l_code, l_own, l_text: STRING_32
			l_version: SB_VERSION
			l_differs: BOOLEAN
			l_row: PHONE_RICH_ROW
			l_base: REAL_64
		do
			l_verses := state.bible.verses_at (key, Void)
			l_page := ui.column
			l_base := state.base_size * 0.9
			from i := 1 until i > l_verses.count loop
				l_code := l_verses [i].version
				l_version := state.bible.version (l_code)
				l_own := {STRING_32} ""
				l_text := {STRING_32} ""
				l_differs := False
				from j := i until j > l_verses.count or else not l_verses [j].version.same_string (l_code) loop
					l_differs := l_differs or l_verses [j].differs_from_english
					if j > i then
						l_own.append ({STRING_32} ", ")
						l_text.append_character (' ')
					end
					l_own.append (l_verses [j].own_label)
					l_text.append (if l_verses [j].text.is_empty then {STRING_32} "(omitted in this edition)" else l_verses [j].text end)
					j := j + 1
				end
				if l_version.rtl then
					l_text := state.hebrew (l_text)
				end
				if l_differs then
					l_text := {STRING_32} "[" + l_own + {STRING_32} "] " + l_text
				end
				l_item := ui.column
				l_item.set_padding (20, 8)
				l_item.extend (ui.label (l_code + {STRING_32} "  %/183/  " + l_version.name, theme.Label_medium, theme.secondary))
				create l_row.make (0, 0, 0)
				state.add_reading_block (l_row, theme, l_version, l_base, 0)
				l_row.add_text (l_text)
				l_item.extend (ui.rich (l_row))
				l_page.extend (l_item)
				l_page.extend (ui.divider)
				i := j
			end
			tab_body.extend_growing (ui.scroller (l_page), 1)
		end

	show_mine
		do
			shell.fill_mine_tab (tab_body, key)
		end

feature {NONE} -- Speech

	sheet_speech: SB_BATCH
			-- What the open tab shows, to be read aloud.
		do
			Result := (create {SB_SPOKEN}.make (state)).sheet_batch (key, tab, shell.packs)
		end

feature {NONE} -- Implementation

	ref: SB_REF
		do
			create Result.make_from_key (key)
		end

	gone
		do
			shell.sheet_gone (Current)
		end

	shell: SB_SHELL

	state: SB_STATE

	theme: SB_THEME

	ui: SB_UI

	controls: PHONE_CONTROLS

	holder, tab_body, reason_room: PHONE_COLUMN

	marks_row: PHONE_ROW

	tabs: SB_TABS

	star_icon, more_icon: PHONE_ICON

	tab: INTEGER
			-- The open tab, from 0.

	reason_field: detachable PHONE_FIELD

	saved_reason: READABLE_STRING_32
		attribute
			Result := {STRING_32} ""
		end

end
