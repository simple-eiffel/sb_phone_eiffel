note
	description: "A KJV word the reader picked: its verse, its text, and which occurrence of that word in the verse it is."
	author: "Larry Rix"

class
	SB_WORD_PICK

create
	make

feature {NONE} -- Initialization

	make (a_key: INTEGER; a_word, a_fold: STRING_32; a_nth: INTEGER)
		do
			key := a_key
			word := a_word
			fold := a_fold
			nth := a_nth
		end

feature -- Access

	key: INTEGER

	word, fold: STRING_32

	nth: INTEGER

end
