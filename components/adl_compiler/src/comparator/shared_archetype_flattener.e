note
	component:   "openEHR ADL Tools"
	description: "Shared access to application root object"
	keywords:    "application, ADL"
	author:      "Thomas Beale <thomas.beale@openehr.org>"
	support:     "http://www.openehr.org/issues/browse/AWB"
	copyright:   "Copyright (c) 2010- The openEHR Foundation <http://www.openEHR.org>"
	license:     "Apache 2.0 License <http://www.apache.org/licenses/LICENSE-2.0.html>"

class SHARED_ARCHETYPE_FLATTENER

feature -- Access

	arch_flattener: ARCHETYPE_FLATTENER
		once
			create Result
		end

	rm_flattener: RM_FLATTENER
		once
			create Result
		end

end



