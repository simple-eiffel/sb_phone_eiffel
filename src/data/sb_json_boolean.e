note
	description: "A java.lang.Boolean in JSON."
	author: "Larry Rix"

class
	SB_JSON_BOOLEAN

inherit
	SB_JSON_VALUE
		redefine
			as_boolean
		end

create
	make

feature {NONE} -- Initialization

	make (a_value: BOOLEAN)
			-- Create the value.
		do
			value := a_value
		ensure
			value_set: value = a_value
		end

feature -- Access

	value: BOOLEAN
			-- The truth value.

	class_name: STRING_8 = "java.lang.Boolean"
			-- <Precursor>

feature -- Conversion

	as_boolean: detachable BOOLEAN_REF
			-- <Precursor>
		do
			Result := value
		end

	java_text: detachable STRING_32
			-- <Precursor>
		do
			if value then
				Result := {STRING_32} "true"
			else
				Result := {STRING_32} "false"
			end
		end

feature -- Output

	write_to (a_out: SB_JSON_STRINGER)
			-- <Precursor>
		do
			if value then
				a_out.put_literal ("true")
			else
				a_out.put_literal ("false")
			end
		end

end
