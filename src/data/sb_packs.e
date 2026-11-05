note
	description: "[
		The packs of this phone: the companion object of PackDb.kt, over a folder rather than an
		Android Context. `a_files' is the app's private files folder; packs live in packs/ under it.
		The app shell reads the chosen content URI into `incoming_path' and calls `load_incoming',
		or calls `load' with a path it can read.
	]"
	author: "Larry Rix"

class
	SB_PACKS


create
	make

feature {NONE} -- Initialization

	make (a_files: READABLE_STRING_GENERAL)
			-- Use the folder packs under `a_files', creating it if need be.
		require
			files_not_empty: not a_files.is_empty
		local
			l_directory: DIRECTORY
		do
			create folder.make_from_string_general (a_files)
			folder.append_string_general ("/packs")
			create l_directory.make_with_name (folder)
			if not l_directory.exists then
				l_directory.recursive_create_dir
			end
			create load_failure.make_empty
			create kotlin.make
		end

feature -- Access

	folder: STRING_32
			-- Where the packs live.

	incoming_path: STRING_32
			-- Where a chosen file is copied first.
		do
			Result := folder + {STRING_32} "/incoming.tmp"
		end

	load_failure: STRING_32
			-- Why the last `load' gave Void: the message of Kotlin's exception.

feature -- Basic operations

	open_all: ARRAYED_LIST [SB_PACK_DB]
			-- Every pack already loaded on this phone, sorted by file name. Unreadable files are skipped.
		local
			l_names: ARRAYED_LIST [STRING_32]
			l_directory: DIRECTORY
			l_name: STRING_32
			l_dot, i, j: INTEGER
			l_entries: ARRAYED_LIST [PATH]
		do
			create l_directory.make_with_name (folder)
			l_entries := l_directory.entries
			create l_names.make (l_entries.count)
			from
				i := 1
			until
				i > l_entries.count
			loop
				l_name := l_entries [i].name.to_string_32
				l_dot := l_name.last_index_of ('.', l_name.count)
				if l_dot > 0 and then l_name.substring (l_dot + 1, l_name.count).same_string_general ("db") then
					from
						j := 1
					until
						j > l_names.count or else kotlin.is_before_in_utf_16 (l_name, l_names [j])
					loop
						j := j + 1
					end
					l_names.go_i_th (j)
					l_names.put_left (l_name)
				end
				i := i + 1
			end
			create Result.make (l_names.count)
			from
				i := 1
			until
				i > l_names.count
			loop
				if attached opened (folder + {STRING_32} "/" + l_names [i]) as al_pack then
					Result.extend (al_pack)
				end
				i := i + 1
			end
		end

	load (a_source: READABLE_STRING_GENERAL): detachable SB_PACK_DB
			-- Copy a chosen file into private storage after checking it is an SB Phone pack. A pack
			-- with the same id replaces the earlier one. The loaded pack, or Void with `load_failure' set.
		local
			l_source, l_copy: RAW_FILE
		do
			create l_source.make_with_name (a_source)
			create l_copy.make_with_name (incoming_path)
			l_source.open_read
			l_copy.open_write
			l_source.copy_to (l_copy)
			l_copy.close
			l_source.close
			Result := load_incoming
		end

	load_incoming: detachable SB_PACK_DB
			-- `load' for a file already at `incoming_path'.
		local
			l_file: RAW_FILE
			l_id: STRING_32
			l_target: STRING_32
		do
			create load_failure.make_empty
			create l_file.make_with_name (incoming_path)
			if attached opened (incoming_path) as al_probe then
				l_id := pack_id (al_probe)
				al_probe.close
				l_target := folder + {STRING_32} "/" + l_id + {STRING_32} ".db"
				delete_if_there (l_target)
				l_file.rename_file (l_target)
				Result := opened (l_target)
				if Result = Void then
					load_failure := {STRING_32} "could not place the pack"
				end
			else
				l_file.delete
				load_failure := {STRING_32} "This file is not an SB Phone pack."
			end
		end

	remove (a_pack: SB_PACK_DB)
			-- Close a pack and delete its file.
		do
			a_pack.close
			delete_if_there (a_pack.path)
		end

feature {NONE} -- Implementation

	kotlin: SB_KOTLIN_TEXT
			-- Kotlin's text rules.

	opened (a_path: READABLE_STRING_32): detachable SB_PACK_DB
			-- The pack at `a_path', or Void if it is not one.
		local
			l_failed: BOOLEAN
		do
			if not l_failed then
				create Result.make (a_path)
			end
		rescue
			l_failed := True
			retry
		end

	pack_id (a_pack: SB_PACK_DB): STRING_32
			-- The name a pack is stored under: its id, letters, digits, - and _ only, else "pack".
		local
			l_id: STRING_32
			i: INTEGER
			c: NATURAL_32
		do
			if attached a_pack.meta_value ("id") as al_id then
				l_id := al_id
			else
				l_id := {STRING_32} "pack"
			end
			create Result.make (l_id.count)
			from
				i := 1
			until
				i > l_id.count
			loop
				c := l_id.code (i)
				if kotlin.is_letter_or_digit (c) or else c = 0x2D or else c = 0x5F then
					Result.append_code (c)
				end
				i := i + 1
			end
			if Result.is_empty then
				Result := {STRING_32} "pack"
			end
		end

	delete_if_there (a_path: READABLE_STRING_32)
			-- Delete the file at `a_path' if it exists.
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_name (a_path)
			if l_file.exists then
				l_file.delete
			end
		end

end
