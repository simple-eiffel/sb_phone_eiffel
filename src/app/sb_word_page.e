note
	description: "A Hebrew or Greek word: its head, the KJV's renderings, the dictionaries side by side, and every place. WordScreen.kt."
	author: "Larry Rix"

class
	SB_WORD_PAGE

inherit
	SB_OVERLAY

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL; a_lemma: INTEGER)
		do
			make_overlay (a_shell, {STRING_32} "Word")
			lemma_id := a_lemma
			shown := 50
			create open_sources.make (8)
			open_sources.compare_objects
			create closed_sources.make (8)
			closed_sources.compare_objects
			create page.make (controls)
			content.extend_growing (ui.scroller (page), 1)
			if attached state.bible.lemma (a_lemma) as al_lemma then
				set_title (al_lemma.headword)
				actions.extend (shell.speak_button ("word:" + a_lemma.out, al_lemma.headword, agent spoken))
				places := state.bible.occurrences (a_lemma)
				senses := state.bible.senses (a_lemma)
				renderings := state.bible.renderings (a_lemma)
				show (al_lemma)
			end
		end

feature {NONE} -- Showing

	show (a_lemma: SB_LEMMA)
		local
			l_order: ARRAY [STRING_32]
			l_groups: ARRAYED_LIST [TUPLE [source: STRING_32; list: ARRAYED_LIST [SB_SENSE]]]
		do
			page.clear
			add_heading (a_lemma)
			add_renderings
			l_order := if a_lemma.is_hebrew then (create {SB_SPOKEN}.make (state)).hebrew_order else (create {SB_SPOKEN}.make (state)).greek_order end
			l_groups := (create {SB_SPOKEN}.make (state)).senses_by_source (senses, l_order)
			if not l_groups.is_empty then
				section ({STRING_32} "The dictionaries, each in its own words")
				page.extend (ui.padded ({STRING_32} "Shown side by side as candidates, not ranked.", theme.Body_small, theme.on_surface_variant, 20, 0, 20, 0))
			end
			across l_groups as ic loop
				add_source (ic.source, ic.list, ic.source.same_string (l_groups.first.source))
			end
			section ({STRING_32} "Every place (" + places.count.out.to_string_32 + {STRING_32} ")")
			create places_box.make (controls)
			page.extend (places_box)
			add_places (1, shown.min (places.count))
			more_room := ui.column
			page.extend (more_room)
			show_more_button
			if attached state.bible.source (if a_lemma.is_hebrew then {STRING_32} "macula_hebrew" else {STRING_32} "macula_greek" end) as al_source then
				page.extend (ui.source_line (al_source.credit))
			end
		end

	add_heading (a_lemma: SB_LEMMA)
		local
			l_box: PHONE_COLUMN
			l_row: PHONE_RICH_ROW
			l_second, l_third: STRING_32
		do
			l_box := ui.column
			l_box.set_padding (20, 20)
			create l_row.make (0, 0, 0)
			theme.add_style_in (l_row, theme.Display_small, if a_lemma.is_hebrew then theme.Hebrew else theme.Plain end, theme.on_background)
			l_row.add_text (state.hebrew (a_lemma.headword))
			l_box.extend (ui.rich (l_row))
			l_second := a_lemma.translit.twin
			if not a_lemma.pron.is_empty then
				l_second.append ({STRING_32} "  (" + a_lemma.pron + {STRING_32} ")")
			end
			l_box.extend (ui.italic (l_second, theme.Title_medium, theme.on_surface_variant))
			l_third := a_lemma.language_name.twin
			if not a_lemma.pos.is_empty then
				l_third.append ({STRING_32} " %/183/ " + a_lemma.pos)
			end
			if not a_lemma.number.is_empty then
				l_third.append ({STRING_32} " %/183/ Strong's " + a_lemma.number)
			end
			l_box.extend (ui.padded (l_third, theme.Body_medium, theme.on_background, 0, 4, 0, 0))
			l_box.extend (top_space (ui.semi_bold ({STRING_32} "Occurs " + a_lemma.count.out.to_string_32 + {STRING_32} " times in the "
				+ if a_lemma.is_hebrew then {STRING_32} "Hebrew Bible (WLC)" else {STRING_32} "Greek New Testament" end, theme.Body_medium, theme.on_background)))
			page.extend (l_box)
		end

	top_space (a_label: PHONE_LABEL): PHONE_LABEL
		do
			a_label.set_padding_each (0, 4, 0, 0)
			Result := a_label
		end

	section (a_title: READABLE_STRING_32)
		do
			page.extend (ui.padded (a_title, theme.Title_medium, theme.primary, 20, 16, 20, 6))
		end

	add_renderings
		local
			l_flow: PHONE_FLOW
			l_chip: PHONE_LABEL
			i: INTEGER
		do
			if not renderings.is_empty then
				section ({STRING_32} "How the KJV renders it")
				create l_flow.make (controls)
				l_flow.set_flow_gap (6)
				l_flow.set_padding (16, 0)
				from i := 1 until i > renderings.count or i > 24 loop
					l_chip := ui.label (renderings [i].english + {STRING_32} " " + renderings [i].n.out.to_string_32, theme.Label_large, theme.on_background)
					l_chip.set_surface (theme.surface_container_high, 12)
					l_chip.set_padding (10, 4)
					l_chip.set_on_tap (agent english_tapped (renderings [i].english))
					l_flow.extend (l_chip)
					i := i + 1
				end
				page.extend (l_flow)
				page.extend (ui.padded ({STRING_32} "Tap an English word for every Hebrew or Greek word behind it, and what it meant then and now.", theme.Body_small, theme.on_surface_variant, 20, 6, 20, 0))
				if attached state.bible.source ({STRING_32} "KJV-links") as al_source then
					page.extend (ui.source_line (al_source.credit))
				end
			end
		end

	english_tapped (a_word: STRING_32)
		do
			shell.open (create {SB_ENGLISH_PAGE}.make (shell, a_word))
		end

	add_source (a_source: STRING_32; a_senses: ARRAYED_LIST [SB_SENSE]; a_first: BOOLEAN)
		local
			l_open: BOOLEAN
			l_head: PHONE_COLUMN
			l_top: PHONE_ROW
			l_info: detachable SB_SOURCE_INFO
			l_gloss: STRING_32
		do
			l_open := (a_first and not closed_sources.has (a_source)) or open_sources.has (a_source)
			l_info := state.bible.source (a_source)
			l_head := ui.tappable_column (agent source_tapped (a_source, l_open), 20, 10)
			l_top := ui.top_row
			l_top.extend_growing (ui.label (if attached l_info as al_info then al_info.name else a_source end, theme.Title_small, theme.secondary), 1)
			l_top.extend (ui.label (if l_open then {STRING_32} "%/9652/" else {STRING_32} "%/9662/  " + a_senses.count.out.to_string_32 end, theme.Title_small, theme.on_background))
			l_head.extend (l_top)
			if not l_open then
				l_gloss := {STRING_32} ""
				across a_senses as ic until not l_gloss.is_empty loop
					if not ic.gloss.is_empty then
						l_gloss := ic.gloss
					end
				end
				l_head.extend (ui.limited (ui.label (l_gloss, theme.Body_medium, theme.on_background), 1))
			end
			page.extend (l_head)
			if l_open then
				across a_senses as ic loop
					add_sense (ic)
				end
				if attached l_info as al_info then
					page.extend (ui.source_line (al_info.credit + {STRING_32} " (" + al_info.license + {STRING_32} ")"))
				end
			end
			page.extend (ui.divider)
		end

	source_tapped (a_source: STRING_32; a_was_open: BOOLEAN)
		do
			open_sources.prune_all (a_source)
			closed_sources.prune_all (a_source)
			if a_was_open then
				closed_sources.extend (a_source)
			else
				open_sources.extend (a_source)
			end
			if attached state.bible.lemma (lemma_id) as al_lemma then
				show (al_lemma)
			end
		end

	add_sense (a_sense: SB_SENSE)
		local
			l_box: PHONE_COLUMN
			l_head: STRING_32
			l_spoken: SB_SPOKEN
			l_row: PHONE_RICH_ROW
			l_note: STRING_32
		do
			create l_spoken.make (state)
			l_box := ui.column
			l_box.set_padding_each (20 + 14 * a_sense.depth.max (0).min (4), 4, 20, 4)
			l_head := l_spoken.sense_head (a_sense)
			if not l_head.is_empty then
				l_box.extend (ui.semi_bold (l_head, theme.Body_medium, theme.on_background))
			end
			if not a_sense.text.is_empty and not l_spoken.sense_repeats (a_sense) then
				create l_row.make (0, 0, 0)
				theme.add_style (l_row, theme.Body_medium, theme.on_background)
				l_row.add_text (a_sense.text)
				l_box.extend (ui.rich (l_row))
			end
			if not a_sense.domain.is_empty then
				l_box.extend (ui.label (a_sense.domain, theme.Label_small, theme.secondary))
			end
			if not a_sense.note_text.is_empty then
				l_note := a_sense.note_text.twin
				l_note.replace_substring_all ({STRING_32} "|", {STRING_32} "%N")
				l_box.extend (ui.label (l_note, theme.Body_small, theme.on_surface_variant))
			end
			page.extend (l_box)
		end

	add_places (a_from, a_to: INTEGER)
		local
			i: INTEGER
			l_ref: SB_REF
			l_item: PHONE_COLUMN
			l_top: PHONE_ROW
		do
			from i := a_from until i > a_to loop
				create l_ref.make_from_key (places [i].eng_key)
				l_item := ui.tappable_column (agent shell.go_to (l_ref), 20, 8)
				l_top := ui.top_row
				l_top.extend_growing (ui.label (l_ref.short_label, theme.Title_small, theme.primary), 1)
				l_top.extend (ui.italic (places [i].gloss, theme.Label_medium, theme.on_background))
				l_item.extend (l_top)
				l_item.extend (ui.limited (ui.label (state.bible.preview_text (l_ref, state.version), theme.Body_medium, theme.on_background), 2))
				places_box.extend (l_item)
				i := i + 1
			end
		end

	show_more_button
		local
			l_room: PHONE_ROW
		do
			more_room.clear
			if places.count > shown then
				l_room := ui.top_row
				l_room.set_padding (16, 16)
				l_room.extend (ui.text_button ({STRING_32} "Show more (" + (places.count - shown).out.to_string_32 + {STRING_32} " left)", agent show_more))
				more_room.extend (l_room)
			end
		end

	show_more
		local
			l_from: INTEGER
		do
			l_from := shown + 1
			shown := shown + 100
			add_places (l_from, shown.min (places.count))
			show_more_button
		end

	spoken: SB_BATCH
		do
			check attached state.bible.lemma (lemma_id) as al_lemma then
				Result := (create {SB_SPOKEN}.make (state)).word_batch (al_lemma, renderings, senses, places)
			end
		end

feature {NONE} -- Implementation

	lemma_id: INTEGER

	shown: INTEGER

	page: PHONE_COLUMN

	places_box: PHONE_COLUMN
		attribute
			create Result.make (controls)
		end

	more_room: PHONE_COLUMN
		attribute
			create Result.make (controls)
		end

	open_sources, closed_sources: ARRAYED_LIST [STRING_32]

	places: like {SB_APP_DB}.occurrences
		attribute
			create Result.make (0)
		end

	senses: ARRAYED_LIST [SB_SENSE]
		attribute
			create Result.make (0)
		end

	renderings: ARRAYED_LIST [SB_RENDERING]
		attribute
			create Result.make (0)
		end

end
