local LAM = LibStub("LibAddonMenu-2.0")
local savedVars = {
    toggle = true
}

-- Add menu with options.
local panelData = {
    type = "panel",
    name = "BestFriends 2018",
    displayName = "BestFriends Settings",
    registerForRefresh = true,
    registerForDefaults = true,
}

local optionsTable = {
    [1] = {
        type = "checkbox",
        name = "Toggle Notifications",
        tooltip = "Toggle notification to not display at all.",
        getFunc = function()
                return savedVars.toggle
            end,
        setFunc = function(v)
                savedVars.toggle = v
            end,
        width = "full", --or "half",
    },
}

local function LoadMenu()
    LAM:RegisterAddonPanel("BestFriends 2018", panelData)
    LAM:RegisterOptionControls("BestFriends 2018", optionsTable)
end

-- Copied and edited from source:
-- https://esoapi.uesp.net/100022/src/ingame/chatsystem/chathandlers.lua.html
-- Original irrelevant code commented out, for reference.
local function initialize(event, addonName)
    if addonName ~= "BestFriends2018" then return end

    -- Load saved variables.
    savedVars = ZO_SavedVars:New("BestfriendsAddonSavedVars", 1, nil, savedVars)

    -- Settings menu.
    LoadMenu()
    
    local function statusChanged(displayName, characterName, oldStatus, newStatus)
        -- Toggled off.
        if not savedVars.toggle then return end

        local wasOnline = oldStatus ~= PLAYER_STATUS_OFFLINE
        local isOnline = newStatus ~= PLAYER_STATUS_OFFLINE
        
        if wasOnline ~= isOnline then
            local text
            local displayNameLink = ZO_LinkHandler_CreateDisplayNameLink(displayName)
            local characterNameLink = ZO_LinkHandler_CreateCharacterLink(characterName)
            if isOnline then
                if characterName ~= "" then
                    --text = zo_strformat(SI_FRIENDS_LIST_FRIEND_CHARACTER_LOGGED_ON, displayNameLink, characterNameLink)
                    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, 
                        SI_FRIENDS_LIST_FRIEND_LOGGED_ON, displayNameLink, characterNameLink)
                else
                    --text = zo_strformat(SI_FRIENDS_LIST_FRIEND_LOGGED_ON, displayNameLink)
                    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, SI_FRIENDS_LIST_FRIEND_LOGGED_ON, 
                        displayNameLink)
                end
            else
                if characterName ~= "" then
                    --text = zo_strformat(SI_FRIENDS_LIST_FRIEND_CHARACTER_LOGGED_OFF, displayNameLink, characterNameLink)
                    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, 
                        SI_FRIENDS_LIST_FRIEND_CHARACTER_LOGGED_OFF, displayNameLink, characterNameLink)
                else
                    --text = zo_strformat(SI_FRIENDS_LIST_FRIEND_LOGGED_OFF, displayNameLink)
                    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, SI_FRIENDS_LIST_FRIEND_CHARACTER_LOGGED_OFF, 
                        displayNameLink)
                end
            end
            -- return text, nil, displayName
        end
    end

    ZO_ChatSystem_GetEventHandlers()[EVENT_FRIEND_PLAYER_STATUS_CHANGED] = statusChanged
end
EVENT_MANAGER:RegisterForEvent("BestFriends2018", EVENT_ADD_ON_LOADED, initialize)