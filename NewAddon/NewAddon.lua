NewAddon = {
    name            = "NewAddon",           -- Matches folder and Manifest file names.
    version         = "1.0",
    author          = "Developer",
    color           = "DDFFEE",             -- Used in menu titles and so on.
    menuName        = "NewAddon Options",   -- Unique identifier for menu object.
    -- Default settings.
    savedVariables = {},
}

local LAM = LibStub("LibAddonMenu-2.0")

-- Wraps text with a color.
local function Colorize(text, color)
    -- Default to addon's .color.
    if not color then color = NewAddon.color end

    text = "|c" .. color .. text .. "|c"
end

-- Settings menu.
local panelData = {
    type = "panel",
    name = NewAddon.menuName,
    displayName = Colorize(NewAddon.menuName),
    author = Colorize(NewAddon.author, "AAF0BB"),
    version = Colorize(NewAddon.version, "AA00FF"),
    slashCommand = "/newaddon",
    registerForRefresh = true,
    registerForDefaults = true,
}

local optionsTable = {
    [1] = {
        type = "header",
        name = "My Header",
        width = "full",	--or "half" (optional)
    },
    [2] = {
        type = "description",
        --title = "My Title",	--(optional)
        title = nil,	--(optional)
        text = "My description text to display.",
        width = "full",	--or "half" (optional)
    },
    [3] = {
        type = "dropdown",
        name = "My Dropdown",
        tooltip = "Dropdown's tooltip text.",
        choices = {"table", "of", "choices"},
        getFunc = function() return "of" end,
        setFunc = function(var) print(var) end,
        width = "half",	--or "half" (optional)
        warning = "Will need to reload the UI.",	--(optional)
    },
    [4] = {
        type = "dropdown",
        name = "My Dropdown",
        tooltip = "Dropdown's tooltip text.",
        choices = {"table", "of", "choices"},
        getFunc = function() return "of" end,
        setFunc = function(var) print(var) end,
        width = "half",	--or "half" (optional)
        warning = "Will need to reload the UI.",	--(optional)
    },
    [5] = {
        type = "slider",
        name = "My Slider",
        tooltip = "Slider's tooltip text.",
        min = 0,
        max = 20,
        step = 1,	--(optional)
        getFunc = function() return 3 end,
        setFunc = function(value) d(value) end,
        width = "half",	--or "half" (optional)
        default = 5,	--(optional)
    },
    [6] = {
        type = "button",
        name = "My Button",
        tooltip = "Button's tooltip text.",
        func = function() d("button pressed!") end,
        width = "half",	--or "half" (optional)
        warning = "Will need to reload the UI.",	--(optional)
    },
    [7] = {
        type = "submenu",
        name = "Submenu Title",
        tooltip = "My submenu tooltip",	--(optional)
        controls = {
            [1] = {
                type = "checkbox",
                name = "My Checkbox",
                tooltip = "Checkbox's tooltip text.",
                getFunc = function() return true end,
                setFunc = function(value) d(value) end,
                width = "half",	--or "half" (optional)
                warning = "Will need to reload the UI.",	--(optional)
            },
            [2] = {
                type = "colorpicker",
                name = "My Color Picker",
                tooltip = "Color Picker's tooltip text.",
                getFunc = function() return 1, 0, 0, 1 end,	--(alpha is optional)
                setFunc = function(r,g,b,a) print(r, g, b, a) end,	--(alpha is optional)
                width = "half",	--or "half" (optional)
                warning = "warning text",
            },
            [3] = {
                type = "editbox",
                name = "My Editbox",
                tooltip = "Editbox's tooltip text.",
                getFunc = function() return "this is some text" end,
                setFunc = function(text) print(text) end,
                isMultiline = false,	--boolean
                width = "half",	--or "half" (optional)
                warning = "Will need to reload the UI.",	--(optional)
                default = "",	--(optional)
            },
        },
    },
    [8] = {
        type = "custom",
        reference = "MyAddonCustomControl",	--unique name for your control to use as reference
        refreshFunc = function(customControl) end,	--(optional) function to call when panel/controls refresh
        width = "half",	--or "half" (optional)
    },
    [9] = {
        type = "texture",
        image = "EsoUI\\Art\\ActionBar\\abilityframe64_up.dds",
        imageWidth = 64,	--max of 250 for half width, 510 for full
        imageHeight = 64,	--max of 100
        tooltip = "Image's tooltip text.",	--(optional)
        width = "half",	--or "half" (optional)
    },
}

NewAddon.AnimateText = function()
    -- Avoid playing the animation over itself.
    if not NewAddonActive:IsHidden() then return end

    -- Has an event ID number, so it's from the RegisterForUpdate.
    if e then
        EVENT_MANAGER:UnregisterForUpdate(NewAddon.name)
    end

    local animation, timeline = CreateSimpleAnimation(ANIMATION_ALPHA, NewAddonActive)

    NewAddonActive:SetHidden(false)
    animation:SetAlphaValues(NewAddonActive:GetAlpha(), 1)
    animation:SetDuration(3000)

    -- Fade-out after fade-in.
    timeline:SetHandler('OnStop', function()
        local animation, timeline = CreateSimpleAnimation(ANIMATION_ALPHA, NewAddonActive)

        animation:SetAlphaValues(NewAddonActive:GetAlpha(), 0)
        animation:SetDuration(3000)
    
        timeline:SetHandler('OnStop', function()
            NewAddonActive:SetHidden(true)
        end)

        timeline:PlayFromStart()
    end)

    timeline:PlayFromStart()
end

NewAddon.Activated = function(e)
    EVENT_MANAGER:UnregisterForEvent(NewAddon.name, EVENT_PLAYER_ACTIVATED)

    d(NewAddon.name .. GetString(SI_NEW_ADDON_MESSAGE)) -- Prints to chat.

    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, 
        NewAddon.name .. GetString(SI_NEW_ADDON_MESSAGE)) -- Top-right alert.

    -- Animate the xml UI center text, after a delay.
    EVENT_MANAGER:RegisterForUpdate(NewAddon.name, 3000, NewAddon.AnimateText)
end
-- When player is ready, after everything has been loaded.
EVENT_MANAGER:RegisterForEvent(NewAddon.name, EVENT_PLAYER_ACTIVATED, NewAddon.Activated)

NewAddon.OnAddOnLoaded = function(event, addonName)
    if addonName ~= NewAddon.name then return end
    EVENT_MANAGER:UnregisterForEvent(NewAddon.name, EVENT_ADD_ON_LOADED)

    -- Register addon panel after loading.
    LAM:RegisterAddonPanel(NewAddon.menuName, panelData)
    LAM:RegisterOptionControls(NewAddon.menuName, optionsTable)

    NewAddon.savedVariables = ZO_SavedVars:New("NewAddonSavedVariables", 1, nil, NewAddon.savedVariables)
    
    -- Slash commands must be lowercase. Set to nil to disable.
    SLASH_COMMANDS["/newaddon"] = NewAddon.AnimateText
    -- Reset autocomplete cache to update it.
    SLASH_COMMAND_AUTO_COMPLETE:InvalidateSlashCommandCache()
end
-- When any addon is loaded, but before UI (Chat) is loaded.
EVENT_MANAGER:RegisterForEvent(NewAddon.name, EVENT_ADD_ON_LOADED, NewAddon.OnAddOnLoaded)