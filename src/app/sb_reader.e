note
	description: "[
		The Read tab, as ReaderScreen.kt has it: the bar, then every chapter on a pager
		of three lists, reused as the pages turn. Rows are built on the Eiffel side and
		kept per list, so a list only ever asks for text it already has.
	]"
	author: "Larry Rix"

class
	SB_READER

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL)
		local
			l_list: PHONE_LIST
			l_icons: SB_ICONS
			i: INTEGER
		do
			create l_icons
			shell := a_shell
			state := a_shell.state
			theme := a_shell.theme
			controls := a_shell.controls
			create body.make (controls)
			create slots.make_filled (create {ARRAYED_LIST [STRING_32]}.make (0), 1, 3)
			create keys.make_filled (create {ARRAYED_LIST [INTEGER]}.make (0), 1, 3)
			create chapter_rows.make_filled (Void, 1, 3)
			create shown_page.make_filled (0, 1, 3)
			create lists.make (3)
			create pager.make (controls)
			create bar.make (controls)
			create rule.make (controls, {STRING_32} "")
			create chapter_button.make (controls, {STRING_32} "")
			create version_button.make (controls, {STRING_32} "")
			create back_icon.make (controls, l_icons.Before, theme.on_surface_variant)
			create forward_icon.make (controls, l_icons.Next, theme.on_surface_variant)
			create parallel_icon.make (controls, l_icons.Columns, theme.on_surface_variant)
			create speaker_icon.make (controls, l_icons.Speaker, theme.on_surface_variant)
			create focus_icon.make (controls, l_icons.Fullscreen, theme.on_surface_variant)
			pager.set_on_page_wanted (agent fill)
			pager.set_on_page_chosen (agent chosen)
			from i := 1 until i > 3 loop
				slots [i] := create {ARRAYED_LIST [STRING_32]}.make (64)
				keys [i] := create {ARRAYED_LIST [INTEGER]}.make (64)
				create l_list.make (controls)
				l_list.set_row_text (agent row_of (i, ?))
				l_list.set_on_select (agent tapped (i, ?))
				l_list.set_on_press (agent pressed (i, ?, ?, ?))
				l_list.call_boolean ("setVerticalScrollBarEnabled", False)
				l_list.call_integer ("setOverScrollMode", 2)
				l_list.call_integer ("setBackgroundColor", theme.background.as_integer_32)
				lists.extend (l_list)
				pager.extend (l_list)
				i := i + 1
			end
			build_bar
			body.extend (bar)
			rule.set_surface (theme.outline_variant, 0)
			rule.set_height (1)
			body.extend (rule)
			body.extend_growing (pager, 1)
			pager.set_page_count (state.bible.chapters.count)
			pager.go_to (state.page)
		end

feature -- Access

	body: PHONE_COLUMN

feature -- Refreshing

	refresh
			-- Show what the state now says: the bar, and every near page read afresh.
		do
			show_bar
			if pager.page /= state.page then
				pager.go_to (state.page)
			end
			pager.set_page_count (state.bible.chapters.count)
		end

	show_focus (a_on: BOOLEAN)
			-- Focus reading drops the bar.
		do
			bar.set_visible (not a_on)
			rule.set_visible (not a_on)
		end

	speaker_changed
			-- Follow the verse being read aloud: mark it, and turn to its chapter.
		local
			l_icons: SB_ICONS
			l_reading, l_turned: BOOLEAN
			l_key: INTEGER
		do
			create l_icons
			l_reading := shell.speaker.is_active and then shell.speaker.source.same_string ("reader")
			speaker_icon.set_path (if l_reading then l_icons.Stop else l_icons.Speaker end)
			speaker_icon.set_tint (if l_reading then theme.primary else theme.on_surface_variant end)
			if attached shell.speaker.now as al_now and then al_now.is_verse then
				l_key := al_now.key
				if state.bible.page_of (al_now.book, al_now.chapter) /= state.page then
					state.turn_to (state.bible.page_of (al_now.book, al_now.chapter))
					l_turned := True
				end
			end
			if l_turned or l_key /= state.read_key then
				state.set_read_key (l_key)
				refresh
				if l_key /= 0 then
					keep_in_view (l_key)
				end
			end
		end

	keep_in_view (a_key: INTEGER)
			-- Bring the row of `a_key' into view, if it is out of it.
		local
			i, l_slot: INTEGER
		do
			from l_slot := 1 until l_slot > 3 or else shown_page [l_slot] = state.page loop
				l_slot := l_slot + 1
			end
			if l_slot <= 3 then
				from i := 1 until i > keys [l_slot].count loop
					if keys [l_slot] [i] = a_key then
						lists [l_slot].show_row (i)
					end
					i := i + 1
				end
			end
		end

feature {NONE} -- The bar

	build_bar
		local
			l_room: PHONE_LABEL
		do
			bar.set_padding (4, 0)
			bar.set_height (48)
			bar.call_integer ("setGravity", Center_vertical)
			add_bar_icon (back_icon, 36, agent go_back)
			add_bar_icon (forward_icon, 36, agent go_forward)
			chapter_button.set_padding (12, 10)
			chapter_button.set_on_tap (agent shell.open_picker)
				-- Compose gives this slot half the spare width and cuts the text at a word.
			chapter_button.call_integer ("setMaxLines", 1)
			bar.extend_growing (chapter_button, 1)
			create l_room.make (controls, {STRING_32} "")
			bar.extend_growing (l_room, 1)
			version_button.set_padding (12, 10)
			version_button.set_on_tap (agent choose_version)
			bar.extend (version_button)
			add_bar_icon (parallel_icon, 40, agent toggle_parallel)
			add_bar_icon (speaker_icon, 40, agent read_aloud)
			add_bar_icon (focus_icon, 40, agent shell.enter_focus)
			show_bar
		end

	add_bar_icon (a_icon: PHONE_ICON; a_room: INTEGER; a_action: PROCEDURE [TUPLE])
		do
			a_icon.set_padding ((a_room - 24) // 2, (a_room - 24) // 2)
			a_icon.set_on_tap (a_action)
			bar.extend (a_icon)
		end

	show_bar
		do
			back_icon.set_tint (if state.can_go_back then theme.on_background else theme.with_alpha (theme.on_background, 97) end)
			forward_icon.set_tint (if state.can_go_forward then theme.on_background else theme.with_alpha (theme.on_background, 97) end)
			chapter_button.set_rich (theme.styled (state.bible.book (state.book_id).short + {STRING_32} " " + state.chapter_number.out.to_string_32 + {STRING_32} " %/9662/", theme.Title_medium, theme.primary))
			version_button.set_rich (theme.styled (state.version + {STRING_32} " %/9662/", theme.Title_small, theme.primary))
			parallel_icon.set_tint (if state.is_parallel_on then theme.primary else theme.on_surface_variant end)
		end

	go_back
		do
			if state.can_go_back then
				state.go_back
				shell.refresh
			end
		end

	go_forward
		do
			if state.can_go_forward then
				state.go_forward
				shell.refresh
			end
		end

	toggle_parallel
		do
			state.toggle_parallel
			refresh
		end

	read_aloud
		do
			if shell.speaker.is_active and then shell.speaker.source.same_string ("reader") then
				shell.speaker.stop
			else
				shell.read_chapter (state.page, 0)
			end
		end

	choose_version
		local
			l_rows: ARRAYED_LIST [PHONE_RICH_ROW]
			l_row: PHONE_RICH_ROW
		do
			create l_rows.make (12)
			across state.bible.versions as ic loop
				create l_row.make (0, 12, 0)
				theme.add_style (l_row, theme.Label_large, theme.on_background)
				l_row.add_run (ic.code, l_row.Semi_bold, 0, 0.0)
				theme.add_style (l_row, theme.Body_small, theme.on_background)
				l_row.add_text (ic.name + {STRING_32} " %/183/ " + ic.coverage)
				l_rows.extend (l_row)
			end
			controls.show_dropdown (version_button, l_rows.to_array, theme.surface_container_high, agent version_chosen)
		end

	version_chosen (a_index: INTEGER)
		do
			if a_index > 0 then
				state.choose_version (state.bible.versions [a_index].code)
				refresh
			end
		end

feature {NONE} -- The pages

	chosen (a_page: INTEGER)
			-- A swipe has settled on `a_page'.
		do
			if a_page /= state.page then
				state.turn_to (a_page)
				show_bar
			end
		end

	fill (a_slot, a_page: INTEGER)
			-- Build list `a_slot' for chapter `a_page'.
		local
			l_chapter: SB_CHAPTER_ROWS
		do
			create l_chapter.make (state, theme, state.bible.chapters [a_page].book, state.bible.chapters [a_page].chapter)
			chapter_rows [a_slot] := l_chapter
			slots [a_slot].wipe_out
			slots [a_slot].append (l_chapter.rows)
			keys [a_slot].wipe_out
			keys [a_slot].append (l_chapter.keys)
			lists [a_slot].set_row_count (slots [a_slot].count)
			if shown_page [a_slot] /= a_page then
				shown_page [a_slot] := a_page
				lists [a_slot].call_integer ("setSelection", 0)
			end
			if a_page = state.page and state.focus_key /= 0 then
				scroll_to_focus (a_slot)
			end
		end

	scroll_to_focus (a_slot: INTEGER)
			-- Bring the first verse at or after the jump's key into view.
		local
			i: INTEGER
			l_found: BOOLEAN
		do
			from i := 1 until l_found or i > keys [a_slot].count loop
				if keys [a_slot] [i] >= state.focus_key then
					l_found := True
					lists [a_slot].call_integer ("setSelection", i - 1)
				end
				i := i + 1
			end
			state.clear_focus_key
		end

	tapped (a_slot, a_row: INTEGER)
			-- A verse's row was tapped.
		do
			if keys [a_slot] [a_row] /= 0 then
				state.user.record_visit (keys [a_slot] [a_row], state.version)
				shell.show_sheet (keys [a_slot] [a_row])
			end
		end

	pressed (a_slot, a_row, a_block, a_offset: INTEGER)
			-- In the KJV, a long press on a word opens the Hebrew or Greek behind it.
		do
			if attached chapter_rows [a_slot] as al_rows and then a_row >= 1 and then a_row <= al_rows.kjv_blocks.count
				and then al_rows.kjv_blocks [a_row] = a_block and then a_block /= 0
				and then attached (create {SB_KJV_WORDS}.make (al_rows.keys [a_row], al_rows.kjv_texts [a_row])).pick_at (a_offset - al_rows.prefixes [a_row]) as al_pick
			then
				shell.show_dialog (create {SB_WORD_PICK_DIALOG}.make (shell, al_pick))
			end
		end

	row_of (a_slot, a_row: INTEGER): READABLE_STRING_32
		do
			Result := slots [a_slot] [a_row]
		end

feature {NONE} -- Implementation

	shell: SB_SHELL

	state: SB_STATE

	theme: SB_THEME

	controls: PHONE_CONTROLS

	bar: PHONE_ROW

	rule: PHONE_LABEL

	pager: PHONE_PAGER

	lists: ARRAYED_LIST [PHONE_LIST]

	slots: ARRAY [ARRAYED_LIST [STRING_32]]
			-- The rows of each list.

	chapter_rows: ARRAY [detachable SB_CHAPTER_ROWS]

	keys: ARRAY [ARRAYED_LIST [INTEGER]]
			-- The verse key of each row; 0 for a title or a credit.

	shown_page: ARRAY [INTEGER]
			-- The chapter each list last showed, to know when to go back to its top.

	chapter_button, version_button: PHONE_LABEL

	back_icon, forward_icon, parallel_icon, speaker_icon, focus_icon: PHONE_ICON

	Center_vertical: INTEGER = 16

end
