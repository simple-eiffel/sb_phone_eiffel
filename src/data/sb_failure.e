note
	description: "[
		Raises what Kotlin and org.json throw, keeping the message where the caller can read it
		whole: an exception description goes through the runtime's string handling.
	]"
	author: "Larry Rix"

class
	SB_FAILURE

feature -- Access

	last_message: STRING_32
			-- The message of the last failure.
		do
			Result := message_cell.item
		end

feature -- Raising

	fail (a_message: READABLE_STRING_32)
			-- Raise an exception for `a_message'.
		local
			l_exception: DEVELOPER_EXCEPTION
		do
			message_cell.put (a_message.to_string_32)
			create l_exception
			l_exception.set_description (a_message)
			l_exception.raise
		end

feature {NONE} -- Implementation

	message_cell: CELL [STRING_32]
			-- Holds `last_message'.
		once
			create Result.put (create {STRING_32}.make_empty)
		end

end
