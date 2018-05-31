if NBUI == nil then NBUI = {} end

local localization_strings = {
		SI_NBUI_ADDON_NAME        = "Notebook",
		SI_NBUI_ADDONOPTIONS_NAME = "Notebook Options",
		SI_NBUI_AUTHOR            = "Bloodspill & phuein",
		SI_NBUI_VERSION_NUM       = "|c00FF004.1|r",
			
		-- Settings Panel
		SI_NBUI_DESCRIPTION_INFO = "A Virtual Notebook.",
		
		SI_NBUI_HEADER_GENERAL = "General Settings",
		
		SI_NBUI_SHOWTITLE_LABEL   = "Show Title",
		SI_NBUI_SHOWTITLE_TOOLTIP = "Displays the title of the book.",
		
		SI_NBUI_TITLE_LABEL   = "Book Title",
		SI_NBUI_TITLE_TOOLTIP = "Changes the title of the book.",
		
		SI_NBUI_COLOR_LABEL   = "Book Color",
		SI_NBUI_COLOR_TOOLTIP = "Changes the color of the book.",
		
		SI_NBUI_DIALOG         = "Confirmation Dialogs",
		SI_NBUI_DIALOG_TOOLTIP = "Turns on/off confirmation dialogs.",
		
		SI_NBUI_LOCK_LABEL   = "Lock Position",
		SI_NBUI_LOCK_TOOLTIP = "This allows you to secure the notebook in place so that it can not be moved.",
		
		SI_NBUI_BUTTON_LABEL   = "Show Chat Button",
		SI_NBUI_BUTTON_TOOLTIP = "Adds a button in the chat window to open/close the book.",

		SI_NBUI_OFFSETMAX_LABEL   = "Offset Maximized Chat Button",
		SI_NBUI_OFFSETMAX_TOOLTIP = "Offsets the button in the maximized chat window.",
		
		SI_NBUI_OFFSETMIN_LABEL   = "Offset Minimized Chat Button",
		SI_NBUI_OFFSETMIN_TOOLTIP = "Offsets the button in the minimized chat window.",
		
		SI_NBUI_WARNING = "This setting must be applied and will result in a load screen.",
		
		-- UI Panel	
		SI_NBUI_CLOSEBUTTON_TOOLTIP = "Close the book.",
		
		SI_NBUI_RUNBUTTON_TOOLTIP = "Run this page as a Lua script.",

		SI_NBUI_DELETEBUTTON_TITLE    = "Delete Page",
		SI_NBUI_DELETEBUTTON_MAINTEXT = "Do you want to delete this page?",
		SI_NBUI_DELETEBUTTON_TOOLTIP  = "Delete this page.",
		
		SI_NBUI_NEWBUTTON_TITLE    = "New Page",
		SI_NBUI_NEWBUTTON_MAINTEXT = "Do you want to create a new page?",
		SI_NBUI_NEWBUTTON_TOOLTIP  = "Create a new page.",
		
		SI_NBUI_SAVEBUTTON_TITLE    = "Save Page",
		SI_NBUI_SAVEBUTTON_MAINTEXT = "Do you want to save changes made to this page?",
		SI_NBUI_SAVEBUTTON_TOOLTIP  = "Save changes made to this page.",
		
		SI_NBUI_UNDOPAGE_TITLE     = "Undo Page",
		SI_NBUI_UNDOPAGE_MAINTEXT  = "Do you want to undo all changes made to this page? It will go back to last save.",
		SI_NBUI_UNDOBUTTON_TOOLTIP = "Undo changes made to this page.",

		SI_NBUI_MOVEPAGEUPBUTTON_TOOLTIP = "Move this page up in the index.",

		SI_NBUI_MOVEPAGEDOWNBUTTON_TOOLTIP = "Move this page down in the index.",

		SI_NBUI_PREVIEWBUTTON_TOOLTIP = "Preview this page by rendering colors, padding, and textures.",
		
		SI_NBUI_YES_LABEL = "Yes",
		SI_NBUI_NO_LABEL  = "No",

		SI_NBUI_NB1INFORMATION_TOOLTIP = "Commands:\n|c00FF00/nb|r toggles the window on/off.\n|c00FF00/nbs|r toggles the settings on/off.",
		
		SI_NBUI_NB1KEYBIND_LABEL = "Notebook",
	}

for stringId, stringValue in pairs(localization_strings) do
   ZO_CreateStringId(stringId, stringValue)
   SafeAddVersion(stringId, 1)
end