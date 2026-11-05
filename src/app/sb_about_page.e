note
	description: "What this app does and does not do. AboutScreen in MoreScreen.kt."
	author: "Larry Rix"

class
	SB_ABOUT_PAGE

inherit
	SB_OVERLAY

create
	make

feature {NONE} -- Initialization

	make (a_shell: SB_SHELL)
		local
			l_page: PHONE_COLUMN
		do
			make_overlay (a_shell, {STRING_32} "About")
			actions.extend (shell.speak_button ("about", {STRING_32} "About", agent spoken))
			l_page := ui.column
			l_page.set_padding (20, 20)
			l_page.extend (ui.label (Lead, theme.Title_medium, theme.on_background))
			across points as ic loop
				l_page.extend (ui.padded (ic.head, theme.Title_small, theme.primary, 0, 16, 0, 0))
				l_page.extend (ui.label (ic.body, theme.Body_medium, theme.on_background))
			end
			l_page.extend (ui.padded ({STRING_32} "Verse numbers follow the English (KJV) numbering. Where the Hebrew numbering differs, the Hebrew number is shown in brackets.", theme.Body_small, theme.on_surface_variant, 0, 24, 0, 0))
			content.extend_growing (ui.scroller (l_page), 1)
		end

feature {NONE} -- Implementation

	spoken: SB_BATCH
		do
			create Result.make ({STRING_32} "")
			Result.add (Lead, {STRING_32} "About")
			across points as ic loop
				Result.add (ic.head + {STRING_32} " " + ic.body, ic.head)
			end
		end

	Lead: STRING_32 = "A free Bible-study app that checks what is said about the Bible against the Bible itself."

	points: ARRAY [TUPLE [head, body: STRING_32]]
		do
			Result := <<
				[{STRING_32} "Every fact shows its source.", {STRING_32} "Each word tag, dictionary entry and cross-reference names where it came from and its license."],
				[{STRING_32} "No network.", {STRING_32} "This app has no permission to use the internet. It cannot send anything anywhere."],
				[{STRING_32} "No ads, accounts or tracking.", {STRING_32} "Nothing to sign in to, nothing to buy, nothing counted."],
				[{STRING_32} "No AI.", {STRING_32} "Everything shown was built ahead of time from sourced data."],
				[{STRING_32} "Your notes stay yours.", {STRING_32} "They live only on this phone. Export them to a file whenever you like."],
				[{STRING_32} "Public texts only.", {STRING_32} "Only texts whose licenses allow sharing are included, and each is credited."],
				[{STRING_32} "Read aloud.", {STRING_32} "Uses the phone's own text-to-speech voices, and only voices installed on the phone. The words go to the phone's speech engine and nowhere else."]
			>>
		end

end
