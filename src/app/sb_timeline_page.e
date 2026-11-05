note
	description: "The Bible's world from prehistory to the apostles, a draft. TimelineScreen in HistoryScreens.kt."
	author: "Larry Rix"

class
	SB_TIMELINE_PAGE

inherit
	SB_OVERLAY

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL)
		local
			l_note: PHONE_LABEL
			l_scroll: PHONE_SIDEWAYS_SCROLL
		do
			make_overlay (a_shell, {STRING_32} "Timeline")
			create chips.make (controls)
			create list_room.make (controls)
			create speak_room.make (controls)
			create shared.make (a_shell)
			create lane.make_empty
			lanes := state.bible.lanes
			actions.extend (speak_room)
			actions.extend (ui.text_button ({STRING_32} "Map", agent open_map))
			chips.call_integer ("setGravity", 16)
			chips.set_least_height (48)
			chips.set_padding (12, 0)
			create l_scroll.make (controls)
			l_scroll.set_child (chips)
			content.extend (l_scroll)
			l_note := ui.padded ({STRING_32} "A draft by Larry Rix: every event below is marked draft or %/8220/to confirm%/8221/.", theme.Body_small, theme.error, 20, 4, 20, 4)
			content.extend (l_note)
			content.extend_growing (list_room, 1)
			show
		end

feature {NONE} -- Showing

	show
		local
			l_page: PHONE_COLUMN
			l_selected: detachable STRING_32
		do
			speak_room.clear
			speak_room.extend (shell.speak_button ("timeline:" + lane.out, {STRING_32} "Timeline", agent spoken))
			chips.clear
			chips.extend (chip ({STRING_32} "All", lane.is_empty, {STRING_32} ""))
			across lanes as ic loop
				chips.extend (chip (ic.title, ic.id.same_string (lane), ic.id))
			end
			list_room.clear
			l_page := ui.column
			if not lane.is_empty then
				l_selected := lane
			end
			across state.bible.events (l_selected) as ic loop
				add_event (l_page, ic)
			end
			if attached state.bible.source ({STRING_32} "timeline") as al_source then
				l_page.extend (ui.source_line (al_source.credit))
			end
			list_room.extend_growing (ui.scroller (l_page), 1)
		end

	chip (a_text: READABLE_STRING_32; a_on: BOOLEAN; a_lane: STRING_32): PHONE_ROW
		do
			Result := ui.top_row
			Result.set_padding_each (0, 0, 6, 0)
			Result.extend (ui.filter_chip (a_text, a_on, agent lane_tapped (a_lane)))
		end

	lane_tapped (a_lane: STRING_32)
		do
			create lane.make_from_string (a_lane)
			show
		end

	lane_title (a_id: READABLE_STRING_32): STRING_32
		do
			create Result.make_empty
			across lanes as ic until not Result.is_empty loop
				if ic.id.same_string (a_id) then
					Result := ic.title
				end
			end
		end

	add_event (a_page: PHONE_COLUMN; a_event: SB_TL_EVENT)
		local
			l_row: PHONE_ROW
			l_top: PHONE_FIT_ROW
			l_text: PHONE_COLUMN
			l_big: BOOLEAN
		do
			l_big := a_event.importance >= 2
			l_row := ui.top_row
			l_row.set_padding (20, 10)
			l_row.set_on_tap (agent open_event (a_event.id))
			l_row.extend_growing (ui.padded (a_event.label, theme.Label_medium, theme.primary, 0, 0, 8, 0), 38)
			l_text := ui.column
			create l_top.make (controls)
			if l_big then
				l_top.extend (padded_end (ui.semi_bold (a_event.title, theme.Title_small, theme.on_background)))
			else
				l_top.extend (padded_end (ui.label (a_event.title, theme.Body_medium, theme.on_background)))
			end
			if attached shared.status_chip (a_event.status) as al_chip then
				l_top.extend (al_chip)
			end
			l_text.extend (l_top)
			l_text.extend (ui.label (lane_title (a_event.lane), theme.Label_small, theme.on_surface_variant))
			l_row.extend_growing (l_text, 62)
			a_page.extend (l_row)
			a_page.extend (ui.divider)
		end

	padded_end (a_label: PHONE_LABEL): PHONE_LABEL
		do
			a_label.set_padding_each (0, 0, 6, 0)
			Result := a_label
		end

	open_event (a_id: STRING_32)
		do
			shell.open (create {SB_EVENT_PAGE}.make (shell, a_id))
		end

	open_map
		do
			shell.open (create {SB_ATLAS_PAGE}.make (shell, -1000, Void))
		end

	spoken: SB_BATCH
		local
			l_selected: detachable STRING_32
		do
			create Result.make ({STRING_32} "")
			Result.add ({STRING_32} "A draft timeline. Every event is marked draft or to confirm.", {STRING_32} "Draft")
			if not lane.is_empty then
				l_selected := lane
			end
			across state.bible.events (l_selected) as ic loop
				Result.add (ic.label + {STRING_32} ". " + ic.title + {STRING_32} ".", ic.label + {STRING_32} " %/183/ " + ic.title)
			end
		end

feature {NONE} -- Implementation

	chips: PHONE_ROW

	speak_room: PHONE_ROW

	list_room: PHONE_COLUMN

	lanes: ARRAYED_LIST [SB_LANE]

	lane: STRING_32
			-- The lane shown, or empty for all.

	shared: SB_PACK_VERSE

end
