note
	description: "Settings: text size, theme, Hebrew pointing, reading aloud, parallel versions. SettingsScreen in MoreScreen.kt."
	author: "Larry Rix"

class
	SB_SETTINGS_PAGE

inherit
	SB_OVERLAY
		redefine
			closing
		end

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL)
		do
			make_overlay (a_shell, {STRING_32} "Settings")
			create page.make (controls)
			create sample_room.make (controls)
			create voices_label.make (controls, shell.speaker.voice_report)
			page.set_padding (20, 20)
			content.extend_growing (ui.scroller (page), 1)
			shell.speaker.set_on_report (agent report_heard)
			shell.speaker.check_voices
			show
		end

feature -- Closing

	closing
		do
			shell.refresh
		end

feature {NONE} -- Showing

	show
		local
			l_slider: PHONE_RANGE
			l_chips: PHONE_ROW
			l_row: PHONE_RICH_ROW
		do
			page.clear
			page.extend (ui.label ({STRING_32} "Text size", theme.Title_medium, theme.on_background))
				-- 0.8 to 2.0 in twelve steps of 0.1.
			l_slider := ui.range (12)
			l_slider.show_steps
			l_slider.set_value (((state.text_scale - 0.8) * 10).rounded)
			l_slider.set_on_change (agent scale_changed)
			page.extend (l_slider)
			create sample_room.make (controls)
			page.extend (sample_room)
			show_samples

			page.extend (ui.padded ({STRING_32} "Theme", theme.Title_medium, theme.on_background, 0, 24, 0, 0))
			l_chips := ui.row
			l_chips.set_least_height (48)
			l_chips.extend (chip_space (ui.filter_chip ({STRING_32} "System", state.theme = state.Theme_system, agent theme_tapped (state.Theme_system))))
			l_chips.extend (chip_space (ui.filter_chip ({STRING_32} "Dark", state.theme = state.Theme_dark, agent theme_tapped (state.Theme_dark))))
			l_chips.extend (chip_space (ui.filter_chip ({STRING_32} "Light", state.theme = state.Theme_light, agent theme_tapped (state.Theme_light))))
			page.extend (l_chips)

			page.extend (ui.padded ({STRING_32} "Hebrew pointing", theme.Title_medium, theme.on_background, 0, 24, 0, 0))
			l_chips := ui.row
			l_chips.set_least_height (48)
			l_chips.extend (chip_space (ui.filter_chip ({STRING_32} "Full", state.pointing = {SB_POINTING}.Level_full, agent pointing_tapped ({SB_POINTING}.Level_full))))
			l_chips.extend (chip_space (ui.filter_chip ({STRING_32} "Vowels", state.pointing = {SB_POINTING}.Level_vowels, agent pointing_tapped ({SB_POINTING}.Level_vowels))))
			l_chips.extend (chip_space (ui.filter_chip ({STRING_32} "Consonants", state.pointing = {SB_POINTING}.Level_consonants, agent pointing_tapped ({SB_POINTING}.Level_consonants))))
			page.extend (l_chips)
			create l_row.make (0, 0, 0)
			state.add_reading_block (l_row, theme, state.bible.version ({STRING_32} "WLC"), state.base_size, 0)
			l_row.add_text (state.hebrew (Hebrew_sample))
			page.extend (ui.rich (l_row))
			page.extend (ui.label ({STRING_32} "Full shows the accents (cantillation) too; Vowels drops them; Consonants shows the letters alone.", theme.Body_small, theme.on_surface_variant))

			show_read_aloud

			page.extend (ui.padded ({STRING_32} "Parallel versions (up to three)", theme.Title_medium, theme.on_background, 0, 24, 0, 0))
			page.extend (ui.label ({STRING_32} "Shown under the main version when the columns button in the reader is on.", theme.Body_small, theme.on_surface_variant))
			across state.bible.versions as ic loop
				add_version (ic)
			end
		end

	chip_space (a_chip: PHONE_CONTROL): PHONE_ROW
		do
			Result := ui.top_row
			Result.set_padding_each (0, 0, 8, 0)
			Result.extend (a_chip)
		end

	show_samples
		local
			l_row: PHONE_RICH_ROW
		do
			sample_room.clear
			create l_row.make (0, 0, 0)
			state.add_reading_block (l_row, theme, state.bible.version ({STRING_32} "KJV"), state.base_size, 0)
			l_row.add_text ({STRING_32} "In the beginning God created the heaven and the earth.")
			sample_room.extend (ui.rich (l_row))
			create l_row.make (0, 0, 0)
			state.add_reading_block (l_row, theme, state.bible.version ({STRING_32} "WLC"), state.base_size, 0)
			l_row.add_text (Hebrew_sample)
			sample_room.extend (ui.rich (l_row))
		end

	show_read_aloud
		local
			l_slider: PHONE_RANGE
			l_buttons: PHONE_ROW
		do
			page.extend (ui.padded ({STRING_32} "Read aloud", theme.Title_medium, theme.on_background, 0, 24, 0, 0))
			page.extend (ui.label ({STRING_32} "Every screen has a speaker button that reads that screen. In the reader it reads the chapter and goes on into the next.", theme.Body_small, theme.on_surface_variant))
			speed_label := ui.padded (speed_text, theme.Body_medium, theme.on_background, 0, 8, 0, 0)
			page.extend (speed_label)
				-- 0.50 to 2.00 in steps of 0.05.
			l_slider := ui.range (30)
			l_slider.show_steps
			l_slider.set_value (((state.speech_rate - 0.5) * 20).rounded)
			l_slider.set_on_change (agent rate_changed)
			page.extend (l_slider)
			add_switch ({STRING_32} "Say verse numbers", state.say_verse_numbers, agent say_tapped)
			add_switch ({STRING_32} "Go on into the next chapter", state.read_on, agent read_on_tapped)
			page.extend (ui.padded ({STRING_32} "Voices on this phone", theme.Title_small, theme.on_background, 0, 8, 0, 0))
			create voices_label.make (controls, shell.speaker.voice_report)
			voices_label.set_rich (theme.styled (shell.speaker.voice_report, theme.Body_small, theme.on_background))
			page.extend (voices_label)
			page.extend (ui.padded ({STRING_32} "Hebrew and Greek are read with modern Israeli and Greek voices: a help for hearing the words, not a reconstruction of how they were said. To add a voice, open the phone's speech settings, choose an engine (Google's has Hebrew and Greek), then its settings %/8594/ Install voice data.",
				theme.Body_small, theme.on_surface_variant, 0, 4, 0, 0))
			l_buttons := ui.top_row
			l_buttons.extend (ui.text_button ({STRING_32} "Test the voices", agent test_voices))
			l_buttons.extend (ui.text_button ({STRING_32} "Phone's speech settings", agent (shell.services).open_speech_settings))
			page.extend (l_buttons)
		end

	add_switch (a_text: READABLE_STRING_32; a_on: BOOLEAN; a_action: PROCEDURE [TUPLE [BOOLEAN]])
		local
			l_row: PHONE_ROW
			l_switch: PHONE_ON_OFF
		do
			l_row := ui.row
			l_row.set_padding (0, 4)
			l_row.set_least_height (56)
			l_switch := ui.on_off (a_on)
			l_row.set_on_tap (agent switch_tapped (l_switch, a_action))
			l_row.extend (l_switch)
			l_row.extend (ui.padded (a_text, theme.Body_large, theme.on_background, 12, 0, 0, 0))
			page.extend (l_row)
		end

	add_version (a_version: SB_VERSION)
		local
			l_on: BOOLEAN
			l_row: PHONE_ROW
			l_text: PHONE_COLUMN
		do
			l_on := across state.parallel as ic some ic.same_string (a_version.code) end
			l_row := ui.row
			l_row.set_padding (0, 8)
			l_row.extend (ui.padded (if l_on then {STRING_32} "%/9745/" else {STRING_32} "%/9744/" end, theme.Title_medium, theme.on_background, 0, 0, 12, 0))
			l_text := ui.column
			l_text.extend (ui.label (a_version.code, theme.Title_small, theme.on_background))
			l_text.extend (ui.label (a_version.name + {STRING_32} " %/183/ " + a_version.coverage, theme.Body_small, theme.on_surface_variant))
			l_row.extend_growing (l_text, 1)
			l_row.set_on_tap (agent version_tapped (a_version.code, l_on))
			page.extend (l_row)
		end

	switch_tapped (a_switch: PHONE_ON_OFF; a_action: PROCEDURE [TUPLE [BOOLEAN]])
		do
			a_switch.set_on (not a_switch.is_on)
			a_action.call ([a_switch.is_on])
		end

	speed_text: STRING_32
			-- "%.2f" with its trailing zeros off, then the times sign.
		local
			l_hundredths: INTEGER
		do
			l_hundredths := (state.speech_rate * 100).rounded
			create Result.make (8)
			Result.append ({STRING_32} "Speed: ")
			Result.append_integer (l_hundredths // 100)
			if l_hundredths \\ 100 /= 0 then
				Result.append_character ('.')
				if l_hundredths \\ 10 = 0 then
					Result.append_integer ((l_hundredths \\ 100) // 10)
				else
					if l_hundredths \\ 100 < 10 then
						Result.append_character ('0')
					end
					Result.append_integer (l_hundredths \\ 100)
				end
			end
			Result.append_character ('%/215/')
		end

feature {NONE} -- Choices

	scale_changed (a_value: INTEGER)
		do
			state.choose_text_scale (0.8 + a_value / 10)
			show_samples
		end

	rate_changed (a_value: INTEGER)
		do
			state.choose_speech_rate (0.5 + a_value / 20)
			shell.speaker.set_rate (state.speech_rate)
			speed_label.set_rich (theme.styled (speed_text, theme.Body_medium, theme.on_background))
		end

	theme_tapped (a_theme: INTEGER)
		do
			state.choose_theme (a_theme)
			shell.apply_theme
		end

	pointing_tapped (a_level: INTEGER)
		do
			state.choose_pointing (a_level)
			show
		end

	say_tapped (a_on: BOOLEAN)
		do
			state.choose_say_verse_numbers (a_on)
		end

	read_on_tapped (a_on: BOOLEAN)
		do
			state.choose_read_on (a_on)
		end

	version_tapped (a_code: STRING_32; a_on: BOOLEAN)
		local
			l_codes: ARRAYED_LIST [STRING_32]
		do
			create l_codes.make (4)
			across state.parallel as ic loop
				if not ic.same_string (a_code) then
					l_codes.extend (ic)
				end
			end
			if not a_on then
				l_codes.extend (a_code)
				if l_codes.count > 3 then
					l_codes.start
					l_codes.remove
				end
			end
			state.choose_parallel (l_codes)
			show
		end

	report_heard
		do
			voices_label.set_rich (theme.styled (shell.speaker.voice_report, theme.Body_small, theme.on_background))
		end

	test_voices
		local
			l_batch: SB_BATCH
		do
			create l_batch.make ({STRING_32} "Testing the voices")
			l_batch.add ({STRING_32} "In the beginning God created the heaven and the earth.", {STRING_32} "English")
			l_batch.add ({STRING_32} "%/1489/%/1456/%/1468/%/1512/%/1461/%/1488/%/1513/%/1473/%/1460/%/1497/%/1514/ %/1489/%/1464/%/1468/%/1512/%/1464/%/1488/ %/1488/%/1457/%/1500/%/1465/%/1492/%/1460/%/1497/%/1501/ %/1488/%/1461/%/1514/ %/1492/%/1463/%/1513/%/1468/%/1464/%/1473/%/1502/%/1463/%/1497/%/1460/%/1501/ %/1493/%/1456/%/1488/%/1461/%/1514/ %/1492/%/1464/%/1488/%/1464/%/1512/%/1462/%/1509/", {STRING_32} "Hebrew")
			l_batch.add ({STRING_32} "%/7944/%/957/ %/7936/%/961/%/967/%/8135/ %/7974/%/957/ %/8001/ %/955/%/972/%/947/%/959/%/962/", {STRING_32} "Greek")
			l_batch.add_item (create {SB_SPEECH}.make_in ({STRING_32} "In principio erat Verbum", {SB_SPEECH}.Lang_latin, {STRING_32} "Latin"))
			shell.speaker.read ("test", l_batch)
		end

feature {NONE} -- Implementation

	page, sample_room: PHONE_COLUMN

	speed_label: PHONE_LABEL
		attribute
			create Result.make (controls, {STRING_32} "")
		end

	voices_label: PHONE_LABEL

	Hebrew_sample: STRING_32
		once
			Result := {STRING_32} "%/1489/%/1456/%/1468/%/1512/%/1461/%/1488/%/1513/%/1473/%/1460/%/1422/%/1497/%/1514/ %/1489/%/1464/%/1468/%/1512/%/1464/%/1427/%/1488/ %/1488/%/1457/%/1500/%/1465/%/1492/%/1460/%/1425/%/1497/%/1501/"
		end

end
