note
	description: "A folded word, phrase or prefix matched against a version's text."
	author: "Larry Rix"

class
	SB_TEXT_NODE

inherit
	SB_QUERY_NODE
		redefine
			is_equal
		end

create
	make,
	make_negated

feature {NONE} -- Initialization

	make (a_match: SB_MATCH)
			-- Create the node.
		do
			match := a_match
		ensure
			match_set: match = a_match
			not_negated: not is_negated
		end

	make_negated (a_match: SB_MATCH)
			-- Create the node, marked as left out.
		do
			match := a_match
			is_negated := True
		ensure
			match_set: match = a_match
			negated: is_negated
		end

feature -- Access

	match: SB_MATCH
			-- What to match.

feature -- Status

	is_negated: BOOLEAN
			-- Is this match left out?

	has_positive: BOOLEAN
			-- <Precursor>
		do
			Result := True
		end

	has_word_term: BOOLEAN
			-- <Precursor>
		do
			Result := False
		end

feature -- Collection

	append_text_matches (a_list: ARRAYED_LIST [SB_MATCH]; a_negated: BOOLEAN)
			-- <Precursor>
		do
			if not a_negated and not is_negated then
				a_list.extend (match)
			end
		end

feature -- Comparison

	is_equal (a_other: like Current): BOOLEAN
			-- Same match, same negation?
		do
			Result := is_negated = a_other.is_negated and then match ~ a_other.match
		end

feature -- Output

	debug_output: STRING_32
			-- <Precursor>
		do
			create Result.make (64)
			Result.append_string_general ("Text(match=")
			Result.append (match.debug_output)
			Result.append_string_general (", negated=" + is_negated.out.as_lower + ")")
		end

end
