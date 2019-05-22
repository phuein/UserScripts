Junkee = Junkee or {}
Junkee.localizations = {
	en = {
		JunkBindingName = "Junk current item",
		DeleteBindingName = "Destroy current item",
		LinkBindingName = "Link in Chat current item",
		LockBindingName = "Un/Lock current item",
		VisibleBindingName = "Show bindings in Inventory",
		JunkLabel = "Junk",
		UnjunkLabel = "UnJunk",
		LinkLabel = "Link",
		LockLabel = "Lock",
		DeleteLabel = "Destroy"
	},
	de = {
		JunkBindingName = "Aktuellen Gegenstand als Trödel markieren",
		DeleteBindingName = "Aktuellen Gegenstand zerstören",
		LinkBindingName = "Link im Chat aktuelles element",
		LockBindingName = "Un / Sperrt das aktuelle objekt",
		VisibleBindingName = "Bindungen in Inventar anzeigen",
		JunkLabel = "Als Trödel markieren",
		UnjunkLabel = "Nicht als Trödel markieren",
		LinkLabel = "Link",
		LockLabel = "Sperren",
		DeleteLabel = "Zerstören"
	},
	fr = {
		JunkBindingName = "Mette aux rebuts",
		DeleteBindingName = "Détruire",
		LinkBindingName = "Lien dans Chat article en cours",
		LockBindingName = "Un / Verrouiller l'élément actuel",
		VisibleBindingName = "Afficher les liaisons dans l'inventaire",
		JunkLabel = "Mette aux rebuts",
		UnjunkLabel = "Ne mette pas aux rebuts",
		LinkLabel = "Lien",
		LockLabel = "Fermer à clé",
		DeleteLabel = "Détruire"
	},
	ru = {
		JunkBindingName = "Отметить как хлам",
		DeleteBindingName = "Уничтожить указанный предмет",
		LinkBindingName = "Ссылка в текущем элементе чата",
		LockBindingName = "Заблокировать текущий элемент",
		VisibleBindingName = "Показать привязки в инвентаре",
		JunkLabel = "Хлам",
		UnjunkLabel = "Не хлам",
		LinkLabel = "Ссылка",
		LockLabel = "Замок",
		DeleteLabel = "Уничтожить"
	},
}

Junkee.language = GetCVar("language.2") or "en"
Junkee.tr = function(str)
	return Junkee.localizations[Junkee.language][str]
end
