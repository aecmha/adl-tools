note
	component:   "openEHR ADL Tools"
	description: "Perform overlaying of template fillers onto flattened core template."
	keywords:    "archetype, comparison, constraint model"
	author:      "Thomas Beale <thomas.beale@openehr.org>"
	support:     "http://www.openehr.org/issues/browse/AWB"
	copyright:   "Copyright (c) 2014- The openEHR Foundation <http://www.openEHR.org>"
	license:     "Apache 2.0 License <http://www.apache.org/licenses/LICENSE-2.0.html>"

class TEMPLATE_FLATTENER

inherit
	SHARED_ARCHETYPE_LIBRARIES
		export
			{NONE} all;
			{ANY} deep_copy, deep_twin, is_deep_equal, standard_is_equal
		end

feature -- Access

	opt: OPERATIONAL_TEMPLATE
		attribute
			create Result.default_create
		end

feature -- Commands

	execute (a_template: TEMPLATE)
			-- create with source (differential) archetype of archetype for which we wish to generate a flat archetype
		require
			Template_valid: a_template.is_valid and then a_template.is_flat
		do
			create opt.make_from_other (a_template)

			overlay_filler_definitions (opt, 0)
			opt.rebuild
		end

feature {NONE} -- Implementation

	overlay_filler_definitions (a_flat_arch: ARCHETYPE; depth: INTEGER)
			-- process `template.suppliers_index' to overlay target definitions.
		require
			a_flat_arch.is_flat
		local
			supp_flat_arch, matched_arch: ARCHETYPE
			supp_arch_root_cco: C_COMPLEX_OBJECT
		do
debug ("overlay")
	io.put_string ("&&&&&& flattening template root nodes &&&&&&%N")
end
			-- limit depth in case of recursive inclusion
			if depth <= Max_template_overlay_depth then
				across a_flat_arch.suppliers_index as xref_idx_csr loop
					-- get the definition structure of the flat archetype corresponding to the archetype id in the suppliers list
					check attached current_library.archetype_matching_ref (xref_idx_csr.key) as att_ala then
						matched_arch := att_ala.flat_archetype
					end

					-- prevent cycling due to inclusion of current archetype (FIXME: won't catch indirect recursion)
					if not matched_arch.archetype_id.physical_id.is_equal (opt.archetype_id.physical_id) then
						create supp_flat_arch.make_from_other (matched_arch)
						supp_arch_root_cco := supp_flat_arch.definition

						-- add the terminology of this archetype to the OPT component_terminologies
						if not opt.has_component_terminology (supp_flat_arch.archetype_id.physical_id) then
							opt.add_component_terminology (supp_flat_arch.terminology, supp_flat_arch.archetype_id.physical_id)
						end

						-- get list of C_ARCHETYPE_ROOT nodes in this archetype or template corresponding to the supplier
						-- archetype id xref_idx.key_for_iteration into each one of these C_ARCHETYPE_ROOT nodes, clone the
						-- flat definition structure from the supplier archetype
						across xref_idx_csr.item as c_arch_roots_csr loop
							-- it is empty and needs to be filled
							if not c_arch_roots_csr.item.has_attributes and not c_arch_roots_csr.item.is_prohibited then
								-- perform overlays on supplier archetype first
								overlay_filler_definitions (supp_flat_arch, depth + 1)
debug ("overlay")
	io.put_string ("%T node at " + c_arch_roots_csr.item.path +
	" with " + xref_idx_csr.key + "%N")
end
								c_arch_roots_csr.item.convert_to_flat (matched_arch.archetype_id)
								across supp_arch_root_cco.attributes as attrs_csr loop
									c_arch_roots_csr.item.put_attribute (attrs_csr.item)
debug ("overlay")
	io.put_string ("%T%T cloning attribute " +
	attrs_csr.item.rm_attribute_path + "%N")
end
								end
							end
						end
					end
				end
			end
		end

end

