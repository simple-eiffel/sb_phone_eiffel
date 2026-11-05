note
	description: "One document in a pack: a commentary section, a framework, an essay, a book chapter."
	author: "Larry Rix"

class
	SB_PACK_DOC

create
	make

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_kind, a_title, a_collection, a_status, a_path: STRING_32; a_words: INTEGER)
			-- Create the document.
		do
			id := a_id
			kind := a_kind
			title := a_title
			collection := a_collection
			status := a_status
			path := a_path
			words := a_words
		ensure
			id_set: id = a_id
			kind_set: kind = a_kind
			title_set: title = a_title
			collection_set: collection = a_collection
			status_set: status = a_status
			path_set: path = a_path
			words_set: words = a_words
		end

feature -- Access

	id: INTEGER_64
			-- The row id.

	kind, title, collection, status, path: STRING_32
			-- What it is.

	words: INTEGER
			-- How long it is.

end
