note
	description: "The tests under simple_testing on the PC. The bodies are in SB_FOLD_CASES and SB_DATA_CASES."
	author: "Larry Rix"
	testing: "covers"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

	SB_FOLD_CASES
		undefine
			default_create
		end

	SB_DATA_CASES
		undefine
			default_create
		end

feature {NONE} -- The check

	check_that (a_tag: STRING_8; a_condition: BOOLEAN)
			-- <Precursor>
		do
			assert (a_tag, a_condition)
		end

feature {NONE} -- The environment

	app_database: STRING_32
			-- <Precursor>
		do
			if attached (create {EXECUTION_ENVIRONMENT}).item ("SB_APP_DB") as al_path then
				Result := al_path.to_string_32
			else
				Result := {STRING_32} "EIFGENs/app_copy.db"
			end
		end

	scratch_folder: STRING_32
			-- <Precursor>
		local
			l_directory: DIRECTORY
		do
			if attached (create {EXECUTION_ENVIRONMENT}).item ("SB_SCRATCH") as al_path then
				Result := al_path.to_string_32
			else
				Result := {STRING_32} "EIFGENs/scratch"
			end
			create l_directory.make_with_name (Result)
			if not l_directory.exists then
				l_directory.recursive_create_dir
			end
		end

end
