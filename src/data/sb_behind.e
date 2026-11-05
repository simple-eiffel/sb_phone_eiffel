note
	description: "An original word behind one English word, and how many times the KJV translates it that way."
	author: "Larry Rix"

class
	SB_BEHIND

create
	make

feature {NONE} -- Initialization

	make (a_lemma: SB_LEMMA; a_n: INTEGER)
			-- Create the record.
		do
			lemma := a_lemma
			n := a_n
		ensure
			lemma_set: lemma = a_lemma
			n_set: n = a_n
		end

feature -- Access

	lemma: SB_LEMMA
			-- The original word.

	n: INTEGER
			-- How many times.

end
