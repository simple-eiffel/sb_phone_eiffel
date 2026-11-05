note
	description: "A java.lang.Integer or java.lang.Long in JSON."
	author: "Larry Rix"

class
	SB_JSON_INTEGER

inherit
	SB_JSON_VALUE
		redefine
			as_integer,
			as_long
		end

create
	make,
	make_long

feature {NONE} -- Initialization

	make (a_value: INTEGER)
			-- Create a java.lang.Integer.
		do
			value := a_value
		ensure
			value_set: value = a_value
			not_long: not is_long
		end

	make_long (a_value: INTEGER_64)
			-- Create a java.lang.Long.
		do
			value := a_value
			is_long := True
		ensure
			value_set: value = a_value
			long: is_long
		end

feature -- Access

	value: INTEGER_64
			-- The number.

	class_name: STRING_8
			-- <Precursor>
		do
			if is_long then
				Result := "java.lang.Long"
			else
				Result := "java.lang.Integer"
			end
		end

feature -- Status

	is_long: BOOLEAN
			-- Is this a java.lang.Long?

feature -- Conversion

	as_integer: detachable INTEGER_REF
			-- <Precursor>
		do
			Result := value.as_integer_32
		end

	as_long: detachable INTEGER_64_REF
			-- <Precursor>
		do
			Result := value
		end

	java_text: detachable STRING_32
			-- <Precursor>
		do
			create Result.make (20)
			Result.append_string_general (value.out)
		end

feature -- Output

	write_to (a_out: SB_JSON_STRINGER)
			-- <Precursor>
		do
			a_out.put_integer (value)
		end

end
