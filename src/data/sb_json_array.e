note
	description: "org.json.JSONArray. Indexes count from 0, as they do in its error messages."
	author: "Larry Rix"

class
	SB_JSON_ARRAY

inherit
	SB_JSON_VALUE

	SB_FAILURE

create
	make

feature {NONE} -- Initialization

	make
			-- Create an empty array.
		do
			create values.make (8)
		end

feature -- Access

	values: ARRAYED_LIST [detachable SB_JSON_VALUE]
			-- The items, from 1; Void stands for a Java null.

	class_name: STRING_8 = "org.json.JSONArray"
			-- <Precursor>

	length: INTEGER
			-- JSONArray.length.
		do
			Result := values.count
		end

	item (a_index: INTEGER): SB_JSON_VALUE
			-- JSONArray.get.
		do
			if a_index < 0 or a_index >= values.count then
				fail (message ("Index " + a_index.out + " out of range [0.." + values.count.out + ")"))
			end
			if attached values [a_index + 1] as al_value then
				Result := al_value
			else
				fail (message ("Value at " + a_index.out + " is null."))
				create {SB_JSON_NULL} Result
			end
		end

	object_at (a_index: INTEGER): SB_JSON_OBJECT
			-- JSONArray.getJSONObject.
		local
			l_value: SB_JSON_VALUE
		do
			l_value := item (a_index)
			if attached {SB_JSON_OBJECT} l_value as al_object then
				Result := al_object
			else
				fail (mismatch (a_index, l_value, "JSONObject"))
				create Result.make
			end
		end

	integer_at (a_index: INTEGER): INTEGER
			-- JSONArray.getInt.
		local
			l_value: SB_JSON_VALUE
		do
			l_value := item (a_index)
			if attached l_value.as_integer as al_integer then
				Result := al_integer.item
			else
				fail (mismatch (a_index, l_value, "int"))
			end
		end

feature -- Element change

	put (a_value: detachable SB_JSON_VALUE)
			-- JSONArray.put.
		do
			values.extend (a_value)
		ensure
			one_more: values.count = old values.count + 1
		end

	put_object (a_object: SB_JSON_OBJECT)
			-- Add `a_object'.
		do
			values.extend (a_object)
		end

	put_integer (a_value: INTEGER)
			-- Add a java.lang.Integer.
		do
			values.extend (create {SB_JSON_INTEGER}.make (a_value))
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

feature -- Output

	write_to (a_out: SB_JSON_STRINGER)
			-- <Precursor>
		local
			i: INTEGER
		do
			a_out.begin_array
			from
				i := 1
			until
				i > values.count
			loop
				if attached values [i] as al_value then
					al_value.write_to (a_out)
				else
					a_out.put_literal ("null")
				end
				i := i + 1
			end
			a_out.end_array
		end

feature {NONE} -- Implementation

	message (a_text: READABLE_STRING_8): STRING_32
			-- `a_text' as a message.
		do
			create Result.make (a_text.count)
			Result.append_string_general (a_text)
		end

	mismatch (a_index: INTEGER; a_actual: SB_JSON_VALUE; a_type: READABLE_STRING_8): STRING_32
			-- JSON.typeMismatch for an index.
		do
			create Result.make (64)
			Result.append_string_general ("Value ")
			if attached a_actual.java_text as al_text then
				Result.append (al_text)
			else
				Result.append_string_general ("null")
			end
			Result.append_string_general (" at " + a_index.out + " of type " + a_actual.class_name + " cannot be converted to " + a_type)
		end

end
