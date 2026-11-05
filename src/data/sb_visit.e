note
	description: "One visit to a verse."
	author: "Larry Rix"

class
	SB_VISIT

create
	make

feature {NONE} -- Initialization

	make (a_key: INTEGER; a_version: STRING_32; a_at: INTEGER_64)
			-- Create the visit.
		do
			key := a_key
			version := a_version
			at := a_at
		ensure
			key_set: key = a_key
			version_set: version = a_version
			at_set: at = a_at
		end

feature -- Access

	key: INTEGER
			-- The verse.

	version: STRING_32
			-- The version read.

	at: INTEGER_64
			-- When, in ms.

end
