note
	description: "Tags a verse. TagDialog in PersonalScreens.kt."
	author: "Larry Rix"

class
	SB_TAG_DIALOG

inherit
	SB_DIALOG
		rename
			make as make_dialog
		end

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL; a_key: INTEGER)
		do
			make_dialog (a_shell, {STRING_32} "Tags %/183/ " + (create {SB_REF}.make_from_key (a_key)).short_label)
			the_shell := a_shell
			key := a_key
			add_close ({STRING_32} "Done")
			show
		end

feature {NONE} -- Showing

	show
		local
			l_state: SB_STATE
			l_ui: SB_UI
			l_all: ARRAYED_LIST [SB_TAG]
			l_mine: SB_ID_SET
			l_flow: PHONE_FLOW
			l_field: PHONE_FIELD
		do
			l_state := the_shell.state
			l_ui := the_shell.ui
			content.clear
			l_all := l_state.user.tags
			l_mine := l_state.user.tags_of (key)
			if l_all.is_empty then
				content.extend (l_ui.label ({STRING_32} "No tags yet. Type one below.", the_shell.theme.Body_medium, the_shell.theme.on_surface_variant))
			end
			create l_flow.make (the_shell.controls)
			l_flow.set_flow_gap (6)
			across l_all as ic loop
				l_flow.extend (l_ui.filter_chip (ic.name, l_mine.has (ic.id), agent tag_tapped (ic.id, l_mine.has (ic.id))))
			end
			content.extend (l_flow)
			l_field := l_ui.field ({STRING_32} "New tag")
			l_field.set_keyboard_action (l_field.Action_done)
			l_field.set_on_action (agent new_tag (l_field))
			content.extend (l_field)
		end

	tag_tapped (a_tag: INTEGER_64; a_on: BOOLEAN)
		do
			the_shell.state.user.set_tagged (key, a_tag, not a_on)
			the_shell.touched
			show
		end

	new_tag (a_field: PHONE_FIELD)
		local
			l_state: SB_STATE
		do
			if not (create {SB_KOTLIN_TEXT}.make).is_blank (a_field.text) then
				l_state := the_shell.state
				l_state.user.set_tagged (key, l_state.user.tag_id (a_field.text), True)
				the_shell.touched
				show
			end
		end

feature {NONE} -- Implementation

	the_shell: SB_SHELL

	key: INTEGER

end
