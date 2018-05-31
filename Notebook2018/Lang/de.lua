if NBUI == nil then NBUI = {} end

local localization_strings = {
		SI_NBUI_ADDON_NAME        = "Notizbuch",
		SI_NBUI_ADDONOPTIONS_NAME = "Notizbuchoptionen",
		SI_NBUI_AUTHOR            = "Bloodspill & phuein",
		SI_NBUI_VERSION_NUM       = "|c00FF004.1|r",
			
		-- Settings Panel
		SI_NBUI_DESCRIPTION_INFO = "Ein Virtuelles Notizbuch.",
		
		SI_NBUI_HEADER_GENERAL = "Allgemeine Einstellungen",
		
		SI_NBUI_SHOWTITLE_LABEL 	= "Titel anzeigen",
		SI_NBUI_SHOWTITLE_TOOLTIP 	= "Zeigt den Titel des Buches.",		
		
		SI_NBUI_TITLE_LABEL 	= "Buchtitel",		
		SI_NBUI_TITLE_TOOLTIP 	= "Ändert den Titel des buchs.",
		
		SI_NBUI_COLOR_LABEL 	= "buchen Farbe",
		SI_NBUI_COLOR_TOOLTIP 	= "Ändert die Farbe des Buchs.",
		
		SI_NBUI_DIALOG 			= "Bestätigungsdialoge",
		SI_NBUI_DIALOG_TOOLTIP 	= "Ein-/Ausschalten Bestätigungsdialoge",
		
		SI_NBUI_LOCK_LABEL 		= "Position sperren",
		SI_NBUI_LOCK_TOOLTIP 	= "Das ermöglicht es dir, das Notizbuch an Stelle zu fixieren, damit es nicht verschoben werden kann.",	
		
		SI_NBUI_BUTTON_LABEL 	= "Chat Button einblenden",
		SI_NBUI_BUTTON_TOOLTIP 	= "Fügt eine Schaltfläche im Chat-Fenster zu öffnen/schließen du das Buch.",
		
		SI_NBUI_OFFSETMAX_LABEL   = "Offset Maximierte Chat Button",
		SI_NBUI_OFFSETMAX_TOOLTIP = "Offsets die Schaltfläche in der maximierten Chat-Fenster.",
		
		SI_NBUI_OFFSETMIN_LABEL 	= "Offset Minimierte Chat Button",
		SI_NBUI_OFFSETMIN_TOOLTIP 	= "Offsets die Schaltfläche in der minimiert Chat-Fenster.",		
		
		SI_NBUI_WARNING = "Das Setzen dieser Einstellung führt zu einem Ladebildschirm.",		
		
		-- UI Panel	
		SI_NBUI_CLOSEBUTTON_TOOLTIP = "Schliesse das Buch.",
		
		SI_NBUI_RUNBUTTON_TOOLTIP = "Führen du diese Seite als Lua-Script.",		

		SI_NBUI_DELETEBUTTON_TITLE    = "Seite löschen",
		SI_NBUI_DELETEBUTTON_MAINTEXT = "Wollen du, um diese Seite zu löschen?",
		SI_NBUI_DELETEBUTTON_TOOLTIP  = "Löschen du diese Seite.",
		
		SI_NBUI_NEWBUTTON_TITLE    = "Neue Seite",
		SI_NBUI_NEWBUTTON_MAINTEXT = "Wollen du eine neue Seite erstellen?",
		SI_NBUI_NEWBUTTON_TOOLTIP  = "Erstellen du eine neue Seite.",
		
		SI_NBUI_SAVEBUTTON_TITLE    = "Seite speichern",
		SI_NBUI_SAVEBUTTON_MAINTEXT = "Wollen du Änderungen an der Seite zu speichern?",
		SI_NBUI_SAVEBUTTON_TOOLTIP  = "Speichern du die Änderungen auf dieser Seite gemacht.",
		
		SI_NBUI_UNDOPAGE_TITLE     = "Undo Seite",
		SI_NBUI_UNDOPAGE_MAINTEXT  = "Möchten du alle Änderungen an dieser Seite rückgängig zu machen? Es wird zurück zum letzten zu speichern.",
		SI_NBUI_UNDOBUTTON_TOOLTIP = "Rückgängig Änderungen an dieser Seite gemacht.",

		SI_NBUI_MOVEPAGEUPBUTTON_TOOLTIP = "Verschieben Sie diese Seite im Index nach oben.",

		SI_NBUI_MOVEPAGEDOWNBUTTON_TOOLTIP = "Verschieben Sie diese Seite im Index nach unten.",

		SI_NBUI_PREVIEWBUTTON_TOOLTIP = "Vorschau dieser Seite durch Rendern von Farben, Auffüllen und Texturen.",
		
		SI_NBUI_YES_LABEL = "Befehle:\n|c00FF00/nb|r schaltet das Fenster ein/aus.\n|c00FF00/nbs|r schaltet die Einstellungen ein/aus.",
		SI_NBUI_NO_LABEL  = "Ja",

		SI_NBUI_NB1INFORMATION_TOOLTIP = "Nein",
		
		SI_NBUI_NB1KEYBIND_LABEL = "Notizbuch",
	}

for stringId, stringValue in pairs(localization_strings) do
   ZO_CreateStringId(stringId, stringValue)
   SafeAddVersion(stringId, 1)
end