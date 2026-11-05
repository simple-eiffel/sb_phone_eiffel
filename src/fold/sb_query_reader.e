note
	description: "[
		Reads the tokens of a typed search into a tree: the inner Parser of QueryParser.

		Kotlin stops at a mistake by throwing. Here `fail' records the first mistake and every
		reading feature gives Void from then on, so the first mistake is the one reported.
	]"
	author: "Larry Rix"

class
	SB_QUERY_READER

create
	make

feature {NONE} -- Initialization

	make (a_tokens: ARRAYED_LIST [SB_QUERY_TOKEN]; a_end: INTEGER; a_fold: SB_FOLD; a_strongs: SB_STRONGS_PATTERN; a_rules: SB_KOTLIN_RULES)
			-- Create the reader, the text ending at the UTF-16 index `a_end'.
		require
			has_tokens: not a_tokens.is_empty
			end_valid: a_end >= 0
		do
			tokens := a_tokens
			end_position := a_end
			fold := a_fold
			strongs := a_strongs
			rules := a_rules
			index := 1
			create error_message.make_empty
		ensure
			at_start: index = 1
			no_error: not has_failed
		end

feature -- Status

	has_failed: BOOLEAN
			-- Was a mistake found?

feature -- Access

	error_message: STRING_32
			-- The first mistake found.

	error_position: INTEGER
			-- Where it is.

feature -- Reading

	read_query: detachable SB_QUERY_NODE
			-- The whole search as a tree, Void if there is a mistake in it.
		do
			Result := read_or
			if not has_failed and then not is_done then
				if peek.kind = {SB_QUERY_TOKEN}.Kind_right_parenthesis then
					fail ({STRING_32} "This ) has no ( before it.")
				else
					fail ({STRING_32} "Unexpected %"" + peek.text + {STRING_32} "%".")
				end
				Result := Void
			end
		ensure
			tree_or_mistake: (Result = Void) = has_failed
		end

feature {NONE} -- The grammar

	read_or: detachable SB_QUERY_NODE
			-- or := and ( OR and )*
		local
			l_items: ARRAYED_LIST [SB_QUERY_NODE]
			l_at: INTEGER
		do
			create l_items.make (2)
			if attached read_and as al_first then
				l_items.extend (al_first)
			end
			from
			until
				has_failed or else is_done or else peek.kind /= {SB_QUERY_TOKEN}.Kind_or
			loop
				l_at := peek.position
				index := index + 1
				if is_done or else peek.kind = {SB_QUERY_TOKEN}.Kind_right_parenthesis or else peek.kind = {SB_QUERY_TOKEN}.Kind_or then
					fail_at ({STRING_32} "OR needs a word after it.", l_at)
				elseif attached read_and as al_next then
					l_items.extend (al_next)
				end
			end
			if not has_failed then
				if l_items.count = 1 then
					Result := l_items.first
				else
					create {SB_OR_NODE} Result.make (l_items)
				end
			end
		end

	read_and: detachable SB_QUERY_NODE
			-- and := unary ( [AND] unary )*
		local
			l_items: ARRAYED_LIST [SB_QUERY_NODE]
			l_at: INTEGER
		do
			create l_items.make (2)
			if attached read_unary as al_first then
				l_items.extend (al_first)
			end
			from
			until
				has_failed or else is_done or else peek.kind = {SB_QUERY_TOKEN}.Kind_or or else peek.kind = {SB_QUERY_TOKEN}.Kind_right_parenthesis
			loop
				if peek.kind = {SB_QUERY_TOKEN}.Kind_and then
					l_at := peek.position
					index := index + 1
					if is_done or else peek.kind = {SB_QUERY_TOKEN}.Kind_right_parenthesis or else peek.kind = {SB_QUERY_TOKEN}.Kind_or then
						fail_at ({STRING_32} "AND needs a word after it.", l_at)
					end
				end
				if not has_failed and then attached read_unary as al_next then
					l_items.extend (al_next)
				end
			end
			if not has_failed then
				if l_items.count = 1 then
					Result := l_items.first
				else
					create {SB_AND_NODE} Result.make (l_items)
				end
			end
		end

	read_unary: detachable SB_QUERY_NODE
			-- unary := NOT unary | primary
		local
			l_at: INTEGER
		do
			if is_done then
				fail ({STRING_32} "A word is missing here.")
			elseif peek.kind = {SB_QUERY_TOKEN}.Kind_not then
				l_at := peek.position
				index := index + 1
				if is_done then
					fail_at ({STRING_32} "NOT needs a word after it.", l_at)
				elseif attached read_unary as al_item then
					create {SB_NOT_NODE} Result.make (al_item)
				end
			else
				Result := read_primary
			end
		end

	read_primary: detachable SB_QUERY_NODE
			-- primary := ( or ) | term
		require
			not_done: not is_done
		local
			t: SB_QUERY_TOKEN
		do
			t := peek
			inspect
				t.kind
			when {SB_QUERY_TOKEN}.Kind_left_parenthesis then
				index := index + 1
				if not is_done and then peek.kind = {SB_QUERY_TOKEN}.Kind_right_parenthesis then
					fail_at ({STRING_32} "These parentheses are empty.", t.position)
				else
					Result := read_or
					if not has_failed then
						if is_done or else peek.kind /= {SB_QUERY_TOKEN}.Kind_right_parenthesis then
							fail_at ({STRING_32} "This ( is never closed.", t.position)
							Result := Void
						else
							index := index + 1
						end
					end
				end
			when {SB_QUERY_TOKEN}.Kind_right_parenthesis then
				fail ({STRING_32} "This ) has no ( before it.")
			when {SB_QUERY_TOKEN}.Kind_or then
				fail ({STRING_32} "OR needs a word before it.")
			when {SB_QUERY_TOKEN}.Kind_and then
				fail ({STRING_32} "AND needs a word before it.")
			when {SB_QUERY_TOKEN}.Kind_phrase then
				index := index + 1
				Result := text_node (t)
			when {SB_QUERY_TOKEN}.Kind_word then
				index := index + 1
				Result := term_node (t)
			else
				fail ({STRING_32} "NOT is misplaced here.")
			end
		end

	text_node (t: SB_QUERY_TOKEN): detachable SB_QUERY_NODE
			-- `t' as folded text.
		local
			l_words: ARRAYED_LIST [STRING_32]
		do
			l_words := fold.words (t.text)
			if l_words.is_empty then
				fail_at ({STRING_32} "Nothing searchable in %"" + t.text + {STRING_32} "%".", t.position)
			else
				create {SB_TEXT_NODE} Result.make (create {SB_MATCH}.make (l_words, t.is_prefix))
			end
		end

	term_node (t: SB_QUERY_TOKEN): detachable SB_QUERY_NODE
			-- `t' as a Strong's number, a field term or folded text.
		local
			l_colon: INTEGER
			l_field, l_value: STRING_32
		do
			strongs.match_term (t.text)
			if strongs.is_matched then
				create {SB_WORD_TERM_NODE} Result.make ({STRING_32} "strongs", strongs.number)
			else
				l_colon := t.text.index_of (':', 1)
				if l_colon > 1 then
					l_field := rules.unicode.lowercase (t.text.substring (1, l_colon - 1))
					l_value := t.text.substring (l_colon + 1, t.text.count)
				else
					create l_field.make_empty
					create l_value.make_empty
				end
				if not is_field (l_field) then
					Result := text_node (t)
				elseif l_value.is_empty or else l_value.same_string ({STRING_32} "*") then
					fail_at (l_field + {STRING_32} ": needs something after the colon.", t.position + l_colon - 1)
				else
					if l_field.same_string ({STRING_32} "lemma") then
						rules.trim_stars (l_value)
					end
					create {SB_WORD_TERM_NODE} Result.make (l_field, l_value)
				end
			end
		end

feature {NONE} -- Implementation

	tokens: ARRAYED_LIST [SB_QUERY_TOKEN]
			-- What was typed.

	index: INTEGER
			-- The next token.

	end_position: INTEGER
			-- The UTF-16 length of the text.

	fold: SB_FOLD
			-- Folds text terms.

	strongs: SB_STRONGS_PATTERN
			-- Recognizes Strong's terms.

	rules: SB_KOTLIN_RULES
			-- Lowercases field names, trims stars.

	is_done: BOOLEAN
			-- Are the tokens used up?
		do
			Result := index > tokens.count
		end

	peek: SB_QUERY_TOKEN
			-- The next token.
		require
			not_done: not is_done
		do
			Result := tokens [index]
		end

	is_field (a_name: STRING_32): BOOLEAN
			-- Is `a_name' strongs, lemma or morph?
		do
			Result := a_name.same_string ({STRING_32} "strongs") or else a_name.same_string ({STRING_32} "lemma")
				or else a_name.same_string ({STRING_32} "morph")
		end

	fail (a_message: STRING_32)
			-- Record a mistake at the next token, or at the end of the text.
		do
			if is_done then
				fail_at (a_message, end_position)
			else
				fail_at (a_message, peek.position)
			end
		end

	fail_at (a_message: STRING_32; a_position: INTEGER)
			-- Record a mistake at `a_position', unless an earlier one stands.
		do
			if not has_failed then
				has_failed := True
				error_message := a_message
				error_position := a_position
			end
		ensure
			failed: has_failed
		end

invariant
	index_valid: index >= 1

end
