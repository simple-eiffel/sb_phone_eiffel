note
	description: "How the KJV renders a word: an English dictionary form and how many times."
	author: "Larry Rix"

class
	SB_RENDERING

create
	make

feature {NONE} -- Initialization

	make (a_english: STRING_32; a_n: INTEGER)
			-- Create the rendering.
		do
			english := a_english
			n := a_n
		ensure
			english_set: english = a_english
			n_set: n = a_n
		end

feature -- Access

	english: STRING_32
			-- The English word.

	n: INTEGER
			-- How many times.

end
