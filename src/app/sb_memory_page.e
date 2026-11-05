note
	description: "Memory cards: a review of those due, and all of them. MemoryScreen in PersonalScreens.kt."
	author: "Larry Rix"

class
	SB_MEMORY_PAGE

inherit
	SB_OVERLAY
		redefine
			refresh
		end

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL)
		do
			make_overlay (a_shell, {STRING_32} "Memory cards")
			create tab_body.make (controls)
			create queue.make (8)
			create tabs.make (ui, <<{STRING_32} "Review", {STRING_32} "All cards">>)
			tabs.set_on_tab (agent tab_tapped)
			queue.append (state.user.due_cards)
			tab := 1
			content.extend (tabs.root)
			content.extend_growing (tab_body, 1)
			refresh
		end

feature -- Refreshing

	refresh
		do
			actions.clear
			if tab = 2 then
				actions.extend (shell.speak_button ("cards", {STRING_32} "Memory cards", agent all_spoken))
			end
			tab_body.clear
			if tab = 1 then
				show_review
			else
				show_all
			end
		end

feature {NONE} -- Review

	tab_tapped (a_tab: INTEGER)
		do
			tab := a_tab
			refresh
		end

	show_review
		local
			l_card: SB_CARD
			l_ref: SB_REF
			l_box: PHONE_COLUMN
			l_row: PHONE_RICH_ROW
			l_text: PHONE_LABEL
			l_buttons: PHONE_ROW
			l_gap: PHONE_LABEL
			l_version: SB_VERSION
		do
			if queue.is_empty then
				show_finished
			else
				l_card := queue.first
				create l_ref.make_from_key (l_card.key)
				if l_card.key_end > l_card.key then
					create l_ref.make (l_ref.book, l_ref.chapter, l_ref.verse, l_card.key_end \\ 1000)
				end
				l_box := ui.column
				l_box.set_padding (24, 24)
				l_box.call_integer ("setGravity", 1)
				l_box.extend (centered (ui.label (queue.count.out.to_string_32 + {STRING_32} " due", theme.Label_large, theme.on_surface_variant)))
				l_box.extend (centered (ui.padded (l_ref.label, theme.Headline_medium, theme.primary, 0, 24, 0, 24)))
				if not is_shown then
					l_box.extend (centered (ui.label ({STRING_32} "Say the verse from memory, then check yourself.", theme.Body_medium, theme.on_background)))
					l_buttons := ui.top_row
					l_buttons.call_integer ("setGravity", 1)
					l_buttons.set_padding_each (0, 24, 0, 0)
					l_buttons.extend (ui.filled_button ({STRING_32} "Show the verse", agent show_verse))
					l_box.extend (l_buttons)
				else
					l_version := state.bible.version (state.version)
					create l_row.make (0, 0, 0)
					state.add_reading_block (l_row, theme, l_version, state.base_size, 0)
					l_row.add_text (state.bible.preview_text (l_ref, state.version))
					l_text := ui.rich (l_row)
					l_text.call_integer ("setGravity", 1)
					l_box.extend (l_text)
					l_box.extend (centered (ui.padded (state.version, theme.Label_medium, theme.secondary, 0, 8, 0, 0)))
					l_buttons := ui.top_row
					l_buttons.call_integer ("setGravity", 1)
					l_buttons.extend (ui.text_button ({STRING_32} "Hear it", agent hear (l_card, l_ref)))
					l_box.extend (l_buttons)
					l_buttons := ui.top_row
					l_buttons.call_integer ("setGravity", 1)
					l_buttons.set_padding_each (0, 32, 0, 0)
					l_buttons.extend (ui.outlined_button ({STRING_32} "Again", agent again (l_card)))
					create l_gap.make (controls, {STRING_32} "")
					l_gap.set_least_width (16)
					l_buttons.extend (l_gap)
					l_buttons.extend (ui.filled_button ({STRING_32} "Got it", agent got_it (l_card)))
					l_box.extend (l_buttons)
					l_box.extend (centered (ui.padded ({STRING_32} "Got it waits 1, 2, 4, 8%/8230/ days before showing it again. Again keeps it in this review.", theme.Body_small, theme.on_surface_variant, 0, 16, 0, 0)))
				end
				tab_body.extend_growing (ui.scroller (l_box), 1)
			end
		end

	centered (a_label: PHONE_LABEL): PHONE_LABEL
		do
			a_label.call_integer ("setGravity", 1)
			Result := a_label
		end

	show_finished
		local
			l_text: STRING_32
		do
			l_text := {STRING_32} ""
			if done > 0 then
				l_text := {STRING_32} "Done: " + done.out.to_string_32 + {STRING_32} " reviewed.%N%N"
			end
			if attached state.user.next_due as al_next then
				l_text.append ({STRING_32} "Nothing is due. The next card is due " + shell.dates.medium (al_next.item) + {STRING_32} ".")
			else
				l_text.append ({STRING_32} "No memory cards yet. Open a verse, tap %/8942/, then %/8220/Add to memory cards%/8221/.")
			end
			tab_body.extend (ui.empty (l_text))
		end

	show_verse
		do
			is_shown := True
			refresh
		end

	again (a_card: SB_CARD)
		do
			state.user.card_again (a_card)
			queue.start
			queue.remove
			queue.extend (a_card.with_interval (0))
			is_shown := False
			refresh
		end

	got_it (a_card: SB_CARD)
		do
			state.user.card_got_it (a_card)
			queue.start
			queue.remove
			done := done + 1
			is_shown := False
			refresh
		end

	hear (a_card: SB_CARD; a_ref: SB_REF)
		local
			l_spoken: SB_SPOKEN
			l_batch: SB_BATCH
		do
			create l_spoken.make (state)
			create l_batch.make (a_ref.label)
			l_batch.add_item (create {SB_SPEECH}.make_in (l_spoken.spoken_of (a_ref) + {STRING_32} ". " + state.bible.preview_text (a_ref, state.version), l_spoken.lang_of (state.bible.version (state.version)), a_ref.label))
			shell.speaker.read ("card:" + a_card.id.out, l_batch)
		end

feature {NONE} -- All cards

	show_all
		local
			l_cards: ARRAYED_LIST [SB_CARD]
			l_page, l_text: PHONE_COLUMN
			l_row: PHONE_ROW
			l_ref: SB_REF
			l_icons: SB_ICONS
		do
			create l_icons
			l_cards := state.user.cards
			if l_cards.is_empty then
				tab_body.extend (ui.empty ({STRING_32} "No memory cards yet. Open a verse, tap %/8942/, then %/8220/Add to memory cards%/8221/."))
			else
				l_page := ui.column
				across l_cards as ic loop
					create l_ref.make_from_key (ic.key)
					l_row := ui.row
					l_row.set_padding_each (20, 8, 0, 8)
					l_text := ui.column
					l_text.set_on_tap (agent shell.go_to (l_ref))
					l_text.extend (ui.label (l_ref.label, theme.Title_small, theme.primary))
					l_text.extend (ui.limited (ui.label (state.bible.preview_text (l_ref, state.version), theme.Body_small, theme.on_background), 2))
					l_text.extend (ui.label ({STRING_32} "Next: " + shell.dates.medium (ic.due) + {STRING_32} "  %/183/  reviewed " + ic.reps.out.to_string_32 + {STRING_32} "%/215/", theme.Label_small, theme.on_surface_variant))
					l_row.extend_growing (l_text, 1)
					l_row.extend (ui.icon_button (l_icons.Close, theme.on_background, agent remove (ic.id)))
					l_page.extend (l_row)
					l_page.extend (ui.divider)
				end
				tab_body.extend_growing (ui.scroller (l_page), 1)
			end
		end

	remove (a_id: INTEGER_64)
		do
			state.user.remove_card (a_id)
			shell.touched
		end

	all_spoken: SB_BATCH
		local
			l_keys: ARRAYED_LIST [INTEGER]
		do
			create l_keys.make (8)
			across state.user.cards as ic loop
				l_keys.extend (ic.key)
			end
			Result := (create {SB_SPOKEN}.make (state)).verses_batch (l_keys)
		end

feature {NONE} -- Implementation

	tabs: SB_TABS

	tab: INTEGER

	tab_body: PHONE_COLUMN

	queue: ARRAYED_LIST [SB_CARD]
			-- The cards due when the review opened; "Again" puts a card back at the end.

	is_shown: BOOLEAN

	done: INTEGER

end
