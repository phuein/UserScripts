NBUI = {}

NBUI.name = "Notebook2018"
-- NBUI.version = "4.13"
NBUI.settings = {
	NB1_Anchor 					= {a = CENTER, b = CENTER, x = 0, y = -20},
	NB1_BookColor 				= {1, 1, 1, 1},
	NB1_TextColor				= {0, 0, 0, 0.7},	-- Notebook title, page title, and text.
	NB1_SelectionColor			= {1, 1, 1, 0.5},	-- R, G, B, A. Between 0 and 1.
	NB1_ShowTitle 				= true,
	NB1_Title 					= "Notebook",
	NB1_Locked 					= true,
	NB1_NewPageTitle 			= "",		-- Empty defaults to time and date.
	NB1_ShowDialog 				= true,	
	NB1_ChatButton 				= true,
	NB1Pages 					= {},
	NB1_AccountWide 			= false,	-- Pages saved for all characters. Overrides character pages!
	NB1_EditModeHover 			= false,	-- Enter Edit Mode on mouse hover on page.
	NB1_EditModeClick 			= true,		-- Enter Edit Mode on mouse click on page.
	NB1_LeaveEditModeOnFocus 	= true,		-- Leave Edit Mode on page lose focus (click outside.)
	NB1_LeaveEditModeOnExit 	= false,	-- Leave Edit Mode on mouse exit page area.
	NB1_DoubleClickSelectPage 	= false,	-- Selects whole page when double clicking, instead of a word.
	NB1_EmoteRead 				= true,		-- Emotes /read when Notebook is open.
	NB1_EmoteIdle				= true,		-- Emotes /idle after closing the Notebook.
	NB1_SelectLine				= true,		-- Select whole line with by tripleclicking it.
	NB1_FormattedMode			= true,		-- Whether to display formatted-text mode Label over Editbox.
}

function ProtectText(text)
	return text:gsub([[\]], [[%%92]])
end

function UnprotectText(text)
	return text:gsub([[%%92]], [[\]])
end

function NBUI.Initialize()
	-- Load saved variables.
	NBUI.dbCharacter = ZO_SavedVars:New("NBUISVDB", 1, nil, NBUI.settings)
	NBUI.db = NBUI.dbCharacter

	NBUI.dbAccount = ZO_SavedVars:NewAccountWide("NBUISVDBACCT", 1, nil, NBUI.settings)
	NBUI.dbAccount.NB1_AccountWide = true -- Always reflect account mode when using it, like in settings.
	-- Switch to account settings.
	if NBUI.db.NB1_AccountWide then
		NBUI.db = NBUI.dbAccount
	end
	
	NB1_IndexPool = ZO_ObjectPool:New(Create_NB1_IndexButton, Remove_NB1_IndexButton)
	
	CreateNB1()
	
	Populate_NB1_ScrollList()
end

function NBUI.OnAddOnLoaded(event, addonName)
  if addonName == NBUI.name then
	NBUI.Initialize()
	CreateNBUISettings()
	ZO_CreateStringId("SI_BINDING_NAME_NBUI_NB1TOGGLE", GetString(SI_NBUI_NB1KEYBIND_LABEL))
  end
end
EVENT_MANAGER:RegisterForEvent(NBUI.name, EVENT_ADD_ON_LOADED, NBUI.OnAddOnLoaded)