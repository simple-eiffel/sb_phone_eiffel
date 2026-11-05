note
	description: "[
		What the app remembers while running and across runs, as AppState.kt has it.
		Pages count from 1 here: Kotlin's page 0 is page 1.
	]"
	author: "Larry Rix"

class
	SB_STATE

create
	make

feature {NONE} -- Initialization

	make (a_bible: SB_APP_DB; a_user: SB_USER_DB)
		do
			bible := a_bible
			user := a_user
			say_verse_numbers := True
			read_on := True
			speech_rate := 1.0
			create back_stack.make (16)
			create forward_stack.make (16)
			create parallel.make (3)
			create search_text.make_empty
			tab := Tab_read
			page := bible.page_of (setting_integer ("book", 43), setting_integer ("chapter", 1))
			version := known_version (user.setting ("version"))
			read_parallel
			is_parallel_on := setting_is ("parallelOn", "1")
			text_scale := setting_real ("textScale", 1.0)
			theme := Theme_dark
			if attached user.setting ("theme") as al_theme then
				if al_theme.same_string ({STRING_32} "System") then
					theme := Theme_system
				elseif al_theme.same_string ({STRING_32} "Light") then
					theme := Theme_light
				end
			end
			say_verse_numbers := setting_is ("sayVerseNumbers", "1")
			read_on := not setting_is ("readOn", "0")
			speech_rate := setting_real ("speechRate", 1.0)
			pointing := {SB_POINTING}.Level_full
			if attached user.setting ("pointing") as al_pointing then
				if al_pointing.same_string ({STRING_32} "Vowels") then
					pointing := {SB_POINTING}.Level_vowels
				elseif al_pointing.same_string ({STRING_32} "Consonants") then
					pointing := {SB_POINTING}.Level_consonants
				end
			end
		ensure
			bible_set: bible = a_bible
			user_set: user = a_user
		end

feature -- Access

	bible: SB_APP_DB

	user: SB_USER_DB

	tab: INTEGER

	page: INTEGER
			-- The chapter showing, from 1.

	focus_key: INTEGER
			-- A verse to scroll to after a jump, or 0.

	flash_key: INTEGER
			-- A verse tinted for a moment after a jump, or 0.

	sheet_key: INTEGER
			-- The verse the sheet shows, or 0.

	read_key: INTEGER
			-- The verse being read aloud, or 0.

	say_verse_numbers: BOOLEAN

	read_on: BOOLEAN
			-- Does reading aloud go on into the next chapter?

	speech_rate: REAL_64

	search_all_versions: BOOLEAN

	version: STRING_32

	parallel: ARRAYED_LIST [STRING_32]

	is_parallel_on: BOOLEAN

	text_scale: REAL_64

	theme: INTEGER

	pointing: INTEGER

	is_focus: BOOLEAN
			-- Focus reading: the text alone, without bars.

	user_revision: INTEGER
			-- Goes up whenever the user's own data changes, so lists read it again.

	search_text: STRING_32

	book_id: INTEGER
		do
			Result := bible.chapters [page].book
		end

	chapter_number: INTEGER
		do
			Result := bible.chapters [page].chapter
		end

	can_go_back: BOOLEAN
		do
			Result := not back_stack.is_empty
		end

	can_go_forward: BOOLEAN
		do
			Result := not forward_stack.is_empty
		end

	base_size: REAL_64
			-- The size of Scripture text.
		do
			Result := 18.0 * text_scale
		end

	shown_versions: ARRAYED_LIST [STRING_32]
			-- The chosen version, then the parallel ones when they are on.
		do
			create Result.make (4)
			Result.extend (version)
			if is_parallel_on then
				across parallel as ic loop
					if not ic.same_string (version) then
						Result.extend (ic)
					end
				end
			end
		ensure
			chosen_first: Result.first.same_string (version)
		end

	hebrew (a_text: READABLE_STRING_32): STRING_32
			-- Hebrew or Aramaic text at the chosen pointing level.
		do
			Result := (create {SB_POINTING}).apply (a_text, pointing)
		end

	add_reading_block (a_row: PHONE_RICH_ROW; a_theme: SB_THEME; a_version: SB_VERSION; a_base: REAL_64; a_above: INTEGER)
			-- A block in a version's reading style: readingStyle in Common.kt.
		do
			if a_version.rtl then
				a_row.add_block (a_theme.Hebrew, a_base * 1.3, a_base * 2.0, a_theme.on_background, True, a_above)
			else
				a_row.add_block (a_theme.Serif, a_base, a_base * 1.5, a_theme.on_background, False, a_above)
			end
		end

feature -- Constants

	Tab_read: INTEGER = 1

	Tab_search: INTEGER = 2

	Tab_library: INTEGER = 3

	Tab_more: INTEGER = 4

	Theme_system: INTEGER = 1

	Theme_dark: INTEGER = 2

	Theme_light: INTEGER = 3

feature -- Moving about

	set_tab (a_tab: INTEGER)
		require
			known: a_tab >= Tab_read and a_tab <= Tab_more
		do
			tab := a_tab
		ensure
			set: tab = a_tab
		end

	set_focus (a_on: BOOLEAN)
		do
			is_focus := a_on
		ensure
			set: is_focus = a_on
		end

	clear_focus_key
		do
			focus_key := 0
		ensure
			cleared: focus_key = 0
		end

	clear_flash
		do
			flash_key := 0
		ensure
			cleared: flash_key = 0
		end

	set_sheet_key (a_key: INTEGER)
		do
			sheet_key := a_key
		ensure
			set: sheet_key = a_key
		end

	set_read_key (a_key: INTEGER)
		do
			read_key := a_key
		ensure
			set: read_key = a_key
		end

	set_search_text (a_text: READABLE_STRING_32)
		do
			create search_text.make_from_string (a_text)
		end

	set_search_all_versions (a_on: BOOLEAN)
		do
			search_all_versions := a_on
		ensure
			set: search_all_versions = a_on
		end

	turn_to (a_page: INTEGER)
			-- Show chapter `a_page', and remember it.
		do
			page := a_page.max (1).min (bible.chapters.count)
			user.set_setting ("book", book_id.out.to_string_32)
			user.set_setting ("chapter", chapter_number.out.to_string_32)
		end

	go_to (a_ref: SB_REF)
			-- A jump: it can be gone back from, unlike a swipe.
		local
			l_from: SB_REF
		do
			l_from := here
			if l_from.book /= a_ref.book or l_from.chapter /= a_ref.chapter then
				back_stack.extend (l_from)
				if back_stack.count > 100 then
					back_stack.start
					back_stack.remove
				end
				forward_stack.wipe_out
			end
			turn_to (bible.page_of (a_ref.book, a_ref.chapter))
			focus_key := if a_ref.verse > 0 then a_ref.key else 0 end
			flash_key := focus_key
			if a_ref.verse > 0 then
				user.record_visit (a_ref.key, version)
			end
			tab := Tab_read
			touched
		end

	go_back
		require
			can: can_go_back
		local
			l_to: SB_REF
		do
			l_to := back_stack.last
			back_stack.finish
			back_stack.remove
			forward_stack.extend (here)
			jump (l_to)
		end

	go_forward
		require
			can: can_go_forward
		local
			l_to: SB_REF
		do
			l_to := forward_stack.last
			forward_stack.finish
			forward_stack.remove
			back_stack.extend (here)
			jump (l_to)
		end

feature -- Choices

	choose_version (a_code: READABLE_STRING_32)
		do
			create version.make_from_string (a_code)
			user.set_setting ("version", version)
		end

	choose_parallel (a_codes: LIST [STRING_32])
		do
			parallel.wipe_out
			across a_codes as ic loop
				if parallel.count < 3 then
					parallel.extend (ic)
				end
			end
			user.set_setting ("parallel", joined (parallel))
		end

	toggle_parallel
		local
			l_codes: ARRAYED_LIST [STRING_32]
		do
			is_parallel_on := not is_parallel_on
			if is_parallel_on and parallel.is_empty then
				create l_codes.make (2)
				if not version.same_string ({STRING_32} "WLC") then
					l_codes.extend ({STRING_32} "WLC")
				end
				if not version.same_string ({STRING_32} "WH") then
					l_codes.extend ({STRING_32} "WH")
				end
				choose_parallel (l_codes)
			end
			user.set_setting ("parallelOn", if is_parallel_on then {STRING_32} "1" else {STRING_32} "0" end)
		end

	choose_text_scale (a_scale: REAL_64)
		do
			text_scale := a_scale
			user.set_setting ("textScale", a_scale.out.to_string_32)
		end

	choose_theme (a_theme: INTEGER)
		do
			theme := a_theme
			user.set_setting ("theme", if a_theme = Theme_system then {STRING_32} "System" elseif a_theme = Theme_light then {STRING_32} "Light" else {STRING_32} "Dark" end)
		end

	choose_pointing (a_level: INTEGER)
		do
			pointing := a_level
			user.set_setting ("pointing", if a_level = {SB_POINTING}.Level_vowels then {STRING_32} "Vowels" elseif a_level = {SB_POINTING}.Level_consonants then {STRING_32} "Consonants" else {STRING_32} "Full" end)
		end

	choose_speech_rate (a_rate: REAL_64)
		do
			speech_rate := a_rate
			user.set_setting ("speechRate", a_rate.out.to_string_32)
		end

	choose_say_verse_numbers (a_on: BOOLEAN)
		do
			say_verse_numbers := a_on
			user.set_setting ("sayVerseNumbers", if a_on then {STRING_32} "1" else {STRING_32} "0" end)
		end

	choose_read_on (a_on: BOOLEAN)
		do
			read_on := a_on
			user.set_setting ("readOn", if a_on then {STRING_32} "1" else {STRING_32} "0" end)
		end

	touched
		do
			user_revision := user_revision + 1
		ensure
			counted: user_revision = old user_revision + 1
		end

feature {NONE} -- Implementation

	back_stack, forward_stack: ARRAYED_LIST [SB_REF]

	here: SB_REF
		do
			create Result.make (book_id, chapter_number, 0, 0)
		end

	jump (a_ref: SB_REF)
		do
			turn_to (bible.page_of (a_ref.book, a_ref.chapter))
			focus_key := if a_ref.verse > 0 then a_ref.key else 0 end
			tab := Tab_read
		end

	setting_integer (a_name: READABLE_STRING_8; a_default: INTEGER): INTEGER
		do
			Result := a_default
			if attached user.setting (a_name) as al_value and then al_value.is_integer then
				Result := al_value.to_integer
			end
		end

	setting_real (a_name: READABLE_STRING_8; a_default: REAL_64): REAL_64
		do
			Result := a_default
			if attached user.setting (a_name) as al_value and then al_value.is_double then
				Result := al_value.to_double
			end
		end

	setting_is (a_name: READABLE_STRING_8; a_value: READABLE_STRING_32): BOOLEAN
		do
			Result := attached user.setting (a_name) as al_value and then al_value.same_string (a_value)
		end

	known_version (a_code: detachable READABLE_STRING_32): STRING_32
			-- `a_code' if the Bible has it, else the KJV.
		do
			Result := {STRING_32} "KJV"
			if attached a_code as al_code then
				across bible.versions as ic loop
					if ic.code.same_string (al_code) then
						create Result.make_from_string (al_code)
					end
				end
			end
		end

	read_parallel
		do
			if attached user.setting ("parallel") as al_text then
				across al_text.split (',') as ic loop
					across bible.versions as jc loop
						if jc.code.same_string (ic) then
							parallel.extend (create {STRING_32}.make_from_string (ic))
						end
					end
				end
			end
		end

	joined (a_codes: LIST [STRING_32]): STRING_32
		do
			create Result.make (16)
			across a_codes as ic loop
				if not Result.is_empty then
					Result.append_character (',')
				end
				Result.append (ic)
			end
		end

invariant
	page_in_range: page >= 1 and page <= bible.chapters.count
	tab_known: tab >= Tab_read and tab <= Tab_more

end
