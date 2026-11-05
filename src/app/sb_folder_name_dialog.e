note
	description: "Names, renames or deletes a folder. FolderNameDialog in LibraryScreen.kt."
	author: "Larry Rix"

class
	SB_FOLDER_NAME_DIALOG

inherit
	SB_DIALOG
		rename
			make as make_dialog
		end

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL; a_folder: detachable SB_FOLDER)
		local
			l_field: PHONE_FIELD
		do
			make_dialog (a_shell, if attached a_folder then {STRING_32} "Folder" else {STRING_32} "New folder" end)
			the_shell := a_shell
			folder := a_folder
			l_field := a_shell.ui.field ({STRING_32} "Name")
			field := l_field
			if attached a_folder as al_folder then
				l_field.set_text (al_folder.name)
				if al_folder.id /= 1 then
					add_button ({STRING_32} "Delete%/8230/", agent ask_delete)
				end
			end
			content.extend (l_field)
			add_close ({STRING_32} "Cancel")
			add_button ({STRING_32} "Save", agent save)
			save_button := last_button
			l_field.set_on_change (agent check_name)
			check_name
		end

feature {NONE} -- Implementation

	check_name
		do
			show_enabled (save_button, not (create {SB_KOTLIN_TEXT}.make).is_blank (field.text))
		end

	save
		do
			if not (create {SB_KOTLIN_TEXT}.make).is_blank (field.text) then
				if attached folder as al_folder then
					the_shell.state.user.rename_folder (al_folder.id, field.text)
				else
					the_shell.state.user.add_folder (field.text).do_nothing
				end
				the_shell.touched
				the_shell.close_dialog
			end
		end

	ask_delete
		local
			l_ask: SB_DIALOG
		do
			the_shell.close_dialog
			create l_ask.make (the_shell, {STRING_32} "Delete this folder and its favorites?")
			l_ask.content.extend (the_shell.ui.label ({STRING_32} "The verses themselves are not touched.", the_shell.theme.Body_medium, the_shell.theme.on_surface_variant))
			l_ask.add_close ({STRING_32} "Cancel")
			l_ask.add_button ({STRING_32} "Delete", agent delete)
			the_shell.show_dialog (l_ask)
		end

	delete
		do
			if attached folder as al_folder then
				the_shell.state.user.delete_folder (al_folder.id)
				the_shell.touched
			end
			the_shell.close_dialog
		end

	the_shell: SB_SHELL

	folder: detachable SB_FOLDER

	field: PHONE_FIELD

	save_button: PHONE_LABEL
		attribute
			Result := last_button
		end

end
