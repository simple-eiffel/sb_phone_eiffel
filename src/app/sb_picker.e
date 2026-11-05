note
	description: "[
		Go to, as PickerScreen.kt has it: book, then chapter, or a typed reference.
		An ambiguous book gives a choice, never a guess.
	]"
	author: "Larry Rix"

class
	SB_PICKER

inherit
	SB_OVERLAY
		redefine
			handle_back
		end

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL)
		do
			make_overlay (a_shell, {STRING_32} "Go to")
			typed := ui.field ({STRING_32} "Reference")
			create message.make (controls, {STRING_32} "")
			create choices.make (controls)
			create holder.make (controls)
			scroll := ui.scroller (holder)
			create typed_box.make (controls)
			typed.set_placeholder ({STRING_32} "jn 3 16")
			typed.set_keyboard_action (typed.Action_go)
			typed.set_on_action (agent go)
			typed.set_on_change (agent on_typed)
			message.set_color (theme.error)
			message.set_padding (20, 0)
			message.set_visible (False)
			choices.set_visible (False)
			holder.set_padding (12, 0)
			typed_box.set_padding (16, 8)
			typed_box.extend (typed)
			content.extend (typed_box)
			content.extend (message)
			content.extend (choices)
			content.extend_growing (scroll, 1)
			show_books
		end

feature -- Status

	handle_back: BOOLEAN
			-- From a book's chapters, Back returns to the books.
		do
			if book /= 0 then
				book := 0
				set_title ({STRING_32} "Go to")
				show_books
				Result := True
			end
		end

feature {NONE} -- Grids

	show_books
		local
			l_flow: PHONE_FLOW
		do
			holder.clear
			add_header ({STRING_32} "Old Testament")
			l_flow := new_flow (76)
			across state.bible.books as ic loop
				if ic.id <= 39 then
					add_cell (l_flow, ic.short, ic.id = state.book_id, agent book_tapped (ic.id))
				end
			end
			holder.extend (l_flow)
			add_header ({STRING_32} "New Testament")
			l_flow := new_flow (76)
			across state.bible.books as ic loop
				if ic.id > 39 then
					add_cell (l_flow, ic.short, ic.id = state.book_id, agent book_tapped (ic.id))
				end
			end
			holder.extend (l_flow)
		end

	show_chapters
		local
			l_flow: PHONE_FLOW
			i: INTEGER
		do
			holder.clear
			add_header ({STRING_32} "Chapter")
			l_flow := new_flow (56)
			from i := 1 until i > state.bible.book (book).chapters loop
				add_cell (l_flow, i.out.to_string_32, book = state.book_id and i = state.chapter_number, agent chapter_tapped (i))
				i := i + 1
			end
			holder.extend (l_flow)
		end

	new_flow (a_cell: INTEGER): PHONE_FLOW
		do
			create Result.make (controls)
			Result.set_cell_width (a_cell)
			Result.set_cell_height (44)
			Result.set_flow_gap (6)
		end

	add_header (a_text: READABLE_STRING_32)
		local
			l_label: PHONE_LABEL
		do
			create l_label.make (controls, {STRING_32} "")
			l_label.set_rich (theme.styled (a_text, theme.Title_small, theme.primary))
			l_label.set_padding (4, 12)
			holder.extend (l_label)
		end

	add_cell (a_flow: PHONE_FLOW; a_text: READABLE_STRING_32; a_current: BOOLEAN; a_action: PROCEDURE [TUPLE])
		local
			l_label: PHONE_LABEL
		do
			create l_label.make (controls, a_text)
			l_label.set_rich (theme.styled (a_text, theme.Body_medium, theme.on_background))
			l_label.call_integer ("setGravity", Center)
			l_label.call_boolean ("setSingleLine", True)
			l_label.set_surface (if a_current then theme.with_alpha (theme.primary, 64) else theme.surface_container_high end, 8)
			l_label.set_on_tap (a_action)
			a_flow.extend (l_label)
		end

	book_tapped (a_book: INTEGER)
		do
			book := a_book
			set_title (state.bible.book (a_book).name)
			show_chapters
		end

	chapter_tapped (a_chapter: INTEGER)
		do
			shell.go_to (create {SB_REF}.make (book, a_chapter, 0, 0))
		end

feature {NONE} -- A typed reference

	on_typed
		do
			message.set_visible (False)
			choices.set_visible (False)
		end

	go
		local
			l_label: PHONE_LABEL
			l_parsed: SB_REF_PARSE
		do
			l_parsed := (create {SB_REF_PARSER}.make).parse (typed.text)
			if attached {SB_REF_PARSE_ONE} l_parsed as al_one then
				shell.go_to (al_one.ref)
			elseif attached {SB_REF_PARSE_CHOICE} l_parsed as al_choice then
				choices.clear
				message.set_visible (False)
				create l_label.make (controls, {STRING_32} "Which did you mean?")
				l_label.set_rich (theme.styled ({STRING_32} "Which did you mean?", theme.Body_large, theme.on_background))
				l_label.set_padding (20, 0)
				choices.extend (l_label)
				across al_choice.refs as ic loop
					choices.extend (ui.text_button (ic.label, agent shell.go_to (ic)))
				end
				choices.set_visible (True)
			else
				message.set_text ({STRING_32} "That doesn't read as a reference. Try %"John 3:16%" or %"ps 23%".")
				message.set_visible (True)
				choices.set_visible (False)
			end
		end

feature {NONE} -- Implementation

	book: INTEGER
			-- The book whose chapters are showing, or 0.

	typed: PHONE_FIELD

	typed_box, holder, choices: PHONE_COLUMN

	message: PHONE_LABEL

	scroll: PHONE_SCROLL

	Center: INTEGER = 17

end
