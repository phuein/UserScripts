if NBUI == nil then NBUI = {} end

function CreateNBUISettings()
	local LAM2 = LibStub("LibAddonMenu-2.0")
	local panelData = {
        type = "panel",
        name = "Notebook 2018",
		displayName = ZO_HIGHLIGHT_TEXT:Colorize(GetString(SI_NBUI_ADDONOPTIONS_NAME)),
		author = GetString(SI_NBUI_AUTHOR),
		version = GetString(SI_NBUI_VERSION_NUM),		
		registerForRefresh  = true,
		registerForDefaults = true,
		-- website = "http://www.esoui.com/downloads/info1105-Notebook.html",
		-- chat command to open settings window
		slashCommand = "/nbs", 

		-- resets NBUI position, when reset to defaults is pressed
		resetFunc = function()
			NBUI.NB1MainWindow:ClearAnchors()
			NBUI.NB1MainWindow:SetAnchor (CENTER, GuiRoot, CENTER, 0, -48)			
			 _,a,_,b,x,y = NBUI.NB1MainWindow:GetAnchor()
			NBUI.db.NB1_Anchor = {["a"]=a, ["b"]=b, ["x"]=x, ["y"]=y}
		end
    }
	LAM2:RegisterAddonPanel("NBUIOptions", panelData)
	
	local optionsData = {
		[1]={ -- general category
			type = "header",
			name = ZO_HIGHLIGHT_TEXT:Colorize(GetString(SI_NBUI_HEADER_GENERAL)),
			},			
		[2]={ -- show title
			type = "checkbox",
			name = GetString(SI_NBUI_SHOWTITLE_LABEL),
			tooltip = GetString(SI_NBUI_SHOWTITLE_TOOLTIP),
			getFunc = function() return NBUI.db.NB1_ShowTitle end,
			setFunc = function(value)
				NBUI.db.NB1_ShowTitle = value
				NBUI.NB1LeftPage_Title:SetHidden(not NBUI.db.NB1_ShowTitle)
				NBUI.NB1LeftPage_Separator:SetHidden(not NBUI.db.NB1_ShowTitle)
				NBUI.NB1Information_Button:SetHidden(not NBUI.db.NB1_ShowTitle)
					if (NBUI.db.NB1_ShowTitle) then
						NBUI.NB1LeftPage_Backdrop:SetDimensions(420, 645)
					else
						NBUI.NB1LeftPage_Backdrop:SetDimensions(420, 690)
					end
				end,
			default = NBUI.defaults.NB1_ShowTitle,
			},						
		[3]={ -- title label
			type = "editbox",
			name = GetString(SI_NBUI_TITLE_LABEL),
			tooltip = GetString(SI_NBUI_TITLE_TOOLTIP),
			getFunc = function() return NBUI.db.NB1_Title end,
			setFunc = function(value)
				NBUI.db.NB1_Title = value
				NBUI.NB1LeftPage_Title:SetText(NBUI.db.NB1_Title)
				end,
			default = NBUI.defaults.NB1_Title,
			},					
		[4]={ -- change book color
			type = "colorpicker",
			name = GetString(SI_NBUI_COLOR_LABEL),
			tooltip = GetString(SI_NBUI_COLOR_TOOLTIP),
			getFunc = function() return unpack(NBUI.db.NB1_BookColor) end,
			setFunc = function(r, g, b, a)
				NBUI.db.NB1_BookColor = {r, g, b, a}
				NBUI.NB1MainWindow_Cover:SetColor(r, g, b, a)
				NBUI.NB1MaxChatWin_ButtonTexture:SetColor(r, g, b, a)
				NBUI.NB1MinChatWin_ButtonTexture:SetColor(r, g, b, a)
				end,
			default = { r = NBUI.defaults.NB1_BookColor[1], g = NBUI.defaults.NB1_BookColor[2], b = NBUI.defaults.NB1_BookColor[3], a = NBUI.defaults.NB1_BookColor[4]},
			},								
		[5] = { -- display dialog
			type = "checkbox",
			name = GetString(SI_NBUI_DIALOG),
			tooltip = GetString(SI_NBUI_DIALOG_TOOLTIP),
			getFunc = function() return NBUI.db.NB1_ShowDialog end,
			setFunc = function(value)
				NBUI.db.NB1_ShowDialog = value
					-- NBUI.NB1SavePage_Button:SetHandler("OnClicked", function(self)
					-- 	if (NBUI.db.NB1_ShowDialog) then
					-- 		ZO_Dialogs_ShowDialog("CONFIRM_NBUI_SAVE")
					-- 	else
					-- 		NBUI.NB1SavePage(self)
					-- 	end			
					-- end)
					-- NBUI.NB1UndoPage_Button:SetHandler("OnClicked", function()
					-- 	if (NBUI.db.NB1_ShowDialog) then
					-- 		ZO_Dialogs_ShowDialog("CONFIRM_NBUI_UNDO")
					-- 	else
					-- 		NBUI.NB1UndoPage()
					-- 	end			
					-- end)
					-- NBUI.NB1DeletePage_Button:SetHandler("OnClicked", function()
					-- 	if (NBUI.db.NB1_ShowDialog) then
					-- 		ZO_Dialogs_ShowDialog("CONFIRM_NBUI_DELETE")
					-- 	else
					-- 		NBUI.NB1DeletePage()
					-- 	end			
					-- end)
					-- NBUI.NB1NewPage_Button:SetHandler("OnClicked", function(self)
					-- 	if (NBUI.db.NB1_ShowDialog) then
					-- 		ZO_Dialogs_ShowDialog("CONFIRM_NBUI_NEWPAGE")
					-- 	else
					-- 		NBUI.NB1NewPage(self)
					-- 	end			
					-- end)					
				end,
			default = NBUI.defaults.NB1_ShowDialog,
			},
		[6]={ -- lock position
			type = "checkbox",
			name = GetString(SI_NBUI_LOCK_LABEL),
			tooltip = GetString(SI_NBUI_LOCK_TOOLTIP),
			getFunc = function() return NBUI.db.NB1_Locked end,
			setFunc = function(value)
				NBUI.db.NB1_Locked = value
				NBUI.NB1MainWindow:SetMovable(not NBUI.db.NB1_Locked)
				end,
			default = NBUI.defaults.NB1_Locked,
			},
		[7]={ -- toggle chat button
			type = "checkbox",
			name =  GetString(SI_NBUI_BUTTON_LABEL),
			tooltip = GetString(SI_NBUI_BUTTON_TOOLTIP),
			getFunc = function() return NBUI.db.NB1_ChatButton end,
			setFunc = function(value) 
				NBUI.db.NB1_ChatButton = value 
				NBUI.NB1MaxChatWin_Button:SetHidden(not NBUI.db.NB1_ChatButton)
				NBUI.NB1MaxChatWin_ButtonTexture:SetHidden(not NBUI.db.NB1_ChatButton)
				NBUI.NB1MinChatWin_Button:SetHidden(not NBUI.db.NB1_ChatButton)
				NBUI.NB1MinChatWin_ButtonTexture:SetHidden(not NBUI.db.NB1_ChatButton) 
				end,
			default = NBUI.defaults.NB1_ChatButton,
			},
		[8]={ -- offset man chat button
			type = "slider",
			name = GetString(SI_NBUI_OFFSETMAX_LABEL),
			tooltip = GetString(SI_NBUI_OFFSETMAX_TOOLTIP),
			min = -300,
			max = -40,
			step = 1,
			getFunc = function() return NBUI.db.NB1_MaxOffsetChatButton end,
			setFunc = function(offset)
				if (NBUI.db.NB1_ChatButton) then
					NBUI.db.NB1_MaxOffsetChatButton = offset
					NBUI.NB1MaxChatWin_Button:SetAnchor(TOPRIGHT, ZO_ChatWindow, TOPRIGHT, NBUI.db.NB1_MaxOffsetChatButton, 7)
				end
			end,						
			disabled = function()
				return not NBUI.db.NB1_ChatButton
			end,
			default = NBUI.defaults.NB1_MaxOffsetChatButton,
			},
		[9]={ -- offset min chat button
			type = "slider",
			name = GetString(SI_NBUI_OFFSETMIN_LABEL),
			tooltip = GetString(SI_NBUI_OFFSETMIN_TOOLTIP),
			min = -400,
			max = 0,
			step = 1,
			getFunc = function() return NBUI.db.NB1_MinOffsetChatButton end,
			setFunc = function(offset)
				if (NBUI.db.NB1_ChatButton) then
					NBUI.db.NB1_MinOffsetChatButton = offset
					NBUI.NB1MinChatWin_Button:SetAnchor(BOTTOMLEFT, ZO_ChatWindowMinBar, BOTTOMLEFT, -3, NBUI.db.NB1_MinOffsetChatButton)
				end
			end,						
			disabled = function()
				return not NBUI.db.NB1_ChatButton
			end,
			default = NBUI.defaults.NB1_MinOffsetChatButton,
			},
		[10]={ -- Switch to Edit Mode on mouse hover over page.
			type = "checkbox",
			name = "EditModeHover",
			tooltip = "Switch to page Edit Mode when mouse hovers over the page.",
			getFunc = function() return NBUI.db.NB1_EditModeHover end,
			setFunc = function(v) NBUI.db.NB1_EditModeHover = v end,
		},
		[11]={ -- Switch to Edit Mode on mouse click on page.
			type = "checkbox",
			name = "EditModeClick",
			tooltip = "Switch to page Edit Mode when clicking the page.",
			getFunc = function() return NBUI.db.NB1_EditModeClick end,
			setFunc = function(v) NBUI.db.NB1_EditModeClick = v end,
		},
		[12]={ -- Leave Edit Mode on page lose focus.
			type = "checkbox",
			name = "LeaveEditModeFocus",
			tooltip = "Leave Edit Mode when the page loses focus (clicking outside of it.)",
			getFunc = function() return NBUI.db.NB1_LeaveEditModeOnFocus end,
			setFunc = function(v) NBUI.db.NB1_LeaveEditModeOnFocus = v end,
		},
		[13]={ -- Leave Edit Mode on mouse exit page.
			type = "checkbox",
			name = "LeaveEditModeExit",
			tooltip = "Leave Edit Mode when mouse exits (moves out of) the page.",
			getFunc = function() return NBUI.db.NB1_LeaveEditModeOnExit end,
			setFunc = function(v) NBUI.db.NB1_LeaveEditModeOnExit = v end,
		},
	}
	LAM2:RegisterOptionControls("NBUIOptions", optionsData)
end