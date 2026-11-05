note
	description: "A batch to read, and how to get the batch after it (the next chapter), if any."
	author: "Larry Rix"

class
	SB_BATCH

create
	make, make_next

feature {NONE} -- Initialization

	make (a_title: READABLE_STRING_32)
		do
			create title.make_from_string (a_title)
			create items.make (32)
		end

	make_next (a_title: READABLE_STRING_32; a_next: FUNCTION [SB_BATCH])
		do
			make (a_title)
			next := a_next
		end

feature -- Access

	title: STRING_32

	items: ARRAYED_LIST [SB_SPEECH]

	next: detachable FUNCTION [SB_BATCH]

feature -- Element change

	set_title (a_title: READABLE_STRING_32)
		do
			create title.make_from_string (a_title)
		end

	set_next (a_next: FUNCTION [SB_BATCH])
		do
			next := a_next
		end

	add (a_text, a_label: READABLE_STRING_32)
			-- Add `a_text' in the English voice.
		do
			items.extend (create {SB_SPEECH}.make (a_text, a_label))
		end

	add_item (a_speech: SB_SPEECH)
		do
			items.extend (a_speech)
		end

end
