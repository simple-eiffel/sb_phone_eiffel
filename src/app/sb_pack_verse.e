note
	description: "What the pack screens share: kinds, statuses, a document's row, and the verse sheet's Mine tab. From PackScreens.kt."
	author: "Larry Rix"

class
	SB_PACK_VERSE

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL)
		do
			shell := a_shell
			theme := a_shell.theme
			ui := a_shell.ui
		end

feature -- Names

	kind_order: ARRAY [STRING_32]
		do
			Result := <<{STRING_32} "commentary", {STRING_32} "framework", {STRING_32} "book", {STRING_32} "essay",
				{STRING_32} "series", {STRING_32} "analysis", {STRING_32} "research", {STRING_32} "note">>
		end

	kind_name (a_kind: READABLE_STRING_32): STRING_32
		local
			l_names: ARRAY [STRING_32]
			i: INTEGER
		do
			l_names := <<{STRING_32} "Commentary", {STRING_32} "Frameworks", {STRING_32} "Books", {STRING_32} "Essays",
				{STRING_32} "Series", {STRING_32} "Analyses", {STRING_32} "Research", {STRING_32} "Notes">>
			from i := 1 until i > 8 or Result /= Void loop
				if kind_order [i].same_string (a_kind) then
					Result := l_names [i]
				end
				i := i + 1
			end
			if Result = Void then
				Result := a_kind.to_string_32
				if not Result.is_empty then
					Result [1] := Result [1].as_upper
				end
			end
		end

feature -- Controls

	status_chip (a_status: READABLE_STRING_32): detachable PHONE_LABEL
			-- Status shown on every document, so a withdrawn or draft text is never mistaken for a settled one.
		local
			l_warn: BOOLEAN
		do
			if not (create {SB_KOTLIN_TEXT}.make).is_blank (a_status) and not a_status.same_string ({STRING_32} "unmarked") then
				l_warn := a_status.same_string ({STRING_32} "withdrawn") or a_status.same_string ({STRING_32} "ungated")
				Result := ui.label (a_status, theme.Label_small, if l_warn then theme.on_error else theme.on_secondary_container end)
				Result.set_surface (if l_warn then theme.error else theme.secondary_container end, 6)
				Result.set_padding (6, 2)
			end
		end

	doc_row (a_page: PHONE_COLUMN; a_pack: SB_PACK_DB; a_doc: SB_PACK_DOC; a_excerpt: detachable READABLE_STRING_32)
			-- DocRow: a document in a list, opening it.
		local
			l_box: PHONE_COLUMN
			l_top: PHONE_FIT_ROW
			l_excerpt: STRING_32
		do
			l_box := ui.tappable_column (agent open_doc (a_pack, a_doc.id), 20, 10)
			create l_top.make (ui.controls)
			l_top.extend (ui.padded (a_doc.title, theme.Title_small, theme.on_background, 0, 0, 8, 0))
			if attached status_chip (a_doc.status) as al_chip then
				l_top.extend (al_chip)
			end
			l_box.extend (l_top)
			if attached a_excerpt as al_excerpt then
				l_excerpt := (create {SB_MARKDOWN}).plain (al_excerpt)
				l_excerpt.left_adjust
				l_excerpt.right_adjust
				l_box.extend (ui.limited (ui.label (l_excerpt, theme.Body_small, theme.on_surface_variant), 3))
			end
			a_page.extend (l_box)
			a_page.extend (ui.divider)
		end

	hit_row (a_page: PHONE_COLUMN; a_pack: SB_PACK_DB; a_hit: SB_PACK_HIT)
		local
			l_text: STRING_32
		do
			l_text := kind_name (a_hit.doc.kind)
			if not (create {SB_KOTLIN_TEXT}.make).is_blank (a_hit.doc.collection) then
				l_text.append ({STRING_32} " %/183/ " + a_hit.doc.collection)
			end
			a_page.extend (ui.padded (l_text, theme.Label_small, theme.secondary, 20, 8, 0, 0))
			doc_row (a_page, a_pack, a_hit.doc, a_hit.excerpt)
		end

	open_doc (a_pack: SB_PACK_DB; a_id: INTEGER_64)
		do
			shell.open (create {SB_PACK_DOC_PAGE}.make (shell, a_pack, a_id))
		end

feature -- The Mine tab

	fill (a_body: PHONE_COLUMN; a_key: INTEGER)
			-- Commentary sections covering the verse, then writings that cite it.
		local
			l_hits: ARRAYED_LIST [TUPLE [pack: SB_PACK_DB; hit: SB_PACK_HIT]]
			l_page: PHONE_COLUMN
			l_top: PHONE_ROW
		do
			create l_hits.make (8)
			across shell.packs as ic loop
				across ic.for_verse (a_key) as jc loop
					l_hits.extend ([ic, jc])
				end
			end
			if l_hits.is_empty then
				a_body.extend (ui.empty ({STRING_32} "Nothing in your materials covers or cites this verse."))
			else
				l_page := ui.column
				l_top := ui.row
				l_top.extend_growing (ui.padded (l_hits.count.out.to_string_32 + {STRING_32} " in your materials", theme.Label_large, theme.secondary, 20, 0, 0, 0), 1)
				l_top.extend (shell.speak_button ("mine:" + a_key.out, {STRING_32} "Mine %/183/ " + (create {SB_REF}.make_from_key (a_key)).label, agent mine_spoken (l_hits)))
				l_page.extend (l_top)
				across l_hits as ic loop
					hit_row (l_page, ic.pack, ic.hit)
				end
				a_body.extend_growing (ui.scroller (l_page), 1)
			end
		end

feature {NONE} -- Implementation

	mine_spoken (a_hits: ARRAYED_LIST [TUPLE [pack: SB_PACK_DB; hit: SB_PACK_HIT]]): SB_BATCH
		do
			create Result.make ({STRING_32} "")
			across a_hits as ic loop
				Result.add (ic.hit.doc.title + {STRING_32} ". " + (create {SB_MARKDOWN}).plain (ic.hit.excerpt), ic.hit.doc.title)
			end
		end

	shell: SB_SHELL

	theme: SB_THEME

	ui: SB_UI

end
