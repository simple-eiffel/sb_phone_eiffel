note
	description: "A Bible reference found in running text."
	author: "Larry Rix"

class
	SB_REF_FOUND

create
	make

feature {NONE} -- Initialization

	make (a_first, a_last: INTEGER; a_text: STRING_32; a_ref: SB_REF)
			-- Create the finding.
		require
			range_in_order: a_first >= 0 and a_first <= a_last
			text_given: not a_text.is_empty
		do
			first := a_first
			last := a_last
			text := a_text
			ref := a_ref
		ensure
			first_set: first = a_first
			last_set: last = a_last
			text_set: text = a_text
			ref_set: ref = a_ref
		end

feature -- Access

	first, last: INTEGER
			-- Kotlin's IntRange: 0-based, last inclusive, counted in UTF-16 units, which is also how
			-- Android's text views count.

	text: STRING_32
			-- The matched text.

	ref: SB_REF
			-- What it reads as.

feature -- Output

	debug_output: STRING_32
			-- The same text as Kotlin's toString on the data class.
		do
			create Result.make (64)
			Result.append_string_general ("Found(range=" + first.out + ".." + last.out + ", text=")
			Result.append (text)
			Result.append_string_general (", ref=")
			Result.append (ref.debug_output)
			Result.append_string_general (")")
		end

invariant
	range_in_order: first >= 0 and first <= last

end
