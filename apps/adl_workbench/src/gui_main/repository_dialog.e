note
	component:   "openEHR Archetype Project"
	description: "[
				 Dialog for the user to enter the repository paths (original version of this class was generated by EiffelBuild).
				 The dialog takes a complete copy of the current profiles structure, and allows the user to play with it, i.e.
				 add new profiles, remove profiles and rename profiles. No choosing of the 'current profile' is done on this 
				 dialog - that is done in the dropdown on the main application form. However, removal of the current profile will
				 cause a new profile to be used in the main application.
				 ]"
	keywords:    "GUI, ADL, archetype"
	author:      "Thomas Beale"
	support:     "http://www.openehr.org/issues/browse/AWB"
	copyright:   "Copyright (c) 2008-2011 Ocean Informatics Pty Ltd <http://www.oceaninfomatics.com>"
	license:     "See notice at bottom of class"

	file:        "$URL$"
	revision:    "$LastChangedRevision$"
	last_change: "$LastChangedDate$"

class
	REPOSITORY_DIALOG

inherit
	EV_DIALOG
		redefine
			initialize, is_in_default_state
		end

	SHARED_APP_UI_RESOURCES
		undefine
			is_equal, default_create, copy
		end

	STRING_UTILITIES
		export
			{NONE}
		undefine
			is_equal, default_create, copy
		end

feature {NONE} -- Initialization

	initialize
			-- Initialize `Current'.
		do
			Precursor {EV_DIALOG}

			create gui_controls.make (0)

			set_minimum_width (530)
			set_minimum_height (280)
			set_maximum_width (800)
			set_maximum_height (800)
			set_title (get_text ("repository_dialog_title"))
			set_icon_pixmap (adl_workbench_icon)

			-- ============ root container ============
			create ev_root_container
			extend (ev_root_container)
			ev_root_container.set_padding (Default_padding_width)
			ev_root_container.set_border_width (Default_border_width)

			-- dialog frame
			create profile_frame_ctl.make (get_text ("profile_list_text"), 0, 0, False)
			ev_root_container.extend (profile_frame_ctl.ev_root_container)

			-- profile list + buttons HBOX
			profile_frame_ctl.add_row (False)

			-- profile list
			create profile_list
			profile_list.set_minimum_height (100)
			profile_list.select_actions.extend (agent on_select_profile)
			profile_frame_ctl.extend (profile_list, True)

			-- ========== buttons VBOX ==============
			create ev_vbox_2
			profile_frame_ctl.extend (ev_vbox_2, False)
			ev_vbox_2.set_minimum_width (100)
			ev_vbox_2.set_padding (Default_padding_width)
			ev_vbox_2.set_border_width (Default_border_width)

			-- add button
			create profile_add_button
			profile_add_button.set_text (get_text ("add_new_profile_button_text"))
			profile_add_button.set_tooltip (get_text ("add_new_profile_button_tooltip"))
			profile_add_button.select_actions.extend (agent add_new_profile)
			ev_vbox_2.extend (profile_add_button)
			ev_vbox_2.disable_item_expand (profile_add_button)

			-- remove button
			create profile_remove_button
			profile_remove_button.set_text (get_text ("remove_profile_button_text"))
			profile_remove_button.set_tooltip (get_text ("remove_profile_button_tooltip"))
			profile_remove_button.select_actions.extend (agent remove_selected_profile)
			ev_vbox_2.extend (profile_remove_button)
			ev_vbox_2.disable_item_expand (profile_remove_button)

			-- edit button
			create profile_edit_button
			profile_edit_button.set_text (get_text ("edit_profile_button_text"))
			profile_edit_button.set_tooltip (get_text ("edit_profile_button_tooltip"))
			profile_edit_button.select_actions.extend (agent edit_selected_profile)
			ev_vbox_2.extend (profile_edit_button)
			ev_vbox_2.disable_item_expand (profile_edit_button)

			-- reference path display control
			create ref_path_ctl.make (get_text ("ref_repo_text"), agent :STRING do Result := rep_profiles_copy.profile (selected_profile_key).reference_repository end, 0, 0, True, True)
			ev_root_container.extend (ref_path_ctl.ev_root_container)
			ev_root_container.disable_item_expand (ref_path_ctl.ev_root_container)
			gui_controls.extend (ref_path_ctl)

			-- work path display control
			create work_path_ctl.make (get_text ("work_repo_text"),
				agent :STRING
					do
						if rep_profiles_copy.profile (selected_profile_key).has_work_repository then
							Result := rep_profiles_copy.profile (selected_profile_key).work_repository
						else
							Result := ""
						end
					end,
				0, 0, True, True)
			ev_root_container.extend (work_path_ctl.ev_root_container)
			ev_root_container.disable_item_expand (work_path_ctl.ev_root_container)
			gui_controls.extend (work_path_ctl)

			-- ============ Ok/Cancel buttons ============
			create ok_cancel_buttons.make (agent on_ok, agent hide)
			ev_root_container.extend (ok_cancel_buttons.ev_root_container)
			ev_root_container.disable_item_expand (ok_cancel_buttons.ev_root_container)
			set_default_cancel_button (ok_cancel_buttons.cancel_button)
			set_default_push_button (ok_cancel_buttons.ok_button)

			-- Connect events.
			show_actions.extend (agent on_show)

			rep_profiles_copy := repository_profiles.deep_twin
			selected_profile_key := rep_profiles_copy.current_profile_name
			populate_controls
		end

feature {NONE} -- Events

	on_show
			-- On showing the dialog, set focus to the profile combo box, adding a new one if there are none yet.
		do
			if rep_profiles_copy.is_empty then
				add_new_profile
			else
				profile_list.set_focus
			end
		end

	on_ok
			-- When the user clicks the OK button, save the changes and rebuild `archetype_directory'.
		do
			set_repository_profiles (rep_profiles_copy)
			current_profile_removed := current_profile_removed_pending
			current_profile_changed := current_profile_changed_pending
			any_profile_changes_made := any_profile_changes_made_pending or current_profile_removed or current_profile_changed
			hide
		end

	on_select_profile
			-- Called by `select_actions' of `profile_list'; all that is done is to populate the
			-- repository directory controls with the relevant directories, and to set the local
			-- variable `selected_profile' (not to be confused with the 'current profile' chosen
			-- in the application)
		do
			if not profile_list.is_empty then
				selected_profile_key := utf32_to_utf8 (profile_list.selected_item.text)
				do_populate
			end
		end

	add_new_profile
			-- Called by `select_actions' of `profile_add_button'.
		local
			edit_dialog: PROFILE_EDIT_DIALOG
		do
			create edit_dialog.make_new (rep_profiles_copy)
			edit_dialog.show_modal_to_window (Current)
			if edit_dialog.is_valid then
				selected_profile_key := rep_profiles_copy.current_profile_name
				any_profile_changes_made_pending := any_profile_changes_made_pending or edit_dialog.has_changed_profile
				-- if there was no profile initially, and one was just created => register change
				current_profile_changed_pending := current_profile_changed_pending or not repository_profiles.has_current_profile
				populate_controls
			end
			edit_dialog.destroy
		end

	edit_selected_profile
			-- Called by `select_actions' of `profile_edit_button'.
		local
			edit_dialog: PROFILE_EDIT_DIALOG
		do
			if attached selected_profile_key then
				create edit_dialog.make_edit (rep_profiles_copy, selected_profile_key)
				edit_dialog.show_modal_to_window (Current)
				if edit_dialog.is_valid and edit_dialog.has_changed_profile then
					selected_profile_key := rep_profiles_copy.current_profile_name
					populate_controls
					current_profile_changed_pending := current_profile_changed_pending or repository_profiles.current_profile_name ~ edit_dialog.initial_profile_name
					any_profile_changes_made_pending := True
				end
				edit_dialog.destroy
			end
		end

	remove_selected_profile
			-- Called by `select_actions' of `profile_remove_button'.
		local
			prof_names: ARRAYED_LIST [STRING]
			error_dialog: EV_INFORMATION_DIALOG
		do
			if rep_profiles_copy.count > 1 then
				current_profile_removed_pending := current_profile_removed_pending or repository_profiles.current_profile_name ~ selected_profile_key
				rep_profiles_copy.remove_profile (selected_profile_key)

				-- figure out which profile to make the new current one
				prof_names := profile_names
				prof_names.search (selected_profile_key)
				prof_names.remove
				if not prof_names.is_empty then
					if prof_names.off then
						prof_names.finish
					end
					selected_profile_key := prof_names.item
					rep_profiles_copy.set_current_profile_name (selected_profile_key)
				else
					selected_profile_key := Void
				end
				populate_controls
			else
				create error_dialog.make_with_text (get_msg_line ("cant_remove_last_profile", Void))
				error_dialog.show_modal_to_window (Current)
			end
		end

feature {NONE} -- Access

	rep_profiles_copy: attached REPOSITORY_PROFILE_CONFIG
			-- local copy of the state of profiles at dialog launch, as a table of
			-- {{ref_path, working path}, prof_name}

	selected_profile_key: STRING
			-- name of profile currently chosen in dialog

feature -- Status

	current_profile_removed: BOOLEAN
			-- flag to indicate that one or more profiles were removed; set from `current_profile_removed_pending'
			-- Should only be set in `on_ok', because until changes are written from the profiles 'copy'
			-- object to the real thing (done in `on_ok'), nothing has actually changed in the application

	current_profile_changed: BOOLEAN
			-- Has the user changed the paths or name for the current profile in use in the main application?
			-- Set from `current_profile_changed_pending'
			-- Should only be set in `on_ok', because until changes are written from the profiles 'copy'
			-- object to the real thing (done in `on_ok'), nothing has actually changed in the application

	any_profile_changes_made: BOOLEAN
			-- have any changes been made at all (if so, resources should be saved in application)
			-- Should only be set in `on_ok', because until changes are written from the profiles 'copy'
			-- object to the real thing (done in `on_ok'), nothing has actually changed in the application

feature {NONE} -- Implementation

	do_populate
			-- Set the dialog widgets from shared settings.
		do
			gui_controls.do_all (agent (an_item: GUI_DATA_CONTROL) do an_item.populate end)
		end

	any_profile_changes_made_pending: BOOLEAN
			-- True if any change at all was made to `current_profile_removed'

	current_profile_removed_pending: BOOLEAN
			-- flag to indicate that one or more profiles were removed from cached copy; this flag will
			-- be copied to `current_profile_removed'

	current_profile_changed_pending: BOOLEAN
			-- Has the user changed the paths or name for the current profile in use in the main application,
			-- within the cached copy of the profiles?

	profile_names: attached ARRAYED_LIST [STRING]
			-- The names of all of the profiles displayed in `profile_list'.
		do
			Result := profile_list.strings_8
			Result.compare_objects
		ensure
			comparing_objects: Result.object_comparison
			correct_count: Result.count = profile_list.count
		end

	populate_controls
			-- Initialise the dialog's widgets from shared settings.
		do
			profile_list.set_strings (rep_profiles_copy.names)

			if not profile_list.is_empty then
				profile_list.i_th (profile_names.index_of (selected_profile_key, 1).max (1)).enable_select
				do_populate
			end
		end

	ev_root_container: EV_VERTICAL_BOX

	gui_controls: ARRAYED_LIST [GUI_DATA_CONTROL]

	ev_vbox_2: EV_VERTICAL_BOX

	profile_frame_ctl: GUI_FRAME_CONTROL

	ref_path_ctl, work_path_ctl: GUI_SINGLE_LINE_TEXT_CONTROL

	profile_list: EV_LIST

	profile_add_button, profile_remove_button, profile_edit_button: EV_BUTTON
	reference_path_text, work_path_text: EV_TEXT_FIELD

	ok_cancel_buttons: GUI_OK_CANCEL_CONTROLS

	is_in_default_state: BOOLEAN
			-- Is `Current' in its default state?
		do
			Result := True
		end

invariant
	selected_profile_key_valid: attached selected_profile_key implies rep_profiles_copy.has_profile (selected_profile_key)

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
--| The Original Code is repository_dialog.e.
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
