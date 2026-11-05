note
	description: "A place on the atlas."
	author: "Larry Rix"

class
	SB_PLACE

create
	make

feature {NONE} -- Initialization

	make (a_id, a_name, a_kind: STRING_32; a_min_zoom: INTEGER; a_lon, a_lat: REAL_32)
			-- Create the place.
		do
			id := a_id
			name := a_name
			kind := a_kind
			min_zoom := a_min_zoom
			lon := a_lon
			lat := a_lat
		ensure
			id_set: id = a_id
			name_set: name = a_name
			kind_set: kind = a_kind
			min_zoom_set: min_zoom = a_min_zoom
			lon_set: lon = a_lon
			lat_set: lat = a_lat
		end

feature -- Access

	id, name, kind: STRING_32
			-- What it is.

	min_zoom: INTEGER
			-- From which zoom it appears.

	lon, lat: REAL_32
			-- Where it is.

end
