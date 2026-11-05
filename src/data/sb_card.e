note
	description: "A memory card."
	author: "Larry Rix"

class
	SB_CARD

create
	make

feature {NONE} -- Initialization

	make (a_id: INTEGER_64; a_key, a_key_end: INTEGER; a_due: INTEGER_64; a_interval_days, a_reps, a_lapses: INTEGER)
			-- Create the card.
		do
			id := a_id
			key := a_key
			key_end := a_key_end
			due := a_due
			interval_days := a_interval_days
			reps := a_reps
			lapses := a_lapses
		ensure
			id_set: id = a_id
			key_set: key = a_key
			key_end_set: key_end = a_key_end
			due_set: due = a_due
			interval_days_set: interval_days = a_interval_days
			reps_set: reps = a_reps
			lapses_set: lapses = a_lapses
		end

feature -- Copying

	with_interval (a_days: INTEGER): SB_CARD
			-- This card at another interval: card.copy(intervalDays = ...).
		do
			Result := twin
			Result.set_interval_days (a_days)
		ensure
			set: Result.interval_days = a_days
		end

feature {SB_CARD} -- Element change

	set_interval_days (a_days: INTEGER)
		do
			interval_days := a_days
		ensure
			set: interval_days = a_days
		end

feature -- Access

	id: INTEGER_64
			-- The row id.

	key, key_end: INTEGER
			-- The verse, and the last verse of a range.

	due: INTEGER_64
			-- When it comes round, in ms.

	interval_days, reps, lapses: INTEGER
			-- How it has gone so far.

end
