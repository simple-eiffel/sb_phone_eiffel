note
	description: "A row of tabs: a text and a mark under the open one. PrimaryTabRow, or PrimaryScrollableTabRow when asked."
	author: "Larry Rix"

class
	SB_TABS

create
	make, make_scrollable

feature {NONE} -- Initialization

	make (a_ui: SB_UI; a_names: ARRAY [STRING_32])
			-- Tabs sharing the width. Tabs count from 1.
		do
			ui := a_ui
			create labels.make (a_names.count)
			create marks.make (a_names.count)
			create row.make (a_ui.controls)
			create root.make (a_ui.controls)
			row.set_height (48)
			across a_names as ic loop
				row.extend_growing (cell (ic, @ic.cursor_index, False), 1)
			end
			root.extend (row)
			root.extend (a_ui.divider)
			select_tab (1)
		end

	make_scrollable (a_ui: SB_UI; a_names: ARRAY [STRING_32])
			-- Tabs at their own width, scrolling sideways.
		local
			l_scroll: PHONE_SIDEWAYS_SCROLL
		do
			ui := a_ui
			create labels.make (a_names.count)
			create marks.make (a_names.count)
			create row.make (a_ui.controls)
			create root.make (a_ui.controls)
			row.set_height (48)
			row.set_padding (8, 0)
			across a_names as ic loop
				row.extend (cell (ic, @ic.cursor_index, True))
			end
			create l_scroll.make (a_ui.controls)
			l_scroll.set_child (row)
			root.extend (l_scroll)
			root.extend (a_ui.divider)
			select_tab (1)
		end

feature -- Access

	root: PHONE_COLUMN

	selected: INTEGER

feature -- Element change

	set_on_tab (a_action: PROCEDURE [TUPLE [INTEGER]])
		do
			tapped := a_action
		end

	select_tab (a_tab: INTEGER)
			-- Mark tab `a_tab' as open.
		local
			i: INTEGER
			l_theme: SB_THEME
		do
			l_theme := ui.theme
			selected := a_tab
			from i := 1 until i > labels.count loop
				labels [i].set_rich (l_theme.styled (labels [i].text, l_theme.Title_small, l_theme.primary))
				marks [i].set_surface (if i = a_tab then l_theme.primary else {NATURAL_32} 0 end, 3)
				i := i + 1
			end
		end

feature {NONE} -- Implementation

	cell (a_name: STRING_32; a_index: INTEGER; a_wide: BOOLEAN): PHONE_COLUMN
		local
			l_label, l_mark: PHONE_LABEL
			l_center: PHONE_ROW
		do
			Result := ui.column
			Result.set_height (48)
			create l_label.make (ui.controls, a_name)
			l_label.call_integer ("setGravity", 17)
				-- The mark takes three from the foot, so the text is kept central by three at the head.
			Result.set_padding_each (if a_wide then 16 else 0 end, 3, if a_wide then 16 else 0 end, 0)
			if a_wide then
				Result.set_least_width (90)
			end
			labels.extend (l_label)
			Result.extend_growing (l_label, 1)
				-- The mark is as wide as the text: the same text, unseen, three high.
			l_mark := ui.label (a_name, ui.theme.Title_small, 0)
			l_mark.set_height (3)
			marks.extend (l_mark)
			l_center := ui.top_row
			l_center.call_integer ("setGravity", 1)
			l_center.extend (l_mark)
			Result.extend (l_center)
			Result.set_on_tap (agent cell_tapped (a_index))
		end

	cell_tapped (a_index: INTEGER)
		do
			select_tab (a_index)
			if attached tapped as al_action then
				al_action.call ([a_index])
			end
		end

	ui: SB_UI

	row: PHONE_ROW

	labels, marks: ARRAYED_LIST [PHONE_LABEL]

	tapped: detachable PROCEDURE [TUPLE [INTEGER]]

end
