note
	description: "An AlertDialog: a title, content that scrolls, and buttons at the end. Tapping outside or Back closes it."
	author: "Larry Rix"

class
	SB_DIALOG

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL; a_title: READABLE_STRING_32)
		local
			l_title_room: PHONE_COLUMN
			l_ui: SB_UI
		do
			shell := a_shell
			l_ui := a_shell.ui
			ui := l_ui
			create root.make (a_shell.controls)
			create card.make (a_shell.controls)
			create content.make (a_shell.controls)
			create buttons.make (a_shell.controls)
			create title.make (a_shell.controls, {STRING_32} "")
			create last_button.make (a_shell.controls, {STRING_32} "")
			card.set_surface (l_ui.theme.surface_container_high, 28)
			card.set_padding (24, 24)
			card.set_on_tap (agent a_shell.do_nothing)
			create l_title_room.make (a_shell.controls)
			l_title_room.set_padding_each (0, 0, 0, 16)
			title.set_rich (l_ui.theme.styled (a_title, l_ui.theme.Headline_small, l_ui.theme.on_background))
			l_title_room.extend (title)
			card.extend (l_title_room)
			card.extend_growing (l_ui.scroller (content), 1)
			buttons.call_integer ("setGravity", Bottom_end)
			buttons.set_padding_each (0, 24, 0, 0)
			card.extend (buttons)
			root.extend (card)
			root.set_on_outside (agent shell.close_dialog)
		end

feature -- Access

	last_button: PHONE_LABEL
			-- The button added last.

	root: PHONE_DIALOG

	content: PHONE_COLUMN
			-- What the dialog says.

feature -- Element change

	set_title (a_title: READABLE_STRING_32)
		do
			title.set_rich (ui.theme.styled (a_title, ui.theme.Headline_small, ui.theme.on_background))
		end

	add_button (a_text: READABLE_STRING_32; a_action: PROCEDURE [TUPLE])
		do
			last_button := ui.text_button (a_text, a_action)
			buttons.extend (last_button)
		end

	show_enabled (a_button: PHONE_LABEL; a_on: BOOLEAN)
			-- Show `a_button' as a TextButton that is on or off.
		do
			a_button.set_rich (ui.theme.styled (a_button.text, ui.theme.Label_large, if a_on then ui.theme.primary else ui.theme.with_alpha (ui.theme.on_background, 97) end))
		end

	add_close (a_text: READABLE_STRING_32)
			-- A button that only closes the dialog.
		do
			add_button (a_text, agent shell.close_dialog)
		end

feature {NONE} -- Implementation

	shell: SB_SHELL

	ui: SB_UI

	card: PHONE_COLUMN

	title: PHONE_LABEL

	buttons: PHONE_ROW

	Bottom_end: INTEGER = 8388693

end
