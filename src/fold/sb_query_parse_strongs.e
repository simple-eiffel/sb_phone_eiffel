note
	description: "A typed search that is a Strong's number alone: a word lookup, not a verse search."
	author: "Larry Rix"

class
	SB_QUERY_PARSE_STRONGS

inherit
	SB_QUERY_PARSE

create
	make

feature {NONE} -- Initialization

	make (a_language, a_number: READABLE_STRING_32)
			-- Create the outcome.
		do
			language := a_language.to_string_32
			number := a_number.to_string_32
		ensure
			language_set: language.same_string (a_language)
			number_set: number.same_string (a_number)
		end

feature -- Access

	language: STRING_32
			-- hbo or grc.

	number: STRING_32
			-- The number, such as H7225: letter in capitals, leading zeros gone.

feature -- Output

	debug_output: STRING_32
			-- <Precursor>
		do
			create Result.make (32)
			Result.append_string_general ("Strongs(language=")
			Result.append (language)
			Result.append_string_general (", number=")
			Result.append (number)
			Result.append_string_general (")")
		end

end
