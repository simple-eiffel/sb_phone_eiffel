note
	description: "A pack: its kinds of document, each kind's documents, and search. PackHomeScreen in PackScreens.kt."
	author: "Larry Rix"

class
	SB_PACK_HOME

inherit
	SB_OVERLAY
		redefine
			handle_back
		end

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL; a_pack: SB_PACK_DB)
		local
			l_room: PHONE_COLUMN
		do
			make_overlay (a_shell, a_pack.title)
			pack := a_pack
			create kind.make_empty
			create submitted.make_empty
			create shared.make (a_shell)
			create results.make (controls)
			create field.make (controls, {STRING_32} "Search " + a_pack.title, theme.primary, theme.outline, theme.on_surface_variant, theme.on_background)
			field.set_keyboard_action (field.Action_search)
			field.set_on_action (agent submit)
			l_room := ui.column
			l_room.set_padding (16, 8)
			l_room.extend (field)
			content.extend (l_room)
			content.extend_growing (results, 1)
			show
		end

feature -- Status

	handle_back: BOOLEAN
			-- From a kind's documents, Back returns to the kinds.
		do
			if not kind.is_empty then
				kind.wipe_out
				show
				Result := True
			end
		end

feature {NONE} -- Showing

	submit
		do
			submitted := field.text.to_string_32
			field.leave
			show
		end

	show
		local
			l_text: SB_KOTLIN_TEXT
		do
			create l_text.make
			actions.clear
			actions.extend (shell.speak_button ("pack:" + pack.path.out + ":" + submitted.out + ":" + kind.out, pack.title, agent spoken))
			results.clear
			if not l_text.is_blank (submitted) then
				show_hits
			elseif kind.is_empty then
				show_kinds
			else
				show_docs
			end
		end

	show_hits
		local
			l_hits: ARRAYED_LIST [SB_PACK_HIT]
			l_page: PHONE_COLUMN
		do
			l_hits := pack.search (submitted)
			if l_hits.is_empty then
				results.extend (ui.empty ({STRING_32} "Nothing found for %/8220/" + submitted + {STRING_32} "%/8221/."))
			else
				l_page := ui.column
				across l_hits as ic loop
					shared.hit_row (l_page, pack, ic)
				end
				results.extend_growing (ui.scroller (l_page), 1)
			end
		end

	show_kinds
		local
			l_page: PHONE_COLUMN
			l_order: ARRAY [STRING_32]
			l_text: SB_KOTLIN_TEXT
			l_note: STRING_32
			i: INTEGER
		do
			create l_text.make
			l_page := ui.column
			l_order := shared.kind_order
			from i := l_order.lower until i > l_order.upper loop
				across pack.kinds as ic loop
					if ic.kind.same_string (l_order [i]) then
						add_kind (l_page, ic.kind, ic.n)
					end
				end
				i := i + 1
			end
			across pack.kinds as ic loop
				if not across l_order as jc some jc.same_string (ic.kind) end then
					add_kind (l_page, ic.kind, ic.n)
				end
			end
			create l_note.make (32)
			if attached pack.meta_value ("built_on") as al_built then
				l_note.append ({STRING_32} "Built " + al_built)
			end
			if attached pack.meta_value ("note") as al_note then
				if not l_note.is_empty then
					l_note.append ({STRING_32} ". ")
				end
				l_note.append (al_note)
			end
			l_page.extend (ui.padded (l_note, theme.Body_small, theme.on_surface_variant, 20, 20, 20, 20))
			results.extend_growing (ui.scroller (l_page), 1)
		end

	add_kind (a_page: PHONE_COLUMN; a_kind: STRING_32; a_count: INTEGER)
		local
			l_row: PHONE_ROW
		do
			l_row := ui.top_row
			l_row.set_padding (20, 14)
			l_row.set_on_tap (agent kind_tapped (a_kind))
			l_row.extend_growing (ui.label (shared.kind_name (a_kind), theme.Title_medium, theme.on_background), 1)
			l_row.extend (ui.label (a_count.out.to_string_32, theme.Label_large, theme.on_surface_variant))
			a_page.extend (l_row)
			a_page.extend (ui.divider)
		end

	kind_tapped (a_kind: STRING_32)
		do
			create kind.make_from_string (a_kind)
			show
		end

	show_docs
		local
			l_page: PHONE_COLUMN
			l_last: detachable STRING_32
			l_text: SB_KOTLIN_TEXT
		do
			create l_text.make
			l_page := ui.column
			across pack.docs (kind) as ic loop
				if not l_text.is_blank (ic.collection) and then (l_last = Void or else not l_last.same_string (ic.collection)) then
					l_page.extend (ui.padded (ic.collection, theme.Title_small, theme.primary, 20, 14, 0, 4))
				end
				l_last := ic.collection
				shared.doc_row (l_page, pack, ic, Void)
			end
			results.extend_growing (ui.scroller (l_page), 1)
		end

	spoken: SB_BATCH
		local
			l_text: SB_KOTLIN_TEXT
			l_line: STRING_32
		do
			create l_text.make
			create Result.make ({STRING_32} "")
			if not l_text.is_blank (submitted) then
				across pack.search (submitted) as ic loop
					Result.add (ic.doc.title + {STRING_32} ". " + (create {SB_MARKDOWN}).plain (ic.excerpt), ic.doc.title)
				end
			elseif kind.is_empty then
				across pack.kinds as ic loop
					Result.add (shared.kind_name (ic.kind) + {STRING_32} ", " + ic.n.out.to_string_32 + {STRING_32} ".", shared.kind_name (ic.kind))
				end
			else
				across pack.docs (kind) as ic loop
					l_line := ic.title.twin
					if not l_text.is_blank (ic.status) and not ic.status.same_string ({STRING_32} "unmarked") then
						l_line.append ({STRING_32} ", " + ic.status + {STRING_32} ".")
					else
						l_line.append_character ('.')
					end
					Result.add (l_line, ic.title)
				end
			end
		end

feature {NONE} -- Implementation

	pack: SB_PACK_DB

	shared: SB_PACK_VERSE

	field: PHONE_FIELD

	results: PHONE_COLUMN

	kind, submitted: STRING_32

end
