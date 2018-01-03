note
	component:   "openEHR ADL Tools"
	description: "[
				 ADL object nodes that are defined in line, rather than being
				 defined as references to exterior resources.
				 ]"
	keywords:    "ADL"
	author:      "Thomas Beale <thomas.beale@oceaninformatics.com>"
	support:     "http://www.openehr.org/issues/browse/AWB"
	copyright:   "Copyright (c) 2006- The openEHR Foundation <http://www.openEHR.org>"
	license:     "Apache 2.0 License <http://www.apache.org/licenses/LICENSE-2.0.html>"

deferred class C_DEFINED_OBJECT

inherit
	C_OBJECT

feature -- Access

	prototype_value: ANY
			-- 	generate a default value from this constraint object
		deferred
		end

feature -- Status Report

	any_allowed: BOOLEAN
			-- True if any value allowed - only type is constrained
		deferred
		end

	valid_value (a_value: like prototype_value): BOOLEAN
		deferred
		end

end


