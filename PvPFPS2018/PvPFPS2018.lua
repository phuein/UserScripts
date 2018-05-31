pvpfps = {
    name = "PvPFPS2018",            -- Matches folder and Manifest file names.
    version = "1.1",
    author = "phuein",
    color = "00DDDD",               -- Used in menu titles and so on.
    menuName = "PvP FPS 2018",      -- Unique identifier for menu object.
    -- Default settings.
    savedVars = {
        normalSS    = nil, -- Will default to current level used, if not saved before.
        lowSS       = SUB_SAMPLING_MODE_LOW, -- 0
        chatMsg     = true,
        ssCmd       = false,
        disabled    = false,
    }
}
local savedVars = pvpfps.savedVars

local LAM = LibStub("LibAddonMenu-2.0")

-- Set later from current.
local curSS = nil

-- Wraps text with a color.
local function Colorize(text, color)
    -- Default to addon's .color.
    if not color then color = pvpfps.color end

    text = "|c" .. color .. text .. "|c"
end

-- Add menu with options.
local panelData = {
    type = "panel",
    name = pvpfps.menuName,
    displayName = Colorize(pvpfps.menuName),
    registerForRefresh = true,
    registerForDefaults = true,
}

local optionsTable = {
    [1] = {
        type = "checkbox",
        name = "Chat Information",
        tooltip = "Display information in a chat message, instead of an alert.",
        getFunc = function()
                return savedVars.chatMsg
            end,
        setFunc = function(v)
                savedVars.chatMsg = v
            end,
        width = "full", --or "half",
    },
    [2] = {
        type = "slider",
        name = "Normal SubSample",
        tooltip = "The SubSample quality used outside of PvP zones.",
        min = SUB_SAMPLING_MODE_LOW,
        max = SUB_SAMPLING_MODE_NORMAL,
        getFunc = function()
                return savedVars.normalSS
            end,
        setFunc = function(v)
                -- Change into new value if being used.
                local changed = savedVars.normalSS == curSS
                savedVars.normalSS = v
                if changed then changeSS(v) end
            end,
        width = "full", --or "half",
    },
    [3] = {
        type = "slider",
        name = "Low SubSample",
        tooltip = "The SubSample quality used in PvP zones.",
        min = SUB_SAMPLING_MODE_LOW,
        max = SUB_SAMPLING_MODE_NORMAL,
        getFunc = function()
                return savedVars.lowSS
            end,
        setFunc = function(v)
                -- Change into new value if being used.
                local changed = savedVars.lowSS == curSS
                savedVars.lowSS = v
                if changed then changeSS(v) end
            end,
        width = "full", --or "half",
    },
    [4] = {
        type = "checkbox",
        name = "/ss",
        tooltip = "Activate the '/ss #' chat command for quick SubSample changing.",
        getFunc = function()
                return savedVars.ssCmd
            end,
        setFunc = function(v)
                savedVars.ssCmd = v
                if v then
                    SLASH_COMMANDS["/ss"] = changeSS
        		else
                    SLASH_COMMANDS["/ss"] = nil
                end
                -- Reset autocomplete cache to update it.
        		SLASH_COMMAND_AUTO_COMPLETE:InvalidateSlashCommandCache()
            end,
        width = "full", --or "half",
    },
    [5] = {
        type = "checkbox",
        name = "Disable Automatic SubSampling Changer",
        tooltip = "If you want to temporarily disable the automatic SubSampling quality changes on zone changes.",
        getFunc = function()
                return savedVars.disabled
            end,
        setFunc = function(v)
                savedVars.disabled = v
            end,
        width = "full", --or "half",
    },
}

local function LoadMenu()
    LAM:RegisterAddonPanel(pvpfps.menuName, panelData)
    LAM:RegisterOptionControls(pvpfps.menuName, optionsTable)
end

local function changeSS(v)
    v = tonumber(v)
    -- Only valid values accepted.
    if v == nil or v == curSS then
        d('Current SubSampling quality is '..curSS..'.')
        return
    end
    if v == nil or v > SUB_SAMPLING_MODE_NORMAL or v < SUB_SAMPLING_MODE_LOW then
        d('Only values between '..SUB_SAMPLING_MODE_LOW..' and '..
            SUB_SAMPLING_MODE_NORMAL..' are valid for SubSampling.')
        return
    end

    SetSetting(SETTING_TYPE_GRAPHICS, GRAPHICS_SETTING_SUB_SAMPLING, v)
    local oldSS = curSS
    curSS = v
    d('Changed SubSampling from '..oldSS..' to '..curSS..'.')
end

pvpfps.CheckPVP = function(e)
    -- Automatic changer can be manually disabled tamporarily.
    if savedVars.disabled then return end

    if IsInCyrodiil() or IsActiveWorldBattleground() then
        if curSS == savedVars.lowSS then return end

        if savedVars.chatMsg then
            d('Entering a PvP Zone. Changing SubSampling from '..curSS..
                ' to '..savedVars.lowSS..'.')
        else
            ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, 
                'Entering a PvP Zone. Changing SubSampling from '..curSS..
                ' to '..savedVars.lowSS..'.')
        end

        SetSetting(SETTING_TYPE_GRAPHICS, GRAPHICS_SETTING_SUB_SAMPLING, savedVars.lowSS)
        curSS = savedVars.lowSS
    else
        if curSS == savedVars.normalSS then return end

        if savedVars.chatMsg then 
            d('Entering a PvE Zone. Changing SubSampling from '..curSS..
                ' to '..savedVars.normalSS..'.')
        else
            ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, 
                'Entering a PvE Zone. Changing SubSampling from '..curSS..
                ' to '..savedVars.normalSS..'.')
        end

        SetSetting(SETTING_TYPE_GRAPHICS, GRAPHICS_SETTING_SUB_SAMPLING, savedVars.normalSS)
        curSS = savedVars.normalSS
    end
end
EVENT_MANAGER:RegisterForEvent(pvpfps.name, EVENT_PLAYER_ACTIVATED, pvpfps.CheckPVP)

-- Initialize settings, menu, and event.
pvpfps.OnLoaded = function(e, addonName)
    if addonName ~= pvpfps.name then return end
    EVENT_MANAGER:UnregisterForEvent(pvpfps.name, EVENT_ADD_ON_LOADED)

    -- Load saved variables.
    savedVars = ZO_SavedVars:New("PVPFPSAddonSavedVars", 1, nil, savedVars)

    -- Settings menu.
    LoadMenu()

    if savedVars.ssCmd then
        SLASH_COMMANDS["/ss"] = changeSS
        -- Reset autocomplete cache to update it.
        SLASH_COMMAND_AUTO_COMPLETE:InvalidateSlashCommandCache()
    end

    -- Load settings.
    curSS = GetSetting(SETTING_TYPE_GRAPHICS, GRAPHICS_SETTING_SUB_SAMPLING)
    if not savedVars.normalSS then savedVars.normalSS = curSS end
end
EVENT_MANAGER:RegisterForEvent(pvpfps.name, EVENT_ADD_ON_LOADED, pvpfps.OnLoaded)