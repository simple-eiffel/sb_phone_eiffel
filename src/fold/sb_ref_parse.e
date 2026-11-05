note
	description: "The outcome of reading a typed reference: one reading, a choice to offer, or nothing."
	author: "Larry Rix"

deferred class
	SB_REF_PARSE

feature -- Output

	debug_output: STRING_32
			-- The same text as Kotlin's toString on the data class.
		deferred
		end

end
