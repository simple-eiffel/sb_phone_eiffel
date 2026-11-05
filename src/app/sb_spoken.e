note
	description: "[
		How things are said, and what each screen reads aloud: the spoken forms in ReadAloud.kt,
		and the speech builders beside each screen in the Kotlin. It also holds the small
		groupings of dictionary data that a screen and its speech must make the same way.
	]"
	author: "Larry Rix"

class
	SB_SPOKEN

create
	make

feature {NONE} -- Initialization

	make (a_state: SB_STATE)
		do
			state := a_state
		end

feature -- Dictionary groupings

	hebrew_order: ARRAY [STRING_32]
		do
			Result := <<{STRING_32} "BDB1906", {STRING_32} "SDBH", {STRING_32} "TBESH">>
		end

	greek_order: ARRAY [STRING_32]
		do
			Result := <<{STRING_32} "AS1922", {STRING_32} "SDGNT", {STRING_32} "ML1889", {STRING_32} "LSJ">>
		end

	senses_by_source (a_senses: ARRAYED_LIST [SB_SENSE]; a_order: ARRAY [STRING_32]): ARRAYED_LIST [TUPLE [source: STRING_32; list: ARRAYED_LIST [SB_SENSE]]]
			-- `a_senses' by source, the sources in `a_order' and the others after, as they came.
		local
			l_groups: like senses_by_source
			l_list: detachable ARRAYED_LIST [SB_SENSE]
			i: INTEGER
		do
			create l_groups.make (4)
			across a_senses as ic loop
				l_list := Void
				across l_groups as jc until l_list /= Void loop
					if jc.source.same_string (ic.source) then
						l_list := jc.list
					end
				end
				if l_list = Void then
					create l_list.make (8)
					l_groups.extend ([ic.source, l_list])
				end
				l_list.extend (ic)
			end
			create Result.make (l_groups.count)
			from i := a_order.lower until i > a_order.upper loop
				across l_groups as jc loop
					if jc.source.same_string (a_order [i]) then
						Result.extend (jc)
					end
				end
				i := i + 1
			end
			across l_groups as jc loop
				if not across a_order as kc some kc.same_string (jc.source) end then
					Result.extend (jc)
				end
			end
		end

	sense_head (a_sense: SB_SENSE): STRING_32
			-- The label and gloss that are not blank.
		do
			create Result.make (32)
			if not text.is_blank (a_sense.label) then
				Result.append (a_sense.label)
			end
			if not text.is_blank (a_sense.gloss) then
				if not Result.is_empty then
					Result.append ({STRING_32} "  ")
				end
				Result.append (a_sense.gloss)
			end
		end

	sense_repeats (a_sense: SB_SENSE): BOOLEAN
			-- Does the full text only repeat the gloss? Some lexicons give both, differing by a final period.
		do
			Result := without_ending (a_sense.text, {STRING_32} ".;,").same_string (without_ending (a_sense.gloss, {STRING_32} ".;,"))
				or else without_ending (a_sense.text, {STRING_32} ".").same_string (without_ending (sense_head (a_sense), {STRING_32} "."))
		end

	then_senses (a_entry: SB_ENGLISH_ENTRY): ARRAYED_LIST [SB_ENGLISH_SENSE]
			-- The senses from the period dictionaries.
		do
			create Result.make (8)
			across a_entry.senses as ic loop
				if ic.source.same_string ({STRING_32} "BLOUNT1661") or ic.source.same_string ({STRING_32} "WRIGHT1884-QUOTING-BACON1604")
					or ic.source.same_string ({STRING_32} "WEBSTER1828") or ic.source.same_string ({STRING_32} "WRIGHT1884") then
					Result.extend (ic)
				end
			end
		end

	today_senses (a_entry: SB_ENGLISH_ENTRY): ARRAYED_LIST [SB_ENGLISH_SENSE]
		do
			create Result.make (8)
			across a_entry.senses as ic loop
				if ic.source.same_string ({STRING_32} "OEWN2025") then
					Result.extend (ic)
				end
			end
		end

	grouped_by_source (a_senses: ARRAYED_LIST [SB_ENGLISH_SENSE]): ARRAYED_LIST [TUPLE [source: STRING_32; list: ARRAYED_LIST [SB_ENGLISH_SENSE]]]
		do
			Result := grouped (a_senses, False)
		end

	grouped_by_pos (a_senses: ARRAYED_LIST [SB_ENGLISH_SENSE]): ARRAYED_LIST [TUPLE [source: STRING_32; list: ARRAYED_LIST [SB_ENGLISH_SENSE]]]
			-- By part of speech, which each tuple's `source' then holds.
		do
			Result := grouped (a_senses, True)
		end

	part_of_speech (a_code: READABLE_STRING_32): STRING_32
		do
			if a_code.same_string ({STRING_32} "n") then
				Result := {STRING_32} "noun"
			elseif a_code.same_string ({STRING_32} "v") then
				Result := {STRING_32} "verb"
			elseif a_code.same_string ({STRING_32} "a") or a_code.same_string ({STRING_32} "s") then
				Result := {STRING_32} "adjective"
			elseif a_code.same_string ({STRING_32} "r") then
				Result := {STRING_32} "adverb"
			else
				Result := a_code.to_string_32
			end
		end

	joined (a_list: LIST [READABLE_STRING_32]; a_between: READABLE_STRING_32): STRING_32
		do
			create Result.make (32)
			across a_list as ic loop
				if not Result.is_empty then
					Result.append (a_between)
				end
				Result.append (ic)
			end
		end

feature -- Spoken forms

	spoken_book (a_id: INTEGER): STRING_32
			-- "1 Corinthians" as it is said: "First Corinthians".
		do
			Result := state.bible.book (a_id).name.twin
			if Result.starts_with ({STRING_32} "1 ") then
				Result := {STRING_32} "First " + Result.substring (3, Result.count)
			elseif Result.starts_with ({STRING_32} "2 ") then
				Result := {STRING_32} "Second " + Result.substring (3, Result.count)
			elseif Result.starts_with ({STRING_32} "3 ") then
				Result := {STRING_32} "Third " + Result.substring (3, Result.count)
			end
		end

	spoken_of (a_ref: SB_REF): STRING_32
			-- A reference as it is said: "John 3, verse 16"; "Psalms, chapter 23".
		local
			l_book: STRING_32
		do
			l_book := spoken_book (a_ref.book)
			if a_ref.verse = 0 then
				Result := l_book + {STRING_32} ", chapter " + a_ref.chapter.out.to_string_32
			elseif a_ref.verse_end > a_ref.verse then
				Result := l_book + {STRING_32} " " + a_ref.chapter.out.to_string_32 + {STRING_32} ", verses " + a_ref.verse.out.to_string_32 + {STRING_32} " to " + a_ref.verse_end.out.to_string_32
			else
				Result := l_book + {STRING_32} " " + a_ref.chapter.out.to_string_32 + {STRING_32} ", verse " + a_ref.verse.out.to_string_32
			end
		end

	spoken_ref (a_key: INTEGER): STRING_32
		do
			Result := spoken_of (create {SB_REF}.make_from_key (a_key))
		end

	spoken_translit (a_text: READABLE_STRING_32): STRING_32
			-- A transliteration without its marks, which voices stumble over.
		local
			l_code: NATURAL_32
		do
			create Result.make (a_text.count)
			across unicode.nfd (a_text) as ic loop
				l_code := ic.natural_32_code
				if unicode.general_category (l_code) [1] = 'M' then
					-- A mark.
				elseif ic = '%/702/' or ic = '%/703/' or ic = '%/700/' or ic = '%/701/' or ic = '%'' or ic = '%/8217/' then
					-- An aleph or ayin sign.
				elseif ic = '%/601/' then
					Result.append_character ('e')
				else
					Result.append_character (ic)
				end
			end
		end

	lang_of (a_version: SB_VERSION): INTEGER
			-- Latin letters are read as English, except the Vulgate.
		do
			Result := if a_version.language.same_string ({STRING_32} "la") then {SB_SPEECH}.Lang_latin else {SB_SPEECH}.Lang_english end
		end

	verse_speech (a_key: INTEGER; a_version: READABLE_STRING_32; a_lead: READABLE_STRING_32): SB_SPEECH
			-- A verse's text as one thing to read, in its version's voice.
		local
			l_version: SB_VERSION
			l_text: STRING_32
		do
			l_version := state.bible.version (a_version)
			create l_text.make (120)
			across state.bible.verses_at (a_key, a_version) as ic loop
				if @ic.cursor_index > 1 then
					l_text.append_character (' ')
				end
				l_text.append (ic.text)
			end
			if text.is_blank (l_text) then
				l_text := {STRING_32} "Not in the " + l_version.name + {STRING_32} "."
			end
			create Result.make_in (a_lead + l_text, lang_of (l_version), (create {SB_REF}.make_from_key (a_key)).label)
		end

	verse_lead (a_key: INTEGER): STRING_32
		do
			Result := spoken_ref (a_key) + {STRING_32} ". "
		end

	verses_batch (a_keys: LIST [INTEGER]): SB_BATCH
			-- A list of verses, each with its reference, in the reading version.
		do
			create Result.make ({STRING_32} "")
			across a_keys as ic loop
				Result.add_item (verse_speech (ic, state.version, verse_lead (ic)))
			end
		end

	add_paragraphs (a_batch: SB_BATCH; a_text: READABLE_STRING_32)
			-- Writing split into paragraphs, so Next and Back move a paragraph at a time.
		local
			l_para: STRING_32
		do
			paragraph_count := 0
			create l_para.make (256)
			across a_text.split ('%N') as ic loop
				if text.is_blank (ic) then
					flush_paragraph (a_batch, l_para)
				else
					if not l_para.is_empty then
						l_para.append_character ('%N')
					end
					l_para.append (ic)
				end
			end
			flush_paragraph (a_batch, l_para)
		end

	year_label (a_year: INTEGER): STRING_32
			-- An astronomical year as people write it: 1300 BC, AD 14.
		do
			if a_year <= 0 then
				Result := (1 - a_year).out.to_string_32 + {STRING_32} " BC"
			elseif a_year < 1000 then
				Result := {STRING_32} "AD " + a_year.out.to_string_32
			else
				Result := a_year.out.to_string_32
			end
		end

feature -- Screens read aloud

	chapter_batch (a_page, a_from_key: INTEGER): SB_BATCH
			-- The chapter on `a_page' from verse `a_from_key', then on if that setting is on.
		local
			l_book, l_chapter, i, j: INTEGER
			l_versions: ARRAYED_LIST [STRING_32]
			l_keys: SORTED_TWO_WAY_LIST [INTEGER]
			l_verses: ARRAYED_LIST [ARRAYED_LIST [SB_VERSE]]
			l_name, l_lead, l_text, l_label: STRING_32
			l_version: SB_VERSION
			l_first: BOOLEAN
			l_found: BOOLEAN
		do
			l_book := state.bible.chapters [a_page].book
			l_chapter := state.bible.chapters [a_page].chapter
			l_name := state.bible.book (l_book).name + {STRING_32} " " + l_chapter.out.to_string_32
			create Result.make (l_name + {STRING_32} " %/183/ " + state.version)
			l_versions := state.shown_versions
			create l_verses.make (l_versions.count)
			create l_keys.make
			across l_versions as ic loop
				l_verses.extend (state.bible.verses_in_chapter (ic, l_book, l_chapter))
				across l_verses.last as jc loop
					if jc.eng_key >= a_from_key and not l_keys.has (jc.eng_key) then
						l_keys.extend (jc.eng_key)
					end
				end
			end
			if a_from_key = 0 or else (not l_keys.is_empty and then l_keys.first \\ 1000 = 1) then
				Result.add_item (create {SB_SPEECH}.make_verse (spoken_book (l_book) + {STRING_32} ", chapter " + l_chapter.out.to_string_32 + {STRING_32} ".", {SB_SPEECH}.Lang_english, l_book, l_chapter, 0, l_name))
			end
			if l_keys.is_empty then
				Result.add (l_name + {STRING_32} " is not in the " + state.bible.version (state.version).name + {STRING_32} ".", l_name)
			else
				across l_keys as ic loop
					from i := 1 until i > l_versions.count loop
						l_version := state.bible.version (l_versions [i])
						create l_text.make (120)
						l_first := True
						l_found := False
						from j := 1 until j > l_verses [i].count loop
							if l_verses [i] [j].eng_key = ic and not text.is_blank (l_verses [i] [j].text) then
								if not l_first then
									l_text.append_character (' ')
								end
								l_text.append (l_verses [i] [j].text)
								l_first := False
								l_found := True
							end
							j := j + 1
						end
						if l_found then
							l_lead := {STRING_32} ""
							if i > 1 then
								l_lead := l_version.code + {STRING_32} ". "
							elseif state.say_verse_numbers then
								l_lead := (ic \\ 1000).out.to_string_32 + {STRING_32} ". "
							end
							l_label := l_name + {STRING_32} ":" + (ic \\ 1000).out.to_string_32
							if i > 1 then
								l_label.append ({STRING_32} " %/183/ " + l_version.code)
							end
							Result.add_item (create {SB_SPEECH}.make_verse (l_lead + l_text, lang_of (l_version), l_book, l_chapter, ic, l_label))
						end
						i := i + 1
					end
				end
				if state.read_on and a_page < state.bible.chapters.count then
					Result.set_next (agent chapter_batch (a_page + 1, 0))
				end
			end
		end

	word_batch (a_lemma: SB_LEMMA; a_renderings: ARRAYED_LIST [SB_RENDERING]; a_senses: ARRAYED_LIST [SB_SENSE]; a_places: like {SB_APP_DB}.occurrences): SB_BATCH
			-- The word page: heading, the KJV's renderings, each dictionary in turn, then the places.
		local
			l_text, l_name, l_one: STRING_32
			i: INTEGER
			l_ref: SB_REF
		do
			create Result.make ({STRING_32} "")
			l_text := a_lemma.headword + {STRING_32} " . " + spoken_translit (a_lemma.translit) + {STRING_32} ". " + a_lemma.language_name
			if not text.is_blank (a_lemma.pos) then
				l_text.append ({STRING_32} ", " + a_lemma.pos)
			end
			l_text.append ({STRING_32} ". Occurs " + a_lemma.count.out.to_string_32 + {STRING_32} " times.")
			Result.add (l_text, a_lemma.headword)
			if not a_renderings.is_empty then
				l_text := {STRING_32} "The King James Version renders it: "
				from i := 1 until i > a_renderings.count or i > 24 loop
					if i > 1 then
						l_text.append ({STRING_32} ", ")
					end
					l_text.append (a_renderings [i].english + {STRING_32} ", " + a_renderings [i].n.out.to_string_32)
					i := i + 1
				end
				l_text.append_character ('.')
				Result.add (l_text, {STRING_32} "How the KJV renders it")
			end
			across senses_by_source (a_senses, if a_lemma.is_hebrew then hebrew_order else greek_order end) as ic loop
				l_name := if attached state.bible.source (ic.source) as al_info then al_info.name else ic.source end
				Result.add (l_name + {STRING_32} ".", l_name)
				across ic.list as jc loop
					l_one := joined_head (jc)
					if sense_repeats (jc) or text.is_blank (jc.text) then
						-- The head says it all.
					elseif text.is_blank (l_one) then
						l_one := jc.text
					else
						l_one := l_one + {STRING_32} ". " + jc.text
					end
					if not text.is_blank (l_one) then
						Result.add (l_one, l_name)
					end
				end
			end
			Result.add ({STRING_32} "Every place: " + a_places.count.out.to_string_32 + {STRING_32} ".", {STRING_32} "Every place")
			from i := 1 until i > a_places.count or i > 50 loop
				create l_ref.make_from_key (a_places [i].eng_key)
				Result.add_item (create {SB_SPEECH}.make_in (spoken_of (l_ref) + {STRING_32} ", " + a_places [i].gloss + {STRING_32} ". " + state.bible.preview_text (l_ref, state.version),
					lang_of (state.bible.version (state.version)), l_ref.label))
				i := i + 1
			end
		end

	english_batch (a_entry: SB_ENGLISH_ENTRY): SB_BATCH
			-- The English word page: the words behind it, what it meant then, what it means today.
		local
			l_then, l_today: ARRAYED_LIST [SB_ENGLISH_SENSE]
			l_text, l_name, l_pos: STRING_32
		do
			create Result.make ({STRING_32} "")
			l_text := a_entry.lemma.twin
			if a_entry.forms.count > 1 then
				l_text.append ({STRING_32} ". In the King James Version as: " + joined (a_entry.forms, {STRING_32} ", ") + {STRING_32} ".")
			else
				l_text.append_character ('.')
			end
			Result.add (l_text, a_entry.lemma)
			if not a_entry.behind.is_empty then
				Result.add ({STRING_32} "The Hebrew and Greek behind it.", {STRING_32} "Behind it")
				across a_entry.behind as ic loop
					l_text := ic.lemma.headword + {STRING_32} " . " + spoken_translit (ic.lemma.translit)
					if not text.is_blank (ic.lemma.hint) then
						l_text.append ({STRING_32} ", " + ic.lemma.hint)
					end
					l_text.append ({STRING_32} ". " + ic.n.out.to_string_32 + {STRING_32} " places.")
					Result.add (l_text, ic.lemma.translit)
				end
			end
			l_then := then_senses (a_entry)
			if not l_then.is_empty or not a_entry.shifts.is_empty then
				Result.add ({STRING_32} "What it meant then.", {STRING_32} "What it meant then")
			end
			if not a_entry.shifts.is_empty then
				l_text := {STRING_32} "Wright's Bible Word-Book, 1884, lists " + a_entry.lemma + {STRING_32} " among the words whose meaning has changed since the King James Version, at "
				across a_entry.shifts as ic loop
					if @ic.cursor_index > 1 then
						l_text.append ({STRING_32} "; ")
					end
					l_text.append (spoken_ref (ic))
				end
				l_text.append_character ('.')
				Result.add (l_text, {STRING_32} "Wright 1884")
			end
			across grouped_by_source (l_then) as ic loop
				l_name := if attached state.bible.source (ic.source) as al_info then al_info.name else ic.source end
				Result.add (l_name + {STRING_32} ".", l_name)
				across ic.list as jc loop
					Result.add (if text.is_blank (jc.sense_no) then jc.text else jc.sense_no + {STRING_32} ". " + jc.text end, l_name)
				end
			end
			l_today := today_senses (a_entry)
			if not l_today.is_empty then
				Result.add ({STRING_32} "What it means today.", {STRING_32} "What it means today")
				across grouped_by_pos (l_today) as ic loop
					l_pos := part_of_speech (ic.source)
					Result.add (l_pos + {STRING_32} ".", l_pos)
					across ic.list as jc loop
						Result.add (@jc.cursor_index.out.to_string_32 + {STRING_32} ". " + jc.text, l_pos)
					end
				end
			end
		end

	sheet_batch (a_key, a_tab: INTEGER; a_packs: LIST [SB_PACK_DB]): SB_BATCH
			-- What the open tab of the verse sheet shows.
		local
			l_ref: SB_REF
			l_words: ARRAYED_LIST [SB_WORD]
			l_verses: ARRAYED_LIST [SB_VERSE]
			i, j: INTEGER
			l_version: SB_VERSION
			l_text: STRING_32
		do
			create Result.make ({STRING_32} "")
			create l_ref.make_from_key (a_key)
			inspect a_tab
			when 0 then
				Result.add_item (verse_speech (a_key, {STRING_32} "KJV", spoken_ref (a_key) + {STRING_32} ", King James Version. "))
				l_words := state.bible.words (a_key)
				if not l_words.is_empty then
					Result.add ({STRING_32} "The " + if l_ref.book <= 39 then {STRING_32} "Hebrew" else {STRING_32} "Greek" end + {STRING_32} " words.", {STRING_32} "Original words")
				end
				across l_words as ic loop
					Result.add (ic.surface + {STRING_32} " . " + ic.gloss, spoken_translit (ic.translit) + {STRING_32} "  %/183/  " + ic.gloss)
				end
			when 1 then
				across state.bible.xrefs (a_key) as ic loop
					Result.add_item (create {SB_SPEECH}.make_in (spoken_of (ic.ref) + {STRING_32} ". " + state.bible.preview_text (ic.ref, state.version), lang_of (state.bible.version (state.version)), ic.ref.label))
				end
			when 2 then
				l_verses := state.bible.verses_at (a_key, Void)
				from i := 1 until i > l_verses.count loop
					l_version := state.bible.version (l_verses [i].version)
					create l_text.make (120)
					from j := i until j > l_verses.count or else not l_verses [j].version.same_string (l_verses [i].version) loop
						if j > i then
							l_text.append_character (' ')
						end
						l_text.append (if l_verses [j].text.is_empty then {STRING_32} "omitted in this edition." else l_verses [j].text end)
						j := j + 1
					end
					Result.add_item (create {SB_SPEECH}.make_in (l_version.name + {STRING_32} ". " + l_text, lang_of (l_version), l_verses [i].version))
					i := j
				end
			else
				across a_packs as ic loop
					across ic.for_verse (a_key) as jc loop
						Result.add (jc.doc.title + {STRING_32} ". " + plain (jc.excerpt), jc.doc.title)
					end
				end
			end
		end

	search_batch (a_result: SB_SEARCH_RESULT; a_text: READABLE_STRING_32): SB_BATCH
		do
			create Result.make ({STRING_32} "")
			across a_result.verses as ic loop
				Result.add_item (create {SB_SPEECH}.make_in (spoken_ref (ic.eng_key) + {STRING_32} ". " + ic.text, lang_of (state.bible.version (ic.version)),
					(create {SB_REF}.make_from_key (ic.eng_key)).short_label + {STRING_32} " %/183/ " + ic.version))
			end
		end

	plain (a_excerpt: READABLE_STRING_32): STRING_32
			-- An excerpt without the marks that bracket what was found.
		do
			create Result.make (a_excerpt.count)
			across a_excerpt as ic loop
				if ic /= '%/1/' and ic /= '%/2/' then
					Result.append_character (ic)
				end
			end
		end

feature {NONE} -- Implementation

	flush_paragraph (a_batch: SB_BATCH; a_para: STRING_32)
		do
			if not text.is_blank (a_para) then
				paragraph_count := paragraph_count + 1
				a_para.left_adjust
				a_para.right_adjust
				a_batch.add (a_para.twin, {STRING_32} "Paragraph " + paragraph_count.out.to_string_32)
			end
			a_para.wipe_out
		end

	paragraph_count: INTEGER

	state: SB_STATE

	text: SB_KOTLIN_TEXT
		once
			create Result.make
		end

	unicode: SB_UNICODE
		once
			create Result.make
		end

	joined_head (a_sense: SB_SENSE): STRING_32
			-- The label and gloss with one space, as the speech has them.
		do
			Result := sense_head (a_sense)
			Result.replace_substring_all ({STRING_32} "  ", {STRING_32} " ")
		end

	without_ending (a_text: READABLE_STRING_32; a_marks: READABLE_STRING_32): STRING_32
			-- `a_text' trimmed, without `a_marks' at its end.
		do
			Result := a_text.to_string_32
			Result.left_adjust
			Result.right_adjust
			from until Result.is_empty or else not a_marks.has (Result [Result.count]) loop
				Result.remove_tail (1)
			end
		end

	grouped (a_senses: ARRAYED_LIST [SB_ENGLISH_SENSE]; a_by_pos: BOOLEAN): ARRAYED_LIST [TUPLE [source: STRING_32; list: ARRAYED_LIST [SB_ENGLISH_SENSE]]]
		local
			l_list: detachable ARRAYED_LIST [SB_ENGLISH_SENSE]
			l_key: STRING_32
		do
			create Result.make (4)
			across a_senses as ic loop
				l_key := if a_by_pos then ic.pos else ic.source end
				l_list := Void
				across Result as jc until l_list /= Void loop
					if jc.source.same_string (l_key) then
						l_list := jc.list
					end
				end
				if l_list = Void then
					create l_list.make (8)
					Result.extend ([l_key, l_list])
				end
				l_list.extend (ic)
			end
		end

end
