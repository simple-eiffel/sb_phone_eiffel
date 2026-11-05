note
	description: "A full screen over the tabs and the navigation, with a top bar: OverlayScaffold in Common.kt. Back closes the top one."
	author: "Larry Rix"

deferred class
	SB_OVERLAY

feature {NONE} -- Initialization

	make_overlay (a_shell: SB_SHELL; a_title: READABLE_STRING_32)
		local
			l_icons: SB_ICONS
			l_back: PHONE_ICON
			l_bar: PHONE_ROW
		do
			shell := a_shell
			state := a_shell.state
			theme := a_shell.theme
			controls := a_shell.controls
			ui := a_shell.ui
			create l_icons
			create root.make (controls)
			root.set_surface (theme.background, 0)
			root.set_on_tap (agent a_shell.do_nothing)
			l_bar := ui.row
			l_bar.set_height (64)
			l_bar.set_padding (4, 0)
			l_back := ui.icon_button (l_icons.Back, theme.on_background, agent shell.back)
			l_bar.extend (l_back)
			create title_label.make (controls, {STRING_32} "")
			title_label.set_padding_each (8, 0, 8, 0)
			title_label.call_integer ("setMaxLines", 1)
			l_bar.extend_growing (title_label, 1)
			create actions.make (controls)
			actions.call_integer ("setGravity", 16)
			l_bar.extend (actions)
			root.extend (l_bar)
			create content.make (controls)
			root.extend_growing (content, 1)
			set_title (a_title)
		end

feature -- Access

	root: PHONE_COLUMN

feature -- Status

	handle_back: BOOLEAN
			-- Did this screen take the Back key for itself? It closes if not.
		do
		end

feature -- Closing

	closing
			-- The screen is about to go.
		do
		end

feature -- Refreshing

	refresh
			-- The user's data may have changed under this screen.
		do
		end

feature {NONE} -- Implementation

	set_title (a_title: READABLE_STRING_32)
		do
			title_label.set_rich (theme.styled (a_title, theme.Title_large, theme.on_background))
		end

	shell: SB_SHELL

	state: SB_STATE

	theme: SB_THEME

	ui: SB_UI

	controls: PHONE_CONTROLS

	content: PHONE_COLUMN

	actions: PHONE_ROW
			-- The icons at the end of the top bar.

	title_label: PHONE_LABEL

end
