note
	component:   "openEHR Archetype Project"
	description: "[
				 EV_GRID control for compiler error output. A preferable implementation is to separate the logical
				 (i.e. non-GUI related) list) of errors, probably in the class ARCHETYPE_COMPILER, which would make
				 it visible when built as a DLL or other component separate from the Vision GUI. To do that, it 
				 would require some way of the GUI update knowing how to add the latest entry/ies to the grid, 
				 without having to do a complete rebuild every time, which is what will happen when a complete
				 build of the archetype system is done.
				 ]"
	keywords:    "ADL"
	author:      "Peter Gummer <peter.gummer@oceaninformatics.com>"
	support:     "Ocean Informatics <support@OceanInformatics.com>"
	copyright:   "Copyright (c) 2007 Ocean Informatics Pty Ltd"
	license:     "See notice at bottom of class"

	file:        "$URL$"
	revision:    "$LastChangedRevision$"
	last_change: "$LastChangedDate$"


class GUI_ERROR_TOOL

inherit
	EV_KEY_CONSTANTS
		export
			{NONE} all;
		end

	EV_SHARED_APPLICATION
		export
			{NONE} all
		end

	SHARED_KNOWLEDGE_REPOSITORY
		export
			{NONE} all
		end

	SHARED_APP_UI_RESOURCES
		export
			{NONE} all
		end

	STRING_UTILITIES
		export
			{NONE} all
		end

	ARCHETYPE_STATISTICAL_DEFINITIONS
		export
			{NONE} all
		end

	COMPILER_ERROR_TYPES
		export
			{NONE} all
		end

create
	make

feature -- Definitions

	Col_category: INTEGER = 1
	Col_location: INTEGER = 2
	Col_message: INTEGER = 3

feature {NONE} -- Initialisation

	make (a_select_archetype_from_gui_data_agent: like select_archetype_from_gui_data;
			an_update_gui_with_compiler_error_counts_agent: like update_gui_with_compiler_error_counts)
			-- Create to control `a_main_window.compiler_output_grid'.
		do
			select_archetype_from_gui_data := a_select_archetype_from_gui_data_agent
			update_gui_with_compiler_error_counts := an_update_gui_with_compiler_error_counts_agent
			create categories.make_filled (Void, Err_type_valid, Err_type_warning)
			create ev_grid.make
			ev_grid.enable_tree
			ev_grid.disable_row_height_fixed
			ev_grid.hide_tree_node_connectors
			ev_grid.add_key_event (key_enter, agent select_node_in_archetype_tree_view)
		end

feature -- Commands

	clear
			-- Wipe out the content from `grid'.
		do
			ev_grid.wipe_out
			categories.discard_items

			ev_grid.insert_new_column (Col_category)
			ev_grid.insert_new_column (Col_location)
			ev_grid.insert_new_column (Col_message)
			ev_grid.column (Col_category).set_title ("Category")
			ev_grid.column (Col_location).set_title ("Archetype")
			ev_grid.column (Col_message).set_title ("Message")

			update_errors_tab_label
		end

	extend_and_select (ara: attached ARCH_CAT_ARCHETYPE)
			-- Add a node representing the errors or warnings of the archetype, if any.
		local
			gli: EV_GRID_LABEL_ITEM
			cat_row, row, subrow: EV_GRID_ROW
			i, row_idx: INTEGER
		do
			remove_archetype_row_if_in_wrong_category (ara)

			if ara.compiler_error_type /= err_type_valid then
				ensure_row_for_category (ara.compiler_error_type)
				cat_row := categories [ara.compiler_error_type]

				from
					row_idx := 0
					i := 1
				until
					i /= 1
				loop
					row_idx := row_idx + 1

					if row_idx <= cat_row.subrow_count then
						row := cat_row.subrow (row_idx)
						row.collapse

						if attached {ARCH_CAT_ARCHETYPE} row.data as other then
							i := ara.id.three_way_comparison (other.id)
						end
					else
						i := -1
					end
				end

				if i = -1 then
					cat_row.insert_subrow (row_idx)
					row := cat_row.subrow (row_idx)
					row.set_data (ara)
					row.collapse_actions.extend (agent ev_grid.step_to_viewable_parent_of_selected_row)
					row.insert_subrow (1)
				end

				subrow := row.subrow (1)
				cat_row.expand
				create gli.make_with_text (utf8_to_utf32 (ara.id.as_string))
				gli.set_pixmap (get_icon_pixmap ("archetype/" + ara.group_name))

				gli.set_tooltip (utf8_to_utf32 (ara.errors.as_string))
				gli.pointer_double_press_actions.force_extend (agent select_node_in_archetype_tree_view)
				row.set_item (col_location, gli)
				row.expand
				gli.enable_select

				if gli.is_displayed then
					gli.ensure_visible
				end

				create gli.make_with_text (utf8_to_utf32 (ara.errors.as_string))
				subrow.set_item (col_message, gli)
				subrow.set_height (gli.text_height)

				if gli.is_displayed then
					gli.ensure_visible
				end

				ev_grid.column (Col_category).resize_to_content
				ev_grid.column (Col_location).resize_to_content
				ev_grid.column (Col_message).resize_to_content
			end

			update_errors_tab_label
		end

	export_repository_report (xml_file_name: attached STRING)
			-- Export the contents of the grid and other statistics to XML file `xml_name'.
		require
			xml_file_name_valid: not xml_file_name.is_empty
		local
			err_type, i: INTEGER
			category: STRING
			message_lines: LIST [STRING]
			ns: XM_NAMESPACE
			document: XM_DOCUMENT
			processing: XM_PROCESSING_INSTRUCTION
			root, statistics_element, category_element, archetype_element: XM_ELEMENT
			attr: XM_ATTRIBUTE
			data: XM_CHARACTER_DATA
			create_category_element: PROCEDURE [ANY, TUPLE]
			pretty_printer: XM_INDENT_PRETTY_PRINT_FILTER
			xmlns_generator: XM_XMLNS_GENERATOR
			file: KL_TEXT_OUTPUT_FILE
			name1, name2: STRING
		do
			create ns.make_default
			create document.make
			create processing.make_last_in_document (document, "xml-stylesheet", "type=%"text/xsl%" href=%"ArchetypeRepositoryReport.xsl%"")
			create root.make_root (document, "archetype-repository-report", ns)

			create_category_element := agent (parent: XM_ELEMENT; description: STRING; count: INTEGER)
				local
					e: XM_ELEMENT
					a: XM_ATTRIBUTE
				do
					create e.make_last (parent, "category", parent.namespace)
					create a.make_last ("description", parent.namespace, description, e)
					create a.make_last ("count", parent.namespace, count.out, e)
				end

			create statistics_element.make_last (root, "statistics", ns)
			create_category_element.call ([statistics_element, "Total Archetypes", current_arch_cat.archetype_count])
			create_category_element.call ([statistics_element, "Specialised Archetypes", current_arch_cat.catalogue_metrics.item (specialised_archetype_count)])
			create_category_element.call ([statistics_element, "Archetypes with slots", current_arch_cat.catalogue_metrics.item (client_archetype_count)])
			create_category_element.call ([statistics_element, "Archetypes used by others", current_arch_cat.catalogue_metrics.item (supplier_archetype_count)])

			from
				err_type := categories.lower
			until
				err_type = categories.upper
			loop
				err_type := err_type + 1
				category := err_type_names [err_type]
				create_category_element.call ([statistics_element, category, count_for_category (err_type)])

				if attached {EV_GRID_ROW} categories [err_type] as row then
					create_category_element.call ([root, category, row.subrow_count])
					category_element ?= root.last

					from i := 0 until i = row.subrow_count loop
						i := i + 1

						if attached {ARCH_CAT_ARCHETYPE} row.subrow (i).data as ara then
							create archetype_element.make_last (category_element, "archetype", ns)
							create attr.make_last ("id", ns, ara.id.as_string, archetype_element)

							from
								message_lines := ara.errors.as_string.split ('%N')
								message_lines.start
							until
								message_lines.off
							loop
								if not message_lines.item.is_empty then
									create data.make_last (create {XM_ELEMENT}.make_last (archetype_element, "message", ns), message_lines.item)
								end

								message_lines.forth
							end
						end
					end
				end
			end

			create file.make (xml_file_name)
			file.open_write

			if file.is_open_write then
				create pretty_printer.make_null
				pretty_printer.set_output_stream (file)
				create xmlns_generator.set_next (pretty_printer)
				document.process_to_events (xmlns_generator)
				file.close

				name1 := file_system.pathname (application_startup_directory, "ArchetypeRepositoryReport.css")
				name2 := file_system.pathname (file_system.dirname (xml_file_name), "ArchetypeRepositoryReport.css")
				file_system.copy_file (name1, name2)
				file_system.copy_file (extension_replaced (name1, ".xsl"), extension_replaced (name2, ".xsl"))
			end
		end

feature -- Access

	ev_grid: EV_GRID_KBD_MOUSE

	parse_error_count: NATURAL
			-- Number of parser errors.
		do
			Result := count_for_category (err_type_parse_error)
		end

	validity_error_count: NATURAL
			-- Number of parser errors.
		do
			Result := count_for_category (err_type_validity_error)
		end

	warning_count: NATURAL
			-- Number of parser errors.
		do
			Result := count_for_category (err_type_warning)
		end

feature {NONE} -- Implementation

	select_archetype_from_gui_data: PROCEDURE [ANY, TUPLE [EV_ANY]]
			-- agent provided by upper level of GUI for doing something
			-- when an archetype in this tool is selected

	update_gui_with_compiler_error_counts: PROCEDURE [ANY, TUPLE [NATURAL, NATURAL, NATURAL]]
			-- agent provided by upper GUI for providing feedback about current error counts

	select_node_in_archetype_tree_view
			-- Select the archetype represented by `selected_cell' in the main window's explorer tree.
		do
			if attached ev_grid.selected_cell and then ev_grid.selected_cell.column.index = Col_location then
				select_archetype_from_gui_data.call ([ev_grid.selected_cell.row])
			end
		end

	update_errors_tab_label
			-- On the Errors tab, indicate parse errors, validity errors and warnings.
		do
			if attached update_gui_with_compiler_error_counts then
				update_gui_with_compiler_error_counts.call ([parse_error_count, validity_error_count, warning_count])
			end
		end

	ensure_row_for_category (err_type: INTEGER)
			-- Insert a row into `grid' representing `err_type', if there was no such row already.
		require
			not_too_small: err_type >= categories.lower
			not_too_big: err_type <= categories.upper
		local
			gli: EV_GRID_LABEL_ITEM
			i, row_idx: INTEGER
			row: EV_GRID_ROW
		do
			if categories [err_type] = Void then
				from
					i := categories.upper
					row_idx := ev_grid.row_count + 1
				until
					i = err_type
				loop
					if categories [i] /= Void then
						row_idx := categories [i].index
					end

					i := i - 1
				end

				ev_grid.insert_new_row (row_idx)
				row := ev_grid.row (row_idx)
				row.set_data (err_type)
				row.collapse_actions.extend (agent ev_grid.step_to_viewable_parent_of_selected_row)
				create gli.make_with_text (utf8_to_utf32 (err_type_names [err_type]))
				gli.set_pixmap (get_icon_pixmap ("tool/" + err_type_keys [err_type]))

				row.set_item (col_category, gli)
				categories [err_type] := row
			end
		ensure
			category_row_attached: categories [err_type] /= Void
		end

	remove_archetype_row_if_in_wrong_category (ara: attached ARCH_CAT_ARCHETYPE)
			-- Remove the row representing `ara' from `grid' if it is under the wrong category.
		local
			cat_row, row: EV_GRID_ROW
			row_idx: INTEGER
		do
			from
				row_idx := ev_grid.row_count
			until
				row_idx = 0
			loop
				row := ev_grid.row (row_idx)
				row_idx := row_idx - 1

				if attached {ARCH_CAT_ARCHETYPE} row.data as other then
					if ara.id.is_equal (other.id) then
						row_idx := 0
						cat_row := row.parent_row

						if cat_row /= categories [ara.compiler_error_type] then
							if cat_row.subrow_count > 1 then
								ev_grid.remove_row (row.index)
							else
								ev_grid.remove_row (cat_row.index)

								if attached {INTEGER_REF} cat_row.data as i then
									categories [i.item] := Void
								end
							end
						end
					end
				end
			end
		end

	count_for_category (err_type: INTEGER): NATURAL
			-- Number of parser errors.
		require
			not_too_small: err_type >= categories.lower
			not_too_big: err_type <= categories.upper
		do
			if attached {EV_GRID_ROW} categories [err_type] as row then
				Result := row.subrow_count.as_natural_32
			end
		end

	categories: attached ARRAY [EV_GRID_ROW]
			-- Rows containing category grouper in column 1.

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
--| The Original Code is gui_compiler_error_control.e
--|
--| The Initial Developer of the Original Code is Thomas Beale.
--| Portions created by the Initial Developer are Copyright (C) 2007
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
