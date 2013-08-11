note
	component:   "openEHR ADL Tools"
	description: "[
				 Abstract parent type of domain specific constraint types. This
				 type guarantees that any descendant can be converted to a standard
				 ADL object form, consisting of a network of C_COMPLEX_OBJECT and 
				 C_ATTRIBUTE instances.
				 ]"
	keywords:    "test, ADL"
	author:      "Thomas Beale <thomas.beale@oceaninformatics.com>"
	support:     "http://www.openehr.org/issues/browse/AWB"
	copyright:   "Copyright (c) 2004- Ocean Informatics Pty Ltd <http://www.oceaninfomatics.com>"
	license:     "Apache 2.0 License <http://www.apache.org/licenses/LICENSE-2.0.html>"

deferred class C_DOMAIN_TYPE

inherit
	C_LEAF_OBJECT
		rename
			safe_deep_twin as c_safe_deep_twin
		redefine
			enter_subtree, exit_subtree, node_id, rm_type_name
		end

	DT_CONVERTIBLE
		redefine
			synchronise_to_tree, finalise_dt, safe_deep_twin
		end

feature -- Initialisation

	make_dt (make_args: detachable ARRAY[ANY])
			-- make used by DT_OBJECT_CONVERTER
		do
		end

feature -- Finalisation

	finalise_dt
			-- used by DT_OBJECT_CONVERTER
		do
			if attached node_id as nid and then not nid.is_empty then
				create representation_cache.make (nid)
			else
				create representation_cache.make_anonymous
			end
			representation.set_content (Current)
		end

feature -- Access

	rm_type_name: STRING
			-- type name from reference model, of object to instantiate
		attribute
			create Result.make_from_string (generator.substring (3, generator.count))
		end

	node_id: STRING
		attribute
			create Result.make_empty
		end

feature -- AOM type mappings

	rm_type_mapping: detachable AOM_TYPE_MAPPING
			-- optional mapping from property names in descendants of this type to property names in
			-- an RM type

	rm_property_name (a_key: STRING): STRING
			-- return the name of a property name that is either a native one of this class,
			-- or else a mapped name from a reference model in use by the compiler
		do
			if attached rm_type_mapping as rm_tm and then rm_tm.property_mappings.has (a_key) and then attached rm_tm.property_mappings.item (a_key) as prop_mapping then
				Result := prop_mapping.target_property_name
			else
				Result := a_key
			end
		end

feature -- Statistics

	constrained_rm_attributes: ARRAYED_SET [STRING]
			-- report which attributes of the equivalent RM type are being constrained here
		deferred
		end

feature -- Conversion

	standard_equivalent: C_COMPLEX_OBJECT
			-- standard equivalent constraint form for this subtype
		deferred
		end

feature -- Duplication

	safe_deep_twin: like Current
		local
			dt_c_obj: detachable DT_COMPLEX_OBJECT_NODE
		do
			if attached dt_representation as dt_co then
				dt_c_obj := dt_co
				dt_representation := Void
			end
			Result := c_safe_deep_twin
			if attached dt_c_obj as dt_co then
				dt_representation := dt_co
			end
		end

feature -- Modification

	set_rm_type_mapping (a_rm_type_mapping: attached like rm_type_mapping)
		do
			rm_type_mapping := a_rm_type_mapping
		end

feature -- Synchronisation

	synchronise_to_tree
			-- synchronise to parse tree representation
		do
			precursor
			if attached dt_representation as dt_rep then
				dt_rep.set_type_visible
				if node_id.is_empty and dt_rep.has_attribute ("node_id") then
					dt_rep.remove_attribute ("node_id")
				end
			end
		end

feature -- Visitor

	enter_subtree (visitor: C_VISITOR; depth: INTEGER)
			-- perform action at start of block for this node
		do
			synchronise_to_tree
			precursor (visitor, depth)
			visitor.start_c_domain_type (Current, depth)
		end

	exit_subtree (visitor: C_VISITOR; depth: INTEGER)
			-- perform action at end of block for this node
		do
			precursor (visitor, depth)
			visitor.end_c_domain_type (Current, depth)
		end

end


