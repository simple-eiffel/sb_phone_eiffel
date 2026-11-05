note
	description: "The app's colors in its dark and light themes, as Theme.kt has them, and the type sizes the screens share."
	author: "Larry Rix"

class
	SB_THEME

create
	make

feature {NONE} -- Initialization

	make (a_dark: BOOLEAN)
		do
			is_dark := a_dark
		ensure
			set: is_dark = a_dark
		end

feature -- Access

	is_dark: BOOLEAN

	primary: NATURAL_32
		do
			Result := if is_dark then 0xFFE2C27A else 0xFF7A5A12 end
		end

	on_primary: NATURAL_32
		do
			Result := if is_dark then 0xFF2A2005 else 0xFFFFFFFF end
		end

	secondary: NATURAL_32
		do
			Result := if is_dark then 0xFF9DB8D9 else 0xFF34557A end
		end

	secondary_container: NATURAL_32
		do
			Result := if is_dark then 0xFF3A3424 else 0xFFEFE2C0 end
		end

	on_secondary_container: NATURAL_32
		do
			Result := if is_dark then 0xFFE2C27A else 0xFF4A3608 end
		end

	background: NATURAL_32
		do
			Result := if is_dark then 0xFF15171C else 0xFFFBF8F1 end
		end

	on_background: NATURAL_32
		do
			Result := if is_dark then 0xFFE6E2D9 else 0xFF1E1C18 end
		end

	on_surface_variant: NATURAL_32
		do
			Result := if is_dark then 0xFFB9B4A8 else 0xFF55504A end
		end

	surface_container: NATURAL_32
		do
			Result := if is_dark then 0xFF1D2028 else 0xFFF3EEE3 end
		end

	surface_container_high: NATURAL_32
		do
			Result := if is_dark then 0xFF242833 else 0xFFEDE7DA end
		end

	surface_container_highest: NATURAL_32
			-- Material's own.
		do
			Result := if is_dark then 0xFF36343B else 0xFFE6E0E9 end
		end

	outline: NATURAL_32
		do
			Result := if is_dark then 0xFF5B606C else 0xFF8E887D end
		end

	surface_container_low: NATURAL_32
		do
			Result := if is_dark then 0xFF1A1C22 else 0xFFF7F3EA end
		end

	outline_variant: NATURAL_32
			-- Dividers: Material's own, which the Kotlin theme leaves as it is.
		do
			Result := if is_dark then 0xFF49454F else 0xFFCAC4D0 end
		end

	error: NATURAL_32
			-- Material's own.
		do
			Result := if is_dark then 0xFFF2B8B5 else 0xFFB3261E end
		end

	on_error: NATURAL_32
			-- Material's own.
		do
			Result := if is_dark then 0xFF601410 else 0xFFFFFFFF end
		end

	highlight_names: ARRAY [STRING_32]
		do
			Result := <<{STRING_32} "Gold", {STRING_32} "Green", {STRING_32} "Blue", {STRING_32} "Rose">>
		end

	highlight (a_index: INTEGER): NATURAL_32
			-- Highlight colors 0 to 3: Gold, Green, Blue, Rose.
		require
			known: a_index >= 0 and a_index <= 3
		do
			inspect a_index
			when 0 then
				Result := if is_dark then 0x55D8B34A else 0x66F2D27A end
			when 1 then
				Result := if is_dark then 0x5543A36B else 0x6696D7AE end
			when 2 then
				Result := if is_dark then 0x554F86C6 else 0x669DC3EC end
			else
				Result := if is_dark then 0x55C65F7E else 0x66EFA9BD end
			end
		end

	with_alpha (a_color: NATURAL_32; a_alpha: NATURAL_32): NATURAL_32
			-- `a_color' at `a_alpha', from 0 to 255.
		require
			alpha_valid: a_alpha <= 255
		do
			Result := (a_color & 0x00FFFFFF) | (a_alpha |<< 24)
		end

feature -- Text styles

	Display_small: INTEGER = 11

	Headline_medium: INTEGER = 12

	Headline_small: INTEGER = 1

	Title_large: INTEGER = 2

	Title_medium: INTEGER = 3

	Title_small: INTEGER = 4

	Body_large: INTEGER = 5

	Body_medium: INTEGER = 6

	Body_small: INTEGER = 7

	Label_large: INTEGER = 8

	Label_medium: INTEGER = 9

	Label_small: INTEGER = 10

	add_style (a_row: PHONE_RICH_ROW; a_style: INTEGER; a_color: NATURAL_32)
			-- Start a block in Material's `a_style'.
		require
			known: a_style >= Headline_small and a_style <= Headline_medium
		do
			add_style_in (a_row, a_style, if a_style = Title_medium or a_style = Title_small or a_style >= Label_large and a_style <= Label_small then Medium else Plain end, a_color)
		end

	add_style_in (a_row: PHONE_RICH_ROW; a_style: INTEGER; a_font: READABLE_STRING_8; a_color: NATURAL_32)
			-- Start a block in the sizes of `a_style', in `a_font'.
		require
			known: a_style >= Headline_small and a_style <= Headline_medium
		do
			inspect a_style
			when Display_small then
				a_row.add_material_block (a_font, 36, 44, 0, a_color, 0)
			when Headline_medium then
				a_row.add_material_block (a_font, 28, 36, 0, a_color, 0)
			when Headline_small then
				a_row.add_material_block (a_font, 24, 32, 0, a_color, 0)
			when Title_large then
				a_row.add_material_block (a_font, 22, 28, 0, a_color, 0)
			when Title_medium then
				a_row.add_material_block (a_font, 16, 24, 0.15, a_color, 0)
			when Title_small then
				a_row.add_material_block (a_font, 14, 20, 0.1, a_color, 0)
			when Body_large then
				a_row.add_material_block (a_font, 16, 24, 0.5, a_color, 0)
			when Body_medium then
				a_row.add_material_block (a_font, 14, 20, 0.25, a_color, 0)
			when Body_small then
				a_row.add_material_block (a_font, 12, 16, 0.4, a_color, 0)
			when Label_large then
				a_row.add_material_block (a_font, 14, 20, 0.1, a_color, 0)
			when Label_medium then
				a_row.add_material_block (a_font, 12, 16, 0.5, a_color, 0)
			else
				a_row.add_material_block (a_font, 11, 16, 0.5, a_color, 0)
			end
		end

	styled (a_text: READABLE_STRING_32; a_style: INTEGER; a_color: NATURAL_32): PHONE_RICH_ROW
			-- `a_text' alone in `a_style', ready for a label.
		do
			create Result.make (0, 0, 0)
			add_style (Result, a_style, a_color)
			Result.add_text (a_text)
		end

feature -- Fonts

	Serif: STRING_8 = "serif"

	Hebrew: STRING_8 = "ezra_sil.ttf"

	Medium: STRING_8 = "sans-serif-medium"

	Plain: STRING_8 = ""

	Mono: STRING_8 = "monospace"

end
