note
	description: "Every text and dataset in the app with its license. CreditsScreen in MoreScreen.kt."
	author: "Larry Rix"

class
	SB_CREDITS_PAGE

inherit
	SB_OVERLAY

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL)
		local
			l_page, l_box: PHONE_COLUMN
			l_line: STRING_32
			l_text: SB_KOTLIN_TEXT
			l_row: PHONE_RICH_ROW
			l_built, l_basis: STRING_32
		do
			make_overlay (a_shell, {STRING_32} "Credits and licenses")
			create l_text.make
			actions.extend (shell.speak_button ("credits", {STRING_32} "Credits and licenses", agent spoken))
			l_page := ui.column
			l_page.extend (ui.padded ({STRING_32} "Every text and dataset in this app is listed here with its license. Texts under share-alike licenses may be shared on the same terms.", theme.Body_medium, theme.on_background, 20, 20, 20, 20))
			across state.bible.sources as ic loop
				l_box := ui.column
				l_box.set_padding (20, 10)
				l_box.extend (ui.label (ic.name, theme.Title_small, theme.on_background))
				l_line := ic.kind + {STRING_32} "  %/183/  " + ic.license
				if ic.share_alike then
					l_line.append ({STRING_32} "  %/183/  share-alike")
				end
				l_box.extend (ui.label (l_line, theme.Label_medium, theme.secondary))
				l_box.extend (ui.label (ic.credit, theme.Body_small, theme.on_background))
				if not l_text.is_blank (ic.url) then
					l_box.extend (ui.label (ic.url, theme.Body_small, theme.on_surface_variant))
				end
				l_page.extend (l_box)
				l_page.extend (ui.divider)
			end
			l_box := ui.column
			l_box.set_padding (20, 20)
			l_box.extend (ui.label ({STRING_32} "Hebrew font: Ezra SIL", theme.Title_small, theme.on_background))
			create l_row.make (0, 0, 0)
			theme.add_style_in (l_row, theme.Body_small, theme.Mono, theme.on_background)
			l_row.add_text (font_license)
			l_box.extend (ui.rich (l_row))
			l_box.extend (ui.padded ({STRING_32} "Icons: Material Design icon shapes, Apache License 2.0.", theme.Body_small, theme.on_background, 0, 12, 0, 0))
			l_built := if attached state.bible.meta ("built_on") as al_built then al_built else {STRING_32} "" end
			l_basis := if attached state.bible.meta ("vmap_basis") as al_basis then al_basis else {STRING_32} "" end
			l_box.extend (ui.padded ({STRING_32} "Data built " + l_built + {STRING_32} ". " + l_basis, theme.Body_small, theme.on_surface_variant, 0, 12, 0, 0))
			l_page.extend (l_box)
			content.extend_growing (ui.scroller (l_page), 1)
		end

feature {NONE} -- Implementation

	font_license: STRING_32
			-- The font's license, kept with the app.
		local
			l_utf: UTF_CONVERTER
			l_bytes: STRING_8
		do
			create Result.make_empty
			shell.phone.assets.read_asset ("licenses/EzraSIL-license.txt")
			if attached shell.phone.assets.last_asset as al_bytes then
				create l_bytes.make (shell.phone.assets.last_asset_size)
				l_bytes.from_c_substring (al_bytes.item, 1, shell.phone.assets.last_asset_size)
				Result := l_utf.utf_8_string_8_to_string_32 (l_bytes)
				Result.prune_all ('%R')
			end
		end

	spoken: SB_BATCH
		do
			create Result.make ({STRING_32} "")
			across state.bible.sources as ic loop
				Result.add (ic.name + {STRING_32} ". " + ic.license + {STRING_32} ". " + ic.credit, ic.name)
			end
		end

end
