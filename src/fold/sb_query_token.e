note
	description: "One token of a typed search."
	author: "Larry Rix"

class
	SB_QUERY_TOKEN

create
	make

feature {NONE} -- Initialization

	make (a_kind: INTEGER; a_text: READABLE_STRING_32; a_position: INTEGER; a_prefix: BOOLEAN)
			-- Create the token.
		require
			valid_kind: a_kind >= Kind_word and a_kind <= Kind_not
			position_valid: a_position >= 0
		do
			kind := a_kind
			text := a_text.to_string_32
			position := a_position
			is_prefix := a_prefix
		ensure
			kind_set: kind = a_kind
			text_set: text.same_string (a_text)
			position_set: position = a_position
			prefix_set: is_prefix = a_prefix
		end

feature -- Kinds

	Kind_word: INTEGER = 1
	Kind_phrase: INTEGER = 2
	Kind_left_parenthesis: INTEGER = 3
	Kind_right_parenthesis: INTEGER = 4
	Kind_or: INTEGER = 5
	Kind_and: INTEGER = 6
	Kind_not: INTEGER = 7
			-- What a token can be.

feature -- Access

	kind: INTEGER
			-- One of the kinds above.

	text: STRING_32
			-- The token's text.

	position: INTEGER
			-- Where it starts, 0-based, in UTF-16 units.

	is_prefix: BOOLEAN
			-- Was it marked as a prefix with a star?

invariant
	position_valid: position >= 0

end
