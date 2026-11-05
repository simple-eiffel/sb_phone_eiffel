note
	description: "A cross-reference from a verse."
	author: "Larry Rix"

class
	SB_XREF

create
	make

feature {NONE} -- Initialization

	make (a_to_key, a_to_end, a_votes: INTEGER)
			-- Create the cross-reference.
		do
			to_key := a_to_key
			to_end := a_to_end
			votes := a_votes
		ensure
			to_key_set: to_key = a_to_key
			to_end_set: to_end = a_to_end
			votes_set: votes = a_votes
		end

feature -- Access

	to_key, to_end: INTEGER
			-- The verse it points to, and the key of the last verse of a range.

	votes: INTEGER
			-- How many readers proposed it.

	ref: SB_REF
			-- The address it points to.
		local
			l_start: SB_REF
		do
			create l_start.make_from_key (to_key)
			if to_end > to_key then
				create Result.make (l_start.book, l_start.chapter, l_start.verse, to_end \\ 1000)
			else
				Result := l_start
			end
		end

end
