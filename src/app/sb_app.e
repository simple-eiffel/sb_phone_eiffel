note
	description: "[
		SB Phone in Eiffel. Takes the Bible database out of the APK when it is missing or
		the app was updated, showing how far it has got, then opens the app.
	]"
	author: "Larry Rix"

class
	SB_APP

create
	make

feature {NONE} -- Initialization

	make
		do
			create phone.make
			phone.log.set_tag ("Eiffel")
			prepare
			if not failed then
				open
			end
			phone.run_controls
		end

feature {NONE} -- Preparing

	prepare
		local
			l_theme: SB_THEME
			l_body: PHONE_COLUMN
			l_title, l_note: PHONE_LABEL
			l_bar: PHONE_PROGRESS
			l_target, l_stamp: STRING_8
		do
			l_target := phone.storage.internal_path + "/app.db"
			l_stamp := l_target + ".stamp"
			if not ((create {RAW_FILE}.make_with_name (l_target)).exists and then stamp_in (l_stamp).same_string (phone.assets.install_stamp)) then
				create l_theme.make (True)
				phone.controls.set_window_colors (l_theme.background, l_theme.background, False)
				create l_body.make (phone.controls)
				l_body.set_surface (l_theme.background, 0)
				l_body.set_padding (32, 32)
				l_body.call_integer ("setGravity", 16)
				create l_title.make (phone.controls, {STRING_32} "")
				l_title.set_rich (l_theme.styled ({STRING_32} "Preparing the Bible library", l_theme.Title_medium, l_theme.on_background))
				l_title.call_integer ("setGravity", 1)
				create l_note.make (phone.controls, {STRING_32} "")
				l_note.set_rich (l_theme.styled ({STRING_32} "This happens once after installing or updating.", l_theme.Body_small, l_theme.on_background))
				l_note.call_integer ("setGravity", 1)
				l_note.set_padding (0, 8)
				create l_bar.make (phone.controls, 100)
				bar := l_bar
				l_body.extend (l_title)
				l_body.extend (l_note)
				l_body.extend (l_bar)
				phone.controls.show (l_body)
				phone.copy_asset ("app.db", l_target, agent on_progress)
				failed := phone.assets.copy_failed
				if failed then
					l_title.set_rich (l_theme.styled ({STRING_32} "The Bible database could not be prepared.", l_theme.Title_medium, l_theme.on_background))
					l_note.set_rich (l_theme.styled ({STRING_32} "It could not be copied out of the app.", l_theme.Body_small, l_theme.on_background))
				else
					write_stamp (l_stamp)
				end
			end
		end

	on_progress (a_at: REAL_64)
		do
			if attached bar as al_bar then
				al_bar.set_value ((a_at * 100).truncated_to_integer)
			end
		end

	stamp_in (a_path: STRING_8): STRING_8
		local
			l_file: PLAIN_TEXT_FILE
		do
			create Result.make_empty
			create l_file.make_with_name (a_path)
			if l_file.exists then
				l_file.open_read
				l_file.read_line
				Result := l_file.last_string.twin
				l_file.close
			end
		end

	write_stamp (a_path: STRING_8)
		local
			l_file: PLAIN_TEXT_FILE
		do
			create l_file.make_create_read_write (a_path)
			l_file.put_string (phone.assets.install_stamp)
			l_file.put_new_line
			l_file.close
		end

feature {NONE} -- Opening

	open
		local
			l_bible: SB_APP_DB
			l_user: SB_USER_DB
			l_state: SB_STATE
			l_shell: SB_SHELL
		do
			create l_bible.make (phone.storage.internal_path + "/app.db")
			create l_user.make (user_db_path)
			create l_state.make (l_bible, l_user)
			create l_shell.make (phone, l_state, create {SB_PACKS}.make (phone.storage.internal_path), Void)
			l_shell.set_on_new_theme (agent new_theme)
			shell := l_shell
			phone.log.info ("sb: open")
		end

	new_theme (a_old: SB_SHELL)
			-- Every screen takes its colors when made, so the shell is made afresh.
		local
			l_shell: SB_SHELL
		do
			create l_shell.make (phone, a_old.state, a_old.pack_store, a_old.packs)
			l_shell.set_on_new_theme (agent new_theme)
			shell := l_shell
			a_old.give_up_screen
			l_shell.open (create {SB_SETTINGS_PAGE}.make (l_shell))
		end

feature {NONE} -- Implementation

	user_db_path: STRING_8
			-- Where SQLiteOpenHelper keeps user.db in the Kotlin app: `databases' beside `files'.
			-- The notes of an install over that app are found only here.
		local
			l_files: STRING_8
			l_folder: DIRECTORY
		do
			l_files := phone.storage.internal_path
			Result := l_files.substring (1, l_files.last_index_of ('/', l_files.count)) + "databases"
			create l_folder.make_with_name (Result)
			if not l_folder.exists then
				l_folder.recursive_create_dir
			end
			Result.append ("/user.db")
		end

	phone: SIMPLE_EIF_PHONE

	bar: detachable PHONE_PROGRESS

	shell: detachable SB_SHELL

	failed: BOOLEAN

end
