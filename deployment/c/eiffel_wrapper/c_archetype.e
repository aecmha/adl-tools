note
	component:   "openEHR ADL Tools"
	description: "[
			 C wrapper for ARCHETYPE. In this wrapper, the following
			 transformations are made:
			 	- incoming C String arguments are converted to Eiffel Strings
			 	- C String return values are converted from Eiffel STRINGs to C Strings
				- all arguments and return values of complex object types (i.e. types other 
				  than String, Integer, Boolean, Real, Char) are replaced by Integer handles,
				  which are keys to the objects maintained in the single instance of this 
				  class.
			 ]"
	keywords:    "C wrapper"
	author:      "Thomas Beale"
	support:     "Ocean Informatics <support@OceanInformatics.biz>"
	copyright:   "Copyright (c) 2004 Ocean Informatics Pty Ltd"
	license:     "Apache 2.0 License <http://www.apache.org/licenses/LICENSE-2.0.html>"


class C_ARCHETYPE

inherit
	SHARED_ARCHETYPE_COMPILER
		export
			{NONE} all
		end

	SHARED_ADL_OBJECTS
		export
			{NONE} all
		end

	C_WRAPPER_TOOLS
		export
			{NONE} all
		end

feature -- Definitions

	Default_concept_code: POINTER
			-- "at0000"
		local
			obj: ANY
		do
			obj := archetype_compiler.archetype.Default_concept_code.to_c
			Result := $obj
		end

feature -- Access

	archetype_id: POINTER
			-- archetype_id as a string
		local
			obj: ANY
		do
			obj := archetype_compiler.archetype.archetype_id.as_string.to_c
			Result := $obj
		end

	archetype_parent_archetype_id: POINTER
			-- id of specialisation parent of this archetype
		local
			obj: ANY
		do
			obj := archetype_compiler.archetype.parent_archetype_id.as_string.to_c
			Result := $obj
		end

	archetype_concept_code: POINTER
			-- concept_code as a string
		local
			obj: ANY
		do
			obj := archetype_compiler.archetype.concept.to_c
			Result := $obj
		end

	archetype_specialisation_depth: INTEGER
			-- infer number of levels of specialisation from concept code
		do
			Result := archetype_compiler.archetype.specialisation_depth
		end

	archetype_version: POINTER
			-- version of this archetype, according to its id
		local
			obj: ANY
		do
			obj := archetype_compiler.archetype.version.to_c
			Result := $obj
		end

	archetype_errors: POINTER
			-- validity errors in this archetype
		local
			obj: ANY
		do
			-- FIXME: This did not compile because of revision 319. What should it do?
			obj := archetype_compiler.archetype.errors.to_c
			Result := $obj
		end

	archetype_warnings: POINTER
			-- validity warnings for this archetype
		local
			obj: ANY
		do
			-- FIXME: This did not compile because of revision 319. What should it do?
			obj := archetype_compiler.archetype.warnings.to_c
			Result := $obj
		end

	archetype_logical_paths (a_lang: POINTER): POINTER
			-- paths with human readable terms substituted
			-- REQUIRE
			-- a_lang /= void and then ontology.languages_available.has (a_lang)
		local
			c_a_lang: BASE_C_STRING
		do
			create c_a_lang.make_by_pointer (a_lang)
			Result := eif_list_string_to_c_array (archetype_compiler.archetype.logical_paths (c_a_lang.string))
		end

	archetype_logical_paths_count: INTEGER
			-- SUPPORT FUNCTION SOLELY FOR USE BY JNI LAYER TO DISCOVER ARRAY LENGTH
		do
			Result := archetype_compiler.archetype.physical_paths.count
		end

	archetype_physical_paths: POINTER
			-- generate physical paths from definition structure
		do
			Result := eif_list_string_to_c_array (archetype_compiler.archetype.physical_paths)
		end

	archetype_physical_paths_count: INTEGER
			-- SUPPORT FUNCTION SOLELY FOR USE BY JNI LAYER TO DISCOVER ARRAY LENGTH
		do
			Result := archetype_compiler.archetype.physical_paths.count
		end

	archetype_physical_to_logical_path (a_phys_path: POINTER; a_lang: POINTER): POINTER
			-- generate a logical path in 'a_lang' from a physical path
			-- REQUIRE
			-- phys_path_valid: a_phys_path /= void and then not a_phys_path.is_empty
			-- lang_valid: a_lang /= void and then not a_lang.is_empty
		local
			c_a_phys_path, c_a_lang: BASE_C_STRING
			obj: ANY
		do
			create c_a_phys_path.make_by_pointer (a_phys_path)
			create c_a_lang.make_by_pointer (a_lang)
			obj := archetype_compiler.archetype.physical_to_logical_path (c_a_phys_path.string, c_a_lang.string).to_c
			Result := $obj
		end

	archetype_definition: INTEGER
			-- integer handle to archetype definition (a C_COMPLEX_OBJECT)
		do
			Result := adl_objects.archetype_definition_handle
		end

feature -- Modification

	archetype_convert_to_specialised (a_spec_concept: POINTER)
			-- convert this arcehtype to being a specialised version of itself
			-- one level down
			-- REQUIRE
			-- concept_valid: a_spec_concept /= void and then not a_spec_concept.is_empty
		local
			c_a_spec_concept: BASE_C_STRING
		do
			create c_a_spec_concept.make_by_pointer (a_spec_concept)
			archetype_compiler.archetype.convert_to_specialised (c_a_spec_concept.string)
		end

	archetype_reset_definition
			-- set definition back to its original state - just the root
			-- node with all children gone
		do
			archetype_compiler.archetype.reset_definition
		end

	archetype_set_definition_node_id (a_term_code: POINTER)
			-- set the node_id of the archetype root node to a_term_id
			-- REQUIRE
			--  valid_term_code: ontology.has_term_code (a_term_code)
		local
			c_a_term_code: BASE_C_STRING
		do
			create c_a_term_code.make_by_pointer (a_term_code)
			archetype_compiler.archetype.set_definition_node_id (c_a_term_code.string)
		end

feature -- Status Report

	archetype_has_physical_path (a_path: POINTER): BOOLEAN
			-- true if physical path `a_path' exists in this archetype
		local
			c_a_path: BASE_C_STRING
		do
			create c_a_path.make_by_pointer (a_path)
			Result := archetype_compiler.archetype.has_physical_path (c_a_path.string)
		end

	archetype_has_warnings: BOOLEAN
			-- True if warnings from last call to validate
		do
			-- FIXME: This did not compile because of revision 319. What should it do?
			Result := archetype_compiler.archetype.has_warnings
		end

	archetype_is_specialised: BOOLEAN
			-- 	True if this archetype identifies a specialisation parent
		do
			Result := archetype_compiler.archetype.is_specialised
		end

	archetype_is_valid: BOOLEAN
			-- is archetype in valid state?
		do
			Result := archetype_compiler.archetype.is_valid
		end

end



