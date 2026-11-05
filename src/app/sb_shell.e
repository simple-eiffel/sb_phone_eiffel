note
	description: "[
		The frame of the app, as SbApp.kt has it: four tabs and the bottom navigation, then
		screens opening over all of it, the verse sheet, and dialogs on top. Back closes them
		in order. In Focus reading the bars go. The player bar sits below everything.
	]"
	author: "Larry Rix"

class
	SB_SHELL

create
	make

feature {NONE} -- Initialization

	make (a_phone: SIMPLE_EIF_PHONE; a_state: SB_STATE; a_store: SB_PACKS; a_packs: detachable ARRAYED_LIST [SB_PACK_DB])
			-- The app's frame. `a_packs' are the packs already open, if any.
		do
			phone := a_phone
			controls := a_phone.controls
			state := a_state
			pack_store := a_store
			packs := if attached a_packs as al_packs then al_packs else a_store.open_all end
			create overlays.make (4)
			create dialogs.make (2)
			create nav_icons.make (4)
			create nav_labels.make (4)
			create theme.make (a_state.theme = a_state.Theme_dark or else (a_state.theme = a_state.Theme_system and a_phone.metrics.is_night))
			create ui.make (controls, theme, a_state)
			create services.make (controls)
			create dates.make
			services.ask ("dateForm", agent dates.read_form)
			create root.make (controls)
			create stack.make (controls)
			create main.make (controls)
			create tab_area.make (controls)
			create nav.make (controls)
			create player_room.make (controls)
			create focus_row.make (controls)
			create focus_exit.make (controls, (create {SB_ICONS}).Fullscreen_exit, theme.on_surface_variant)
			create focus_speak.make (controls, (create {SB_ICONS}).Speaker, theme.on_surface_variant)
			create speaker.make (a_phone, services)
			create reader_part.make (Current)
			create search_part.make (Current)
			create library_part.make (Current)
			create more_part.make (Current)
			tab_area.extend (reader.body)
			tab_area.extend (search.body)
			tab_area.extend (library.body)
			tab_area.extend (more.body)
			main.extend_growing (tab_area, 1)
			build_nav
			main.extend (nav)
			stack.extend (main)
			root.extend_growing (stack, 1)
			root.extend (player_room)
			build_focus_buttons
			controls.set_window_colors (theme.background, theme.surface_container, not theme.is_dark)
			services.set_on_failure (agent failed)
			speaker.set_rate (a_state.speech_rate)
			speaker.set_on_change (agent speaker_changed)
			show_tab
			controls.show (root)
			update_back
		end

feature -- Access

	state: SB_STATE

	theme: SB_THEME

	ui: SB_UI

	controls: PHONE_CONTROLS

	services: PHONE_SERVICES

	speaker: SB_SPEAKER

	packs: ARRAYED_LIST [SB_PACK_DB]
			-- The packs loaded.

	pack_store: SB_PACKS

	dates: SB_DATES

	phone: SIMPLE_EIF_PHONE

feature -- Moving about

	refresh
			-- Show what the state now says.
		do
			reader.refresh
			search.refresh
			show_tab
			update_back
		end

	touched
			-- The user's own data has changed.
		do
			state.touched
			reader.refresh
			refresh_tab
			if attached sheet as al_sheet then
				al_sheet.refresh
			end
			if not overlays.is_empty then
				overlays.last.refresh
			end
		end

	go_to (a_ref: SB_REF)
			-- Jump to `a_ref', closing every screen over the tabs.
		do
			drop_sheet
			close_overlays
			state.go_to (a_ref)
			refresh
			if state.flash_key /= 0 then
				services.after (1600, agent flash_over)
			end
		end

	open_picker
		do
			open (create {SB_PICKER}.make (Current))
		end

	open_english (a_word: READABLE_STRING_32)
		do
			open (create {SB_ENGLISH_PAGE}.make (Current, a_word))
		end

	open (a_overlay: SB_OVERLAY)
			-- Put `a_overlay' over everything. The verse sheet steps aside and comes back after.
		do
			hide_sheet
			overlays.extend (a_overlay)
			stack.extend (a_overlay.root)
			show_tab
			show_focus
			update_back
		end

	back
			-- The Back key: a dialog, the sheet, the top screen, then Focus, then the Read tab.
		do
			if not dialogs.is_empty then
				close_dialog
			elseif attached sheet as al_sheet then
				al_sheet.dismiss
			elseif not overlays.is_empty then
				if not overlays.last.handle_back then
					close_top
				end
			elseif state.is_focus then
				leave_focus
			elseif state.tab /= state.Tab_read then
				state.set_tab (state.Tab_read)
				show_tab
			end
			update_back
		end

	enter_focus
		do
			state.set_focus (True)
			show_focus
			update_back
		end

	leave_focus
		do
			state.set_focus (False)
			show_focus
			update_back
		end

	apply_theme
			-- The theme has changed: every screen is made afresh, as Compose would redraw it.
		do
			if attached on_new_theme as al_action then
				al_action.call ([Current])
			end
		end

	set_on_new_theme (a_action: PROCEDURE [TUPLE [SB_SHELL]])
		do
			on_new_theme := a_action
		end

	give_up_screen
			-- A new shell has taken over.
		do
			speaker.stop
			root.discard
		end

feature -- The verse sheet

	show_sheet (a_key: INTEGER)
		do
			state.set_sheet_key (a_key)
			put_sheet
			update_back
		end

	drop_sheet
			-- Take the sheet away at once, for good.
		do
			hide_sheet
			state.set_sheet_key (0)
			update_back
		end

	dismiss_sheet
		do
			drop_sheet
		end

	sheet_gone (a_sheet: SB_VERSE_SHEET)
			-- `a_sheet' has slid away.
		do
			if sheet = a_sheet then
				drop_sheet
			end
		end

feature -- Dialogs

	show_dialog (a_dialog: SB_DIALOG)
		do
			dialogs.extend (a_dialog)
			stack.extend (a_dialog.root)
			update_back
		end

	close_dialog
		local
			l_top: SB_DIALOG
		do
			if not dialogs.is_empty then
				l_top := dialogs.last
				services.hide_keyboard
				dialogs.finish
				dialogs.remove
				stack.remove (l_top.root)
				l_top.root.discard
			end
			update_back
		end

feature -- Shared rows

	lemma_row (a_lemma: SB_LEMMA; a_end: READABLE_STRING_32): PHONE_ROW
			-- An original word in a list, opening its page: BehindRow and the Search tab's row.
		local
			l_text: PHONE_COLUMN
		do
			Result := ui.row
			Result.set_padding (20, 8)
			Result.extend (ui.lemma_head (a_lemma))
			l_text := ui.column
			l_text.set_padding_each (12, 0, 0, 0)
			l_text.extend (ui.italic (a_lemma.translit, theme.Body_large, theme.on_background))
			if not a_lemma.hint.is_empty then
				l_text.extend (ui.limited (ui.label (a_lemma.hint, theme.Body_small, theme.on_surface_variant), 1))
			end
			Result.extend_growing (l_text, 1)
			Result.extend (ui.label (a_end, theme.Label_medium, theme.on_surface_variant))
			Result.set_on_tap (agent open_word (a_lemma.id))
		end

	open_word (a_lemma: INTEGER)
		do
			open (create {SB_WORD_PAGE}.make (Current, a_lemma))
		end

	fill_mine_tab (a_body: PHONE_COLUMN; a_key: INTEGER)
			-- The Mine tab of the verse sheet.
		do
			(create {SB_PACK_VERSE}.make (Current)).fill (a_body, a_key)
		end

feature -- Reading aloud

	speak_button (a_source: READABLE_STRING_8; a_title: READABLE_STRING_32; a_build: FUNCTION [SB_BATCH]): PHONE_ICON
			-- The read-aloud button every screen carries: it reads what that screen shows, and
			-- tapped again while that screen is being read, it stops.
		local
			l_mine: BOOLEAN
			l_icons: SB_ICONS
		do
			create l_icons
			l_mine := speaker.is_active and then speaker.source.same_string (a_source)
			create Result.make (controls, if l_mine then l_icons.Stop else l_icons.Speaker end, if l_mine then theme.primary else theme.on_surface_variant end)
			Result.set_padding (12, 12)
			Result.set_on_tap (agent speak_tapped (a_source, a_title, a_build, Result))
		end

	read_chapter (a_page, a_from_key: INTEGER)
			-- Read the chapter on `a_page' from verse `a_from_key' (0 for its start).
		do
			last_speak_icon := Void
			speaker.read ("reader", (create {SB_SPOKEN}.make (state)).chapter_batch (a_page, a_from_key))
		end

feature {NONE} -- Building

	build_nav
		local
			l_icons: SB_ICONS
		do
			create l_icons
			nav.set_surface (theme.surface_container, 0)
			nav.set_height (80)
			nav.set_spacing (8, 0)
			nav_item (state.Tab_read, {STRING_32} "Read", l_icons.Book)
			nav_item (state.Tab_search, {STRING_32} "Search", l_icons.Search)
			nav_item (state.Tab_library, {STRING_32} "Library", l_icons.Bookmark)
			nav_item (state.Tab_more, {STRING_32} "More", l_icons.More)
		end

	nav_item (a_tab: INTEGER; a_label: READABLE_STRING_32; a_path: READABLE_STRING_8)
		local
			l_item: PHONE_COLUMN
			l_pill: PHONE_ROW
			l_icon: PHONE_ICON
			l_label: PHONE_LABEL
		do
			create l_item.make (controls)
				-- Material centers these in the bar's top 76, so big text moves the icon up instead of being cut off.
			l_item.call_integer ("setGravity", Center)
			l_item.set_height (80)
			l_item.set_padding_each (0, 0, 0, 4)
			create l_pill.make (controls)
			l_pill.call_integer ("setGravity", Center)
			create l_icon.make (controls, a_path, theme.on_surface_variant)
			l_icon.set_padding (16, 4)
			l_pill.extend (l_icon)
			l_item.extend (l_pill)
			create l_label.make (controls, a_label)
			l_label.call_integer ("setGravity", Center)
			l_label.set_padding_each (0, 4, 0, 0)
			l_item.extend (l_label)
			l_item.set_on_tap (agent tab_tapped (a_tab))
			nav.extend_growing (l_item, 1)
			nav_icons.extend (l_icon)
			nav_labels.extend (l_label)
		end

	build_focus_buttons
			-- In Focus reading: only a faint way back out, and read aloud.
		local
			l_room: PHONE_LABEL
		do
			focus_speak.set_padding (12, 12)
			focus_speak.set_surface (theme.with_alpha (theme.surface_container_high, 204), 24)
			focus_speak.set_on_tap (agent focus_speak_tapped)
			focus_exit.set_padding (12, 12)
			focus_exit.set_surface (theme.with_alpha (theme.surface_container_high, 204), 24)
			focus_exit.set_on_tap (agent leave_focus)
			focus_row.call_integer ("setGravity", Bottom)
			focus_row.set_padding (16, 16)
			focus_row.extend (focus_speak)
			create l_room.make (controls, {STRING_32} "")
			focus_row.extend_growing (l_room, 1)
			focus_row.extend (focus_exit)
			focus_row.set_visible (False)
			stack.extend (focus_row)
		end

feature {NONE} -- Showing

	show_tab
		local
			i: INTEGER
			l_on: BOOLEAN
		do
			reader.body.set_visible (state.tab = state.Tab_read)
			search.body.set_visible (state.tab = state.Tab_search)
			library.body.set_visible (state.tab = state.Tab_library)
			more.body.set_visible (state.tab = state.Tab_more)
			from i := 1 until i > 4 loop
				l_on := state.tab = i and overlays.is_empty
				nav_icons [i].set_tint (if l_on then theme.on_secondary_container else theme.on_surface_variant end)
				if l_on then
					nav_icons [i].set_surface (theme.secondary_container, 16)
				else
					nav_icons [i].set_surface (0, 16)
				end
				nav_labels [i].set_rich (theme.styled (nav_labels [i].text, theme.Label_medium, if l_on then theme.secondary else theme.on_surface_variant end))
				i := i + 1
			end
		end

	show_focus
		local
			l_on: BOOLEAN
		do
			l_on := state.is_focus and state.tab = state.Tab_read and overlays.is_empty
			controls.set_bars_hidden (l_on)
			nav.set_visible (not l_on)
			reader.show_focus (l_on)
			focus_row.set_visible (l_on)
		end

	put_sheet
			-- Show the sheet the state asks for, if nothing is over it.
		local
			l_sheet: SB_VERSE_SHEET
		do
			if state.sheet_key /= 0 and overlays.is_empty and sheet = Void then
				create l_sheet.make (Current, state.sheet_key)
				sheet := l_sheet
				stack.extend (l_sheet.root)
			end
		end

	hide_sheet
		do
			if attached sheet as al_sheet then
				services.hide_keyboard
				sheet := Void
				stack.remove (al_sheet.root)
				al_sheet.root.discard
			end
		end

	tab_tapped (a_tab: INTEGER)
		do
			close_overlays
			state.set_tab (a_tab)
			show_tab
			show_focus
			refresh_tab
			update_back
		end

	refresh_tab
			-- Library and More read the user's data when they are in view, and only then.
		do
			if overlays.is_empty then
				if state.tab = state.Tab_library then
					library.refresh
				elseif state.tab = state.Tab_more then
					more.refresh
				end
			end
		end

	close_top
		local
			l_top: SB_OVERLAY
		do
			l_top := overlays.last
			l_top.closing
			services.hide_keyboard
			overlays.finish
			overlays.remove
			stack.remove (l_top.root)
			l_top.root.discard
			show_tab
			show_focus
			if overlays.is_empty then
				put_sheet
				refresh_tab
			else
				overlays.last.refresh
			end
		end

	close_overlays
		do
			from until overlays.is_empty loop
				close_top
			end
		end

	failed (a_words: READABLE_STRING_32)
			-- A call to the phone did not go through.
		do
			phone.log.info ("sb: failed: " + (create {UTF_CONVERTER}).utf_32_string_to_utf_8_string_8 (a_words))
		end

	flash_over
		do
			state.clear_flash
			reader.refresh
		end

	update_back
			-- Back belongs to the app only while it has something to go back from.
		do
			if not dialogs.is_empty or sheet /= Void or not overlays.is_empty or state.tab /= state.Tab_read or state.is_focus then
				controls.set_on_back (agent back)
			else
				controls.clear_on_back
			end
		end

feature {NONE} -- Reading aloud

	speak_tapped (a_source: READABLE_STRING_8; a_title: READABLE_STRING_32; a_build: FUNCTION [SB_BATCH]; a_icon: PHONE_ICON)
		local
			l_icons: SB_ICONS
			l_batch: SB_BATCH
		do
			create l_icons
			if speaker.is_active and then speaker.source.same_string (a_source) then
				speaker.stop
			else
				l_batch := a_build.item ([])
				l_batch.set_title (a_title)
				speaker.read (a_source, l_batch)
				a_icon.set_path (l_icons.Stop)
				a_icon.set_tint (theme.primary)
				last_speak_icon := a_icon
			end
		end

	focus_speak_tapped
		do
			if speaker.is_active and then speaker.source.same_string ("reader") then
				speaker.stop
			else
				read_chapter (state.page, 0)
			end
		end

	speaker_changed
			-- What the phone is reading has moved on.
		local
			l_icons: SB_ICONS
		do
			create l_icons
			if not speaker.is_active and then attached last_speak_icon as al_icon then
				al_icon.set_path (l_icons.Speaker)
				al_icon.set_tint (theme.on_surface_variant)
				last_speak_icon := Void
			end
			focus_speak.set_path (if speaker.is_active and then speaker.source.same_string ("reader") then l_icons.Stop else l_icons.Speaker end)
			services.keep_screen_on (speaker.is_active)
			reader.speaker_changed
			show_player
		end

	show_player
			-- PlayerBar in ReadAloud.kt, below everything while something is being read.
		do
			if not speaker.is_active then
				player_room.clear
				player := Void
			elseif attached player as al_player then
				al_player.update
			else
				player_room.clear
				player := create {SB_PLAYER_BAR}.make (Current)
				if attached player as al_new then
					player_room.extend (al_new.root)
				end
			end
		end

feature {NONE} -- Implementation

	root, main, player_room: PHONE_COLUMN

	stack, tab_area: PHONE_STACK

	reader_part: detachable SB_READER
			-- Detachable only because the tabs need a finished Current to be made.

	search_part: detachable SB_SEARCH_TAB

	library_part: detachable SB_LIBRARY_TAB

	more_part: detachable SB_MORE_TAB

	reader: SB_READER
		do
			check attached reader_part as al_part then
				Result := al_part
			end
		end

	search: SB_SEARCH_TAB
		do
			check attached search_part as al_part then
				Result := al_part
			end
		end

	library: SB_LIBRARY_TAB
		do
			check attached library_part as al_part then
				Result := al_part
			end
		end

	more: SB_MORE_TAB
		do
			check attached more_part as al_part then
				Result := al_part
			end
		end

	nav: PHONE_ROW

	nav_icons: ARRAYED_LIST [PHONE_ICON]

	nav_labels: ARRAYED_LIST [PHONE_LABEL]

	overlays: ARRAYED_LIST [SB_OVERLAY]

	dialogs: ARRAYED_LIST [SB_DIALOG]

	sheet: detachable SB_VERSE_SHEET

	focus_exit, focus_speak: PHONE_ICON

	focus_row: PHONE_ROW

	on_new_theme: detachable PROCEDURE [TUPLE [SB_SHELL]]

	last_speak_icon: detachable PHONE_ICON

	player: detachable SB_PLAYER_BAR
			-- The bar while something is being read.
			-- The button that started what is being read.

	Center: INTEGER = 17


	Bottom: INTEGER = 80

end
