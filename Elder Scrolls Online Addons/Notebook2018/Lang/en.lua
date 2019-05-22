local localization_strings = {
		SI_NBUI_ADDON_NAME        = "Notebook",
		SI_NBUI_ADDONOPTIONS_NAME = "Notebook Options",
		SI_NBUI_AUTHOR            = "Bloodspill & phuein",

		-- Settings Panel
		SI_NBUI_DESCRIPTION_INFO = "A Virtual Notebook.",

		SI_NBUI_HEADER_BOOK 		= "Book",
		SI_NBUI_HEADER_COLORS 		= "Colors",
		SI_NBUI_HEADER_INTERACTIVE 	= "Interactive",

		SI_NBUI_SHOWTITLE_NAME   	= "Show Title",
		SI_NBUI_SHOWTITLE_TOOLTIP 	= "Displays the title of the book.",

		SI_NBUI_TITLE_NAME   	= "Book Title",
		SI_NBUI_TITLE_TOOLTIP 	= "Changes the title of the book.",

		SI_NBUI_COLOR_NAME   	= "Book Color",
		SI_NBUI_COLOR_TOOLTIP 	= "Changes the color of the book.",

		SI_NBUI_NEWPAGETITLE_NAME    = "Default New Page Title",
		SI_NBUI_NEWPAGETITLE_TOOLTIP = "Sets a default title for new pages. Empty this to default back to time and date.",

		SI_NBUI_ACCOUNTWIDE_NAME     = "Account-Wide Notebook",
		SI_NBUI_ACCOUNTWIDE_MAINTEXT = "This will Reload the UI immediately! Do you wish to continue?",
		SI_NBUI_ACCOUNTWIDE_TOOLTIP  = "One Notebook for all characters in your account.",

		SI_NBUI_ACCOUNTDELETE  		  = "Overwrite Account-Wide",
		SI_NBUI_ACCOUNTDELETE_TOOLTIP = "Overwrites the Account-Wide Notebook with the current character's pages.",

		SI_NBUI_DIALOG         	= "Confirmation Dialogs",
		SI_NBUI_DIALOG_TOOLTIP 	= "Turns confirmation dialogs On / Off.",

		SI_NBUI_LOCK_NAME   	= "Lock Position",
		SI_NBUI_LOCK_TOOLTIP 	= "This allows you to secure the notebook in place so that it can not be moved.",

		SI_NBUI_BUTTON_NAME   	= "Show Chat Button",
		SI_NBUI_BUTTON_TOOLTIP 	= "Adds a button in the chat window to open/close the book.",

		SI_NBUI_OFFSETMAX_NAME   	= "Offset Maximized Chat Button",
		SI_NBUI_OFFSETMAX_TOOLTIP 	= "Offsets the button in the maximized chat window.",

		SI_NBUI_OFFSETMIN_NAME   	= "Offset Minimized Chat Button",
		SI_NBUI_OFFSETMIN_TOOLTIP 	= "Offsets the button in the minimized chat window.",

		SI_NBUI_FORMATTEDMODE_NAME		= "Formatted Text Mode",
		SI_NBUI_FORMATTEDMODE_TOOLTIP	= "Toggle whether Formatted-Mode (colors, images) is available, at all.",

		SI_NBUI_EDITMODE_HOVER_NAME  	= "Enter Edit-Mode on Hover",
		SI_NBUI_EDITMODE_HOVER_TOOLTIP  = "Switch to page Edit-Mode when mouse hovers over the page.",

		SI_NBUI_EDITMODE_CLICK_NAME  	= "Enter Edit-Mode on Click",
		SI_NBUI_EDITMODE_CLICK_TOOLTIP  = "Switch to page Edit-Mode when clicking the page.",

		SI_NBUI_LEAVEEDITMODE_FOCUS_NAME  	= "Leave Edit-Mode on Focus",
		SI_NBUI_LEAVEEDITMODE_FOCUS_TOOLTIP = "Leave Edit-Mode when the page loses focus (clicking outside of it.)",

		SI_NBUI_LEAVEEDITMODE_EXIT_NAME  	= "Leave Edit-Mode on Exit",
		SI_NBUI_LEAVEEDITMODE_EXIT_TOOLTIP  = "Leave Edit-Mode when mouse exits (moves out of) the page.",

		SI_NBUI_DBLCLICKPAGE_NAME  		= "Double-Click To Select All",
		SI_NBUI_DBLCLICKPAGE_TOOLTIP  	= "Selects the whole page text, instead of a word, when double-clicking.",

		SI_NBUI_EMOTEREAD_NAME  	= "Emote When Reading",
		SI_NBUI_EMOTEREAD_TOOLTIP  	= "Emote /read when opening the Notebook.",

		SI_NBUI_EMOTEIDLE_NAME  	= "Emote Idle When Closed",
		SI_NBUI_EMOTEIDLE_TOOLTIP  	= "Emote /idle after closing the Notebook.",

		SI_NBUI_SELECTLINE_NAME  	= "Select Line with Tripleclick",
		SI_NBUI_SELECTLINE_TOOLTIP  = "Select current line by triple-clicking your mouse.",

		SI_NBUI_SELECTCOLOR_NAME	= "Text Selection Color",
		SI_NBUI_SELECTCOLOR_TOOLTIP	= "Changes the color of your text selection.",

		SI_NBUI_TEXTCOLOR_NAME		= "Text Color",
		SI_NBUI_TEXTCOLOR_TOOLTIP	= "Changes the text color of your notebook title, page title, and content.",

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

		SI_NBUI_NB1INFORMATION_TOOLTIP = "|c00FF00/nb|r toggles the window on/off.\n|c00FF00/nbs|r toggles the settings on/off.\n\n|c00FF00Tip:|r Selecting a page will undo your changes.",

		SI_NBUI_NB1KEYBIND_LABEL = "Notebook",
	}

for stringId, stringValue in pairs(localization_strings) do
   ZO_CreateStringId(stringId, stringValue)
   SafeAddVersion(stringId, 1)
end