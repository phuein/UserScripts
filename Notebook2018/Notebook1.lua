if NBUI == nil then NBUI = {} end

local buttonCount = 1
local savedVarsStringMax = 1900

---------------------------------------------------------------------------------------------------
function Set_Button_TextColors(button)
	-- Tinker with text color from settings.
	local color = {unpack(NBUI.db.NB1_TextColor)};
	
	color[4] = 0.6
	button:SetMouseOverFontColor(unpack(color))
	
	color[4] = 0.7
	button:SetNormalFontColor(unpack(color))
	
	color[4] = 0.8
	button:SetPressedFontColor(unpack(color))
end

function Create_NB1_IndexButton(NB1_IndexPool)
	local button = WINDOW_MANAGER:CreateControlFromVirtual("NB1_Index" .. NB1_IndexPool:GetNextControlId(), NBUI.NB1LeftPage_ScrollContainer.scrollChild, "ZO_DefaultTextButton")
	local anchorBtn = buttonCount == 1 and NBUI.NB1LeftPage_ScrollContainer.scrollChild or NB1_IndexPool:AcquireObject(buttonCount-1)
		button:SetAnchor(TOPLEFT, anchorBtn, buttonCount == 1 and TOPLEFT or BOTTOMLEFT)
		button:SetClickSound(SOUNDS.BOOK_PAGE_TURN)
		button:SetFont("ZoFontBookPaper")
		button:SetHandler("OnClicked", function(self)
			currentlyViewing = self.id
			
			NBUI.NB1RightPage_Title:SetHidden(false)
			NBUI.NB1RightPage_ScrollContainer:SetHidden(false)
			
			-- Bug with unsaved variables from game.
			local title = self.data.title
			if title == nil then
				title = ""
			end
			NBUI.NB1RightPage_Title:SetText(UnprotectText(title))
			NBUI.NB1RightPage_Title:SetCursorPosition(0)
			
			-- Bug with unsaved variables from game.
			local text = self.data.text
			if text == nil then
				text = ""
			end
			NBUI.NB1RightPage_Contents:SetText(UnprotectText(text))
			NBUI.NB1RightPage_Contents:SetCursorPosition(0)
			
			NBUI.NB1SelectedPage_Button:ClearAnchors()
			NBUI.NB1SelectedPage_Button:SetAnchorFill(self)
			-- hides these buttons
			NBUI.NB1SavePage_Button:SetHidden(true)
			NBUI.NB1UndoPage_Button:SetHidden(true)
			-- shows these buttons
			-- NBUI.NB1RunScript_Button:SetHidden(false)
			NBUI.NB1SelectedPage_Button:SetHidden(false)
			NBUI.NB1DeletePage_Button:SetHidden(false)
			NBUI.NB1MovePageUp_Button:SetHidden(false)
			NBUI.NB1MovePageDown_Button:SetHidden(false)
			NBUI.NBUI_NB1RightPage_CharacterCounter:SetHidden(true)
		end)
		button:SetWidth(400)
		button:SetHorizontalAlignment(TEXT_ALIGN_LEFT)
		Set_Button_TextColors(button)
		
	buttonCount = buttonCount + 1
	return button
end
---------------------------------------------------------------------------------------------------
function Populate_NB1_ScrollList()
	local numPages = #NBUI.db.NB1Pages
	for i = 1, numPages do
		local button = NB1_IndexPool:AcquireObject(i)
		button.data = NBUI.db.NB1Pages[i]
		button.id = i
		button:SetText(UnprotectText(button.data.title))
		button:SetHidden(false)
		Set_Button_TextColors(button)
	end
	local activePages = NB1_IndexPool:GetActiveObjectCount()
	if activePages > numPages then
		for i = numPages+1, activePages do
			NB1_IndexPool:ReleaseObject(i)
		end
	end
end
---------------------------------------------------------------------------------------------------
function Remove_NB1_IndexButton(button)
	button:SetHidden(true)
end
---------------------------------------------------------------------------------------------------
--  Interface  --
---------------------------------------------------------------------------------------------------
function CreateNB1()
	-- To let elements tweak text alpha.
	local color = {unpack(NBUI.db.NB1_TextColor)};
---------------------------------------------------------------------------------------------------
	NBUI.NB1MainWindow = WINDOW_MANAGER:CreateTopLevelWindow("NBUI_NB1MainWindow")
		SCENE_MANAGER:RegisterTopLevel(NBUI.NB1MainWindow, false)	
		NBUI.NB1MainWindow:AllowBringToTop(true)
		NBUI.NB1MainWindow:SetAnchor(NBUI.db.NB1_Anchor.a, GuiRoot, NBUI.db.NB1_Anchor.b, NBUI.db.NB1_Anchor.x, NBUI.db.NB1_Anchor.y)
		NBUI.NB1MainWindow:SetClampedToScreen(true)		
		NBUI.NB1MainWindow:SetDimensions(1004, 752)
		NBUI.NB1MainWindow:SetDrawLayer(0)		
		NBUI.NB1MainWindow:SetDrawLevel(0) 
		NBUI.NB1MainWindow:SetDrawTier(0) 
		NBUI.NB1MainWindow:SetHandler("OnMoveStop", function(self)
			local _,a,_,b,x,y = self:GetAnchor()
			NBUI.db.anchor = {["a"]=a, ["b"]=b, ["x"]=x, ["y"]=y}
		end)		
		NBUI.NB1MainWindow:SetHandler("OnReceiveDrag", function(self)
			self:StartMoving()
		end)		
		NBUI.NB1MainWindow:SetHidden(true)		
		NBUI.NB1MainWindow:SetMouseEnabled(true)	
 		NBUI.NB1MainWindow:SetMovable(not NBUI.db.NB1_Locked)
 		-- Add fragment to scene, like other UI elements.
 		-- local fragment = ZO_HUDFadeSceneFragment:New(NBUI.NB1MainWindow)
 		-- Add to scenes.
 		-- HUD_SCENE:AddFragment(fragment)
 		-- HUD_UI_SCENE:AddFragment(fragment)
---------------------------------------------------------------------------------------------------	
	NBUI.NB1MainWindow_Cover = WINDOW_MANAGER:CreateControl("NBUI_NB1MainWindow_Cover", NBUI.NB1MainWindow, CT_TEXTURE)
		NBUI.NB1MainWindow_Cover:SetAnchor(TOPLEFT, NBUI.NB1MainWindow, TOPLEFT, -10, -126)
		NBUI.NB1MainWindow_Cover:SetAnchor(BOTTOMRIGHT, NBUI.NB1MainWindow, BOTTOMRIGHT, 10, 146)		
		NBUI.NB1MainWindow_Cover:SetDimensions(1024, 1024)
		NBUI.NB1MainWindow_Cover:SetTexture("/esoui/art/lorelibrary/lorelibrary_paperbook.dds")
		NBUI.NB1MainWindow_Cover:SetColor(unpack(NBUI.db.NB1_BookColor))
		NBUI.NB1MainWindow_Cover:SetAlpha(1)
--***********************************************************************************************--		
--  LEFT PAGE  ------------------------------------------------------------------------------------
	NBUI.NB1LeftPage_TitleBackdrop = WINDOW_MANAGER:CreateControlFromVirtual("NBUI_NB1LeftPage_TitleBackdrop", NBUI.NB1MainWindow, "ZO_EditBackdrop")
		NBUI.NB1LeftPage_TitleBackdrop:SetAnchor(TOPLEFT, NBUI.NB1MainWindow_Cover, TOPLEFT, 85, 160)		
		NBUI.NB1LeftPage_TitleBackdrop:SetCenterColor(0, 0, 0, 0)		
		NBUI.NB1LeftPage_TitleBackdrop:SetDimensions(420, 45)
		NBUI.NB1LeftPage_TitleBackdrop:SetDrawLayer(0)		
		NBUI.NB1LeftPage_TitleBackdrop:SetDrawLevel(1)
		NBUI.NB1LeftPage_TitleBackdrop:SetDrawTier(0)		
		NBUI.NB1LeftPage_TitleBackdrop:SetEdgeColor(0, 0, 0, 0)
		NBUI.NB1LeftPage_TitleBackdrop:SetHidden(not NBUI.db.NB1_ShowTitle)	
---------------------------------------------------------------------------------------------------	
	NBUI.NB1LeftPage_Title = WINDOW_MANAGER:CreateControl("NBUI_NB1LeftPage_Title", NBUI.NB1MainWindow, CT_LABEL)
		NBUI.NB1LeftPage_Title:SetAnchor(CENTER, NBUI.NB1LeftPage_TitleBackdrop, CENTER, 0, 0)
		NBUI.NB1LeftPage_Title:SetColor(unpack(NBUI.db.NB1_TextColor))
		NBUI.NB1LeftPage_Title:SetDrawLayer(0)		
		NBUI.NB1LeftPage_Title:SetDrawLevel(2)
		NBUI.NB1LeftPage_Title:SetDrawTier(0) 			
		NBUI.NB1LeftPage_Title:SetFont("ZoFontBookPaperTitle")
		NBUI.NB1LeftPage_Title:SetHidden(not NBUI.db.NB1_ShowTitle)		
		NBUI.NB1LeftPage_Title:SetText(NBUI.db.NB1_Title)
---------------------------------------------------------------------------------------------------
	NBUI.NB1Information_Button = WINDOW_MANAGER:CreateControl("NBUI_NB1Information_Button", NBUI.NB1MainWindow, CT_BUTTON)
		NBUI.NB1Information_Button:SetAnchor(CENTER, NBUI.NB1LeftPage_TitleBackdrop, RIGHT, -30, 0)		
		NBUI.NB1Information_Button:SetDimensions(32, 32)
		NBUI.NB1Information_Button:SetDrawLayer(1)		
		NBUI.NB1Information_Button:SetDrawLevel(1)
		NBUI.NB1Information_Button:SetDrawTier(0)		
		NBUI.NB1Information_Button:SetHandler("OnClicked", function(self)
			InitializeTooltip(InformationTooltip, self, TOPLEFT, 0, 0, BOTTOMRIGHT)
			SetTooltipText(InformationTooltip, GetString(SI_NBUI_NB1INFORMATION_TOOLTIP))
		end)
		NBUI.NB1Information_Button:SetHandler("OnMouseExit", function(self)
			ClearTooltip(InformationTooltip)
		end)
		NBUI.NB1Information_Button:SetHidden(not NBUI.db.NB1_ShowTitle)		
		NBUI.NB1Information_Button:SetMouseOverTexture("/esoui/art/buttons/info_over.dds")
		NBUI.NB1Information_Button:SetNormalTexture("/esoui/art/buttons/info_up.dds")
		NBUI.NB1Information_Button:SetPressedTexture("/esoui/art/buttons/info_down.dds")
---------------------------------------------------------------------------------------------------		
	NBUI.NB1LeftPage_Separator = WINDOW_MANAGER:CreateControl("NBUI_NB1LeftPage_Separator", NBUI.NB1MainWindow, CT_TEXTURE)		
		NBUI.NB1LeftPage_Separator:SetAnchor(CENTER, NBUI.NB1LeftPage_TitleBackdrop, BOTTOM, 0, 0)		
		NBUI.NB1LeftPage_Separator:SetColor(unpack(NBUI.db.NB1_TextColor))
		NBUI.NB1LeftPage_Separator:SetDimensions(420, 2)
		NBUI.NB1LeftPage_Separator:SetDrawLayer(1)		
		NBUI.NB1LeftPage_Separator:SetDrawLevel(1)
		NBUI.NB1LeftPage_Separator:SetDrawTier(0)		
		NBUI.NB1LeftPage_Separator:SetHidden(not NBUI.db.NB1_ShowTitle)
		NBUI.NB1LeftPage_Separator:SetTexture("/esoui/art/interaction/conversation_divider.dds")	
---------------------------------------------------------------------------------------------------
	NBUI.NB1LeftPage_Backdrop = WINDOW_MANAGER:CreateControlFromVirtual("NBUI_NB1LeftPage_Backdrop", NBUI.NB1MainWindow, "ZO_EditBackdrop")
		NBUI.NB1LeftPage_Backdrop:SetAnchor(BOTTOMLEFT, NBUI.NB1MainWindow_Cover, BOTTOMLEFT, 85, -164)		
		NBUI.NB1LeftPage_Backdrop:SetCenterColor(0, 0, 0, 0)
			if (NBUI.db.NB1_ShowTitle) then
				NBUI.NB1LeftPage_Backdrop:SetDimensions(420, 645)
			else
				NBUI.NB1LeftPage_Backdrop:SetDimensions(420, 690)
			end	
		NBUI.NB1LeftPage_Backdrop:SetDrawLayer(0)		
		NBUI.NB1LeftPage_Backdrop:SetDrawLevel(1)
		NBUI.NB1LeftPage_Backdrop:SetDrawTier(0)		
		NBUI.NB1LeftPage_Backdrop:SetEdgeColor(0, 0, 0, 0)		
---------------------------------------------------------------------------------------------------
	NBUI.NB1LeftPage_ScrollContainer = WINDOW_MANAGER:CreateControlFromVirtual("NBUI_NB1LeftPage_ScrollContainer", NBUI.NB1MainWindow, "ZO_ScrollContainer")
		NBUI.NB1LeftPage_ScrollContainer.scrollChild = NBUI.NB1LeftPage_ScrollContainer:GetNamedChild("ScrollChild")		
		NBUI.NB1LeftPage_ScrollContainer:SetAnchorFill(NBUI.NB1LeftPage_Backdrop)
		NBUI.NB1LeftPage_ScrollContainer:SetDrawLayer(0)	
		NBUI.NB1LeftPage_ScrollContainer:SetDrawLevel(2)
		NBUI.NB1LeftPage_ScrollContainer:SetDrawTier(0)
---------------------------------------------------------------------------------------------------	  
	NBUI.NB1SelectedPage_Button = WINDOW_MANAGER:CreateControl(nil, NBUI.NB1LeftPage_ScrollContainer.scrollChild, CT_TEXTURE)
		NBUI.NB1SelectedPage_Button:SetAlpha(.45)		
		NBUI.NB1SelectedPage_Button:SetDrawLayer(0)		
		NBUI.NB1SelectedPage_Button:SetDrawLevel(3) 
		NBUI.NB1SelectedPage_Button:SetDrawTier(0) 	
		NBUI.NB1SelectedPage_Button:SetHidden(true)
		NBUI.NB1SelectedPage_Button:SetTexture("esoui/art/buttons/generic_highlight.dds")
		NBUI.NB1SelectedPage_Button:SetWidth(420)
---------------------------------------------------------------------------------------------------		
	NBUI.NB1SavePage_Button = WINDOW_MANAGER:CreateControl("NBUI_NB1SavePage_Button", NBUI.NB1LeftPage_ScrollContainer.scrollChild, CT_BUTTON)
		NBUI.NB1SavePage_Button:SetAnchor(RIGHT, NBUI.NB1SelectedPage_Button, RIGHT, -60, -2) 		
		NBUI.NB1SavePage_Button:SetClickSound(SOUNDS.BOOK_PAGE_TURN)
		NBUI.NB1SavePage_Button:SetDimensions(30, 30)
		NBUI.NB1SavePage_Button:SetDrawLayer(1)		
		NBUI.NB1SavePage_Button:SetDrawLevel(1)
		NBUI.NB1SavePage_Button:SetDrawTier(0)	
		NBUI.NB1SavePage_Button:SetHandler("OnClicked", function(self)
			if (NBUI.db.NB1_ShowDialog) then
				ZO_Dialogs_ShowDialog("NBUI_NB1CONFIRM_SAVE")
			else
				NBUI.NB1SavePage(self)
			end			
		end)
		NBUI.NB1SavePage_Button:SetHandler("OnMouseEnter", function(self)
			InitializeTooltip(InformationTooltip, self, TOPLEFT, 0, 0, BOTTOMRIGHT)
			SetTooltipText(InformationTooltip, GetString(SI_NBUI_SAVEBUTTON_TOOLTIP))
		end)
		NBUI.NB1SavePage_Button:SetHandler("OnMouseExit", function(self)
			ClearTooltip(InformationTooltip)
		end)
		NBUI.NB1SavePage_Button:SetHidden(true)		
		NBUI.NB1SavePage_Button:SetMouseOverTexture("/esoui/art/buttons/edit_save_over.dds")
		NBUI.NB1SavePage_Button:SetNormalTexture("/esoui/art/buttons/edit_save_up.dds")
		NBUI.NB1SavePage_Button:SetPressedTexture("/esoui/art/buttons/edit_save_down.dds")	
---------------------------------------------------------------------------------------------------		
	NBUI.NB1MovePageUp_Button = WINDOW_MANAGER:CreateControl("NBUI_NB1MovePageUp_Button", NBUI.NB1LeftPage_ScrollContainer.scrollChild, CT_BUTTON)
		NBUI.NB1MovePageUp_Button:SetAnchor(RIGHT, NBUI.NB1SelectedPage_Button, RIGHT, -126, 0) 		
		NBUI.NB1MovePageUp_Button:SetClickSound(SOUNDS.BOOK_PAGE_TURN)
		NBUI.NB1MovePageUp_Button:SetDimensions(20, 20)
		NBUI.NB1MovePageUp_Button:SetDrawLayer(1)		
		NBUI.NB1MovePageUp_Button:SetDrawLevel(1)
		NBUI.NB1MovePageUp_Button:SetDrawTier(0)	
		NBUI.NB1MovePageUp_Button:SetHandler("OnClicked", function(self)
			-- if (NBUI.db.NB1_ShowDialog) then
			-- 	ZO_Dialogs_ShowDialog("NBUI_NB1CONFIRM_MOVEPAGEUP")
			-- else
				NBUI.NB1MovePageUp(self)
			-- end
		end)
		NBUI.NB1MovePageUp_Button:SetHandler("OnMouseEnter", function(self)
			InitializeTooltip(InformationTooltip, self, TOPLEFT, 0, 0, BOTTOMRIGHT)
			SetTooltipText(InformationTooltip, GetString(SI_NBUI_MOVEPAGEUPBUTTON_TOOLTIP))
		end)
		NBUI.NB1MovePageUp_Button:SetHandler("OnMouseExit", function(self)
			ClearTooltip(InformationTooltip)
		end)
		NBUI.NB1MovePageUp_Button:SetHidden(true)		
		NBUI.NB1MovePageUp_Button:SetMouseOverTexture("esoui/art/buttons/gamepad/gp_uparrow.dds")
		NBUI.NB1MovePageUp_Button:SetNormalTexture("esoui/art/buttons/gamepad/gp_uparrow.dds")
		NBUI.NB1MovePageUp_Button:SetPressedTexture("esoui/art/buttons/gamepad/gp_uparrow.dds")	
---------------------------------------------------------------------------------------------------		
	NBUI.NB1MovePageDown_Button = WINDOW_MANAGER:CreateControl("NBUI_NB1MovePageDown_Button", NBUI.NB1LeftPage_ScrollContainer.scrollChild, CT_BUTTON)
		NBUI.NB1MovePageDown_Button:SetAnchor(RIGHT, NBUI.NB1SelectedPage_Button, RIGHT, -96, 0)
		NBUI.NB1MovePageDown_Button:SetClickSound(SOUNDS.BOOK_PAGE_TURN)
		NBUI.NB1MovePageDown_Button:SetDimensions(20, 20)
		NBUI.NB1MovePageDown_Button:SetDrawLayer(1)		
		NBUI.NB1MovePageDown_Button:SetDrawLevel(1)
		NBUI.NB1MovePageDown_Button:SetDrawTier(0)	
		NBUI.NB1MovePageDown_Button:SetHandler("OnClicked", function(self)
			-- if (NBUI.db.NB1_ShowDialog) then
			-- 	ZO_Dialogs_ShowDialog("NBUI_NB1CONFIRM_MOVEPAGEDOWN")
			-- else
				NBUI.NB1MovePageDown(self)
			-- end
		end)
		NBUI.NB1MovePageDown_Button:SetHandler("OnMouseEnter", function(self)
			InitializeTooltip(InformationTooltip, self, TOPLEFT, 0, 0, BOTTOMRIGHT)
			SetTooltipText(InformationTooltip, GetString(SI_NBUI_MOVEPAGEDOWNBUTTON_TOOLTIP))
		end)
		NBUI.NB1MovePageDown_Button:SetHandler("OnMouseExit", function(self)
			ClearTooltip(InformationTooltip)
		end)
		NBUI.NB1MovePageDown_Button:SetHidden(true)		
		NBUI.NB1MovePageDown_Button:SetMouseOverTexture("esoui/art/buttons/gamepad/gp_downarrow.dds")
		NBUI.NB1MovePageDown_Button:SetNormalTexture("esoui/art/buttons/gamepad/gp_downarrow.dds")
		NBUI.NB1MovePageDown_Button:SetPressedTexture("esoui/art/buttons/gamepad/gp_downarrow.dds")
---------------------------------------------------------------------------------------------------	
	NBUI.NB1UndoPage_Button = WINDOW_MANAGER:CreateControl("NBUI_NB1UndoPage_Button", NBUI.NB1LeftPage_ScrollContainer.scrollChild, CT_BUTTON)
		NBUI.NB1UndoPage_Button:SetAnchor(RIGHT, NBUI.NB1SelectedPage_Button, RIGHT, -30, 0)
		NBUI.NB1UndoPage_Button:SetClickSound(SOUNDS.BOOK_PAGE_TURN)
		NBUI.NB1UndoPage_Button:SetDimensions(32, 35)
		NBUI.NB1UndoPage_Button:SetDrawLayer(1)		
		NBUI.NB1UndoPage_Button:SetDrawLevel(1)
		NBUI.NB1UndoPage_Button:SetDrawTier(0)
		NBUI.NB1UndoPage_Button:SetHandler("OnClicked", function(self)
			if (NBUI.db.NB1_ShowDialog) then
				ZO_Dialogs_ShowDialog("NBUI_NB1CONFIRM_UNDO")
			else
				NBUI.NB1UndoPage()
			end			
		end)
		NBUI.NB1UndoPage_Button:SetHandler("OnMouseEnter", function(self)
			InitializeTooltip(InformationTooltip, self, TOPLEFT, 0, 0, BOTTOMRIGHT)
			SetTooltipText(InformationTooltip, GetString(SI_NBUI_UNDOBUTTON_TOOLTIP))
		end)
		NBUI.NB1UndoPage_Button:SetHandler("OnMouseExit", function(self)
			ClearTooltip(InformationTooltip)
		end)
		NBUI.NB1UndoPage_Button:SetHidden(true)		
		NBUI.NB1UndoPage_Button:SetMouseOverTexture("/esoui/art/contacts/social_note_over.dds") 
		NBUI.NB1UndoPage_Button:SetNormalTexture("/esoui/art/contacts/social_note_up.dds")
		NBUI.NB1UndoPage_Button:SetPressedTexture("/esoui/art/contacts/social_note_down.dds")		
---------------------------------------------------------------------------------------------------		
	-- NBUI.NB1RunScript_Button = WINDOW_MANAGER:CreateControl("NBUI_NB1RunScript_Button", NBUI.NB1LeftPage_ScrollContainer.scrollChild, CT_BUTTON)
	-- 	NBUI.NB1RunScript_Button:SetAnchor(RIGHT, NBUI.NB1SelectedPage_Button, RIGHT, -30, -2)		
	-- 	NBUI.NB1RunScript_Button:SetClickSound(SOUNDS.BOOK_PAGE_TURN)
	-- 	NBUI.NB1RunScript_Button:SetDimensions(28, 28)
	-- 	NBUI.NB1RunScript_Button:SetDrawLayer(1)		
	-- 	NBUI.NB1RunScript_Button:SetDrawLevel(1)
	-- 	NBUI.NB1RunScript_Button:SetDrawTier(0) 
	-- 	NBUI.NB1RunScript_Button:SetHandler("OnClicked", function(self)
	-- 		local NBUIScript = zo_loadstring(NBUI.NB1RightPage_Contents:GetText())
	-- 		if NBUIScript then
	-- 			NBUIScript()
	-- 		end
	-- 	end)
	-- 	NBUI.NB1RunScript_Button:SetHandler("OnMouseEnter", function(self)
	-- 		InitializeTooltip(InformationTooltip, self, TOPLEFT, 0, 0, BOTTOMRIGHT)
	-- 		SetTooltipText(InformationTooltip, GetString(SI_NBUI_RUNBUTTON_TOOLTIP))
	-- 	end)
	-- 	NBUI.NB1RunScript_Button:SetHandler("OnMouseExit", function(self)
	-- 		ClearTooltip(InformationTooltip)
	-- 	end)
	-- 	NBUI.NB1RunScript_Button:SetHidden(true)		
	-- 	NBUI.NB1RunScript_Button:SetMouseOverTexture("/esoui/art/buttons/edit_over.dds")
	-- 	NBUI.NB1RunScript_Button:SetNormalTexture("/esoui/art/buttons/edit_up.dds")
	-- 	NBUI.NB1RunScript_Button:SetPressedTexture("/esoui/art/buttons/edit_down.dds")
---------------------------------------------------------------------------------------------------
	NBUI.NB1DeletePage_Button = WINDOW_MANAGER:CreateControl("NBUI_NB1DeletePage_Button", NBUI.NB1LeftPage_ScrollContainer.scrollChild, CT_BUTTON)
		NBUI.NB1DeletePage_Button:SetAnchor(RIGHT, NBUI.NB1SelectedPage_Button, RIGHT, 0, 0) 		
		NBUI.NB1DeletePage_Button:SetClickSound(SOUNDS.BOOK_PAGE_TURN)
		NBUI.NB1DeletePage_Button:SetDimensions(26, 26)
		NBUI.NB1DeletePage_Button:SetDrawLayer(1)
		NBUI.NB1DeletePage_Button:SetDrawLevel(1)
		NBUI.NB1DeletePage_Button:SetDrawTier(0)
		NBUI.NB1DeletePage_Button:SetHandler("OnClicked", function(self)
			if (NBUI.db.NB1_ShowDialog) then
				ZO_Dialogs_ShowDialog("NBUI_NB1CONFIRM_DELETE")
			else
				NBUI.NB1DeletePage()
			end			
		end)
		NBUI.NB1DeletePage_Button:SetHandler("OnMouseEnter", function(self)
			InitializeTooltip(InformationTooltip, self, TOPLEFT, 0, 0, BOTTOMRIGHT)
			SetTooltipText(InformationTooltip, GetString(SI_NBUI_DELETEBUTTON_TOOLTIP))
		end)
		NBUI.NB1DeletePage_Button:SetHandler("OnMouseExit", function(self)
			ClearTooltip(InformationTooltip)
		end)		
		NBUI.NB1DeletePage_Button:SetMouseOverTexture("/esoui/art/buttons/decline_over.dds")
		NBUI.NB1DeletePage_Button:SetNormalTexture("/esoui/art/buttons/decline_up.dds")
		NBUI.NB1DeletePage_Button:SetPressedTexture("/esoui/art/buttons/decline_down.dds")		
--***********************************************************************************************--		
--  RIGHT PAGE  -----------------------------------------------------------------------------------		
	NBUI.NB1RightPage_TitleBackdrop  = WINDOW_MANAGER:CreateControlFromVirtual("NBUI_NB1RightPage_TitleBackdrop", NBUI.NB1MainWindow, "ZO_EditBackdrop")
		NBUI.NB1RightPage_TitleBackdrop:SetAnchor(TOPRIGHT, NBUI.NB1MainWindow_Cover, TOPRIGHT, -70, 160)		
		NBUI.NB1RightPage_TitleBackdrop:SetCenterColor(0, 0, 0, 0)		
		NBUI.NB1RightPage_TitleBackdrop:SetDimensions(420, 45)
		NBUI.NB1RightPage_TitleBackdrop:SetDrawLayer(0)
		NBUI.NB1RightPage_TitleBackdrop:SetDrawLevel(1)
		NBUI.NB1RightPage_TitleBackdrop:SetDrawTier(0)		
		NBUI.NB1RightPage_TitleBackdrop:SetEdgeColor(0, 0, 0, 0)		
---------------------------------------------------------------------------------------------------	
	NBUI.NB1RightPage_Backdrop = WINDOW_MANAGER:CreateControlFromVirtual("NBUI_NB1RightPage_Backdrop", NBUI.NB1MainWindow, "ZO_EditBackdrop")
		NBUI.NB1RightPage_Backdrop:SetAnchor(BOTTOMRIGHT, NBUI.NB1MainWindow_Cover, BOTTOMRIGHT, -70, -164)		
		NBUI.NB1RightPage_Backdrop:SetCenterColor(0, 0, 0, 0)
		NBUI.NB1RightPage_Backdrop:SetDimensions(420, 645)
		NBUI.NB1RightPage_Backdrop:SetDrawLayer(0)
		NBUI.NB1RightPage_Backdrop:SetDrawLevel(1)
		NBUI.NB1RightPage_Backdrop:SetDrawTier(0)		
		NBUI.NB1RightPage_Backdrop:SetEdgeColor(0, 0, 0, 0)
---------------------------------------------------------------------------------------------------	
	NBUI.NB1RightPage_Title = WINDOW_MANAGER:CreateControlFromVirtual("NBUI_NB1RightPage_Title", NBUI.NB1RightPage_TitleBackdrop, "ZO_DefaultEditForBackdrop")
		NBUI.NB1RightPage_Title:SetColor(unpack(NBUI.db.NB1_TextColor))
		NBUI.NB1RightPage_Title:SetDrawLayer(0)
		NBUI.NB1RightPage_Title:SetDrawLevel(2)
		NBUI.NB1RightPage_Title:SetDrawTier(0)		
		NBUI.NB1RightPage_Title:SetFont("ZoFontBookPaperTitle")
		NBUI.NB1RightPage_Title:SetHandler("OnEscape", NBUI.NB1RightPage_Title.LoseFocus)		
		NBUI.NB1RightPage_Title:SetHandler("OnTab", function() 
			NBUI.NB1RightPage_Contents:TakeFocus() 
		end)
		NBUI.NB1RightPage_Title:SetHandler("OnMouseDoubleClick", function(self) 
			zo_callLater(function() self:SelectAll() end, 100)
		end) 
		NBUI.NB1RightPage_Title:SetHandler("OnTextChanged", function(self)
				local NB1Pages = NBUI.db.NB1Pages[currentlyViewing]
				if not NB1Pages or self:GetText() ~= NB1Pages.title or self:GetText() then
					NBUI.NB1SavePage_Button:SetHidden(false)
					NBUI.NB1UndoPage_Button:SetHidden(false)				
				else
					NBUI.NB1SavePage_Button:SetHidden(true)
					NBUI.NB1UndoPage_Button:SetHidden(true)				
				end
			end)
		NBUI.NB1RightPage_Title:SetMaxInputChars(33)
		NBUI.NB1RightPage_Title:SetHidden(true)
---------------------------------------------------------------------------------------------------		
	NBUI.NB1RightPage_ScrollContainer = WINDOW_MANAGER:CreateControlFromVirtual("NBUI_NB1RightPage_ScrollContainer", NBUI.NB1MainWindow, "ZO_ScrollContainer")
		NBUI.NB1RightPage_ScrollContainer.scrollChild = NBUI.NB1RightPage_ScrollContainer:GetNamedChild("ScrollChild")
		-- NBUI.NB1RightPage_ScrollContainer:SetAnchorFill(NBUI.NB1RightPage_Backdrop)
		NBUI.NB1RightPage_ScrollContainer:ClearAnchors()
		NBUI.NB1RightPage_ScrollContainer:SetAnchor(TOPLEFT, NBUI.NB1RightPage_Backdrop, TOPLEFT, 0, 0)
		NBUI.NB1RightPage_ScrollContainer:SetAnchor(BOTTOMRIGHT, NBUI.NB1RightPage_Backdrop, BOTTOMRIGHT, 0, -30) -- Extra space on bottom of page.
		NBUI.NB1RightPage_ScrollContainer:SetDrawLayer(0)	
		NBUI.NB1RightPage_ScrollContainer:SetDrawLevel(2)
		NBUI.NB1RightPage_ScrollContainer:SetDrawTier(0)
		NBUI.NB1RightPage_ScrollContainer:SetHidden(true)
		
---------------------------------------------------------------------------------------------------	

	NBUI.NBUI_NB1RightPage_CharacterCounter = WINDOW_MANAGER:CreateControl("NBUI_NB1RightPage_CharacterCounter", NBUI.NB1RightPage_ScrollContainer, CT_LABEL)
	NBUI.NBUI_NB1RightPage_CharacterCounter:SetAnchor(BOTTOMRIGHT, NBUI.NB1RightPage_ScrollContainer, BOTTOMRIGHT, -30, 25)
	NBUI.NBUI_NB1RightPage_CharacterCounter:SetFont("$(ANTIQUE_FONT)|14")
	NBUI.NBUI_NB1RightPage_CharacterCounter:SetDrawLayer(0)
	NBUI.NBUI_NB1RightPage_CharacterCounter:SetDrawLevel(3)
	NBUI.NBUI_NB1RightPage_CharacterCounter:SetDrawTier(1)
	color[4] = 0.5
	NBUI.NBUI_NB1RightPage_CharacterCounter:SetColor(unpack(color))
	NBUI.NBUI_NB1RightPage_CharacterCounter:SetHidden(true)
	
---------------------------------------------------------------------------------------------------	
	NBUI.NB1RightPage_Contents = WINDOW_MANAGER:CreateControlFromVirtual("NBUI_NB1RightPage_Contents", NBUI.NB1RightPage_ScrollContainer, "ZO_DefaultEditMultiLineForBackdrop")
		NBUI.NB1RightPage_Contents:ClearAnchors()
		NBUI.NB1RightPage_Contents:SetAnchor(TOPLEFT, NBUI.NB1RightPage_ScrollContainer, TOPLEFT, 6, 5)
		NBUI.NB1RightPage_Contents:SetHeight(NBUI.NB1RightPage_ScrollContainer:GetHeight())
		NBUI.NB1RightPage_Contents:SetWidth(NBUI.NB1RightPage_ScrollContainer:GetWidth()-20)
		NBUI.NB1RightPage_Contents:SetColor(unpack(NBUI.db.NB1_TextColor))
		NBUI.NB1RightPage_Contents:SetDrawLayer(0)
		NBUI.NB1RightPage_Contents:SetDrawLevel(3)
		NBUI.NB1RightPage_Contents:SetDrawTier(1)
		NBUI.NB1RightPage_Contents:SetMaxInputChars(3000) -- Visual max, higher than saveable max.
		NBUI.NB1RightPage_Contents:SetFont("ZoFontBookPaper")
		-- NBUI.NB1RightPage_Contents:SetMultiLine(true)
		if NBUI.db.NB1_FormattedMode then NBUI.NB1RightPage_Contents:SetHidden(true) end
		NBUI.NB1RightPage_Contents:SetSelectionColor(unpack(NBUI.db.NB1_SelectionColor))
		
		NBUI.NB1RightPage_Contents:SetHandler("OnFocusLost", function()
			if NBUI.db.NB1_FormattedMode and NBUI.db.NB1_LeaveEditModeOnFocus then
				NBUI.NB1RightPage_Contents:SetHidden(true)
				NBUI.NB1RightPage_ContentsLabel:SetHidden(false)
			end
		end)
		NBUI.NB1RightPage_Contents:SetHandler("OnMouseExit", function()
			if NBUI.db.NB1_FormattedMode and NBUI.db.NB1_LeaveEditModeOnExit then
				NBUI.NB1RightPage_Contents:SetHidden(true)
				NBUI.NB1RightPage_ContentsLabel:SetHidden(false)
			end
		end)
		
		NBUI.NB1RightPage_Contents:SetHandler("OnEscape", NBUI.NB1RightPage_Contents.LoseFocus)
		NBUI.NB1RightPage_Contents:SetHandler("OnTab", function() 
			NBUI.NB1RightPage_Title:TakeFocus() 
		end)

		NBUI.NB1RightPage_Contents:SetHandler("OnMouseDoubleClick", function(self)
			-- Select all page, from Settings.
			if NBUI.db.NB1_DoubleClickSelectPage then
				zo_callLater(function() self:SelectAll() end, 100)
			end

			-- Track double-clicking.
			self.DoubleClicked = true

			-- Catch triple-clicks.
			-- Avoid duplicates if already running.
			if not self.TripleClicking then
				self.TripleClicking = true
				zo_callLater(function() self.TripleClicking = false end, 500)
			end
		end)

		-- Catch triple-clicks.
		NBUI.NB1RightPage_Contents:SetHandler("OnMouseUp", function(self, button, upInside)
			if button == MOUSE_BUTTON_INDEX_LEFT and upInside then
				if NBUI.db.NB1_SelectLine and not self.DoubleClicked and self.TripleClicking then
					NBUI.SelectLine(self)
				end
			end
			-- Do not confuse with triple-clicking.
			if self.DoubleClicked then self.DoubleClicked = false end
		end)

		NBUI.NB1RightPage_Contents:SetHandler("OnTextChanged", function(self)
			local page = NBUI.db.NB1Pages[currentlyViewing]
			local text = self:GetText()
			if not page or text ~= page.text or text then
				NBUI.NB1SavePage_Button:SetHidden(false)
				NBUI.NB1UndoPage_Button:SetHidden(false)				
			else
				NBUI.NB1SavePage_Button:SetHidden(true)
				NBUI.NB1UndoPage_Button:SetHidden(true)				
			end
			
			-- Update label display.
			NBUI.NB1RightPage_ContentsLabel:SetText(text)
			NBUI.NB1RightPage_ContentsLabel:UpdateHeight()
			
			-- Update character counter.
			-- NOTE: SavedVars won't save a string with over 2,000 character bytes.
			local textLen = #text
			if textLen > savedVarsStringMax then
				NBUI.NB1SavePage_Button:SetHidden(true)
			end
			NBUI.NBUI_NB1RightPage_CharacterCounter:SetText(textLen .. ' / ' .. savedVarsStringMax)
			NBUI.NBUI_NB1RightPage_CharacterCounter:SetHidden(false)
		end)
		
---------------------------------------------------------------------------------------------------	
	NBUI.NB1RightPage_ContentsLabel = WINDOW_MANAGER:CreateControl("NBUI_NB1RightPage_ContentsLabel", NBUI.NB1RightPage_ScrollContainer.scrollChild, CT_LABEL)	
		NBUI.NB1RightPage_ContentsLabel:SetAnchor(TOPLEFT, NBUI.NB1RightPage_ScrollContainer.scrollChild, TOPLEFT, 6, 5) -- Matches Editbox.
		NBUI.NB1RightPage_ContentsLabel:SetWidth(NBUI.NB1RightPage_ScrollContainer:GetWidth()-20)
		NBUI.NB1RightPage_ContentsLabel:SetHeight(NBUI.NB1RightPage_ScrollContainer:GetHeight())
		NBUI.NB1RightPage_ContentsLabel:SetColor(unpack(NBUI.db.NB1_TextColor))
		NBUI.NB1RightPage_ContentsLabel:SetDrawLayer(0)
		NBUI.NB1RightPage_ContentsLabel:SetDrawLevel(3)
		NBUI.NB1RightPage_ContentsLabel:SetDrawTier(1)
		NBUI.NB1RightPage_ContentsLabel:SetFont("ZoFontBookPaper")
		NBUI.NB1RightPage_ContentsLabel:SetHidden(false)
		if not NBUI.db.NB1_FormattedMode then NBUI.NB1RightPage_ContentsLabel:SetHidden(true) end
		NBUI.NB1RightPage_ContentsLabel:SetMouseEnabled(true)
		-- NBUI.NB1RightPage_ContentsLabel:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)	-- TEXT_WRAP_MODE_TRUNCATE / TEXT_WRAP_MODE_ELLIPSIS

		NBUI.NB1RightPage_ContentsLabel:SetHandler("OnMouseEnter", function(self)
			if NBUI.db.NB1_EditModeHover then
				NBUI.NB1RightPage_Contents:SetHidden(false)
				NBUI.NB1RightPage_ContentsLabel:SetHidden(true)
				NBUI.NB1RightPage_Contents:TakeFocus()
			end
		end)

		NBUI.NB1RightPage_ContentsLabel:SetHandler("OnMouseUp", function(self, button, upInside)
			if NBUI.db.NB1_EditModeClick and upInside then
				NBUI.NB1RightPage_Contents:SetHidden(false)
				NBUI.NB1RightPage_ContentsLabel:SetHidden(true)
				NBUI.NB1RightPage_Contents:TakeFocus()
			end
		end)

		NBUI.NB1RightPage_ContentsLabel.UpdateHeight = function(self, hidden)
			-- Filled height if shorter than page,
			-- otherwise let dynamic height set it for scrollsbar.
			NBUI.NB1RightPage_ContentsLabel:SetHeight(0) -- Test dynamic height with current text.
			zo_callLater(function(self, height)
				local height = NBUI.NB1RightPage_ScrollContainer:GetHeight()
				if NBUI.NB1RightPage_ContentsLabel:GetHeight() < height then
					NBUI.NB1RightPage_ContentsLabel:SetHeight(height)
				end
			end, 100)
		end
---------------------------------------------------------------------------------------------------	
	NBUI.NB1NewPage_Button = WINDOW_MANAGER:CreateControl("NBUI_NB1NewPage_Button", NBUI.NB1MainWindow, CT_BUTTON)
		NBUI.NB1NewPage_Button:SetAnchor(TOPRIGHT, NBUI.NB1RightPage_TitleBackdrop, TOPRIGHT, 34, -25)		
		NBUI.NB1NewPage_Button:SetClickSound(SOUNDS.BOOK_PAGE_TURN)	
		NBUI.NB1NewPage_Button:SetDimensions(32, 32)
		NBUI.NB1NewPage_Button:SetDrawLayer(1)
		NBUI.NB1NewPage_Button:SetDrawLevel(2)
		NBUI.NB1NewPage_Button:SetDrawTier(0)
		NBUI.NB1NewPage_Button:SetHandler("OnClicked", function(self)
			if (NBUI.db.NB1_ShowDialog) then
				ZO_Dialogs_ShowDialog("NBUI_NB1CONFIRM_NEWPAGE")
			else
				NBUI.NB1NewPage(self)
			end	
		end)
		NBUI.NB1NewPage_Button:SetHandler("OnMouseEnter", function(self)
			InitializeTooltip(InformationTooltip, self, TOPLEFT, 0, 0, BOTTOMRIGHT)
			SetTooltipText(InformationTooltip, GetString(SI_NBUI_NEWBUTTON_TOOLTIP))
		end)
		NBUI.NB1NewPage_Button:SetHandler("OnMouseExit", function(self)
			ClearTooltip(InformationTooltip)
		end)		
		NBUI.NB1NewPage_Button:SetMouseOverTexture("/esoui/art/chatwindow/chat_addtab_over.dds")
		NBUI.NB1NewPage_Button:SetNormalTexture("/esoui/art/chatwindow/chat_addtab_up.dds")
		NBUI.NB1NewPage_Button:SetPressedTexture("/esoui/art/chatwindow/chat_addtab_down.dds")
			
	NBUI.NB1NewPage_Button.highlight = WINDOW_MANAGER:CreateControl("NBUI_NB1NewPage_Button_highlight", NBUI.NB1NewPage_Button, CT_TEXTURE)		
		NBUI.NB1NewPage_Button.highlight:SetAnchor(TOPLEFT, NBUI.NB1NewPage_Button, TOPLEFT, -15, -6)
		NBUI.NB1NewPage_Button.highlight:SetAnchor(BOTTOMRIGHT, NBUI.NB1NewPage_Button, BOTTOMRIGHT, 6, 15)
		NBUI.NB1NewPage_Button.highlight:SetColor(0, 0.8, 0, 0)		
		NBUI.NB1NewPage_Button.highlight:SetDrawLayer(1)
		NBUI.NB1NewPage_Button.highlight:SetDrawLevel(1)
		NBUI.NB1NewPage_Button.highlight:SetDrawTier(0)		
		NBUI.NB1NewPage_Button.highlight:SetTexture("/esoui/art/chatwindow/maximize_up.dds")
		NBUI.NB1NewPage_Button.highlight:SetAlpha(1)
--***********************************************************************************************--		
--  MAIN WINDOW CLOSE BUTTON  ---------------------------------------------------------------------		
--[[
		NBUI.NB1Close_Button = WINDOW_MANAGER:CreateControlFromVirtual("NBUI_NB1Close_Button", NBUI.NB1MainWindow, "ZO_CloseButton")
			NBUI.NB1Close_Button:SetDimensions(16, 16)
			NBUI.NB1Close_Button:SetAnchor(TOPRIGHT, NBUI.NB1RightPage_TitleBackdrop, TOPRIGHT, 40, -25)
			NBUI.NB1Close_Button:SetHandler("OnClicked", function(self) 
				NBUI.NB1MainWindow:SetHidden(true) 
				NBUI.NB1MainWindow:SetTopmost(false)
			end) 
			NBUI.NB1Close_Button:SetHandler("OnMouseEnter", function(self)
				InitializeTooltip(InformationTooltip, self, TOPLEFT, 0, 0, BOTTOMRIGHT)
				SetTooltipText(InformationTooltip, GetString(SI_NBUI_CLOSEBUTTON_TOOLTIP))
			end)
			NBUI.NB1Close_Button:SetHandler("OnMouseExit", function(self)
				ClearTooltip(InformationTooltip)
			end)
]]--

	NBUI.NB1Close_Button = WINDOW_MANAGER:CreateControl("NBUI_NB1Close_Button", NBUI.NB1MainWindow, CT_BUTTON)
		NBUI.NB1Close_Button:SetAnchor(BOTTOMRIGHT, NBUI.NB1RightPage_Backdrop, BOTTOMRIGHT, 46, 16)		
		NBUI.NB1Close_Button:SetClickSound(SOUNDS.BOOK_CLOSE)		
		NBUI.NB1Close_Button:SetDimensions(25, 25)
		NBUI.NB1Close_Button:SetDrawLayer(1)
		NBUI.NB1Close_Button:SetDrawLevel(2)
		NBUI.NB1Close_Button:SetDrawTier(0)	
		NBUI.NB1Close_Button:SetHandler("OnClicked", NBUI.NB1KeyBindToggle
			-- function(self) 
			-- NBUI.NB1MainWindow:SetHidden(true) 
			-- if SCENE_MANAGER:IsInUIMode() then
			-- 	SCENE_MANAGER:SetInUIMode(false)
			-- end
			-- DoCommand("/idle")
			--end
		)
		NBUI.NB1Close_Button:SetHandler("OnMouseEnter", function(self)
			InitializeTooltip(InformationTooltip, self, TOPLEFT, 0, 0, BOTTOMRIGHT)
			SetTooltipText(InformationTooltip, GetString(SI_NBUI_CLOSEBUTTON_TOOLTIP))
		end)
		NBUI.NB1Close_Button:SetHandler("OnMouseExit", function(self)
			ClearTooltip(InformationTooltip)
		end)
		NBUI.NB1Close_Button:SetMouseOverTexture("/esoui/art/buttons/closebutton_mouseover.dds")
		NBUI.NB1Close_Button:SetNormalTexture("/esoui/art/buttons/closebutton_up.dds")
		NBUI.NB1Close_Button:SetPressedTexture("/esoui/art/buttons/closebutton_down.dds")
		
	NBUI.NB1Close_ButtonTexture = WINDOW_MANAGER:CreateControl("NBUI_NB1Close_ButtonTexture", NBUI.NB1Close_Button, CT_TEXTURE)		
		NBUI.NB1Close_ButtonTexture:SetAnchor(TOPLEFT, NBUI.NB1Close_Button, TOPLEFT, -20, -11)
		NBUI.NB1Close_ButtonTexture:SetAnchor(BOTTOMRIGHT, NBUI.NB1Close_Button, BOTTOMRIGHT, 10, 20)
		NBUI.NB1Close_ButtonTexture:SetColor(0.8, 0, 0, 0)		
		NBUI.NB1Close_ButtonTexture:SetDrawLayer(1)
		NBUI.NB1Close_ButtonTexture:SetDrawLevel(1)
		NBUI.NB1Close_ButtonTexture:SetDrawTier(0)	
		NBUI.NB1Close_ButtonTexture:SetTexture("/esoui/art/chatwindow/maximize_up.dds")--("/esoui/art/buttons/cancel_up.dds")
		NBUI.NB1Close_ButtonTexture:SetTextureRotation(4.7, .61, .32)
		NBUI.NB1Close_ButtonTexture:SetAlpha(1)
		
--***********************************************************************************************--		
--  CHAT WINDOW BUTTONS  --------------------------------------------------------------------------
	NBUI.NB1MaxChatWin_Button = WINDOW_MANAGER:CreateControl("NBUI_NB1MaxChatWin_Button", ZO_ChatWindow, CT_BUTTON)	
		NBUI.NB1MaxChatWin_Button:SetDimensions(32, 32)
		NBUI.NB1MaxChatWin_Button:SetAnchor(CENTER, ZO_ChatWindowOptions, CENTER, -40, 1)
		-- NBUI.NB1MaxChatWin_Button:SetAnchor(TOPRIGHT, ZO_ChatWindow, TOPRIGHT, NBUI.db.NB1_MaxOffsetChatButton, 7)
		NBUI.NB1MaxChatWin_Button:SetMouseOverTexture("/esoui/art/mainmenu/menubar_journal_down.dds")
		NBUI.NB1MaxChatWin_Button:SetHidden(not NBUI.db.NB1_ChatButton)				
		NBUI.NB1MaxChatWin_Button:SetHandler("OnClicked", function(self)
			--if button == 1 then
				NBUI.NB1KeyBindToggle()
			--elseif button == 2 then
				--DoCommand("/nb1s") 
			--end
		end)		
		NBUI.NB1MaxChatWin_Button:SetHandler("OnMouseEnter", function(self)
			InitializeTooltip(InformationTooltip, self, TOPLEFT, 0, 0, BOTTOMRIGHT)
			SetTooltipText(InformationTooltip, NBUI.db.NB1_Title)
		end)
		NBUI.NB1MaxChatWin_Button:SetHandler("OnMouseExit", function(self)
			ClearTooltip(InformationTooltip)
		end)
		
	NBUI.NB1MaxChatWin_ButtonTexture = WINDOW_MANAGER:CreateControl("NBUI_NB1MaxTexureChatButton", ZO_ChatWindow, CT_TEXTURE)		
		NBUI.NB1MaxChatWin_ButtonTexture:SetAnchorFill(NBUI.NB1MaxChatWin_Button)
		NBUI.NB1MaxChatWin_ButtonTexture:SetColor(unpack(NBUI.db.NB1_BookColor))
		NBUI.NB1MaxChatWin_ButtonTexture:SetDrawTier(DT_HIGH)
		NBUI.NB1MaxChatWin_ButtonTexture:SetHidden(not NBUI.db.NB1_ChatButton)
		NBUI.NB1MaxChatWin_ButtonTexture:SetTexture("/esoui/art/mainmenu/menubar_journal_up.dds")

	NBUI.NB1MinChatWin_Button = WINDOW_MANAGER:CreateControl("NBUI_NB1MinChatWin_Button", ZO_ChatWindowMinBar, CT_BUTTON)
		NBUI.NB1MinChatWin_Button:SetDimensions(32, 32)
		NBUI.NB1MinChatWin_Button:SetAnchor(TOPLEFT, ZO_ChatWindowMinBar, nil, 0, 220)
		-- NBUI.NB1MinChatWin_Button:SetAnchor(BOTTOMLEFT, ZO_ChatWindowMinBar, BOTTOMLEFT, -3, NBUI.db.NB1_MinOffsetChatButton)
		NBUI.NB1MinChatWin_Button:SetMouseOverTexture("/esoui/art/mainmenu/menubar_journal_down.dds")
		NBUI.NB1MinChatWin_Button:SetHidden(not NBUI.db.NB1_ChatButton)
		NBUI.NB1MinChatWin_Button:SetHandler("OnClicked", function(self)
			NBUI.NB1KeyBindToggle()
		end)		
		NBUI.NB1MinChatWin_Button:SetHandler("OnMouseEnter", function(self)
			InitializeTooltip(InformationTooltip, self, TOPLEFT, 0, 0, BOTTOMRIGHT)
			SetTooltipText(InformationTooltip, NBUI.db.NB1_Title)
		end)
		NBUI.NB1MinChatWin_Button:SetHandler("OnMouseExit", function(self)
			ClearTooltip(InformationTooltip)
		end)

	NBUI.NB1MinChatWin_ButtonTexture = WINDOW_MANAGER:CreateControl("NBUI_NB1MinTexureChatButton", ZO_ChatWindowMinBar, CT_TEXTURE)		
		NBUI.NB1MinChatWin_ButtonTexture:SetAnchorFill(NBUI.NB1MinChatWin_Button)
		NBUI.NB1MinChatWin_ButtonTexture:SetColor(unpack(NBUI.db.NB1_BookColor))
		NBUI.NB1MinChatWin_ButtonTexture:SetDrawTier(DT_HIGH)
		NBUI.NB1MinChatWin_ButtonTexture:SetHidden(not NBUI.db.NB1_ChatButton)
		NBUI.NB1MinChatWin_ButtonTexture:SetTexture("/esoui/art/mainmenu/menubar_journal_up.dds")		
end

-- Return date and time as shown below,
-- Or the default text set by user.
function NBUI.NB1NewTitle(self)
	if NBUI.db.NB1_NewPageTitle ~= "" then
		return NBUI.db.NB1_NewPageTitle
	end

	-- Bug catcher.
	if not os or not os.date then return GetString(SI_NBUI_NEWBUTTON_TITLE) end

	local h = os.date("%I")
	local m = ":" .. os.date("%M")
	local pm = os.date("%p")

	-- Bug catcher.
	if not h or not m or not pm then return GetString(SI_NBUI_NEWBUTTON_TITLE) end

	local t = tonumber(h) .. m .. pm:lower()
	local date = tonumber(os.date("%d"))
	-- e.g. 9:39pm Wed', May 2, '18
	local title = os.date(t .. " %a', %B " .. date .. ", '%y")
	return title
end

function NBUI.NB1NewPage(self)		
	currentlyViewing = nil
	
	NBUI.NB1RightPage_Title:SetHidden(false)
	NBUI.NB1RightPage_ScrollContainer:SetHidden(false)

	-- Title is current date and time, formatted.
	NBUI.NB1RightPage_Title:SetText(NBUI.NB1NewTitle())
	--NBUI.NB1RightPage_Title:SetText("New Page "..#NBUI.db.NB1Pages+1)
	--NBUI.NB1RightPage_Title:SelectAll()
	--NBUI.NB1RightPage_Title:TakeFocus()
	NBUI.NB1RightPage_Contents:Clear()
	NBUI.NB1SavePage(self)
	
	NBUI.NB1UndoPage_Button:SetHidden(true)
end	
NB1ConfirmNewDialog = {
	title={ text = GetString(SI_NBUI_NEWBUTTON_TITLE)},
	mainText={ text = GetString(SI_NBUI_NEWBUTTON_MAINTEXT)},
	buttons = {
		[1]={ 
			text = GetString(SI_NBUI_YES_LABEL), callback = function(self)
				NBUI.NB1NewPage(self)
				zo_callLater(function() SetGameCameraUIMode(true) end, 10)
			end
			},
		[2]={ text = GetString(SI_NBUI_NO_LABEL)}
	}
}
ZO_Dialogs_RegisterCustomDialog("NBUI_NB1CONFIRM_NEWPAGE", NB1ConfirmNewDialog)

function NBUI.NB1SavePage(self)
	local titleText = NBUI.NB1RightPage_Title:GetText()
		if titleText == "" then
			NBUI.NB1RightPage_Title:SetText(NBUI.NB1NewTitle())
			titleText = NBUI.NB1RightPage_Title:GetText()
		end
	local pageText = NBUI.NB1RightPage_Contents:GetText()
	local safe_titleText = ProtectText(titleText)	
	local safe_pageText = ProtectText(pageText)
	
	-- NOTE: SavedVars won't save a string with over 2,000 character bytes.
	local textLen = #safe_pageText
	-- d(textLen)
	if textLen > savedVarsStringMax then
		d('Page is too long to save!')
		return
	end
	
	if currentlyViewing == nil then	--if this was a new page
		table.insert(NBUI.db.NB1Pages, {["title"] = safe_titleText, ["text"]=safe_pageText})
		currentlyViewing = #NBUI.db.NB1Pages
		NBUI.NB1SelectedPage_Button:SetHidden(false)
		NBUI.NB1SelectedPage_Button:ClearAnchors()
		self.new = true
	else
		NBUI.db.NB1Pages[currentlyViewing].title 	= safe_titleText
		NBUI.db.NB1Pages[currentlyViewing].text 	= safe_pageText
		self.new = false
	end
		
	Populate_NB1_ScrollList()
	if self.new then
		-- NBUI.NB1SelectedPage_Button:SetAnchorFill(_G["NBUI_Index"..currentlyViewing])
		NBUI.NB1SelectedPage_Button:SetAnchorFill(NB1_IndexPool:AcquireObject(currentlyViewing))
	end

	NBUI.NB1SavePage_Button:SetHidden(true)
	NBUI.NB1UndoPage_Button:SetHidden(true)
	NBUI.NBUI_NB1RightPage_CharacterCounter:SetHidden(true)
end
NB1ConfirmSaveDialog = {
	title = { text = GetString(SI_NBUI_SAVEBUTTON_TITLE)},
	mainText = { text = GetString(SI_NBUI_SAVEBUTTON_MAINTEXT)},
	buttons = {
		[1]={ 
			text = GetString(SI_NBUI_YES_LABEL), callback = function(self)
				NBUI.NB1SavePage(self)
				zo_callLater(function() SetGameCameraUIMode(true) end, 10)
			end
			},
		[2]={ text = GetString(SI_NBUI_NO_LABEL)}
	}
}
ZO_Dialogs_RegisterCustomDialog("NBUI_NB1CONFIRM_SAVE", NB1ConfirmSaveDialog)

function NBUI.NB1UndoPage() 		
	if currentlyViewing then
		NBUI.NB1RightPage_Title:SetText(NBUI.db.NB1Pages[currentlyViewing].title)
		NBUI.NB1RightPage_Contents:SetText(NBUI.db.NB1Pages[currentlyViewing].text)
	end
	
	NBUI.NB1SavePage_Button:SetHidden(true)
	NBUI.NB1UndoPage_Button:SetHidden(true)
end
NB1ConfirmUndoDialog = {
	title = { text = GetString(SI_NBUI_UNDOPAGE_TITLE)},
	mainText = { text = GetString(SI_NBUI_UNDOPAGE_MAINTEXT)},
	buttons = {
		[1]={ 
			text = GetString(SI_NBUI_YES_LABEL), callback = function()
				NBUI.NB1UndoPage()
				zo_callLater(function() SetGameCameraUIMode(true) end, 10)
			end
			},
		[2]={ text = GetString(SI_NBUI_NO_LABEL)}
	}
}
ZO_Dialogs_RegisterCustomDialog("NBUI_NB1CONFIRM_UNDO", NB1ConfirmUndoDialog)

-- delete page function
function NBUI.NB1DeletePage()
	if currentlyViewing then
		table.remove(NBUI.db.NB1Pages, currentlyViewing)
		currentlyViewing = nil
		Populate_NB1_ScrollList()
		NBUI.NB1SelectedPage_Button:SetHidden(true)
	end

	NBUI.NB1RightPage_Title:Clear()
	NBUI.NB1RightPage_Contents:Clear()

	NBUI.NB1RightPage_Title:SetHidden(true)
	NBUI.NB1RightPage_ScrollContainer:SetHidden(true)
		
	NBUI.NB1DeletePage_Button:SetHidden(true)
	NBUI.NB1SavePage_Button:SetHidden(true)				
	NBUI.NB1UndoPage_Button:SetHidden(true)

	NBUI.NB1MovePageUp_Button:SetHidden(true)
	NBUI.NB1MovePageDown_Button:SetHidden(true)
	-- NBUI.NB1RunScript_Button:SetHidden(true)
end
NB1ConfirmDeleteDialog = {
	title = {text = GetString(SI_NBUI_DELETEBUTTON_TITLE)},
	mainText = {text = GetString(SI_NBUI_DELETEBUTTON_MAINTEXT)},
	buttons = {
		[1]={
			text = GetString(SI_NBUI_YES_LABEL), callback = function()
				NBUI.NB1DeletePage()
				zo_callLater(function() SetGameCameraUIMode(true) end, 10)
			end
			},
		[2]={text = GetString(SI_NBUI_NO_LABEL)}
	}
}
ZO_Dialogs_RegisterCustomDialog("NBUI_NB1CONFIRM_DELETE", NB1ConfirmDeleteDialog)

-- Shift page one slot up.
function NBUI.NB1MovePageUp(self)
	-- Ignore if first item in table.
	if not currentlyViewing or currentlyViewing == 1 then return end

	NBUI.NB1SelectedPage_Button:SetHidden(true)
	NBUI.NB1SelectedPage_Button:ClearAnchors()

	local page = table.remove(NBUI.db.NB1Pages, currentlyViewing)
	table.insert(NBUI.db.NB1Pages, currentlyViewing-1, page)
	currentlyViewing = currentlyViewing-1
	
	Populate_NB1_ScrollList()
	NBUI.NB1SelectedPage_Button:SetAnchorFill(NB1_IndexPool:AcquireObject(currentlyViewing))
	NBUI.NB1SelectedPage_Button:SetHidden(false)
end

-- Shift page one slot down.
function NBUI.NB1MovePageDown(self)
	-- Ignore if last item in table.
	if not currentlyViewing or currentlyViewing == #NBUI.db.NB1Pages then return end

	NBUI.NB1SelectedPage_Button:SetHidden(true)
	NBUI.NB1SelectedPage_Button:ClearAnchors()

	local page = table.remove(NBUI.db.NB1Pages, currentlyViewing)
	table.insert(NBUI.db.NB1Pages, currentlyViewing+1, page)
	currentlyViewing = currentlyViewing+1
	
	Populate_NB1_ScrollList()
	NBUI.NB1SelectedPage_Button:SetAnchorFill(NB1_IndexPool:AcquireObject(currentlyViewing))
	NBUI.NB1SelectedPage_Button:SetHidden(false)
end

-- Toggles previewing colors, padding, and textures from text tags.
function NBUI.NB1Preview(self)
	local oldState = NBUI.db.NB1Pages[currentlyViewing].preview
	local newState = not state
	-- Toggle.
	NBUI.db.NB1Pages[currentlyViewing].preview = not oldState
	d(state, NBUI.db.NB1Pages[currentlyViewing].preview)
	-- Apply template for preview mode.
	if newState then
		WINDOW_MANAGER:ApplyTemplateToControl(NBUI.NB1RightPage_Contents, "ZO_SavingEditBox")
	else
		WINDOW_MANAGER:ApplyTemplateToControl(NBUI.NB1RightPage_Contents, "ZO_DefaultEditMultiLineForBackdrop")
	end
end

function NBUI.NB1KeyBindToggle()
	SCENE_MANAGER:ToggleTopLevel(NBUI.NB1MainWindow)
	if NBUI.NB1MainWindow:IsHidden() then
		PlaySound(SOUNDS.BOOK_CLOSE)
		if NBUI.db.NB1_EmoteIdle then DoCommand("/idle") end
	else
		PlaySound(SOUNDS.BOOK_OPEN)
		if NBUI.db.NB1_EmoteRead then DoCommand("/read") end
	end
end

-- Selects the line under cursor for an EditBox control.
function NBUI.SelectLine(control)
	local cursor = control:GetCursorPosition()
	local text = control:GetText()

	-- Find first Newline before cursor, or startoftext.
	local first = nil
	local t = text:sub(0, cursor)
	t = t:reverse()
	first = t:find('\n')
	if first == nil then first = 0 else first = cursor-first end
	-- Find first Newline after cursor, or endoftext.
	local last = nil
	last = text:find('\n', cursor)
	if last == nil then last = text:len() end

	control:SetSelection(first, last)
end

SLASH_COMMANDS["/nb"] = NBUI.NB1KeyBindToggle