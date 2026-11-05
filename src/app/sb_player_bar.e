note
	description: "The bar at the bottom while something is being read: what it is, and back, pause, next, stop. PlayerBar in ReadAloud.kt. Built once and updated in place: a button rebuilt under a finger loses the tap."
	author: "Larry Rix"

class
	SB_PLAYER_BAR

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL)
		local
			l_ui: SB_UI
			l_row: PHONE_ROW
			l_text: PHONE_COLUMN
			l_icons: SB_ICONS
			l_speaker: SB_SPEAKER
		do
			l_ui := a_shell.ui
			theme := a_shell.theme
			speaker := a_shell.speaker
			l_speaker := a_shell.speaker
			create l_icons
			create root.make (a_shell.controls)
			root.set_surface (theme.surface_container_high, 0)
			root.extend (l_ui.divider)
			l_row := l_ui.row
			l_row.set_padding_each (16, 2, 4, 2)
			l_text := l_ui.column
			title_label := l_ui.limited (l_ui.label (l_speaker.title, theme.Title_small, theme.on_background), 1)
			line_label := l_ui.limited (l_ui.label ({STRING_32} "", theme.Body_small, theme.on_surface_variant), 2)
			l_text.extend (title_label)
			l_text.extend (line_label)
			l_row.extend_growing (l_text, 1)
			l_row.extend (l_ui.icon_button (l_icons.Skip_previous, theme.on_background, agent l_speaker.skip_previous))
			play_icon := l_ui.icon_button (l_icons.Pause, theme.primary, agent l_speaker.toggle)
			l_row.extend (play_icon)
			l_row.extend (l_ui.icon_button (l_icons.Skip_next, theme.on_background, agent l_speaker.skip_next))
			l_row.extend (l_ui.icon_button (l_icons.Close, theme.on_background, agent l_speaker.stop))
			root.extend (l_row)
			update
		end

feature -- Access

	root: PHONE_COLUMN

feature -- Update

	update
			-- Show where the reading has got to.
		local
			l_line: STRING_32
			l_icons: SB_ICONS
		do
			create l_icons
			title_label.set_rich (theme.styled (speaker.title, theme.Title_small, theme.on_background))
			l_line := if speaker.notice.is_empty then speaker.now_label else speaker.notice end
			line_label.set_rich (theme.styled (l_line, theme.Body_small, if speaker.notice.is_empty then theme.on_surface_variant else theme.error end))
			line_label.set_visible (not l_line.is_empty)
			play_icon.set_path (if speaker.is_playing then l_icons.Pause else l_icons.Play end)
		end

feature {NONE} -- Implementation

	theme: SB_THEME

	speaker: SB_SPEAKER

	title_label, line_label: PHONE_LABEL

	play_icon: PHONE_ICON

end
