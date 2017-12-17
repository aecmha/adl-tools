note
	component:   "openEHR ADL Tools"
	description: "Descriptor of a model node in a directory of archetypes"
	keywords:    "ADL, archetype"
	author:      "Thomas Beale <thomas.beale@openehr.org>"
	support:     "http://www.openehr.org/issues/browse/AWB"
	copyright:   "Copyright (c) 2006- The openEHR Foundation <http://www.openEHR.org>"
	license:     "Apache 2.0 License <http://www.apache.org/licenses/LICENSE-2.0.html>"

deferred class ARCH_LIB_MODEL_ITEM

inherit
	ARCH_LIB_ITEM
		redefine
			parent
		end

feature -- Access

	group_name: STRING
			-- Name distinguishing the type of item and the group to which its `repository' belongs.
			-- Useful as a logical key to pixmap icons, etc.

	qualified_name: IMMUTABLE_STRING_8
			-- name of this node

	name: STRING
			-- class_name

feature -- Status Report

	has_artefacts: BOOLEAN
			-- True if there are any archetypes at or below this point
		do
			Result := across subtree_artefact_counts as counts_csr some counts_csr.item > 0 end
		end

feature {ARCH_LIB_ITEM} -- Implementation

	parent: detachable ARCH_LIB_MODEL_ITEM
			-- parent node

end



