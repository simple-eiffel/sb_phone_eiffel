note
	description: "A favorite verse, range or whole chapter in a folder."
	author: "Larry Rix"

class
	SB_FAVORITE

create
	make

feature {NONE} -- Initialization

	make (a_id, a_folder: INTEGER_64; a_key, a_key_end: INTEGER; a_whole_chapter: BOOLEAN; a_version: STRING_32; a_created: INTEGER_64)
			-- Create the favorite.
		do
			id := a_id
			folder := a_folder
			key := a_key
			key_end := a_key_end
			whole_chapter := a_whole_chapter
			version := a_version
			created := a_created
		ensure
			id_set: id = a_id
			folder_set: folder = a_folder
			key_set: key = a_key
			key_end_set: key_end = a_key_end
			whole_chapter_set: whole_chapter = a_whole_chapter
			version_set: version = a_version
			created_set: created = a_created
		end

feature -- Access

	id, folder: INTEGER_64
			-- The row id and the folder.

	key, key_end: INTEGER
			-- The verse (or chapter, verse 0), and the last verse of a range.

	whole_chapter: BOOLEAN
			-- Does it stand for the whole chapter?

	version: STRING_32
			-- The version it was marked in.

	created: INTEGER_64
			-- When, in ms.

end
