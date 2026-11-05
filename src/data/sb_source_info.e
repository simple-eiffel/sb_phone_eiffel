note
	description: "One source of the data, with its license."
	author: "Larry Rix"

class
	SB_SOURCE_INFO

create
	make

feature {NONE} -- Initialization

	make (a_code, a_name, a_kind, a_license, a_credit, a_url: STRING_32; a_share_alike: BOOLEAN)
			-- Create the record.
		do
			code := a_code
			name := a_name
			kind := a_kind
			license := a_license
			credit := a_credit
			url := a_url
			share_alike := a_share_alike
		ensure
			code_set: code = a_code
			name_set: name = a_name
			kind_set: kind = a_kind
			license_set: license = a_license
			credit_set: credit = a_credit
			url_set: url = a_url
			share_alike_set: share_alike = a_share_alike
		end

feature -- Access

	code, name, kind, license, credit, url: STRING_32
			-- What it is.

	share_alike: BOOLEAN
			-- Is its license share-alike?

end
