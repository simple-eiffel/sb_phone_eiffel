note
	description: "The outcome of reading a typed search: a query, a Strong's lookup or a mistake."
	author: "Larry Rix"

deferred class
	SB_QUERY_PARSE

feature -- Output

	debug_output: STRING_32
			-- The same text as Kotlin's toString on the data class.
		deferred
		end

end
