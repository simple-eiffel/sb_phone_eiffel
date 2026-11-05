note
	description: "Who ruled where, year by year. AtlasScreen in HistoryScreens.kt."
	author: "Larry Rix"

class
	SB_ATLAS_PAGE

inherit
	SB_OVERLAY

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL; a_year: INTEGER; a_place: detachable READABLE_STRING_32)
		local
			l_stack: PHONE_STACK
			l_row: PHONE_ROW
			l_land: ARRAYED_LIST [TUPLE [kind: READABLE_STRING_32; ring: ARRAY [REAL_32]]]
			l_places: ARRAYED_LIST [TUPLE [id, name: READABLE_STRING_32; least_zoom: INTEGER; lon, lat: REAL_32]]
			l_credit: STRING_32
		do
			make_overlay (a_shell, {STRING_32} "")
			year := a_year.max (Least_year).min (Most_year)
			create atlas.make (controls, if theme.is_dark then 0xFF2E323C else 0xFFE9E4D6 end, if theme.is_dark then 0xFF101C2B else 0xFFC9DCEB end, theme.on_background, theme.primary)
			slider := ui.range (Most_year - Least_year)
			create picked_room.make (controls)
			create count_label.make (controls, {STRING_32} "")
			create speak_room.make (controls)
			create l_land.make (state.bible.land.count)
			across state.bible.land as ic loop
				l_land.extend ([ic.kind, ic.ring])
			end
			create l_places.make (64)
			across state.bible.places (Void) as ic loop
				l_places.extend ([ic.id, ic.name, ic.min_zoom, ic.lon, ic.lat])
			end
			if attached a_place as al_place then
				atlas.set_focus_place (al_place)
			end
			atlas.set_places (l_places)
			atlas.set_land (l_land)
			atlas.set_on_pick (agent picked)
			actions.extend (speak_room)
			create l_stack.make (controls)
			l_stack.extend (atlas)
			picked_room.call_integer ("setGravity", Bottom_start)
			picked_room.set_padding (12, 12)
			picked_room.set_visible (False)
			l_stack.extend (picked_room)
			content.extend_growing (l_stack, 1)
			l_row := ui.row
			l_row.set_padding (12, 0)
			l_row.extend (ui.text_button ({STRING_32} "%/8722/50", agent step (-50)))
			slider.set_value (year - Least_year)
			slider.set_on_change (agent slid)
			l_row.extend_growing (slider, 1)
			l_row.extend (ui.text_button ({STRING_32} "+50", agent step (50)))
			content.extend (l_row)
			count_label.set_padding (20, 0)
			content.extend (count_label)
			if attached state.bible.source ({STRING_32} "cliopatria") as al_source then
				l_credit := al_source.credit + {STRING_32} " "
				if attached state.bible.source ({STRING_32} "naturalearth") as al_land then
					l_credit.append (al_land.credit)
				end
				content.extend (ui.source_line (l_credit))
			end
			show_year
		end

feature {NONE} -- Showing

	show_year
		local
			l_rings: ARRAYED_LIST [TUPLE [name: READABLE_STRING_32; ring: ARRAY [REAL_32]]]
			l_label: STRING_32
		do
			areas := state.bible.areas (year)
			create l_rings.make (areas.count)
			across areas as ic loop
				l_rings.extend ([ic.name, ic.ring])
			end
			atlas.set_outlines (l_rings)
			l_label := year_label (year)
			set_title ({STRING_32} "Empires %/183/ " + l_label)
			speak_room.clear
			speak_room.extend (shell.speak_button ("atlas:" + year.out, {STRING_32} "Empires %/183/ " + l_label, agent spoken))
			count_label.set_rich (theme.styled ({STRING_32} "Tap the map to name what was there. " + areas.count.out.to_string_32 + {STRING_32} " outlines in " + l_label + {STRING_32} ".", theme.Body_small, theme.on_surface_variant))
		end

	step (a_by: INTEGER)
		do
			year := (year + a_by).max (Least_year).min (Most_year)
			slider.set_value (year - Least_year)
			show_year
		end

	slid (a_value: INTEGER)
		do
			year := Least_year + a_value
			show_year
		end

	picked (a_outlines: ARRAYED_LIST [INTEGER])
		local
			l_seen: ARRAYED_LIST [STRING_32]
			l_card: PHONE_COLUMN
			l_area: SB_AREA
		do
			picked_room.clear
			create l_seen.make (4)
			l_seen.compare_objects
			if a_outlines.is_empty then
				picked_room.set_visible (False)
			else
				create l_card.make (controls)
				l_card.set_surface (theme.surface_container_high, 10)
				l_card.set_padding (12, 12)
				l_card.set_on_tap (agent hide_picked)
				across a_outlines as ic loop
					if ic <= areas.count then
						l_area := areas [ic]
						if not l_seen.has (l_area.name) then
							l_seen.extend (l_area.name)
							l_card.extend (ui.label (l_area.name + {STRING_32} "  %/183/  " + year_label (l_area.year_from) + {STRING_32} " %/8211/ " + year_label (l_area.year_to), theme.Body_medium, theme.on_background))
						end
					end
				end
				picked_room.extend (l_card)
				picked_room.set_visible (True)
			end
		end

	hide_picked
		do
			picked_room.clear
			picked_room.set_visible (False)
		end

	spoken: SB_BATCH
		local
			l_seen: ARRAYED_LIST [STRING_32]
			l_spoken: ARRAYED_LIST [SB_AREA]
		do
			create l_seen.make (16)
			l_seen.compare_objects
			create l_spoken.make (16)
			across state.bible.areas (year) as ic loop
				if not l_seen.has (ic.name) then
					l_seen.extend (ic.name)
					l_spoken.extend (ic)
				end
			end
			create Result.make ({STRING_32} "")
			Result.add ({STRING_32} "In " + year_label (year) + {STRING_32} ", " + l_spoken.count.out.to_string_32 + {STRING_32} " outlines.", year_label (year))
			across l_spoken as ic loop
				Result.add (ic.name + {STRING_32} ", " + year_label (ic.year_from) + {STRING_32} " to " + year_label (ic.year_to) + {STRING_32} ".", ic.name)
			end
		end

	year_label (a_year: INTEGER): STRING_32
		do
			Result := (create {SB_SPOKEN}.make (state)).year_label (a_year)
		end

feature {NONE} -- Implementation

	atlas: PHONE_ATLAS

	slider: PHONE_RANGE

	picked_room: PHONE_COLUMN

	speak_room: PHONE_ROW

	count_label: PHONE_LABEL

	year: INTEGER

	areas: ARRAYED_LIST [SB_AREA]
		attribute
			create Result.make (0)
		end

	Least_year: INTEGER = -3399

	Most_year: INTEGER = 400

	Bottom_start: INTEGER = 8388691

end
