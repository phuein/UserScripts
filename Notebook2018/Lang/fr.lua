if NBUI == nil then NBUI = {} end

local localization_strings = {
		SI_NBUI_ADDON_NAME        = "Carnet",
		SI_NBUI_ADDONOPTIONS_NAME = "Options de Carnet",
		SI_NBUI_AUTHOR            = "Bloodspill & phuein",
		SI_NBUI_VERSION_NUM       = "|c00FF004.1|r",
			
		-- Settings Panel
		SI_NBUI_DESCRIPTION_INFO = "Un ordinateur portable virtuel.",
		
		SI_NBUI_HEADER_GENERAL = "Réglages Généraux",
		
		SI_NBUI_SHOWTITLE_LABEL   = "Afficher le titre",
		SI_NBUI_SHOWTITLE_TOOLTIP = "Affiche le titre du livre.",
		
		SI_NBUI_TITLE_LABEL   = "Titre De Livre",
		SI_NBUI_TITLE_TOOLTIP = "Change le titre du livre.",
		
		SI_NBUI_COLOR_LABEL   = "Color Book",
		SI_NBUI_COLOR_TOOLTIP = "Change la couleur du livre.",
		
		SI_NBUI_DIALOG         = "Dialogues de confirmation",
		SI_NBUI_DIALOG_TOOLTIP = "Active / désactive les boîtes de dialogue de confirmation.",
		
		SI_NBUI_LOCK_LABEL   = "Position Lock",
		SI_NBUI_LOCK_TOOLTIP = "Cela vous permet de sécuriser le portable en place afin qu'il ne peut pas être déplacé.",
		
		SI_NBUI_BUTTON_LABEL   = "Afficher Chat Button",
		SI_NBUI_BUTTON_TOOLTIP = "Ajoute un bouton dans la fenêtre de chat pour ouvrir / fermer le livre.",

		SI_NBUI_OFFSETMAX_LABEL   = "Décalage bouton de chat maximisée",
		SI_NBUI_OFFSETMAX_TOOLTIP = "Décalages le bouton dans la fenêtre de chat maximisée.",
		
		SI_NBUI_OFFSETMIN_LABEL   = "Décalage bouton de chat minimisé",
		SI_NBUI_OFFSETMIN_TOOLTIP = "Décalages le bouton dans la fenêtre de chat minimisé.",
		
		SI_NBUI_WARNING = "Ce paramètre doit être appliqué et se traduira par un écran de chargement.",
		
		-- UI Panel	
		SI_NBUI_CLOSEBUTTON_TOOLTIP = "Ferme le livre.",
		
		SI_NBUI_RUNBUTTON_TOOLTIP = "Exécutez cette page comme un script Lua.",

		SI_NBUI_DELETEBUTTON_TITLE    = "Supprimer la page",
		SI_NBUI_DELETEBUTTON_MAINTEXT = "Voulez-vous supprimer cette page?",
		SI_NBUI_DELETEBUTTON_TOOLTIP  = "Supprimer cette page.",
		
		SI_NBUI_NEWBUTTON_TITLE    = "Nouvelle Page",
		SI_NBUI_NEWBUTTON_MAINTEXT = "Voulez-vous créer une nouvelle page?",
		SI_NBUI_NEWBUTTON_TOOLTIP  = "Créer une nouvelle page.",
		
		SI_NBUI_SAVEBUTTON_TITLE    = "Enregistrer la page.",
		SI_NBUI_SAVEBUTTON_MAINTEXT = "Voulez-vous enregistrer les modifications apportées à la page?",
		SI_NBUI_SAVEBUTTON_TOOLTIP  = "Enregistrer les modifications apportées à cette page.",
		
		SI_NBUI_UNDOPAGE_TITLE     = "Annuler la page",
		SI_NBUI_UNDOPAGE_MAINTEXT  = "Voulez-vous annuler toutes les modifications apportées à cette page? Il reviendra à la dernière sauvegarde.",
		SI_NBUI_UNDOBUTTON_TOOLTIP = "Annuler les modifications apportées à cette page.",

		SI_NBUI_MOVEPAGEUPBUTTON_TOOLTIP = "Déplacez cette page dans l'index.",

		SI_NBUI_MOVEPAGEDOWNBUTTON_TOOLTIP = "Déplacez cette page dans l'index.",

		SI_NBUI_PREVIEWBUTTON_TOOLTIP = "Prévisualisez cette page en affichant les couleurs, le remplissage et les textures.",
		
		SI_NBUI_YES_LABEL = "Commandes:\n|c00FF00/nb|r bascule la fenêtre on/off.\n|c00FF00/nbs|r bascule les réglages on/off.",
		SI_NBUI_NO_LABEL  = "Oui",

		SI_NBUI_NB1INFORMATION_TOOLTIP = "Non",
		
		SI_NBUI_NB1KEYBIND_LABEL = "Carnet",
	}

for stringId, stringValue in pairs(localization_strings) do
   ZO_CreateStringId(stringId, stringValue)
   SafeAddVersion(stringId, 1)
end