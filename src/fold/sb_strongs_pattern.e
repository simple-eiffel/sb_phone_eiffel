note
	description: "[
		QueryParser's two Strong's patterns by hand, with their groups:
			strongsAlone  ^\s*(?:strongs:)?([HhGg])0*(\d{1,5})([a-z]?)\s*$
			strongsTerm   ^(?:strongs:)?([HhGg])0*(\d{1,5})([a-z]?)$   with IGNORE_CASE
		both used as matchEntire.

		Each `try_' feature is one element, trying its choices in the regex's own order, as in
		SB_REF_PATTERN. "H00000" needs the backing off: 0* first takes every zero, \d then
		has none, so 0* gives one back, and the number is H0.
	]"
	author: "Larry Rix"

class
	SB_STRONGS_PATTERN

create
	make

feature {NONE} -- Initialization

	make (a_rules: SB_KOTLIN_RULES)
			-- Create the pattern under `a_rules'.
		do
			rules := a_rules
			create text.make_empty
		ensure
			rules_set: rules = a_rules
			nothing_matched: not is_matched
		end

feature -- Status

	is_matched: BOOLEAN
			-- Did the whole of the last text match?

feature -- Groups

	is_hebrew: BOOLEAN
			-- Was the letter H or h?
		require
			matched: is_matched
		do
			Result := text.code (letter_at) = 0x48 or else text.code (letter_at) = 0x68
		end

	number: STRING_32
			-- The letter in capitals, the digits and any suffix as typed.
		require
			matched: is_matched
		do
			create Result.make (8)
			if is_hebrew then
				Result.append_code (0x48)
			else
				Result.append_code (0x47)
			end
			Result.append (text.substring (digits_from, text_to - 1))
		ensure
			not_empty: not Result.is_empty
		end

feature -- Matching

	match_alone (a_text: READABLE_STRING_32)
			-- Try strongsAlone on the whole of `a_text'.
		local
			p, l_after: INTEGER
		do
			text := a_text.to_string_32
			is_matched := False
			is_term := False
			from
				p := rules.skip_spaces (text, 1)
			until
				p < 1 or is_matched
			loop
				l_after := exact_prefix_end (p)
				if l_after > 0 then
					try_letter (l_after)
				end
				if not is_matched then
					try_letter (p)
				end
				p := p - 1
			end
		end

	match_term (a_text: READABLE_STRING_32)
			-- Try strongsTerm on the whole of `a_text'.
		local
			l_after: INTEGER
		do
			text := a_text.to_string_32
			is_matched := False
			is_term := True
			l_after := rules.strongs_prefix_end (text, 1)
			if l_after > 0 then
				try_letter (l_after)
			end
			if not is_matched then
				try_letter (1)
			end
		end

feature {NONE} -- The regex, element by element

	try_letter (a_at: INTEGER)
			-- ([HhGg])0* at `a_at'.
		local
			l_zeros_end, r: INTEGER
		do
			if a_at <= text.count and then is_strongs_letter (text.code (a_at)) then
				letter_at := a_at
				from
					l_zeros_end := a_at + 1
				until
					l_zeros_end > text.count or else text.code (l_zeros_end) /= 0x30
				loop
					l_zeros_end := l_zeros_end + 1
				end
				from
					r := l_zeros_end
				until
					r <= a_at or is_matched
				loop
					try_digits (r)
					r := r - 1
				end
			end
		end

	try_digits (a_from: INTEGER)
			-- (\d{1,5}) at `a_from'.
		local
			e: INTEGER
		do
			digits_from := a_from
			from
				e := rules.skip_digits (text, a_from, 5)
			until
				e <= a_from or is_matched
			loop
				try_suffix (e)
				e := e - 1
			end
		end

	try_suffix (a_from: INTEGER)
			-- ([a-z]?) at `a_from'.
		do
			if a_from <= text.count and then is_suffix (text.code (a_from)) then
				try_finish (a_from + 1)
			end
			if not is_matched then
				try_finish (a_from)
			end
		end

	try_finish (a_from: INTEGER)
			-- \s*$ at `a_from', or $ alone for strongsTerm.
		do
			text_to := a_from
			if is_term then
				is_matched := a_from = text.count + 1
			else
				is_matched := rules.skip_spaces (text, a_from) = text.count + 1
			end
		end

feature {NONE} -- Implementation

	rules: SB_KOTLIN_RULES
			-- What \s, \d and IGNORE_CASE accept.

	text: STRING_32
			-- The text being matched.

	is_term: BOOLEAN
			-- Is this strongsTerm, rather than strongsAlone?

	letter_at, digits_from, text_to: INTEGER
			-- The letter's index; where the digits start; the index after the digits and suffix.

	is_strongs_letter (a_code: NATURAL_32): BOOLEAN
			-- Does [HhGg] accept `a_code'? IGNORE_CASE adds nothing on either runtime.
		do
			Result := a_code = 0x48 or else a_code = 0x68 or else a_code = 0x47 or else a_code = 0x67
		end

	is_suffix (a_code: NATURAL_32): BOOLEAN
			-- Does [a-z] accept `a_code' here?
		do
			if is_term then
				Result := rules.is_letter_ignoring_case (a_code)
			else
				Result := rules.is_lower_ascii (a_code)
			end
		end

	exact_prefix_end (a_at: INTEGER): INTEGER
			-- The index after "strongs:" at `a_at', case sensitive, or 0.
		do
			if a_at + 7 <= text.count and then text.substring (a_at, a_at + 7).same_string ({STRING_32} "strongs:") then
				Result := a_at + 8
			end
		end

end
