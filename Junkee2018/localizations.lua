Junkee = Junkee or {}
Junkee.localizations = {
	en = {
		JunkBindingName = "Junk current item",
		DeleteBindingName = "Destroy current item",
		LinkBindingName = "Link in Chat current item",
		VisibleBindingName = "Show bindings in Inventory",
		JunkLabel = "Junk",
		UnjunkLabel = "UnJunk",
		LinkLabel = "Link",
		DeleteLabel = "Destroy"
	},
	de = {
		JunkBindingName = "Aktuellen Gegenstand als Trödel markieren",
		DeleteBindingName = "Aktuellen Gegenstand zerstören",
		VisibleBindingName = "Bindungen in Inventar anzeigen",
		JunkLabel = "Als Trödel markieren",
		UnjunkLabel = "Nicht als Trödel markieren",
		DeleteLabel = "Zerstören"
	},
	fr = {
		JunkBindingName = "Mette aux rebuts",
		DeleteBindingName = "Détruire",
		VisibleBindingName = "Afficher les liaisons dans l'inventaire",
		JunkLabel = "Mette aux rebuts",
		UnjunkLabel = "Ne mette pas aux rebuts",
		DeleteLabel = "Détruire"
	},
	ru = {
		JunkBindingName = "Отметить как хлам",
		DeleteBindingName = "Уничтожить указанный предмет",
		JunkLabel = "Хлам",
		UnjunkLabel = "Не хлам",
		DeleteLabel = "Уничтожить"
	},
}

Junkee.language = GetCVar("language.2") or "en"
Junkee.tr = function(str)
	return Junkee.localizations[Junkee.language][str]
end
