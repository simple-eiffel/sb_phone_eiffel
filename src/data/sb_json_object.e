note
	description: "[
		org.json.JSONObject: names in the order first put, a later put replacing the value. Names
		are compared one by one; they may hold any text, so they are never hashed as STRING_32.
	]"
	author: "Larry Rix"

class
	SB_JSON_OBJECT

inherit
	SB_JSON_VALUE

	SB_FAILURE

create
	make

feature {NONE} -- Initialization

	make
			-- Create an empty object.
		do
			create names.make (8)
			create values.make (8)
		end

feature -- Access

	names: ARRAYED_LIST [STRING_32]
			-- The names, in order.

	values: ARRAYED_LIST [SB_JSON_VALUE]
			-- The value of each name.

	class_name: STRING_8 = "org.json.JSONObject"
			-- <Precursor>

	opt (a_name: READABLE_STRING_GENERAL): detachable SB_JSON_VALUE
			-- JSONObject.opt.
		local
			i: INTEGER
		do
			from
				i := 1
			until
				i > names.count or Result /= Void
			loop
				if names [i].same_string_general (a_name) then
					Result := values [i]
				end
				i := i + 1
			end
		end

	item (a_name: READABLE_STRING_GENERAL): SB_JSON_VALUE
			-- JSONObject.get.
		do
			if attached opt (a_name) as al_value then
				Result := al_value
			else
				fail ({STRING_32} "No value for " + a_name.to_string_32)
				create {SB_JSON_NULL} Result
			end
		end

	integer_at (a_name: READABLE_STRING_GENERAL): INTEGER
			-- JSONObject.getInt.
		local
			l_value: SB_JSON_VALUE
		do
			l_value := item (a_name)
			if attached l_value.as_integer as al_integer then
				Result := al_integer.item
			else
				fail (mismatch (a_name, l_value, "int"))
			end
		end

	long_at (a_name: READABLE_STRING_GENERAL): INTEGER_64
			-- JSONObject.getLong.
		local
			l_value: SB_JSON_VALUE
		do
			l_value := item (a_name)
			if attached l_value.as_long as al_long then
				Result := al_long.item
			else
				fail (mismatch (a_name, l_value, "long"))
			end
		end

	string_at (a_name: READABLE_STRING_GENERAL): STRING_32
			-- JSONObject.getString.
		local
			l_value: SB_JSON_VALUE
		do
			l_value := item (a_name)
			if attached l_value.java_text as al_text then
				Result := al_text
			else
				fail (mismatch (a_name, l_value, "String"))
				create Result.make_empty
			end
		end

	opt_integer (a_name: READABLE_STRING_GENERAL): INTEGER
			-- JSONObject.optInt.
		do
			if attached opt (a_name) as al_value and then attached al_value.as_integer as al_integer then
				Result := al_integer.item
			end
		end

	opt_long (a_name: READABLE_STRING_GENERAL; a_fallback: INTEGER_64): INTEGER_64
			-- JSONObject.optLong.
		do
			Result := a_fallback
			if attached opt (a_name) as al_value and then attached al_value.as_long as al_long then
				Result := al_long.item
			end
		end

	opt_boolean (a_name: READABLE_STRING_GENERAL): BOOLEAN
			-- JSONObject.optBoolean.
		do
			if attached opt (a_name) as al_value and then attached al_value.as_boolean as al_boolean then
				Result := al_boolean.item
			end
		end

	opt_string (a_name: READABLE_STRING_GENERAL; a_fallback: READABLE_STRING_32): STRING_32
			-- JSONObject.optString.
		do
			if attached opt (a_name) as al_value and then attached al_value.java_text as al_text then
				Result := al_text
			else
				Result := a_fallback.to_string_32
			end
		end

	opt_array (a_name: READABLE_STRING_GENERAL): detachable SB_JSON_ARRAY
			-- JSONObject.optJSONArray.
		do
			if attached {SB_JSON_ARRAY} opt (a_name) as al_array then
				Result := al_array
			end
		end

feature -- Element change

	put (a_name: READABLE_STRING_GENERAL; a_value: SB_JSON_VALUE)
			-- JSONObject.put.
		local
			i: INTEGER
			l_done: BOOLEAN
		do
			if attached {SB_JSON_DOUBLE} a_value as al_double and then not numbers.is_finite (al_double.value) then
				fail ({STRING_32} "Forbidden numeric value: " + numbers.double_text (al_double.value).to_string_32)
			end
			from
				i := 1
			until
				i > names.count or l_done
			loop
				if names [i].same_string_general (a_name) then
					values [i] := a_value
					l_done := True
				end
				i := i + 1
			end
			if not l_done then
				names.extend (a_name.to_string_32)
				values.extend (a_value)
			end
		end

	put_string (a_name: READABLE_STRING_GENERAL; a_value: READABLE_STRING_32)
			-- Put a string.
		do
			put (a_name, create {SB_JSON_STRING}.make (a_value))
		end

	put_integer (a_name: READABLE_STRING_GENERAL; a_value: INTEGER)
			-- Put a java.lang.Integer.
		do
			put (a_name, create {SB_JSON_INTEGER}.make (a_value))
		end

	put_long (a_name: READABLE_STRING_GENERAL; a_value: INTEGER_64)
			-- Put a java.lang.Long.
		do
			put (a_name, create {SB_JSON_INTEGER}.make_long (a_value))
		end

	put_boolean (a_name: READABLE_STRING_GENERAL; a_value: BOOLEAN)
			-- Put a boolean.
		do
			put (a_name, create {SB_JSON_BOOLEAN}.make (a_value))
		end

feature -- Conversion

	java_text: detachable STRING_32
			-- <Precursor>
		local
			l_out: SB_JSON_STRINGER
		do
			create l_out.make_compact
			write_to (l_out)
			if not l_out.has_failed then
				Result := l_out.text
			end
		end

	indented_text (a_spaces: INTEGER): STRING_32
			-- JSONObject.toString (a_spaces).
		local
			l_out: SB_JSON_STRINGER
		do
			create l_out.make_indented (a_spaces)
			write_to (l_out)
			Result := l_out.text
		end

feature -- Output

	write_to (a_out: SB_JSON_STRINGER)
			-- <Precursor>
		local
			i: INTEGER
		do
			a_out.begin_object
			from
				i := 1
			until
				i > names.count
			loop
				a_out.put_key (names [i])
				values [i].write_to (a_out)
				i := i + 1
			end
			a_out.end_object
		end

feature {NONE} -- Implementation

	mismatch (a_name: READABLE_STRING_GENERAL; a_actual: SB_JSON_VALUE; a_type: READABLE_STRING_8): STRING_32
			-- JSON.typeMismatch for a name.
		do
			create Result.make (64)
			Result.append_string_general ("Value ")
			if attached a_actual.java_text as al_text then
				Result.append (al_text)
			else
				Result.append_string_general ("null")
			end
			Result.append_string_general (" at ")
			Result.append_string_general (a_name)
			Result.append_string_general (" of type " + a_actual.class_name + " cannot be converted to " + a_type)
		end

invariant
	same_count: names.count = values.count

end
