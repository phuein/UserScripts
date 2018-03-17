Junkee = Junkee or {}
Junkee.__index = Junkee
Junkee.name = "Junkee2018"

local LAM = LibStub("LibAddonMenu-2.0")

local em = EVENT_MANAGER

local INVENTORIES_TO_HOOK = {INVENTORY_BACKPACK, INVENTORY_BANK}

Junkee.bagId  = nil
Junkee.slotId = nil
Junkee.isJunk = false

Junkee.defaults = {
	visible = true,
	firstRun = true
}

Junkee.isVisible = function()
	return Junkee.savedVars.visible
end
Junkee.setVisible = function(v)
	Junkee.savedVars.visible = v
end

Junkee.OnMouseEnter = function(control)
	Junkee.bagId  = control.dataEntry.data.bagId
	Junkee.slotId = control.dataEntry.data.slotIndex
	Junkee.isJunk = control.dataEntry.data.isJunk
	if Junkee.savedVars.visible then
		Junkee.AddJunkAction()
	end
end

Junkee.OnMouseExit = function(control)
	Junkee.bagId  = nil
	Junkee.slotId = nil
	Junkee.isJunk = false
	if Junkee.savedVars.visible then
		Junkee.RemoveJunkAction()
	end
end

local function registerHook(inventory)
	local listView = inventory.listView
	if listView and listView.dataTypes and listView.dataTypes[1] then
		local originalCallback = listView.dataTypes[1].setupCallback
		listView.dataTypes[1].setupCallback = function(rowControl, slot)
			originalCallback(rowControl, slot)
			ZO_PreHookHandler(rowControl, "OnMouseEnter", Junkee.OnMouseEnter)
			ZO_PreHookHandler(rowControl, "OnMouseExit",  Junkee.OnMouseExit)
		end
	end
end

local function registerHooks()
	for _, index in pairs(INVENTORIES_TO_HOOK) do
		registerHook(PLAYER_INVENTORY.inventories[index])
	end
end

-- Add menu with options.
local panelData = {
    type = "panel",
    name = "JunkeePanel",
    displayName = "Junkee Settings",
    registerForRefresh = true,
    registerForDefaults = true,
}

local optionsTable = {
    [1] = {
        type = "checkbox",
        name = "Display Keybindings",
        tooltip = "Display the addon's keybindings when opening the Inventory. " ..
        	"They appear on the bottom left.",
        getFunc = Junkee.isVisible,
        setFunc = Junkee.setVisible,
        width = "full",	--or "half",
    },
}

local function LoadMenu()
	LAM:RegisterAddonPanel("JunkeePanel", panelData)
	LAM:RegisterOptionControls("JunkeePanel", optionsTable)
end

Junkee.Loaded = function(eventCode, addonName)
	if (Junkee.name == addonName) then
		em:UnregisterForEvent(Junkee.name, EVENT_ADD_ON_LOADED)

		registerHooks()

		-- Load saved variables.
		Junkee.savedVars = ZO_SavedVars:New("JunkeeAddonSavedVars", 1, nil, Junkee.defaults)

		LoadMenu()
	end
end
em:RegisterForEvent(Junkee.name, EVENT_ADD_ON_LOADED, Junkee.Loaded)

Junkee.JunkIt = function()
	if Junkee.bagId == nil then return end
	local isJunk = IsItemJunk(Junkee.bagId, Junkee.slotId)
	SetItemIsJunk(Junkee.bagId, Junkee.slotId, not isJunk)
	if isJunk then	
		PlaySound(SOUNDS.INVENTORY_ITEM_UNJUNKED)		
	else
		PlaySound(SOUNDS.INVENTORY_ITEM_JUNKED)		
	end
end

Junkee.DeleteIt = function()
	if Junkee.bagId == nil then return end
	DestroyItem(Junkee.bagId, Junkee.slotId)
end

local function createJunkStripDescriptor(name)
	return JunkeeKeyStrip:New(name, "JUNKEE_JUNK_IT", Junkee.JunkIt)
end

local junkStripDescriptor = createJunkStripDescriptor(Junkee.tr("JunkLabel"))
local unjunkStripDescriptor = createJunkStripDescriptor(Junkee.tr("UnjunkLabel"))
local deleteStripDescriptor = JunkeeKeyStrip:New(Junkee.tr("DeleteLabel"), "JUNKEE_DELETE_IT", Junkee.DeleteIt)
local linkStripDescriptor = JunkeeKeyStrip:New(Junkee.tr("LinkLabel"), "JUNKEE_LINK_IT", Junkee.LinkIt)

Junkee.AddJunkAction = function()
	deleteStripDescriptor:Add(true)
	linkStripDescriptor:Add(true)
	if (Junkee.isJunk) then
		unjunkStripDescriptor:Add(true)
	else
		junkStripDescriptor:Add(true)
	end
end

Junkee.RemoveJunkAction = function()
	linkStripDescriptor:Remove()
	deleteStripDescriptor:Remove()
	junkStripDescriptor:Remove()
	unjunkStripDescriptor:Remove()
end

-- Link item in chat.
Junkee.LinkIt = function()
	if Junkee.bagId == nil then return end
	local link = GetItemLink(Junkee.bagId, Junkee.slotId, 1)
	ZO_LinkHandler_InsertLink(link)
end

-- Needed to bind Shift+T
function KEYBINDING_MANAGER:IsChordingAlwaysEnabled()
	return true
end

ZO_CreateStringId("SI_BINDING_NAME_JUNKEE_JUNK_IT", Junkee.tr("JunkBindingName"))
ZO_CreateStringId("SI_BINDING_NAME_JUNKEE_DELETE_IT", Junkee.tr("DeleteBindingName"))
ZO_CreateStringId("SI_BINDING_NAME_JUNKEE_LINK_IT", Junkee.tr("LinkBindingName"))

-- Act when everything is ready, for sure,
-- because player has acted.
local function OnActivated(eventCode, initial)
    em:UnregisterForEvent(addonName, eventCode)
    
    if Junkee.savedVars.firstRun then
		Junkee.savedVars.firstRun = false
		-- Do on first run of addon.
		d("Junkee recommended keybindings:\nJunk/UnJunk = Z, Destroy = Shift+Z, Link = F2.")
	end
end
em:RegisterForEvent(Junkee.name, EVENT_PLAYER_ACTIVATED, OnActivated)
