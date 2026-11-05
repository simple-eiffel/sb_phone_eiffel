note
	description: "A search or verse hit in a pack, with a short excerpt."
	author: "Larry Rix"

class
	SB_PACK_HIT

create
	make

feature {NONE} -- Initialization

	make (a_doc: SB_PACK_DOC; a_excerpt: STRING_32)
			-- Create the hit.
		do
			doc := a_doc
			excerpt := a_excerpt
		ensure
			doc_set: doc = a_doc
			excerpt_set: excerpt = a_excerpt
		end

feature -- Access

	doc: SB_PACK_DOC
			-- The document.

	excerpt: STRING_32
			-- The words around the hit.

end
