note
	description: "JSONObject.NULL."
	author: "Larry Rix"

class
	SB_JSON_NULL

inherit
	SB_JSON_VALUE

feature -- Access

	class_name: STRING_8 = "org.json.JSONObject$1"
			-- <Precursor>

feature -- Conversion

	java_text: detachable STRING_32
			-- <Precursor>
		do
			Result := {STRING_32} "null"
		end

feature -- Output

	write_to (a_out: SB_JSON_STRINGER)
			-- <Precursor>
		do
			a_out.put_literal ("null")
		end

end
