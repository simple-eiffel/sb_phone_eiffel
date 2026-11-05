note
	description: "One Bible version in app.db."
	author: "Larry Rix"

class
	SB_VERSION

create
	make

feature {NONE} -- Initialization

	make (a_code, a_name, a_language: STRING_32; a_rtl: BOOLEAN; a_versification, a_coverage: STRING_32; a_first_id, a_last_id: INTEGER_64)
			-- Create the version.
		do
			code := a_code
			name := a_name
			language := a_language
			rtl := a_rtl
			versification := a_versification
			coverage := a_coverage
			first_id := a_first_id
			last_id := a_last_id
		ensure
			code_set: code = a_code
			name_set: name = a_name
			language_set: language = a_language
			rtl_set: rtl = a_rtl
			versification_set: versification = a_versification
			coverage_set: coverage = a_coverage
			first_id_set: first_id = a_first_id
			last_id_set: last_id = a_last_id
		end

feature -- Access

	code, name, language: STRING_32
			-- What identifies it.

	rtl: BOOLEAN
			-- Is its text written right to left?

	versification, coverage: STRING_32
			-- Its numbering and what it holds.

	first_id, last_id: INTEGER_64
			-- The verse ids of this version run from `first_id' to `last_id'.

end
