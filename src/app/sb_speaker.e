note
	description: "[
		Reads text aloud, as Speaker.kt does: a batch of items, each split by script so Hebrew
		goes to a Hebrew voice and Greek to a Greek one, and long stretches into sentences.
		Back, next, pause and stop move through it. Reading goes on into the batch after.
	]"
	author: "Larry Rix"

class
	SB_SPEAKER

create
	make

feature {NONE} -- Initialization

	make (a_phone: SIMPLE_EIF_PHONE; a_services: PHONE_SERVICES)
		do
			create voices.make (a_phone.controls)
			controls := a_phone.controls
			services := a_services
			create source.make_empty
			create title.make_empty
			create now_label.make_empty
			create notice.make_empty
			create voice_report.make_from_string ({STRING_32} "Checking%/8230/")
			create items.make (0)
			create chunks.make (0)
			create missing.make (4)
			rate := 1.0
			voices.set_on_voice (agent heard)
		end

feature -- Access

	is_active, is_playing: BOOLEAN

	source: STRING_8
			-- Which screen is being read.

	title: STRING_32

	now_label: STRING_32

	notice: STRING_32

	now: detachable SB_SPEECH
			-- The item being read.

	voice_report: STRING_32
			-- Which voice each language uses on this phone, once the engines have been asked.

feature -- Element change

	set_on_change (a_action: PROCEDURE [TUPLE])
		do
			on_change := a_action
		end

	set_on_report (a_action: PROCEDURE [TUPLE])
		do
			on_report := a_action
		end

	set_rate (a_rate: REAL_64)
		do
			rate := a_rate
			voices.set_rate (a_rate)
		end

feature -- Controls

	read (a_source: READABLE_STRING_8; a_batch: SB_BATCH)
			-- Start reading `a_batch', stopping anything already being read.
		do
			voices.stop
			generation := generation + 1
			create source.make_from_string (a_source)
			is_active := True
			is_playing := True
			notice.wipe_out
			missing.wipe_out
			start (a_batch)
		end

	pause
		do
			if is_playing then
				generation := generation + 1
				voices.stop
				is_playing := False
				changed
			end
		end

	resume
		do
			if is_active and not is_playing then
				is_playing := True
				voices.take_audio (True)
				generation := generation + 1
				speak_current
			end
		end

	toggle
			-- Pause, or carry on.
		do
			if is_playing then
				pause
			else
				resume
			end
		end

	stop
		do
			generation := generation + 1
			voices.stop
			finish
		end

	skip_next
			-- To the next item.
		local
			i, l_item, l_to: INTEGER
		do
			if is_active and position <= chunks.count and position >= 1 then
				l_item := chunks [position].owner
				l_to := chunks.count + 1
				from i := chunks.count until i < 1 loop
					if chunks [i].owner > l_item then
						l_to := i
					end
					i := i - 1
				end
				generation := generation + 1
				voices.stop
				position := l_to
				if is_playing then
					speak_current
				end
			end
		end

	skip_previous
			-- Back to the start of this item, or to the item before when already at its start.
		local
			i, l_item, l_first, l_before: INTEGER
		do
			if is_active and position <= chunks.count and position >= 1 then
				l_item := chunks [position].owner
				from i := chunks.count until i < 1 loop
					if chunks [i].owner = l_item then
						l_first := i
					elseif chunks [i].owner = l_item - 1 then
						l_before := i
					end
					i := i - 1
				end
				generation := generation + 1
				voices.stop
				if position > l_first then
					position := l_first
				elseif l_before > 0 then
					position := l_before
				else
					position := l_first
				end
				if is_playing then
					speak_current
				end
			end
		end

	check_voices
			-- Ask the engines which voices they have.
		local
			l_wire: STRING_32
		do
			create l_wire.make (64)
			l_wire.append ({STRING_32} "English%/29/en%/29/US%/29/")
			l_wire.append ({STRING_32} "%/30/Hebrew%/29/he,iw%/29/IL%/29/")
			l_wire.append ({STRING_32} "%/30/Greek%/29/el%/29/GR%/29/")
			l_wire.append ({STRING_32} "%/30/Latin%/29/la%/29/%/29/it")
			voices.ask_report (l_wire)
		end

feature {NONE} -- Reading

	start (a_batch: SB_BATCH)
		local
			i: INTEGER
		do
			if a_batch.items.is_empty then
				finish
			else
				title := a_batch.title
				items := a_batch.items
				next := a_batch.next
				create chunks.make (items.count)
				from i := 1 until i > items.count loop
					add_chunks (i, items [i])
					i := i + 1
				end
				position := 1
				voices.set_rate (rate)
				voices.take_audio (True)
				speak_current
			end
		end

	speak_current
		local
			l_chunk: TUPLE [owner: INTEGER; text: STRING_32; lang: INTEGER]
		do
			if is_playing then
				from
				until
					position > chunks.count or else not missing.has (chunks [position].lang)
				loop
					position := position + 1
				end
				if position <= chunks.count then
					l_chunk := chunks [position]
					now := items [l_chunk.owner]
					now_label := items [l_chunk.owner].label
					changed
					voices.speak (generation * 100000 + position, codes (l_chunk.lang), country (l_chunk.lang), if l_chunk.lang = {SB_SPEECH}.Lang_latin then "it" else "" end, l_chunk.text)
				elseif attached next as al_next then
					if missing.is_empty then
						start (al_next.item ([]))
					else
						services.after (Skip_pause, agent next_after_skip (generation))
					end
				else
					finish
				end
			end
		end

	next_after_skip (a_generation: INTEGER)
			-- On to the next batch, unless the reading was stopped or moved meanwhile.
			-- A pause between batches: with no voice for any of it, nothing else would let a tap through.
		do
			if a_generation = generation and is_playing and position > chunks.count and then attached next as al_next then
				start (al_next.item ([]))
			end
		end

	heard (a_kind, a_detail: READABLE_STRING_32)
		do
			if a_kind.same_string ({STRING_32} "done") then
				if a_detail.is_integer and then a_detail.to_integer = generation * 100000 + position and is_playing then
					position := position + 1
					speak_current
				end
			elseif a_kind.same_string ({STRING_32} "missing") then
				if a_detail.is_integer and then a_detail.to_integer = generation * 100000 + position and is_playing then
					note_missing (chunks [position].lang)
					position := position + 1
					speak_current
				end
			elseif a_kind.same_string ({STRING_32} "lost") then
				pause
			elseif a_kind.same_string ({STRING_32} "report") then
				voice_report := a_detail.to_string_32
				if attached on_report as al_action then
					al_action.call ([])
				end
			end
		end

	note_missing (a_lang: INTEGER)
		local
			l_and, l_or: STRING_32
		do
			if not missing.has (a_lang) then
				missing.extend (a_lang)
				create l_and.make (16)
				create l_or.make (16)
				across missing as ic loop
					if not l_and.is_empty then
						l_and.append ({STRING_32} " and ")
						l_or.append ({STRING_32} " or ")
					end
					l_and.append (lang_label (ic))
					l_or.append (lang_label (ic))
				end
				notice := l_and + {STRING_32} " skipped: this phone has no " + l_or + {STRING_32} " voice installed (see Settings %/8594/ Read aloud)."
			end
		end

	finish
		do
			is_active := False
			is_playing := False
			source.wipe_out
			now := Void
			now_label.wipe_out
			create items.make (0)
			create chunks.make (0)
			next := Void
			position := 0
			voices.take_audio (False)
			if not notice.is_empty then
				controls.toast (notice)
				notice.wipe_out
			end
			changed
		end

	changed
		do
			if attached on_change as al_action then
				al_action.call ([])
			end
		end

feature {NONE} -- Preparing the text

	add_chunks (a_item: INTEGER; a_speech: SB_SPEECH)
			-- Split `a_speech' into stretches by script: chunksOf.
		local
			l_texts: ARRAYED_LIST [STRING_32]
			l_langs: ARRAYED_LIST [INTEGER]
			l_script, i, l_lang: INTEGER
			l_char: CHARACTER_32
			l_clean: STRING_32
		do
			create l_texts.make (2)
			create l_langs.make (2)
			across a_speech.text as ic loop
				l_char := ic
				l_script := script_of (l_char, a_speech.lang)
				if l_texts.is_empty then
					l_texts.extend (create {STRING_32}.make (64))
					l_texts.last.append_character (l_char)
					l_langs.extend (l_script)
				elseif l_script = 0 or l_langs.last = l_script then
					l_texts.last.append_character (l_char)
				elseif l_langs.last = 0 then
					l_texts.last.append_character (l_char)
					l_langs [l_langs.count] := l_script
				else
					l_texts.extend (create {STRING_32}.make (64))
					l_texts.last.append_character (l_char)
					l_langs.extend (l_script)
				end
			end
			from i := 1 until i > l_texts.count loop
				l_lang := if l_langs [i] = 0 then a_speech.lang else l_langs [i] end
				l_clean := cleaned (l_texts [i], l_lang)
				if has_letter_or_digit (l_clean) then
					across sentences (l_clean) as ic loop
						chunks.extend ([a_item, ic, l_lang])
					end
				end
				i := i + 1
			end
		end

	script_of (a_char: CHARACTER_32; a_lang: INTEGER): INTEGER
			-- Spaces, punctuation and combining marks (0) stay with the stretch they are in.
		local
			l_code: NATURAL_32
		do
			l_code := a_char.natural_32_code
			if (l_code >= 0x0590 and l_code <= 0x05FF) or (l_code >= 0xFB1D and l_code <= 0xFB4F) then
				Result := {SB_SPEECH}.Lang_hebrew
			elseif (l_code >= 0x0370 and l_code <= 0x03FF) or (l_code >= 0x1F00 and l_code <= 0x1FFF) then
				Result := {SB_SPEECH}.Lang_greek
			elseif unicode.is_letter_or_digit (l_code) then
				Result := a_lang
			end
		end

	has_letter_or_digit (a_text: STRING_32): BOOLEAN
		do
			Result := across a_text as ic some unicode.is_letter_or_digit (ic.natural_32_code) end
		end

	cleaned (a_text: STRING_32; a_lang: INTEGER): STRING_32
		local
			l_text: STRING_32
		do
			if a_lang = {SB_SPEECH}.Lang_hebrew then
					-- Accents off, maqaf as a space, sof pasuq as a full stop.
				l_text := (create {SB_POINTING}).apply (a_text, {SB_POINTING}.Level_vowels)
				l_text.replace_substring_all ({STRING_32} "%/1470/", {STRING_32} " ")
				l_text.replace_substring_all ({STRING_32} "%/1475/", {STRING_32} ".")
				l_text.replace_substring_all ({STRING_32} "%/1472/", {STRING_32} "")
				l_text.replace_substring_all ({STRING_32} "%/1478/", {STRING_32} "")
			elseif a_lang = {SB_SPEECH}.Lang_greek then
				l_text := monotonic (a_text)
			else
				l_text := spoken_english (a_text)
			end
			Result := single_spaced (l_text)
		end

	monotonic (a_text: STRING_32): STRING_32
			-- Polytonic Greek to the one-accent spelling modern Greek voices read. The phone
			-- composes it again before speaking.
		do
			create Result.make (a_text.count)
			across unicode.nfd (a_text) as ic loop
				inspect ic.natural_32_code
				when 0x0313, 0x0314, 0x0345, 0x0306, 0x0304 then
					-- Breathings, iota subscript, length marks: off.
				when 0x0300, 0x0342 then
					Result.append_character ('%/769/')
				else
					Result.append_character (ic)
				end
			end
		end

	spoken_english (a_text: STRING_32): STRING_32
			-- Symbols a voice would read badly, and verse references in running text.
		local
			i, l_digits, l_second, l_third, p: INTEGER
		do
			create Result.make (a_text.count + 16)
			from i := 1 until i > a_text.count loop
				if is_digit (a_text [i]) then
					l_digits := digit_run (a_text, i)
					p := i + l_digits
					l_second := if p <= a_text.count and then a_text [p] = ':' then digit_run (a_text, p + 1) else 0 end
					if l_second > 0 then
						l_third := range_digits (a_text, p + 1 + l_second)
						Result.append (a_text.substring (i, p - 1))
						if l_third > 0 then
							Result.append ({STRING_32} ", verses ")
							Result.append (a_text.substring (p + 1, p + l_second))
							Result.append ({STRING_32} " to ")
							Result.append (a_text.substring (range_end - l_third + 1, range_end))
							i := range_end + 1
						else
							Result.append ({STRING_32} ", verse ")
							Result.append (a_text.substring (p + 1, p + l_second))
							i := p + l_second + 1
						end
					else
						Result.append (a_text.substring (i, p - 1))
						i := p
					end
				else
					inspect a_text [i].natural_32_code
					when 215 then
						Result.append ({STRING_32} " times")
					when 38 then
						Result.append ({STRING_32} " and ")
					when 183 then
						Result.append_character (',')
					when 8224, 9733, 9734, 9998, 8594, 8592, 9662, 9652, 9656, 8226, 35, 42, 95, 124, 91, 93, 123, 125, 60, 62 then
						Result.append_character (' ')
					else
						Result.append_character (a_text [i])
					end
					i := i + 1
				end
			end
		end

	range_digits (a_text: STRING_32; a_at: INTEGER): INTEGER
			-- How many digits follow a dash at `a_at', with `range_end' their last place; or 0.
		local
			p: INTEGER
		do
			p := a_at
			if p <= a_text.count and then unicode_space (a_text [p]) then
				p := p + 1
			end
			if p <= a_text.count and then (a_text [p] = '-' or a_text [p] = '%/8211/') then
				p := p + 1
				if p <= a_text.count and then unicode_space (a_text [p]) then
					p := p + 1
				end
				Result := digit_run (a_text, p)
				range_end := p + Result - 1
			end
		end

	range_end: INTEGER

	digit_run (a_text: STRING_32; a_at: INTEGER): INTEGER
		local
			p: INTEGER
		do
			from p := a_at until p > a_text.count or else not is_digit (a_text [p]) loop
				p := p + 1
			end
			Result := p - a_at
		end

	is_digit (a_char: CHARACTER_32): BOOLEAN
		do
			Result := a_char >= '0' and a_char <= '9'
		end

	unicode_space (a_char: CHARACTER_32): BOOLEAN
		do
			Result := a_char = ' ' or a_char = '%T' or a_char = '%N' or a_char = '%R'
		end

	single_spaced (a_text: STRING_32): STRING_32
			-- Runs of spaces as one, trimmed.
		local
			l_space: BOOLEAN
		do
			create Result.make (a_text.count)
			across a_text as ic loop
				if unicode_space (ic) then
					l_space := not Result.is_empty
				else
					if l_space then
						Result.append_character (' ')
						l_space := False
					end
					Result.append_character (ic)
				end
			end
		end

	sentences (a_text: STRING_32): ARRAYED_LIST [STRING_32]
			-- `a_text' in pieces a voice takes whole.
		local
			l_part, l_run: STRING_32
			i, l_start: INTEGER
		do
			create Result.make (1)
			if a_text.count <= 500 then
				Result.extend (a_text)
			else
				create l_run.make (512)
				l_start := 1
				from i := 1 until i > a_text.count loop
					if (i = a_text.count) or else (a_text [i + 1] = ' ' and then (a_text [i] = '.' or a_text [i] = ';' or a_text [i] = ':' or a_text [i] = '!' or a_text [i] = '?')) then
						l_part := a_text.substring (l_start, i)
						l_start := i + 2
						if not l_run.is_empty and l_run.count + l_part.count > 500 then
							Result.extend (l_run.twin)
							l_run.wipe_out
						end
						if not l_run.is_empty then
							l_run.append_character (' ')
						end
						l_run.append (l_part)
						from until l_run.count <= 3000 loop
							Result.extend (l_run.substring (1, 3000))
							l_run.remove_head (3000)
						end
						i := i + 1
					end
					i := i + 1
				end
				if not l_run.is_empty then
					Result.extend (l_run)
				end
			end
		end

feature {NONE} -- Languages

	codes (a_lang: INTEGER): STRING_8
		do
			inspect a_lang
			when {SB_SPEECH}.Lang_hebrew then
				Result := "he,iw"
			when {SB_SPEECH}.Lang_greek then
				Result := "el"
			when {SB_SPEECH}.Lang_latin then
				Result := "la"
			else
				Result := "en"
			end
		end

	country (a_lang: INTEGER): STRING_8
		do
			inspect a_lang
			when {SB_SPEECH}.Lang_hebrew then
				Result := "IL"
			when {SB_SPEECH}.Lang_greek then
				Result := "GR"
			when {SB_SPEECH}.Lang_latin then
				Result := ""
			else
				Result := "US"
			end
		end

	lang_label (a_lang: INTEGER): STRING_32
		do
			inspect a_lang
			when {SB_SPEECH}.Lang_hebrew then
				Result := {STRING_32} "Hebrew"
			when {SB_SPEECH}.Lang_greek then
				Result := {STRING_32} "Greek"
			when {SB_SPEECH}.Lang_latin then
				Result := {STRING_32} "Latin"
			else
				Result := {STRING_32} "English"
			end
		end

feature {NONE} -- Implementation

	voices: PHONE_VOICES

	controls: PHONE_CONTROLS

	items: ARRAYED_LIST [SB_SPEECH]

	chunks: ARRAYED_LIST [TUPLE [owner: INTEGER; text: STRING_32; lang: INTEGER]]

	next: detachable FUNCTION [SB_BATCH]

	position: INTEGER

	generation: INTEGER

	rate: REAL_64

	missing: ARRAYED_LIST [INTEGER]

	services: PHONE_SERVICES

	Skip_pause: INTEGER = 50
			-- Milliseconds between batches once a language has been skipped.

	on_change, on_report: detachable PROCEDURE [TUPLE]

	unicode: SB_UNICODE
		once
			create Result.make
		end

end
