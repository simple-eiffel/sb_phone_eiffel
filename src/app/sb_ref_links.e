note
	description: "[
		Writing with references in it, each recognised reference opening its verse: linkRefs in
		PersonalScreens.kt, whose pattern is
		((?:[1-3]\s?)?[A-Za-z]{2,}\.?(?:\s(?:of\s)?Songs?)?)\s(\d{1,3}):(\d{1,3})(?:\s?[-–]\s?(\d{1,3}))?
	]"
	author: "Larry Rix"

class
	SB_REF_LINKS

create
	make, make_italic

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL; a_body: READABLE_STRING_32)
		do
			build (a_shell, a_body, 0)
		end

	make_italic (a_shell: SB_SHELL; a_body: READABLE_STRING_32)
		do
			build (a_shell, a_body, 2)
		end

	build (a_shell: SB_SHELL; a_body: READABLE_STRING_32; a_flags: INTEGER)
		local
			l_row: PHONE_RICH_ROW
			i, l_stop, l_last: INTEGER
			l_theme: SB_THEME
		do
			shell := a_shell
			l_theme := a_shell.theme
			create runs.make (8)
			create text.make (a_shell.controls)
			create l_row.make (0, 0, 0)
			l_theme.add_style (l_row, l_theme.Body_large, l_theme.on_background)
			l_last := 1
			from i := 1 until i > a_body.count loop
				l_stop := match_at (a_body, i)
				if l_stop >= i and then attached {SB_REF_PARSE_ONE} (create {SB_REF_PARSER}.make).parse (a_body.substring (i, l_stop)) as al_one then
					if i > l_last then
						l_row.add_run (a_body.substring (l_last, i - 1), a_flags, 0, 0.0)
						runs.extend (Void)
					end
					l_row.add_run (a_body.substring (i, l_stop), l_row.Tappable + l_row.Underlined + a_flags, l_theme.primary, 0.0)
					runs.extend (al_one.ref)
					l_last := l_stop + 1
					i := l_last
				elseif l_stop >= i then
					i := l_stop + 1
				else
					i := i + 1
				end
			end
			if l_last <= a_body.count or l_last = 1 then
				l_row.add_run (a_body.substring (l_last, a_body.count), a_flags, 0, 0.0)
				runs.extend (Void)
			end
			text.set_rich (l_row)
			text.set_on_run (agent run_tapped)
			text.set_padding_each (0, 12, 0, 0)
		end

feature -- Access

	text: PHONE_TAPPABLE_TEXT

feature {NONE} -- Implementation

	run_tapped (a_run: INTEGER)
		do
			if a_run >= 1 and a_run <= runs.count and then attached runs [a_run] as al_ref then
				shell.go_to (al_ref)
			end
		end

	match_at (a_text: READABLE_STRING_32; a_start: INTEGER): INTEGER
			-- Where the pattern's match starting at `a_start' ends, or 0.
		local
			p, l_letters, l_digits, l_verse_end: INTEGER
		do
			p := a_start
			if p <= a_text.count and then a_text [p] >= '1' and then a_text [p] <= '3' then
				p := p + 1
				if p <= a_text.count and then is_space (a_text [p]) then
					p := p + 1
				end
			end
			from until p > a_text.count or else not is_letter (a_text [p]) loop
				p := p + 1
				l_letters := l_letters + 1
			end
			if l_letters >= 2 then
				if p <= a_text.count and then a_text [p] = '.' then
					p := p + 1
				end
				p := after_songs (a_text, p)
				if p <= a_text.count and then is_space (a_text [p]) then
					p := p + 1
					l_digits := digits_at (a_text, p)
					if l_digits >= 1 and l_digits <= 3 and then p + l_digits <= a_text.count and then a_text [p + l_digits] = ':' then
						p := p + l_digits + 1
						l_digits := digits_at (a_text, p).min (3)
						if l_digits >= 1 then
							Result := p + l_digits - 1
							l_verse_end := range_end (a_text, Result + 1)
							if l_verse_end > 0 then
								Result := l_verse_end
							end
						end
					end
				end
			end
		end

	after_songs (a_text: READABLE_STRING_32; a_at: INTEGER): INTEGER
			-- `a_at', past " Song", " Songs", " of Song" or " of Songs" when they are there.
		local
			p: INTEGER
		do
			Result := a_at
			p := a_at
			if p <= a_text.count and then is_space (a_text [p]) then
				p := p + 1
				if p + 2 <= a_text.count and then a_text.substring (p, p + 1).same_string ({STRING_32} "of") and then is_space (a_text [p + 2]) then
					p := p + 3
				end
				if p + 3 <= a_text.count and then a_text.substring (p, p + 3).same_string ({STRING_32} "Song") then
					p := p + 4
					if p <= a_text.count and then a_text [p] = 's' then
						p := p + 1
					end
					Result := p
				end
			end
		end

	range_end (a_text: READABLE_STRING_32; a_at: INTEGER): INTEGER
			-- Where a "-30" at `a_at' ends, or 0.
		local
			p, l_digits: INTEGER
		do
			p := a_at
			if p <= a_text.count and then is_space (a_text [p]) then
				p := p + 1
			end
			if p <= a_text.count and then (a_text [p] = '-' or a_text [p] = '%/8211/') then
				p := p + 1
				if p <= a_text.count and then is_space (a_text [p]) then
					p := p + 1
				end
				l_digits := digits_at (a_text, p).min (3)
				if l_digits >= 1 then
					Result := p + l_digits - 1
				end
			end
		end

	digits_at (a_text: READABLE_STRING_32; a_at: INTEGER): INTEGER
		local
			p: INTEGER
		do
			from p := a_at until p > a_text.count or else not (a_text [p] >= '0' and a_text [p] <= '9') loop
				p := p + 1
			end
			Result := p - a_at
		end

	is_letter (a_character: CHARACTER_32): BOOLEAN
		do
			Result := (a_character >= 'a' and a_character <= 'z') or (a_character >= 'A' and a_character <= 'Z')
		end

	is_space (a_character: CHARACTER_32): BOOLEAN
		do
			Result := a_character = ' ' or a_character = '%T' or a_character = '%N' or a_character = '%R'
		end

	shell: SB_SHELL

	runs: ARRAYED_LIST [detachable SB_REF]

end
