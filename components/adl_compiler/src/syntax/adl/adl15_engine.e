note
	component:   "openEHR Archetype Project"
	description: "[
				 This class knows how to parse an ADL text, and serialise an ARCHETYPE object in ADL 1.4 and 1.5.
				 Both parsing and serialisation are multi-part, i.e. treat an archetype as a series of sections
				 each headed by keywords (apart from the items in the header section.
				 ]"
	keywords:    "ADL, parse, serialise"
	author:      "Thomas Beale <thomas.beale@oceaninformatics.com>"
	support:     "http://www.openehr.org/issues/browse/AWB"
	copyright:   "Copyright (c) 2003- Ocean Informatics Pty Ltd <http://www.oceaninfomatics.com>"
	license:     "See notice at bottom of class"

class ADL15_ENGINE

inherit
	SHARED_ARCHETYPE_SERIALISERS
		export
			{NONE} all;
			{ANY} archetype_native_serialiser_formats, has_archetype_native_serialiser_format
		end

	ADL_SYNTAX_CONVERTER
		export
			{NONE} all
		end

	SHARED_DT_OBJECT_CONVERTER
		export
			{NONE} all;
			{ANY} deep_copy, deep_twin, is_deep_equal, standard_is_equal
		end

create
	make

feature {NONE} -- Initialisation

	make
		do
			create language_context.make
			create description_context.make
			create definition_context.make
			create invariant_context.make
			create ontology_context.make
			create annotations_context.make
		end

feature -- Access

	errors: ERROR_ACCUMULATOR
			-- errors of last parse
		attribute
			create Result.make
		end

feature -- Parsing

	parse_differential (a_text: STRING; an_rm_schema: BMM_SCHEMA): detachable DIFFERENTIAL_ARCHETYPE
			-- parse text as differential archetype. If successful, `archetype' contains the parse structure.
		do
			rm_schema := an_rm_schema
			if attached {DIFFERENTIAL_ARCHETYPE} parse (a_text, False) as da then
				Result := da
			end
		end

	parse_legacy_flat (a_text: STRING; an_rm_schema: BMM_SCHEMA): detachable FLAT_ARCHETYPE
			-- parse text as flat archetype. If successful, `archetype' contains the parse structure.
		do
			rm_schema := an_rm_schema
			if attached {FLAT_ARCHETYPE} parse (a_text, True) as fa then
				Result := fa
			end
		end

feature -- Validation

	post_parse_process (aca: ARCH_CAT_ARCHETYPE; an_rm_schema: BMM_SCHEMA)
		local
			proc: AOM_POST_PARSE_PROCESSOR
		do
			if attached post_parse_processor as pcp then
				proc := pcp
				proc.initialise (aca, an_rm_schema)
			else
				create proc.make (aca, an_rm_schema)
				post_parse_processor := proc
			end
			proc.execute
		end

	phase_1_validate (aca: ARCH_CAT_ARCHETYPE; an_rm_schema: BMM_SCHEMA)
		local
			proc: ARCHETYPE_PHASE_1_VALIDATOR
		do
			validation_passed := False
			if attached phase_1_validator as pv then
				proc := pv
				proc.initialise (aca, an_rm_schema)
			else
				create proc.initialise (aca, an_rm_schema)
				phase_1_validator := proc
			end
			proc.validate
			validation_passed := proc.passed
			errors := proc.errors
		end

	phase_2_validate (aca: ARCH_CAT_ARCHETYPE; an_rm_schema: BMM_SCHEMA)
		local
			proc: ARCHETYPE_PHASE_2_VALIDATOR
		do
			validation_passed := False
			if attached phase_2_validator as pv then
				proc := pv
				proc.initialise (aca, an_rm_schema)
			else
				create proc.initialise (aca, an_rm_schema)
				phase_2_validator := proc
			end
			proc.validate
			validation_passed := proc.passed
			errors := proc.errors
		end

	phase_3_validate (aca: ARCH_CAT_ARCHETYPE; an_rm_schema: BMM_SCHEMA)
		local
			proc: ARCHETYPE_PHASE_3_VALIDATOR
		do
			validation_passed := False
			if attached phase_3_validator as pv then
				proc := pv
				proc.initialise (aca, an_rm_schema)
			else
				create proc.initialise (aca, an_rm_schema)
				phase_3_validator := proc
			end
			proc.validate
			validation_passed := proc.passed
			errors := proc.errors
		end

	post_compile_process (aca: ARCH_CAT_ARCHETYPE; an_rm_schema: BMM_SCHEMA)
		local
			proc: AOM_POST_COMPILE_PROCESSOR
		do
			if attached post_compile_processor as pcp then
				proc := pcp
				proc.initialise (aca, an_rm_schema)
			else
				create proc.initialise (aca, an_rm_schema)
				post_compile_processor := proc
			end
			proc.execute
		end

	validation_passed: BOOLEAN
			-- result of last validation

feature -- Serialisation

	serialise (an_archetype: ARCHETYPE; a_format, a_lang: STRING): STRING
			-- serialise current archetype into any semantic multi-part format.
		require
			Language_valid: an_archetype.has_language (a_lang)
			format_valid: has_archetype_native_serialiser_format (a_format)
		local
			comp_onts_serialised: STRING
			comp_onts_helper: COMPONENT_ONTOLOGIES_HELPER
			generate_adl14_ontology: BOOLEAN
			serialiser: ARCHETYPE_MULTIPART_SERIALISER
		do
			-- set a flag for use below, to generate old-style flat archetypes for old tools
			generate_adl14_ontology := attached {FLAT_ARCHETYPE} an_archetype and adl_version_for_flat_output_numeric = 140

			an_archetype.synchronise_adl15

			-- language section
			language_context.set_tree (an_archetype.orig_lang_translations.dt_representation)
			language_context.serialise (a_format, False, False)

			-- description section
			description_context.set_tree (an_archetype.description.dt_representation)
			description_context.serialise (a_format, False, False)

			-- definition section
			definition_context.set_tree (an_archetype.definition)
			definition_context.serialise (an_archetype, a_format, a_lang)

			-- rules section
			if an_archetype.has_invariants then
				invariant_context.set_tree (an_archetype.invariants)
				invariant_context.serialise (a_format)
			end

			-- ontology section
			check attached an_archetype.ontology.dt_representation as dt_ont then

	-- this is a hack which causes ontology section to be output as dADL with the 'items' attributes
	-- rather than the native nested structure
	if generate_adl14_ontology then
		convert_ontology_to_unnested (dt_ont)
	end

				ontology_context.set_tree (dt_ont)
				ontology_context.serialise (a_format, False, False)

	-- and this puts the in-memory structure back to native form so things work correctly from here
	if generate_adl14_ontology then
		convert_ontology_to_nested (dt_ont)
	end
			end

			-- OPT only: component_ontologies section
			if attached {OPERATIONAL_TEMPLATE} an_archetype as opt then
				create comp_onts_helper.make
				comp_onts_helper.set_component_ontologies (opt.component_ontologies)
				ontology_context.set_tree (dt_object_converter.object_to_dt (comp_onts_helper))
				ontology_context.serialise (a_format, False, False)
				comp_onts_serialised := ontology_context.serialised
			else
				create comp_onts_serialised.make_empty
			end

			-- annotations section
			if an_archetype.has_annotations then
				annotations_context.set_tree (an_archetype.annotations.dt_representation)
				annotations_context.serialise (a_format, False, False)
			end

			-- perform the pasting together of pieces to make ADL archetype
			check attached archetype_native_serialiser_for_format (a_format) as ser then
				serialiser := ser
			end
			serialiser.reset
			serialiser.serialise_from_parts (an_archetype, language_context.serialised, description_context.serialised, definition_context.serialised,
				invariant_context.serialised, ontology_context.serialised, annotations_context.serialised, comp_onts_serialised)

			Result := serialiser.last_result
		end

feature {NONE} -- Implementation

	parse (a_text: STRING; is_legacy_flat: BOOLEAN): detachable ARCHETYPE
			-- parse text as either a differential source archetype or template, or else a legacy flat. If successful, `archetype' contains the parse
			-- structure.
		local
			res_desc: detachable RESOURCE_DESCRIPTION
			annots: detachable RESOURCE_ANNOTATIONS
			orig_lang_trans: detachable LANGUAGE_TRANSLATIONS
		do
			create adl_parser.make
			adl_parser.execute (a_text)

			create errors.make

			if adl_parser.syntax_error then
				errors.append (adl_parser.errors)
			else
				------------------- ADL 'language' section (mandatory) ---------------
				-- parse AUTHORED_RESOURCE.original_language & translations
				-- using helper type LANGUAGE_TRANSLATIONS
				check attached adl_parser.language_text as lt then
					language_context.set_source (lt, adl_parser.language_text_start_line)
				end
				language_context.parse
				if not language_context.parse_succeeded then
					errors.append (language_context.errors)
				elseif not dt_object_converter.errors.has_errors and
					attached {LANGUAGE_TRANSLATIONS} language_context.tree.as_object (({LANGUAGE_TRANSLATIONS}).type_id, Void) as lt
				then
					orig_lang_trans := lt
				else
					errors.add_error (ec_deserialise_e1, <<({LANGUAGE_TRANSLATIONS}).name>>, generator + ".parse")
					errors.append (dt_object_converter.errors)
				end

				------------------- description section (optional) ---------------
				-- parse AUTHORED_RESOURCE.description
				if not errors.has_errors then
					if attached adl_parser.description_text as dt and then not dt.is_empty then
						description_context.set_source (dt, adl_parser.description_text_start_line)
						description_context.parse
						if not description_context.parse_succeeded then
							errors.append (description_context.errors)
						elseif not dt_object_converter.errors.has_errors and
							attached {RESOURCE_DESCRIPTION} description_context.tree.as_object (({RESOURCE_DESCRIPTION}).type_id, Void) as rd
						then
							res_desc := rd
						else
							errors.add_error (ec_deserialise_e1, <<({RESOURCE_DESCRIPTION}).name>>, generator + ".parse")
							errors.append (dt_object_converter.errors)
						end
					else
						description_context.reset
					end
				end

				------------------- definition section (mandatory) ---------------
				-- parse ARCHETYPE.definition
				if not errors.has_errors then
					check attached adl_parser.definition_text as def_text then
						definition_context.set_source (def_text, adl_parser.definition_text_start_line, not is_legacy_flat, rm_schema)
					end
					definition_context.parse
					if not definition_context.parse_succeeded then
						errors.append (definition_context.errors)
					end
				end

				------------------- invariant section (optional) ---------------
				-- parse ARCHETYPE.invariants
				if not errors.has_errors then
					if attached adl_parser.invariant_text as inv_text and then not inv_text.is_empty then
						invariant_context.set_source (inv_text, adl_parser.invariant_text_start_line, not is_legacy_flat, rm_schema)
						invariant_context.parse
						if not invariant_context.parse_succeeded then
							errors.append (invariant_context.errors)
						end
					else
						invariant_context.reset
					end
				end

				------------------- ontology section (mandatory) ---------------
				-- parse ARCHETYPE.ontology
				if not errors.has_errors then
					check attached adl_parser.ontology_text as ont_text then
						ontology_context.set_source (ont_text, adl_parser.ontology_text_start_line)
					end
					ontology_context.parse
					if not ontology_context.parse_succeeded then
						errors.append (ontology_context.errors)
					end
				end

				------------------- annotations section (optional) ---------------
				-- parse AUTHORED_RESOURCE.annotations
				if not errors.has_errors then
					if attached adl_parser.annotations_text as annot_text and then not annot_text.is_empty then
						annotations_context.set_source (annot_text, adl_parser.annotations_text_start_line)
						annotations_context.parse
						if not annotations_context.parse_succeeded then
							errors.append (annotations_context.errors)
						elseif not dt_object_converter.errors.has_errors and
							attached {RESOURCE_ANNOTATIONS} annotations_context.tree.as_object (({RESOURCE_ANNOTATIONS}).type_id, Void) as res_ann
						then
							annots := res_ann
						else
							errors.add_error (ec_deserialise_e1, <<({RESOURCE_ANNOTATIONS}).name>>, generator + ".parse")
							errors.append (dt_object_converter.errors)
						end
					else
						annotations_context.reset
					end
				end

				------------------- build the archetype --------------					
				if not errors.has_errors then
					if attached definition_context.tree as definition and
						attached adl_parser.archetype_id as id and
						attached adl_parser.artefact_type as art_type and
						attached ontology_context.tree as ont_tree
					then
						-- FIXME: needed on ADL 1.4 style archetypes that have 'items' in the ontology
						convert_ontology_to_nested (ont_tree)  -- perform any version upgrade conversions

						if is_legacy_flat then
							if attached orig_lang_trans as olt and then attached {FLAT_ARCHETYPE_ONTOLOGY}
								ont_tree.as_object (({FLAT_ARCHETYPE_ONTOLOGY}).type_id, <<olt.original_language.code_string, definition.node_id>>) as flat_ont
								and not dt_object_converter.errors.has_errors
							then
								create {FLAT_ARCHETYPE} Result.make (
									art_type,
									id,
									olt.original_language,
									adl_parser.uid,
									res_desc,	-- may be Void
									definition,
									flat_ont
								)
							else
								errors.add_error (ec_SAON, Void, generator + ".parse")
								errors.append (dt_object_converter.errors)
							end
						else
							if attached orig_lang_trans as olt and then attached {DIFFERENTIAL_ARCHETYPE_ONTOLOGY}
								ont_tree.as_object (({DIFFERENTIAL_ARCHETYPE_ONTOLOGY}).type_id, <<olt.original_language.code_string, definition.node_id>>) as diff_ont
								and not dt_object_converter.errors.has_errors
							then
								create {DIFFERENTIAL_ARCHETYPE} Result.make (
									art_type,
									id,
									olt.original_language,
									adl_parser.uid,
									res_desc,	-- may be Void
									definition,
									diff_ont
								)
							else
								errors.add_error (ec_SAON, Void, generator + ".parse")
								errors.append (dt_object_converter.errors)
							end
						end

						if attached Result as new_arch then
							-- add optional parts
							if attached {ARCHETYPE_ID} adl_parser.parent_archetype_id as parent_id then
								new_arch.set_parent_archetype_id (parent_id)
							end

							if attached adl_parser.adl_version as adl_av then
								new_arch.set_adl_version (adl_av)
							else
								new_arch.set_adl_version (latest_adl_version)
							end

							if adl_parser.is_controlled then
								new_arch.set_is_controlled
							end

							if adl_parser.is_generated then
								new_arch.set_is_generated
							end

							-- other meta-data
							if attached adl_parser.other_metadata as omd and then not omd.is_empty then
								across omd as omd_csr loop
									if attached omd_csr.key as a_key and attached omd_csr.item as an_item then
										new_arch.add_other_metadata_value (a_key, an_item)
									end
								end
							end

							if attached orig_lang_trans.translations as olt_trans then
								new_arch.set_translations (olt_trans)
							end

							if attached invariant_context.tree as inv_tree then
								new_arch.set_invariants (inv_tree)
							end

							if attached annots as a then
								new_arch.set_annotations (a)
							end
						end
					end
				end
			end
		end

	adl_parser: ADL_VALIDATOR
		attribute
			create Result.make
		end

	language_context: ODIN_ENGINE

	description_context: ODIN_ENGINE

	definition_context: CADL_ENGINE

	invariant_context: ASSERTION_ENGINE

	ontology_context: ODIN_ENGINE

	annotations_context: ODIN_ENGINE

	post_parse_processor: detachable AOM_POST_PARSE_PROCESSOR
		note
			option: stable
		attribute
		end

	phase_1_validator: detachable ARCHETYPE_PHASE_1_VALIDATOR
		note
			option: stable
		attribute
		end

	phase_2_validator: detachable ARCHETYPE_PHASE_2_VALIDATOR
		note
			option: stable
		attribute
		end

	phase_3_validator: detachable ARCHETYPE_PHASE_3_VALIDATOR
		note
			option: stable
		attribute
		end

	post_compile_processor: detachable AOM_POST_COMPILE_PROCESSOR
		note
			option: stable
		attribute
		end

	rm_schema: BMM_SCHEMA
		attribute
			create Result.make (unknown_value, unknown_value, unknown_value)
		end

	original_language_and_translations_from_ontology (ontology: ARCHETYPE_ONTOLOGY): LANGUAGE_TRANSLATIONS
			-- The original language and translations, mined from `ontology'.
		do
			create Result.make
			Result.set_original_language_from_string (ontology.original_language)
			across ontology.languages_available as langs_csr loop
				if not langs_csr.item.is_equal (ontology.original_language) then
					Result.add_new_translation (langs_csr.item)
				end
			end
		end

end


--|
--| ***** BEGIN LICENSE BLOCK *****
--| Version: MPL 1.1/GPL 2.0/LGPL 2.1
--|
--| The contents of this file are subject to the Mozilla Public License Version
--| 1.1 (the 'License'); you may not use this file except in compliance with
--| the License. You may obtain a copy of the License at
--| http://www.mozilla.org/MPL/
--|
--| Software distributed under the License is distributed on an 'AS IS' basis,
--| WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
--| for the specific language governing rights and limitations under the
--| License.
--|
--| The Original Code is adl_engine.e.
--|
--| The Initial Developer of the Original Code is Thomas Beale.
--| Portions created by the Initial Developer are Copyright (C) 2003-2004
--| the Initial Developer. All Rights Reserved.
--|
--| Contributor(s):
--|
--| Alternatively, the contents of this file may be used under the terms of
--| either the GNU General Public License Version 2 or later (the 'GPL'), or
--| the GNU Lesser General Public License Version 2.1 or later (the 'LGPL'),
--| in which case the provisions of the GPL or the LGPL are applicable instead
--| of those above. If you wish to allow use of your version of this file only
--| under the terms of either the GPL or the LGPL, and not to allow others to
--| use your version of this file under the terms of the MPL, indicate your
--| decision by deleting the provisions above and replace them with the notice
--| and other provisions required by the GPL or the LGPL. If you do not delete
--| the provisions above, a recipient may use your version of this file under
--| the terms of any one of the MPL, the GPL or the LGPL.
--|
--| ***** END LICENSE BLOCK *****
--|
