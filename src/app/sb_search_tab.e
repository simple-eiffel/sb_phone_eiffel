note
	description: "The Search tab, as SearchScreen.kt has it: a query field, the version chips, and the results or the help."
	author: "Larry Rix"

class
	SB_SEARCH_TAB

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL)
		do
			shell := a_shell
			state := a_shell.state
			theme := a_shell.theme
			ui := a_shell.ui
			controls := a_shell.controls
			create body.make (controls)
			create chips.make (controls)
			create results.make (controls)
			create field.make (controls, {STRING_32} "Search", theme.primary, theme.outline, theme.on_surface_variant, theme.on_background)
			create submitted.make_from_string (state.search_text)
			create field_room.make (controls)
			field_room.set_padding_each (16, 12, 16, 0)
			field.set_placeholder ({STRING_32} "love %"one another%"  %/183/  %/956/%/953/%/956/*  %/183/  H7225")
			field.set_keyboard_action (field.Action_search)
			field.set_text (state.search_text)
			field.set_on_change (agent typed)
			field.set_on_action (agent submit)
			field_room.extend (field)
			body.extend (field_room)
			chips.set_padding (16, 0)
			chips.set_least_height (48)
			chips.call_integer ("setGravity", 16)
			body.extend (chips)
			body.extend_growing (results, 1)
			show
		end

feature -- Access

	body: PHONE_COLUMN

feature -- Refreshing

	refresh
			-- The reading version may have changed: only then is there anything to do again.
		do
			if not state.version.same_string (shown_version) then
				show
			end
		end

feature {NONE} -- Input

	typed
		do
			state.set_search_text (field.text)
		end

	submit
		do
			submitted := state.search_text.twin
			field.leave
			show
		end

	chip_tapped (a_all: BOOLEAN)
		do
			state.set_search_all_versions (a_all)
			submitted := state.search_text.twin
			show
		end

feature {NONE} -- Showing

	show
		local
			l_gap: PHONE_LABEL
		do
			shown_version := state.version.twin
			generation := generation + 1
			pending.wipe_out
			chips.clear
			chips.extend (ui.filter_chip (state.version, not state.search_all_versions, agent chip_tapped (False)))
			create l_gap.make (controls, {STRING_32} "  ")
			chips.extend (l_gap)
			chips.extend (ui.filter_chip ({STRING_32} "All versions", state.search_all_versions, agent chip_tapped (True)))
			results.clear
			if (create {SB_KOTLIN_TEXT}.make).is_blank (submitted) then
				show_help
			else
				run
			end
		end

	run
		local
			l_refs: ARRAYED_LIST [SB_REF]
			l_parse: SB_QUERY_PARSE
			l_none: SB_SEARCH_RESULT
			l_lemmas: ARRAYED_LIST [SB_LEMMA]
			l_result: SB_SEARCH_RESULT
		do
			create l_refs.make (2)
			if attached {SB_REF_PARSE_ONE} (create {SB_REF_PARSER}.make).parse (submitted) as al_one then
				l_refs.extend (al_one.ref)
			elseif attached {SB_REF_PARSE_CHOICE} (create {SB_REF_PARSER}.make).parse (submitted) as al_choice then
				l_refs.append (al_choice.refs)
			end
			create l_none.make (0, create {ARRAYED_LIST [SB_VERSE]}.make (0), create {ARRAYED_LIST [SB_MATCH]}.make (0))
			l_parse := (create {SB_QUERY_PARSER}.make).parse (submitted)
			if attached {SB_QUERY_PARSE_STRONGS} l_parse as al_strongs then
				l_lemmas := state.bible.lemmas_by_strongs (al_strongs.number)
				if l_lemmas.is_empty then
					show_problem ({STRING_32} "No word carries Strong's " + al_strongs.number + {STRING_32} ".", {STRING_32} "", -1)
				else
					show_found (l_none, l_refs, l_lemmas, Void, Void)
				end
			elseif attached {SB_QUERY_PARSE_ERROR} l_parse as al_error then
				if not l_refs.is_empty then
					create l_lemmas.make (0)
					show_found (l_none, l_refs, l_lemmas, Void, Void)
				else
					show_problem (al_error.message, submitted, al_error.position)
				end
			elseif attached {SB_QUERY_PARSE_TEXT} l_parse as al_text then
				l_result := state.bible.search (al_text.query, if state.search_all_versions and not al_text.query.has_word_terms then Void else state.version end)
				create l_lemmas.make (0)
				if attached {SB_TEXT_NODE} al_text.query.root as al_node and then al_node.match.words.count = 1 then
					single_word (l_result, l_refs, al_node.match)
				else
					show_found (l_result, l_refs, l_lemmas, Void, Void)
				end
			end
		end

	single_word (a_result: SB_SEARCH_RESULT; a_refs: ARRAYED_LIST [SB_REF]; a_match: SB_MATCH)
			-- One word: also the original words like it, and the English entry for it.
		local
			l_word: STRING_32
			l_lemmas: ARRAYED_LIST [SB_LEMMA]
			l_entry: detachable SB_ENGLISH_ENTRY
		do
			l_word := a_match.words.first
			l_lemmas := state.bible.lemmas_matching (l_word, l_word.as_lower)
			if not a_match.is_prefix and then is_plain_english (l_word) then
				l_entry := state.bible.english_entry (l_word)
				if l_entry.behind.is_empty and l_entry.senses.is_empty then
					l_entry := Void
				end
			end
			show_found (a_result, a_refs, l_lemmas, l_entry, a_match)
		end

	is_plain_english (a_word: STRING_32): BOOLEAN
		do
			Result := across a_word as ic all ic >= 'a' and ic <= 'z' end
		end

	show_problem (a_message, a_query: READABLE_STRING_32; a_position: INTEGER)
		local
			l_box: PHONE_COLUMN
			l_row: PHONE_RICH_ROW
			l_marker: STRING_32
		do
			l_box := ui.column
			l_box.set_padding (20, 20)
			l_box.extend (ui.label (a_message, theme.Body_large, theme.error))
			if a_position >= 0 and not a_query.is_empty then
				create l_row.make (0, 0, 0)
				theme.add_style_in (l_row, theme.Body_large, theme.Mono, theme.on_background)
				l_row.add_text (a_query)
				l_box.extend (top_gap (ui.rich (l_row)))
				create l_marker.make_filled (' ', a_position.min (a_query.count))
				l_marker.append_character ('^')
				create l_row.make (0, 0, 0)
				theme.add_style_in (l_row, theme.Body_large, theme.Mono, theme.error)
				l_row.add_text (l_marker)
				l_box.extend (ui.rich (l_row))
			end
			results.extend (l_box)
		end

	top_gap (a_label: PHONE_LABEL): PHONE_LABEL
		do
			a_label.set_padding_each (0, 12, 0, 0)
			Result := a_label
		end

	label_line (a_text: READABLE_STRING_32): PHONE_LABEL
		do
			Result := ui.padded (a_text, theme.Title_small, theme.secondary, 20, 12, 0, 4)
		end

	show_found (a_result: SB_SEARCH_RESULT; a_refs: ARRAYED_LIST [SB_REF]; a_lemmas: ARRAYED_LIST [SB_LEMMA]; a_english: detachable SB_ENGLISH_ENTRY; a_single: detachable SB_MATCH)
		local
			l_page, l_box: PHONE_COLUMN
			l_label: PHONE_LABEL
		do
			l_page := ui.column
			if not a_refs.is_empty then
				l_box := ui.column
				l_box.set_padding (20, 8)
				across a_refs as ic loop
					l_label := ui.label ({STRING_32} "Go to " + ic.label + {STRING_32} "  %/8594/", theme.Title_medium, theme.primary)
					l_label.set_padding (0, 6)
					l_label.set_on_tap (agent shell.go_to (ic))
					l_box.extend (l_label)
				end
				l_page.extend (l_box)
				l_page.extend (ui.divider)
			end
			if attached a_english as al_english then
				add_english (l_page, al_english)
			end
			if not a_lemmas.is_empty then
				l_page.extend (label_line ({STRING_32} "Original words"))
				across a_lemmas as ic loop
					pending.extend (agent add_lemma (l_page, ic))
				end
				pending.extend (agent add_divider (l_page))
			end
			if not a_result.matches.is_empty or a_result.by_verse then
				add_verses (l_page, a_result)
			end
			results.extend_growing (ui.scroller (l_page), 1)
			add_rows (generation, First_rows)
		end

	add_rows (a_generation, a_count: INTEGER)
			-- Add up to `a_count' more rows of the results of `a_generation', and come back for the
			-- rest. A list of hundreds, made at once, would hold up the screen; Compose's makes
			-- only what shows, and this lets the first rows appear at once.
		local
			i: INTEGER
		do
			if a_generation = generation then
				from i := 1 until i > a_count or pending.is_empty loop
					pending.first.call ([])
					pending.start
					pending.remove
					i := i + 1
				end
				if not pending.is_empty then
					shell.services.after (Row_pause, agent add_rows (a_generation, Later_rows))
				end
			end
		end

	add_lemma (a_page: PHONE_COLUMN; a_lemma: SB_LEMMA)
		do
			a_page.extend (shell.lemma_row (a_lemma, a_lemma.number + {STRING_32} "  %/183/  " + a_lemma.count.out.to_string_32 + {STRING_32} "%/215/"))
		end

	add_divider (a_page: PHONE_COLUMN)
		do
			a_page.extend (ui.divider)
		end

	add_verse_header (a_page: PHONE_COLUMN; a_line: STRING_32; a_result: SB_SEARCH_RESULT)
		local
			l_top: PHONE_ROW
		do
			l_top := ui.row
			l_top.extend_growing (label_line (a_line), 1)
			if not a_result.verses.is_empty then
				l_top.extend (shell.speak_button ("search:" + (create {UTF_CONVERTER}).utf_32_string_to_utf_8_string_8 (state.search_text), {STRING_32} "Search: " + state.search_text,
					agent search_speech (a_result)))
			end
			a_page.extend (l_top)
		end

	add_english (a_page: PHONE_COLUMN; a_entry: SB_ENGLISH_ENTRY)
		local
			l_box: PHONE_COLUMN
			l_text: STRING_32
			i: INTEGER
		do
			l_box := ui.tappable_column (agent shell.open_english (a_entry.lemma), 20, 10)
			l_box.extend (ui.label ({STRING_32} "%/8220/" + a_entry.lemma + {STRING_32} "%/8221/ in the KJV  %/8594/", theme.Title_medium, theme.primary))
			if a_entry.behind.is_empty then
				l_text := {STRING_32} "What it meant then and means now"
			else
				l_text := {STRING_32} "Translates " + a_entry.behind.count.out.to_string_32 + {STRING_32} " Hebrew and Greek word"
				if a_entry.behind.count /= 1 then
					l_text.append_character ('s')
				end
				l_text.append ({STRING_32} ": ")
				from i := 1 until i > 4 or i > a_entry.behind.count loop
					if i > 1 then
						l_text.append ({STRING_32} ", ")
					end
					l_text.append (a_entry.behind [i].lemma.translit + {STRING_32} " (" + a_entry.behind [i].n.out.to_string_32 + {STRING_32} ")")
					i := i + 1
				end
				if a_entry.behind.count > 4 then
					l_text.append ({STRING_32} ", %/8230/")
				end
			end
			l_box.extend (ui.limited (ui.label (l_text, theme.Body_medium, theme.on_background), 2))
			a_page.extend (l_box)
			a_page.extend (ui.divider)
		end

	add_verses (a_page: PHONE_COLUMN; a_result: SB_SEARCH_RESULT)
		local
			l_shown_in, l_line: STRING_32
			l_first: INTEGER
			l_keys: ARRAYED_LIST [INTEGER]
		do
			l_shown_in := {STRING_32} ""
			if a_result.by_verse then
				l_shown_in := {STRING_32} "  %/183/  shown in " + if a_result.verses.is_empty then state.version else a_result.verses.first.version end
				create l_keys.make (a_result.verses.count)
				across a_result.verses as ic loop
					if not l_keys.has (ic.eng_key) then
						l_keys.extend (ic.eng_key)
					end
				end
				l_first := l_keys.count
			else
				l_first := a_result.verses.count
			end
			if a_result.total = 0 then
				l_line := {STRING_32} "No verses found"
			elseif l_first < a_result.total then
				l_line := a_result.total.out.to_string_32 + {STRING_32} " verses (first " + l_first.out.to_string_32 + {STRING_32} " shown)" + l_shown_in
			else
				l_line := a_result.total.out.to_string_32 + {STRING_32} " verses" + l_shown_in
			end
			pending.extend (agent add_verse_header (a_page, l_line, a_result))
			across a_result.verses as ic loop
				pending.extend (agent add_verse (a_page, ic, a_result))
			end
		end

	search_speech (a_result: SB_SEARCH_RESULT): SB_BATCH
		do
			Result := (create {SB_SPOKEN}.make (state)).search_batch (a_result, state.search_text)
		end

	add_verse (a_page: PHONE_COLUMN; a_verse: SB_VERSE; a_result: SB_SEARCH_RESULT)
		local
			l_box: PHONE_COLUMN
			l_eng: SB_REF
			l_head, l_text: STRING_32
			l_version: SB_VERSION
			l_row: PHONE_RICH_ROW
		do
			create l_eng.make_from_key (a_verse.eng_key)
			l_version := state.bible.version (a_verse.version)
			l_box := ui.tappable_column (agent shell.go_to (l_eng), 20, 8)
			l_head := l_eng.short_label.twin
			if a_verse.differs_from_english then
				l_head.append ({STRING_32} "  [" + a_verse.chapter.out.to_string_32 + {STRING_32} ":" + a_verse.verse.out.to_string_32 + {STRING_32} "]")
			end
			l_head.append ({STRING_32} "  %/183/  " + a_verse.version)
			l_box.extend (ui.label (l_head, theme.Label_large, theme.primary))
			l_text := if l_version.rtl then state.hebrew (a_verse.text) else a_verse.text end
			create l_row.make (0, 0, 0)
			state.add_reading_block (l_row, theme, l_version, state.base_size * 0.9, 0)
			add_marked (l_row, l_text, a_result.matches)
			l_box.extend (ui.rich (l_row))
			if attached a_result.word_hits.item (a_verse.eng_key) as al_hits then
				add_hits (l_box, a_verse, al_hits)
			end
			a_page.extend (l_box)
			a_page.extend (ui.divider)
		end

	add_hits (a_box: PHONE_COLUMN; a_verse: SB_VERSE; a_hits: ARRAYED_LIST [STRING_32])
		local
			l_row: PHONE_RICH_ROW
			l_text: STRING_32
			l_label: PHONE_LABEL
		do
			l_text := {STRING_32} "Matched: "
			across a_hits as ic loop
				if @ic.cursor_index > 1 then
					l_text.append ({STRING_32} "  ")
				end
				l_text.append (state.hebrew (ic))
			end
			create l_row.make (0, 0, 0)
			theme.add_style_in (l_row, theme.Body_medium, if a_verse.book <= 39 then theme.Hebrew else theme.Plain end, theme.secondary)
			l_row.add_text (l_text)
			l_label := ui.rich (l_row)
			l_label.set_padding_each (0, 2, 0, 0)
			a_box.extend (l_label)
		end

	add_marked (a_row: PHONE_RICH_ROW; a_text: STRING_32; a_matches: ARRAYED_LIST [SB_MATCH])
			-- `a_text' with the words a match found in bold: marked.
		local
			l_exact, l_prefixes: ARRAYED_LIST [STRING_32]
			i, l_start, l_last: INTEGER
			l_word, l_folded: STRING_32
			l_hit: BOOLEAN
		do
			create l_exact.make (4)
			l_exact.compare_objects
			create l_prefixes.make (2)
			across a_matches as ic loop
				across ic.words as jc loop
					if ic.is_prefix and @jc.is_last then
						l_prefixes.extend (jc)
					else
						l_exact.extend (jc)
					end
				end
			end
			l_last := 1
			from i := 1 until i > a_text.count loop
				if is_word_character (a_text [i]) then
					l_start := i
					from until i > a_text.count or else not is_word_character (a_text [i]) loop
						i := i + 1
					end
					l_word := a_text.substring (l_start, i - 1)
					l_folded := fold.fold (l_word)
					l_hit := l_exact.has (l_folded) or else across l_prefixes as ic some l_folded.starts_with (ic) end
					if l_hit then
						if l_start > l_last then
							a_row.add_text (a_text.substring (l_last, l_start - 1))
						end
						a_row.add_run (l_word, a_row.Bold, theme.primary, 0.0)
						l_last := i
					end
				else
					i := i + 1
				end
			end
			if l_last <= a_text.count then
				a_row.add_text (a_text.substring (l_last, a_text.count))
			end
		end

	is_word_character (a_character: CHARACTER_32): BOOLEAN
			-- [\p{L}\p{M}\p{N}'’]
		local
			l_category: STRING_8
		do
			if a_character = '%'' or a_character = '%/8217/' then
				Result := True
			else
				l_category := unicode.general_category (a_character.natural_32_code)
				Result := l_category [1] = 'L' or l_category [1] = 'M' or l_category [1] = 'N'
			end
		end

	show_help
		local
			l_box: PHONE_COLUMN
			l_row: PHONE_ROW
			l_lines: ARRAY [TUPLE [example, meaning: STRING_32]]
		do
			l_box := ui.column
			l_box.set_padding (20, 20)
			l_box.extend (ui.label ({STRING_32} "How to search", theme.Title_medium, theme.on_background))
			l_lines := <<
				[{STRING_32} "grace peace", {STRING_32} "verses with both words"],
				[{STRING_32} "%"living water%"", {STRING_32} "an exact phrase"],
				[{STRING_32} "believ*", {STRING_32} "words that begin with it"],
				[{STRING_32} "faith OR hope", {STRING_32} "either word"],
				[{STRING_32} "love -hate", {STRING_32} "leave out verses with a word (also NOT)"],
				[{STRING_32} "(faith OR hope) love", {STRING_32} "group with parentheses"],
				[{STRING_32} "H1254 heaven", {STRING_32} "Strong's number and English together"],
				[{STRING_32} "lemma:logos  %/183/  lemma:%/1489/%/1512/%/1488/", {STRING_32} "every form of an original word"],
				[{STRING_32} "morph:Vqp3ms", {STRING_32} "Hebrew grammar code (qal perfect 3rd masc. sing.)"],
				[{STRING_32} "morph:V-AAI-3S  %/183/  morph:V-AA*", {STRING_32} "Greek grammar code; * for any ending"],
				[{STRING_32} "%/1489/%/1512/%/1488/  %/183/  %/955/%/959/%/947/%/959/%/962/", {STRING_32} "Hebrew and Greek, with or without points and accents"],
				[{STRING_32} "bara  %/183/  logos", {STRING_32} "an original word by its sound"],
				[{STRING_32} "grace", {STRING_32} "also: the Hebrew and Greek the KJV translates as %"grace%", and what it meant then"],
				[{STRING_32} "H1254  %/183/  G3056", {STRING_32} "a Strong's number"],
				[{STRING_32} "jn 3 16", {STRING_32} "go to a reference"]
			>>
			across l_lines as ic loop
				l_row := ui.top_row
				l_row.set_padding_each (0, 8, 0, 0)
				l_row.extend_growing (ui.semi_bold (ic.example, theme.Body_medium, theme.on_background), 45)
				l_row.extend_growing (ui.label (ic.meaning, theme.Body_medium, theme.on_background), 55)
				l_box.extend (l_row)
			end
			results.extend_growing (ui.scroller (l_box), 1)
		end

feature {NONE} -- Implementation

	shell: SB_SHELL

	state: SB_STATE

	theme: SB_THEME

	ui: SB_UI

	controls: PHONE_CONTROLS

	field: PHONE_FIELD

	field_room, results: PHONE_COLUMN

	chips: PHONE_ROW

	submitted: STRING_32

	pending: ARRAYED_LIST [PROCEDURE [TUPLE]]
			-- The rows still to add.
		attribute
			create Result.make (64)
		end

	generation: INTEGER
			-- Which set of results is showing.

	First_rows: INTEGER = 14

	Later_rows: INTEGER = 10

	Row_pause: INTEGER = 40

	shown_version: STRING_32
			-- The reading version when the results were made.
		attribute
			create Result.make_empty
		end

	fold: SB_FOLD
		once
			create Result.make
		end

	unicode: SB_UNICODE
		once
			create Result.make
		end

end
