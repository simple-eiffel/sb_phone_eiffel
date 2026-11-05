note
	description: "[
		Dates as the phone writes them: DateFormat.getDateInstance(MEDIUM). The phone's pattern,
		month names and clock offset are asked for once at the start; until they arrive
		the American form serves.
	]"
	author: "Larry Rix"

class
	SB_DATES

create
	make

feature {NONE} -- Initialization

	make
		do
			pattern := {STRING_32} "MMM d, y"
			months := <<{STRING_32} "Jan", {STRING_32} "Feb", {STRING_32} "Mar", {STRING_32} "Apr", {STRING_32} "May", {STRING_32} "Jun",
				{STRING_32} "Jul", {STRING_32} "Aug", {STRING_32} "Sep", {STRING_32} "Oct", {STRING_32} "Nov", {STRING_32} "Dec">>
		end

feature -- Element change

	read_form (a_form: READABLE_STRING_32)
			-- Take "pattern|offset|Jan|Feb|...", as the phone answers.
		local
			l_parts: LIST [READABLE_STRING_32]
			i: INTEGER
		do
			l_parts := a_form.split ('|')
			if l_parts.count = 14 and then l_parts [2].is_integer_64 then
				pattern := l_parts [1].to_string_32
				offset := l_parts [2].to_integer_64
				from i := 1 until i > 12 loop
					months [i] := l_parts [i + 2].to_string_32
					i := i + 1
				end
			end
		end

feature -- Formatting

	medium (a_millis: INTEGER_64): STRING_32
			-- `a_millis' from 1970 as a date.
		local
			l_days: INTEGER_64
			l_date: TUPLE [year, month, day: INTEGER]
			i: INTEGER
			l_run: INTEGER
			l_char: CHARACTER_32
			l_quoted: BOOLEAN
		do
			l_days := floor_days (a_millis + offset)
			l_date := civil (l_days)
			create Result.make (12)
			from i := 1 until i > pattern.count loop
				l_char := pattern [i]
				if l_char = '%'' then
					l_quoted := not l_quoted
					i := i + 1
				elseif l_quoted or not ((l_char >= 'a' and l_char <= 'z') or (l_char >= 'A' and l_char <= 'Z')) then
					Result.append_character (l_char)
					i := i + 1
				else
					l_run := 1
					from until i + l_run > pattern.count or else pattern [i + l_run] /= l_char loop
						l_run := l_run + 1
					end
					inspect l_char.to_character_8
					when 'y' then
						if l_run = 2 then
							Result.append (two_digits (l_date.year \\ 100))
						else
							Result.append_integer (l_date.year)
						end
					when 'M', 'L' then
						if l_run >= 3 then
							Result.append (months [l_date.month])
						elseif l_run = 2 then
							Result.append (two_digits (l_date.month))
						else
							Result.append_integer (l_date.month)
						end
					when 'd' then
						if l_run = 2 then
							Result.append (two_digits (l_date.day))
						else
							Result.append_integer (l_date.day)
						end
					else
					end
					i := i + l_run
				end
			end
		end

	iso_today (a_millis: INTEGER_64): STRING_32
			-- `a_millis' as 2026-11-05, for a file name: LocalDate.now().
		local
			l_date: TUPLE [year, month, day: INTEGER]
		do
			l_date := civil (floor_days (a_millis + offset))
			create Result.make (10)
			Result.append_integer (l_date.year)
			Result.append_character ('-')
			Result.append (two_digits (l_date.month))
			Result.append_character ('-')
			Result.append (two_digits (l_date.day))
		end

feature {NONE} -- Implementation

	floor_days (a_millis: INTEGER_64): INTEGER_64
		do
			Result := a_millis // 86400000
			if a_millis < 0 and a_millis \\ 86400000 /= 0 then
				Result := Result - 1
			end
		end

	civil (a_days: INTEGER_64): TUPLE [year, month, day: INTEGER]
			-- The calendar date of `a_days' from 1970-01-01.
		local
			l_z, l_era, l_doe, l_yoe, l_doy, l_mp, l_d, l_m, l_y: INTEGER_64
		do
			l_z := a_days + 719468
			l_era := (if l_z >= 0 then l_z else l_z - 146096 end) // 146097
			l_doe := l_z - l_era * 146097
			l_yoe := (l_doe - l_doe // 1460 + l_doe // 36524 - l_doe // 146096) // 365
			l_y := l_yoe + l_era * 400
			l_doy := l_doe - (365 * l_yoe + l_yoe // 4 - l_yoe // 100)
			l_mp := (5 * l_doy + 2) // 153
			l_d := l_doy - (153 * l_mp + 2) // 5 + 1
			l_m := if l_mp < 10 then l_mp + 3 else l_mp - 9 end
			if l_m <= 2 then
				l_y := l_y + 1
			end
			Result := [l_y.to_integer_32, l_m.to_integer_32, l_d.to_integer_32]
		end

	two_digits (a_number: INTEGER): STRING_32
		do
			create Result.make (2)
			if a_number < 10 then
				Result.append_character ('0')
			end
			Result.append_integer (a_number)
		end

	pattern: STRING_32

	months: ARRAY [STRING_32]

	offset: INTEGER_64

end
