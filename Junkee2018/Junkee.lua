Junkee = Junkee or {}
Junkee.__index = Junkee
Junkee.name = "Junkee2018"

local LAM = LibStub("LibAddonMenu-2.0")

local em = EVENT_MANAGER

local INVENTORIES_TO_HOOK = {INVENTORY_BACKPACK, INVENTORY_BANK}

Junkee.slotControl = nil -- Reference for misc' properties.
Junkee.bagId  = nil
Junkee.slotId = nil
Junkee.isJunk = false

-- Defaults.
Junkee.savedVars = {
	visible = true, 		-- All items visible.
	DestroyVisible = true,
	LinkVisible = true,
	LockVisible = true,
	firstRun = true,
	nameInChat = true,
	hideMainQuest = false,
	-- Each command name will have "/" prepended to it automatically.
	slashCmds = {
		GroupLeave = {
			cmd = "/gl",
			active = false,
			f = function()
					if IsUnitGrouped("player") then
		    			GroupLeave()
		    		end
		    	end
		},
		GroupDisband = {
			cmd = "/gd",
			active = false,
			f = function()
					if IsUnitGrouped("player") and IsUnitGroupLeader("player") then
		    			GroupDisband()
		    		end
		    	end
		},
		d = {
			cmd = "/d",
			active = false,
			f = function(text)
				CHAT_SYSTEM:StartTextEntry("/script d(" .. text .. ")")
			end
		},
	}
}

Junkee.OnMouseEnter = function(control)
	Junkee.slotControl = control
	Junkee.bagId  = control.dataEntry.data.bagId
	Junkee.slotId = control.dataEntry.data.slotIndex
	Junkee.isJunk = control.dataEntry.data.isJunk
	if Junkee.savedVars.visible then
		Junkee.AddJunkAction()
	end
end

Junkee.OnMouseExit = function(control)
	Junkee.slotControl = nil
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
    name = "Junkee 2018",
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
        getFunc = function() return Junkee.savedVars.visible end,
        setFunc = function(v) Junkee.savedVars.visible = v end,
        width = "full",	--or "half",
    },
    [2] = {
        type = "checkbox",
        name = "Display the Destroy Keybinding",
        tooltip = "Display the addon's keybinding for Destroy when opening the Inventory.",
        getFunc = function()
        	return Junkee.savedVars.visible and Junkee.savedVars.DestroyVisible
        end,
        setFunc = function(v) Junkee.savedVars.DestroyVisible = v end,
        width = "full",	--or "half",
    },
    [3] = {
        type = "checkbox",
        name = "Display the Link Keybinding",
        tooltip = "Display the addon's keybinding for Link when opening the Inventory.",
        getFunc = function()
        	return Junkee.savedVars.visible and Junkee.savedVars.LinkVisible
        end,
        setFunc = function(v) Junkee.savedVars.LinkVisible = v end,
        width = "full",	--or "half",
    },
    [4] = {
        type = "checkbox",
        name = "Display the Lock Keybinding",
        tooltip = "Display the addon's keybinding for Lock when opening the Inventory.",
        getFunc = function()
        	return Junkee.savedVars.visible and Junkee.savedVars.LockVisible
        end,
        setFunc = function(v) Junkee.savedVars.LockVisible = v end,
        width = "full",	--or "half",
    },
    [5] = {
        type = "checkbox",
        name = Junkee.savedVars.slashCmds["GroupLeave"].cmd,
        tooltip = "Chat command to leave your group.",
        getFunc = function()
        		return Junkee.savedVars.slashCmds["GroupLeave"].active
        	end,
        setFunc = function(v)
        		local cmd = Junkee.savedVars.slashCmds["GroupLeave"].cmd

        		Junkee.savedVars.slashCmds["GroupLeave"].active = v
        		if v then
        			SLASH_COMMANDS[cmd] = Junkee.savedVars.slashCmds["GroupLeave"].f
        		else
        			SLASH_COMMANDS[cmd] = nil
        		end
        		-- Reset autocomplete cache to update it.
        		SLASH_COMMAND_AUTO_COMPLETE:InvalidateSlashCommandCache()
        	end,
        width = "full",	--or "half",
    },
    [6] = {
        type = "checkbox",
        name = Junkee.savedVars.slashCmds["GroupDisband"].cmd,
        tooltip = "Chat command to disband your group.",
        getFunc = function()
        		return Junkee.savedVars.slashCmds["GroupDisband"].active
        	end,
        setFunc = function(v)
        		local cmd = Junkee.savedVars.slashCmds["GroupDisband"].cmd

        		Junkee.savedVars.slashCmds["GroupDisband"].active = v
        		if v then
        			SLASH_COMMANDS[cmd] = Junkee.savedVars.slashCmds["GroupDisband"].f
        		else
        			SLASH_COMMANDS[cmd] = nil
        		end
        		-- Reset autocomplete cache to update it.
        		SLASH_COMMAND_AUTO_COMPLETE:InvalidateSlashCommandCache()
        	end,
        width = "full",	--or "half",
	},
	[7] = {
        type = "checkbox",
        name = Junkee.savedVars.slashCmds["d"].cmd,
        tooltip = "Chat command to automatically replace /d CMD with /script d(CMD).",
        getFunc = function()
        		return Junkee.savedVars.slashCmds["d"].active
        	end,
        setFunc = function(v)
        		local cmd = Junkee.savedVars.slashCmds["d"].cmd

        		Junkee.savedVars.slashCmds["d"].active = v
        		if v then
        			SLASH_COMMANDS[cmd] = Junkee.savedVars.slashCmds["d"].f
        		else
        			SLASH_COMMANDS[cmd] = nil
        		end
        		-- Reset autocomplete cache to update it.
        		SLASH_COMMAND_AUTO_COMPLETE:InvalidateSlashCommandCache()
        	end,
        width = "full",
	},
	[8] = {
		type = "checkbox",
		name = "Name in Chat",
		tooltip = "Mouse Middle-Click copies an inventory item's name into the chat and selects it, for quick copying.",
		getFunc = function()
				return Junkee.savedVars.nameInChat
			end,
		setFunc = function(v)
				Junkee.savedVars.nameInChat = v
			end,
		width = "full",
	},
	[9] = {
		type = "checkbox",
		name = "Hide Main Quest",
		tooltip = "Hides the Main Quest from the Journal.",
		getFunc = function()
				return Junkee.savedVars.hideMainQuest
			end,
		setFunc = function(v)
				Junkee.savedVars.hideMainQuest = v
				-- Apply change now. Reload all quests, in case we're adding them back.
				QUEST_JOURNAL_KEYBOARD:RefreshQuestMasterList()
				QUEST_JOURNAL_KEYBOARD:RefreshQuestList()
			end,
		width = "full",
	},
}

local function LoadMenu()
	LAM:RegisterAddonPanel("Junkee 2018", panelData)
	LAM:RegisterOptionControls("Junkee 2018", optionsTable)
end

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
local lockStripDescriptor = JunkeeKeyStrip:New(Junkee.tr("LockLabel"), "JUNKEE_LOCK_IT", Junkee.LockIt)

Junkee.AddJunkAction = function()
	if (Junkee.isJunk) then
		junkStripDescriptor:Remove()
		unjunkStripDescriptor:Add(true)
	else
		unjunkStripDescriptor:Remove()
		junkStripDescriptor:Add(true)
	end

	if Junkee.savedVars.DestroyVisible then deleteStripDescriptor:Add(true) end
	if Junkee.savedVars.LinkVisible then linkStripDescriptor:Add(true) end
	if Junkee.savedVars.LockVisible then lockStripDescriptor:Add(true) end
end

Junkee.RemoveJunkAction = function()
	unjunkStripDescriptor:Remove()
	junkStripDescriptor:Remove()

	deleteStripDescriptor:Remove()
	linkStripDescriptor:Remove()
	lockStripDescriptor:Remove()
end

-- Link item in chat.
Junkee.LinkIt = function()
	if Junkee.bagId == nil then return end

	local link = GetItemLink(Junkee.bagId, Junkee.slotId, 1)
	ZO_LinkHandler_InsertLink(link)
end

-- Un/Lock item.
Junkee.LockIt = function()
	if Junkee.bagId == nil then return end

	local bag, index = Junkee.bagId, Junkee.slotId
	local locking = not IsItemPlayerLocked(bag, index) -- The locking state to apply.
	if CanItemBePlayerLocked(bag, index) then
	    SetItemIsPlayerLocked(bag, index, locking)
	    PlaySound(not locking and SOUNDS.INVENTORY_ITEM_LOCKED or SOUNDS.INVENTORY_ITEM_UNLOCKED)
	end

	-- Below is taken from the game code for locking.
	-- IsItemAlreadySlottedToCraft() errors,
	-- so until that's solved I use the above code. Reference:
	-- http://www.esoui.com/forums/showthread.php?p=34500

	-- local inventorySlot = Junkee.slotControl
	-- local bag, index = Junkee.bagId, Junkee.slotId -- ZO_Inventory_GetBagAndIndex(inventorySlot)
	-- local locking = not IsItemPlayerLocked(bag, index) -- The locking state to apply.
	-- local action

	-- if locking then
	-- 	action = SI_ITEM_ACTION_MARK_AS_LOCKED
	-- 	-- Can't lock these.
	-- 	if IsItemAlreadySlottedToCraft(inventorySlot) then return end
	-- else
	-- 	action = SI_ITEM_ACTION_UNMARK_AS_LOCKED
	-- end

 --    if CanItemBePlayerLocked(bag, index) and
 --    	not QUICKSLOT_WINDOW:AreQuickSlotsShowing() then
 --        slotActions:AddSlotAction(action,
 --        	function() MarkAsPlayerLockedHelper(bag, index, locking) end,
 --        	"secondary")
 --    end
end

-- Needed to bind CTRL/Shift+KEY.
function KEYBINDING_MANAGER:IsChordingAlwaysEnabled()
	return true
end

ZO_CreateStringId("SI_BINDING_NAME_JUNKEE_JUNK_IT", Junkee.tr("JunkBindingName"))
ZO_CreateStringId("SI_BINDING_NAME_JUNKEE_DELETE_IT", Junkee.tr("DeleteBindingName"))
ZO_CreateStringId("SI_BINDING_NAME_JUNKEE_LINK_IT", Junkee.tr("LinkBindingName"))
ZO_CreateStringId("SI_BINDING_NAME_JUNKEE_LOCK_IT", Junkee.tr("LockBindingName"))

ZO_CreateStringId("SI_BINDING_NAME_JUNKEE_COPY_NAME", "Name in Chat")

-- Copies text to chat inputbox and selects it, for quick copying.
local function CopyToChatInput(text)
	CHAT_SYSTEM:StartTextEntry(text)
	ZO_ChatWindowTextEntryEditBox:SelectAll()
end

-- Get formatted item name from slot.
local function SlotToName(inventorySlot)
	local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)

	if index and bag then
		-- Some slot items require formatting. Taking this from game code:
		-- https://esodata.uesp.net/100017/src/ingame/crafting/craftinginventory.lua.html#192
		 return zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(bag, index))
	end
end

-- Some cases return the row, so get the name from that.
local function RowToName(inventorySlot)
	if inventorySlot.dataEntry then
		return inventorySlot.dataEntry.data.name
	end
end

-- Find the matching slot index in list.
local function AttachmentToName(inventorySlot)
	local link = GetAttachedItemLink(MAIL_INBOX:GetOpenMailId(), ZO_Inventory_GetSlotIndex(inventorySlot), LINK_STYLE_DEFAULT)
	if link then
		return zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(link))
	end
end

-- Add middle-mouse button to click listener.
local function AddMiddleMouseButton(slotControl, stackCount, iconFile, meetsUsageRequirement, locked)
	-- Patch for mail items, or any Control really.
	slotControl:EnableMouseButton(MOUSE_BUTTON_INDEX_MIDDLE, true)
end

-- Middle mouse copies item name to chat.
local function MiddleMouseCopiesNameToChat(inventorySlot, button)
	-- Enabled.
	if Junkee.savedVars.nameInChat == false then return	end

	-- Middle mouse button.
	if button == MOUSE_BUTTON_INDEX_MIDDLE then
		-- Rows.
		local name = RowToName(inventorySlot)
		-- Slots.
		if not name then name = SlotToName(inventorySlot) end
		-- Mail attachments.
		if not name then name = AttachmentToName(inventorySlot) end

		-- Silent failure.
		if name then
			CopyToChatInput(name)
		end
	end
end

-- Pre-hook to add buttons to mouse click event.
local function PreHookMouseButtons()
	ZO_PreHook("ZO_Inventory_SetupSlot", AddMiddleMouseButton)
end

-- Pre-hook adding name copying with click.
local function PreHookNameCopyClick()
	ZO_PreHook("ZO_InventorySlot_OnSlotClicked", MiddleMouseCopiesNameToChat)
end

-- Hides the Main Quest category from the Journal.
local function HideMainQuest()
	-- Enabled.
	if Junkee.savedVars.hideMainQuest == false then return end

	for i=1, #QUEST_JOURNAL_KEYBOARD.questMasterList.quests do
		if QUEST_JOURNAL_KEYBOARD.questMasterList.quests[i].categoryName == "Main Quest" then
			QUEST_JOURNAL_KEYBOARD.questMasterList.quests[i] = nil
		end
	end

	for i=1, #QUEST_JOURNAL_KEYBOARD.questMasterList.categories do
		if QUEST_JOURNAL_KEYBOARD.questMasterList.categories[i].name == "Main Quest" then
			QUEST_JOURNAL_KEYBOARD.questMasterList.categories[i] = nil
		end
	end
end

-- Pre-hook main quest from journal.
local function PreHookMainQuest()
	ZO_PreHook(QUEST_JOURNAL_KEYBOARD, "RefreshQuestList", HideMainQuest)
	-- Apply now.
	QUEST_JOURNAL_KEYBOARD:RefreshQuestList()
end

-- Act when everything is ready, for sure,
-- because player has acted.
local function OnActivated(eventCode, initial)
    em:UnregisterForEvent(addonName, eventCode)

    if Junkee.savedVars.firstRun then
		Junkee.savedVars.firstRun = false
		-- Do on first run of addon.
		d("Junkee recommends these keybindings:\n" ..
			"Junk/UnJunk = Z, Destroy = Shift+Z, Link = F2, Lock = Tab.")
	end

	-- Hook mouse buttons, such as for mail attachments.
	PreHookMouseButtons()

	-- Pre-hook click event.
	PreHookNameCopyClick()

	-- Remove Main Quests from quests list, so they're hidden.
	PreHookMainQuest()
end
em:RegisterForEvent(Junkee.name, EVENT_PLAYER_ACTIVATED, OnActivated)

Junkee.Loaded = function(eventCode, addonName)
	if (Junkee.name == addonName) then
		em:UnregisterForEvent(Junkee.name, EVENT_ADD_ON_LOADED)

		registerHooks()

		-- Load saved variables.
		Junkee.savedVars = ZO_SavedVars:New("JunkeeAddonSavedVars", 2, nil, Junkee.savedVars)

		-- Settings menu.
		LoadMenu()

		-- Chat /slash commands.
		local newCmds
		for name, item in pairs(Junkee.savedVars.slashCmds) do
			if item.active then
				newCmds = true
				SLASH_COMMANDS[item.cmd] = item.f
			end
		end
		-- Reset autocomplete cache to update it.
		if newCmds then
			SLASH_COMMAND_AUTO_COMPLETE:InvalidateSlashCommandCache()
		end
	end
end
em:RegisterForEvent(Junkee.name, EVENT_ADD_ON_LOADED, Junkee.Loaded)