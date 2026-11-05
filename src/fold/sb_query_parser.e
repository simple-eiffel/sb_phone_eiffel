note
	description: "[
		Reads a typed search: QueryParser in Query.kt. A Strong's number alone is a lookup;
		anything else is tokenized and read into a tree, or gives the first mistake with its
		position. The wording of every message is Kotlin's, and positions are Kotlin's
		string indexes, which count UTF-16 units, not characters.
	]"
	author: "Larry Rix"

class
	SB_QUERY_PARSER

create
	make,
	make_with_rules

feature {NONE} -- Initialization

	make
			-- Create the parser with the rules of Kotlin on Android.
		do
			make_with_rules (create {SB_KOTLIN_RULES}.make_android)
		end

	make_with_rules (a_rules: SB_KOTLIN_RULES)
			-- Create the parser under `a_rules'.
		do
			rules := a_rules
			create strongs.make (a_rules)
			create fold.make
			create tokens.make (0)
			create tokenize_error.make_empty
		ensure
			rules_set: rules = a_rules
		end

feature -- Parsing

	parse (a_input: READABLE_STRING_32): SB_QUERY_PARSE
			-- `a_input' read as a search.
		local
			l_reader: SB_QUERY_READER
		do
			strongs.match_alone (a_input)
			if strongs.is_matched then
				if strongs.is_hebrew then
					create {SB_QUERY_PARSE_STRONGS} Result.make ({STRING_32} "hbo", strongs.number)
				else
					create {SB_QUERY_PARSE_STRONGS} Result.make ({STRING_32} "grc", strongs.number)
				end
			else
				tokenize (a_input)
				if not tokenize_error.is_empty then
					create {SB_QUERY_PARSE_ERROR} Result.make (tokenize_error, tokenize_error_position)
				elseif tokens.is_empty then
					create {SB_QUERY_PARSE_ERROR} Result.make ({STRING_32} "Type a word to search for.", -1)
				else
					create l_reader.make (tokens, rules.utf16_offset (a_input, a_input.count + 1), fold, strongs, rules)
					if attached l_reader.read_query as al_root then
						if al_root.has_positive then
							create {SB_QUERY_PARSE_TEXT} Result.make (create {SB_SEARCH_QUERY}.make (al_root))
						else
							create {SB_QUERY_PARSE_ERROR} Result.make ({STRING_32} "Add a word to look for, not only words to leave out.", -1)
						end
					else
						create {SB_QUERY_PARSE_ERROR} Result.make (l_reader.error_message, l_reader.error_position)
					end
				end
			end
		end

feature {NONE} -- Tokenizing

	tokenize (a_input: READABLE_STRING_32)
			-- Fill `tokens' from `a_input', or set `tokenize_error'.
		local
			s: READABLE_STRING_32
			i, l_close, l_next, l_start: INTEGER
			c: NATURAL_32
			l_word: STRING_32
			l_prefix: BOOLEAN
		do
			s := a_input
			create tokens.make (8)
			create tokenize_error.make_empty
			from
				i := 1
			until
				i > s.count or not tokenize_error.is_empty
			loop
				c := s.code (i)
				if rules.is_whitespace (c) then
					i := i + 1
				elseif c = 0x28 then
					add ({SB_QUERY_TOKEN}.Kind_left_parenthesis, {STRING_32} "(", s, i, False)
					i := i + 1
				elseif c = 0x29 then
					add ({SB_QUERY_TOKEN}.Kind_right_parenthesis, {STRING_32} ")", s, i, False)
					i := i + 1
				elseif c = 0x7C then
					add ({SB_QUERY_TOKEN}.Kind_or, {STRING_32} "|", s, i, False)
					i := i + 1
				elseif c = 0x2D and then i < s.count and then not rules.is_whitespace (s.code (i + 1))
					and then (tokens.is_empty or else rules.is_whitespace (s.code (i - 1)) or else s.code (i - 1) = 0x28)
				then
					add ({SB_QUERY_TOKEN}.Kind_not, {STRING_32} "-", s, i, False)
					i := i + 1
				elseif c = Straight_quote or else c = Open_quote then
					l_close := close_quote_after (s, i)
					if l_close = 0 then
						tokenize_error := {STRING_32} "This quotation mark is never closed."
						tokenize_error_position := rules.utf16_offset (s, i)
					else
						l_prefix := False
						l_next := l_close + 1
						if l_next <= s.count and then s.code (l_next) = Star then
							l_prefix := True
							l_next := l_next + 1
						end
						add ({SB_QUERY_TOKEN}.Kind_phrase, s.substring (i + 1, l_close - 1), s, i, l_prefix)
						i := l_next
					end
				else
					l_start := i
					from
					until
						i > s.count or else ends_word (s.code (i))
					loop
						i := i + 1
					end
					l_word := s.substring (l_start, i - 1).to_string_32
					if l_word.same_string ({STRING_32} "OR") then
						add ({SB_QUERY_TOKEN}.Kind_or, l_word, s, l_start, False)
					elseif l_word.same_string ({STRING_32} "AND") then
						add ({SB_QUERY_TOKEN}.Kind_and, l_word, s, l_start, False)
					elseif l_word.same_string ({STRING_32} "NOT") then
						add ({SB_QUERY_TOKEN}.Kind_not, l_word, s, l_start, False)
					else
						l_prefix := l_word.code (l_word.count) = Star and then not l_word.has (':')
						if l_prefix then
							rules.trim_stars (l_word)
						end
						add ({SB_QUERY_TOKEN}.Kind_word, l_word, s, l_start, l_prefix)
					end
				end
			end
		end

	add (a_kind: INTEGER; a_text: READABLE_STRING_32; a_input: READABLE_STRING_32; a_index: INTEGER; a_prefix: BOOLEAN)
			-- Add a token that starts at `a_index' of `a_input'.
		do
			tokens.extend (create {SB_QUERY_TOKEN}.make (a_kind, a_text, rules.utf16_offset (a_input, a_index), a_prefix))
		end

	close_quote_after (a_input: READABLE_STRING_32; a_index: INTEGER): INTEGER
			-- The index of the first closing quote after `a_index', or 0.
		local
			i: INTEGER
		do
			from
				i := a_index + 1
			until
				i > a_input.count or Result > 0
			loop
				if a_input.code (i) = Straight_quote or else a_input.code (i) = Close_quote then
					Result := i
				end
				i := i + 1
			end
		end

	ends_word (a_code: NATURAL_32): BOOLEAN
			-- Does `a_code' end a word?
		do
			Result := rules.is_whitespace (a_code) or else a_code = 0x28 or else a_code = 0x29 or else a_code = 0x7C
				or else a_code = Straight_quote or else a_code = Open_quote
		end

feature {NONE} -- Implementation

	rules: SB_KOTLIN_RULES
			-- The character rules.

	strongs: SB_STRONGS_PATTERN
			-- The Strong's patterns.

	fold: SB_FOLD
			-- Folds text terms.

	tokens: ARRAYED_LIST [SB_QUERY_TOKEN]
			-- The tokens of the search being read.

	tokenize_error: STRING_32
			-- What `tokenize' found wrong, empty if nothing.

	tokenize_error_position: INTEGER
			-- Where.

	Straight_quote: NATURAL_32 = 0x22
	Open_quote: NATURAL_32 = 0x201C
	Close_quote: NATURAL_32 = 0x201D
			-- A phrase opens with the first two and closes with the first or the last.

	Star: NATURAL_32 = 0x2A
			-- Marks a prefix.

end
