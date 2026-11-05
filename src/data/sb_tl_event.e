note
	description: "One event of the timeline."
	author: "Larry Rix"

class
	SB_TL_EVENT

create
	make

feature {NONE} -- Initialization

	make (a_id, a_lane, a_title, a_kind: STRING_32; a_importance: INTEGER; a_summary, a_status: STRING_32; a_earliest, a_latest: INTEGER; a_label: STRING_32)
			-- Create the event.
		do
			id := a_id
			lane := a_lane
			title := a_title
			kind := a_kind
			importance := a_importance
			summary := a_summary
			status := a_status
			earliest := a_earliest
			latest := a_latest
			label := a_label
		ensure
			id_set: id = a_id
			lane_set: lane = a_lane
			title_set: title = a_title
			kind_set: kind = a_kind
			importance_set: importance = a_importance
			summary_set: summary = a_summary
			status_set: status = a_status
			earliest_set: earliest = a_earliest
			latest_set: latest = a_latest
			label_set: label = a_label
		end

feature -- Access

	id, lane, title, kind: STRING_32
			-- What it is.

	importance: INTEGER
			-- How much it stands out.

	summary, status: STRING_32
			-- What is said of it and how settled that is.

	earliest, latest: INTEGER
			-- Its span in astronomical years.

	label: STRING_32
			-- Its date in words.

end
