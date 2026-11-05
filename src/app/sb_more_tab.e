note
	description: "The More tab, as MoreScreen.kt has it: packs, then the tools, then saving and loading the user's own data."
	author: "Larry Rix"

class
	SB_MORE_TAB

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL)
		do
			shell := a_shell
			state := a_shell.state
			theme := a_shell.theme
			ui := a_shell.ui
			controls := a_shell.controls
			create body.make (controls)
			create page.make (controls)
			body.extend_growing (ui.scroller (page), 1)
			refresh
		end

feature -- Access

	body: PHONE_COLUMN

feature -- Refreshing

	refresh
		local
			l_due, l_prayers: INTEGER
			l_row: PHONE_ROW
			l_box: PHONE_COLUMN
		do
			l_due := state.user.due_cards.count
			l_prayers := state.user.prayers (False).count
			page.clear
			across shell.packs as ic loop
				l_row := ui.row
				l_box := ui.column
				add_row (l_box, ic.title, {STRING_32} "Your materials %/183/ tap to browse and search", agent open_pack (ic))
				l_row.extend_growing (l_box, 1)
				l_row.extend (ui.padded_button ({STRING_32} "Remove", agent ask_remove (ic), 8))
				page.extend (l_row)
			end
			add_row (page, if is_loading then {STRING_32} "Loading pack%/8230/" else {STRING_32} "Load pack%/8230/" end,
				{STRING_32} "Open a pack file you downloaded (your own materials). It stays on this phone only.", agent load_pack)
			add_row (page, {STRING_32} "Timeline", {STRING_32} "The Bible's world from prehistory to the apostles (a draft)", agent open_timeline)
			add_row (page, {STRING_32} "Empires atlas", {STRING_32} "Who ruled where, year by year, 3400 BC %/8211/ AD 400", agent open_atlas)
			add_row (page, {STRING_32} "Memory cards", if l_due > 0 then l_due.out.to_string_32 + {STRING_32} " due for review" else {STRING_32} "Nothing due right now" end, agent open_memory)
			add_row (page, {STRING_32} "Prayer list", if l_prayers > 0 then l_prayers.out.to_string_32 + {STRING_32} " on the list" else {STRING_32} "Add what you are praying for" end, agent open_prayers)
			add_row (page, {STRING_32} "Settings", {STRING_32} "Text size, theme, Hebrew pointing, parallel versions", agent open_settings)
			add_row (page, {STRING_32} "Credits and licenses", {STRING_32} "Every text and dataset in this app, with its license", agent open_credits)
			add_row (page, {STRING_32} "About", {STRING_32} "What this app does and does not do", agent open_about)
			add_row (page, {STRING_32} "Export my notes and marks", {STRING_32} "Save favorites, highlights, notes, journal, tags, cards, prayers and history to a file", agent save_data)
			add_row (page, {STRING_32} "Import notes and marks", {STRING_32} "Merge a file saved from this app", agent load_data)
		end

feature {NONE} -- Rows

	add_row (a_page: PHONE_COLUMN; a_title, a_detail: READABLE_STRING_32; a_action: PROCEDURE [TUPLE])
		local
			l_box: PHONE_COLUMN
		do
			l_box := ui.tappable_column (a_action, 20, 14)
			l_box.extend (ui.label (a_title, theme.Title_medium, theme.on_background))
			l_box.extend (ui.label (a_detail, theme.Body_small, theme.on_surface_variant))
			a_page.extend (l_box)
			a_page.extend (ui.divider)
		end

	open_pack (a_pack: SB_PACK_DB)
		do
			shell.open (create {SB_PACK_HOME}.make (shell, a_pack))
		end

	open_timeline
		do
			shell.open (create {SB_TIMELINE_PAGE}.make (shell))
		end

	open_atlas
		do
			shell.open (create {SB_ATLAS_PAGE}.make (shell, -1000, Void))
		end

	open_memory
		do
			shell.open (create {SB_MEMORY_PAGE}.make (shell))
		end

	open_prayers
		do
			shell.open (create {SB_PRAYER_PAGE}.make (shell))
		end

	open_settings
		do
			shell.open (create {SB_SETTINGS_PAGE}.make (shell))
		end

	open_credits
		do
			shell.open (create {SB_CREDITS_PAGE}.make (shell))
		end

	open_about
		do
			shell.open (create {SB_ABOUT_PAGE}.make (shell))
		end

feature {NONE} -- Packs

	load_pack
		do
			if not is_loading then
				shell.services.open_file (<<"application/octet-stream", "application/x-sqlite3", "application/vnd.sqlite3", "*/*">>, shell.pack_store.incoming_path, agent pack_picked)
			end
		end

	pack_picked (a_outcome: READABLE_STRING_32; a_detail: READABLE_STRING_32)
		local
			l_loaded: detachable SB_PACK_DB
			l_old: ARRAYED_LIST [SB_PACK_DB]
		do
			if a_outcome.same_string ({STRING_32} "failed") then
				controls.toast (if a_detail.is_empty then {STRING_32} "That file could not be loaded." else a_detail end)
			elseif a_outcome.same_string ({STRING_32} "done") then
				is_loading := True
				refresh
				l_loaded := shell.pack_store.load_incoming
				is_loading := False
				if attached l_loaded as al_pack then
						-- A newer copy of the same pack replaces the old one.
					create l_old.make (1)
					across shell.packs as ic loop
						if ic.path.same_string (al_pack.path) then
							l_old.extend (ic)
						end
					end
					across l_old as ic loop
						ic.close
						shell.packs.prune_all (ic)
					end
					shell.packs.extend (al_pack)
					controls.toast ({STRING_32} "Loaded: " + al_pack.title)
				else
					controls.toast (if shell.pack_store.load_failure.is_empty then {STRING_32} "That file could not be loaded." else shell.pack_store.load_failure end)
				end
				refresh
			end
		end

	ask_remove (a_pack: SB_PACK_DB)
		local
			l_ask: SB_DIALOG
		do
			create l_ask.make (shell, {STRING_32} "Remove %/8220/" + a_pack.title + {STRING_32} "%/8221/ from this phone?")
			l_ask.content.extend (ui.label ({STRING_32} "Only the pack file on this phone is removed. You can load it again from the file any time.", theme.Body_medium, theme.on_surface_variant))
			l_ask.add_close ({STRING_32} "Keep")
			l_ask.add_button ({STRING_32} "Remove", agent remove (a_pack))
			shell.show_dialog (l_ask)
		end

	remove (a_pack: SB_PACK_DB)
		do
			shell.packs.prune_all (a_pack)
			shell.pack_store.remove (a_pack)
			shell.close_dialog
			refresh
		end

feature {NONE} -- Notes and marks

	save_data
			-- Save the user's data to a file of their choosing.
		local
			l_path: STRING_32
			l_file: RAW_FILE
			l_now: INTEGER_64
		do
			l_path := shell.phone.storage.internal_path.to_string_32 + {STRING_32} "/export.tmp"
			create l_file.make_with_name (l_path)
			l_file.create_read_write
			l_file.put_string (state.user.export_json_utf_8)
			l_file.close
			l_now := (create {SB_CLOCK}).now
			shell.services.save_file (l_path, {STRING_32} "sb-phone-notes-" + shell.dates.iso_today (l_now) + {STRING_32} ".json", "application/json", agent exported (l_path, ?, ?))
		end

	exported (a_path: READABLE_STRING_32; a_outcome: READABLE_STRING_32; a_detail: READABLE_STRING_32)
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_name (a_path)
			if l_file.exists then
				l_file.delete
			end
			if a_outcome.same_string ({STRING_32} "done") then
				controls.toast ({STRING_32} "Your notes and marks were saved to the file.")
			elseif a_outcome.same_string ({STRING_32} "failed") then
				controls.toast ({STRING_32} "Export failed: " + a_detail)
			end
		end

	load_data
		do
			shell.services.open_file (<<"application/json", "text/plain", "*/*">>, shell.phone.storage.internal_path.to_string_32 + {STRING_32} "/import.tmp", agent imported)
		end

	imported (a_outcome: READABLE_STRING_32; a_detail: READABLE_STRING_32)
		local
			l_file: RAW_FILE
			l_path: STRING_32
			l_summary: STRING_32
		do
			if a_outcome.same_string ({STRING_32} "failed") then
				controls.toast ({STRING_32} "Import failed: " + a_detail)
			elseif a_outcome.same_string ({STRING_32} "done") then
				l_path := shell.phone.storage.internal_path.to_string_32 + {STRING_32} "/import.tmp"
				create l_file.make_with_name (l_path)
				l_file.open_read
				l_file.read_stream (l_file.count)
				l_summary := state.user.import_json_utf_8 (l_file.last_string)
				l_file.close
				l_file.delete
				if state.user.has_import_failed then
					controls.toast ({STRING_32} "Import failed: " + l_summary)
				else
					shell.touched
					controls.toast (l_summary)
				end
			end
		end

feature {NONE} -- Implementation

	shell: SB_SHELL

	state: SB_STATE

	theme: SB_THEME

	ui: SB_UI

	controls: PHONE_CONTROLS

	page: PHONE_COLUMN

	is_loading: BOOLEAN

end
