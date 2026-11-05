note
	description: "Puts a verse or its whole chapter in folders. FolderDialog in PersonalScreens.kt."
	author: "Larry Rix"

class
	SB_FOLDER_DIALOG

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
			make_dialog (a_shell, (create {SB_REF}.make_from_key (a_key)).label)
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
			l_row: PHONE_ROW
			l_gap: PHONE_COLUMN
			l_in: ARRAYED_LIST [INTEGER_64]
			l_ref: SB_REF
			l_field: PHONE_FIELD
		do
			l_state := the_shell.state
			l_ui := the_shell.ui
			create l_ref.make_from_key (key)
			content.clear
			set_title (if whole_chapter then l_state.bible.book (l_ref.book).name + {STRING_32} " " + l_ref.chapter.out.to_string_32 else l_ref.label end)
			l_row := l_ui.row
			l_row.extend (l_ui.check_box (whole_chapter))
			l_row.extend (l_ui.label ({STRING_32} "The whole chapter", the_shell.theme.Body_medium, the_shell.theme.on_surface_variant))
			l_row.set_on_tap (agent chapter_tapped)
			content.extend (l_row)
			l_gap := l_ui.column
			l_gap.set_padding (0, 4)
			l_gap.extend (l_ui.divider)
			content.extend (l_gap)
			create l_in.make (4)
			across l_state.user.favorites_of (target_key) as ic loop
				if ic.whole_chapter = whole_chapter then
					l_in.extend (ic.folder)
				end
			end
			across l_state.user.folders as ic loop
				l_row := l_ui.row
				l_row.extend (l_ui.check_box (l_in.has (ic.id)))
				l_row.extend_growing (l_ui.label (ic.name + {STRING_32} "  (" + ic.count.out.to_string_32 + {STRING_32} ")", the_shell.theme.Body_medium, the_shell.theme.on_surface_variant), 1)
				l_row.set_on_tap (agent folder_tapped (ic.id, l_in.has (ic.id)))
				content.extend (l_row)
			end
			l_field := l_ui.field ({STRING_32} "New folder")
			l_field.set_keyboard_action (l_field.Action_done)
			l_field.set_on_action (agent new_folder (l_field))
			content.extend (l_field)
		end

	target_key: INTEGER
		local
			l_ref: SB_REF
		do
			Result := key
			if whole_chapter then
				create l_ref.make_from_key (key)
				Result := (create {SB_REF}.make (l_ref.book, l_ref.chapter, 0, 0)).key
			end
		end

	chapter_tapped
		do
			whole_chapter := not whole_chapter
			show
		end

	folder_tapped (a_folder: INTEGER_64; a_on: BOOLEAN)
		local
			l_state: SB_STATE
		do
			l_state := the_shell.state
			if a_on then
				across l_state.user.favorites_of (target_key) as ic loop
					if ic.folder = a_folder and ic.whole_chapter = whole_chapter then
						l_state.user.remove_favorite (ic.id)
					end
				end
			else
				l_state.user.add_favorite (a_folder, target_key, l_state.version, 0, whole_chapter)
			end
			the_shell.touched
			show
		end

	new_folder (a_field: PHONE_FIELD)
		local
			l_state: SB_STATE
		do
			if not (create {SB_KOTLIN_TEXT}.make).is_blank (a_field.text) then
				l_state := the_shell.state
				l_state.user.add_favorite (l_state.user.add_folder (a_field.text), target_key, l_state.version, 0, whole_chapter)
				the_shell.touched
				show
			end
		end

feature {NONE} -- Implementation

	the_shell: SB_SHELL

	key: INTEGER

	whole_chapter: BOOLEAN

end
