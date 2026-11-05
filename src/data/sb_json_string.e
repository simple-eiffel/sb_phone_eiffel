note
	description: "A java.lang.String in JSON."
	author: "Larry Rix"

class
	SB_JSON_STRING

inherit
	SB_JSON_VALUE
		redefine
			as_integer,
			as_long,
			as_boolean
		end

create
	make

feature {NONE} -- Initialization

	make (a_text: READABLE_STRING_32)
			-- Create the value.
		do
			text := a_text.to_string_32
		ensure
			text_set: text.same_string (a_text)
		end

feature -- Access

	text: STRING_32
			-- The string.

	class_name: STRING_8 = "java.lang.String"
			-- <Precursor>

feature -- Conversion

	as_integer: detachable INTEGER_REF
			-- <Precursor>
		do
			if attached numbers.parsed_double (text) as al_value then
				Result := numbers.to_int (al_value.item)
			end
		end

	as_long: detachable INTEGER_64_REF
			-- <Precursor>
		do
			if attached numbers.parsed_double (text) as al_value then
				Result := numbers.to_long (al_value.item)
			end
		end

	as_boolean: detachable BOOLEAN_REF
			-- <Precursor>
		do
			if numbers.text_rules.equal_ignoring_case (text, {STRING_32} "true") then
				Result := True
			elseif numbers.text_rules.equal_ignoring_case (text, {STRING_32} "false") then
				Result := False
			end
		end

	java_text: detachable STRING_32
			-- <Precursor>
		do
			Result := text
		end

feature -- Output

	write_to (a_out: SB_JSON_STRINGER)
			-- <Precursor>
		do
			a_out.put_string (text)
		end

end
