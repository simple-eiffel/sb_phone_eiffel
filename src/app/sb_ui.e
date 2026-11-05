note
	description: "[
		The building blocks the screens share, each set as Material sets it in the Kotlin app:
		styled text, dividers, text and icon buttons, chips, fields, and the lines that
		recur from screen to screen. Sizes are those of Compose's Material 3.
	]"
	author: "Larry Rix"

class
	SB_UI

create
	make

feature {NONE} -- Initialization

	make (a_controls: PHONE_CONTROLS; a_theme: SB_THEME; a_state: SB_STATE)
		do
			controls := a_controls
			theme := a_theme
			state := a_state
		ensure
			controls_set: controls = a_controls
			theme_set: theme = a_theme
			state_set: state = a_state
		end

feature -- Access

	controls: PHONE_CONTROLS

	theme: SB_THEME

	state: SB_STATE

feature -- Text

	label (a_text: READABLE_STRING_32; a_style: INTEGER; a_color: NATURAL_32): PHONE_LABEL
			-- `a_text' in `a_style'.
		do
			create Result.make (controls, a_text)
			Result.set_rich (theme.styled (a_text, a_style, a_color))
		end

	body (a_text: READABLE_STRING_32): PHONE_LABEL
			-- `a_text' as a Text with no style of its own.
		do
			Result := label (a_text, theme.Body_large, theme.on_background)
		end

	padded (a_text: READABLE_STRING_32; a_style: INTEGER; a_color: NATURAL_32; a_start, a_top, a_end, a_bottom: INTEGER): PHONE_LABEL
			-- `a_text' in `a_style', with space around it.
		do
			Result := label (a_text, a_style, a_color)
			Result.set_padding_each (a_start, a_top, a_end, a_bottom)
		end

	rich (a_row: PHONE_RICH_ROW): PHONE_LABEL
			-- The first block of `a_row'.
		do
			create Result.make (controls, {STRING_32} "")
			Result.set_rich (a_row)
		end

	limited (a_label: PHONE_LABEL; a_lines: INTEGER): PHONE_LABEL
			-- `a_label', cut off after `a_lines'.
		do
			a_label.call_integer ("setMaxLines", a_lines)
			Result := a_label
		end

	source_line (a_text: READABLE_STRING_32): PHONE_LABEL
			-- SourceLine in VerseSheet.kt.
		do
			Result := padded ({STRING_32} "Source: " + a_text, theme.Label_small, theme.on_surface_variant, 20, 12, 20, 12)
		end

	empty (a_message: READABLE_STRING_32): PHONE_LABEL
			-- Empty in Common.kt.
		local
			l_row: PHONE_RICH_ROW
		do
			create l_row.make (0, 0, 0)
			theme.add_style (l_row, theme.Body_medium, theme.on_surface_variant)
			l_row.center_block
			l_row.add_text (a_message)
			Result := rich (l_row)
			Result.call_integer ("setGravity", Center_horizontal)
			Result.set_padding (32, 32)
		end

	lemma_head (a_lemma: SB_LEMMA): PHONE_LABEL
			-- LemmaHead in EnglishScreen.kt.
		local
			l_row: PHONE_RICH_ROW
		do
			create l_row.make (0, 0, 0)
			theme.add_style_in (l_row, theme.Title_large, if a_lemma.is_hebrew then theme.Hebrew else theme.Plain end, theme.on_background)
			l_row.add_text (state.hebrew (a_lemma.headword))
			Result := rich (l_row)
		end

	italic (a_text: READABLE_STRING_32; a_style: INTEGER; a_color: NATURAL_32): PHONE_LABEL
		local
			l_row: PHONE_RICH_ROW
		do
			create l_row.make (0, 0, 0)
			theme.add_style (l_row, a_style, a_color)
			l_row.add_run (a_text, l_row.Italic, 0, 0.0)
			Result := rich (l_row)
		end

	semi_bold (a_text: READABLE_STRING_32; a_style: INTEGER; a_color: NATURAL_32): PHONE_LABEL
		local
			l_row: PHONE_RICH_ROW
		do
			create l_row.make (0, 0, 0)
			theme.add_style (l_row, a_style, a_color)
			l_row.add_run (a_text, l_row.Semi_bold, 0, 0.0)
			Result := rich (l_row)
		end

feature -- Lines and boxes

	divider: PHONE_LABEL
		do
			create Result.make (controls, {STRING_32} "")
			Result.set_surface (theme.outline_variant, 0)
			Result.set_height (1)
		end

	column: PHONE_COLUMN
		do
			create Result.make (controls)
		end

	row: PHONE_ROW
			-- A row with its children centered on one line.
		do
			create Result.make (controls)
			Result.call_integer ("setGravity", Center_vertical)
		end

	top_row: PHONE_ROW
			-- A row with its children at the top.
		do
			create Result.make (controls)
		end

	tappable_column (a_action: PROCEDURE [TUPLE]; a_sides, a_top_and_bottom: INTEGER): PHONE_COLUMN
			-- A column the width of the screen that is tapped as one.
		do
			Result := column
			Result.set_padding (a_sides, a_top_and_bottom)
			Result.set_on_tap (a_action)
		end

	scroller (a_child: PHONE_CONTROL): PHONE_SCROLL
			-- `a_child' scrolling, with no bar showing: Compose draws none.
		do
			create Result.make (controls)
			Result.call_boolean ("setVerticalScrollBarEnabled", False)
			Result.call_integer ("setOverScrollMode", 2)
			Result.set_child (a_child)
		end

feature -- Buttons

	text_button (a_text: READABLE_STRING_32; a_action: PROCEDURE [TUPLE]): PHONE_LABEL
			-- A TextButton.
		do
			Result := label (a_text, theme.Label_large, theme.primary)
			Result.call_integer ("setGravity", Center)
			Result.set_padding (12, 10)
			Result.set_on_tap (a_action)
		end

	icon_button (a_path: READABLE_STRING_8; a_tint: NATURAL_32; a_action: PROCEDURE [TUPLE]): PHONE_ICON
			-- An IconButton: a 24 icon in a 48 square.
		do
			create Result.make (controls, a_path, a_tint)
			Result.set_padding (12, 12)
			Result.set_on_tap (a_action)
		end

	filter_chip (a_text: READABLE_STRING_32; a_selected: BOOLEAN; a_action: PROCEDURE [TUPLE]): PHONE_LABEL
			-- A FilterChip.
		do
			Result := label (a_text, theme.Label_large, if a_selected then theme.on_secondary_container else theme.on_surface_variant end)
			Result.call_integer ("setGravity", Center)
			Result.set_padding (16, 0)
			Result.set_least_height (32)
			if a_selected then
				Result.set_surface (theme.secondary_container, 8)
			else
				Result.set_bordered_surface (0, 8, theme.outline_variant, 1)
			end
			Result.set_on_tap (a_action)
		end

	padded_button (a_text: READABLE_STRING_32; a_action: PROCEDURE [TUPLE]; a_end: INTEGER): PHONE_ROW
			-- A TextButton with space after it.
		do
			Result := top_row
			Result.set_padding_each (0, 0, a_end, 0)
			Result.extend (text_button (a_text, a_action))
		end

	filled_button (a_text: READABLE_STRING_32; a_action: PROCEDURE [TUPLE]): PHONE_LABEL
			-- A Button.
		do
			Result := label (a_text, theme.Label_large, theme.on_primary)
			Result.call_integer ("setGravity", Center)
			Result.set_surface (theme.primary, 20)
			Result.set_padding (24, 10)
			Result.set_on_tap (a_action)
		end

	outlined_button (a_text: READABLE_STRING_32; a_action: PROCEDURE [TUPLE]): PHONE_LABEL
			-- An OutlinedButton.
		do
			Result := label (a_text, theme.Label_large, theme.primary)
			Result.call_integer ("setGravity", Center)
			Result.set_bordered_surface (0, 20, theme.outline, 1)
			Result.set_padding (24, 10)
			Result.set_on_tap (a_action)
		end

	range (a_maximum: INTEGER): PHONE_RANGE
			-- A Slider.
		do
			create Result.make (controls, a_maximum, theme.primary, theme.secondary_container, theme.on_primary)
		end

	on_off (a_on: BOOLEAN): PHONE_ON_OFF
			-- A Switch.
		do
			create Result.make (controls, a_on, theme.primary, theme.on_primary, theme.outline, theme.surface_container_highest)
		end

	field (a_label: READABLE_STRING_32): PHONE_FIELD
			-- An OutlinedTextField.
		do
			create Result.make (controls, a_label, theme.primary, theme.outline, theme.on_surface_variant, theme.on_background)
		end

	check_box (a_on: BOOLEAN): PHONE_ICON
			-- A Checkbox, shown only: the row around it takes the tap.
		local
			l_icons: SB_ICONS
		do
			create l_icons
			create Result.make (controls, if a_on then l_icons.Check_box else l_icons.Check_box_blank end, if a_on then theme.primary else theme.on_surface_variant end)
			Result.set_padding (12, 12)
		end

feature {NONE} -- Implementation

	Center: INTEGER = 17

	Center_vertical: INTEGER = 16

	Center_horizontal: INTEGER = 1

end
