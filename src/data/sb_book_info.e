note
	description: "One book of the canon as app.db holds it."
	author: "Larry Rix"

class
	SB_BOOK_INFO

create
	make

feature {NONE} -- Initialization

	make (a_id: INTEGER; a_code, a_name, a_short: STRING_32; a_chapters: INTEGER)
			-- Create the book.
		do
			id := a_id
			code := a_code
			name := a_name
			short := a_short
			chapters := a_chapters
		ensure
			id_set: id = a_id
			code_set: code = a_code
			name_set: name = a_name
			short_set: short = a_short
			chapters_set: chapters = a_chapters
		end

feature -- Access

	id: INTEGER
			-- 1 to 66, in canon order.

	code, name, short: STRING_32
			-- Its names.

	chapters: INTEGER
			-- How many chapters it has.

end
