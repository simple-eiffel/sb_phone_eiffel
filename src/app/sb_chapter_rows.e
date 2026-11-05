note
	description: "[
		One chapter as list rows, built as ChapterPage in ReaderScreen.kt builds them: the
		title, then a row per English-numbered verse with a block per version shown, then
		the source's credit. A chapter a version does not have gives one row saying so.
	]"
	author: "Larry Rix"

class
	SB_CHAPTER_ROWS

create
	make

feature {NONE} -- Initialization

	make (a_state: SB_STATE; a_theme: SB_THEME; a_book, a_chapter: INTEGER)
		do
			state := a_state
			theme := a_theme
			book := a_book
			chapter := a_chapter
			create rows.make (64)
			create keys.make (64)
			create kjv_blocks.make (64)
			create kjv_texts.make (64)
			create prefixes.make (64)
			highlights := a_state.user.highlight_map
			stars := a_state.user.starred_keys
			notes := a_state.user.noted_keys
			build
		ensure
			matched: rows.count = keys.count
		end

feature -- Access

	rows: ARRAYED_LIST [STRING_32]

	keys: ARRAYED_LIST [INTEGER]
			-- The verse key of each row; 0 for one that is not a verse.

	kjv_blocks: ARRAYED_LIST [INTEGER]
			-- The block of each row holding a single KJV verse, or 0.

	kjv_texts: ARRAYED_LIST [READABLE_STRING_32]
			-- That verse's text.

	prefixes: ARRAYED_LIST [INTEGER]
			-- How many characters come before it in the block.

feature {NONE} -- Building

	build
		local
			l_versions: ARRAYED_LIST [STRING_32]
			l_tables: ARRAYED_LIST [HASH_TABLE [ARRAYED_LIST [SB_VERSE], INTEGER]]
			l_sorted: SORTED_TWO_WAY_LIST [INTEGER]
		do
			l_versions := state.shown_versions
			create l_tables.make (l_versions.count)
			create l_sorted.make
			across l_versions as ic loop
				l_tables.extend (by_key (ic, l_sorted))
			end
			if l_sorted.is_empty then
				add_missing
			else
				add_title
				across l_sorted as ic loop
					add_verse (ic, l_versions, l_tables)
				end
				add_credit
			end
		end

	by_key (a_version: READABLE_STRING_32; a_keys: SORTED_TWO_WAY_LIST [INTEGER]): HASH_TABLE [ARRAYED_LIST [SB_VERSE], INTEGER]
			-- The chapter in `a_version', its rows gathered by English key.
		local
			l_list: ARRAYED_LIST [SB_VERSE]
		do
			create Result.make (64)
			across state.bible.verses_in_chapter (a_version, book, chapter) as ic loop
				if attached Result.item (ic.eng_key) as al_list then
					al_list.extend (ic)
				else
					create l_list.make (1)
					l_list.extend (ic)
					Result.put (l_list, ic.eng_key)
					if not a_keys.has (ic.eng_key) then
						a_keys.extend (ic.eng_key)
					end
				end
			end
		end

	add_title
		local
			l_row: PHONE_RICH_ROW
			l_text: STRING_32
		do
			create l_row.make_padded (0, 20, 16, 8)
			theme.add_style (l_row, theme.Headline_small, theme.primary)
			l_text := state.bible.book (book).name + {STRING_32} " " + chapter.out.to_string_32
			if state.user.starred_chapters.has ((create {SB_REF}.make (book, chapter, 0, 0)).key) then
				l_text.append ({STRING_32} "  %/9733/")
			end
			l_row.add_text (l_text)
			add_plain_row (l_row)
		end

	add_plain_row (a_row: PHONE_RICH_ROW)
			-- `a_row', which is no verse.
		do
			rows.extend (a_row.wire)
			keys.extend (0)
			kjv_blocks.extend (0)
			kjv_texts.extend ({STRING_32} "")
			prefixes.extend (0)
		end

	add_missing
		local
			l_row: PHONE_RICH_ROW
			l_version: SB_VERSION
		do
			l_version := state.bible.version (state.version)
			create l_row.make (0, 32, 32)
			theme.add_style (l_row, theme.Body_medium, theme.on_surface_variant)
			l_row.center_block
			l_row.add_text (l_version.code + {STRING_32} " (" + l_version.name + {STRING_32} ") has " + l_version.coverage + {STRING_32} " only, so "
				+ state.bible.book (book).name + {STRING_32} " " + chapter.out.to_string_32 + {STRING_32} " is not in it. Choose another version from "
				+ l_version.code + {STRING_32} " %/9662/ above.")
			add_plain_row (l_row)
		end

	add_verse (a_key: INTEGER; a_versions: ARRAYED_LIST [STRING_32]; a_tables: ARRAYED_LIST [HASH_TABLE [ARRAYED_LIST [SB_VERSE], INTEGER]])
		local
			l_row: PHONE_RICH_ROW
			l_verses: detachable ARRAYED_LIST [SB_VERSE]
			i, l_block, l_kjv_block, l_prefix: INTEGER
			l_kjv_text: READABLE_STRING_32
		do
			l_kjv_text := {STRING_32} ""
			create l_row.make (wash (a_key), 20, 6)
			from i := 1 until i > a_versions.count loop
				l_verses := a_tables [i].item (a_key)
				if i = 1 or l_verses /= Void then
					add_block (l_row, a_key, i, state.bible.version (a_versions [i]), l_verses)
					l_block := l_block + 1
					if a_versions [i].same_string ({STRING_32} "KJV") and then attached l_verses as al_verses and then al_verses.count = 1 and then not al_verses.first.text.is_empty then
						l_kjv_block := l_block
						l_kjv_text := al_verses.first.text
						l_prefix := if i = 1 then (a_key \\ 1000).out.count + 1 else 5 end
					end
				end
				i := i + 1
			end
			rows.extend (l_row.wire)
			keys.extend (a_key)
			kjv_blocks.extend (l_kjv_block)
			kjv_texts.extend (l_kjv_text)
			prefixes.extend (l_prefix)
		end

	add_block (a_row: PHONE_RICH_ROW; a_key, a_index: INTEGER; a_version: SB_VERSION; a_verses: detachable ARRAYED_LIST [SB_VERSE])
		local
			l_base, l_size: REAL_64
			l_first: BOOLEAN
		do
			l_base := state.base_size
			l_size := if a_version.rtl then l_base * 1.3 else l_base end
			if a_version.rtl then
				a_row.add_block (theme.Hebrew, l_size, l_base * 2.0, theme.on_background, True, if a_index > 1 then 4 else 0 end)
			else
				a_row.add_block (theme.Serif, l_size, l_base * 1.5, theme.on_background, False, if a_index > 1 then 4 else 0 end)
			end
			if a_index = 1 then
				a_row.add_run ((a_key \\ 1000).out.to_string_32 + {STRING_32} " ", a_row.Bold + a_row.Superscript, theme.primary, l_base * 0.65 / l_size)
			else
				a_row.add_run (a_version.code + {STRING_32} "  ", a_row.Bold, theme.secondary, l_base * 0.6 / l_size)
			end
			if a_verses = Void then
				a_row.add_run ({STRING_32} "(not in this version)", 0, theme.on_surface_variant, 0.0)
			else
				l_first := True
				across a_verses as ic loop
					if not l_first then
						a_row.add_text ({STRING_32} " ")
					end
					l_first := False
					if ic.differs_from_english or a_verses.count > 1 then
						a_row.add_run ({STRING_32} "[" + ic.own_label + {STRING_32} "] ", 0, theme.on_surface_variant, l_base * 0.6 / l_size)
					end
					if ic.text.is_empty then
						a_row.add_run ({STRING_32} "(omitted in this edition)", 0, theme.on_surface_variant, 0.0)
					elseif a_version.rtl then
						a_row.add_text (state.hebrew (ic.text))
					else
						a_row.add_text (ic.text)
					end
				end
			end
			if a_index = 1 then
				if stars.has (a_key) then
					a_row.add_run ({STRING_32} "  %/9733/", 0, theme.primary, 0.0)
				end
				if notes.has (a_key) then
					a_row.add_run ({STRING_32} "  %/9998/", 0, theme.secondary, 0.0)
				end
			end
		end

	add_credit
		local
			l_row: PHONE_RICH_ROW
		do
			if attached state.bible.source (state.version) as al_source then
				create l_row.make_padded (0, 20, 24, 32)
				theme.add_style (l_row, theme.Body_small, theme.on_surface_variant)
				l_row.add_text (al_source.credit)
				add_plain_row (l_row)
			end
		end

	wash (a_key: INTEGER): NATURAL_32
		do
			if state.flash_key = a_key then
				Result := theme.with_alpha (theme.primary, 64)
			elseif state.read_key = a_key then
				Result := theme.with_alpha (theme.primary, 36)
			elseif highlights.has (a_key) then
				Result := theme.highlight (highlights.item (a_key))
			end
		end

feature {NONE} -- Implementation

	state: SB_STATE

	theme: SB_THEME

	book, chapter: INTEGER

	highlights: like {SB_USER_DB}.highlight_map

	stars: like {SB_USER_DB}.starred_keys

	notes: like {SB_USER_DB}.noted_keys

end
