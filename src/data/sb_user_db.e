note
	description: "[
		The user's own data, on this phone only: favorites in folders, highlights with reasons,
		notes (every saved version kept, deletions restorable), a journal, tags, memory cards,
		a prayer list, reading history and settings. Verse keys use English numbering.

		One to one with UserDb.kt. The file is the very file Android's SQLiteOpenHelper keeps,
		and either side can open what the other wrote: PRAGMA user_version 2, table
		android_metadata as Android leaves it, and auto_vacuum and secure_delete as Android's
		SQLite sets them by default.

		Kotlin's optional parameters are written out: `add_favorite' takes all five, `add_card'
		both, `journal' its flag. Kotlin's null is Void.
	]"
	author: "Larry Rix"

class
	SB_USER_DB

inherit
	SB_FAILURE
		export
			{NONE} all
		end

create
	make

feature {NONE} -- Initialization

	make (a_path: READABLE_STRING_GENERAL)
			-- Open or create the file at `a_path', and bring it to version 2.
		require
			path_not_empty: not a_path.is_empty
		local
			l_version: INTEGER_64
			l_is_new: BOOLEAN
		do
			create sql.make (a_path)
			create kotlin.make
			l_is_new := sql.first_integer ("SELECT count(*) FROM sqlite_master", no_args) = 0
			if l_is_new then
				sql.rows ("PRAGMA auto_vacuum = 1", no_args).wipe_out
			end
			sql.rows ("PRAGMA secure_delete = 1", no_args).wipe_out
			write_android_metadata
			l_version := sql.first_integer ("PRAGMA user_version", no_args)
			if l_version > Schema_version then
				fail ({STRING_32} "Can't downgrade database from version " + l_version.out.to_string_32 + {STRING_32} " to " + Schema_version.out.to_string_32)
			elseif l_version < Schema_version then
				sql.begin
				if l_version = 0 then
					create_version_1
				end
				upgrade_to_2
				sql.run ("PRAGMA user_version = " + Schema_version.out, no_args)
				sql.commit
			end
		end

	write_android_metadata
			-- What Android's setLocale leaves in every database it opens.
		do
			sql.run ("CREATE TABLE IF NOT EXISTS android_metadata (locale TEXT)", no_args)
			if sql.first_integer ("SELECT count(*) FROM android_metadata", no_args) = 0 then
				sql.run ("INSERT INTO android_metadata (locale) VALUES (?)", <<Default_locale>>)
			end
		end

	create_version_1
			-- The tables of version 1.
		do
			sql.run ("CREATE TABLE bookmark(key INTEGER PRIMARY KEY, version TEXT NOT NULL, created INTEGER NOT NULL)", no_args)
			sql.run ("CREATE TABLE highlight(key INTEGER PRIMARY KEY, color INTEGER NOT NULL, created INTEGER NOT NULL)", no_args)
			sql.run ("CREATE TABLE note(id INTEGER PRIMARY KEY AUTOINCREMENT, key INTEGER NOT NULL, text TEXT NOT NULL, created INTEGER NOT NULL, updated INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0)", no_args)
			sql.run ("CREATE INDEX note_key ON note(key)", no_args)
			sql.run ("CREATE TABLE note_version(note_id INTEGER NOT NULL, text TEXT NOT NULL, saved INTEGER NOT NULL)", no_args)
			sql.run ("CREATE TABLE history(key INTEGER NOT NULL, version TEXT NOT NULL, at INTEGER NOT NULL)", no_args)
			sql.run ("CREATE INDEX history_at ON history(at)", no_args)
			sql.run ("CREATE TABLE setting(name TEXT PRIMARY KEY, value TEXT NOT NULL)", no_args)
		end

	upgrade_to_2
			-- Version 2: folders and favorites (bookmarks move into "Favorites"), highlight reasons,
			-- journal, tags, cards, prayers.
		do
			sql.run ("CREATE TABLE folder(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, ord INTEGER NOT NULL, created INTEGER NOT NULL)", no_args)
			sql.run ("INSERT INTO folder(id, name, ord, created) VALUES (1, 'Favorites', 0, ?)", <<now>>)
			sql.run ("CREATE TABLE favorite(id INTEGER PRIMARY KEY AUTOINCREMENT, folder INTEGER NOT NULL, key INTEGER NOT NULL, key_end INTEGER NOT NULL DEFAULT 0, whole_chapter INTEGER NOT NULL DEFAULT 0, version TEXT NOT NULL, created INTEGER NOT NULL, UNIQUE(folder, key, key_end, whole_chapter))", no_args)
			sql.run ("CREATE INDEX favorite_key ON favorite(key)", no_args)
			sql.run ("INSERT INTO favorite(folder, key, version, created) SELECT 1, key, version, created FROM bookmark", no_args)
			sql.run ("DROP TABLE bookmark", no_args)
			sql.run ("ALTER TABLE highlight ADD COLUMN reason TEXT NOT NULL DEFAULT ''", no_args)
			sql.run ("CREATE TABLE journal(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, body TEXT NOT NULL, created INTEGER NOT NULL, updated INTEGER NOT NULL, deleted INTEGER NOT NULL DEFAULT 0)", no_args)
			sql.run ("CREATE TABLE journal_version(journal_id INTEGER NOT NULL, title TEXT NOT NULL, body TEXT NOT NULL, saved INTEGER NOT NULL)", no_args)
			sql.run ("CREATE TABLE tag(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE COLLATE NOCASE, created INTEGER NOT NULL)", no_args)
			sql.run ("CREATE TABLE verse_tag(key INTEGER NOT NULL, tag INTEGER NOT NULL, created INTEGER NOT NULL, PRIMARY KEY(key, tag))", no_args)
			sql.run ("CREATE TABLE card(id INTEGER PRIMARY KEY AUTOINCREMENT, key INTEGER NOT NULL, key_end INTEGER NOT NULL DEFAULT 0, created INTEGER NOT NULL, due INTEGER NOT NULL, interval_days INTEGER NOT NULL DEFAULT 0, reps INTEGER NOT NULL DEFAULT 0, lapses INTEGER NOT NULL DEFAULT 0, UNIQUE(key, key_end))", no_args)
			sql.run ("CREATE TABLE prayer(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, details TEXT NOT NULL, key INTEGER NOT NULL DEFAULT 0, created INTEGER NOT NULL, answered INTEGER NOT NULL DEFAULT 0, answer TEXT NOT NULL DEFAULT '', deleted INTEGER NOT NULL DEFAULT 0)", no_args)
		end

feature -- Access

	Schema_version: INTEGER = 2
			-- PRAGMA user_version of a current file.

	now: INTEGER_64
			-- System.currentTimeMillis.
		do
			Result := (create {SB_CLOCK}).now
		end

feature -- Settings

	setting (a_name: READABLE_STRING_GENERAL): detachable STRING_32
			-- The setting `a_name', if set.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
		do
			l_rows := sql.rows ("SELECT value FROM setting WHERE name = ?", <<a_name>>)
			if not l_rows.is_empty then
				Result := sql.text (l_rows.first, 1)
			end
		end

	set_setting (a_name, a_value: READABLE_STRING_GENERAL)
			-- Set the setting `a_name'.
		do
			sql.run ("INSERT OR REPLACE INTO setting(name, value) VALUES (?, ?)", <<a_name, a_value>>)
		end

feature -- Favorites in folders

	folders: ARRAYED_LIST [SB_FOLDER]
			-- Every folder, in order, with how many favorites each holds.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			i: INTEGER
		do
			l_rows := sql.rows ("SELECT f.id, f.name, (SELECT COUNT(*) FROM favorite v WHERE v.folder = f.id) FROM folder f ORDER BY f.ord, f.id", no_args)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				Result.extend (create {SB_FOLDER}.make (sql.long (l_rows [i], 1), sql.text (l_rows [i], 2), sql.integer (l_rows [i], 3)))
				i := i + 1
			end
		end

	favorites (a_folder: INTEGER_64): ARRAYED_LIST [SB_FAVORITE]
			-- The favorites in a folder.
		do
			Result := favorite_list ("SELECT id, folder, key, key_end, whole_chapter, version, created FROM favorite WHERE folder = ? ORDER BY key", <<a_folder>>)
		end

	favorites_of (a_key: INTEGER): ARRAYED_LIST [SB_FAVORITE]
			-- The favorites of a verse, in every folder.
		do
			Result := favorite_list ("SELECT id, folder, key, key_end, whole_chapter, version, created FROM favorite WHERE key = ?", <<a_key>>)
		end

	starred_keys: SB_ID_SET
			-- Verse keys with a star: every verse favorite (ranges count for each verse in them).
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_keys: ARRAYED_LIST [INTEGER_64]
			l_key, l_end, i, j: INTEGER
		do
			l_rows := sql.rows ("SELECT key, key_end FROM favorite WHERE whole_chapter = 0", no_args)
			create l_keys.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				l_key := sql.integer (l_rows [i], 1)
				l_end := sql.integer (l_rows [i], 2)
				if l_end > l_key then
					from
						j := l_key
					until
						j > l_end
					loop
						l_keys.extend (j)
						j := j + 1
					end
				else
					l_keys.extend (l_key)
				end
				i := i + 1
			end
			create Result.make_from_list (l_keys)
		end

	starred_chapters: SB_ID_SET
			-- Chapter keys (verse 0) that are favorites as a whole chapter.
		do
			Result := sql.integer_set ("SELECT key FROM favorite WHERE whole_chapter = 1", no_args)
		end

	add_favorite (a_folder: INTEGER_64; a_key: INTEGER; a_version: READABLE_STRING_GENERAL; a_key_end: INTEGER; a_whole_chapter: BOOLEAN)
			-- Add a favorite to a folder, unless it is there. Kotlin's defaults are 0 and False.
		local
			l_whole: INTEGER
		do
			if a_whole_chapter then
				l_whole := 1
			end
			sql.run ("INSERT OR IGNORE INTO favorite(folder, key, key_end, whole_chapter, version, created) VALUES (?, ?, ?, ?, ?, ?)",
				<<a_folder, a_key, a_key_end, l_whole, a_version, now>>)
		end

	remove_favorite (a_id: INTEGER_64)
			-- Remove a favorite.
		do
			sql.run ("DELETE FROM favorite WHERE id = ?", <<a_id>>)
		end

	toggle_star (a_key: INTEGER; a_version: READABLE_STRING_GENERAL): BOOLEAN
			-- The star in the verse sheet: in "Favorites" (folder 1) or out of every folder. True when now starred.
		local
			l_all: ARRAYED_LIST [SB_FAVORITE]
			l_found: BOOLEAN
			i: INTEGER
		do
			l_all := favorites_of (a_key)
			from
				i := 1
			until
				i > l_all.count
			loop
				if not l_all [i].whole_chapter then
					l_found := True
					remove_favorite (l_all [i].id)
				end
				i := i + 1
			end
			if not l_found then
				add_favorite (1, a_key, a_version, 0, False)
				Result := True
			end
		end

	add_folder (a_name: READABLE_STRING_32): INTEGER_64
			-- Add a folder at the end; its id.
		local
			l_ord: INTEGER_64
		do
			l_ord := sql.first_integer ("SELECT COALESCE(MAX(ord), 0) + 1 FROM folder", no_args)
			Result := sql.insert ("INSERT INTO folder(name, ord, created) VALUES (?, ?, ?)", <<kotlin.trimmed (a_name), l_ord.as_integer_32, now>>)
		end

	rename_folder (a_id: INTEGER_64; a_name: READABLE_STRING_32)
			-- Rename a folder.
		do
			sql.run ("UPDATE folder SET name = ? WHERE id = ?", <<kotlin.trimmed (a_name), a_id>>)
		end

	delete_folder (a_id: INTEGER_64)
			-- Delete a folder and its favorites. The first folder ("Favorites") stays.
		do
			if a_id /= 1 then
				sql.run ("DELETE FROM favorite WHERE folder = ?", <<a_id>>)
				sql.run ("DELETE FROM folder WHERE id = ?", <<a_id>>)
			end
		end

feature -- Highlights

	highlights: ARRAYED_LIST [SB_HIGHLIGHT]
			-- Every highlight, newest first.
		do
			Result := highlight_list ("SELECT key, color, reason, created FROM highlight ORDER BY created DESC", no_args)
		end

	highlight_map: HASH_TABLE [INTEGER, INTEGER]
			-- The color of each highlighted verse, by key.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			i: INTEGER
		do
			l_rows := sql.rows ("SELECT key, color FROM highlight", no_args)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				Result.force (sql.integer (l_rows [i], 2), sql.integer (l_rows [i], 1))
				i := i + 1
			end
		end

	highlight (a_key: INTEGER): detachable SB_HIGHLIGHT
			-- The highlight of a verse, if any.
		local
			l_list: ARRAYED_LIST [SB_HIGHLIGHT]
		do
			l_list := highlight_list ("SELECT key, color, reason, created FROM highlight WHERE key = ?", <<a_key>>)
			if not l_list.is_empty then
				Result := l_list.first
			end
		end

	set_highlight (a_key: INTEGER; a_color: detachable INTEGER_REF)
			-- Set a highlight color (0 to 3), keeping any reason, or clear it when `a_color' is Void.
		do
			if attached a_color as al_color then
				sql.run ("UPDATE highlight SET color = ? WHERE key = ?", <<al_color.item, a_key>>)
				if sql.changes = 0 then
					last_id := sql.insert ("INSERT INTO highlight(key, color, reason, created) VALUES (?, ?, ?, ?)", <<a_key, al_color.item, {STRING_32} "", now>>)
				end
			else
				sql.run ("DELETE FROM highlight WHERE key = ?", <<a_key>>)
			end
		end

	set_highlight_reason (a_key: INTEGER; a_reason: READABLE_STRING_32)
			-- Set why a verse is highlighted.
		do
			sql.run ("UPDATE highlight SET reason = ? WHERE key = ?", <<kotlin.trimmed (a_reason), a_key>>)
		end

feature -- Notes

	notes: ARRAYED_LIST [SB_NOTE]
			-- Every live note, newest first.
		do
			Result := note_list ("SELECT id, key, text, created, updated FROM note WHERE deleted = 0 ORDER BY updated DESC", no_args)
		end

	deleted_notes: ARRAYED_LIST [SB_NOTE]
			-- Deleted notes, each with the last text it had before deletion.
		do
			Result := note_list ("SELECT n.id, n.key, COALESCE((SELECT text FROM note_version v WHERE v.note_id = n.id AND v.text <> '' ORDER BY saved DESC LIMIT 1), n.text), n.created, n.updated FROM note n WHERE n.deleted = 1 ORDER BY n.updated DESC", no_args)
		end

	note_for (a_key: INTEGER): detachable SB_NOTE
			-- The live note of a verse, if any.
		local
			l_list: ARRAYED_LIST [SB_NOTE]
		do
			l_list := note_list ("SELECT id, key, text, created, updated FROM note WHERE key = ? AND deleted = 0 ORDER BY updated DESC LIMIT 1", <<a_key>>)
			if not l_list.is_empty then
				Result := l_list.first
			end
		end

	noted_keys: SB_ID_SET
			-- The verses with a live note.
		do
			Result := sql.integer_set ("SELECT DISTINCT key FROM note WHERE deleted = 0", no_args)
		end

	save_note (a_key: INTEGER; a_text: READABLE_STRING_32)
			-- Save a note's text; every saved text is also kept in note_version. An empty text
			-- deletes it (restorably). Inside the transaction, as in Kotlin, a blank new note and an
			-- unchanged text leave without committing.
		local
			l_time, l_id: INTEGER_64
			l_deleted: INTEGER
			l_save: BOOLEAN
		do
			if attached note_for (a_key) as al_existing then
				l_time := now
				sql.begin
				if not al_existing.text.same_string (a_text) then
					if kotlin.is_blank (a_text) then
						l_deleted := 1
					end
					sql.run ("UPDATE note SET text = ?, updated = ?, deleted = ? WHERE id = ?", <<a_text, l_time, l_deleted, al_existing.id>>)
					l_id := al_existing.id
					l_save := True
				end
			else
				l_time := now
				sql.begin
				if not kotlin.is_blank (a_text) then
					l_id := sql.insert ("INSERT INTO note(key, text, created, updated) VALUES (?, ?, ?, ?)", <<a_key, a_text, l_time, l_time>>)
					l_save := True
				end
			end
			if l_save then
				last_id := sql.insert ("INSERT INTO note_version(note_id, text, saved) VALUES (?, ?, ?)", <<l_id, a_text, l_time>>)
				sql.commit
			else
				sql.rollback
			end
		rescue
			if sql.is_open and then sql.is_in_transaction then
				sql.rollback
			end
		end

	restore_note (a_id: INTEGER_64)
			-- Bring a deleted note back with its last non-empty text. If the verse has a newer note,
			-- the restored text is appended to it.
		local
			l_deleted: ARRAYED_LIST [SB_NOTE]
			l_note: detachable SB_NOTE
			l_time: INTEGER_64
			i: INTEGER
		do
			l_deleted := deleted_notes
			from
				i := 1
			until
				i > l_deleted.count or l_note /= Void
			loop
				if l_deleted [i].id = a_id then
					l_note := l_deleted [i]
				end
				i := i + 1
			end
			if attached l_note as al_note then
				if attached note_for (al_note.key) as al_current then
					save_note (al_note.key, al_current.text + {STRING_32} "%N%N" + al_note.text)
					sql.run ("DELETE FROM note WHERE id = ?", <<a_id>>)
				else
					l_time := now
					sql.run ("UPDATE note SET text = ?, deleted = 0, updated = ? WHERE id = ?", <<al_note.text, l_time, a_id>>)
					last_id := sql.insert ("INSERT INTO note_version(note_id, text, saved) VALUES (?, ?, ?)", <<a_id, al_note.text, l_time>>)
				end
			end
		end

feature -- Journal

	journal (a_deleted: BOOLEAN): ARRAYED_LIST [SB_JOURNAL_ENTRY]
			-- The live entries, or the deleted ones, newest first.
		local
			l_flag: INTEGER
		do
			if a_deleted then
				l_flag := 1
			end
			Result := journal_list ("SELECT id, title, body, created, updated FROM journal WHERE deleted = ? ORDER BY updated DESC", <<l_flag>>)
		end

	journal_entry (a_id: INTEGER_64): detachable SB_JOURNAL_ENTRY
			-- The entry `a_id', if any.
		local
			l_list: ARRAYED_LIST [SB_JOURNAL_ENTRY]
		do
			l_list := journal_list ("SELECT id, title, body, created, updated FROM journal WHERE id = ?", <<a_id>>)
			if not l_list.is_empty then
				Result := l_list.first
			end
		end

	new_journal_entry: INTEGER_64
			-- Insert an empty entry; its id.
		local
			l_time: INTEGER_64
		do
			l_time := now
			Result := sql.insert ("INSERT INTO journal(title, body, created, updated) VALUES ('', '', ?, ?)", <<l_time, l_time>>)
		end

	save_journal (a_id: INTEGER_64; a_title, a_body: READABLE_STRING_32)
			-- Save an entry, keeping every saved version. An entry left completely empty is removed.
		local
			l_time: INTEGER_64
		do
			if attached journal_entry (a_id) as al_old then
				if kotlin.is_blank (a_title) and then kotlin.is_blank (a_body) and then kotlin.is_blank (al_old.title) and then kotlin.is_blank (al_old.body) then
					sql.run ("DELETE FROM journal WHERE id = ?", <<a_id>>)
				elseif not (al_old.title.same_string (a_title) and then al_old.body.same_string (a_body)) then
					l_time := now
					sql.run ("UPDATE journal SET title = ?, body = ?, updated = ? WHERE id = ?", <<a_title, a_body, l_time, a_id>>)
					last_id := sql.insert ("INSERT INTO journal_version(journal_id, title, body, saved) VALUES (?, ?, ?, ?)", <<a_id, a_title, a_body, l_time>>)
				end
			end
		end

	set_journal_deleted (a_id: INTEGER_64; a_deleted: BOOLEAN)
			-- Delete an entry, or bring it back.
		local
			l_flag: INTEGER
		do
			if a_deleted then
				l_flag := 1
			end
			sql.run ("UPDATE journal SET deleted = ?, updated = ? WHERE id = ?", <<l_flag, now, a_id>>)
		end

feature -- Tags

	tags: ARRAYED_LIST [SB_TAG]
			-- Every tag by name, with how many verses carry it.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			i: INTEGER
		do
			l_rows := sql.rows ("SELECT t.id, t.name, (SELECT COUNT(*) FROM verse_tag v WHERE v.tag = t.id) FROM tag t ORDER BY t.name COLLATE NOCASE", no_args)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				Result.extend (create {SB_TAG}.make (sql.long (l_rows [i], 1), sql.text (l_rows [i], 2), sql.integer (l_rows [i], 3)))
				i := i + 1
			end
		end

	tags_of (a_key: INTEGER): SB_ID_SET
			-- The tags of a verse.
		do
			Result := sql.integer_set ("SELECT tag FROM verse_tag WHERE key = ?", <<a_key>>)
		end

	tagged_keys (a_tag: INTEGER_64): ARRAYED_LIST [INTEGER]
			-- The verses carrying a tag.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			i: INTEGER
		do
			l_rows := sql.rows ("SELECT key FROM verse_tag WHERE tag = ? ORDER BY key", <<a_tag>>)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				Result.extend (sql.integer (l_rows [i], 1))
				i := i + 1
			end
		end

	tag_id (a_name: READABLE_STRING_32): INTEGER_64
			-- Find or create a tag by name (case does not matter).
		local
			l_name: STRING_32
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
		do
			l_name := kotlin.trimmed (a_name)
			l_rows := sql.rows ("SELECT id FROM tag WHERE name = ? COLLATE NOCASE", <<l_name>>)
			if l_rows.is_empty then
				Result := sql.insert ("INSERT INTO tag(name, created) VALUES (?, ?)", <<l_name, now>>)
			else
				Result := sql.long (l_rows.first, 1)
			end
		end

	set_tagged (a_key: INTEGER; a_tag: INTEGER_64; a_on: BOOLEAN)
			-- Put a tag on a verse, or take it off.
		do
			if a_on then
				sql.run ("INSERT OR IGNORE INTO verse_tag(key, tag, created) VALUES (?, ?, ?)", <<a_key, a_tag, now>>)
			else
				sql.run ("DELETE FROM verse_tag WHERE key = ? AND tag = ?", <<a_key, a_tag>>)
			end
		end

	delete_tag (a_tag: INTEGER_64)
			-- Delete a tag and take it off every verse.
		do
			sql.run ("DELETE FROM verse_tag WHERE tag = ?", <<a_tag>>)
			sql.run ("DELETE FROM tag WHERE id = ?", <<a_tag>>)
		end

feature -- Memory cards

	cards: ARRAYED_LIST [SB_CARD]
			-- Every card, by verse.
		do
			Result := card_list ("SELECT id, key, key_end, due, interval_days, reps, lapses FROM card ORDER BY key", no_args)
		end

	due_cards: ARRAYED_LIST [SB_CARD]
			-- The cards due now.
		do
			Result := card_list ("SELECT id, key, key_end, due, interval_days, reps, lapses FROM card WHERE due <= ? ORDER BY due, key", <<now>>)
		end

	has_card (a_key: INTEGER): BOOLEAN
			-- Is there a card for this verse?
		do
			Result := not sql.rows ("SELECT 1 FROM card WHERE key = ?", <<a_key>>).is_empty
		end

	add_card (a_key, a_key_end: INTEGER)
			-- Add a card, due now, unless it is there. Kotlin's default for `a_key_end' is 0.
		do
			sql.run ("INSERT OR IGNORE INTO card(key, key_end, created, due) VALUES (?, ?, ?, ?)", <<a_key, a_key_end, now, now>>)
		end

	remove_card (a_id: INTEGER_64)
			-- Remove a card.
		do
			sql.run ("DELETE FROM card WHERE id = ?", <<a_id>>)
		end

	card_got_it (a_card: SB_CARD)
			-- "Got it": the wait doubles (1, 2, 4, 8 days and so on, at most 180).
		local
			l_days: INTEGER
		do
			if a_card.interval_days = 0 then
				l_days := 1
			else
				l_days := a_card.interval_days * 2
			end
			l_days := l_days.min (180)
			sql.run ("UPDATE card SET interval_days = ?, reps = ?, due = ? WHERE id = ?",
				<<l_days, a_card.reps + 1, now + l_days.to_integer_64 * Milliseconds_per_day, a_card.id>>)
		end

	card_again (a_card: SB_CARD)
			-- "Again": back to the start; the card comes round again in this review.
		do
			sql.run ("UPDATE card SET interval_days = 0, lapses = ?, due = ? WHERE id = ?", <<a_card.lapses + 1, now, a_card.id>>)
		end

	next_due: detachable INTEGER_64_REF
			-- When the next card comes round, if there is a card.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
		do
			l_rows := sql.rows ("SELECT MIN(due) FROM card", no_args)
			if not l_rows.is_empty and then attached {INTEGER_64} l_rows.first [1] as al_due then
				Result := al_due
			end
		end

feature -- Prayer list

	prayers (a_answered: BOOLEAN): ARRAYED_LIST [SB_PRAYER]
			-- The answered prayers, or the open ones, newest first.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_row: SIMPLE_SQL_ROW
			i: INTEGER
		do
			if a_answered then
				l_rows := sql.rows ("SELECT id, title, details, key, created, answered, answer FROM prayer WHERE deleted = 0 AND answered > 0 ORDER BY answered DESC", no_args)
			else
				l_rows := sql.rows ("SELECT id, title, details, key, created, answered, answer FROM prayer WHERE deleted = 0 AND answered = 0 ORDER BY created DESC", no_args)
			end
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				l_row := l_rows [i]
				Result.extend (create {SB_PRAYER}.make (sql.long (l_row, 1), sql.text (l_row, 2), sql.text (l_row, 3), sql.integer (l_row, 4), sql.long (l_row, 5), sql.long (l_row, 6), sql.text (l_row, 7)))
				i := i + 1
			end
		end

	save_prayer (a_id: detachable INTEGER_64_REF; a_title, a_details: READABLE_STRING_32; a_key: INTEGER)
			-- Add a prayer when `a_id' is Void, otherwise change it.
		do
			if attached a_id as al_id then
				sql.run ("UPDATE prayer SET title = ?, details = ?, key = ? WHERE id = ?", <<kotlin.trimmed (a_title), kotlin.trimmed (a_details), a_key, al_id.item>>)
			else
				last_id := sql.insert ("INSERT INTO prayer(title, details, key, created) VALUES (?, ?, ?, ?)", <<kotlin.trimmed (a_title), kotlin.trimmed (a_details), a_key, now>>)
			end
		end

	answer_prayer (a_id: INTEGER_64; a_answer: READABLE_STRING_32)
			-- Mark a prayer answered.
		do
			sql.run ("UPDATE prayer SET answered = ?, answer = ? WHERE id = ?", <<now, kotlin.trimmed (a_answer), a_id>>)
		end

	reopen_prayer (a_id: INTEGER_64)
			-- Put an answered prayer back on the list.
		do
			sql.run ("UPDATE prayer SET answered = 0 WHERE id = ?", <<a_id>>)
		end

	delete_prayer (a_id: INTEGER_64)
			-- Delete a prayer.
		do
			sql.run ("UPDATE prayer SET deleted = 1 WHERE id = ?", <<a_id>>)
		end

feature -- History

	record_visit (a_key: INTEGER; a_version: READABLE_STRING_GENERAL)
			-- Record a visit, unless it is to the verse last visited; keep the newest 500.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
		do
			l_rows := sql.rows ("SELECT key FROM history ORDER BY at DESC LIMIT 1", no_args)
			if l_rows.is_empty or else sql.integer (l_rows.first, 1) /= a_key then
				last_id := sql.insert ("INSERT INTO history(key, version, at) VALUES (?, ?, ?)", <<a_key, a_version, now>>)
				sql.run ("DELETE FROM history WHERE rowid NOT IN (SELECT rowid FROM history ORDER BY at DESC LIMIT 500)", no_args)
			end
		end

	history: ARRAYED_LIST [SB_VISIT]
			-- The last 200 visits, newest first.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			i: INTEGER
		do
			l_rows := sql.rows ("SELECT key, version, at FROM history ORDER BY at DESC LIMIT 200", no_args)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				Result.extend (create {SB_VISIT}.make (sql.integer (l_rows [i], 1), sql.text (l_rows [i], 2), sql.long (l_rows [i], 3)))
				i := i + 1
			end
		end

feature -- Export and import

	export_json: STRING_32
			-- Everything, as Android's org.json toString (2) writes it.
		do
			Result := export_json_at (now)
		end

	export_json_at (a_exported: INTEGER_64): STRING_32
			-- `export_json', with `a_exported' as its time of export.
		local
			l_root: SB_JSON_OBJECT
		do
			create l_root.make
			l_root.put_string ("format", {STRING_32} "sb_phone user data")
			l_root.put_integer ("formatVersion", 2)
			l_root.put_long ("exported", a_exported)
			l_root.put_string ("verseKeys", {STRING_32} "book*1000000 + chapter*1000 + verse, English (KJV) numbering")
			l_root.put ("folders", exported_folders)
			l_root.put ("highlights", exported_highlights)
			l_root.put ("notes", exported_notes)
			l_root.put ("journal", exported_journal)
			l_root.put ("tags", exported_tags)
			l_root.put ("cards", exported_cards)
			l_root.put ("prayers", exported_prayers)
			l_root.put ("history", exported_history)
			Result := l_root.indented_text (2)
		end

	export_json_utf_8: STRING_8
			-- `export_json' as the bytes String.toByteArray gives: UTF-8, with ? for a lone surrogate.
		do
			Result := {UTF_CONVERTER}.string_32_to_utf_8_string_8 (without_lone_surrogates (export_json))
		end

	has_import_failed: BOOLEAN
			-- Did the last `import_json' fail, with nothing imported?

	import_json (a_text: READABLE_STRING_32): STRING_32
			-- Merge an export (format 1 or 2) into this phone's data. The summary sentence; when
			-- `has_import_failed', the message Kotlin's exception carries instead, and the
			-- transaction was rolled back.
		local
			l_failed: BOOLEAN
		do
			if l_failed then
				Result := last_message
				has_import_failed := True
			else
				has_import_failed := False
				Result := merged (a_text)
			end
		rescue
			if sql.is_open and then sql.is_in_transaction then
				sql.rollback
			end
			l_failed := True
			retry
		end

	import_json_utf_8 (a_bytes: READABLE_STRING_8): STRING_32
			-- `import_json' on the bytes of a file, as ByteArray.decodeToString reads them.
		local
			l_decoder: SIMPLE_ENCODING
		do
			create l_decoder.make
			Result := import_json (l_decoder.utf_8_to_utf_32 (a_bytes))
		end

feature -- Closing

	close
			-- Close the file.
		do
			sql.close
		end

feature {NONE} -- Implementation

	sql: SB_SQL
			-- The connection.

	kotlin: SB_KOTLIN_TEXT
			-- Kotlin's text rules.

	last_id: INTEGER_64
			-- The id of the last row inserted where nothing asks for it.

	Default_locale: STRING_32 = "en_US"
			-- What android_metadata holds until Android, on opening the file, writes its own.

	Milliseconds_per_day: INTEGER_64 = 86_400_000
			-- The length of a day.

	no_args: ARRAY [detachable ANY]
			-- No arguments.
		do
			create Result.make_empty
		end

	favorite_list (a_sql: READABLE_STRING_8; a_args: ARRAY [detachable ANY]): ARRAYED_LIST [SB_FAVORITE]
			-- The favorites `a_sql' selects.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_row: SIMPLE_SQL_ROW
			i: INTEGER
		do
			l_rows := sql.rows (a_sql, a_args)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				l_row := l_rows [i]
				Result.extend (create {SB_FAVORITE}.make (sql.long (l_row, 1), sql.long (l_row, 2), sql.integer (l_row, 3), sql.integer (l_row, 4), sql.flag (l_row, 5), sql.text (l_row, 6), sql.long (l_row, 7)))
				i := i + 1
			end
		end

	highlight_list (a_sql: READABLE_STRING_8; a_args: ARRAY [detachable ANY]): ARRAYED_LIST [SB_HIGHLIGHT]
			-- The highlights `a_sql' selects.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			i: INTEGER
		do
			l_rows := sql.rows (a_sql, a_args)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				Result.extend (create {SB_HIGHLIGHT}.make (sql.integer (l_rows [i], 1), sql.integer (l_rows [i], 2), sql.text (l_rows [i], 3), sql.long (l_rows [i], 4)))
				i := i + 1
			end
		end

	note_list (a_sql: READABLE_STRING_8; a_args: ARRAY [detachable ANY]): ARRAYED_LIST [SB_NOTE]
			-- The notes `a_sql' selects.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_row: SIMPLE_SQL_ROW
			i: INTEGER
		do
			l_rows := sql.rows (a_sql, a_args)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				l_row := l_rows [i]
				Result.extend (create {SB_NOTE}.make (sql.long (l_row, 1), sql.integer (l_row, 2), sql.text (l_row, 3), sql.long (l_row, 4), sql.long (l_row, 5)))
				i := i + 1
			end
		end

	journal_list (a_sql: READABLE_STRING_8; a_args: ARRAY [detachable ANY]): ARRAYED_LIST [SB_JOURNAL_ENTRY]
			-- The journal entries `a_sql' selects.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_row: SIMPLE_SQL_ROW
			i: INTEGER
		do
			l_rows := sql.rows (a_sql, a_args)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				l_row := l_rows [i]
				Result.extend (create {SB_JOURNAL_ENTRY}.make (sql.long (l_row, 1), sql.text (l_row, 2), sql.text (l_row, 3), sql.long (l_row, 4), sql.long (l_row, 5)))
				i := i + 1
			end
		end

	card_list (a_sql: READABLE_STRING_8; a_args: ARRAY [detachable ANY]): ARRAYED_LIST [SB_CARD]
			-- The cards `a_sql' selects.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_row: SIMPLE_SQL_ROW
			i: INTEGER
		do
			l_rows := sql.rows (a_sql, a_args)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				l_row := l_rows [i]
				Result.extend (create {SB_CARD}.make (sql.long (l_row, 1), sql.integer (l_row, 2), sql.integer (l_row, 3), sql.long (l_row, 4), sql.integer (l_row, 5), sql.integer (l_row, 6), sql.integer (l_row, 7)))
				i := i + 1
			end
		end

feature {NONE} -- Export implementation

	exported_folders: SB_JSON_ARRAY
			-- The folders with their favorites.
		local
			l_folders: ARRAYED_LIST [SB_FOLDER]
			l_favorites: ARRAYED_LIST [SB_FAVORITE]
			l_folder, l_favorite: SB_JSON_OBJECT
			l_array: SB_JSON_ARRAY
			i, j: INTEGER
		do
			create Result.make
			l_folders := folders
			from
				i := 1
			until
				i > l_folders.count
			loop
				create l_folder.make
				l_folder.put_string ("name", l_folders [i].name)
				create l_array.make
				l_favorites := favorites (l_folders [i].id)
				from
					j := 1
				until
					j > l_favorites.count
				loop
					create l_favorite.make
					l_favorite.put_integer ("key", l_favorites [j].key)
					l_favorite.put_integer ("keyEnd", l_favorites [j].key_end)
					l_favorite.put_boolean ("wholeChapter", l_favorites [j].whole_chapter)
					l_favorite.put_string ("version", l_favorites [j].version)
					l_favorite.put_long ("created", l_favorites [j].created)
					l_array.put_object (l_favorite)
					j := j + 1
				end
				l_folder.put ("favorites", l_array)
				Result.put_object (l_folder)
				i := i + 1
			end
		end

	exported_highlights: SB_JSON_ARRAY
			-- The highlights.
		local
			l_list: ARRAYED_LIST [SB_HIGHLIGHT]
			l_object: SB_JSON_OBJECT
			i: INTEGER
		do
			create Result.make
			l_list := highlights
			from
				i := 1
			until
				i > l_list.count
			loop
				create l_object.make
				l_object.put_integer ("key", l_list [i].key)
				l_object.put_integer ("color", l_list [i].color)
				l_object.put_string ("reason", l_list [i].reason)
				l_object.put_long ("created", l_list [i].created)
				Result.put_object (l_object)
				i := i + 1
			end
		end

	exported_notes: SB_JSON_ARRAY
			-- The live notes, then the deleted ones, each with its versions.
		local
			l_versions: HASH_TABLE [SB_JSON_ARRAY, INTEGER_64]
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_array: SB_JSON_ARRAY
			l_object: SB_JSON_OBJECT
			l_id: INTEGER_64
			i: INTEGER
		do
			l_rows := sql.rows ("SELECT note_id, text, saved FROM note_version ORDER BY saved", no_args)
			create l_versions.make (l_rows.count.max (1))
			from
				i := 1
			until
				i > l_rows.count
			loop
				l_id := sql.long (l_rows [i], 1)
				if attached l_versions [l_id] as al_array then
					l_array := al_array
				else
					create l_array.make
					l_versions.force (l_array, l_id)
				end
				create l_object.make
				l_object.put_string ("text", sql.text (l_rows [i], 2))
				l_object.put_long ("saved", sql.long (l_rows [i], 3))
				l_array.put_object (l_object)
				i := i + 1
			end
			create Result.make
			put_notes (Result, notes, False, l_versions)
			put_notes (Result, deleted_notes, True, l_versions)
		end

	put_notes (a_array: SB_JSON_ARRAY; a_notes: ARRAYED_LIST [SB_NOTE]; a_deleted: BOOLEAN; a_versions: HASH_TABLE [SB_JSON_ARRAY, INTEGER_64])
			-- Add `a_notes' to `a_array'.
		local
			l_object: SB_JSON_OBJECT
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_notes.count
			loop
				create l_object.make
				l_object.put_integer ("key", a_notes [i].key)
				l_object.put_string ("text", a_notes [i].text)
				l_object.put_long ("created", a_notes [i].created)
				l_object.put_long ("updated", a_notes [i].updated)
				l_object.put_boolean ("deleted", a_deleted)
				if attached a_versions [a_notes [i].id] as al_versions then
					l_object.put ("versions", al_versions)
				else
					l_object.put ("versions", create {SB_JSON_ARRAY}.make)
				end
				a_array.put_object (l_object)
				i := i + 1
			end
		end

	exported_journal: SB_JSON_ARRAY
			-- The live entries, then the deleted ones.
		do
			create Result.make
			put_journal (Result, journal (False), False)
			put_journal (Result, journal (True), True)
		end

	put_journal (a_array: SB_JSON_ARRAY; a_entries: ARRAYED_LIST [SB_JOURNAL_ENTRY]; a_deleted: BOOLEAN)
			-- Add `a_entries' to `a_array'.
		local
			l_object: SB_JSON_OBJECT
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_entries.count
			loop
				create l_object.make
				l_object.put_string ("title", a_entries [i].title)
				l_object.put_string ("body", a_entries [i].body)
				l_object.put_long ("created", a_entries [i].created)
				l_object.put_long ("updated", a_entries [i].updated)
				l_object.put_boolean ("deleted", a_deleted)
				a_array.put_object (l_object)
				i := i + 1
			end
		end

	exported_tags: SB_JSON_ARRAY
			-- The tags with their verses.
		local
			l_tags: ARRAYED_LIST [SB_TAG]
			l_keys: ARRAYED_LIST [INTEGER]
			l_array: SB_JSON_ARRAY
			l_object: SB_JSON_OBJECT
			i, j: INTEGER
		do
			create Result.make
			l_tags := tags
			from
				i := 1
			until
				i > l_tags.count
			loop
				create l_object.make
				l_object.put_string ("name", l_tags [i].name)
				create l_array.make
				l_keys := tagged_keys (l_tags [i].id)
				from
					j := 1
				until
					j > l_keys.count
				loop
					l_array.put_integer (l_keys [j])
					j := j + 1
				end
				l_object.put ("keys", l_array)
				Result.put_object (l_object)
				i := i + 1
			end
		end

	exported_cards: SB_JSON_ARRAY
			-- The cards.
		local
			l_list: ARRAYED_LIST [SB_CARD]
			l_object: SB_JSON_OBJECT
			i: INTEGER
		do
			create Result.make
			l_list := cards
			from
				i := 1
			until
				i > l_list.count
			loop
				create l_object.make
				l_object.put_integer ("key", l_list [i].key)
				l_object.put_integer ("keyEnd", l_list [i].key_end)
				l_object.put_long ("due", l_list [i].due)
				l_object.put_integer ("intervalDays", l_list [i].interval_days)
				l_object.put_integer ("reps", l_list [i].reps)
				l_object.put_integer ("lapses", l_list [i].lapses)
				Result.put_object (l_object)
				i := i + 1
			end
		end

	exported_prayers: SB_JSON_ARRAY
			-- The open prayers, then the answered ones.
		do
			create Result.make
			put_prayers (Result, prayers (False))
			put_prayers (Result, prayers (True))
		end

	put_prayers (a_array: SB_JSON_ARRAY; a_prayers: ARRAYED_LIST [SB_PRAYER])
			-- Add `a_prayers' to `a_array'.
		local
			l_object: SB_JSON_OBJECT
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_prayers.count
			loop
				create l_object.make
				l_object.put_string ("title", a_prayers [i].title)
				l_object.put_string ("details", a_prayers [i].details)
				l_object.put_integer ("key", a_prayers [i].key)
				l_object.put_long ("created", a_prayers [i].created)
				l_object.put_long ("answered", a_prayers [i].answered)
				l_object.put_string ("answer", a_prayers [i].answer)
				a_array.put_object (l_object)
				i := i + 1
			end
		end

	exported_history: SB_JSON_ARRAY
			-- The last visits.
		local
			l_list: ARRAYED_LIST [SB_VISIT]
			l_object: SB_JSON_OBJECT
			i: INTEGER
		do
			create Result.make
			l_list := history
			from
				i := 1
			until
				i > l_list.count
			loop
				create l_object.make
				l_object.put_integer ("key", l_list [i].key)
				l_object.put_string ("version", l_list [i].version)
				l_object.put_long ("at", l_list [i].at)
				Result.put_object (l_object)
				i := i + 1
			end
		end

	without_lone_surrogates (a_text: STRING_32): STRING_32
			-- `a_text' with ? for each code in the surrogate range.
		local
			i: INTEGER
		do
			Result := a_text
			from
				i := 1
			until
				i > Result.count
			loop
				if Result.code (i) >= 0xD800 and Result.code (i) <= 0xDFFF then
					Result.put_code (0x3F, i)
				end
				i := i + 1
			end
		end

feature {NONE} -- Import implementation

	merged (a_text: READABLE_STRING_32): STRING_32
			-- Merge `a_text'; the summary.
		local
			l_root: SB_JSON_OBJECT
			l_favorites, l_highlights, l_notes, l_journal, l_tags, l_cards, l_prayers: INTEGER
		do
			l_root := (create {SB_JSON_TOKENER}.make (a_text)).root_object
			if not l_root.opt_string ("format", {STRING_32} "").same_string_general ("sb_phone user data") then
				fail ({STRING_32} "This file is not an SB Phone export.")
			end
			sql.begin
			l_favorites := imported_bookmarks (l_root) + imported_folders (l_root)
			l_highlights := imported_highlights (l_root)
			l_notes := imported_notes (l_root)
			l_journal := imported_journal (l_root)
			l_tags := imported_tags (l_root)
			l_cards := imported_cards (l_root)
			l_prayers := imported_prayers (l_root)
			sql.commit
			create Result.make (100)
			Result.append_string_general ("Imported " + l_favorites.out + " favorites, " + l_highlights.out + " highlights, " + l_notes.out + " notes, " + l_journal.out + " journal entries, "
				+ l_tags.out + " tags, " + l_cards.out + " memory cards and " + l_prayers.out + " prayers.")
		end

	imported_bookmarks (a_root: SB_JSON_OBJECT): INTEGER
			-- Format 1 had bookmarks; they go into "Favorites".
		local
			l_object: SB_JSON_OBJECT
			i: INTEGER
		do
			if attached a_root.opt_array ("bookmarks") as al_array then
				from
					i := 0
				until
					i >= al_array.length
				loop
					l_object := al_array.object_at (i)
					add_favorite (1, l_object.integer_at ("key"), l_object.string_at ("version"), 0, False)
					Result := Result + 1
					i := i + 1
				end
			end
		end

	imported_folders (a_root: SB_JSON_OBJECT): INTEGER
			-- The folders; how many favorites.
		local
			l_object, l_favorite: SB_JSON_OBJECT
			l_name: STRING_32
			l_id: INTEGER_64
			i, k: INTEGER
		do
			if attached a_root.opt_array ("folders") as al_array then
				from
					i := 0
				until
					i >= al_array.length
				loop
					l_object := al_array.object_at (i)
					l_name := l_object.string_at ("name")
					l_id := folder_named (l_name)
					if attached l_object.opt_array ("favorites") as al_favorites then
						from
							k := 0
						until
							k >= al_favorites.length
						loop
							l_favorite := al_favorites.object_at (k)
							add_favorite (l_id, l_favorite.integer_at ("key"), l_favorite.opt_string ("version", {STRING_32} "KJV"), l_favorite.opt_integer ("keyEnd"), l_favorite.opt_boolean ("wholeChapter"))
							Result := Result + 1
							k := k + 1
						end
					end
					i := i + 1
				end
			end
		end

	folder_named (a_name: STRING_32): INTEGER_64
			-- The first folder named `a_name', case aside, else a new one.
		local
			l_folders: ARRAYED_LIST [SB_FOLDER]
			i: INTEGER
		do
			l_folders := folders
			from
				i := 1
			until
				i > l_folders.count or Result /= 0
			loop
				if kotlin.equal_ignoring_case (l_folders [i].name, a_name) then
					Result := l_folders [i].id
				end
				i := i + 1
			end
			if Result = 0 then
				Result := add_folder (a_name)
			end
		end

	imported_highlights (a_root: SB_JSON_OBJECT): INTEGER
			-- The highlights; how many.
		local
			l_object: SB_JSON_OBJECT
			i: INTEGER
		do
			if attached a_root.opt_array ("highlights") as al_array then
				from
					i := 0
				until
					i >= al_array.length
				loop
					l_object := al_array.object_at (i)
					sql.run ("INSERT OR REPLACE INTO highlight(key, color, reason, created) VALUES (?, ?, ?, ?)",
						<<l_object.integer_at ("key"), l_object.integer_at ("color"), l_object.opt_string ("reason", {STRING_32} ""), l_object.long_at ("created")>>)
					Result := Result + 1
					i := i + 1
				end
			end
		end

	imported_notes (a_root: SB_JSON_OBJECT): INTEGER
			-- The notes with their versions; how many notes.
		local
			l_object, l_version: SB_JSON_OBJECT
			l_id: INTEGER_64
			l_deleted, i, k: INTEGER
		do
			if attached a_root.opt_array ("notes") as al_array then
				from
					i := 0
				until
					i >= al_array.length
				loop
					l_object := al_array.object_at (i)
					l_deleted := 0
					if l_object.opt_boolean ("deleted") then
						l_deleted := 1
					end
					l_id := sql.insert ("INSERT INTO note(key, text, created, updated, deleted) VALUES (?, ?, ?, ?, ?)",
						<<l_object.integer_at ("key"), l_object.string_at ("text"), l_object.long_at ("created"), l_object.long_at ("updated"), l_deleted>>)
					if attached l_object.opt_array ("versions") as al_versions then
						from
							k := 0
						until
							k >= al_versions.length
						loop
							l_version := al_versions.object_at (k)
							last_id := sql.insert ("INSERT INTO note_version(note_id, text, saved) VALUES (?, ?, ?)", <<l_id, l_version.string_at ("text"), l_version.long_at ("saved")>>)
							k := k + 1
						end
					end
					Result := Result + 1
					i := i + 1
				end
			end
		end

	imported_journal (a_root: SB_JSON_OBJECT): INTEGER
			-- The journal; how many entries.
		local
			l_object: SB_JSON_OBJECT
			l_deleted, i: INTEGER
		do
			if attached a_root.opt_array ("journal") as al_array then
				from
					i := 0
				until
					i >= al_array.length
				loop
					l_object := al_array.object_at (i)
					l_deleted := 0
					if l_object.opt_boolean ("deleted") then
						l_deleted := 1
					end
					last_id := sql.insert ("INSERT INTO journal(title, body, created, updated, deleted) VALUES (?, ?, ?, ?, ?)",
						<<l_object.string_at ("title"), l_object.string_at ("body"), l_object.long_at ("created"), l_object.long_at ("updated"), l_deleted>>)
					Result := Result + 1
					i := i + 1
				end
			end
		end

	imported_tags (a_root: SB_JSON_OBJECT): INTEGER
			-- The tags; how many.
		local
			l_object: SB_JSON_OBJECT
			l_id: INTEGER_64
			i, k: INTEGER
		do
			if attached a_root.opt_array ("tags") as al_array then
				from
					i := 0
				until
					i >= al_array.length
				loop
					l_object := al_array.object_at (i)
					l_id := tag_id (l_object.string_at ("name"))
					Result := Result + 1
					if attached l_object.opt_array ("keys") as al_keys then
						from
							k := 0
						until
							k >= al_keys.length
						loop
							set_tagged (al_keys.integer_at (k), l_id, True)
							k := k + 1
						end
					end
					i := i + 1
				end
			end
		end

	imported_cards (a_root: SB_JSON_OBJECT): INTEGER
			-- The memory cards; how many.
		local
			l_object: SB_JSON_OBJECT
			i: INTEGER
		do
			if attached a_root.opt_array ("cards") as al_array then
				from
					i := 0
				until
					i >= al_array.length
				loop
					l_object := al_array.object_at (i)
					sql.run ("INSERT OR IGNORE INTO card(key, key_end, created, due, interval_days, reps, lapses) VALUES (?, ?, ?, ?, ?, ?, ?)",
						<<l_object.integer_at ("key"), l_object.opt_integer ("keyEnd"), now, l_object.opt_long ("due", now), l_object.opt_integer ("intervalDays"), l_object.opt_integer ("reps"), l_object.opt_integer ("lapses")>>)
					Result := Result + 1
					i := i + 1
				end
			end
		end

	imported_prayers (a_root: SB_JSON_OBJECT): INTEGER
			-- The prayers; how many.
		local
			l_object: SB_JSON_OBJECT
			i: INTEGER
		do
			if attached a_root.opt_array ("prayers") as al_array then
				from
					i := 0
				until
					i >= al_array.length
				loop
					l_object := al_array.object_at (i)
					last_id := sql.insert ("INSERT INTO prayer(title, details, key, created, answered, answer) VALUES (?, ?, ?, ?, ?, ?)",
						<<l_object.string_at ("title"), l_object.opt_string ("details", {STRING_32} ""), l_object.opt_integer ("key"), l_object.opt_long ("created", now), l_object.opt_long ("answered", 0), l_object.opt_string ("answer", {STRING_32} "")>>)
					Result := Result + 1
					i := i + 1
				end
			end
		end

end
