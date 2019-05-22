local PersonalTimer = {
	--Metadata
	name = "PersonalTimer2018",
	readableName = "Personal Timer 2018",
	version = "1.0",
	author = "lazeeman0 & phuein",
	settingsVersion = 1,
	
	--Slash command
	slashCommand = "/pt",
	
	--Display Formats
	displayFormats = {
		[1] = "SS.m",
		[2] = "MM:SS.m",
		[3] = "HH:MM:SS.m",
	},
	displayValues = {
		[1] = "%0.2fs",
		[2] = "%02d:%02d.%.02s",
		[3] = "%02d:%02d:%02d.%.02s",
	},
	
	--right mouse actions for when the mouse is enabled
	rightMouseActions = {
		reset = "Reset",
		restart = "Restart",
	},
	
	--Variables
	prefix = "Timer: ",
	postfix = "",
	startTime = 0,
	currentTime = 0,
	currentEllapsedSeconds = 0,
	running = false,
}

-- Default values for saved variables
local defaults = {
	left = 100,
	top = 100,
	displayFormat = PersonalTimer.displayFormats.seconds,
	locked = false,
	enableMouseActions = false,
	rightMouseAction = PersonalTimer.rightMouseActions.reset,
	displayFont = "ZoFontWinH5",
}

-- Register LibAddonMenu
local LAM = LibStub("LibAddonMenu-2.0")

-- Build the settings menu
function PersonalTimer.BuildSettingsMenu()
	local panelData = {
		type = "panel",
		name = PersonalTimer.readableName,
		displayName = PersonalTimer.readableName,
		author = PersonalTimer.author,
		version = PersonalTimer.version,
		slashCommand = PersonalTimer.slashCommand,	--(optional) will register a keybind to open to this panel
		registerForRefresh = true,
	}
	
	local optionsTable = {
		[1] = {
			type = "dropdown",
			name = "Display format",
			tooltip = "The timer display format.",
			choices = {
				PersonalTimer.displayFormats.seconds,
				PersonalTimer.displayFormats.minutes,
				PersonalTimer.displayFormats.hours
			},
			getFunc = function() return PersonalTimer.savedVariables.displayFormat end,
			setFunc = function(df)
				PersonalTimer.savedVariables.displayFormat = df
				PersonalTimer.UpdateDisplayType(PersonalTimer.running)
			end,
		},
		[2] = {
			type = "checkbox",
			name = "Enable mouse actions",
			tooltip = "Enable's mouse actions on the timer:\n\nleft mouse button -> start/pause\nright mouse button -> reset/restart timer\nmiddle mouse button -> toggle format",
			getFunc = function() return PersonalTimer.savedVariables.enableMouseActions end,
			setFunc = function(value)
				PersonalTimer.savedVariables.enableMouseActions = value
				if value then
					PersonalTimer.savedVariables.locked = true
					PersonalTimerUI:SetMovable(false)
				end
			end,
			warning = "When enabling, timer will be locked automatically.",	--(optional)
		},
		[3] = {
			type = "dropdown",
			name = "Right mouse button action",
			tooltip = "What clicking the right mouse button on the timer will do",
			choices = {
				PersonalTimer.rightMouseActions.reset,
				PersonalTimer.rightMouseActions.restart,
			},
			getFunc = function() return PersonalTimer.savedVariables.rightMouseAction end,
			setFunc = function(value)
				PersonalTimer.savedVariables.rightMouseAction = value
			end,
			disabled = function() return not PersonalTimer.savedVariables.enableMouseActions end,
		},
		[4] = {
			type = "checkbox",
			name = "Lock timer position",
			tooltip = "Lock the timer's position on the screen",
			getFunc = function() return PersonalTimer.savedVariables.locked end,
			setFunc = function(value) 
				PersonalTimer.savedVariables.locked = value
				PersonalTimerUI:SetMovable(not value)
			end,
			disabled = function() return PersonalTimer.savedVariables.enableMouseActions end,
		},
		-- [5] = {
			-- type = "dropdown",
			-- name = "Display Size",
			-- tooltip = "The timer display text size.",
			-- choices = {
				-- "ZoFontWinH1",
				-- "ZoFontWinH2",
				-- "ZoFontWinH3",
				-- "ZoFontWinH4",
				-- "ZoFontWinH5"
			-- },
			-- getFunc = function() return PersonalTimer.savedVariables.displayFont end,
			-- setFunc = function(font)
				-- PersonalTimer.savedVariables.displaySize = font
				-- --UpdateDisplayType(PersonalTimer.running)
				-- PersonalTimerUICounter:SetFont(font)
			-- end,
		-- },
	}
	
	LAM:RegisterAddonPanel("PersonalTimerSettingsMenu", panelData)
	LAM:RegisterOptionControls("PersonalTimerSettingsMenu", optionsTable)	
end

function PersonalTimer.UpdateDisplayType(running)
	-- Seconds.
	if PersonalTimer.savedVariables.displayFormat == 1 then
		PersonalTimerUICounter:SetText(PersonalTimer.prefix .. string.format("", seconds) .. PersonalTimer.postfix)
	-- Minutes.
	elseif PersonalTimer.savedVariables.displayFormat == 2 then
		local obj = PersonalTimer.secondsToTime(seconds)
		PersonalTimerUICounter:SetText(PersonalTimer.prefix .. 
			string.format("", obj.h, obj.m, obj.s, tonumber(obj.milli)) .. 
			PersonalTimer.postfix)
	-- Hours.
	else
		local obj = PersonalTimer.secondsToTime(seconds)
		PersonalTimerUICounter:SetText(PersonalTimer.prefix .. 
			string.format("", obj.h, obj.m, obj.s, tonumber(obj.milli)) .. 
			PersonalTimer.postfix)
	end



	if PersonalTimer.savedVariables.displayFormat == PersonalTimer.displayFormats.seconds then
		PersonalTimer.showTimeFunction = function(seconds)
			PersonalTimer.displaySeconds(seconds)
		end		
	else
		PersonalTimer.showTimeFunction = function(seconds)
			PersonalTimer.displayTime(seconds)
		end
	end
	
	if not running then
		PersonalTimer.showTimeFunction(PersonalTimer.currentEllapsedSeconds);
	end
end

function PersonalTimer.secondsToTime(seconds)
	local obj = {}
	
	if seconds <= 0 then
		obj.h = 0
		obj.m = 0
		obj.s = 0
		obj.milli = 0
	else
		-- extract milliseconds
		local secs = math.floor(seconds)
		local milli = math.floor((seconds - secs) * 1000)
	
		-- extract hours
		local hours = math.floor(secs / 3600)
		
		--extract minutes
		local minutes = math.floor((secs / 60) % 60)
	 
		-- extract seconds
		local seconds = math.floor(secs % 60)
	 
		--create the final array
		obj.h = hours
		obj.m = minutes
		obj.s = seconds
		obj.milli = milli
	end
	
	return obj
end

function PersonalTimer.PersonalTimerUpdate()
	if PersonalTimer.running then
		local delta = GetFrameDeltaTimeSeconds()
		
		PersonalTimer.currentEllapsedSeconds = PersonalTimer.currentEllapsedSeconds + delta
		PersonalTimer.showTimeFunction(PersonalTimer.currentEllapsedSeconds)
	end
end

function PersonalTimer.RestorePosition()	
	PersonalTimerUI:ClearAnchors()
	PersonalTimerUI:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, PersonalTimer.savedVariables.left, PersonalTimer.savedVariables.top);
	PersonalTimerUI:SetHandler("OnUpdate", function() PersonalTimer.PersonalTimerUpdate() end)
	PersonalTimerUI:SetHandler("OnMoveStop", function() PersonalTimer.PersonalTimerMoveStop() end)
	PersonalTimerUI:SetHandler("OnMouseUp", function(event, button, ctrl, alt, sshift, command) PersonalTimer.PersonalTimerProcessMouseUp(event, button, ctrl, alt, sshift, command) end)
end

function PersonalTimer.ToggleDisplayType()
	if PersonalTimer.savedVariables.displayFormat == PersonalTimer.displayFormats.seconds then
		PersonalTimer.savedVariables.displayFormat = PersonalTimer.displayFormats.hours
	else
		PersonalTimer.savedVariables.displayFormat = PersonalTimer.displayFormats.seconds
	end
	
	PersonalTimer.UpdateDisplayType(PersonalTimer.running)
end

function PersonalTimer.PersonalTimerProcessMouseUp(event, button, ctrl, alt, sshift, command)
	if WINDOW_MANAGER:GetMouseOverControl() == WINDOW_MANAGER:GetControlByName("PersonalTimerUI", "") then
		if PersonalTimer.savedVariables.enableMouseActions and PersonalTimer.savedVariables.locked then
			if button == 1 then
				PersonalTimer_ProcessStartPause()
			elseif button == 2 then
				if PersonalTimer.savedVariables.rightMouseAction == PersonalTimer.rightMouseActions.reset then
					PersonalTimer_ProcessReset()
				else
					PersonalTimer_ProcessRestart()
				end
			elseif button == 3 then
				-- PersonalTimer.ToggleDisplayType()
			end
		end
	end
end

function PersonalTimer_ProcessStartPause()
	PersonalTimer.running = not PersonalTimer.running
end

function PersonalTimer_ProcessReset()
	PersonalTimer.running = false	
	PersonalTimer.currentEllapsedSeconds = 0
	PersonalTimer.UpdateDisplayType(PersonalTimer.running)
end

function PersonalTimer_ProcessRestart()
	PersonalTimer.currentEllapsedSeconds = 0
	PersonalTimer.running = true
end

function PersonalTimer.PersonalTimerMoveStop()
	PersonalTimer.savedVariables.left = PersonalTimerUI:GetLeft()
	PersonalTimer.savedVariables.top = PersonalTimerUI:GetTop()
end

function PersonalTimer.OnAddOnLoaded(eventCode, addOnName)
	if addOnName == PersonalTimer.name then
		PersonalTimerUIBackdrop:SetAlpha(0.0)
		
		ZO_CreateStringId("SI_BINDING_NAME_PERSONAL_TIMER_START_PAUSE", "Start/Pause Timer")
		ZO_CreateStringId("SI_BINDING_NAME_PERSONAL_TIMER_RESET", "Reset Timer")
		ZO_CreateStringId("SI_BINDING_NAME_PERSONAL_TIMER_RESTART", "Restart Timer")
		
		PersonalTimer.savedVariables = ZO_SavedVars:New("PersonalTimerSavedVariables", 
			PersonalTimer.settingsVersion, nil, defaults, "default")	  	

		PersonalTimer.RestorePosition()
		PersonalTimer.UpdateDisplayType(PersonalTimer.running)
		PersonalTimerUI:SetMovable(not PersonalTimer.savedVariables.locked)
		PersonalTimerUICounter:SetFont(PersonalTimer.savedVariables.displayFont)
		
		PersonalTimer.BuildSettingsMenu()
	end
end

EVENT_MANAGER:RegisterForEvent(PersonalTimer.name, EVENT_ADD_ON_LOADED, PersonalTimer.OnAddOnLoaded)

-- Needed to bind CTRL/Shift+KEY.
function KEYBINDING_MANAGER:IsChordingAlwaysEnabled()
	return true
end