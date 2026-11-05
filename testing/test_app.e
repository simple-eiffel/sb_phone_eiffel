note
	description: "Test application for the SB Phone Eiffel project."
	author: "Larry Rix"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run the tests.
		local
			l_tests: LIB_TESTS
			l_cases: ARRAYED_LIST [TUPLE [name: STRING_8; test: PROCEDURE]]
			i: INTEGER
		do
			print ("Running SB Phone Eiffel tests...%N%N")
			create l_tests
			l_cases := l_tests.all_cases
			from
				i := 1
			until
				i > l_cases.count
			loop
				run_test (l_cases [i].test, l_cases [i].name)
				i := i + 1
			end
			l_cases := l_tests.all_data_cases
			from
				i := 1
			until
				i > l_cases.count
			loop
				run_test (l_cases [i].test, l_cases [i].name)
				i := i + 1
			end
			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")
			if failed > 0 then
				print ("TESTS FAILED%N")
				(create {EXCEPTIONS}).die (1)
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Test Runners

	run_test (a_test: PROCEDURE; a_name: STRING_8)
			-- Run a single test and update counters.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name + "%N")
			if attached (create {EXCEPTION_MANAGER}).last_exception as al_ex and then attached al_ex.description as al_d then
				print ("    " + al_d.to_string_8 + "%N")
			end
			failed := failed + 1
			l_retried := True
			retry
		end

feature {NONE} -- Access

	passed, failed: INTEGER
			-- The counts.

end
