function CreateNBUISettings()
	local LAM = LibStub("LibAddonMenu-2.0")
	local panelData = {
        type = "panel",
        name = "Notebook 2018",
		displayName = ZO_HIGHLIGHT_TEXT:Colorize(GetString(SI_NBUI_ADDONOPTIONS_NAME)),
		author = GetString(SI_NBUI_AUTHOR),
		registerForRefresh  = true,
		registerForDefaults = true,
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
	LAM:RegisterAddonPanel("NBUIOptions", panelData)

	local optionsData = {}

	-- Book category. --
	table.insert(optionsData, {
		type = "header",
		name = ZO_HIGHLIGHT_TEXT:Colorize(GetString(SI_NBUI_HEADER_BOOK)),
	})

	-- Show book title.
	table.insert(optionsData, {
		type = "checkbox",
		name = GetString(SI_NBUI_SHOWTITLE_NAME),
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
		default = NBUI.settings.NB1_ShowTitle,
	})

	-- Title label.
	table.insert(optionsData, {
		type = "editbox",
		name = GetString(SI_NBUI_TITLE_NAME),
		tooltip = GetString(SI_NBUI_TITLE_TOOLTIP),
		getFunc = function() return NBUI.db.NB1_Title end,
		setFunc = function(value)
			NBUI.db.NB1_Title = value
			NBUI.NB1LeftPage_Title:SetText(NBUI.db.NB1_Title)
			end,
		default = NBUI.settings.NB1_Title,
	})

	-- Notebook saves as account-wide.
	table.insert(optionsData, {
		type = "checkbox",
		name = GetString(SI_NBUI_ACCOUNTWIDE_NAME),
		tooltip = GetString(SI_NBUI_ACCOUNTWIDE_TOOLTIP),
		getFunc = function() return NBUI.db.NB1_AccountWide end,
		setFunc = function(value)
			local confirmDialog = {
				title = {text = GetString(SI_NBUI_ACCOUNTWIDE_NAME)},
				mainText = {text = GetString(SI_NBUI_ACCOUNTWIDE_MAINTEXT)},
				buttons = {
					[1]={
						text = GetString(SI_NBUI_YES_LABEL), callback = function()
							NBUI.dbCharacter.NB1_AccountWide = value
							ReloadUI("ingame")
						end
						},
					[2]={
						text = GetString(SI_NBUI_NO_LABEL), callback = function()
							zo_callLater(function() CALLBACK_MANAGER:FireCallbacks("LAM-RefreshPanel", LAM.currentAddonPanel) end, 100)
					end
					}
				}
			}
			ZO_Dialogs_RegisterCustomDialog("NBUI_NB1CONFIRMDIALOG", confirmDialog)
			ZO_Dialogs_ShowDialog("NBUI_NB1CONFIRMDIALOG")
			end,
		default = NBUI.db.NB1_AccountWide,
		warning = "Will need to reload the UI!",
	})

	-- Overwrite the Account-Wide Notebook with the current character's pages.
	-- NOTE: Display only in CharacterWide mode.
	if not NBUI.db.NB1_AccountWide then
		table.insert(optionsData, {
			type = "button",
			name = GetString(SI_NBUI_ACCOUNTDELETE),
			tooltip = GetString(SI_NBUI_ACCOUNTDELETE_TOOLTIP),
			-- disabled = not NBUI.db.NB1_AccountWide,
			func = function(value)
				local confirmDialog = {
					title = {text = GetString(SI_NBUI_ACCOUNTWIDE_NAME)},
					mainText = {text = GetString(SI_NBUI_ACCOUNTWIDE_MAINTEXT)},
					buttons = {
						[1]={
							text = GetString(SI_NBUI_YES_LABEL), callback = function()
								_G["NBUISVDBACCT"]["Default"][GetDisplayName()]["$AccountWide"] =
									ZO_DeepTableCopy(_G["NBUISVDB"]["Default"][GetDisplayName()][GetUnitName("player")])

								ReloadUI("ingame")
							end
							},
						[2]={text = GetString(SI_NBUI_NO_LABEL)}
					}
				}
				ZO_Dialogs_RegisterCustomDialog("NBUI_NB1CONFIRMDIALOG", confirmDialog)
				ZO_Dialogs_ShowDialog("NBUI_NB1CONFIRMDIALOG")
			end,
			warning = "Will need to reload the UI!",
		})
	end

	-- Default new page title.
	table.insert(optionsData, {
		type = "editbox",
		name = GetString(SI_NBUI_NEWPAGETITLE_NAME),
		tooltip = GetString(SI_NBUI_NEWPAGETITLE_TOOLTIP),
		getFunc = function() return NBUI.db.NB1_NewPageTitle end,
		setFunc = function(value)
			NBUI.db.NB1_NewPageTitle = value
			end,
		default = NBUI.settings.NB1_NewPageTitle,
	})

	-- Overwrite the Accountwide or Character Notebook of
	-- another account or character on this machine (PC) from current active Notebook.
	-- TODO: Languages implementation.
	local overwriteAccount, overwriteCharacter

	table.insert(optionsData, {
		type = "submenu",
		name = ZO_HIGHLIGHT_TEXT:Colorize("Overwrite Other Account or Character"),
		controls = {
			[1] = {
				type = "editbox",
				name = "Account Name For Overwrite",
				tooltip = "The account name that will have its Account-Wide Notebook overwritten.",
				getFunc = function() return "" end,
				setFunc = function(value)
					overwriteAccount = value
				end,
				width = "half",
			},
			[2] = {
				type = "button",
				name = "Overwrite Account",
				tooltip = "This will create or overwrite the Account-Wide Notebook of another " ..
									"account on this PC, from the current active Notebook.",
				-- disabled = not NBUI.db.NB1_AccountWide,
				func = function(value)
					-- Must have an account name to overwrite.
					if overwriteAccount == "" then return end

					-- Accounts must start with an @.
					local c = string.sub(overwriteAccount, 1, 1)
					if c ~= "@" then
						overwriteAccount = "@" .. overwriteAccount
					end

					-- Ignore if same as current account.
					if overwriteAccount == GetDisplayName() then return end

					local confirmDialog = {
						title = {text = "Overwrite Other Account"},
						mainText = {text = "Continue?"},
						buttons = {
							[1]={
								text = GetString(SI_NBUI_YES_LABEL), callback = function()
									-- Use active Notebook.
									local t
									if NBUI.db.NB1_AccountWide then
										t = _G["NBUISVDBACCT"]["Default"][GetDisplayName()]["$AccountWide"]
									else
										t = _G["NBUISVDB"]["Default"][GetDisplayName()][GetUnitName("player")]
									end

									-- Create tables. Will only overwrite Account-Wide Notebook, but not individual character.
									if not _G["NBUISVDBACCT"]["Default"][overwriteAccount] then
										_G["NBUISVDBACCT"]["Default"][overwriteAccount]  = {}
									end

									_G["NBUISVDBACCT"]["Default"][overwriteAccount]["$AccountWide"] = ZO_DeepTableCopy(t)

									ReloadUI("ingame")
								end
								},
							[2]={text = GetString(SI_NBUI_NO_LABEL)}
						}
					}
					ZO_Dialogs_RegisterCustomDialog("NBUI_NB1CONFIRMDIALOG", confirmDialog)
					ZO_Dialogs_ShowDialog("NBUI_NB1CONFIRMDIALOG")
				end,
				warning = "Will need to reload the UI!",
			},
			[3] = {
				type = "editbox",
				name = "Character Name For Overwrite",
				tooltip = "The character name that will have its Character-Wide Notebook overwritten.",
				getFunc = function() return "" end,
				setFunc = function(value)
					overwriteCharacter = value
				end,
				width = "half",
			},
			[4] = {
				type = "button",
				name = "Overwrite Character",
				tooltip = "This will create or overwrite the Character-Wide Notebook of another " ..
									"character on this PC, from the current active Notebook.",
				-- disabled = not NBUI.db.NB1_AccountWide,
				func = function(value)
					-- Must have an account name and character name to overwrite.
					if overwriteAccount == "" then return end
					if overwriteCharacter == "" then return end

					-- Accounts must start with an @.
					local c = string.sub(overwriteAccount, 1, 1)
					if c ~= "@" then
						overwriteAccount = "@" .. overwriteAccount
					end

					-- Ignore if same character and account and current.
					-- Allow overwriting between characters of the same account.
					if overwriteAccount == GetDisplayName() and overwriteCharacter == GetUnitName("player") then return end

					local confirmDialog = {
						title = {text = "Overwrite Other Character"},
						mainText = {text = "Continue?"},
						buttons = {
							[1]={
								text = GetString(SI_NBUI_YES_LABEL), callback = function()
									-- Use active Notebook.
									local t
									if NBUI.db.NB1_AccountWide then
										t = _G["NBUISVDBACCT"]["Default"][GetDisplayName()]["$AccountWide"]
									else
										t = _G["NBUISVDB"]["Default"][GetDisplayName()][GetUnitName("player")]
									end

									-- Create tables. Do not overwrite whole table, only character's table.
									if not _G["NBUISVDB"]["Default"][overwriteAccount] then
										_G["NBUISVDB"]["Default"][overwriteAccount]  = {}
									end
									_G["NBUISVDB"]["Default"][overwriteAccount][overwriteCharacter] = ZO_DeepTableCopy(t)

									ReloadUI("ingame")
								end
								},
							[2]={text = GetString(SI_NBUI_NO_LABEL)}
						}
					}
					ZO_Dialogs_RegisterCustomDialog("NBUI_NB1CONFIRMDIALOG", confirmDialog)
					ZO_Dialogs_ShowDialog("NBUI_NB1CONFIRMDIALOG")
				end,
				warning = "Will need to reload the UI!",
			},
		},
	})

	-- Colors category. --
	table.insert(optionsData, {
		type = "header",
		name = ZO_HIGHLIGHT_TEXT:Colorize(GetString(SI_NBUI_HEADER_COLORS)),
	})

	-- Change book color.
	table.insert(optionsData, {
		type = "colorpicker",
		name = GetString(SI_NBUI_COLOR_NAME),
		tooltip = GetString(SI_NBUI_COLOR_TOOLTIP),
		getFunc = function() return unpack(NBUI.db.NB1_BookColor) end,
		setFunc = function(r, g, b, a)
			NBUI.db.NB1_BookColor = {r, g, b, a}
			NBUI.NB1MainWindow_Cover:SetColor(r, g, b, a)
			NBUI.NB1MaxChatWin_ButtonTexture:SetColor(r, g, b, a)
			NBUI.NB1MinChatWin_ButtonTexture:SetColor(r, g, b, a)
			end,
		default = { r = NBUI.settings.NB1_BookColor[1], g = NBUI.settings.NB1_BookColor[2], b = NBUI.settings.NB1_BookColor[3], a = NBUI.settings.NB1_BookColor[4]},
	})

	-- Text color. R, G, B, A. Between 0 to 1.
	table.insert(optionsData, {
		type = "colorpicker",
		name = GetString(SI_NBUI_TEXTCOLOR_NAME),
		tooltip = GetString(SI_NBUI_TEXTCOLOR_TOOLTIP),
		getFunc = function() return unpack(NBUI.db.NB1_TextColor) end,
		setFunc = function(r, g, b, a)
				NBUI.db.NB1_TextColor = {r, g, b, a}
				NBUI.NB1LeftPage_Title:SetColor(unpack(NBUI.db.NB1_TextColor))
				NBUI.NB1LeftPage_Separator:SetColor(unpack(NBUI.db.NB1_TextColor))
				NBUI.NB1RightPage_Title:SetColor(unpack(NBUI.db.NB1_TextColor))
				NBUI.NB1RightPage_Contents:SetColor(unpack(NBUI.db.NB1_TextColor))
				NBUI.NB1RightPage_ContentsLabel:SetColor(unpack(NBUI.db.NB1_TextColor))
				Populate_NB1_ScrollList()
			end,
	})

	-- Selection color. R, G, B, A. Between 0 to 1.
	table.insert(optionsData, {
		type = "colorpicker",
		name = GetString(SI_NBUI_SELECTCOLOR_NAME),
		tooltip = GetString(SI_NBUI_SELECTCOLOR_TOOLTIP),
		getFunc = function() return unpack(NBUI.db.NB1_SelectionColor) end,
		setFunc = function(r, g, b, a)
				NBUI.db.NB1_SelectionColor = {r, g, b, a}
				NBUI.NB1RightPage_Contents:SetSelectionColor(unpack(NBUI.db.NB1_SelectionColor))
			end,
	})

	-- Interactive category. --
	table.insert(optionsData, {
		type = "header",
		name = ZO_HIGHLIGHT_TEXT:Colorize(GetString(SI_NBUI_HEADER_INTERACTIVE)),
	})

	-- Display dialog.
	table.insert(optionsData, {
		type = "checkbox",
		name = GetString(SI_NBUI_DIALOG),
		tooltip = GetString(SI_NBUI_DIALOG_TOOLTIP),
		getFunc = function() return NBUI.db.NB1_ShowDialog end,
		setFunc = function(value)
			NBUI.db.NB1_ShowDialog = value
			end,
		default = NBUI.settings.NB1_ShowDialog,
	})

	-- Lock book position.
	table.insert(optionsData, {
		type = "checkbox",
		name = GetString(SI_NBUI_LOCK_NAME),
		tooltip = GetString(SI_NBUI_LOCK_TOOLTIP),
		getFunc = function() return NBUI.db.NB1_Locked end,
		setFunc = function(value)
			NBUI.db.NB1_Locked = value
			NBUI.NB1MainWindow:SetMovable(not NBUI.db.NB1_Locked)
			end,
		default = NBUI.settings.NB1_Locked,
	})

	-- Toggle chat button.
	table.insert(optionsData, {
		type = "checkbox",
		name =  GetString(SI_NBUI_BUTTON_NAME),
		tooltip = GetString(SI_NBUI_BUTTON_TOOLTIP),
		getFunc = function() return NBUI.db.NB1_ChatButton end,
		setFunc = function(value)
			NBUI.db.NB1_ChatButton = value
			NBUI.NB1MaxChatWin_Button:SetHidden(not NBUI.db.NB1_ChatButton)
			NBUI.NB1MaxChatWin_ButtonTexture:SetHidden(not NBUI.db.NB1_ChatButton)
			NBUI.NB1MinChatWin_Button:SetHidden(not NBUI.db.NB1_ChatButton)
			NBUI.NB1MinChatWin_ButtonTexture:SetHidden(not NBUI.db.NB1_ChatButton)
			end,
		default = NBUI.settings.NB1_ChatButton,
	})

	-- Opened-chat button offset.
	table.insert(optionsData, {
		type = "slider",
		name =  GetString(SI_NBUI_OFFSETMAX_NAME),
		tooltip = GetString(SI_NBUI_OFFSETMAX_TOOLTIP),
		min = -180,
		max = 40,
		step = 1,	--(optional)
		disabled = function() return not NBUI.db.NB1_ChatButton end,
		getFunc = function() return NBUI.db.NB1_ChatButton_Max_Offset end,
		setFunc = function(value)
			NBUI.db.NB1_ChatButton_Max_Offset = value
			-- Anchoring must be done the same way as the original!
			NBUI.NB1MaxChatWin_Button:ClearAnchors()
			NBUI.NB1MaxChatWin_Button:SetAnchor(CENTER, ZO_ChatWindowOptions, CENTER, -30 + NBUI.db.NB1_ChatButton_Max_Offset, 1)
		end,
		default = NBUI.settings.NB1_ChatButton_Max_Offset,
})

	-- Closed-chat button offset.
	table.insert(optionsData, {
		type = "slider",
		name =  GetString(SI_NBUI_OFFSETMIN_NAME),
		tooltip = GetString(SI_NBUI_OFFSETMIN_TOOLTIP),
		min = -100,
		max = 220,
		step = 1,	--(optional)
		disabled = function() return not NBUI.db.NB1_ChatButton end,
		getFunc = function() return NBUI.db.NB1_ChatButton_Min_Offset end,
		setFunc = function(value)
			NBUI.db.NB1_ChatButton_Min_Offset = value
			-- Anchoring must be done the same way as the original!
			NBUI.NB1MinChatWin_Button:ClearAnchors()
			NBUI.NB1MinChatWin_Button:SetAnchor(TOPLEFT, ZO_ChatWindowMinBar, nil, 0, 230 + NBUI.db.NB1_ChatButton_Min_Offset)
		end,
		default = NBUI.settings.NB1_ChatButton_Min_Offset,
})

	-- Display Text-Formatting mode over Editbox, at all.
	table.insert(optionsData, {
		type = "checkbox",
		name = GetString(SI_NBUI_FORMATTEDMODE_NAME),
		tooltip = GetString(SI_NBUI_FORMATTEDMODE_TOOLTIP),
		getFunc = function() return NBUI.db.NB1_FormattedMode end,
		setFunc = function(v)
			NBUI.db.NB1_FormattedMode = v
			if v then
				NBUI.NB1RightPage_ContentsLabel:SetHidden(false)
				NBUI.NB1RightPage_Contents:SetHidden(true)
			else
				NBUI.NB1RightPage_ContentsLabel:SetHidden(true)
				NBUI.NB1RightPage_Contents:SetHidden(false)
			end
		end,
	})

	-- Switch to Edit Mode on mouse hover over page.
	table.insert(optionsData, {
		type = "checkbox",
		name = GetString(SI_NBUI_EDITMODE_HOVER_NAME),
		tooltip = GetString(SI_NBUI_EDITMODE_HOVER_TOOLTIP),
		getFunc = function() return NBUI.db.NB1_EditModeHover end,
		setFunc = function(v) NBUI.db.NB1_EditModeHover = v end,
	})

	-- Switch to Edit Mode on mouse click on page.
	table.insert(optionsData, {
		type = "checkbox",
		name = GetString(SI_NBUI_EDITMODE_CLICK_NAME),
		tooltip = GetString(SI_NBUI_EDITMODE_CLICK_TOOLTIP),
		getFunc = function() return NBUI.db.NB1_EditModeClick end,
		setFunc = function(v) NBUI.db.NB1_EditModeClick = v end,
	})

	-- Leave Edit Mode on page lose focus.
	table.insert(optionsData, {
		type = "checkbox",
		name = GetString(SI_NBUI_LEAVEEDITMODE_FOCUS_NAME),
		tooltip = GetString(SI_NBUI_LEAVEEDITMODE_FOCUS_TOOLTIP),
		getFunc = function() return NBUI.db.NB1_LeaveEditModeOnFocus end,
		setFunc = function(v) NBUI.db.NB1_LeaveEditModeOnFocus = v end,
	})

	-- Leave Edit Mode on mouse exit page.
	table.insert(optionsData, {
		type = "checkbox",
		name = GetString(SI_NBUI_LEAVEEDITMODE_EXIT_NAME),
		tooltip = GetString(SI_NBUI_LEAVEEDITMODE_EXIT_TOOLTIP),
		getFunc = function() return NBUI.db.NB1_LeaveEditModeOnExit end,
		setFunc = function(v) NBUI.db.NB1_LeaveEditModeOnExit = v end,
	})

	-- Emote /read when opening the Notebook.
	table.insert(optionsData, {
		type = "checkbox",
		name = GetString(SI_NBUI_EMOTEREAD_NAME),
		tooltip = GetString(SI_NBUI_EMOTEREAD_TOOLTIP),
		getFunc = function() return NBUI.db.NB1_EmoteRead end,
		setFunc = function(v) NBUI.db.NB1_EmoteRead = v end,
	})

	-- Emote /idle after closing the Notebook.
	table.insert(optionsData, {
		type = "checkbox",
		name = GetString(SI_NBUI_EMOTEIDLE_NAME),
		tooltip = GetString(SI_NBUI_EMOTEIDLE_TOOLTIP),
		getFunc = function() return NBUI.db.NB1_EmoteIdle end,
		setFunc = function(v) NBUI.db.NB1_EmoteIdle = v end,
	})

	-- Select line by triple-clicking.
	table.insert(optionsData, {
		type = "checkbox",
		name = GetString(SI_NBUI_SELECTLINE_NAME),
		tooltip = GetString(SI_NBUI_SELECTLINE_TOOLTIP),
		getFunc = function() return NBUI.db.NB1_SelectLine end,
		setFunc = function(v) NBUI.db.NB1_SelectLine = v end,
	})

	-- Double-clicking selects whole page text.
	table.insert(optionsData, {
		type = "checkbox",
		name = GetString(SI_NBUI_DBLCLICKPAGE_NAME),
		tooltip = GetString(SI_NBUI_DBLCLICKPAGE_TOOLTIP),
		getFunc = function() return NBUI.db.NB1_DoubleClickSelectPage end,
		setFunc = function(v) NBUI.db.NB1_DoubleClickSelectPage = v end,
	})

	LAM:RegisterOptionControls("NBUIOptions", optionsData)
end