note
	description: "[
		A value of Android's org.json, with what the Kotlin code asks of it: the conversions of
		JSON.java (toInteger, toLong, toBoolean, toString) and the class names that its error
		messages quote. A Java null in an array is Void here.
	]"
	author: "Larry Rix"

deferred class
	SB_JSON_VALUE

feature -- Conversion

	as_integer: detachable INTEGER_REF
			-- JSON.toInteger.
		do
		end

	as_long: detachable INTEGER_64_REF
			-- JSON.toLong.
		do
		end

	as_boolean: detachable BOOLEAN_REF
			-- JSON.toBoolean.
		do
		end

	java_text: detachable STRING_32
			-- String.valueOf: Void only for a container that cannot be written.
		deferred
		end

feature -- Access

	class_name: STRING_8
			-- The Java class, as an error message names it.
		deferred
		end

feature -- Output

	write_to (a_out: SB_JSON_STRINGER)
			-- Write this value to `a_out'.
		deferred
		end

feature {NONE} -- Implementation

	numbers: SB_JAVA_NUMBERS
			-- Java's number rules.
		once
			create Result
		end

end
