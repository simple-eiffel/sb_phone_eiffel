note
	description: "One event of the timeline, with its dating claims. TimelineEventScreen in HistoryScreens.kt."
	author: "Larry Rix"

class
	SB_EVENT_PAGE

inherit
	SB_OVERLAY

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL; a_id: STRING_32)
		local
			l_shared: SB_PACK_VERSE
			l_page, l_box: PHONE_COLUMN
			l_top: PHONE_ROW
			l_places: ARRAYED_LIST [SB_PLACE]
			l_names: ARRAYED_LIST [READABLE_STRING_32]
			l_spoken: SB_SPOKEN
			l_links: SB_REF_LINKS
			l_room: PHONE_ROW
			l_text: SB_KOTLIN_TEXT
			l_who, l_line: STRING_32
			l_parts: ARRAYED_LIST [READABLE_STRING_32]
		do
			make_overlay (a_shell, {STRING_32} "")
			id := a_id
			create l_shared.make (a_shell)
			create l_spoken.make (state)
			create l_text.make
			across state.bible.events (Void) as ic until event /= Void loop
				if ic.id.same_string (a_id) then
					event := ic
				end
			end
			claims := state.bible.claims (a_id)
			l_places := state.bible.places (a_id)
			if attached event as al_event then
				set_title (al_event.title)
				actions.extend (shell.speak_button ("event:" + a_id.out, al_event.title, agent spoken))
				l_page := ui.column
				l_page.set_padding (20, 0)
				l_top := ui.row
				l_top.set_padding_each (0, 8, 0, 0)
				l_top.extend (ui.padded (al_event.label, theme.Title_medium, theme.primary, 0, 0, 8, 0))
				if attached l_shared.status_chip (al_event.status) as al_chip then
					l_top.extend (al_chip)
				end
				l_page.extend (l_top)
				l_page.extend (ui.label ({STRING_32} "Draft: not yet confirmed.", theme.Body_small, theme.error))
				create l_links.make (a_shell, al_event.summary)
				l_links.text.set_padding (0, 12)
				l_page.extend (l_links.text)
				if not l_places.is_empty then
					create l_names.make (l_places.count)
					across l_places as ic loop
						l_names.extend (ic.name)
					end
					l_room := ui.top_row
					l_room.extend (ui.text_button ({STRING_32} "Show " + l_spoken.joined (l_names, {STRING_32} ", ") + {STRING_32} " on the map  %/8594/", agent open_map ((al_event.earliest + al_event.latest) // 2, l_places.first.id)))
					l_page.extend (l_room)
				end
				l_page.extend (ui.padded ({STRING_32} "The dating", theme.Title_small, theme.secondary, 0, 8, 0, 0))
				across claims as ic loop
					l_box := ui.column
					l_box.set_padding (0, 8)
					l_box.extend (ui.label (if ic.lean then ic.label + {STRING_32} "  (preferred)" else ic.label end, theme.Title_small, theme.on_background))
					create l_parts.make (2)
					if not l_text.is_blank (ic.chronology) then
						l_parts.extend (ic.chronology)
					end
					if not l_text.is_blank (ic.held_by) then
						l_parts.extend (ic.held_by)
					end
					l_who := l_spoken.joined (l_parts, {STRING_32} " %/183/ ")
					create l_parts.make (2)
					if not ic.basis.is_empty then
						l_parts.extend ({STRING_32} "Basis: " + ic.basis)
					end
					if not l_text.is_blank (l_who) then
						l_parts.extend (l_who)
					end
					l_line := l_spoken.joined (l_parts, {STRING_32} "  %/183/  ")
					l_box.extend (ui.label (l_line, theme.Label_medium, theme.on_surface_variant))
					if not l_text.is_blank (ic.note_text) then
						l_box.extend (ui.label (ic.note_text, theme.Body_medium, theme.on_background))
					end
					if not l_text.is_blank (ic.citation) then
						l_box.extend (ui.label (ic.citation, theme.Body_small, theme.on_surface_variant))
					end
					l_page.extend (l_box)
					l_page.extend (ui.divider)
				end
				if attached state.bible.source ({STRING_32} "timeline") as al_source then
					l_page.extend (ui.source_line (al_source.credit))
				end
				content.extend_growing (ui.scroller (l_page), 1)
			else
				content.extend (ui.empty ({STRING_32} "Not found."))
			end
		end

feature {NONE} -- Implementation

	open_map (a_year: INTEGER; a_place: STRING_32)
		do
			shell.open (create {SB_ATLAS_PAGE}.make (shell, a_year, a_place))
		end

	spoken: SB_BATCH
		local
			l_parts: ARRAYED_LIST [READABLE_STRING_32]
			l_text: SB_KOTLIN_TEXT
			l_spoken: SB_SPOKEN
		do
			create l_text.make
			create l_spoken.make (state)
			create Result.make ({STRING_32} "")
			if attached event as al_event then
				Result.add (al_event.title + {STRING_32} ". " + al_event.label + {STRING_32} ". Draft, not yet confirmed. " + al_event.summary, al_event.title)
				Result.add ({STRING_32} "The dating.", {STRING_32} "The dating")
				across claims as ic loop
					create l_parts.make (6)
					l_parts.extend (if ic.lean then ic.label + {STRING_32} ", preferred" else ic.label end)
					if not l_text.is_blank (ic.basis) then
						l_parts.extend ({STRING_32} "Basis: " + ic.basis)
					end
					if not l_text.is_blank (ic.chronology) then
						l_parts.extend (ic.chronology)
					end
					if not l_text.is_blank (ic.held_by) then
						l_parts.extend (ic.held_by)
					end
					if not l_text.is_blank (ic.note_text) then
						l_parts.extend (ic.note_text)
					end
					if not l_text.is_blank (ic.citation) then
						l_parts.extend (ic.citation)
					end
					Result.add (l_spoken.joined (l_parts, {STRING_32} ". "), ic.label)
				end
			end
		end

	id: STRING_32

	event: detachable SB_TL_EVENT

	claims: ARRAYED_LIST [SB_TL_CLAIM]

end
