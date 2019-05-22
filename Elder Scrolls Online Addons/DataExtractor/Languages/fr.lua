-- Every variable must start with this addon's unique ID, as each is a global.
local localization_strings = {
	SI_NEW_ADDON_MESSAGE = " c'est actif!",
	-- Keybindings.
	SI_BINDING_NAME_NEWADDON_DISPLAY = "Afficher le NewAddon",
}

for stringId, stringValue in pairs(localization_strings) do
	ZO_CreateStringId(stringId, stringValue)
	SafeAddVersion(stringId, 1)
end