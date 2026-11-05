note
	description: "A small Markdown reader: headings, quotes, list items, paragraphs, with emphasis marks removed. From PackScreens.kt."
	author: "Larry Rix"

class
	SB_MARKDOWN

feature -- Reading

	blocks (a_text: READABLE_STRING_32): ARRAYED_LIST [TUPLE [kind: CHARACTER_8; text: STRING_32; level: INTEGER]]
			-- `a_text' as blocks: 'h' heading, 'q' quote, 'l' list item, 'p' paragraph.
		local
			l_para, l_line: STRING_32
			l_in_front: BOOLEAN
			l_level, l_skip: INTEGER
			l_index: INTEGER
		do
			create Result.make (32)
			create l_para.make (256)
			across a_text.split ('%N') as ic loop
				l_index := @ic.cursor_index
				l_line := ic.to_string_32
				l_line.right_adjust
				if l_index = 1 and l_line.same_string ({STRING_32} "---") then
					l_in_front := True
				elseif l_in_front then
					if l_line.same_string ({STRING_32} "---") then
						l_in_front := False
					end
				elseif text.is_blank (l_line) then
					flush (Result, l_para)
				elseif l_line [1] = '#' then
					flush (Result, l_para)
					from l_level := 0 until l_level >= l_line.count or else l_line [l_level + 1] /= '#' loop
						l_level := l_level + 1
					end
					Result.extend (['h', plain (trimmed (l_line.substring (l_level + 1, l_line.count))), l_level])
				elseif l_line [1] = '>' then
					flush (Result, l_para)
					Result.extend (['q', plain (without_quote_marks (l_line)), 0])
				else
					l_skip := list_mark (l_line)
					if l_skip > 0 then
						flush (Result, l_para)
						Result.extend (['l', plain (l_line.substring (l_skip + 1, l_line.count)), 0])
					elseif l_line [1] = '|' then
						flush (Result, l_para)
						Result.extend (['p', plain (table_row (l_line)), 0])
					else
						if not l_para.is_empty then
							l_para.append_character (' ')
						end
						l_para.append (trimmed (l_line))
					end
				end
			end
			flush (Result, l_para)
			from Result.start until Result.after loop
				if Result.item.kind = 'p' and then is_rule (Result.item.text) then
					Result.remove
				else
					Result.forth
				end
			end
		end

	plain (a_text: READABLE_STRING_32): STRING_32
			-- `a_text' without Markdown emphasis and wiki-link brackets, keeping the words.
		local
			i, l_close, l_bar, l_paren: INTEGER
			l_text: STRING_32
		do
			create l_text.make (a_text.count)
			from i := 1 until i > a_text.count loop
				if i < a_text.count and then a_text [i] = '[' and then a_text [i + 1] = '[' then
					l_close := a_text.substring_index ({STRING_32} "]]", i)
					if l_close > 0 then
						l_bar := a_text.index_of ('|', i)
						if l_bar > 0 and l_bar < l_close then
							l_text.append (a_text.substring (l_bar + 1, l_close - 1))
						else
							l_text.append (a_text.substring (i + 2, l_close - 1))
						end
						i := l_close + 2
					else
						l_text.append_character (a_text [i])
						i := i + 1
					end
				elseif a_text [i] = '[' then
					l_close := a_text.index_of (']', i)
					l_paren := if l_close > 0 and l_close < a_text.count and then a_text [l_close + 1] = '(' then a_text.index_of (')', l_close) else 0 end
					if l_paren > 0 and l_close > i + 1 then
						l_text.append (a_text.substring (i + 1, l_close - 1))
						i := l_paren + 1
					else
						l_text.append_character (a_text [i])
						i := i + 1
					end
				else
					l_text.append_character (a_text [i])
					i := i + 1
				end
			end
			l_text.replace_substring_all ({STRING_32} "**", {STRING_32} "")
			l_text.replace_substring_all ({STRING_32} "__", {STRING_32} "")
			l_text.replace_substring_all ({STRING_32} "`", {STRING_32} "")
			Result := without_stars (l_text)
		end

feature {NONE} -- Implementation

	flush (a_blocks: like blocks; a_para: STRING_32)
		do
			if not text.is_blank (a_para) then
				a_blocks.extend (['p', plain (trimmed (a_para)), 0])
			end
			a_para.wipe_out
		end

	trimmed (a_text: READABLE_STRING_32): STRING_32
		do
			Result := a_text.to_string_32
			Result.left_adjust
			Result.right_adjust
		end

	without_quote_marks (a_line: STRING_32): STRING_32
		local
			i: INTEGER
		do
			from i := 1 until i > a_line.count or else (a_line [i] /= '>' and a_line [i] /= ' ') loop
				i := i + 1
			end
			Result := a_line.substring (i, a_line.count)
		end

	list_mark (a_line: STRING_32): INTEGER
			-- How much of `a_line' is a list mark: ^\s*([-*+]|\d+[.)])\s+ ; 0 if none.
		local
			p, l_digits: INTEGER
		do
			p := 1
			from until p > a_line.count or else not is_space (a_line [p]) loop
				p := p + 1
			end
			if p <= a_line.count then
				if a_line [p] = '-' or a_line [p] = '*' or a_line [p] = '+' then
					p := p + 1
					l_digits := 1
				else
					from until p > a_line.count or else not (a_line [p] >= '0' and a_line [p] <= '9') loop
						p := p + 1
						l_digits := l_digits + 1
					end
					if l_digits > 0 and p <= a_line.count and then (a_line [p] = '.' or a_line [p] = ')') then
						p := p + 1
					else
						l_digits := 0
					end
				end
				if l_digits > 0 and p <= a_line.count and then is_space (a_line [p]) then
					from until p > a_line.count or else not is_space (a_line [p]) loop
						p := p + 1
					end
					Result := p - 1
				end
			end
		end

	table_row (a_line: STRING_32): STRING_32
		local
			l_body: STRING_32
		do
			l_body := a_line.twin
			from until l_body.is_empty or else l_body [1] /= '|' loop
				l_body.remove_head (1)
			end
			from until l_body.is_empty or else l_body [l_body.count] /= '|' loop
				l_body.remove_tail (1)
			end
			create Result.make (l_body.count)
			across l_body.split ('|') as ic loop
				if @ic.cursor_index > 1 then
					Result.append ({STRING_32} "  %/183/  ")
				end
				Result.append (trimmed (ic))
			end
		end

	is_rule (a_text: STRING_32): BOOLEAN
			-- ^[-:| ]+$
		do
			Result := not a_text.is_empty and then across a_text as ic all ic = '-' or ic = ':' or ic = '|' or ic = ' ' end
		end

	is_space (a_char: CHARACTER_32): BOOLEAN
		do
			Result := a_char = ' ' or a_char = '%T'
		end

	is_word (a_char: CHARACTER_32): BOOLEAN
			-- \w
		do
			Result := (a_char >= 'a' and a_char <= 'z') or (a_char >= 'A' and a_char <= 'Z') or (a_char >= '0' and a_char <= '9') or a_char = '_'
		end

	without_stars (a_text: STRING_32): STRING_32
			-- (?<![\w*])\*(?!\s)([^*]+)(?<!\s)\*(?![\w*]) as $1
		local
			i, l_close: INTEGER
			l_before_ok, l_after_ok: BOOLEAN
		do
			create Result.make (a_text.count)
			from i := 1 until i > a_text.count loop
				if a_text [i] = '*' then
					l_before_ok := i = 1 or else not (is_word (a_text [i - 1]) or a_text [i - 1] = '*')
					l_close := if i < a_text.count then a_text.index_of ('*', i + 1) else 0 end
					l_after_ok := l_close > 0 and then (l_close = a_text.count or else not (is_word (a_text [l_close + 1]) or a_text [l_close + 1] = '*'))
					if l_before_ok and l_after_ok and then l_close > i + 1 and then not is_space (a_text [i + 1]) and then not is_space (a_text [l_close - 1]) then
						Result.append (a_text.substring (i + 1, l_close - 1))
						i := l_close + 1
					else
						Result.append_character ('*')
						i := i + 1
					end
				else
					Result.append_character (a_text [i])
					i := i + 1
				end
			end
		end

	text: SB_KOTLIN_TEXT
		once
			create Result.make
		end

end
