note
	description: "A document from a pack: its status first, then the text with references made into links. PackDocumentScreen."
	author: "Larry Rix"

class
	SB_PACK_DOC_PAGE

inherit
	SB_OVERLAY

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL; a_pack: SB_PACK_DB; a_id: INTEGER_64)
		local
			l_page, l_quote: PHONE_COLUMN
			l_top: PHONE_ROW
			l_text: SB_KOTLIN_TEXT
			l_line: STRING_32
			l_link: PHONE_TAPPABLE_TEXT
			l_shared: SB_PACK_VERSE
		do
			make_overlay (a_shell, {STRING_32} "")
			pack := a_pack
			id := a_id
			create l_text.make
			create l_shared.make (a_shell)
			create body_text.make_empty
			if attached a_pack.doc (a_id) as al_doc then
				doc := al_doc
				set_title (al_doc.title)
				body_text := a_pack.body (a_id)
				actions.extend (shell.speak_button ("doc:" + a_pack.path.out + ":" + a_id.out, al_doc.title, agent spoken))
				l_page := ui.column
				l_page.set_padding (16, 0)
				l_top := ui.row
				l_top.set_padding (0, 8)
				l_line := l_shared.kind_name (al_doc.kind)
				if not l_text.is_blank (al_doc.collection) then
					l_line.append ({STRING_32} " %/183/ " + al_doc.collection)
				end
				l_top.extend (ui.padded (l_line, theme.Label_large, theme.secondary, 0, 0, 8, 0))
				if attached l_shared.status_chip (al_doc.status) as al_chip then
					l_top.extend (al_chip)
				end
				l_page.extend (l_top)
				if al_doc.status.same_string ({STRING_32} "withdrawn") then
					l_page.extend (ui.padded ({STRING_32} "Withdrawn: kept for the record, not to be taken as current.", theme.Body_small, theme.error, 0, 0, 0, 8))
				end
				across (create {SB_MARKDOWN}).blocks (body_text) as ic loop
					inspect ic.kind
					when 'h' then
						l_page.extend (ui.padded (ic.text, if ic.level <= 1 then theme.Headline_small elseif ic.level = 2 then theme.Title_large else theme.Title_medium end, theme.primary, 0, 14, 0, 4))
					when 'q' then
						l_quote := ui.column
						l_quote.set_padding_each (12, 4, 0, 4)
						l_link := (create {SB_REF_LINKS}.make_italic (a_shell, ic.text)).text
						l_link.set_surface (theme.surface_container_low, 0)
						l_link.set_padding (8, 8)
						l_quote.extend (l_link)
						l_page.extend (l_quote)
					when 'l' then
						l_link := (create {SB_REF_LINKS}.make (a_shell, {STRING_32} "%/8226/  " + ic.text)).text
						l_link.set_padding_each (8, 2, 0, 0)
						l_page.extend (l_link)
					else
						l_link := (create {SB_REF_LINKS}.make (a_shell, ic.text)).text
						l_link.set_padding (0, 4)
						l_page.extend (l_link)
					end
				end
				l_page.extend (ui.padded (al_doc.path, theme.Label_small, theme.on_surface_variant, 0, 24, 0, 24))
				content.extend_growing (ui.scroller (l_page), 1)
			else
				content.extend (ui.empty ({STRING_32} "This document is not in the pack."))
			end
		end

feature {NONE} -- Implementation

	spoken: SB_BATCH
		local
			l_shared: SB_PACK_VERSE
			l_text: SB_KOTLIN_TEXT
			l_line: STRING_32
		do
			create Result.make ({STRING_32} "")
			if attached doc as al_doc then
				create l_shared.make (shell)
				create l_text.make
				l_line := al_doc.title + {STRING_32} ". " + l_shared.kind_name (al_doc.kind)
				if not l_text.is_blank (al_doc.status) and not al_doc.status.same_string ({STRING_32} "unmarked") then
					l_line.append ({STRING_32} ", " + al_doc.status + {STRING_32} ".")
				else
					l_line.append_character ('.')
				end
				Result.add (l_line, al_doc.title)
				across (create {SB_MARKDOWN}).blocks (body_text) as ic loop
					Result.add (ic.text, if ic.kind = 'h' then ic.text else al_doc.title end)
				end
			end
		end

	pack: SB_PACK_DB

	id: INTEGER_64

	doc: detachable SB_PACK_DOC

	body_text: STRING_32

end
