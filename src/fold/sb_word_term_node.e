note
	description: "A term matched against the original-language words: `field' is strongs, lemma or morph."
	author: "Larry Rix"

class
	SB_WORD_TERM_NODE

inherit
	SB_QUERY_NODE
		redefine
			is_equal
		end

create
	make

feature {NONE} -- Initialization

	make (a_field, a_value: READABLE_STRING_32)
			-- Create the node.
		do
			field := a_field.to_string_32
			value := a_value.to_string_32
		ensure
			field_set: field.same_string (a_field)
			value_set: value.same_string (a_value)
		end

feature -- Access

	field: STRING_32
			-- strongs, lemma or morph.

	value: STRING_32
			-- The value to match in `field'.

feature -- Status

	has_positive: BOOLEAN
			-- <Precursor>
		do
			Result := True
		end

	has_word_term: BOOLEAN
			-- <Precursor>
		do
			Result := True
		end

feature -- Collection

	append_text_matches (a_list: ARRAYED_LIST [SB_MATCH]; a_negated: BOOLEAN)
			-- <Precursor>
		do
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same field, same value?
		do
			Result := field.same_string (a_other.field) and then value.same_string (a_other.value)
		end

feature -- Output

	debug_output: STRING_32
			-- <Precursor>
		do
			create Result.make (32)
			Result.append_string_general ("WordTerm(field=")
			Result.append (field)
			Result.append_string_general (", value=")
			Result.append (value)
			Result.append_string_general (")")
		end

end
