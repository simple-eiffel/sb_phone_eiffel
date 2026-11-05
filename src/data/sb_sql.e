note
	description: "[
		A connection, as the data classes use it: every call of android.database.sqlite that the
		Kotlin code makes, over SIMPLE_SQL_DATABASE.

		Values are substituted into the SQL as literals, by `bound'. simple_sql does the same
		(it has no real bind variables), but it cuts a text at a NUL character, and Android keeps
		such a text whole, so the substitution is done here: `sql_text' writes a text holding a
		NUL as a cast of its bytes.

		Text columns come back as UTF-8 and are decoded by `text'. A failed statement raises an
		exception, as Android's rawQuery and execSQL do; `insert' returns -1 instead, as
		SQLiteDatabase.insert does.
	]"
	author: "Larry Rix"

class
	SB_SQL

inherit
	SB_FAILURE
		export
			{NONE} all
		end

create
	make,
	make_read_only

feature {NONE} -- Initialization

	make (a_path: READABLE_STRING_GENERAL)
			-- Open or create the database at `a_path'.
		require
			path_not_empty: not a_path.is_empty
		do
			create database.make (a_path)
			create decoder.make
		end

	make_read_only (a_path: READABLE_STRING_GENERAL)
			-- Open the existing database at `a_path', read only. SQLITE_DATABASE hands SQLite the path
			-- cut to 8 bits, so a path beyond ASCII (a pack id may be) is opened by attaching it, which
			-- goes through a URI in UTF-8. Tables of the attached file need no schema name.
		require
			path_not_empty: not a_path.is_empty
			exists: (create {RAW_FILE}.make_with_name (a_path)).exists
		do
			create decoder.make
			if attached {READABLE_STRING_8} a_path or else not has_high_code (a_path) then
				create database.make_read_only (a_path)
			else
				create database.make_memory
				database.attach_read_only (a_path, "file")
				check_ok ("ATTACH")
			end
		end

	has_high_code (a_text: READABLE_STRING_GENERAL): BOOLEAN
			-- Does `a_text' hold anything beyond ASCII?
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > a_text.count or Result
			loop
				Result := a_text.code (i) > 0x7F
				i := i + 1
			end
		end

feature -- Access

	database: SIMPLE_SQL_DATABASE
			-- The connection.

feature -- Status

	is_open: BOOLEAN
			-- Is the connection open?
		do
			Result := database.is_open
		end

	is_in_transaction: BOOLEAN
			-- Is a transaction open?
		require
			open: is_open
		do
			Result := database.is_in_transaction
		end

feature -- Queries

	rows (a_sql: READABLE_STRING_8; a_args: ARRAY [detachable ANY]): ARRAYED_LIST [SIMPLE_SQL_ROW]
			-- The rows of `a_sql' with `a_args' in place of each ?.
		require
			open: is_open
		do
			Result := database.query (bound (a_sql, a_args)).rows
			check_ok (a_sql)
		end

	integer_set (a_sql: READABLE_STRING_8; a_args: ARRAY [detachable ANY]): SB_ID_SET
			-- The integers in the first column of `a_sql'.
		require
			open: is_open
		local
			l_ids: ARRAYED_LIST [INTEGER_64]
		do
			create l_ids.make (256)
			database.query_stream (bound (a_sql, a_args), agent extend_with_row (l_ids, ?))
			check_ok (a_sql)
			create Result.make_from_list (l_ids)
		end

	first_integer (a_sql: READABLE_STRING_8; a_args: ARRAY [detachable ANY]): INTEGER_64
			-- The integer in the first row, 0 if there is none.
		require
			open: is_open
		local
			l_rows: like rows
		do
			l_rows := rows (a_sql, a_args)
			if not l_rows.is_empty then
				Result := long (l_rows.first, 1)
			end
		end

feature -- Commands

	run (a_sql: READABLE_STRING_8; a_args: ARRAY [detachable ANY])
			-- Run `a_sql' with `a_args' in place of each ?.
		require
			open: is_open
		do
			database.execute (bound (a_sql, a_args))
			check_ok (a_sql)
		end

	insert (a_sql: READABLE_STRING_8; a_args: ARRAY [detachable ANY]): INTEGER_64
			-- Run the INSERT `a_sql': the new row id, or -1 if it failed.
		require
			open: is_open
		do
			database.execute (bound (a_sql, a_args))
			if database.has_error then
				Result := -1
			else
				Result := database.last_insert_rowid
			end
		end

	changes: INTEGER
			-- How many rows the last statement changed.
		require
			open: is_open
		do
			Result := database.changes_count
		end

	begin
			-- Start a transaction.
		require
			open: is_open
			not_in_transaction: not is_in_transaction
		do
			database.begin_transaction
			check_ok ("BEGIN")
		end

	commit
			-- End the transaction, keeping what it did.
		require
			open: is_open
			in_transaction: is_in_transaction
		do
			database.commit
			check_ok ("COMMIT")
		end

	rollback
			-- End the transaction, undoing what it did.
		require
			open: is_open
			in_transaction: is_in_transaction
		do
			database.rollback
		end

	close
			-- Close the connection.
		do
			database.close
		ensure
			closed: not is_open
		end

feature -- Row values

	text (a_row: SIMPLE_SQL_ROW; a_column: INTEGER): STRING_32
			-- The text of column `a_column' (from 1), as Cursor.getString gives it.
		require
			column_in_range: a_column >= 1 and a_column <= a_row.count
		do
			if attached {READABLE_STRING_8} a_row [a_column] as al_text then
				Result := decoder.utf_8_to_utf_32 (al_text)
			elseif attached {INTEGER_64} a_row [a_column] as al_integer then
				create Result.make (20)
				Result.append_string_general (al_integer.out)
			else
				create Result.make_empty
			end
		end

	integer (a_row: SIMPLE_SQL_ROW; a_column: INTEGER): INTEGER
			-- The integer of column `a_column' (from 1), cut to 32 bits as Cursor.getInt does.
		require
			column_in_range: a_column >= 1 and a_column <= a_row.count
		do
			Result := long (a_row, a_column).as_integer_32
		end

	long (a_row: SIMPLE_SQL_ROW; a_column: INTEGER): INTEGER_64
			-- The integer of column `a_column' (from 1), 0 if it is NULL.
		require
			column_in_range: a_column >= 1 and a_column <= a_row.count
		do
			if attached {INTEGER_64} a_row [a_column] as al_integer then
				Result := al_integer
			end
		end

	real (a_row: SIMPLE_SQL_ROW; a_column: INTEGER): REAL_64
			-- The number of column `a_column' (from 1).
		require
			column_in_range: a_column >= 1 and a_column <= a_row.count
		do
			if attached {REAL_64} a_row [a_column] as al_real then
				Result := al_real
			elseif attached {INTEGER_64} a_row [a_column] as al_integer then
				Result := al_integer.to_double
			end
		end

	flag (a_row: SIMPLE_SQL_ROW; a_column: INTEGER): BOOLEAN
			-- Is column `a_column' (from 1) exactly 1?
		require
			column_in_range: a_column >= 1 and a_column <= a_row.count
		do
			Result := integer (a_row, a_column) = 1
		end

	floats (a_row: SIMPLE_SQL_ROW; a_column: INTEGER): ARRAY [REAL_32]
			-- The little-endian 32-bit floats of the blob in column `a_column' (from 1), from index 1.
		require
			column_in_range: a_column >= 1 and a_column <= a_row.count
		local
			i, l_count: INTEGER
		do
			if attached {MANAGED_POINTER} a_row [a_column] as al_blob then
				l_count := al_blob.count // 4
				create Result.make_filled ({REAL_32} 0.0, 1, l_count)
				from
					i := 1
				until
					i > l_count
				loop
					Result [i] := al_blob.read_real_32_le ((i - 1) * 4)
					i := i + 1
				end
			else
				create Result.make_empty
			end
		end

feature -- SQL text

	bound (a_sql: READABLE_STRING_8; a_args: ARRAY [detachable ANY]): STRING_8
			-- `a_sql' with each ? outside a quoted string replaced by the next of `a_args'.
		local
			i, l_arg: INTEGER
			c: CHARACTER_8
			l_quoted: BOOLEAN
		do
			create Result.make (a_sql.count + 32)
			l_arg := a_args.lower
			from
				i := 1
			until
				i > a_sql.count
			loop
				c := a_sql [i]
				if c = '%'' then
					l_quoted := not l_quoted
					Result.append_character (c)
				elseif c = '?' and not l_quoted then
					Result.append (literal (a_args [l_arg]))
					l_arg := l_arg + 1
				else
					Result.append_character (c)
				end
				i := i + 1
			end
		end

	literal (a_value: detachable ANY): STRING_8
			-- `a_value' as SQL.
		do
			if attached {INTEGER_64} a_value as al_long then
				Result := al_long.out
			elseif attached {INTEGER_32} a_value as al_integer then
				Result := al_integer.out
			elseif attached {READABLE_STRING_GENERAL} a_value as al_text then
				Result := sql_text (al_text)
			else
				Result := "NULL"
			end
		end

	sql_text (a_text: READABLE_STRING_GENERAL): STRING_8
			-- `a_text' as a SQL text literal, in UTF-8.
		local
			l_bytes: STRING_8
			i: INTEGER
		do
			l_bytes := {UTF_CONVERTER}.string_32_to_utf_8_string_8 (as_android_stores_it (a_text.to_string_32))
			if l_bytes.has ('%U') then
				create Result.make (l_bytes.count * 2 + 24)
				Result.append ("CAST(X'")
				from
					i := 1
				until
					i > l_bytes.count
				loop
					Result.append (l_bytes.code (i).to_hex_string.substring (7, 8))
					i := i + 1
				end
				Result.append ("' AS TEXT)")
			else
				create Result.make (l_bytes.count + 8)
				Result.append_character ('%'')
				from
					i := 1
				until
					i > l_bytes.count
				loop
					if l_bytes [i] = '%'' then
						Result.append_character ('%'')
					end
					Result.append_character (l_bytes [i])
					i := i + 1
				end
				Result.append_character ('%'')
			end
		end

feature {NONE} -- Implementation

	decoder: SIMPLE_ENCODING
			-- Decodes the UTF-8 of text columns.

	as_android_stores_it (a_text: STRING_32): STRING_32
			-- `a_text' as it ends up in the database on Android. Android binds UTF-16, and SQLite reads
			-- a surrogate with no partner together with whatever unit comes after it.
		local
			i: INTEGER
			c, d: NATURAL_32
			l_lone: BOOLEAN
		do
			from
				i := 1
			until
				i > a_text.count or l_lone
			loop
				l_lone := a_text.code (i) >= 0xD800 and a_text.code (i) <= 0xDFFF
				i := i + 1
			end
			if l_lone then
				create Result.make (a_text.count)
				from
					i := 1
				until
					i > a_text.count
				loop
					c := a_text.code (i)
					if c >= 0xD800 and c <= 0xDFFF and i < a_text.count then
						d := a_text.code (i + 1)
						if d > 0xFFFF then
							d := 0xD800 + ((d - 0x10000) |>> 10)
						end
						Result.append_code ((d & 0x3FF) + ((c & 0x3F) |<< 10) + (((c & 0x3C0) + 0x40) |<< 10))
						i := i + 1
					else
						Result.append_code (c)
					end
					i := i + 1
				end
			else
				Result := a_text
			end
		end

	extend_with_row (a_ids: ARRAYED_LIST [INTEGER_64]; a_row: SIMPLE_SQL_ROW): BOOLEAN
			-- Add the first column of `a_row' to `a_ids'; False, so that the stream goes on.
		do
			a_ids.extend (long (a_row, 1))
		end

	check_ok (a_sql: READABLE_STRING_8)
			-- Raise an exception if the last statement failed.
		local
			l_message: STRING_32
		do
			if database.has_error then
				create l_message.make (a_sql.count + 32)
				if attached database.last_error_message as al_text then
					l_message.append (al_text)
				end
				l_message.append_string_general (" in ")
				l_message.append_string_general (a_sql)
				fail (l_message)
			end
		end

end
