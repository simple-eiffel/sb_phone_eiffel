note
	description: "Asks what to open for a picked KJV word: the Hebrew or Greek behind it, or its English meaning then and now. WordPickDialog."
	author: "Larry Rix"

class
	SB_WORD_PICK_DIALOG

inherit
	SB_DIALOG
		rename
			make as make_dialog
		end

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL; a_pick: SB_WORD_PICK)
		local
			l_state: SB_STATE
			l_lemmas: ARRAYED_LIST [SB_LEMMA]
			l_ui: SB_UI
			l_theme: SB_THEME
			l_more: PHONE_LABEL
			l_row: PHONE_RICH_ROW
			l_item: PHONE_ROW
			l_text: PHONE_COLUMN
			l_second: STRING_32
		do
			make_dialog (a_shell, {STRING_32} "%/8220/" + a_pick.word + {STRING_32} "%/8221/  %/183/  " + (create {SB_REF}.make_from_key (a_pick.key)).short_label)
			l_state := a_shell.state
			l_ui := a_shell.ui
			l_theme := a_shell.theme
			l_lemmas := l_state.bible.kjv_lemmas (a_pick.key, a_pick.fold, a_pick.nth)
			if l_lemmas.is_empty then
				content.extend (l_ui.label ({STRING_32} "No Hebrew or Greek word is linked to this English word here (often a word the translators supplied).", l_theme.Body_medium, l_theme.on_surface_variant))
			else
				content.extend (l_ui.label ({STRING_32} "Translates", l_theme.Label_large, l_theme.secondary))
				across l_lemmas as ic loop
					l_item := l_ui.row
					l_item.set_padding (0, 8)
					l_item.extend (l_ui.lemma_head (ic))
					l_text := l_ui.column
					l_text.set_padding_each (12, 0, 0, 0)
					l_text.extend (l_ui.italic (ic.translit, l_theme.Body_medium, l_theme.on_surface_variant))
					l_second := ic.number.twin
					if not ic.hint.is_empty then
						l_second.append ({STRING_32} "  %/183/  " + ic.hint)
					end
					l_text.extend (l_ui.limited (l_ui.label (l_second, l_theme.Body_small, l_theme.on_surface_variant), 1))
					l_item.extend_growing (l_text, 1)
					l_item.set_on_tap (agent open_word (a_shell, ic.id))
					content.extend (l_item)
				end
			end
			create l_row.make (0, 0, 0)
			l_theme.add_style (l_row, l_theme.Body_medium, l_theme.primary)
			l_row.add_run ({STRING_32} "What %/8220/" + a_pick.word + {STRING_32} "%/8221/ meant then and means now  %/8594/", l_row.Semi_bold, 0, 0.0)
			l_more := l_ui.rich (l_row)
			l_more.set_padding_each (0, 16, 0, 4)
			l_more.set_on_tap (agent open_english (a_shell, a_pick.word))
			content.extend (l_more)
			add_close ({STRING_32} "Close")
		end

feature {NONE} -- Implementation

	open_word (a_shell: SB_SHELL; a_lemma: INTEGER)
		do
			a_shell.close_dialog
			a_shell.open (create {SB_WORD_PAGE}.make (a_shell, a_lemma))
		end

	open_english (a_shell: SB_SHELL; a_word: STRING_32)
		do
			a_shell.close_dialog
			a_shell.open (create {SB_ENGLISH_PAGE}.make (a_shell, a_word.as_lower))
		end

end
