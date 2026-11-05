note
	description: "[
		A private data pack loaded from a file the user chose. It never ships in the app; it lives
		only in this phone's private storage. Format "sb_phone pack": pack_meta, doc, doc_ref
		(verse keys a doc covers or cites), doc_fts (folded text). One to one with PackDb.kt; the
		companion object of that class is SB_PACKS here.

		`search' asks where the typed word stands in lower (d.body). On Android lower () is ICU's,
		and here it is not, so the body comes back whole and `icu_lowercase' does what SQL does.
	]"
	author: "Larry Rix"

class
	SB_PACK_DB

inherit
	SB_FAILURE
		export
			{NONE} all
		end

create
	make

feature {NONE} -- Initialization

	make (a_path: READABLE_STRING_GENERAL)
			-- Open the pack at `a_path'. An exception tells that it is not an SB Phone pack.
		require
			path_not_empty: not a_path.is_empty
			exists: (create {RAW_FILE}.make_with_name (a_path)).exists
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_format: detachable STRING_32
			i: INTEGER
		do
			path := a_path.to_string_32
			create sql.make_read_only (a_path)
			create fold.make
			create kotlin.make
			create meta.make (8)
			l_format := stored_format
			if l_format = Void or else not l_format.same_string_general (Format) then
				sql.close
				fail ({STRING_32} "not an SB Phone pack")
			end
			l_rows := sql.rows ("SELECT key, value FROM pack_meta", no_args)
			from
				i := 1
			until
				i > l_rows.count
			loop
				meta.force (sql.text (l_rows [i], 2), utf_8 (sql.text (l_rows [i], 1)))
				i := i + 1
			end
		end

	stored_format: detachable STRING_32
			-- The format in the file, Void if it has none or is no database.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_failed: BOOLEAN
		do
			if not l_failed then
				l_rows := sql.rows ("SELECT value FROM pack_meta WHERE key = 'format'", no_args)
				if not l_rows.is_empty then
					Result := sql.text (l_rows.first, 1)
				end
			end
		rescue
			l_failed := True
			retry
		end

feature -- Access

	Format: STRING_8 = "sb_phone pack"
			-- What pack_meta says of a pack.

	path: STRING_32
			-- The file.

	meta: HASH_TABLE [STRING_32, STRING_8]
			-- Table pack_meta, keyed by the UTF-8 of each key; `meta_value' takes the key as text.

	meta_value (a_key: READABLE_STRING_GENERAL): detachable STRING_32
			-- The value of `a_key' in table pack_meta, if any.
		do
			Result := meta [utf_8 (a_key.to_string_32)]
		end

	title: STRING_32
			-- The pack's title, else its file name without the extension.
		local
			l_name: STRING_32
			l_dot: INTEGER
		do
			if attached meta_value ("title") as al_title then
				Result := al_title
			else
				l_name := kotlin.file_name_of (path)
				l_dot := l_name.last_index_of ('.', l_name.count)
				if l_dot > 0 then
					Result := l_name.substring (1, l_dot - 1)
				else
					Result := l_name
				end
			end
		end

	kinds: ARRAYED_LIST [TUPLE [kind: STRING_32; n: INTEGER]]
			-- The kinds of document, with how many of each.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			i: INTEGER
		do
			l_rows := sql.rows ("SELECT kind, COUNT(*) FROM doc GROUP BY kind ORDER BY kind", no_args)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				Result.extend ([sql.text (l_rows [i], 1), sql.integer (l_rows [i], 2)])
				i := i + 1
			end
		end

	docs (a_kind: READABLE_STRING_GENERAL): ARRAYED_LIST [SB_PACK_DOC]
			-- The documents of a kind.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			i: INTEGER
		do
			l_rows := sql.rows ("SELECT id, kind, title, collection, status, path, words FROM doc WHERE kind = ? ORDER BY collection, sort, title", <<a_kind>>)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				Result.extend (doc_from (l_rows [i]))
				i := i + 1
			end
		end

	doc (a_id: INTEGER_64): detachable SB_PACK_DOC
			-- The document `a_id', if any.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
		do
			l_rows := sql.rows ("SELECT id, kind, title, collection, status, path, words FROM doc WHERE id = ?", <<a_id>>)
			if not l_rows.is_empty then
				Result := doc_from (l_rows.first)
			end
		end

	body (a_id: INTEGER_64): STRING_32
			-- The text of a document, empty if there is none.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
		do
			l_rows := sql.rows ("SELECT body FROM doc WHERE id = ?", <<a_id>>)
			if l_rows.is_empty then
				create Result.make_empty
			else
				Result := sql.text (l_rows.first, 1)
			end
		end

	for_verse (a_eng_key: INTEGER): ARRAYED_LIST [SB_PACK_HIT]
			-- Commentary sections covering a verse, then other documents that cite it.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			i: INTEGER
		do
			l_rows := sql.rows ("SELECT d.id, d.kind, d.title, d.collection, d.status, d.path, d.words, substr(d.body, 1, 400) FROM doc_ref r JOIN doc d ON d.id = r.doc WHERE r.eng_key = ? ORDER BY CASE d.kind WHEN 'commentary' THEN 0 ELSE 1 END, r.covers DESC, d.kind, d.title LIMIT 200", <<a_eng_key>>)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				Result.extend (create {SB_PACK_HIT}.make (doc_from (l_rows [i]), sql.text (l_rows [i], 8)))
				i := i + 1
			end
		end

	Default_limit: INTEGER = 200
			-- How many hits `search' gives.

	search (a_text: READABLE_STRING_32): ARRAYED_LIST [SB_PACK_HIT]
			-- `search_limited' with the default limit.
		do
			Result := search_limited (a_text, Default_limit)
		end

	search_limited (a_text: READABLE_STRING_32; a_limit: INTEGER): ARRAYED_LIST [SB_PACK_HIT]
			-- Full-text search over titles and bodies; every word required.
		local
			l_words: ARRAYED_LIST [STRING_32]
			l_match, l_first, l_body, l_raw: STRING_32
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_at, i: INTEGER
		do
			l_words := fold.words (a_text)
			if l_words.is_empty then
				create Result.make (0)
			else
				create l_match.make (a_text.count + 8)
				from
					i := 1
				until
					i > l_words.count
				loop
					if i > 1 then
						l_match.append_code (32)
					end
					l_match.append (l_words [i])
					l_match.append_code (0x2A)
					i := i + 1
				end
					-- The index holds folded text, so the excerpt is cut from the original around the first typed word.
				l_first := kotlin.without_quotes_and_stars (kotlin.lowercase (kotlin.first_word (a_text)))
				l_rows := sql.rows ("SELECT d.id, d.kind, d.title, d.collection, d.status, d.path, d.words, d.body FROM doc_fts JOIN doc d ON d.id = doc_fts.docid WHERE doc_fts MATCH ? LIMIT " + a_limit.out, <<l_match>>)
				create Result.make (l_rows.count)
				from
					i := 1
				until
					i > l_rows.count
				loop
					l_body := sql.text (l_rows [i], 8)
					if l_first.is_empty then
						l_at := 1
					else
						l_at := kotlin.icu_lowercase (l_body).substring_index (l_first, 1)
					end
					l_raw := l_body.substring ((l_at - 70).max (1), ((l_at - 70).max (1) + 299).min (l_body.count))
					Result.extend (create {SB_PACK_HIT}.make (doc_from (l_rows [i]), excerpt (l_raw, l_at)))
					i := i + 1
				end
			end
		end

	refs_of (a_doc: INTEGER_64): ARRAYED_LIST [SB_REF]
			-- Verses a document covers or cites, in canon order.
		local
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			i: INTEGER
		do
			l_rows := sql.rows ("SELECT DISTINCT eng_key FROM doc_ref WHERE doc = ? ORDER BY eng_key", <<a_doc>>)
			create Result.make (l_rows.count)
			from
				i := 1
			until
				i > l_rows.count
			loop
				Result.extend (create {SB_REF}.make_from_key (sql.integer (l_rows [i], 1)))
				i := i + 1
			end
		end

feature -- Status

	is_open: BOOLEAN
			-- Is the file open?
		do
			Result := sql.is_open
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

	fold: SB_FOLD
			-- Search folding.

	kotlin: SB_KOTLIN_TEXT
			-- Kotlin's text rules.

	no_args: ARRAY [detachable ANY]
			-- No arguments.
		do
			create Result.make_empty
		end

	utf_8 (a_text: STRING_32): STRING_8
			-- `a_text' in UTF-8.
		do
			Result := {UTF_CONVERTER}.string_32_to_utf_8_string_8 (a_text)
		end

	doc_from (a_row: SIMPLE_SQL_ROW): SB_PACK_DOC
			-- The document in the first seven columns of `a_row'.
		do
			create Result.make (sql.long (a_row, 1), sql.text (a_row, 2), sql.text (a_row, 3), sql.text (a_row, 4), sql.text (a_row, 5), sql.text (a_row, 6), sql.integer (a_row, 7))
		end

	excerpt (a_raw: STRING_32; a_at: INTEGER): STRING_32
			-- Start the excerpt on a word boundary, a few words before the match.
		local
			l_space: INTEGER
		do
			if a_at > 70 then
				create Result.make (a_raw.count + 1)
				Result.append_code (0x2026)
				l_space := a_raw.index_of (' ', 1)
				if l_space > 0 then
					Result.append (kotlin.with_spaces_collapsed (a_raw.substring (l_space + 1, a_raw.count)))
				else
					Result.append (kotlin.with_spaces_collapsed (a_raw))
				end
			else
				Result := kotlin.with_spaces_collapsed (a_raw)
			end
		end

end
