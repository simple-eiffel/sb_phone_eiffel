note
	description: "A java.lang.Double in JSON."
	author: "Larry Rix"

class
	SB_JSON_DOUBLE

inherit
	SB_JSON_VALUE
		redefine
			as_integer,
			as_long
		end

create
	make

feature {NONE} -- Initialization

	make (a_value: REAL_64)
			-- Create the value.
		do
			value := a_value
		end

feature -- Access

	value: REAL_64
			-- The number.

	class_name: STRING_8 = "java.lang.Double"
			-- <Precursor>

feature -- Conversion

	as_integer: detachable INTEGER_REF
			-- <Precursor>
		do
			Result := numbers.to_int (value)
		end

	as_long: detachable INTEGER_64_REF
			-- <Precursor>
		do
			Result := numbers.to_long (value)
		end

	java_text: detachable STRING_32
			-- <Precursor>
		do
			create Result.make (24)
			Result.append_string_general (numbers.double_text (value))
		end

feature -- Output

	write_to (a_out: SB_JSON_STRINGER)
			-- <Precursor>
		do
			a_out.put_double (value)
		end

end
