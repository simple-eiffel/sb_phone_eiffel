note
	description: "One book of the 66-book canon. `id' follows canon order, 1 = Genesis ... 66 = Revelation."
	author: "Larry Rix"

class
	SB_BOOK

create
	make

feature {NONE} -- Initialization

	make (a_id: INTEGER; a_code, a_name, a_short: READABLE_STRING_8; a_aliases: ARRAY [STRING_8])
			-- Create the book.
		require
			valid_id: a_id >= 1 and a_id <= 66
			code_given: not a_code.is_empty
			name_given: not a_name.is_empty
			short_given: not a_short.is_empty
		local
			i: INTEGER
		do
			id := a_id
			code := a_code.to_string_32
			name := a_name.to_string_32
			short := a_short.to_string_32
			create aliases.make (a_aliases.count)
			from
				i := a_aliases.lower
			until
				i > a_aliases.upper
			loop
				aliases.extend (a_aliases [i].to_string_32)
				i := i + 1
			end
		ensure
			id_set: id = a_id
			aliases_kept: aliases.count = a_aliases.count
		end

feature -- Access

	id: INTEGER
			-- Canon order, from 1.

	code: STRING_32
			-- The three-character code, such as "GEN".

	name: STRING_32
			-- The full name, such as "Genesis".

	short: STRING_32
			-- The short name, such as "Gen".

	aliases: ARRAYED_LIST [STRING_32]
			-- Other ways of typing the book.

feature -- Status

	is_old_testament: BOOLEAN
			-- Is this one of the first 39?
		do
			Result := id <= 39
		end

feature -- Output

	debug_output: STRING_32
			-- The same text as Kotlin's toString on the data class.
		local
			i: INTEGER
		do
			create Result.make (64)
			Result.append_string_general ("Book(id=")
			Result.append_string_general (id.out)
			Result.append_string_general (", code=")
			Result.append (code)
			Result.append_string_general (", name=")
			Result.append (name)
			Result.append_string_general (", short=")
			Result.append (short)
			Result.append_string_general (", aliases=[")
			from
				i := 1
			until
				i > aliases.count
			loop
				if i > 1 then
					Result.append_string_general (", ")
				end
				Result.append (aliases [i])
				i := i + 1
			end
			Result.append_string_general ("])")
		end

invariant
	valid_id: id >= 1 and id <= 66

end
