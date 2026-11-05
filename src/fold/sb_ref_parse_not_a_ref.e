note
	description: "Typed text that is not a reference."
	author: "Larry Rix"

class
	SB_REF_PARSE_NOT_A_REF

inherit
	SB_REF_PARSE

feature -- Output

	debug_output: STRING_32
			-- <Precursor>
		do
			create Result.make_from_string_general ("NotARef")
		end

end
