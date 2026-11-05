note
	description: "An English word of the KJV: the Hebrew and Greek behind it, what it meant then, what it means today. EnglishScreen.kt."
	author: "Larry Rix"

class
	SB_ENGLISH_PAGE

inherit
	SB_OVERLAY

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL; a_word: READABLE_STRING_32)
		local
			l_fold: STRING_32
			l_entry: SB_ENGLISH_ENTRY
		do
			make_overlay (a_shell, a_word)
			create page.make (controls)
			content.extend_growing (ui.scroller (page), 1)
			l_fold := (create {SB_FOLD}.make).fold (a_word)
			l_entry := state.bible.english_entry (l_fold)
			entry := l_entry
			set_title (l_entry.lemma)
			actions.extend (shell.speak_button ("english:" + (create {UTF_CONVERTER}).utf_32_string_to_utf_8_string_8 (l_fold), l_entry.lemma, agent spoken))
			show
		end

feature {NONE} -- Showing

	show
		local
			l_head, l_forms: STRING_32
			l_hebrew, l_greek: ARRAYED_LIST [SB_BEHIND]
			l_spoken: SB_SPOKEN
			l_then, l_today: ARRAYED_LIST [SB_ENGLISH_SENSE]
			l_box: PHONE_COLUMN
			l_ref: SB_REF
			l_label: PHONE_LABEL
		do
			create l_spoken.make (state)
			l_head := entry.lemma
			page.extend (ui.padded (l_head, theme.Display_small, theme.on_background, 20, 16, 20, 0))
			if entry.forms.count > 1 then
				l_forms := {STRING_32} "In the KJV as: " + l_spoken.joined (entry.forms, {STRING_32} ", ")
			else
				l_forms := {STRING_32} "An English word in the King James Version"
			end
			page.extend (ui.padded (l_forms, theme.Body_medium, theme.on_surface_variant, 20, 0, 20, 0))
			heading ({STRING_32} "The Hebrew and Greek behind it")
			if entry.behind.is_empty then
				note_line ({STRING_32} "The KJV word links have no Hebrew or Greek word for %"" + l_head + {STRING_32} "%".")
			end
			create l_hebrew.make (8)
			create l_greek.make (8)
			across entry.behind as ic loop
				if ic.lemma.is_hebrew then
					l_hebrew.extend (ic)
				else
					l_greek.extend (ic)
				end
			end
			behind_group ({STRING_32} "Old Testament", l_hebrew)
			behind_group ({STRING_32} "New Testament", l_greek)
			if not entry.behind.is_empty and then attached state.bible.source ({STRING_32} "KJV-links") as al_source then
				page.extend (ui.source_line (al_source.credit))
			end

			heading ({STRING_32} "What it meant then")
			l_then := l_spoken.then_senses (entry)
			if not entry.shifts.is_empty then
				note_line ({STRING_32} "Wright's Bible Word-Book (1884) lists %"" + l_head + {STRING_32} "%" among the words whose meaning has changed since the King James Version. The places he cites:")
				l_box := ui.column
				l_box.set_padding (20, 0)
				across entry.shifts as ic loop
					create l_ref.make_from_key (ic)
					l_label := ui.label (l_ref.label + {STRING_32} "  %/8594/", theme.Body_large, theme.primary)
					l_label.set_padding (0, 6)
					l_label.set_on_tap (agent shell.go_to (l_ref))
					l_box.extend (l_label)
				end
				page.extend (l_box)
			end
			if l_then.is_empty and entry.shifts.is_empty then
				note_line ({STRING_32} "None of the period dictionaries in this app has an entry for %"" + l_head + {STRING_32} "%" yet.")
			end
			across l_spoken.grouped_by_source (l_then) as ic loop
				sense_group (ic.source, ic.list)
			end

			l_today := l_spoken.today_senses (entry)
			if not l_today.is_empty then
				heading ({STRING_32} "What it means today")
				across l_spoken.grouped_by_pos (l_today) as ic loop
					l_box := ui.column
					l_box.set_padding (20, 4)
					l_box.extend (ui.label (l_spoken.part_of_speech (ic.source), theme.Label_large, theme.secondary))
					across ic.list as jc loop
						l_box.extend (ui.padded (@jc.cursor_index.out.to_string_32 + {STRING_32} ". " + jc.text, theme.Body_medium, theme.on_background, 0, 2, 0, 0))
					end
					page.extend (l_box)
				end
				if attached state.bible.source ({STRING_32} "OEWN2025") as al_source then
					page.extend (ui.source_line (al_source.credit))
				end
			end
		end

	heading (a_text: READABLE_STRING_32)
		do
			page.extend (ui.padded (a_text, theme.Title_medium, theme.primary, 20, 20, 20, 4))
		end

	note_line (a_text: READABLE_STRING_32)
		do
			page.extend (ui.padded (a_text, theme.Body_medium, theme.on_background, 20, 4, 20, 4))
		end

	behind_group (a_label: READABLE_STRING_32; a_group: ARRAYED_LIST [SB_BEHIND])
		local
			l_sum: INTEGER
		do
			if not a_group.is_empty then
				across a_group as ic loop
					l_sum := l_sum + ic.n
				end
				page.extend (ui.padded (a_label + {STRING_32} " (" + l_sum.out.to_string_32 + {STRING_32} " places)", theme.Label_large, theme.secondary, 20, 8, 0, 0))
				across a_group as ic loop
					page.extend (shell.lemma_row (ic.lemma, ic.lemma.number + {STRING_32} "  %/183/  " + ic.n.out.to_string_32 + {STRING_32} "%/215/"))
				end
			end
		end

	sense_group (a_source: STRING_32; a_list: ARRAYED_LIST [SB_ENGLISH_SENSE])
		local
			l_box: PHONE_COLUMN
			l_text: STRING_32
		do
			l_box := ui.column
			l_box.set_padding (20, 8)
			l_box.extend (ui.label (if attached state.bible.source (a_source) as al_info then al_info.name else a_source end, theme.Title_small, theme.secondary))
			across a_list as ic loop
				l_text := {STRING_32} ""
				if not ic.sense_no.is_empty then
					l_text := ic.sense_no + {STRING_32} ". "
				end
				l_box.extend (ui.padded (l_text + ic.text, theme.Body_medium, theme.on_background, 0, 4, 0, 0))
			end
			if not a_list.is_empty and then not a_list.first.cite.is_empty then
				l_box.extend (ui.padded (a_list.first.cite, theme.Label_small, theme.on_surface_variant, 0, 4, 0, 0))
			end
			page.extend (l_box)
			page.extend (ui.divider)
		end

	spoken: SB_BATCH
		do
			Result := (create {SB_SPOKEN}.make (state)).english_batch (entry)
		end

feature {NONE} -- Implementation

	entry: SB_ENGLISH_ENTRY

	page: PHONE_COLUMN

end
