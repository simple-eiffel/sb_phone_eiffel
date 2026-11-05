note
	description: "A typed search with a mistake in it."
	author: "Larry Rix"

class
	SB_QUERY_PARSE_ERROR

inherit
	SB_QUERY_PARSE

create
	make

feature {NONE} -- Initialization

	make (a_message: READABLE_STRING_32; a_position: INTEGER)
			-- Create the outcome.
		require
			message_given: not a_message.is_empty
			position_valid: a_position >= -1
		do
			message := a_message.to_string_32
			position := a_position
		ensure
			message_set: message.same_string (a_message)
			position_set: position = a_position
		end

feature -- Access

	message: STRING_32
			-- What is wrong, for the user.

	position: INTEGER
			-- The 0-based index where the problem is, or -1. Kotlin's string index: UTF-16 units.

feature -- Output

	debug_output: STRING_32
			-- <Precursor>
		do
			create Result.make (64)
			Result.append_string_general ("Error(message=")
			Result.append (message)
			Result.append_string_general (", position=" + position.out + ")")
		end

invariant
	position_valid: position >= -1

end
