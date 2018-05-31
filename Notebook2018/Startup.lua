NBUI = {}

NBUI.name = "Notebook2018"
NBUI.version = "4.13"
NBUI.settings = {}

function ProtectText(text)
	return text:gsub([[\]], [[%%92]])
end

function UnprotectText(text)
	return text:gsub([[%%92]], [[\]])
end

function NBUI.Initialize()
	-- Load saved variables.
	NBUI.db = ZO_SavedVars:New("NBUISVDB", 1, nil, NBUI.defaults)
	-- NBUISVDB = NBUISVDB or {}
	-- for k,v in pairs(NBUI.defaults) do
	--     if type(NBUISVDB[k]) == "nil" then
	-- 		NBUISVDB[k] = v
	--     end
	-- end
	-- NBUISVDB.NB1Pages = NBUISVDB.NB1Pages or {}	
	
	NB1_IndexPool = ZO_ObjectPool:New(Create_NB1_IndexButton, Remove_NB1_IndexButton)
	
	CreateNBUISettings()
end

function NBUI.OnAddOnLoaded(event, addonName)
  if addonName == NBUI.name then
	NBUI.Initialize()
	
	CreateNB1()
	
	Populate_NB1_ScrollList()
	
	ZO_CreateStringId("SI_BINDING_NAME_NBUI_NB1TOGGLE", GetString(SI_NBUI_NB1KEYBIND_LABEL))
  end
end

EVENT_MANAGER:RegisterForEvent(NBUI.name, EVENT_ADD_ON_LOADED, NBUI.OnAddOnLoaded)