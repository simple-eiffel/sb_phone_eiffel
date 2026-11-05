note
	description: "[
		The Eiffel side of the data differential: for each case, the same canonical lines that
		testing/diff/DataOracle.java writes from the real Kotlin classes, Android's SQLite and
		org.json. The output goes through `emit': to a file on the PC (SB_DATA_DIFF_APP), into a hash
		on the emulator (spikes/s_data), where the same code runs compiled by gec.

		A case is fields separated by tabs: the operation, then its arguments. Text is hexadecimal
		code points separated by spaces; ~ stands for Void. Pages are written from 0, as Kotlin
		counts them.
	]"
	author: "Larry Rix"

deferred class
	SB_DATA_DIFF

feature -- Running

	run_app (a_database, a_cases: READABLE_STRING_32)
			-- Run the cases of SB_APP_DB on `a_database'.
		do
			create app.make (a_database)
			create parser.make
			for_each_case (a_cases, agent app_case, False)
			if attached app as al_app then
				al_app.close
			end
		end

	run_user (a_folder, a_cases: READABLE_STRING_32)
			-- Run the cases of SB_USER_DB on user.db in `a_folder'.
		local
			l_directory: DIRECTORY
			l_path: STRING_32
		do
			create l_directory.make_with_name (a_folder)
			if not l_directory.exists then
				l_directory.recursive_create_dir
			end
			l_path := a_folder + {STRING_32} "/user.db"
			user_path := l_path
			create user.make (l_path)
			for_each_case (a_cases, agent user_case, True)
			if attached user as al_user then
				al_user.close
			end
		end

	run_pack (a_files, a_cases: READABLE_STRING_32)
			-- Run the cases of SB_PACK_DB on the packs under `a_files'.
		local
			l_packs: SB_PACKS
			l_all: ARRAYED_LIST [SB_PACK_DB]
			i: INTEGER
		do
			create l_packs.make (a_files)
			packs := l_packs
			l_all := l_packs.open_all
			from
				i := 1
			until
				i > l_all.count
			loop
				line ("pack " + esc (kotlin.file_name_of (l_all [i].path)) + "|" + esc (l_all [i].title))
				i := i + 1
			end
			if not l_all.is_empty then
				pack := l_all.first
			end
			for_each_case (a_cases, agent pack_case, False)
			if attached pack as al_pack and then al_pack.is_open then
				al_pack.close
			end
		end

	run_text (a_cases: READABLE_STRING_32)
			-- Write Kotlin's text rules for each line of `a_cases'.
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_name (a_cases)
			l_file.open_read
			from
				l_file.read_line
			until
				l_file.end_of_file and l_file.last_string.is_empty
			loop
				text_case (decoded (l_file.last_string))
				if l_file.end_of_file then
					l_file.last_string.wipe_out
				else
					l_file.read_line
				end
			end
			l_file.close
		end

	run_export (a_database: READABLE_STRING_32; a_exported: INTEGER_64)
			-- Write the export of the user.db at `a_database', as of `a_exported'.
		local
			l_user: SB_USER_DB
		do
			create l_user.make (a_database)
			emit ({UTF_CONVERTER}.string_32_to_utf_8_string_8 (l_user.export_json_at (a_exported)))
			l_user.close
		end

feature {NONE} -- Output

	emit (a_text: READABLE_STRING_8)
			-- Send out `a_text'.
		deferred
		end

	line (a_text: READABLE_STRING_8)
			-- Send out `a_text' as a line.
		do
			emit (a_text)
			emit ("%N")
		end

feature {NONE} -- Implementation

	app: detachable SB_APP_DB
			-- The Bible database.

	user: detachable SB_USER_DB
			-- The user's database.

	user_path: detachable STRING_32
			-- Where `user' is.

	pack: detachable SB_PACK_DB
			-- The pack in use.

	packs: detachable SB_PACKS
			-- The packs.

	parser: detachable SB_QUERY_PARSER
			-- Reads searches.

	kotlin: SB_KOTLIN_TEXT
			-- Kotlin's text rules.
		once
			create Result.make
		end

	for_each_case (a_cases: READABLE_STRING_32; a_case: PROCEDURE [ARRAYED_LIST [STRING_8]]; a_timed: BOOLEAN)
			-- Run `a_case' on each line of `a_cases'.
		local
			l_file: RAW_FILE
			l_fields: LIST [STRING_8]
			l_list: ARRAYED_LIST [STRING_8]
		do
			create l_file.make_with_name (a_cases)
			l_file.open_read
			from
				l_file.read_line
			until
				l_file.end_of_file and l_file.last_string.is_empty
			loop
				l_fields := l_file.last_string.split ('%T')
				create l_list.make (l_fields.count)
				across l_fields as ic loop
					l_list.extend (ic.twin)
				end
				if a_timed and then attached user as al_user then
					line ("#T " + al_user.now.out)
				end
				line ("# " + esc (l_file.last_string.to_string_32))
				guarded (a_case, l_list)
				if a_timed then
					pause
				end
				if l_file.end_of_file then
					l_file.last_string.wipe_out
				else
					l_file.read_line
				end
			end
			l_file.close
		end

	guarded (a_case: PROCEDURE [ARRAYED_LIST [STRING_8]]; a_fields: ARRAYED_LIST [STRING_8])
			-- Run `a_case', writing any exception instead of stopping.
		local
			l_failed: BOOLEAN
		do
			if not l_failed then
				a_case.call ([a_fields])
			end
		rescue
			l_failed := True
			if attached (create {EXCEPTION_MANAGER}).last_exception as al_exception and then attached al_exception.description as al_text then
				line ("exception " + esc (al_text.to_string_32))
			else
				line ("exception")
			end
			retry
		end

	pause
			-- Wait a few milliseconds, so that no two operations share a time.
		do
			(create {EXECUTION_ENVIRONMENT}).sleep (2_000_000)
		end

feature {NONE} -- The cases of SB_APP_DB

	app_case (f: ARRAYED_LIST [STRING_8])
			-- One case.
		local
			l_op: STRING_8
			l_db: SB_APP_DB
			i: INTEGER
			l_books: ARRAYED_LIST [SB_BOOK_INFO]
			l_versions: ARRAYED_LIST [SB_VERSION]
		do
			check attached app as al_app then
				l_db := al_app
			end
			l_op := f [1]
			if l_op.same_string ("versions") then
				l_versions := l_db.versions
				from i := 1 until i > l_versions.count loop
					line (esc (l_versions [i].code) + "|" + esc (l_versions [i].name) + "|" + esc (l_versions [i].language) + "|" + flag (l_versions [i].rtl) + "|" + esc (l_versions [i].versification) + "|" + esc (l_versions [i].coverage) + "|" + l_versions [i].first_id.out + "|" + l_versions [i].last_id.out)
					i := i + 1
				end
			elseif l_op.same_string ("books") then
				l_books := l_db.books
				from i := 1 until i > l_books.count loop
					line (l_books [i].id.out + "|" + esc (l_books [i].code) + "|" + esc (l_books [i].name) + "|" + esc (l_books [i].short) + "|" + l_books [i].chapters.out)
					i := i + 1
				end
			elseif l_op.same_string ("chapters") then
				line ("n " + l_db.chapters.count.out)
				from i := 1 until i > l_db.chapters.count loop
					line (l_db.chapters [i].book.out + ":" + l_db.chapters [i].chapter.out + "=" + (l_db.page_of (l_db.chapters [i].book, l_db.chapters [i].chapter) - 1).out)
					i := i + 1
				end
			elseif l_op.same_string ("page") then
				line ("P " + (l_db.page_of (f [2].to_integer, f [3].to_integer) - 1).out)
			elseif l_op.same_string ("version") then
				line (esc (l_db.version (decoded (f [2])).code))
			elseif l_op.same_string ("vic") then
				write_verses (l_db.verses_in_chapter (decoded (f [2]), f [3].to_integer, f [4].to_integer))
			elseif l_op.same_string ("vat") then
				write_verses (l_db.verses_at (f [2].to_integer, optional (f [3])))
			elseif l_op.same_string ("preview") then
				line (esc (l_db.preview_text (create {SB_REF}.make (f [2].to_integer, f [3].to_integer, f [4].to_integer, f [5].to_integer), decoded (f [6]))))
			elseif l_op.same_string ("words") then
				write_words (l_db.words (f [2].to_integer))
			elseif l_op.same_string ("lemma") then
				if attached l_db.lemma (f [2].to_integer) as al_lemma then
					line (lemma_text (al_lemma))
				else
					line ("none")
				end
			elseif l_op.same_string ("bystrongs") then
				write_lemmas (l_db.lemmas_by_strongs (decoded (f [2])))
			elseif l_op.same_string ("matching") then
				write_lemmas (l_db.lemmas_matching (decoded (f [2]), decoded (f [3])))
			elseif l_op.same_string ("kjvlem") then
				write_lemmas (l_db.kjv_lemmas (f [2].to_integer, decoded (f [3]), f [4].to_integer))
			elseif l_op.same_string ("search") then
				write_search (l_db, decoded (f [2]), optional (f [3]), f [4].to_integer)
			else
				app_lists (l_db, f)
			end
		end

	app_lists (a_db: SB_APP_DB; f: ARRAYED_LIST [STRING_8])
			-- One case that writes a list ended by "end".
		local
			l_op: STRING_8
			i: INTEGER
		do
			l_op := f [1]
			if l_op.same_string ("senses") then
				across a_db.senses (f [2].to_integer) as ic loop
					line ("s " + esc (ic.source) + "|" + esc (ic.entry) + "|" + ic.depth.out + "|" + esc (ic.label) + "|" + esc (ic.gloss) + "|" + esc (ic.text) + "|" + esc (ic.domain) + "|" + esc (ic.note_text))
				end
				line ("end")
			elseif l_op.same_string ("renderings") then
				across a_db.renderings (f [2].to_integer) as ic loop
					line ("r " + esc (ic.english) + "|" + ic.n.out)
				end
				line ("end")
			elseif l_op.same_string ("occ") then
				across a_db.occurrences (f [2].to_integer) as ic loop
					line ("o " + ic.eng_key.out + "|" + esc (ic.gloss))
				end
				line ("end")
			elseif l_op.same_string ("kjvlinked") then
				across a_db.kjv_linked (f [2].to_integer) as ic loop
					line ("k " + esc (ic.fold) + "|" + ic.nth.out)
				end
				line ("end")
			elseif l_op.same_string ("shifted") then
				across a_db.shifted_in (f [2].to_integer) as ic loop
					line ("h " + esc (ic))
				end
				line ("end")
			elseif l_op.same_string ("english") then
				write_english (a_db.english_entry (decoded (f [2])))
			elseif l_op.same_string ("lanes") then
				across a_db.lanes as ic loop
					line (esc (ic.id) + "|" + esc (ic.title) + "|" + esc (ic.group))
				end
			elseif l_op.same_string ("events") then
				across a_db.events (optional (f [2])) as ic loop
					line (esc (ic.id) + "|" + esc (ic.lane) + "|" + esc (ic.title) + "|" + esc (ic.kind) + "|" + ic.importance.out + "|" + esc (ic.summary) + "|" + esc (ic.status) + "|" + ic.earliest.out + "|" + ic.latest.out + "|" + esc (ic.label))
				end
				line ("end")
			elseif l_op.same_string ("claims") then
				across a_db.claims (decoded (f [2])) as ic loop
					line (esc (ic.label) + "|" + esc (ic.chronology) + "|" + esc (ic.held_by) + "|" + esc (ic.basis) + "|" + flag (ic.lean) + "|" + esc (ic.note_text) + "|" + esc (ic.citation))
				end
				line ("end")
			elseif l_op.same_string ("places") then
				across a_db.places (optional (f [2])) as ic loop
					line (esc (ic.id) + "|" + esc (ic.name) + "|" + esc (ic.kind) + "|" + ic.min_zoom.out + "|" + float_hex (ic.lon) + "|" + float_hex (ic.lat))
				end
				line ("end")
			elseif l_op.same_string ("land") then
				from
					i := 1
				until
					i > a_db.land.count
				loop
					line (esc (a_db.land [i].kind) + "|" + ring_text (a_db.land [i].ring))
					i := i + 1
				end
				line ("end")
			elseif l_op.same_string ("areas") then
				across a_db.areas (f [2].to_integer) as ic loop
					line (esc (ic.name) + "|" + ic.year_from.out + "|" + ic.year_to.out + "|" + ring_text (ic.ring))
				end
				line ("end")
			elseif l_op.same_string ("xrefs") then
				across a_db.xrefs (f [2].to_integer) as ic loop
					line (ic.to_key.out + "|" + ic.to_end.out + "|" + ic.votes.out + "|" + ic.ref.book.out + "|" + ic.ref.chapter.out + "|" + ic.ref.verse.out + "|" + ic.ref.verse_end.out)
				end
				line ("end")
			elseif l_op.same_string ("sources") then
				across a_db.sources as ic loop
					line (esc (ic.code) + "|" + esc (ic.name) + "|" + esc (ic.kind) + "|" + esc (ic.license) + "|" + esc (ic.credit) + "|" + esc (ic.url) + "|" + flag (ic.share_alike))
				end
			elseif l_op.same_string ("source") then
				if attached a_db.source (decoded (f [2])) as al_source then
					line (esc (al_source.name))
				else
					line ("none")
				end
			elseif l_op.same_string ("meta") then
				if attached a_db.meta (decoded (f [2])) as al_meta then
					line (esc (al_meta))
				else
					line ("none")
				end
			else
				line ("unknown operation")
			end
		end

	write_verses (a_verses: ARRAYED_LIST [SB_VERSE])
			-- The verses.
		do
			line ("n " + a_verses.count.out)
			across a_verses as ic loop
				line ("V " + ic.id.out + "|" + esc (ic.version) + "|" + ic.book.out + "|" + ic.chapter.out + "|" + ic.verse.out + "|" + ic.eng_key.out
					+ "|" + esc (ic.own_label) + "|" + flag (ic.differs_from_english) + "|" + esc (ic.text))
			end
		end

	write_words (a_words: ARRAYED_LIST [SB_WORD])
			-- The words.
		do
			line ("n " + a_words.count.out)
			across a_words as ic loop
				line ("W " + ic.id.out + "|" + ic.eng_key.out + "|" + ic.book.out + "|" + ic.chapter.out + "|" + ic.verse.out + "|" + ic.pos.out + "|" + esc (ic.surface) + "|" + esc (ic.after)
					+ "|" + esc (ic.translit) + "|" + esc (ic.gloss) + "|" + ic.lemma.out + "|" + esc (ic.morph) + "|" + esc (ic.parse))
			end
		end

	lemma_text (a_lemma: SB_LEMMA): STRING_8
			-- The line of a lemma.
		do
			Result := "L " + a_lemma.id.out + "|" + esc (a_lemma.language) + "|" + esc (a_lemma.headword) + "|" + esc (a_lemma.translit) + "|" + esc (a_lemma.pron) + "|" + esc (a_lemma.strongs)
				+ "|" + esc (a_lemma.pos) + "|" + a_lemma.count.out + "|" + esc (a_lemma.number) + "|" + esc (a_lemma.hint) + "|" + flag (a_lemma.is_hebrew) + "|" + esc (a_lemma.language_name)
		end

	write_lemmas (a_lemmas: ARRAYED_LIST [SB_LEMMA])
			-- The lemmas.
		do
			line ("n " + a_lemmas.count.out)
			across a_lemmas as ic loop
				line (lemma_text (ic))
			end
		end

	write_english (a_entry: SB_ENGLISH_ENTRY)
			-- An English word.
		do
			line ("E " + esc (a_entry.lemma))
			across a_entry.forms as ic loop
				line ("f " + esc (ic))
			end
			across a_entry.behind as ic loop
				line ("b " + ic.n.out + " " + lemma_text (ic.lemma))
			end
			across a_entry.senses as ic loop
				line ("s " + esc (ic.source) + "|" + esc (ic.year) + "|" + esc (ic.sense_no) + "|" + esc (ic.pos) + "|" + esc (ic.text) + "|" + esc (ic.cite))
			end
			across a_entry.shifts as ic loop
				line ("x " + ic.out)
			end
			line ("end")
		end

	write_search (a_db: SB_APP_DB; a_query: STRING_32; a_version: detachable STRING_32; a_limit: INTEGER)
			-- A search.
		local
			l_query: SB_SEARCH_QUERY
			l_result: SB_SEARCH_RESULT
			l_line: STRING_8
			l_hash: NATURAL_64
			l_keys: ARRAYED_LIST [INTEGER_64]
			l_sorted: SB_ID_SET
			i: INTEGER
		do
			check attached parser as al_parser then
				if attached {SB_QUERY_PARSE_TEXT} al_parser.parse (a_query) as al_text then
					l_query := al_text.query
					last_search_start := clock_ms
					l_result := a_db.search_limited (l_query, a_version, a_limit)
					searched (a_query, a_version, clock_ms - last_search_start)
					create l_line.make (256)
					l_line.append ("S " + l_result.total.out + "|" + flag (l_result.by_verse) + "|" + l_result.verses.count.out + "|")
					l_hash := Fnv_start
					across l_result.verses as ic loop
						l_line.append (ic.id.out + ",")
						l_hash := hash_text (l_hash, ic.version)
						l_hash := hash_text (l_hash, ic.text)
						l_hash := hash_integer (l_hash, ic.eng_key.as_natural_32)
					end
					l_line.append ("|" + l_hash.out + "|")
					across l_result.matches as ic loop
						l_line.append (esc (ic.fts) + " ")
					end
					line (l_line)
					create l_keys.make (l_result.word_hits.count)
					from
						l_result.word_hits.start
					until
						l_result.word_hits.after
					loop
						l_keys.extend (l_result.word_hits.key_for_iteration)
						l_result.word_hits.forth
					end
					create l_sorted.make_from_list (l_keys)
					from
						i := 1
					until
						i > l_sorted.count
					loop
						create l_line.make (64)
						l_line.append ("H " + l_sorted [i].out)
						if attached l_result.word_hits [l_sorted [i].as_integer_32] as al_hits then
							across al_hits as ic loop
								l_line.append ("|" + esc (ic))
							end
						end
						line (l_line)
						i := i + 1
					end
				else
					line ("not a text query")
				end
			end
		end

	searched (a_query: STRING_32; a_version: detachable STRING_32; a_ms: INTEGER_64)
			-- `a_query' took `a_ms'.
		do
		end

	last_search_start: INTEGER_64
			-- When the search being timed began.

	clock_ms: INTEGER_64
			-- A clock, in milliseconds.
		do
			Result := (create {SB_CLOCK}).now
		end

feature {NONE} -- The cases of SB_USER_DB

	user_case (f: ARRAYED_LIST [STRING_8])
			-- One case.
		local
			l_op: STRING_8
			l_db: SB_USER_DB
		do
			check attached user as al_user then
				l_db := al_user
			end
			l_op := f [1]
			if l_op.same_string ("set") then
				l_db.set_setting (decoded (f [2]), decoded (f [3]))
			elseif l_op.same_string ("get") then
				if attached l_db.setting (decoded (f [2])) as al_value then
					line (esc (al_value))
				else
					line ("none")
				end
			elseif l_op.same_string ("folders") then
				across l_db.folders as ic loop
					line (ic.id.out + "|" + esc (ic.name) + "|" + ic.count.out)
				end
				line ("end")
			elseif l_op.same_string ("favs") then
				write_favorites (l_db.favorites (f [2].to_integer_64))
			elseif l_op.same_string ("favsof") then
				write_favorites (l_db.favorites_of (f [2].to_integer))
			elseif l_op.same_string ("starred") then
				write_set (l_db.starred_keys)
			elseif l_op.same_string ("starchap") then
				write_set (l_db.starred_chapters)
			elseif l_op.same_string ("addfav") then
				l_db.add_favorite (f [2].to_integer_64, f [3].to_integer, decoded (f [4]), f [5].to_integer, f [6].same_string ("1"))
			elseif l_op.same_string ("rmfav") then
				l_db.remove_favorite (f [2].to_integer_64)
			elseif l_op.same_string ("toggle") then
				line ("toggle " + flag (l_db.toggle_star (f [2].to_integer, decoded (f [3]))))
			elseif l_op.same_string ("addfolder") then
				line ("id " + l_db.add_folder (decoded (f [2])).out)
			elseif l_op.same_string ("renfolder") then
				l_db.rename_folder (f [2].to_integer_64, decoded (f [3]))
			elseif l_op.same_string ("delfolder") then
				l_db.delete_folder (f [2].to_integer_64)
			elseif l_op.same_string ("hls") then
				across l_db.highlights as ic loop
					line (highlight_text (ic))
				end
				line ("end")
			elseif l_op.same_string ("hlmap") then
				write_map (l_db.highlight_map)
			elseif l_op.same_string ("hl") then
				if attached l_db.highlight (f [2].to_integer) as al_highlight then
					line (highlight_text (al_highlight))
				else
					line ("none")
				end
			elseif l_op.same_string ("sethl") then
				if f [3].same_string ("~") then
					l_db.set_highlight (f [2].to_integer, Void)
				else
					l_db.set_highlight (f [2].to_integer, f [3].to_integer)
				end
			elseif l_op.same_string ("sethlr") then
				l_db.set_highlight_reason (f [2].to_integer, decoded (f [3]))
			else
				user_notes_case (l_db, f)
			end
		end

	user_notes_case (a_db: SB_USER_DB; f: ARRAYED_LIST [STRING_8])
			-- One case of notes, journal and tags.
		local
			l_op: STRING_8
		do
			l_op := f [1]
			if l_op.same_string ("notes") then
				write_notes (a_db.notes)
			elseif l_op.same_string ("delnotes") then
				write_notes (a_db.deleted_notes)
			elseif l_op.same_string ("notefor") then
				if attached a_db.note_for (f [2].to_integer) as al_note then
					line (note_text (al_note))
				else
					line ("none")
				end
			elseif l_op.same_string ("noted") then
				write_set (a_db.noted_keys)
			elseif l_op.same_string ("save") then
				a_db.save_note (f [2].to_integer, decoded (f [3]))
			elseif l_op.same_string ("restore") then
				a_db.restore_note (f [2].to_integer_64)
			elseif l_op.same_string ("journal") then
				across a_db.journal (f [2].same_string ("1")) as ic loop
					line (entry_text (ic))
				end
				line ("end")
			elseif l_op.same_string ("jentry") then
				if attached a_db.journal_entry (f [2].to_integer_64) as al_entry then
					line (entry_text (al_entry))
				else
					line ("none")
				end
			elseif l_op.same_string ("newj") then
				line ("id " + a_db.new_journal_entry.out)
			elseif l_op.same_string ("savej") then
				a_db.save_journal (f [2].to_integer_64, decoded (f [3]), decoded (f [4]))
			elseif l_op.same_string ("setjdel") then
				a_db.set_journal_deleted (f [2].to_integer_64, f [3].same_string ("1"))
			elseif l_op.same_string ("tags") then
				across a_db.tags as ic loop
					line (ic.id.out + "|" + esc (ic.name) + "|" + ic.count.out)
				end
				line ("end")
			elseif l_op.same_string ("tagsof") then
				write_set (a_db.tags_of (f [2].to_integer))
			elseif l_op.same_string ("tagged") then
				write_integers (a_db.tagged_keys (f [2].to_integer_64))
			elseif l_op.same_string ("tagid") then
				line ("id " + a_db.tag_id (decoded (f [2])).out)
			elseif l_op.same_string ("settag") then
				a_db.set_tagged (f [2].to_integer, f [3].to_integer_64, f [4].same_string ("1"))
			elseif l_op.same_string ("deltag") then
				a_db.delete_tag (f [2].to_integer_64)
			else
				user_cards_case (a_db, f)
			end
		end

	user_cards_case (a_db: SB_USER_DB; f: ARRAYED_LIST [STRING_8])
			-- One case of cards, prayers, history and export.
		local
			l_op: STRING_8
		do
			l_op := f [1]
			if l_op.same_string ("cards") then
				write_cards (a_db.cards)
			elseif l_op.same_string ("due") then
				write_cards (a_db.due_cards)
			elseif l_op.same_string ("hascard") then
				line ("has " + flag (a_db.has_card (f [2].to_integer)))
			elseif l_op.same_string ("addcard") then
				a_db.add_card (f [2].to_integer, f [3].to_integer)
			elseif l_op.same_string ("rmcard") then
				a_db.remove_card (f [2].to_integer_64)
			elseif l_op.same_string ("gotit") then
				if attached card_with_id (a_db, f [2].to_integer_64) as al_card then
					a_db.card_got_it (al_card)
				end
			elseif l_op.same_string ("again") then
				if attached card_with_id (a_db, f [2].to_integer_64) as al_card then
					a_db.card_again (al_card)
				end
			elseif l_op.same_string ("nextdue") then
				if attached a_db.next_due as al_due then
					line (al_due.item.out)
				else
					line ("none")
				end
			elseif l_op.same_string ("prayers") then
				across a_db.prayers (f [2].same_string ("1")) as ic loop
					line (ic.id.out + "|" + esc (ic.title) + "|" + esc (ic.details) + "|" + ic.key.out + "|" + ic.created.out + "|" + ic.answered.out + "|" + esc (ic.answer))
				end
				line ("end")
			elseif l_op.same_string ("savep") then
				if f [2].same_string ("~") then
					a_db.save_prayer (Void, decoded (f [3]), decoded (f [4]), f [5].to_integer)
				else
					a_db.save_prayer (f [2].to_integer_64, decoded (f [3]), decoded (f [4]), f [5].to_integer)
				end
			elseif l_op.same_string ("answer") then
				a_db.answer_prayer (f [2].to_integer_64, decoded (f [3]))
			elseif l_op.same_string ("reopen") then
				a_db.reopen_prayer (f [2].to_integer_64)
			elseif l_op.same_string ("delp") then
				a_db.delete_prayer (f [2].to_integer_64)
			elseif l_op.same_string ("visit") then
				a_db.record_visit (f [2].to_integer, decoded (f [3]))
			elseif l_op.same_string ("history") then
				across a_db.history as ic loop
					line (ic.key.out + "|" + esc (ic.version) + "|" + ic.at.out)
				end
				line ("end")
			elseif l_op.same_string ("export") then
				line (esc (a_db.export_json))
			elseif l_op.same_string ("import") then
				write_import (a_db, decoded (f [2]))
			elseif l_op.same_string ("dump") then
				write_dump
			else
				line ("unknown operation")
			end
		end

	write_import (a_db: SB_USER_DB; a_text: STRING_32)
			-- Import `a_text'.
		local
			l_text: STRING_32
		do
			l_text := a_db.import_json (a_text)
			if a_db.has_import_failed then
				line ("import failed " + esc (l_text))
			else
				line ("import " + esc (l_text))
			end
		end

	card_with_id (a_db: SB_USER_DB; a_id: INTEGER_64): detachable SB_CARD
			-- The card `a_id', if any.
		do
			across a_db.cards as ic loop
				if ic.id = a_id then
					Result := ic
				end
			end
		end

	write_favorites (a_list: ARRAYED_LIST [SB_FAVORITE])
			-- The favorites.
		do
			across a_list as ic loop
				line (ic.id.out + "|" + ic.folder.out + "|" + ic.key.out + "|" + ic.key_end.out + "|" + flag (ic.whole_chapter) + "|" + esc (ic.version) + "|" + ic.created.out)
			end
			line ("end")
		end

	highlight_text (a_item: SB_HIGHLIGHT): STRING_8
			-- The line of a highlight.
		do
			Result := a_item.key.out + "|" + a_item.color.out + "|" + esc (a_item.reason) + "|" + a_item.created.out
		end

	note_text (a_item: SB_NOTE): STRING_8
			-- The line of a note.
		do
			Result := a_item.id.out + "|" + a_item.key.out + "|" + esc (a_item.text) + "|" + a_item.created.out + "|" + a_item.updated.out
		end

	write_notes (a_list: ARRAYED_LIST [SB_NOTE])
			-- The notes.
		do
			across a_list as ic loop
				line (note_text (ic))
			end
			line ("end")
		end

	entry_text (a_item: SB_JOURNAL_ENTRY): STRING_8
			-- The line of a journal entry.
		do
			Result := a_item.id.out + "|" + esc (a_item.title) + "|" + esc (a_item.body) + "|" + a_item.created.out + "|" + a_item.updated.out
		end

	write_cards (a_list: ARRAYED_LIST [SB_CARD])
			-- The cards.
		do
			across a_list as ic loop
				line (ic.id.out + "|" + ic.key.out + "|" + ic.key_end.out + "|" + ic.due.out + "|" + ic.interval_days.out + "|" + ic.reps.out + "|" + ic.lapses.out)
			end
			line ("end")
		end

	write_set (a_set: SB_ID_SET)
			-- The items, ascending.
		local
			l_line: STRING_8
			i: INTEGER
		do
			create l_line.make (64)
			l_line.append ("set")
			from
				i := 1
			until
				i > a_set.count
			loop
				l_line.append (" " + a_set [i].out)
				i := i + 1
			end
			line (l_line)
		end

	write_map (a_map: HASH_TABLE [INTEGER, INTEGER])
			-- The map as Java's TreeMap prints it.
		local
			l_keys: ARRAYED_LIST [INTEGER_64]
			l_sorted: SB_ID_SET
			l_line: STRING_8
			i: INTEGER
		do
			create l_keys.make (a_map.count)
			from
				a_map.start
			until
				a_map.after
			loop
				l_keys.extend (a_map.key_for_iteration)
				a_map.forth
			end
			create l_sorted.make_from_list (l_keys)
			create l_line.make (64)
			l_line.append ("{")
			from
				i := 1
			until
				i > l_sorted.count
			loop
				if i > 1 then
					l_line.append (", ")
				end
				l_line.append (l_sorted [i].out + "=" + a_map [l_sorted [i].as_integer_32].out)
				i := i + 1
			end
			l_line.append ("}")
			line (l_line)
		end

	write_integers (a_list: ARRAYED_LIST [INTEGER])
			-- The list as Java prints it.
		local
			l_line: STRING_8
			i: INTEGER
		do
			create l_line.make (64)
			l_line.append ("[")
			from
				i := 1
			until
				i > a_list.count
			loop
				if i > 1 then
					l_line.append (", ")
				end
				l_line.append (a_list [i].out)
				i := i + 1
			end
			l_line.append ("]")
			line (l_line)
		end

	write_dump
			-- The file as it stands: the pragmas, the schema, and every table.
		local
			l_sql: SB_SQL
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_columns: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_select: STRING_8
			i: INTEGER
			l_name: STRING_8
		do
			check attached user_path as al_path then
				create l_sql.make_read_only (al_path)
			end
			across <<"user_version", "encoding", "auto_vacuum", "page_size">> as ic loop
				l_rows := l_sql.rows ("PRAGMA " + ic, create {ARRAY [detachable ANY]}.make_empty)
				line ("pragma " + ic + " " + esc (l_sql.text (l_rows.first, 1)))
			end
			l_rows := l_sql.rows ("SELECT type, name, tbl_name, sql FROM sqlite_master ORDER BY rowid", create {ARRAY [detachable ANY]}.make_empty)
			across l_rows as ic loop
				if ic [4] = Void then
					line ("master " + esc (l_sql.text (ic, 1)) + "|" + esc (l_sql.text (ic, 2)) + "|" + esc (l_sql.text (ic, 3)) + "|~")
				else
					line ("master " + esc (l_sql.text (ic, 1)) + "|" + esc (l_sql.text (ic, 2)) + "|" + esc (l_sql.text (ic, 3)) + "|" + esc (l_sql.text (ic, 4)))
				end
			end
			across <<"android_metadata", "sqlite_sequence", "highlight", "note", "note_version", "history", "setting", "folder", "favorite", "journal", "journal_version", "tag", "verse_tag", "card", "prayer">> as ic loop
				l_columns := l_sql.rows ("PRAGMA table_info(" + ic + ")", create {ARRAY [detachable ANY]}.make_empty)
				create l_select.make (256)
				l_select.append ("SELECT ")
				from
					i := 1
				until
					i > l_columns.count
				loop
					if i > 1 then
						l_select.append (" || '|' || ")
					end
					l_name := l_sql.text (l_columns [i], 2).to_string_8
					l_select.append ("typeof(%"" + l_name + "%") || ':' || CASE typeof(%"" + l_name + "%") WHEN 'integer' THEN %"" + l_name + "%" ELSE hex(%"" + l_name + "%") END")
					i := i + 1
				end
				l_select.append (" FROM " + ic + " ORDER BY rowid")
				line ("table " + ic)
				across l_sql.rows (l_select, create {ARRAY [detachable ANY]}.make_empty) as jc loop
					line (l_sql.text (jc, 1).to_string_8)
				end
			end
			l_sql.close
		end

feature {NONE} -- The cases of SB_PACK_DB

	doc_text (a_doc: SB_PACK_DOC): STRING_8
			-- The line of a document.
		do
			Result := a_doc.id.out + "|" + esc (a_doc.kind) + "|" + esc (a_doc.title) + "|" + esc (a_doc.collection) + "|" + esc (a_doc.status) + "|" + esc (a_doc.path) + "|" + a_doc.words.out
		end

	pack_case (f: ARRAYED_LIST [STRING_8])
			-- One case.
		local
			l_op: STRING_8
		do
			l_op := f [1]
			if l_op.same_string ("load") then
				check attached packs as al_packs then
					if attached al_packs.load (decoded (f [2])) as al_pack then
						pack := al_pack
						line ("loaded " + esc (kotlin.file_name_of (al_pack.path)) + "|" + esc (al_pack.title))
					else
						line ("exception " + esc (al_packs.load_failure))
					end
				end
			elseif l_op.same_string ("remove") then
				check attached packs as al_packs and attached pack as al_pack then
					al_packs.remove (al_pack)
				end
				line ("removed")
			else
				check attached pack as al_pack then
					pack_query (al_pack, f)
				end
			end
		end

	pack_query (a_pack: SB_PACK_DB; f: ARRAYED_LIST [STRING_8])
			-- One case on `a_pack'.
		local
			l_op: STRING_8
			l_keys: ARRAYED_LIST [STRING_8]
		do
			l_op := f [1]
			if l_op.same_string ("title") then
				line (esc (a_pack.title))
			elseif l_op.same_string ("meta") then
				create l_keys.make (a_pack.meta.count)
				l_keys.compare_objects
				from
					a_pack.meta.start
				until
					a_pack.meta.after
				loop
					l_keys.extend (a_pack.meta.key_for_iteration)
					a_pack.meta.forth
				end
				from
				until
					l_keys.is_empty
				loop
					if attached a_pack.meta [smallest (l_keys)] as al_value then
						line (esc (smallest (l_keys).to_string_32) + "=" + esc (al_value))
					end
					l_keys.start
					l_keys.prune (smallest (l_keys))
				end
			elseif l_op.same_string ("kinds") then
				across a_pack.kinds as ic loop
					line (esc (ic.kind) + "|" + ic.n.out)
				end
				line ("end")
			elseif l_op.same_string ("docs") then
				across a_pack.docs (decoded (f [2])) as ic loop
					line (doc_text (ic))
				end
				line ("end")
			elseif l_op.same_string ("doc") then
				if attached a_pack.doc (f [2].to_integer_64) as al_doc then
					line (doc_text (al_doc))
				else
					line ("none")
				end
			elseif l_op.same_string ("body") then
				line (hash_text (Fnv_start, a_pack.body (f [2].to_integer_64)).out)
			elseif l_op.same_string ("forverse") then
				write_hits (a_pack.for_verse (f [2].to_integer))
			elseif l_op.same_string ("search") then
				write_hits (a_pack.search_limited (decoded (f [2]), f [3].to_integer))
			elseif l_op.same_string ("refs") then
				across a_pack.refs_of (f [2].to_integer_64) as ic loop
					line (ic.book.out + ":" + ic.chapter.out + ":" + ic.verse.out)
				end
				line ("end")
			else
				line ("unknown operation")
			end
		end

	smallest (a_keys: ARRAYED_LIST [STRING_8]): STRING_8
			-- The first of `a_keys' in sorted order.
		do
			Result := a_keys.first
			across a_keys as ic loop
				if ic < Result then
					Result := ic
				end
			end
		end

	write_hits (a_hits: ARRAYED_LIST [SB_PACK_HIT])
			-- The hits.
		do
			across a_hits as ic loop
				line (doc_text (ic.doc) + "|" + esc (ic.excerpt))
			end
			line ("end")
		end

feature {NONE} -- The text rules

	text_case (a_text: STRING_32)
			-- The rules on `a_text'.
		do
			line (esc (kotlin.trimmed (a_text)) + "|" + flag (kotlin.is_blank (a_text)) + "|" + esc (kotlin.lowercase (a_text)) + "|" + esc (kotlin.icu_lowercase (a_text)) + "|" + esc (kotlin.case_folded (a_text)))
		end

feature {NONE} -- Text

	flag (a_value: BOOLEAN): STRING_8
			-- `a_value' as Java writes it.
		do
			if a_value then
				Result := "true"
			else
				Result := "false"
			end
		end

	esc (a_text: READABLE_STRING_GENERAL): STRING_8
			-- `a_text' in printable ASCII, as DataOracle.esc writes it.
		local
			i: INTEGER
			l_code: NATURAL_32
		do
			create Result.make (a_text.count + 8)
			from
				i := 1
			until
				i > a_text.count
			loop
				l_code := a_text.code (i)
				if l_code >= 0x20 and l_code <= 0x7E and l_code /= 0x5C and l_code /= 0x7C then
					Result.append_code (l_code)
				else
					Result.append ("\u{")
					Result.append (hex (l_code))
					Result.append ("}")
				end
				i := i + 1
			end
		end

	hex (a_code: NATURAL_32): STRING_8
			-- `a_code' in lowercase hexadecimal, without leading zeros.
		do
			Result := a_code.to_hex_string.as_lower
			Result.prune_all_leading ('0')
			if Result.is_empty then
				Result := "0"
			end
		end

	optional (a_field: STRING_8): detachable STRING_32
			-- The text of a field, Void for ~.
		do
			if not a_field.same_string ("~") then
				Result := decoded (a_field)
			end
		end

	decoded (a_field: STRING_8): STRING_32
			-- The text of a field of hexadecimal code points.
		local
			i: INTEGER
			l_value: NATURAL_32
			l_digits: BOOLEAN
			c: CHARACTER_8
		do
			create Result.make (a_field.count // 3)
			from
				i := 1
			until
				i > a_field.count + 1
			loop
				if i <= a_field.count then
					c := a_field [i]
				else
					c := ' '
				end
				if c.is_hexa_digit then
					if c.is_digit then
						l_value := l_value * 16 + (c.code - 48).to_natural_32
					else
						l_value := l_value * 16 + (c.as_lower.code - 87).to_natural_32
					end
					l_digits := True
				elseif l_digits then
					Result.append_code (l_value)
					l_value := 0
					l_digits := False
				end
				i := i + 1
			end
		end

	float_hex (a_value: REAL_32): STRING_8
			-- The bits of `a_value' as Java's Integer.toHexString writes them.
		do
			Result := hex (float_bits (a_value))
		end

	float_bits (a_value: REAL_32): NATURAL_32
			-- The bits of `a_value'.
		local
			l_cell: MANAGED_POINTER
		do
			create l_cell.make (4)
			l_cell.put_real_32 (a_value, 0)
			Result := l_cell.read_natural_32 (0)
		end

	ring_text (a_ring: ARRAY [REAL_32]): STRING_8
			-- The size and hash of a ring.
		local
			l_hash: NATURAL_64
			i: INTEGER
		do
			l_hash := Fnv_start
			from
				i := a_ring.lower
			until
				i > a_ring.upper
			loop
				l_hash := hash_integer (l_hash, float_bits (a_ring [i]))
				i := i + 1
			end
			Result := a_ring.count.out + " " + l_hash.out
		end

	Fnv_start: NATURAL_64 = 0xCBF29CE484222325
			-- The start of an FNV-1a hash.

	hash_integer (a_hash: NATURAL_64; a_value: NATURAL_32): NATURAL_64
			-- `a_hash' with `a_value' added.
		do
			Result := a_hash.bit_xor (a_value.to_natural_64) * 0x100000001B3
		end

	hash_text (a_hash: NATURAL_64; a_text: READABLE_STRING_32): NATURAL_64
			-- `a_hash' with each code of `a_text' added, then a line end.
		local
			i: INTEGER
		do
			Result := a_hash
			from
				i := 1
			until
				i > a_text.count
			loop
				Result := hash_integer (Result, a_text.code (i))
				i := i + 1
			end
			Result := hash_integer (Result, 10)
		end

end
