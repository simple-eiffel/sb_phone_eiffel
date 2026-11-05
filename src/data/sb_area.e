note
	description: "An empire's outline: lon,lat pairs. Years are astronomical (0 = 1 BC)."
	author: "Larry Rix"

class
	SB_AREA

create
	make

feature {NONE} -- Initialization

	make (a_name: STRING_32; a_year_from, a_year_to: INTEGER; a_ring: ARRAY [REAL_32])
			-- Create the area.
		do
			name := a_name
			year_from := a_year_from
			year_to := a_year_to
			ring := a_ring
		ensure
			name_set: name = a_name
			year_from_set: year_from = a_year_from
			year_to_set: year_to = a_year_to
			ring_set: ring = a_ring
		end

feature -- Access

	name: STRING_32
			-- The empire.

	year_from, year_to: INTEGER
			-- When it stood.

	ring: ARRAY [REAL_32]
			-- Its outline, lon then lat, from index 1.

end
