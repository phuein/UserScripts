ShowMount = {
    name                = "ShowMount",          -- Matches folder and Manifest file names.
    author              = "phuein & Sponsored by ShadowOFMen from Tamriel Crown Exchange",
    color               = "ffc235",             -- Used in menu titles and so on.
    menuName            = "ShowMount ",         -- UNIQUE identifier for menu object.
    -- Default settings.
    savedVariables = {
        FirstLoad   = true,                     -- First time ever that the addon is loaded.
        -- Mount selection.
        MountOne    = 0,
        MountTwo    = 0,
        MountThree  = 0,
        MountFour   = 0,
        EnableChatCmds = true,
        SortByName = false,
    },
    -- Sounds.
    soundWarn           = SOUNDS.QUICKSLOT_USE_EMPTY, -- Maybe SOUNDS.LOCKPICKING_BREAK instead?
    soundInfo           = SOUNDS.QUEST_SHARED,
    soundSet            = SOUNDS.QUEST_FOCUSED,
    soundReset          = SOUNDS.QUEST_ABANDONED,
    -- Populate unlocked mounts list for settings, every time. Lists all match item indexes.
    mountsIds       = {},
    mountsNames     = {},
    mountsNamesMenu = {},   -- Without affecting indexes, first item is always "-".
    mountsLinks     = {},
    mountsTextures  = {},
    -- Tracking.
    mountCurrent    = 0     -- Last activate mount by mount_id.
}

-- Convert int to str for mount slots.
ShowMount.Num2Num = {"One", "Two", "Three", "Four"}

-- Wraps text with a color.
function ShowMount.Colorize(text, color)
    -- Default to addon's .color.
    if not color then color = ShowMount.color end

    text = "|c" .. color .. text .. "|r"

    return text
end

-- Verbosity.
ShowMount.Instructions  = "Type " .. ShowMount.Colorize("/sm", "ffa500") .. " to select your mounts."
ShowMount.NoneActive    = "A mount must be Set Active first."
-- Or EsoStrings[SI_COLLECTIBLEUSAGEBLOCKREASON9] -> "This collectible is not ready yet."
ShowMount.CooldownMsg   = ShowMount.Colorize("Can't switch mounts that fast.", "ffa500") -- Orange.

-- Returns item index from chosen list.
function ShowMount.GetIndex(list, item)
    local t={}

    for k,v in pairs(ShowMount[list]) do
       t[v]=k
    end

    return t[item]
end

-- Returns true if cooldown time hasn't elapsed; Falsy otherwise.
-- t - os.time()
function ShowMount.CoolingDown(t)
    if os.time() - t <= ShowMount.lastEventCooldown then return true end
end

-- Return an in-game texture format for images to display.
-- NOTE: This is specifically designed for these notifications.
-- Defualts to 100x100 pixels.
-- Newlines to avoid overlap with text or images.
-- f - Filename with path.
function ShowMount.FormatTexture(f)
    return "\n\n\n|t128:128:" .. f .. "|t\n\n"
end

-- Populate the unlocked mounts list on demand.
function ShowMount.PopulateMounts()
    -- Reset.
    ShowMount.mountsIds         = {}
    ShowMount.mountsNames       = {}
    ShowMount.mountsNamesMenu   = {"-"}
    ShowMount.mountsLinks       = {}
    ShowMount.mountsTextures    = {}

    -- Stop when matched as many as are unlocked.
    local maxMatches = GetTotalUnlockedCollectiblesByCategoryType(COLLECTIBLE_CATEGORY_TYPE_MOUNT)
    local len = GetTotalCollectiblesByCategoryType(COLLECTIBLE_CATEGORY_TYPE_MOUNT)

    for i=1,len do
        if maxMatches == 0 then break end

        -- Get mount_id from index.
        local mount_id = GetCollectibleId(8, nil, i)

        -- Add if unlocked.
        if GetCollectibleUnlockStateById(mount_id) ~= 0 then
            local index = #ShowMount.mountsIds+1
            ShowMount.mountsIds[index]          = mount_id
            ShowMount.mountsNames[index]        = GetCollectibleName(mount_id)
            ShowMount.mountsLinks[index]        = GetCollectibleLink(mount_id)
            ShowMount.mountsTextures[index]     = GetCollectibleIcon(mount_id)
            -- For menu lists without affecting indexes.
            ShowMount.mountsNamesMenu[#ShowMount.mountsNamesMenu+1] = GetCollectibleName(mount_id)

            -- Count.
            maxMatches = maxMatches - 1
        end
    end
end

-- Returns True and prints message,
-- if current active mount is still in cooldown and can't be switched.
function ShowMount.IsCooldown()
    local msg

    -- Current mount.
    local mount_id = GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_MOUNT)

    -- Don't flood Collectible activations before cooldown.
    local cooldown, duration = GetCollectibleCooldownAndDuration(mount_id)
    if duration > 0 then
        -- Verbose.
        msg = ShowMount.CooldownMsg
        -- d(msg)
        ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, ShowMount.soundWarn, msg)
        return true
    end
end

-- Return a mount_id from vague selection.
function ShowMount.SelectMount(m)
    local mount_id

    if m == "Random" then
        -- Random mount selection from unlocked mounts.
        mount_id = ShowMount.mountCurrent

        if #ShowMount.mountsIds == 0 then
            -- If no mounts are unlocked.
            mount_id = 0
        elseif #ShowMount.mountsIds == 1 then
            -- If only one mount is unlocked, always return it.
            mount_id = ShowMount.mountsIds[1]
        else
            -- Loop until selecting a mount different from current.
            local i
            while mount_id == ShowMount.mountCurrent do
                i = math.random(1, #ShowMount.mountsIds)
                mount_id = ShowMount.mountsIds[i]
            end
        end
    else
        -- Specific selection from slot.
        mount_id = ShowMount.savedVariables["Mount" .. m]
    end

    return mount_id
end

-- Set mount as active, if set by user.
-- m - "Random", or "One", "Two", ...
function ShowMount.ActivateMount(m)
    local msg

    -- Can't switch during cooldown. Prints message.
    if ShowMount.IsCooldown() then return end

    local mount_id = ShowMount.SelectMount(m)

    -- Selection not available.
    -- Either slot is empty or no mounts are unlocked.
    -- NOTE: nil is not expected.
    if mount_id == 0 or mount_id == nil then
        -- Silent fail.
        return
    end

    -- Switch.
    UseCollectible(mount_id)
    -- Track.
    ShowMount.mountCurrent = mount_id

    -- Verbose.
    msg = "Active mount set to " .. GetCollectibleLink(mount_id) .. "."
    -- d(msg)
    msg = msg .. ShowMount.FormatTexture(GetCollectibleIcon(mount_id)) -- Add image.
    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, ShowMount.soundInfo, msg)
end

-- Reference helper for SLASH_COMMAND.
function ShowMount.ActivateMountOne()
    ShowMount.ActivateMount("One")
end

-- Reference helper for SLASH_COMMAND.
function ShowMount.ActivateMountTwo()
    ShowMount.ActivateMount("Two")
end

-- Reference helper for SLASH_COMMAND.
function ShowMount.ActivateMountThree()
    ShowMount.ActivateMount("Three")
end

-- Reference helper for SLASH_COMMAND.
function ShowMount.ActivateMountFour()
    ShowMount.ActivateMount("Four")
end

-- Reference helper for SLASH_COMMAND.
function ShowMount.ActivateMountRandom()
    ShowMount.ActivateMount("Random")
end

-- Set Mount slot to selection or active mount.
-- NOTE: 0 should not be a possible id for any available collection item in the game.
function ShowMount.SetMount(mount_num, mount_id)
    local msg

    local mount_id = mount_id or GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_MOUNT)

    -- 0 means none is active.
    -- The player either has none, or hadn't activate any, yet.
    if mount_id == 0 then
        -- Verbose.
        msg = ShowMount.NoneActive
        -- d(msg)
        ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, ShowMount.soundSet, msg)
        return
    end

    ShowMount.savedVariables["Mount" .. mount_num] = mount_id

    -- Verbose.
    msg = "Mount " .. mount_num .. " set to " .. GetCollectibleLink(mount_id) .. "."
    -- d(msg)
    msg = msg .. ShowMount.FormatTexture(GetCollectibleIcon(mount_id)) -- Add image.
    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, ShowMount.soundSet, msg)
end

-- Reset mount by number, or reset all mounts if nil.
function ShowMount.ResetMounts(mount_num)
    local msg

    if mount_num == nil then
        -- Reset all.
        ShowMount.savedVariables["MountOne"]    = 0
        ShowMount.savedVariables["MountTwo"]    = 0
        ShowMount.savedVariables["MountThree"]  = 0
        ShowMount.savedVariables["MountFour"]   = 0
        msg = "All mounts have been reset."
    else
        -- Reset selection.
        ShowMount.savedVariables["Mount" .. mount_num] = 0
        msg = "Mount " .. mount_num .. " has been reset."
    end

    -- Verbose.
    -- d(msg)
    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, ShowMount.soundReset, msg)
end

-- Enable or disable chat commands.
function ShowMount.EnableChatCommands(b)
    ShowMount.savedVariables.EnableChatCmds = b

    if b then
        -- Slash commands must be lowercase. Set to nil to disable.
        -- SLASH_COMMANDS["/sm"] = ShowMount.ToggleMount
        -- NOTE: Shows selection menu instead.

        SLASH_COMMANDS["/sm1"] = ShowMount.ActivateMountOne
        SLASH_COMMANDS["/sm2"] = ShowMount.ActivateMountTwo
        SLASH_COMMANDS["/sm3"] = ShowMount.ActivateMountThree
        SLASH_COMMANDS["/sm4"] = ShowMount.ActivateMountFour

        SLASH_COMMANDS["/smr"] = ShowMount.ActivateMountRandom
    else
        -- SLASH_COMMANDS["/sm"]  = nil

        SLASH_COMMANDS["/sm1"] = nil
        SLASH_COMMANDS["/sm2"] = nil
        SLASH_COMMANDS["/sm3"] = nil
        SLASH_COMMANDS["/sm4"] = nil

        SLASH_COMMANDS["/smr"] = nil
    end

    -- Reset autocomplete cache to update it.
    SLASH_COMMAND_AUTO_COMPLETE:InvalidateSlashCommandCache()
end

-- Tell player how to use the addon on first load ever.
function ShowMount.Activated(e)
    EVENT_MANAGER:UnregisterForEvent(ShowMount.name, EVENT_PLAYER_ACTIVATED)

    if ShowMount.savedVariables.FirstLoad then
        ShowMount.savedVariables.FirstLoad = false

        local msg = ShowMount.Instructions
        d(msg)
        ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, ShowMount.soundWarn, msg)
    end

    -- Update current mount.
    ShowMount.mountCurrent = GetActiveCollectibleByType(COLLECTIBLE_CATEGORY_TYPE_MOUNT)
end
-- When player is ready, after everything has been loaded.
EVENT_MANAGER:RegisterForEvent(ShowMount.name, EVENT_PLAYER_ACTIVATED, ShowMount.Activated)

function ShowMount.OnAddOnLoaded(event, addonName)
    if addonName ~= ShowMount.name then return end
    EVENT_MANAGER:UnregisterForEvent(ShowMount.name, EVENT_ADD_ON_LOADED)

    ShowMount.savedVariables = ZO_SavedVars:New("ShowMountSavedVariables", 1, nil, ShowMount.savedVariables)

    -- Populate unlocked mounts list.
    ShowMount.PopulateMounts()

    -- Settings menu in Settings.lua.
    ShowMount.LoadSettings()

    ShowMount.EnableChatCommands(ShowMount.savedVariables.EnableChatCmds)
end
-- When any addon is loaded, but before UI (Chat) is loaded.
EVENT_MANAGER:RegisterForEvent(ShowMount.name, EVENT_ADD_ON_LOADED, ShowMount.OnAddOnLoaded)