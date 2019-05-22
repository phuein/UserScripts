-- Settings menu.
function ShowMount.LoadSettings()
    local LAM = LibStub("LibAddonMenu-2.0")

    local panelData = {
        type = "panel",
        name = ShowMount.menuName,
        displayName = ShowMount.Colorize(ShowMount.menuName),
        author = ShowMount.Colorize(ShowMount.author),
        slashCommand = "/sm",
        registerForRefresh = true,
    }
    LAM:RegisterAddonPanel(ShowMount.menuName, panelData)

    local optionsTable = {}

    -- Category. --
    -- table.insert(optionsTable, {
    --     type = "header",
    --     name = ZO_HIGHLIGHT_TEXT:Colorize("Options"),
    --     width = "full",	--or "half" (optional)
    -- })

    -- table.insert(optionsTable, {
    --     type = "description",
    --     -- title = "My Title",	--(optional)
    --     title = nil,	--(optional)
    --     text = "Set or reset your mount selection.",
    --     width = "full",	--or "half" (optional)
    -- })

    -- Mount selection category. --
    table.insert(optionsTable, {
        type = "header",
        name = ZO_HIGHLIGHT_TEXT:Colorize("Mount Selection"),
    })

    table.insert(optionsTable, {
        type = "dropdown",
        name = "Set Mount One",
        choices = ShowMount.mountsNamesMenu,
        getFunc = function()
            local i = ShowMount.GetIndex("mountsIds", ShowMount.savedVariables.MountOne)
            local name = ShowMount.mountsNames[i]
            return name or "-"
        end,
        setFunc = function(v)
            -- Reset.
            if v == "-" then ShowMount.ResetMounts("One") return end
            -- or Set.
            local i = ShowMount.GetIndex("mountsNames", v)
            local mount_id = ShowMount.mountsIds[i]
            ShowMount.SetMount("One", mount_id)
        end,
        width = "half",
        scrollable = true,
        sort = ShowMount.savedVariables.SortByName,
    })

    table.insert(optionsTable, {
        type = "dropdown",
        name = "Set Mount Two",
        choices = ShowMount.mountsNamesMenu,
        getFunc = function()
            local i = ShowMount.GetIndex("mountsIds", ShowMount.savedVariables.MountTwo)
            local name = ShowMount.mountsNames[i]
            return name or "-"
        end,
        setFunc = function(v)
            -- Reset.
            if v == "-" then ShowMount.ResetMounts("Two") return end
            -- or Set.
            local i = ShowMount.GetIndex("mountsNames", v)
            local mount_id = ShowMount.mountsIds[i]
            ShowMount.SetMount("Two", mount_id)
        end,
        width = "half",
        scrollable = true,
        sort = ShowMount.savedVariables.SortByName,
    })

    table.insert(optionsTable, {
        type = "dropdown",
        name = "Set Mount Three",
        choices = ShowMount.mountsNamesMenu,
        getFunc = function()
            local i = ShowMount.GetIndex("mountsIds", ShowMount.savedVariables.MountThree)
            local name = ShowMount.mountsNames[i]
            return name or "-"
        end,
        setFunc = function(v)
            -- Reset.
            if v == "-" then ShowMount.ResetMounts("Three") return end
            -- or Set.
            local i = ShowMount.GetIndex("mountsNames", v)
            local mount_id = ShowMount.mountsIds[i]
            ShowMount.SetMount("Three", mount_id)
        end,
        width = "half",
        scrollable = true,
        sort = ShowMount.savedVariables.SortByName,
    })

    table.insert(optionsTable, {
        type = "dropdown",
        name = "Set Mount Four",
        choices = ShowMount.mountsNamesMenu,
        getFunc = function()
            local i = ShowMount.GetIndex("mountsIds", ShowMount.savedVariables.MountFour)
            local name = ShowMount.mountsNames[i]
            return name or "-"
        end,
        setFunc = function(v)
            -- Reset.
            if v == "-" then ShowMount.ResetMounts("Four") return end
            -- or Set.
            local i = ShowMount.GetIndex("mountsNames", v)
            local mount_id = ShowMount.mountsIds[i]
            ShowMount.SetMount("Four", mount_id)
        end,
        width = "half",
        scrollable = true,
        sort = ShowMount.savedVariables.SortByName,
    })

    -- Other options category. --
    table.insert(optionsTable, {
        type = "header",
        name = ZO_HIGHLIGHT_TEXT:Colorize("Options"),
    })

    table.insert(optionsTable, {
        type = "checkbox",
        name = "Enable chat commands for mount activation.",
        tooltip = "/sm1 /sm2 /sm3 /sm4 /smr",
        getFunc = function() return ShowMount.savedVariables.EnableChatCmds end,
        setFunc = function(v)
            ShowMount.EnableChatCommands(v)
        end,
        width = "full",
    })

    table.insert(optionsTable, {
        type = "checkbox",
        name = "Sort mounts by name.",
        tooltip = "A to Z.",
        getFunc = function() return ShowMount.savedVariables.SortByName end,
        setFunc = function(v)
            if v then
                ShowMount.savedVariables.SortByName = "name-up"
            else
                ShowMount.savedVariables.SortByName = nil
            end
        end,
        width = "full",
        requiresReload = true,
    })

    table.insert(optionsTable, {
        type = "button",
        name = "Reset All Mounts",
        func = function() ShowMount.ResetMounts() end,
        width = "half",
    })

    -- table.insert(optionsTable, {
    --     type = "texture",
    --     image = "EsoUI\\Art\\ActionBar\\abilityframe64_up.dds",
    --     imageWidth = 64,	--max of 250 for half width, 510 for full
    --     imageHeight = 64,	--max of 100
    --     tooltip = "Image's tooltip text.",	--(optional)
    --     width = "half",	--or "half" (optional)
    -- })

    LAM:RegisterOptionControls(ShowMount.menuName, optionsTable)
end