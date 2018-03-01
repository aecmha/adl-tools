note
	component:   "openEHR ADL Tools"
	description: "Second order constraint"
	keywords:    "AOM, ADL"
	author:      "Thomas Beale <thomas.beale@openehr.org>"
	support:     "http://www.openehr.org/issues/browse/AWB"
	copyright:   "Copyright (c) 2013- The openEHR Foundation <http://www.openEHR.org>"
	license:     "Apache 2.0 License <http://www.apache.org/licenses/LICENSE-2.0.html>"

deferred class C_2ND_ORDER

inherit
	ITERABLE [ARCHETYPE_CONSTRAINT]

feature -- Initialisation

	make
		do
			create members.make (0)
		end

feature -- Access

	members: ARRAYED_LIST [attached like member_type]

	member_type: detachable ARCHETYPE_CONSTRAINT

	i_th_member (i: INTEGER): attached like member_type
		require
			i_in_range: i > 0 and i <= members.count
		do
			Result := members.i_th (i)
		end

	count: INTEGER
		do
			Result := members.count
		end

	new_cursor: INDEXABLE_ITERATION_CURSOR [attached like member_type]
			-- Fresh cursor associated with current structure
		do
			Result := members.new_cursor
		end

feature -- Comparison

	c_conforms_to (other: like Current; rm_type_conformance_checker: FUNCTION [ANY, TUPLE [STRING, STRING], BOOLEAN]): BOOLEAN
			-- True if this node is a subset of, or the same as `other'
		deferred
		end

	c_congruent_to (other: like Current): BOOLEAN
			-- True if Current and `other' are semantically the same locally (child objects may differ)
		deferred
		end

feature -- Modification

	put_member (a_member: attached like member_type)
		do
			members.extend (a_member)
			a_member.set_soc_parent (Current)
		end

end

