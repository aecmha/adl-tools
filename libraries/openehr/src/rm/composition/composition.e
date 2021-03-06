note
	component:   "openEHR ADL Tools"
	description: "[
	             A particular version of content extracted from a  VERSIONED_COMPOSITION. 
	             Corresponds to the event of a HCP committing new information to the health 
	             record. A new COMPOSITION is created by a VERSIONED_COMPOSITION for 
	             creation or modification. 
	             
	             COMPOSITION objects are simple items combining an audit and a content object.
			 ]"
	keywords:    "composition, versioning"

	requirements:"ISO 18308 TS V1.0 ???"
	design:      "openEHR EHR Reference Model 5.0"

	author:      "Thomas Beale"
	support:     "Ocean Informatics <support@OceanInformatics.biz>"
	copyright:   "Copyright (c) 2000-2005 The openEHR Foundation <http://www.openEHR.org>"
	license:     "Apache 2.0 License <http://www.apache.org/licenses/LICENSE-2.0.html>"


class COMPOSITION

inherit
	LOCATABLE

	EXTERNAL_ENVIRONMENT_ACCESS
		export
			{NONE} all
		end

feature -- Definitions

	Id_delimiter: STRING = "!"
			-- delimiter for sections of id.

feature -- Access
	
	composer: PARTY_PROXY
			-- Person or agent primarily responsible for the content of the Composition

	content: LIST [CONTENT_ITEM]
			-- the clinical session content of this transaction

	context: EVENT_CONTEXT
			-- The clinical session context of this transaction, 
			-- i.e. the contextual attributes of the clinical session
			
	language: CODE_PHRASE	
			-- Mandatory indicator of the localised language in which this 
			-- Composition is written. Coded from openEHR Code Set �languages�.
			-- individual Entries may override this value
			
	territory: CODE_PHRASE	
			-- Name of territory in which this Composition was written. 
			-- Coded from openEHR �countries� code set, which is an expression of the ISO 3166 standard.

	category: DV_CODED_TEXT	
			-- Indicates what broad category this Composition is belogs to, 
			-- e.g. "persistent� - of longitudinal validity, �event�, �process� etc.

	path_of_item (a_loc: LOCATABLE): STRING
			-- The path to an item relative to the root of this archetyped structure.
		do
				-- TO_BE_IMPLEM
		end

	item_at_path (a_path: STRING): LOCATABLE
			-- The item at a path (relative to this item).
		do
				-- TO_BE_IMPLEM
		end

	parent: LOCATABLE
			-- parent node of this node in compositional structure
		once			
		end

feature -- Status Report

	is_persistent: BOOLEAN
			-- Indicates whether this transaction is considered persistent, i.e. of longitudinal validity or not.
		do
			
		end
		
	path_exists (a_path: STRING): BOOLEAN
			-- True if the path is valid with respect to the current item.
		do
				-- TO_BE_IMPLEM
		end
		
feature {NONE} -- Implementation

	term_set_descriptors: LIST [TERMINOLOGY_ID]
			-- terminology ids for all terms used in this transaction, keyed by 
			-- the idea recorded in the term

invariant
	Archetype_root_point: is_archetype_root
	Composer_exists: composer /= Void
	Content_valid: content /= Void implies not content.is_empty
	Category_validity: category /= Void and then 
		terminology(Terminology_id_openehr).has_code_for_group_id (Group_id_composition_category, category.defining_code)
	Is_persistent_validity: is_persistent implies context = Void
	Territory_valid: territory /= Void and then code_set(Code_set_id_countries).has(territory)
	Language_valid: language /= Void and then code_set(Code_set_id_languages).has(language)
	No_parent: parent = Void

end



