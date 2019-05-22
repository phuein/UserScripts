--[[
    Scan for game data and save to savedvars, on demand.
    Data available: Skills, Item Sets, Furniture Items, Recipes.
    Uses layered callbacks to reduce CPU usage (freezes or crashes.)
--]]

DataExtractor = {
    name            = "DataExtractor",          -- Matches folder and Manifest file names.
    author          = "phuein",
    color           = "DDFFEE",                 -- Used in menu titles and so on.
    menuName        = "Data Extractor",         -- A UNIQUE identifier for menu object.
    -- Default settings.
    savedVariables = {
        FirstLoad = true,                       -- First time the addon is loaded ever.
        -- Scraping categories. TODO
        scrapeSkills = true,
        scrapeItems = true,
        -- Scraping sub-categories. TODO
        scrapeSets = true,
        scrapeFurniture = true,
        scrapeRecipes = true,
        -- Saved data. NOTE Content length may be long!
        dataSkills = {},
        dataItems = {
            Sets = {},
            Furniture = {},
            Recipes = {},
        },
    },
    -- Options.
    itemScanLimit   = 500000,                   -- How many itemIDs to scan through. NOTE Max is probably around 200k.
    -- Data.
    dataSkills      = {},                       -- ... skills.
    dataSets        = {},                       -- Holds references to all item sets.
    dataFurniture   = {},                       -- ... furniture.
    dataRecipes     = {},                       -- ... recipes.
    -- Counters.
    dataSkillLinesCounter = 0,
    dataSkillsCounter = 0,
    dataSetsCounter = 0,
    dataFurnitureCounter = 0,
    dataRecipesCounter = 0,
    -- Tracking.
    scrapingSkills = false,                     -- Avoid running a scraper more than once at a time.
    scrapingItems = false,
    -- Track skills async.
    currentType = nil,
    currentLine = nil,
    currentSkill = nil,
    -- Slash commands. Lowercase! Slash!
    slashSkills = '/scrapeskills',
    slashItems = '/scrapeitems',
    slashSave = '/scrapesave',
}

-- Wraps text with a color.
function DataExtractor.Colorize(text, color)
    -- Default to addon's .color.
    if not color then color = DataExtractor.color end

    text = string.format('|c%s%s|r', color, text)

    return text
end

-- Adds items to the database from given item id that applies to a link object.
-- i - (int) item id.
-- Returns true on success.
local function AddItemFromID(i)
    -- Textless link.
    -- 364, 50 for max lvl.
    -- 10000 for fully repaired. (2nd from last, might not be necessary.)
    local link = ZO_LinkHandler_CreateLink('', nil, ITEM_LINK_TYPE, i, 364, 50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

    local itemName = GetItemLinkName(link)

    -- No match, skip.
    if itemName == '' then return end

    -- Only matching for: Sets, Furniture, and Recipes.
    -- Vars will be used below!
    local hasSet, setName, setNumBonuses, setNumEquipped, setMaxEquipped, setID = GetItemLinkSetInfo(link)
    local itemType = GetItemLinkItemType(link)

    -- Format.
    itemName = zo_strformat(SI_TOOLTIP_ITEM_NAME, itemName)

    -- Sets.
    if hasSet then
        local data = DataExtractor.dataSets

        -- Set already listed.
        if data[setID] then return end

        data[setID] = {}
        local item = data[setID] -- Reference.

        item.id = setID
        item.name = setName

        -- Get bonuses info.
        for j = 1, setNumBonuses do
            local numRequired, bonusDescription = GetItemLinkSetBonusInfo(link, nil, j)
            item[j+1] = bonusDescription
        end

        DataExtractor.dataSetsCounter = DataExtractor.dataSetsCounter + 1

        return true
    end

    -- Furniture.
    if itemType == ITEMTYPE_FURNISHING then
        local data = DataExtractor.dataFurniture

        data[i] = {}
        local item = data[i] -- Reference.

        item.id = i
        item.name = itemName

        local quality = GetItemLinkQuality(link)
        quality = GetString("SI_ITEMQUALITY", quality)
        item.quality = quality

        local flavor = GetItemLinkFlavorText(link)
        if flavor ~= '' then
            item.description = flavor
        end

        -- Category.
        local dataId = GetItemLinkFurnitureDataId(link)
        local categoryId, subcategoryId = GetFurnitureDataCategoryInfo(dataId)
        item.category = GetFurnitureCategoryName(categoryId)

        -- Tags. "Furnishing Behavior".
        local numTags = GetItemLinkNumItemTags(link)
        local tagStrings = {}
        for j = 1, numTags do
            local tagDescription, tagCategory = GetItemLinkItemTagInfo(link, j)

            if tagDescription ~= '' then
                table.insert(tagStrings, zo_strformat(SI_TOOLTIP_ITEM_TAG_FORMATER, tagDescription))
            end
        end
        if #tagStrings > 0 then
            item.tags = table.concat(tagStrings, ', ')
        end

        DataExtractor.dataFurnitureCounter = DataExtractor.dataFurnitureCounter +1

        return true
    end

    -- Recipes.
    if itemType == ITEMTYPE_RECIPE then
        local data = DataExtractor.dataRecipes

        data[i] = {}
        local item = data[i] -- Reference.

        item.id = i
        item.name = itemName

        local quality = GetItemLinkQuality(link)
        quality = GetString("SI_ITEMQUALITY", quality)
        item.quality = quality

        local recipeType = GetItemLinkRecipeCraftingSkillType(link)
        recipeType = GetCraftingSkillName(recipeType)
        item.type = recipeType

        local recipeItemLink = GetItemLinkRecipeResultItemLink(link)
        local hasAbility, abilityHeader, abilityDescription, cooldown, hasScaling, minLevel, maxLevel, isChampionPoints, remainingCooldown = GetItemLinkOnUseAbilityInfo(recipeItemLink)
        if hasAbility then
            item.description = abilityDescription

            if hasScaling then
                local champ = ''
                if isChampionPoints then champ = 'cp' end
                item.scales = string.format('Scales from level %s%s to %s%s.', champ, minLevel, champ, maxLevel)
            end
        end

        -- Ingredients.
        local ingredients = {}
        local numIngredients = GetItemLinkRecipeNumIngredients(link)
        for j = 1, numIngredients do
            local ingredientName, numOwned, numRequired = GetItemLinkRecipeIngredientInfo(link, j)
            table.insert(ingredients, string.format('%s (%s)', ingredientName, numRequired))
        end
        item.ingredients = table.concat(ingredients, ', ')

        -- Skills required.
        skills = {}
        local numSkillsReq = GetItemLinkRecipeNumTradeskillRequirements(link)
        for j = 1, numSkillsReq do
            local skill, lvl = GetItemLinkRecipeTradeskillRequirement(link, j)

            local skillid = GetTradeskillLevelPassiveAbilityId(skill)
            local skillName = GetAbilityName(skillid)

            table.insert(skills, string.format('%s %s', skillName, lvl))
        end
        item.skills = table.concat(skills, ', ')

        DataExtractor.dataRecipesCounter = DataExtractor.dataRecipesCounter + 1

        return true
    end
end

-- Updates the callbacks to the next: skill, line, type, or done.
local function UpdateSkillsPosition(i, j, line, k, skillsLimit, linesLimit)
    -- Finished all skills for this line! Catches empty lines.
    if k == skillsLimit or k == -1 then
        -- Finished all skills of all lines of type! Next type. Catches empty types.
        if j == linesLimit or j == -1 then
            -- Finished all skills of all lines of all types! Complete.
            if i == SKILL_TYPE_MAX_VALUE then
                -- Print summary.
                d(
                    string.format(
                        '|cFFFFFFDataExtractor:|r Finished! Types: %s Lines: %s Skills: %s. (Use %s to save the data!)',
                        SKILL_TYPE_MAX_VALUE, DataExtractor.dataSkillLinesCounter, DataExtractor.dataSkillsCounter,
                        DataExtractor.slashSave
                    )
                )
                -- Update tracker.
                DataExtractor.scrapingSkills = false
            else
                -- d('finished type ' .. DataExtractor['currentType'])
                DataExtractor.currentType = DataExtractor.currentType + 1
            end
        else
            -- Next line.
            -- d('finished line ' .. DataExtractor['currentLine'])
            DataExtractor.currentLine = DataExtractor.currentLine + 1
        end
    else
        DataExtractor.currentSkill = DataExtractor.currentSkill + 1
    end
end

-- Get a skill.
local function AddSkill(i, j, line, k, skillsLimit, linesLimit)
    -- Delay until ready for call.
    if DataExtractor.currentSkill ~= k then
        -- Don't keep waiting if moved to next type or line.
        if DataExtractor.currentType == i and DataExtractor.currentLine == j then
            zo_callLater(function() AddSkill(i, j, line, k, skillsLimit, linesLimit) end, 50)
        end
        return
    end

    -- d('adding skill ' .. k)

    local skills = line.skills -- Reference
    skills[k] = {}
    local skill = skills[k] -- Reference

    -- Only skills with morphs have this.
    local pid = GetProgressionSkillProgressionId(i, j, k)

    if pid == 0 then
        -- No morphs, such as passive skills.
        local name, icon, earnedRank, passive, ultimate, purchased, progressionIndex, rank = GetSkillAbilityInfo(i, j, k)

        -- skill.icon = icon
        -- skill.earnedRank = earnedRank
        -- skill.passive = passive
        -- skill.ultimate = ultimate
        -- skill.purchased = purchased
        -- skill.progressionIndex = progressionIndex
        -- skill.rank = rank

        local abilityId = GetSkillAbilityId(i, j, k, false)

        skill.name = zo_strformat(SI_ABILITY_NAME, name)
        skill.id = abilityId
        skill.description = GetAbilityDescription(abilityId, MAX_RANKS_PER_ABILITY)
    else
        -- Skills with morphs. Ultimates and fighting skills.

        -- skill.index = string.format('%s, %s, %s', i, j, k)
        -- skill.ProgressionId = pid
        -- skill.ProgressionName  = GetProgressionSkillProgressionName(i, j, k)

        -- Base and two morphs: 0, 1, 2.
        for x = MORPH_SLOT_MIN_VALUE, MORPH_SLOT_MAX_VALUE do
            if x == MORPH_SLOT_MIN_VALUE then
                -- Base keeps data in skill table.
                s = skill
            else
                -- Morphs keep data in sub-tables.
                skill[x] = {}
                s = skill[x]
            end

            s.id = GetProgressionSkillMorphSlotAbilityId(pid, x)
            aid = s.id

            s.name = GetAbilityName(aid)
            s.description = GetAbilityDescription(aid, MAX_RANKS_PER_ABILITY)

            -- For morphs.
            if x > MORPH_SLOT_MIN_VALUE then
                s.parentAbilityId = skill.id
            end
        end
    end

    DataExtractor.dataSkillsCounter = DataExtractor.dataSkillsCounter + 1

    UpdateSkillsPosition(i, j, line, k, skillsLimit, linesLimit)
end

-- Get a skill line, and continue to get its skills.
local function AddLine(data, i, j, linesLimit)
    -- Delay until ready for call.
    if DataExtractor.currentLine ~= j then
        -- Don't keep waiting if moved to next type.
        if DataExtractor.currentType == i then
            zo_callLater(function() AddLine(data, i, j, linesLimit) end, 200)
        end
        return
    end

    -- d('adding line ' .. j)

    local name, rank, unlocked, notid, a, unlock, b, c = GetSkillLineInfo(i, j)

    data[j] = {}
    line = data[j] -- Reference.

    line.skills = {} -- Will hold all skills in line.

    line.name = name
    -- line.rank = rank
    -- line.unlocked = unlocked
    line.id = notid
    -- line.unlock = unlock
    -- line.a = a
    -- line.b = b
    -- line.c = b

    DataExtractor.dataSkillLinesCounter = DataExtractor.dataSkillLinesCounter + 1

    -- Get all skills for line.
    local skillsLimit = GetNumSkillAbilities(i, j)
    DataExtractor.currentSkill = 1

    -- No skills in line.
    if skillsLimit == 0 then
        -- Make it finish the iteration.
        UpdateSkillsPosition(i, j, line, -1)
        return
    end

    for k = 1, skillsLimit do
        AddSkill(i, j, line, k, skillsLimit, linesLimit)
    end
end

-- Get all skill lines for line type.
-- Continues to getting skills for each line.
local function AddType(i)
    -- Delay until ready for call.
    if DataExtractor.currentType ~= i then
        zo_callLater(function() AddType(i) end, 500)
        return
    end

    -- d('doing type ' .. i)

    local typeName = GetString("SI_SKILLTYPE", i)
    -- Empty type. Next!
    if typeName == '' then
        DataExtractor.currentType = DataExtractor.currentType + 1
        return
    end

    DataExtractor.dataSkills[i] = {}
    local data = DataExtractor.dataSkills[i]

    data.name = typeName

    -- Get me all skill lines for type.
    local linesLimit = GetNumSkillLines(i)
    local delay = 10
    DataExtractor.currentLine = 1

    -- No lines in type.
    if linesLimit == 0 then
        -- Make it finish the iteration.
        UpdateSkillsPosition(i, -1, nil, -1)
        return
    end

    for j = 1, linesLimit do
        AddLine(data, i, j, linesLimit)
    end
end

-- Scrapes all the skills in the game.
local function GetAllSkills()
    -- Don't run twice.
    if DataExtractor.scrapingSkills == true then
        d('|cFFFFFFDataExtractor:|r Skill scraper is already running!')
        return
    end
    -- Track.
    DataExtractor.scrapingSkills = true

    d('|cFFFFFFDataExtractor:|r Gathering skills data, please wait...')

    -- Gets all types. Each type gets all lines. Each line gets all skills.
    DataExtractor.currentType = SKILL_TYPE_MIN_VALUE
    for i = SKILL_TYPE_MIN_VALUE, SKILL_TYPE_MAX_VALUE do
        AddType(i)
    end
end

-- Scrapes all the items in the game.
local function GetAllItems()
    -- Don't run twice.
    if DataExtractor.scrapingItems == true then
        d('|cFFFFFFDataExtractor:|r Item scraper is already running!')
        return
    end
    -- Track.
    DataExtractor.scrapingItems = true

    -- Iterate over all items in-game.
    local limit = DataExtractor.itemScanLimit

    local chunk = 100               -- Split the load to avoid crashing the game.
    local chunks = limit / chunk    -- How many chunks to process.
    local delay = 50                -- ms delay between chunks.

    local addedDelay = 0
    for t = 1, chunks do
        zo_callLater(function()
            local x = 1 + (chunk * (t-1))   -- Start.
            local y = chunk * t             -- End.

            for i = x, y do
                AddItemFromID(i)
            end

            -- FINISHED. Last chunk prints summary.
            if t == chunks then
                d(
                    string.format(
                        '|cFFFFFFDataExtractor:|r Finished! Total IDs: %s Sets: %s Furniture: %s Recipes: %s. (Use %s to save the data!)',
                        limit, DataExtractor.dataSetsCounter, DataExtractor.dataFurnitureCounter, DataExtractor.dataRecipesCounter,
                        DataExtractor.slashSave
                    )
                )
                -- Update tracker.
                DataExtractor.scrapingItems = false
            end
        end, delay * t)
    end

    d(string.format('|cFFFFFFDataExtractor:|r Gathering item data, please wait for %s seconds...', math.floor((chunks * delay) / 1000)))
end

-- Saved the scraped data from all tables into savedvars,
-- and commits a /reloadui to force save to file.
local function SaveData()
    -- Update savedvars.
    DataExtractor.savedVariables.dataSkills = DataExtractor.dataSkills

    DataExtractor.savedVariables.dataItems.Sets = DataExtractor.dataSets
    DataExtractor.savedVariables.dataItems.Furniture = DataExtractor.dataFurniture
    DataExtractor.savedVariables.dataItems.Recipes = DataExtractor.dataRecipes

    ReloadUI("ingame")
end

-- Only show the loading message on first load ever.
function DataExtractor.Activated(e)
    EVENT_MANAGER:UnregisterForEvent(DataExtractor.name, EVENT_PLAYER_ACTIVATED)

    if DataExtractor.savedVariables.FirstLoad then
        DataExtractor.savedVariables.FirstLoad = false
    end
end
-- When player is ready, after everything has been loaded.
EVENT_MANAGER:RegisterForEvent(DataExtractor.name, EVENT_PLAYER_ACTIVATED, DataExtractor.Activated)

function DataExtractor.OnAddOnLoaded(event, addonName)
    if addonName ~= DataExtractor.name then return end
    EVENT_MANAGER:UnregisterForEvent(DataExtractor.name, EVENT_ADD_ON_LOADED)

    DataExtractor.savedVariables = ZO_SavedVars:NewAccountWide("DataExtractorSavedVariables", 1, nil, DataExtractor.savedVariables)

    -- Settings menu in Settings.lua. TODO
    -- DataExtractor.LoadSettings()

    SLASH_COMMANDS[DataExtractor.slashSkills] = GetAllSkills
    SLASH_COMMANDS[DataExtractor.slashItems] = GetAllItems
    SLASH_COMMANDS[DataExtractor.slashSave] = SaveData

    -- Reset autocomplete cache to update it.
    SLASH_COMMAND_AUTO_COMPLETE:InvalidateSlashCommandCache()
end
-- When any addon is loaded, but before UI (Chat) is loaded.
EVENT_MANAGER:RegisterForEvent(DataExtractor.name, EVENT_ADD_ON_LOADED, DataExtractor.OnAddOnLoaded)