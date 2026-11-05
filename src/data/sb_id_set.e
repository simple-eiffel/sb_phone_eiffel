note
	description: "[
		A set of row ids or verse keys, held sorted, each once. It stands for Kotlin's HashSet<Long>
		and Set<Int>: searches build these from thousands of rows, and a sorted array makes the
		AND, OR and NOT of a search merges, with no hashing. Items count from 1.
	]"
	author: "Larry Rix"

class
	SB_ID_SET

create
	make_empty,
	make_from_list

create {SB_ID_SET}
	make_from_sorted

feature {NONE} -- Initialization

	make_empty
			-- Create an empty set.
		do
			create items.make_empty (0)
		ensure
			empty: is_empty
		end

	make_from_list (a_list: ARRAYED_LIST [INTEGER_64])
			-- Create the set of what `a_list' holds, in any order, with repeats.
		local
			i: INTEGER
			l_sorted: BOOLEAN
			l_items: SPECIAL [INTEGER_64]
		do
			create l_items.make_empty (a_list.count)
			l_sorted := True
			from
				i := 1
			until
				i > a_list.count
			loop
				l_items.extend (a_list [i])
				if i > 1 and then a_list [i] <= a_list [i - 1] then
					l_sorted := False
				end
				i := i + 1
			end
			if l_sorted then
				items := l_items
			else
				items := without_repeats (merge_sorted (l_items))
			end
		ensure
			no_more_than_given: count <= a_list.count
		end

	make_from_sorted (a_items: SPECIAL [INTEGER_64])
			-- Create the set from `a_items', already sorted and without repeats.
		do
			items := a_items
		ensure
			items_set: items = a_items
		end

feature -- Access

	item alias "[]" (a_index: INTEGER): INTEGER_64
			-- The item at `a_index', in ascending order.
		require
			index_in_range: a_index >= 1 and a_index <= count
		do
			Result := items [a_index - 1]
		end

feature -- Measurement

	count: INTEGER
			-- How many items.
		do
			Result := items.count
		end

feature -- Status

	is_empty: BOOLEAN
			-- Is it empty?
		do
			Result := items.count = 0
		end

	has (a_item: INTEGER_64): BOOLEAN
			-- Is `a_item' in the set?
		local
			l_low, l_high, l_middle: INTEGER
		do
			from
				l_low := 0
				l_high := items.count - 1
			until
				Result or else l_low > l_high
			loop
				l_middle := (l_low + l_high) // 2
				if items [l_middle] = a_item then
					Result := True
				elseif items [l_middle] < a_item then
					l_low := l_middle + 1
				else
					l_high := l_middle - 1
				end
			end
		end

feature -- Set operations

	intersection (a_other: SB_ID_SET): SB_ID_SET
			-- The items in both.
		local
			i, j: INTEGER
			l_result: SPECIAL [INTEGER_64]
			l_mine, l_theirs: SPECIAL [INTEGER_64]
		do
			l_mine := items
			l_theirs := a_other.items
			create l_result.make_empty (count.min (a_other.count))
			from
			until
				i >= l_mine.count or j >= l_theirs.count
			loop
				if l_mine [i] = l_theirs [j] then
					l_result.extend (l_mine [i])
					i := i + 1
					j := j + 1
				elseif l_mine [i] < l_theirs [j] then
					i := i + 1
				else
					j := j + 1
				end
			end
			create Result.make_from_sorted (l_result)
		ensure
			no_larger: Result.count <= count and Result.count <= a_other.count
		end

	union (a_other: SB_ID_SET): SB_ID_SET
			-- The items in either.
		local
			i, j: INTEGER
			l_result: SPECIAL [INTEGER_64]
			l_mine, l_theirs: SPECIAL [INTEGER_64]
		do
			l_mine := items
			l_theirs := a_other.items
			create l_result.make_empty (count + a_other.count)
			from
			until
				i >= l_mine.count and j >= l_theirs.count
			loop
				if j >= l_theirs.count or else (i < l_mine.count and then l_mine [i] < l_theirs [j]) then
					l_result.extend (l_mine [i])
					i := i + 1
				elseif i >= l_mine.count or else l_theirs [j] < l_mine [i] then
					l_result.extend (l_theirs [j])
					j := j + 1
				else
					l_result.extend (l_mine [i])
					i := i + 1
					j := j + 1
				end
			end
			create Result.make_from_sorted (l_result)
		ensure
			no_smaller: Result.count >= count and Result.count >= a_other.count
		end

	difference (a_other: SB_ID_SET): SB_ID_SET
			-- The items here that are not in `a_other'.
		local
			i, j: INTEGER
			l_result: SPECIAL [INTEGER_64]
			l_mine, l_theirs: SPECIAL [INTEGER_64]
		do
			l_mine := items
			l_theirs := a_other.items
			create l_result.make_empty (count)
			from
			until
				i >= l_mine.count
			loop
				if j >= l_theirs.count or else l_mine [i] < l_theirs [j] then
					l_result.extend (l_mine [i])
					i := i + 1
				elseif l_mine [i] = l_theirs [j] then
					i := i + 1
					j := j + 1
				else
					j := j + 1
				end
			end
			create Result.make_from_sorted (l_result)
		ensure
			no_larger: Result.count <= count
		end

feature {SB_ID_SET} -- Implementation

	items: SPECIAL [INTEGER_64]
			-- The items, ascending.

feature {NONE} -- Implementation

	merge_sorted (a_items: SPECIAL [INTEGER_64]): SPECIAL [INTEGER_64]
			-- The items of `a_items' in ascending order.
		local
			l_from, l_to, l_swap: SPECIAL [INTEGER_64]
			l_width, l_start, l_middle, l_end, i, j, k, l_count: INTEGER
		do
			l_count := a_items.count
			l_from := a_items
			create l_to.make_filled (0, l_count)
			from
				l_width := 1
			until
				l_width >= l_count
			loop
				from
					l_start := 0
				until
					l_start >= l_count
				loop
					l_middle := (l_start + l_width).min (l_count)
					l_end := (l_start + 2 * l_width).min (l_count)
					from
						i := l_start
						j := l_middle
						k := l_start
					until
						k >= l_end
					loop
						if i < l_middle and then (j >= l_end or else l_from [i] <= l_from [j]) then
							l_to [k] := l_from [i]
							i := i + 1
						else
							l_to [k] := l_from [j]
							j := j + 1
						end
						k := k + 1
					end
					l_start := l_end
				end
				l_swap := l_from
				l_from := l_to
				l_to := l_swap
				l_width := l_width * 2
			end
			Result := l_from
		ensure
			same_count: Result.count = a_items.count
		end

	without_repeats (a_items: SPECIAL [INTEGER_64]): SPECIAL [INTEGER_64]
			-- The sorted `a_items' with each item once.
		local
			i: INTEGER
		do
			create Result.make_empty (a_items.count)
			from
				i := 0
			until
				i >= a_items.count
			loop
				if i = 0 or else a_items [i] /= a_items [i - 1] then
					Result.extend (a_items [i])
				end
				i := i + 1
			end
		ensure
			no_more: Result.count <= a_items.count
		end

end
