note
	component:   "openEHR ADL Tools"
	description: "Archetype abstraction"
	keywords:    "archetype"
	author:      "Thomas Beale <thomas.beale@oceaninformatics.com>"
	support:     "http://www.openehr.org/issues/browse/AWB"
	copyright:   "Copyright (c) 2003- Ocean Informatics Pty Ltd <http://www.oceaninfomatics.com>"
	license:     "Apache 2.0 License <http://www.apache.org/licenses/LICENSE-2.0.html>"

 class ARCHETYPE

inherit
	ARCHETYPE_DEFINITIONS
		export
			{NONE} all;
			{ANY} deep_twin, valid_standard_version
		end

	ADL_2_TERM_CODE_TOOLS
		export
			{NONE} all;
			{ANY} deep_twin, specialisation_depth_from_code, is_valid_code
		end

	AUTHORED_RESOURCE
		redefine
			make_from_other, add_language_tag
		end

create {ADL_14_ENGINE, ADL_2_ENGINE, ARCHETYPE}
	make

create {P_ARCHETYPE}
	make_all

create {ARCHETYPE_COMPARATOR, ARCH_LIB_ARCHETYPE_ITEM}
	make_differential_from_flat

create {ARCHETYPE_FLATTENER}
	make_flat_specialised, make_flat_non_specialised

create {ARCHETYPE_FLATTENER, ARCH_LIB_ARCHETYPE_EDITABLE}
	make_from_other

create {ARCH_LIB_ARCHETYPE_ITEM}
	make_empty_differential, make_empty_differential_child

feature -- Initialisation

	make_dt (make_args: ARRAY[ANY])
			-- basic make routine to guarantee validity on creation
		do
		end

	make (an_artefact_type: like artefact_type;
			an_id: like archetype_id;
			an_rm_release: like rm_release;
			an_original_language: like original_language;
			a_uid: like uid;
			a_description: like description;
			a_definition: like definition;
			a_terminology: like terminology)
				-- make from pieces, typically obtained by parsing
		require
			Description_valid: not an_artefact_type.is_overlay implies attached a_description
		do
			artefact_type := an_artefact_type
			adl_version := 	Latest_adl_version
			rm_release := an_rm_release
			archetype_id := an_id
			original_language := an_original_language
			description := a_description
			definition := a_definition
			terminology := a_terminology
			is_dirty := True
			is_differential := a_terminology.is_differential
			uid := a_uid

			set_terminology_agents
		ensure
			Artefact_type_set: artefact_type = an_artefact_type
			Adl_version_set: adl_version = Latest_adl_version
			Id_set: archetype_id = an_id
			Original_language_set: original_language = an_original_language
			Definition_set: definition = a_definition
			Terminology_set: terminology = a_terminology
			Is_dirty: is_dirty
			Is_differential_follows_terminology: is_differential = a_terminology.is_differential
			Not_generated: not is_generated
		end

	make_all (an_artefact_type: like artefact_type;
			an_adl_version: STRING;
			an_rm_release: like rm_release;
			an_id: like archetype_id;
			a_parent_archetype_id: like parent_archetype_id;
			is_controlled_flag: BOOLEAN;
			a_uid: like uid;
			an_other_metadata: like other_metadata;
			an_original_language: like original_language;
			a_translations: like translations;
			a_description: like description;
			a_definition: like definition;
			a_rules: like rules;
			a_terminology: like terminology;
			an_annotations: like annotations)
				-- make from all possible items
		require
			Translations_valid: attached a_translations as att_trans implies not att_trans.is_empty
			Description_valid: not an_artefact_type.is_overlay implies attached a_description
			Invariants_valid: attached a_rules as att_rules implies not att_rules.is_empty
		do
			make (an_artefact_type, an_id, an_rm_release,
					an_original_language, a_uid,
					a_description,
					a_definition, a_terminology)
			parent_archetype_id := a_parent_archetype_id
			translations := a_translations
			adl_version := an_adl_version
			is_controlled := is_controlled_flag
			other_metadata := an_other_metadata
			rules := a_rules
			annotations := an_annotations
		ensure
			Artefact_type_set: artefact_type = an_artefact_type
			Adl_version_set: adl_version = an_adl_version
			Rm_release_set: rm_release = an_rm_release
			Is_controlled_set: is_controlled = is_controlled_flag
			Id_set: archetype_id = an_id
			Parent_id_set: parent_archetype_id = a_parent_archetype_id
			Original_language_set: original_language = an_original_language
			Translations_set: translations = a_translations
			Definition_set: definition = a_definition
			Invariants_set: rules = a_rules
			Terminology_set: terminology = a_terminology
			Is_differential_follows_terminology: is_differential = a_terminology.is_differential
			Is_dirty: is_dirty
			Not_generated: not is_generated
		end

	make_from_other (other: like Current)
			-- duplicate from another archetype
		local
			other_parent_arch_id: detachable STRING
			other_annotations: detachable RESOURCE_ANNOTATIONS
			other_description: detachable RESOURCE_DESCRIPTION
			other_translations: detachable HASH_TABLE [TRANSLATION_DETAILS, STRING]
			other_invariants: detachable  ARRAYED_LIST [ASSERTION]
			other_other_metadata: detachable HASH_TABLE [STRING, STRING]
		do
			if attached other.parent_archetype_id as other_pid then
				other_parent_arch_id := other_pid.deep_twin
			end
			if attached other.translations as other_trans then
				other_translations := other_trans.deep_twin
			end
			if attached other.description as other_desc then
				other_description := other_desc.deep_twin
			end
			if attached other.annotations as other_annots then
				other_annotations := other_annots.deep_twin
			end
			if other.has_rules then
				other_invariants := other.rules.deep_twin
			end
			if attached other.other_metadata then
				other_other_metadata := other.other_metadata.deep_twin
			end
			make_all (other.artefact_type.twin, other.adl_version.twin, other.rm_release.twin, other.archetype_id.deep_twin,
					other_parent_arch_id, other.is_controlled, other.uid, other_other_metadata,
					other.original_language.deep_twin, other_translations,
					other_description, other.definition.deep_twin, other_invariants,
					other.terminology.deep_twin, other_annotations)
			is_generated := other.is_generated
			is_valid := other.is_valid
			is_differential := other.is_differential

			rebuild
		ensure then
			Is_generated_preserved: is_generated = other.is_generated
			Is_valid_preserved: is_valid = other.is_valid
			Is_differential_preserved: is_differential = other.is_differential
		end

feature {ARCH_LIB_ARCHETYPE_ITEM} -- Initialisation

	make_empty_differential (an_artefact_type: ARTEFACT_TYPE; an_id: like archetype_id; an_rm_release, an_original_language: STRING)
			-- make a new differential form archetype
		require
			Language_valid: not an_original_language.is_empty
		do
			artefact_type := an_artefact_type
			archetype_id := an_id
			create adl_version.make_from_string (Latest_adl_version)
			rm_release := an_rm_release
			create terminology.make_differential_empty (an_original_language, 0)
			create original_language.make (ts.Default_language_code_set, an_original_language)
			create description.default_create
			create definition.make (an_id.rm_class, terminology.concept_code.twin)
			is_dirty := True
			is_valid := True
			is_differential := True
		ensure
			Artefact_type_set: artefact_type = an_artefact_type
			Adl_version_set: adl_version.same_string (Latest_adl_version)
			Rm_release_set: rm_release = an_rm_release
			Id_set: archetype_id = an_id
			Original_language_set: original_language.code_string.is_equal (an_original_language)
			terminology_original_language_set: original_language.code_string.is_equal (terminology.original_language)
			Not_specialised: not is_specialised
			Not_generated: not is_generated
			Is_dirty: is_dirty
			Is_valid: is_valid
			Is_differential: is_differential
		end

	make_empty_differential_child (an_artefact_type: ARTEFACT_TYPE; spec_depth: INTEGER; an_id: like archetype_id; a_parent_id, an_rm_release, an_original_language: STRING)
			-- make a new differential form archetype as a child of `a_parent'
		require
			Language_valid: not an_original_language.is_empty
		do
			make_empty_differential (an_artefact_type, an_id, an_rm_release, an_original_language)
			parent_archetype_id := a_parent_id
		ensure
			Artefact_type_set: artefact_type = an_artefact_type
			Adl_version_set: adl_version.same_string (Latest_adl_version)
			Rm_release_set: rm_release = an_rm_release
			Id_set: archetype_id = an_id
			Original_language_set: original_language.code_string.is_equal (an_original_language)
			Terminology_original_language_set: original_language.code_string.is_equal (terminology.original_language)
			Not_generated: not is_generated
			Is_dirty: is_dirty
			Is_valid: is_valid
			Is_differential: is_differential
			Parent_archetype_id_set: parent_archetype_id = a_parent_id
		end

feature {ARCHETYPE_COMPARATOR, ARCH_LIB_ARCHETYPE_ITEM} -- Initialisation

	make_differential_from_flat (a_flat: ARCHETYPE)
			-- make a differential archetype using components (not copies) of a flat archetype; used to support
			-- legacy archetyps that are parsed in a flat form but have to be converted to differential form
		require
			a_flat.is_flat
		do
			make_all (a_flat.artefact_type, Latest_adl_version, a_flat.rm_release, a_flat.archetype_id, a_flat.parent_archetype_id,
					a_flat.is_controlled, a_flat.uid, a_flat.other_metadata, a_flat.original_language, a_flat.translations,
					a_flat.description, a_flat.definition, a_flat.rules,
					a_flat.terminology.to_differential, a_flat.annotations)
			is_generated := True
			is_differential := True
			rebuild
		ensure
			is_generated
			is_differential
		end

feature {ARCHETYPE_FLATTENER} -- Initialisation

	make_flat_non_specialised (a_diff: ARCHETYPE)
			-- Create a new flat archetype from a top-level differential archetype
		require
			a_diff.is_differential and not a_diff.is_specialised
		do
			make (a_diff.artefact_type.deep_twin, a_diff.archetype_id.deep_twin,
					a_diff.rm_release.twin,
					a_diff.original_language.deep_twin,
					a_diff.uid,
					a_diff.description.deep_twin,
					a_diff.definition.deep_twin, a_diff.terminology.to_flat)
			if attached a_diff.translations as a_diff_trans then
				translations := a_diff_trans.deep_twin
			end
			if attached a_diff.rules as a_diff_invs then
				rules := a_diff_invs.deep_twin
			end
			if attached a_diff.annotations as a_diff_annots then
				annotations := a_diff_annots.deep_twin
			end
			is_generated := a_diff.is_generated
			is_valid := True

			rebuild
		ensure
			Generated: is_generated = a_diff.is_generated
			Top_level: not is_specialised
			Is_flat: is_flat
			Is_valid: is_valid
		end

	make_flat_specialised (a_diff, a_flat_parent: ARCHETYPE)
			-- Create a new flat archetype from a differential archetype and its flat parent, as preparation
			-- for generating a flat archetype. The following items from the differential are used:
			-- 	* artefact_type
			--	* archetype_id
			--	* uid
			--	* original_language
			--	* translations
			--
			-- The following items from the flat parent:
			-- 	* definition (with root node id from differential definition)
			--  * terminology !!! with languages removed that are not in the orig_lang/translations of the diff
			-- 	* rules
			--	* annotations
			--
		require
			Conformance: a_diff.is_differential and a_flat_parent.is_flat
			Valid_specialisation_relationship: a_diff.specialisation_depth = a_flat_parent.specialisation_depth + 1
		local
			desc: like description
			flat_terminology: ARCHETYPE_TERMINOLOGY
		do
			-- basic identifying info, and language from from child
			-- definition comes from parent, waiting for flattening of child on top
			-- ontology comes from child, waiting for parent items to be merged on top
			if attached a_diff.description as orig_desc then
				desc := orig_desc.deep_twin
			end

			flat_terminology := a_flat_parent.terminology.deep_twin
			flat_terminology.reduce_languages_to (a_diff.terminology)

			make (a_diff.artefact_type.deep_twin, a_diff.archetype_id.deep_twin,
					a_diff.rm_release.twin,
					a_diff.original_language.deep_twin, a_diff.uid, desc,
					a_flat_parent.definition.deep_twin,
					flat_terminology)
			definition.set_node_id (a_diff.definition.node_id.twin)

			-- other metadata is created from parent, with child meta-data
			-- merged on top, overwriting any values of the same key
			if attached a_flat_parent.other_metadata as att_md then
				other_metadata := att_md.deep_twin
			end

			-- translations are what is available in the child archetype
			if attached a_diff.translations as a_diff_trans then
				translations := a_diff_trans.deep_twin
			end

			-- rules starts with what is in the parent archetype and
			-- child invariants are merged
			if attached a_flat_parent.rules as parent_rules then
				rules := parent_rules.deep_twin
			end

			-- annotations starts with what is in the parent archetype and
			-- child annotations are merged
			if attached a_flat_parent.annotations as parent_annots then
				annotations := parent_annots.deep_twin
			end

			is_generated := a_diff.is_generated
			is_valid := True

			rebuild
		ensure
			Generated: is_generated = a_diff.is_generated
			Specialised: is_specialised
			Is_flat: is_flat
			Is_valid: is_valid
		end

feature -- Access

	uid: detachable HIER_OBJECT_ID
			-- optional UID identifier of this artefact
			-- FIXME: should really be in AUTHORED_RESOURCE

	archetype_id: ARCHETYPE_HRID

	other_metadata: detachable HASH_TABLE [STRING, STRING]

	adl_version: STRING
			-- Semver.org compatible version of ADL/AOM used in this archetype

	rm_release: STRING
			-- Semver.org compatible release of the reference model on which the archetype was based.
			-- This does not imply conformance only to this release, since an archetype may
			-- be valid with respect to multiple releases of a reference model. Conformance is captured
			-- outside of the archetype.

	artefact_type: ARTEFACT_TYPE
			-- design type of artefact, archetype, template, template-component, etc

	parent_archetype_id: detachable STRING
			-- reference to specialisation parent of this archetype, typically in
			-- the form of a semantic id, i.e. with no minor or patch version

	specialisation_depth: INTEGER
			-- infer number of levels of specialisation from concept code
		do
			Result := specialisation_depth_from_code (concept_id)
		ensure
			non_negative: Result >= 0
		end

	concept_id: STRING
			-- at-code of concept of the archetype as a whole and the code of its root node
		do
			Result := definition.node_id
		end

	definition: C_COMPLEX_OBJECT

	rules: detachable ARRAYED_LIST [ASSERTION]

	terminology: ARCHETYPE_TERMINOLOGY

feature -- Paths

	path_map: HASH_TABLE [ARCHETYPE_CONSTRAINT, STRING]
			-- get the full path map of the archetype, including paths created by
			-- proxy objects
		do
			if attached path_map_cache as pmc then
				Result := pmc
			else
				Result := definition.path_map
				path_map_cache := Result
			end
		end

	all_paths: ARRAYED_LIST [STRING]
			-- all paths from definition structure
		do
			-- filter out paths that key C_PRIMITIVE_OBJECTs, since their immediate attribute parent  paths are the
			-- same, minus the useless terminal node id id9999
			Result := all_paths_filtered (agent (ac: ARCHETYPE_CONSTRAINT): BOOLEAN do Result := not attached {C_PRIMITIVE_OBJECT} ac end)
		ensure
			Result.object_comparison
		end

	leaf_paths: ARRAYED_LIST [STRING]
			-- paths from definition structure C_PRIMITIVE_OBJECTs only
		do
			Result := all_paths_filtered (agent (ac: ARCHETYPE_CONSTRAINT): BOOLEAN do Result := attached {C_ATTRIBUTE} ac as ca and then ca.is_leaf_parent end)
		ensure
			Result.object_comparison
		end

	leaf_paths_annotated (a_lang: STRING): ARRAYED_LIST [STRING]
			-- paths from definition structure C_PRIMITIVE_OBJECTs only; annotated from terminology
		do
			create Result.make (0)
			Result.compare_objects
			across leaf_paths as paths_csr loop
				Result.extend (annotated_path (paths_csr.item, a_lang, True))
			end
		ensure
			Result.object_comparison
		end

	all_paths_filtered (a_filter: FUNCTION [ANY, TUPLE [ARCHETYPE_CONSTRAINT], BOOLEAN]): ARRAYED_LIST [STRING]
			-- all paths from definition structure filtered by `a_filter'; inclusion if filter
			-- returns True
		do
			create Result.make (0)
			Result.compare_objects
			across path_map as all_paths_csr loop
				if a_filter.item ([all_paths_csr.item]) then
					Result.extend (all_paths_csr.key)
				end
			end
		ensure
			Result.object_comparison
		end

	all_paths_annotated (a_lang: STRING): ARRAYED_LIST [STRING]
			-- all paths from definition structure; annotated from terminology
		do
			create Result.make (0)
			Result.compare_objects
			across all_paths as paths_csr loop
				Result.extend (annotated_path (paths_csr.item, a_lang, True))
			end
		ensure
			Result.object_comparison
		end

	all_interface_tags (a_language: STRING): HASH_TABLE [STRING, STRING]
			-- generate a table of tags suitable for use in XSD, programming languages,
			-- keyed by physical path
		do
			Result := interface_tags (a_language, all_paths)
		end

	interface_tags (a_language: STRING; path_set: ARRAYED_LIST [STRING]): HASH_TABLE [STRING, STRING]
			-- convert `path_set' to a hash of interface tags, keyed by path
		require
			a_lang_valid: not a_language.is_empty
		local
			og_phys_path, og_log_path: OG_PATH
			tag_path, tag, id_code: STRING
			an_arch_id: ARCHETYPE_HRID
		do
			create Result.make (0)
			across path_set as path_csr loop
				create og_phys_path.make_from_string (path_csr.item)
				create og_log_path.make_from_other (og_phys_path)

				-- generate a human-readable path from the physical path
				from
					og_phys_path.start
					og_log_path.start
				until
					og_phys_path.off
				loop
					if og_phys_path.item.is_addressable then
						id_code := og_phys_path.item.object_id

						-- only use the object address if it is valid (it could be an archetype id) and
						-- b) in the terminology (for objects under single-valued attributes, this is optional)
						if is_valid_id_code (id_code) and then terminology.has_id_code (id_code) then
							og_log_path.item.set_object_id (terminology.term_definition (a_language, id_code).text)
						elseif archetype_id.valid_id (id_code) then
							create an_arch_id.make_from_string (id_code)
							og_log_path.item.set_object_id (an_arch_id.concept_id)
						else
							og_log_path.item.clear_object_id
						end
					else
						og_log_path.item.clear_object_id
					end
					og_phys_path.forth
					og_log_path.forth
				end

				-- create a string from from the structured form of the path
				create tag_path.make (200)
				across og_log_path as path_seg_csr loop
					if path_seg_csr.item.is_addressable then
						tag_path.append (path_seg_csr.item.object_id)
					else
						tag_path.append (path_seg_csr.item.attr_name)
					end
					if not path_seg_csr.is_last then
						tag_path.append_character ('_')
					end
				end

				-- perform character-by-character replacements
				create tag.make (tag_path.count)
				across tag_path as char_csr loop
					if Adl_tag_remove_characters.has (char_csr.item) then
						-- do nothing
					elseif Adl_tag_underscore_characters.has (char_csr.item)  then
						tag.append_character ('_')
					elseif Adl_tag_character_replacements.has (char_csr.item) and then attached Adl_tag_character_replacements.item (char_csr.item) as rep_str then
						tag.append (rep_str)
					else
						tag.append_character (char_csr.item)
					end
				end

				-- Add the path to the result, unless it is the root, which is not useful in a set of interface tags
				if not tag.is_empty then
					Result.put (tag, og_phys_path.as_string)
				end
			end
		end

	rm_type_paths_annotated (a_lang, rm_type: STRING): ARRAYED_LIST [STRING]
			-- paths to C_OBJECT nodes which have type `rm_type', with human readable terms substituted
		require
			has_language: terminology.has_language (a_lang)
		local
			filt_paths: ARRAYED_LIST [STRING]
		do
			filt_paths := all_paths_filtered (
				agent (ac: ARCHETYPE_CONSTRAINT; an_rm_type: STRING): BOOLEAN
					do
						Result := attached {C_OBJECT} ac as co and then co.rm_type_name.is_equal (an_rm_type)
					end (?, rm_type)
			)
			create Result.make (0)
			Result.compare_objects
			across filt_paths as paths_csr loop
				Result.extend (annotated_path (paths_csr.item, a_lang, True))
			end
		end

	object_at_path (a_path: STRING): C_OBJECT
			-- find the c_object from the path_map matching the path; uses path map so as to pick up
			-- paths generated by internal references
		require
			a_path_valid: has_object_path (a_path)
		do
			Result := definition.object_at_path (a_path)
		end

	attribute_at_path (a_path: STRING): C_ATTRIBUTE
			-- find the C_ATTRIBUTE from the path_map matching the path; uses path map so as to pick up
			-- paths generated by internal references
		require
			a_path_valid: has_attribute_path (a_path)
		do
			Result := definition.attribute_at_path (a_path)
		end

	matching_path (a_path: STRING): detachable STRING
			-- Find longest path that matches a_path in this archetype. Useful for processing paths
			-- to primitive leaf objects, where the path refers to an object or attribute that is
			-- not actually specified within the archetype, i.e. only a parent object is.
			-- If asked on a flat archetype, result is a path anywhere in inheritance-flattened archetype;
			-- Will pick up paths generated by internal references
		local
			match_len: INTEGER
		do
			-- only compare paths of length > 1 to avoid matching '/'
			match_len := 1
			across all_paths as paths_csr loop
				if paths_csr.item.count > match_len and a_path.starts_with (paths_csr.item) then
					Result := paths_csr.item
					match_len := Result.count
				end
			end
		end

	annotated_path (a_phys_path, a_language: STRING; with_codes: BOOLEAN): STRING
			-- generate a logical path in 'a_language' from a physical path
			-- if `with_code' then generate annotated form of each code, i.e. "code|text|"
		require
			a_lang_valid: not a_language.is_empty
		local
			id_code, log_str: STRING
			og_phys_path, og_log_path: OG_PATH
		do
			create og_phys_path.make_from_string (a_phys_path)
			create og_log_path.make_from_other (og_phys_path)
			from
				og_phys_path.start
				og_log_path.start
			until
				og_phys_path.off
			loop
				if og_phys_path.item.is_addressable then
					id_code := og_phys_path.item.object_id
					if is_valid_id_code (id_code) and then terminology.has_id_code (id_code) then
						if with_codes then
							log_str := annotated_code (id_code, terminology.term_definition (a_language, id_code).text, "")
						else
							log_str := terminology.term_definition (a_language, id_code).text
						end
						og_log_path.item.set_object_id (log_str)
					else
						og_log_path.item.set_object_id (id_code)
					end
				end
				og_phys_path.forth
				og_log_path.forth
			end

			Result := og_log_path.as_string
		end

feature -- Status Report

	is_differential: BOOLEAN
			-- True if this archetype is differential

	is_flat: BOOLEAN
			-- True if this archetype is flat
		do
			Result := not is_differential
		end

	is_specialised: BOOLEAN
			-- 	True if this archetype identifies a specialisation parent
		do
			Result := specialisation_depth > 0
		end

	is_valid: BOOLEAN
			-- True if archetype is completely validated, including with respect to specialisation parents, where they exist

	is_dirty: BOOLEAN
			-- marker to be used to indicate if structure has changed in such a way that cached elements have to be regenerated,
			-- or re-validation is needed. Set to False after validation

	is_generated: BOOLEAN
			-- True if this archetype was generated from another one, rather than being an original authored archetype

	has_rules: BOOLEAN
			-- true if there are invariants
		do
			Result := attached rules
		end

	has_path (a_path: STRING): BOOLEAN
			-- True if a_path exists in this archetype. If asked on a flat archetype, result indicates whether path exists
			-- anywhere in inheritance-flattened archetype. ; uses path map so as to pick up paths generated by internal references
		do
			Result := definition.has_path (a_path)
		end

	has_object_path (a_path: STRING): BOOLEAN
			-- True if a_path exists in this archetype and refers to a C_OBJECT node
		do
			Result := definition.has_object_path (a_path)
		end

	has_attribute_path (a_path: STRING): BOOLEAN
			-- True if a_path exists in this archetype. If asked on a flat archetype, result indicates whether path exists
			-- anywhere in inheritance-flattened archetype. ; uses path map so as to pick up paths generated by internal references
		do
			Result := definition.has_attribute_path (a_path)
		end

	is_template: BOOLEAN
			-- True if `artefact_type' is a template
		do
			Result := artefact_type.is_template
		end

feature -- Status Setting

	set_is_valid (a_validity: BOOLEAN)
			-- set is_valid flag
		require
			Is_differential: is_differential
		do
			is_valid := a_validity
			is_dirty := False
		end

	set_differential
			-- set is_diffrential flag
		do
			is_differential := True
		end

	set_is_generated
			-- set is_generated flag
		do
			is_generated := True
		end

	clear_is_generated
			-- unset is_generated flag
		do
			is_generated := False
		end

	set_is_dirty
			-- set is_dirty flag
		do
			is_dirty := True
		end

	clear_is_dirty
			-- unset is_dirty flag
		do
			is_dirty := False
		end

feature -- Validation

	id_codes_index: HASH_TABLE [ARRAYED_LIST [ARCHETYPE_CONSTRAINT], STRING]
			-- table of {list<node>, code} for at-codes that identify nodes in archetype
			-- for later checking in ontology. Doesn't include id-codes.
			-- (note that there are other uses of term codes from the ontology, which is
			-- why this attribute is not just called 'term_codes_xref_table')
		local
			def_it: C_ITERATOR
		do
			create Result.make (0)
			create def_it.make (definition)
			def_it.do_all_on_entry (
				agent (a_c_node: ARCHETYPE_CONSTRAINT; depth: INTEGER; idx: HASH_TABLE [ARRAYED_LIST [ARCHETYPE_CONSTRAINT], STRING])
					local
						og_path: OG_PATH
					do
						-- if it's a differential path, get the id-codes from the path
						if attached {C_ATTRIBUTE} a_c_node as ca and then attached ca.differential_path as diff_path then
							create og_path.make_from_string (diff_path)
							across og_path as path_csr loop
								if path_csr.item.is_addressable and is_id_code (path_csr.item.object_id) then
									if not idx.has (path_csr.item.object_id) then
										idx.put (create {ARRAYED_LIST [ARCHETYPE_CONSTRAINT]}.make(0), path_csr.item.object_id)
									end
									idx.item (path_csr.item.object_id).extend (ca)
								end
							end
						elseif attached {C_OBJECT} a_c_node as co then
							if is_id_code (co.node_id) then
								if not idx.has (co.node_id) then
									idx.put (create {ARRAYED_LIST [ARCHETYPE_CONSTRAINT]}.make(0), co.node_id)
								end
								idx.item (co.node_id).extend (co)
							end
						end
					end (?, ?, Result))
		end

	value_codes_index: HASH_TABLE [ARRAYED_LIST [C_TERMINOLOGY_CODE], STRING]
			-- table of {list<node>, code} for term codes which appear in archetype nodes as data,
			-- in C_TERMINOLOGY_CODE types
			-- keys are either local codes, e.g. "at44" or fully qualified non-local code strings
			-- e.g. "openehr::233", "snomedct_20100601::20000349" etc
		local
			def_it: C_ITERATOR
		do
			create Result.make (0)
			create def_it.make (definition)
			def_it.do_all_on_entry (
				agent (a_c_node: ARCHETYPE_CONSTRAINT; depth: INTEGER; idx: HASH_TABLE [ARRAYED_LIST [C_OBJECT], STRING])
					do
						if attached {C_TERMINOLOGY_CODE} a_c_node as ctc then
							if is_valid_value_code (ctc.constraint) then
								if not idx.has (ctc.constraint) then
									idx.put (create {ARRAYED_LIST [C_TERMINOLOGY_CODE]}.make(0), ctc.constraint)
								end
								if attached idx.item (ctc.constraint) as att_list and then not att_list.has (ctc) then
									att_list.extend (ctc)
								end
							end

							-- check assumed value code - which is an at-code that can occur with an ac-code
							if attached ctc.assumed_value as att_av then
								if not idx.has (att_av) then
									idx.put (create {ARRAYED_LIST [C_TERMINOLOGY_CODE]}.make(0), att_av)
								end
								if attached idx.item (att_av) as att_list and then not att_list.has (ctc) then
									att_list.extend (ctc)
								end
							end
						end
					end (?, ?, Result))
		end

	term_constraints_index: HASH_TABLE [C_TERMINOLOGY_CODE, STRING]
			-- table of {C_TERMINOLOGY_CODE, code} keyed by ac-codes
			-- (doesn't include C_TERMINOLOGY_CODEs containg only an at-code; use `value_codes_index' for that)
		local
			def_it: C_ITERATOR
		do
			create Result.make (0)
			create def_it.make (definition)
			def_it.do_all_on_entry (
				agent (a_c_node: ARCHETYPE_CONSTRAINT; depth: INTEGER; idx: HASH_TABLE [C_TERMINOLOGY_CODE, STRING])
					do
						if attached {C_TERMINOLOGY_CODE} a_c_node as ctc then
							if is_valid_value_set_code (ctc.constraint) then
								idx.put (ctc, ctc.constraint)
							end
						end
					end (?, ?, Result))
		end

	use_node_index: HASH_TABLE [ARRAYED_LIST [C_COMPLEX_OBJECT_PROXY], STRING]
			-- table of {list<C_COMPLEX_OBJECT_PROXY>, target_path}
			-- i.e. <list of use_nodes> keyed by path they point to
		local
			def_it: C_ITERATOR
		do
			create Result.make (0)
			create def_it.make (definition)
			def_it.do_all_on_entry (
				agent (a_c_node: ARCHETYPE_CONSTRAINT; depth: INTEGER; idx: HASH_TABLE [ARRAYED_LIST [C_COMPLEX_OBJECT_PROXY], STRING])
					do
						if attached {C_COMPLEX_OBJECT_PROXY} a_c_node as air then
							if not idx.has (air.target_path) then
								idx.put (create {ARRAYED_LIST[C_COMPLEX_OBJECT_PROXY]}.make(0), air.target_path)
							end
							idx.item (air.target_path).extend (air)
						end
					end (?, ?, Result))
		end

	suppliers_index: HASH_TABLE [ARRAYED_LIST [C_ARCHETYPE_ROOT], STRING]
			-- table of {list<C_ARCHETYPE_ROOT>, archetype_ref}
			-- i.e. table of <list of use_archetype nodes>, each keyed by archetype ref
		local
			def_it: C_ITERATOR
		do
			create Result.make (0)
			create def_it.make (definition)
			def_it.do_all_on_entry (
				agent (a_c_node: ARCHETYPE_CONSTRAINT; depth: INTEGER; idx: HASH_TABLE [ARRAYED_LIST [C_ARCHETYPE_ROOT], STRING])
					do
						if attached {C_ARCHETYPE_ROOT} a_c_node as car then
							if not idx.has (car.archetype_ref) then
								idx.put (create {ARRAYED_LIST [C_ARCHETYPE_ROOT]}.make(0), car.archetype_ref)
							end
							idx.item (car.archetype_ref).extend (car)
						end
					end (?, ?, Result))
		end

	rules_index: HASH_TABLE [ARRAYED_LIST [EXPR_LEAF], STRING]
			-- table of {list<EXPR_LEAF>, target_path}
			-- i.e. <list of invariant leaf nodes> keyed by path they point to
		local
			def_it: EXPR_ITERATOR
		do
			create Result.make (0)
			if has_rules then
				across rules as inv_csr loop
					create def_it.make (inv_csr.item)
					def_it.do_all (
						agent (a_node: EXPR_ITEM; depth: INTEGER; idx: HASH_TABLE [ARRAYED_LIST [EXPR_LEAF], STRING])
							do
								if attached {EXPR_LEAF} a_node as el then
									if el.is_archetype_definition_ref and attached {STRING} el.item as tgt_path then
										if not idx.has (tgt_path) then
											idx.put (create {ARRAYED_LIST[EXPR_LEAF]}.make(0), tgt_path)
										end
										idx.item (tgt_path).extend (el)
									end
								end
							end (?, ?, Result),
						Void)
				end
			end
		end

	slot_index: ARRAYED_LIST [ARCHETYPE_SLOT]
			-- list of archetype slots in this archetype
		local
			def_it: C_ITERATOR
		do
			create Result.make (0)
			create def_it.make (definition)
			def_it.do_all_on_entry (
				agent (a_c_node: ARCHETYPE_CONSTRAINT; depth: INTEGER; idx: ARRAYED_LIST [ARCHETYPE_SLOT])
					do
						if attached {ARCHETYPE_SLOT} a_c_node as a_slot then idx.extend (a_slot) end
					end (?, ?, Result))
		end

	tuple_parent_index: ARRAYED_LIST [C_COMPLEX_OBJECT]
			-- list of C_COMPLEX_OBJECT that have C_ATTRIBUTE_TUPLEs in this archetype
		local
			def_it: C_ITERATOR
		do
			create Result.make (0)
			create def_it.make (definition)
			def_it.do_all_on_entry (
				agent (a_c_node: ARCHETYPE_CONSTRAINT; depth: INTEGER; idx: ARRAYED_LIST [C_COMPLEX_OBJECT])
					do
						if attached {C_COMPLEX_OBJECT} a_c_node as cco and then cco.has_attribute_tuples then
							idx.extend (cco)
						end
					end (?, ?, Result))
		end

	terminology_unused_term_codes: ARRAYED_LIST [STRING]
			-- list of at codes found in terminology that are not referenced anywhere in the archetype definition
		local
			id_codes: like id_codes_index
			constraint_codes: like term_constraints_index
			value_codes: ARRAYED_SET[STRING]
		do
			create Result.make (0)

			id_codes := id_codes_index
			across terminology.id_codes as term_codes_csr loop
				if not id_codes.has (term_codes_csr.item) then
					Result.extend (term_codes_csr.item)
				end
			end

			create value_codes.make (0)
			value_codes.compare_objects
			across terminology.value_sets as vs_csr loop
				value_codes.merge (vs_csr.item.members)
			end
			across value_codes_index.current_keys as keys_csr loop
				value_codes.extend (keys_csr.item)
			end
			across terminology.value_codes as term_codes_csr loop
				if not value_codes.has (term_codes_csr.item) then
					Result.extend (term_codes_csr.item)
				end
			end

			constraint_codes := term_constraints_index
			across terminology.value_set_codes as term_codes_csr loop
				if not constraint_codes.has (term_codes_csr.item) then
					Result.extend (term_codes_csr.item)
				end
			end

			Result.prune (concept_id)
		end

feature -- Modification

	set_adl_version (a_ver: STRING)
			-- set `adl_version' with a string containing only '.' and numbers,
			-- not commencing or finishing in '.'
		require
			Valid_version: valid_standard_version(a_ver)
		do
			adl_version := a_ver
		end

	set_rm_release (a_ver: STRING)
			-- set `rm_release' with a string containing only '.' and numbers,
			-- not commencing or finishing in '.'
		require
			Valid_version: valid_standard_version (a_ver)
		do
			rm_release := a_ver
		end

	set_archetype_id (an_id: like archetype_id)
		do
			archetype_id := an_id
		end

	set_uid (a_uid: STRING)
		do
			create uid.make_from_string (a_uid)
		end

	set_artefact_type_from_string (s: STRING)
		require
			(create {ARTEFACT_TYPE}).valid_type_name(s)
		do
			create artefact_type.make_from_type_name(s)
		end

	set_other_metadata (a_metadata: like other_metadata)
		do
			other_metadata := a_metadata
		end

	add_other_metadata_value (a_key, a_value: STRING)
			-- add the pair `a_key' / `a_value' to `other_metadata', overwriting any value
			-- with the same key if necessary.
		local
			o_metadata: HASH_TABLE [STRING, STRING]
		do
			if attached other_metadata as omd then
				o_metadata := omd
			else
				create o_metadata.make (0)
			end
			o_metadata.force (a_value, a_key)
			other_metadata := o_metadata
		ensure
			other_metadata.item (a_key) = a_value
		end

	add_other_metadata_flag (a_key: STRING)
			-- add a meta-data item of the form of a flag, whose value is implied to be 'true',
			-- overwriting any value with the same key if necessary.
		local
			o_metadata: HASH_TABLE [STRING, STRING]
			any_flag: BOOLEAN
		do
			if attached other_metadata as omd then
				o_metadata := omd
			else
				create o_metadata.make (0)
			end
			any_flag := True
			o_metadata.force (any_flag.out, a_key)
			other_metadata := o_metadata
		ensure
			other_metadata.item (a_key).is_equal ((True).out)
		end

	set_parent_archetype_id (an_id: like parent_archetype_id)
		do
			parent_archetype_id := an_id
		end

	set_definition (a_node: like definition)
		do
			definition := a_node
		end

	set_rules (an_assertion_list: ARRAYED_LIST[ASSERTION])
			-- set invariants
		do
			rules := an_assertion_list
		end

	set_terminology (an_ont: attached like terminology)
		do
			terminology := an_ont
		end

	add_rule (an_inv: ASSERTION)
			-- add a new invariant
		do
			if rules = Void then
				create rules.make(0)
			end
			rules.extend(an_inv)
		end

	rebuild
			-- rebuild any cached state after changes to definition or invariant structure
		do
			if is_specialised then
				roll_up_inheritance_status
			end
			is_dirty := False

			-- update highest id code in terminology
			extract_highest_added_id_codes
		end

	create_new_id_code: STRING
			-- create a new id-code at the specialisation depth of this archetype
		do
			Result := new_added_id_code_at_level (specialisation_depth, highest_added_id_code)
			highest_added_id_code := highest_added_id_code + 1
		end

	create_refined_id_code (a_parent_id: STRING): STRING
			-- create a id-code at the specialisation depth of this archetype as a child
			-- id of `a_parent_id'
		require
			specialisation_depth_from_code (a_parent_id) + 1 = specialisation_depth
		do
			Result := new_refined_code_at_level (a_parent_id, specialisation_depth, highest_redefined_id_codes.item (a_parent_id))
			highest_redefined_id_codes.replace (highest_redefined_id_codes.item (a_parent_id) + 1, a_parent_id)
		end

	add_language_tag (a_lang_tag: STRING)
			-- add a new language to the archetype - creates new language section in
			-- terminology, translations and resource description
		do
			precursor (a_lang_tag)
			terminology.add_language (a_lang_tag)
		end

	remove_terminology_unused_codes
			-- remove all term and constraint codes from terminology
		require
			is_differential
		do
			across terminology_unused_term_codes as codes_csr loop
				terminology.remove_definition (codes_csr.item)
			end
		end

feature {ARCH_LIB_ARCHETYPE_ITEM, ARCHETYPE_COMPARATOR} -- Structure

	convert_to_differential_paths
			-- FIXME: only needed while differential archetype source is being created in uncompressed form
			-- compress paths of congruent nodes in specialised archetype so that equivalent paths
			-- are recorded in the `differential_path' attribute of terminal C_ATTRIBUTE nodes of congruent sections
			-- This routine only works if validation has successfully completed because the latter process sets
			-- is_mergeable markers in the structure.
		require
			Is_differential: is_differential
			Is_specialised: is_specialised
			Is_generated: is_generated
		local
			def_it: C_ITERATOR
			converted_def: C_COMPLEX_OBJECT
		do
			converted_def := definition.deep_twin
			create def_it.make (definition)
			def_it.do_at_surface (agent node_set_differential_path (converted_def, ?, ?),
				agent (a_c_node: ARCHETYPE_CONSTRAINT): BOOLEAN
					do
						Result := not a_c_node.is_path_compressible
					end
			)
			definition := converted_def
			rebuild
		end

	node_set_differential_path (root_cco: C_COMPLEX_OBJECT; a_c_node: ARCHETYPE_CONSTRAINT; depth: INTEGER)
			-- FIXME: only needed while differential archetype source is being created in uncompressed form
			-- perform validation of node against reference model
			-- This function gets executed on nodes 1 level BELOW where the is_congruent marker is True
		local
			ca2: C_ATTRIBUTE
			co2: C_OBJECT
		do
			if attached {C_ATTRIBUTE} a_c_node as ca then
				-- these are attributes that are not congruent to any node in the parent archetype,
				-- i.e. they don't exist in the parent.
				if root_cco.has_attribute_path (ca.path) then
					ca2 := root_cco.attribute_at_path (ca.path)
					if not ca2.has_differential_path then
						debug("compress")
							io.put_string ("Compressing path at ATTR " + ca.path + "%N")
						end
						if not ca2.parent.is_root then
							ca2.set_differential_path_to_here
						end
					else
						debug("compress")
							io.put_string ("Path " + ca.path + " no longer available - attribute moved (already compressed?)%N")
						end
					end
				end
			elseif attached {C_OBJECT} a_c_node as co then
				if not co.is_root then
					if root_cco.has_object_path (co.path) then
						co2 := root_cco.object_at_path (co.path)
						if not co2.parent.has_differential_path then
debug("compress")
	io.put_string ("Compressing path of ATTR above OBJ with path " + co.path + "%N")
end
							co2.parent.set_differential_path_to_here
						end
					else
		debug("compress")
			io.put_string ("Path " + co.path + " no longer available - parent moved (already compressed?)%N")
		end
					end
				end
			end
		end

feature {NONE} -- Implementation

	extract_highest_added_id_codes
			-- set `highest_added_id_code' and populate `highest_redefined_id_codes'
		local
			def_it: C_ITERATOR
		do
			highest_added_id_code := 0
			create def_it.make (definition)
			def_it.do_all_on_entry (
				agent (a_c_node: ARCHETYPE_CONSTRAINT; depth: INTEGER)
					local
						parent_node_id: STRING
						code_idx: INTEGER
					do
						if attached {C_OBJECT} a_c_node as co and then not attached {C_PRIMITIVE_OBJECT} co then
							-- need to avoid at-codes in archetypes not yet converted or fully converted
							if is_id_code (co.node_id) and not co.node_id.starts_with (Fake_adl_14_node_id_base) and then specialisation_depth_from_code (co.node_id) = specialisation_depth then
								code_idx := code_index_at_level (co.node_id, specialisation_depth)
								if is_refined_code (co.node_id) then
									parent_node_id := specialised_code_base (co.node_id)
									if not highest_redefined_id_codes.has (parent_node_id) then
										highest_redefined_id_codes.put (code_idx, parent_node_id)
									elseif highest_redefined_id_codes.item (parent_node_id) < code_idx then
										highest_redefined_id_codes.replace (code_idx, parent_node_id)
									end
								else
									highest_added_id_code := highest_added_id_code.max (code_idx)
								end
							end
						end
					end)
		end

	highest_added_id_code: INTEGER
			-- integer code value of the highest id_code added at this specialisation level

	highest_redefined_id_codes: HASH_TABLE [INTEGER, STRING]
			-- table of highest code indexes of child codes used in this archetype keyed by parent node id
		attribute
			create Result.make (0)
		end

	roll_up_inheritance_status
			-- set rolled_up_specialisation statuses in nodes of definition
			-- only useful to call for specialised archetypes
		require
			is_specialised
		local
			a_c_iterator: OG_CONTENT_ITERATOR
			rollup_builder: C_ROLLUP_BUILDER
		do
			create rollup_builder.make (Current)
			create a_c_iterator.make (definition.representation, rollup_builder)
			a_c_iterator.do_all
		end

	path_map_cache: detachable HASH_TABLE [ARCHETYPE_CONSTRAINT, STRING]
			-- complete map of paths available in this archetype, including paths implied by
			-- use_nodes in definition structure; paths to C_OBJECTs have the C_OBJECT reference

	set_terminology_agents
		do
			-- set agent to create new id-codes into terminology
			terminology.set_new_id_code_agt (agent create_new_id_code)

			set_c_terminology_code_agents
		end

	set_c_terminology_code_agents
			-- set a terminology extractor agent into every C_TERMINOLOGY_CODE object so
			-- it can evaluate value sets
		local
			def_it: C_ITERATOR
		do
			create def_it.make (definition)
			def_it.do_all_on_entry (
				agent (a_c_node: ARCHETYPE_CONSTRAINT; depth: INTEGER)
					do
						if attached {C_TERMINOLOGY_CODE} a_c_node as ctc then
							ctc.set_value_set_extractor (agent get_value_set)
						end
					end)
		end

	get_value_set (ac_code: STRING): ARRAYED_LIST [STRING]
		do
			if terminology.value_sets.has (ac_code) then
				Result := terminology.value_sets.item (ac_code).members
			else
				create Result.make (0)
				Result.compare_objects
			end
		end

invariant
	Description_valid: not artefact_type.is_overlay implies attached description
	Translations_valid: artefact_type.is_overlay implies not attached description
	Concept_valid: concept_id.is_equal (terminology.concept_code)
	Invariants_valid: attached rules implies not rules.is_empty
	RM_type_validity: definition.rm_type_name.as_lower.is_equal (archetype_id.rm_class.as_lower)
	Specialisation_validity: is_specialised implies (specialisation_depth > 0 and attached parent_archetype_id)

end


