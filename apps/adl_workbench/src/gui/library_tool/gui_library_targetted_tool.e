note
	component:   "openEHR ADL Tools"
	description: "General model of a GUI tool whose data source is an archetype/template library"
	keywords:    "GUI, archteype"
	author:      "Thomas Beale <thomas.beale@openehr.org>"
	support:     "http://www.openehr.org/issues/browse/AWB"
	copyright:   "Copyright (c) 2011- The openEHR Foundation <http://www.openEHR.org>"
	license:     "Apache 2.0 License <http://www.apache.org/licenses/LICENSE-2.0.html>"

deferred class GUI_LIBRARY_TARGETTED_TOOL

inherit
	GUI_TOOL
		redefine
			source, selection_history, selected_item
		end

	SHARED_GUI_LIBRARY_TOOL_AGENTS
		export
			{NONE} all
		end

feature -- Access

	source: detachable ARCHETYPE_LIBRARY
			-- archetype catalogue to which this tool is targetted

	tool_artefact_id: STRING
			-- a system-wide unique artefact id that can be used to find a tool in a GUI collection like
			-- docked panes or similar
		do
			Result := "catalogue"
		end

	selection_history: ARCHETYPE_LIBRARY_SELECTION_HISTORY
		attribute
			create Result.make
		end

	selected_item: detachable ARCH_LIB_ITEM
		do
			Result := selection_history.selected_item
		end

end


