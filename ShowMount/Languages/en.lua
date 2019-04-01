-- Every variable must start with this addon's unique ID, as each is a global.
local localization_strings = {
    -- Keybindings.
    -- SI_BINDING_NAME_SHOWMOUNT_TOGGLE    = "Toggle Active Mount",
    SI_BINDING_NAME_SHOWMOUNT_SMONE     = "Set Active Mount from Slot One",
    SI_BINDING_NAME_SHOWMOUNT_SMTWO     = "Set Active Mount from Slot Two",
    SI_BINDING_NAME_SHOWMOUNT_SMTHREE   = "Set Active Mount from Slot Three",
    SI_BINDING_NAME_SHOWMOUNT_SMFOUR    = "Set Active Mount from Slot Four",
    SI_BINDING_NAME_SHOWMOUNT_SMRANDOM  = "Set Active Mount from Random",
}

for stringId, stringValue in pairs(localization_strings) do
   ZO_CreateStringId(stringId, stringValue)
   SafeAddVersion(stringId, 1)
end