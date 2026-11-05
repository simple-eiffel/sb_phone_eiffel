note
	description: "[
		Removes Hebrew pointing for display, by level. Full keeps everything; Vowels removes the
		cantillation (accents) and meteg; Consonants also removes the vowel points, dagesh,
		shin and sin dots and rafe. Maqaf, paseq, sof pasuq and nun hafukha (punctuation) always
		stay.
	]"
	author: "Larry Rix"

class
	SB_POINTING

feature -- Levels

	Level_full: INTEGER = 1
			-- Show all the pointing.

	Level_vowels: INTEGER = 2
			-- Show the vowels, not the cantillation.

	Level_consonants: INTEGER = 3
			-- Show the consonants alone.

	is_valid_level (a_level: INTEGER): BOOLEAN
			-- Is `a_level' one of the three levels?
		do
			Result := a_level >= Level_full and a_level <= Level_consonants
		end

feature -- Conversion

	apply (a_text: READABLE_STRING_32; a_level: INTEGER): STRING_32
			-- `a_text' at `a_level'.
		require
			valid_level: is_valid_level (a_level)
		local
			i: INTEGER
			l_code: NATURAL_32
		do
			create Result.make (a_text.count)
			from
				i := 1
			until
				i > a_text.count
			loop
				l_code := a_text.code (i)
				if a_level = Level_full
					or else (a_level = Level_vowels and then not is_cantillation (l_code))
					or else (a_level = Level_consonants and then not is_cantillation (l_code) and then not is_point (l_code))
				then
					Result.append_code (l_code)
				end
				i := i + 1
			end
		ensure
			full_keeps_all: a_level = Level_full implies Result.same_string (a_text)
			never_longer: Result.count <= a_text.count
		end

feature {NONE} -- Implementation

	is_cantillation (a_code: NATURAL_32): BOOLEAN
			-- Is `a_code' a Hebrew accent, or meteg?
		do
			Result := (a_code >= 0x591 and a_code <= 0x5AF) or else a_code = 0x5BD
		end

	is_point (a_code: NATURAL_32): BOOLEAN
			-- Is `a_code' a vowel point, dagesh, shin or sin dot, rafe or upper or lower dot?
		do
			Result := (a_code >= 0x5B0 and a_code <= 0x5BC) or else a_code = 0x5BF or else a_code = 0x5C1
				or else a_code = 0x5C2 or else a_code = 0x5C4 or else a_code = 0x5C5 or else a_code = 0x5C7
		end

end
