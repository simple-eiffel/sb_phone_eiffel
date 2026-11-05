note
	description: "A typed reference naming a book ambiguously: a choice to offer, never a guess."
	author: "Larry Rix"

class
	SB_REF_PARSE_CHOICE

inherit
	SB_REF_PARSE

create
	make

feature {NONE} -- Initialization

	make (a_refs: ARRAYED_LIST [SB_REF])
			-- Create the outcome.
		require
			a_real_choice: a_refs.count >= 2
		do
			refs := a_refs
		ensure
			refs_set: refs = a_refs
		end

feature -- Access

	refs: ARRAYED_LIST [SB_REF]
			-- The readings, in canon order.

feature -- Output

	debug_output: STRING_32
			-- <Precursor>
		local
			i: INTEGER
		do
			create Result.make (128)
			Result.append_string_general ("Choice(refs=[")
			from
				i := 1
			until
				i > refs.count
			loop
				if i > 1 then
					Result.append_string_general (", ")
				end
				Result.append (refs [i].debug_output)
				i := i + 1
			end
			Result.append_string_general ("])")
		end

end
