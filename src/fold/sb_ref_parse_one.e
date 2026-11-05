note
	description: "A typed reference with exactly one reading."
	author: "Larry Rix"

class
	SB_REF_PARSE_ONE

inherit
	SB_REF_PARSE

create
	make

feature {NONE} -- Initialization

	make (a_ref: SB_REF)
			-- Create the outcome.
		do
			ref := a_ref
		ensure
			ref_set: ref = a_ref
		end

feature -- Access

	ref: SB_REF
			-- The reading.

feature -- Output

	debug_output: STRING_32
			-- <Precursor>
		do
			create Result.make (64)
			Result.append_string_general ("One(ref=")
			Result.append (ref.debug_output)
			Result.append_string_general (")")
		end

end
