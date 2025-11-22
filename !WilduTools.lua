local _, ns = ...
local addon = ns.Addon

-- Load modules

local DEBUG = ns.DEBUG
local API = ns.API

local ActionBars = ns.ActionBars
local Addons = ns.Addons
local Automation = ns.Automation
local CooldownManager = ns.CooldownManager
local CVars = ns.CVars
local Minimap = ns.Minimap
local Nameplates = ns.Nameplates
local UI = ns.UI
local UTM = ns.UTM
local WilduUI = ns.WilduUI

local runner = nil

-- Start file read timer
DEBUG.startDebugTimer("FILE_START_TIME")

-- helper to check enabled settings (file scope so event handlers can use it)
local function isEnabled(key)
	if not addon or not addon.db or not addon.db.profile then
		return false
	end
	local v = addon.db.profile[key]
	return v ~= false and v ~= nil
end

DEBUG.startDebugTimer("PLAYER_LOGIN_FRAME_INIT")
local PlayerLoginFrame = CreateFrame("Frame", nil, UIParent)
PlayerLoginFrame:RegisterEvent("PLAYER_LOGIN")
PlayerLoginFrame:SetScript("OnEvent", function()
    DEBUG.startDebugTimer("PLAYER_LOGIN_EVENT_START")
	Automation:InitializeGossips()
	Automation:InitAutoAcceptRole()
	Automation:InitAutoAcceptGroupInvite()
    DEBUG.checkpointDebugTimer("PLAYER_LOGIN_EVENT_AUTOMATION_DONE", "PLAYER_LOGIN_EVENT_START")

	C_Timer.After(1, function()
        DEBUG.startDebugTimer("PLAYER_LOGIN_DELAYED_START")
		WilduUI.InitializeRangeFrame()
		WilduUI.InitializeMountableAreaIndicator()
		WilduUI.InitializeCrosshair()
		WilduUI.InitializeTargetCombatIndicator()
		WilduUI.InitializePlayerCombatIndicator()
		if not InCombatLockdown() then
			if isEnabled("general_alwaysEnableAllActionBars") then
				CVars.enableAllActionBars()
			end
		end
        DEBUG.checkpointDebugTimer("PLAYER_LOGIN_DELAYED_DONE", "PLAYER_LOGIN_DELAYED_START")
	end)
    DEBUG.checkpointDebugTimer("PLAYER_LOGIN_EVENT_END", "PLAYER_LOGIN_EVENT_START")
end)
DEBUG.checkpointDebugTimer("PLAYER_LOGIN_FRAME_INIT_DONE", "PLAYER_LOGIN_FRAME_INIT")

DEBUG.startDebugTimer("INTERFACE_SCALE_FRAME_INIT")
local InterfaceScaleFrame = CreateFrame("Frame", nil, UIParent)
-- InterfaceScaleFrame:RegisterEvent("VARIABLES_LOADED")
InterfaceScaleFrame:RegisterEvent("PLAYER_LOGIN")
-- InterfaceScaleFrame:RegisterEvent("UI_SCALE_CHANGED")
InterfaceScaleFrame:SetScript("OnEvent", function()
    DEBUG.startDebugTimer("INTERFACE_SCALE_EVENT_START")
	CVars.setInterfaceScale()
	if isEnabled("blizzUI_chatTooltipOnChatLinks") then
		pcall(function()
			UI.TooltipChatLinks()
		end)
	end
	-- TODO do module function
	-- CHAT_FRAME_BUTTON_FRAME_MIN_ALPHA = 1.0
	-- CHAT_FRAME_TAB_SELECTED_MOUSEOVER_ALPHA = 1.0
	-- CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA = 1.0
	CHAT_FRAME_TAB_ALERTING_MOUSEOVER_ALPHA = 1.0
	CHAT_FRAME_TAB_ALERTING_NOMOUSE_ALPHA = 1.0
	-- CHAT_FRAME_TAB_NORMAL_MOUSEOVER_ALPHA = 1.0
	-- CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA = 1.0
	
    DEBUG.checkpointDebugTimer("INTERFACE_SCALE_EVENT_END", "INTERFACE_SCALE_EVENT_START")
end)
DEBUG.checkpointDebugTimer("INTERFACE_SCALE_FRAME_INIT_DONE", "INTERFACE_SCALE_FRAME_INIT")

DEBUG.startDebugTimer("INIT_FRAME_INIT")
local InitFrame = CreateFrame("Frame", nil, UIParent)
InitFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
InitFrame:SetScript("OnEvent", function()
    DEBUG.startDebugTimer("INIT_FRAME_EVENT_START")
	C_Timer.After(1, function()
        DEBUG.startDebugTimer("INIT_FRAME_DELAYED_START")
		Addons.scaleAddOnsSize()
		Addons.checkForWAModels()
		
		ns.ControlBehavior.FreeRightClickMove:Init()
        
		-- DEBUG.checkpointDebugTimer("INIT_FRAME_DELAYED_ADDONS_DONE", "INIT_FRAME_DELAYED_START")
		
		if isEnabled("blizzUI_addCastTimeTextOutline") then UI.addCastTimeTextOutline() end
		if isEnabled("blizzUI_altPowerBarText") then UI.enhanceAltPowerBarStatusText() end
		if isEnabled("blizzUI_changeFriendlyNamesFont") then UI.changeFriendlyNamesFonts() end
		if isEnabled("blizzUI_cleanupObjectiveTracker") then UI.cleanupObjectiveTracker() end
		if isEnabled("blizzUI_enchanceUIErrorFrame") then UI.enhanceUIErrorFrame() end
		if isEnabled("blizzUI_expandFriendListHeight") then UI.expandFriendListHeight() end
		if isEnabled("blizzUI_hideBagsFrames") then UI.hideBlizzardBagAndReagentFrames() end
		if isEnabled("blizzUI_hideScreenshotText") then UI.hideScreenshotText() end
		
		if isEnabled("blizzUI_resizeBlizzardObjectiveTracker") then UI.resizeBlizzardObjectiveTracker(addon.db.profile["blizzUI_resizeBlizzardObjectiveTrackerRange"]) end
		DEBUG.checkpointDebugTimer("INIT_FRAME_DELAYED_UI_TWEAKS_DONE", "INIT_FRAME_DELAYED_START")
		
		if isEnabled("actionBars_disableMouseOnActionBars") and (InCombatLockdown() or not isEnabled("actionBars_disableMouseOnActionBars_onlyInCombat")) then

			if isEnabled("actionBars_disable_mouse_ActionButton") then ns.ActionBars.disableMouseOnBar("ActionButton") else ns.ActionBars.enableMouseOnBar("ActionButton") end
			if isEnabled("actionBars_disable_mouse_MultiBarBottomLeftButton") then ns.ActionBars.disableMouseOnBar("MultiBarBottomLeftButton") else ns.ActionBars.enableMouseOnBar("MultiBarBottomLeftButton") end
			if isEnabled("actionBars_disable_mouse_MultiBarBottomRightButton") then ns.ActionBars.disableMouseOnBar("MultiBarBottomRightButton") else ns.ActionBars.enableMouseOnBar("MultiBarBottomRightButton") end
			if isEnabled("actionBars_disable_mouse_MultiBarLeftButton") then ns.ActionBars.disableMouseOnBar("MultiBarLeftButton") else ns.ActionBars.enableMouseOnBar("MultiBarLeftButton") end
			if isEnabled("actionBars_disable_mouse_MultiBarRightButton") then ns.ActionBars.disableMouseOnBar("MultiBarRightButton") else ns.ActionBars.enableMouseOnBar("MultiBarRightButton") end
			if isEnabled("actionBars_disable_mouse_MultiBar5Button") then ns.ActionBars.disableMouseOnBar("MultiBar5Button") else ns.ActionBars.enableMouseOnBar("MultiBar5Button") end
			if isEnabled("actionBars_disable_mouse_MultiBar6Button") then ns.ActionBars.disableMouseOnBar("MultiBar6Button") else ns.ActionBars.enableMouseOnBar("MultiBar6Button") end
			if isEnabled("actionBars_disable_mouse_MultiBar7Button") then ns.ActionBars.disableMouseOnBar("MultiBar7Button") else ns.ActionBars.enableMouseOnBar("MultiBar7Button") end
		else
			ns.ActionBars.enableMouseOnBar("ActionButton")
			ns.ActionBars.enableMouseOnBar("MultiBarBottomLeftButton")
			ns.ActionBars.enableMouseOnBar("MultiBarBottomRightButton")
			ns.ActionBars.enableMouseOnBar("MultiBarLeftButton")
			ns.ActionBars.enableMouseOnBar("MultiBarRightButton")
			ns.ActionBars.enableMouseOnBar("MultiBar5Button")
			ns.ActionBars.enableMouseOnBar("MultiBar6Button")
			ns.ActionBars.enableMouseOnBar("MultiBar7Button")
		end
		if not InCombatLockdown() then
			
			if isEnabled("actionBars_disableMouseOnExtraActionBar")  then
				ActionBars.disableMouseOnExtraActionBarArt()
			end
		end
        DEBUG.checkpointDebugTimer("INIT_FRAME_DELAYED_ACTIONBARS_DONE", "INIT_FRAME_DELAYED_UI_TWEAKS_DONE")
	end)
    DEBUG.checkpointDebugTimer("INIT_FRAME_EVENT_END", "INIT_FRAME_EVENT_START")
end)

DEBUG.startDebugTimer("COMBAT_FRAME_INIT")
local CombatFrame = CreateFrame("Frame")
CombatFrame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Fired when you enter combat
CombatFrame:RegisterEvent("PLAYER_REGEN_ENABLED") -- Fired when you leave combat
CombatFrame:SetScript("OnEvent", function(_self, event)
    DEBUG.startDebugTimer("COMBAT_FRAME_EVENT_START")
	if event == "PLAYER_REGEN_DISABLED" then
		-- entering combat
		if isEnabled("automation_druidFormCombatPreservation") then
			Automation:SetFormPreservation(true)
		end
		if isEnabled("actionBars_disableMouseOnActionBars") and isEnabled("actionBars_disableMouseOnActionBars_onlyInCombat") then
			if isEnabled("actionBars_disable_mouse_ActionButton") then ns.ActionBars.disableMouseOnBar("ActionButton") else ns.ActionBars.enableMouseOnBar("ActionButton") end
			if isEnabled("actionBars_disable_mouse_MultiBarBottomLeftButton") then ns.ActionBars.disableMouseOnBar("MultiBarBottomLeftButton") else ns.ActionBars.enableMouseOnBar("MultiBarBottomLeftButton") end
			if isEnabled("actionBars_disable_mouse_MultiBarBottomRightButton") then ns.ActionBars.disableMouseOnBar("MultiBarBottomRightButton") else ns.ActionBars.enableMouseOnBar("MultiBarBottomRightButton") end
			if isEnabled("actionBars_disable_mouse_MultiBarLeftButton") then ns.ActionBars.disableMouseOnBar("MultiBarLeftButton") else ns.ActionBars.enableMouseOnBar("MultiBarLeftButton") end
			if isEnabled("actionBars_disable_mouse_MultiBarRightButton") then ns.ActionBars.disableMouseOnBar("MultiBarRightButton") else ns.ActionBars.enableMouseOnBar("MultiBarRightButton") end
			if isEnabled("actionBars_disable_mouse_MultiBar5Button") then ns.ActionBars.disableMouseOnBar("MultiBar5Button") else ns.ActionBars.enableMouseOnBar("MultiBar5Button") end
			if isEnabled("actionBars_disable_mouse_MultiBar6Button") then ns.ActionBars.disableMouseOnBar("MultiBar6Button") else ns.ActionBars.enableMouseOnBar("MultiBar6Button") end
			if isEnabled("actionBars_disable_mouse_MultiBar7Button") then ns.ActionBars.disableMouseOnBar("MultiBar7Button") else ns.ActionBars.enableMouseOnBar("MultiBar7Button") end
		end

	elseif event == "PLAYER_REGEN_ENABLED" then
		-- leaving combat
		if not InCombatLockdown() then
			if isEnabled("automation_druidFormCombatPreservation") then
				Automation:SetFormPreservation(false)
			end
			if isEnabled("actionBars_disableMouseOnActionBars_onlyInCombat") then
				ns.ActionBars.enableMouseOnBar("ActionButton")
				ns.ActionBars.enableMouseOnBar("MultiBarBottomLeftButton")
				ns.ActionBars.enableMouseOnBar("MultiBarBottomRightButton")
				ns.ActionBars.enableMouseOnBar("MultiBarLeftButton")
				ns.ActionBars.enableMouseOnBar("MultiBarRightButton")
				ns.ActionBars.enableMouseOnBar("MultiBar5Button")
				ns.ActionBars.enableMouseOnBar("MultiBar6Button")
				ns.ActionBars.enableMouseOnBar("MultiBar7Button")
			end
			if isEnabled("actionBars_disableMouseOnExtraActionBar") then ActionBars.disableMouseOnExtraActionBarArt() end
			if isEnabled("general_alwaysEnableAllActionBars") then
				CVars.enableAllActionBars()
			end
		end
	end
    DEBUG.checkpointDebugTimer("COMBAT_FRAME_EVENT_END", "COMBAT_FRAME_EVENT_START")
end)
DEBUG.checkpointDebugTimer("COMBAT_FRAME_INIT_DONE", "COMBAT_FRAME_INIT")

local secondThrotthle = GetTime() + 10 -- throttle to avoid errors on world loading
local lastTimeSwim = 0
local UpdateFrameLastUpdate = nil

DEBUG.startDebugTimer("UPDATE_FRAME_INIT")
local UpdateFrame = CreateFrame("Frame")
UpdateFrame:SetScript("OnUpdate", function()
    DEBUG.startDebugTimer("UPDATE_FRAME_ONUPDATE_START", "UPDATE_FRAME_INIT")
	
    -- DEBUG.checkpointDebugTimer("UPDATE_FRAME_ONUPDATE_EXPANSION_CHECK_DONE", "UPDATE_FRAME_ONUPDATE_START")

	if IsSwimming() then
		lastTimeSwim = GetTime()
	end
	if isEnabled("automation_druidCancelTravelFormEnabled") and secondThrotthle + 0.75 < GetTime() then
		secondThrotthle = GetTime()
		local flyingSpeed = ({GetUnitSpeed("player")})[3] or 0
		if not UnitAffectingCombat("player")
			and (not (C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive()))
			and (not IsInInstance())
			and IsFlyableArea()
			and (GetShapeshiftForm() == 3)
			and (flyingSpeed < 10)
			and (not IsFlying())
			and (not IsSwimming())
			and (lastTimeSwim + 3 < GetTime())
		then
			ns.Addon:Print("All conditions met for travel form autmation - force switching form")
			CancelShapeshiftForm()
		end
	end
    -- DEBUG.checkpointDebugTimer("UPDATE_FRAME_ONUPDATE_DRUID_AUTOMATION_DONE", "UPDATE_FRAME_ONUPDATE_EXPANSION_CHECK_DONE")

	if isEnabled("cooldownManager_centerBuffIcons") and not addon.isMidnight then 
		ns.CooldownManager.centerBuffIcons()
	end 
    -- DEBUG.checkpointDebugTimer("UPDATE_FRAME_ONUPDATE_COOLDOWN_MANAGER_DONE", "UPDATE_FRAME_ONUPDATE_DRUID_AUTOMATION_DONE")

	if UpdateFrameLastUpdate ~= nil and UpdateFrameLastUpdate > GetTime() - 0.1 then
		return
	end
	UpdateFrameLastUpdate = GetTime()
	
    -- DEBUG.checkpointDebugTimer("UPDATE_FRAME_ONUPDATE_END", "UPDATE_FRAME_ONUPDATE_COOLDOWN_MANAGER_DONE")
end)
DEBUG.checkpointDebugTimer("UPDATE_FRAME_INIT_DONE", "UPDATE_FRAME_INIT")



-- Addon initialization
function addon:OnInitialize()
    DEBUG.startDebugTimer("ADDON_ON_INITIALIZE_START")
	-- Initialize database
	self.db = LibStub("AceDB-3.0"):New("WilduToolsDB", ns.DEFAULT_SETTINGS, true)
	ns.db = self.db

	-- Register slash commands
	self:RegisterChatCommand("wildutools", function()
		self:ShowConfig()
	end)
	self:RegisterChatCommand("wt", function()
		self:ShowConfig()
	end)
	-- Utilities
	self:RegisterChatCommand("utm", function(input)
		ns.UTM:HandleCommand(input)
	end)
	-- Shortcuts
	self:RegisterChatCommand("ccb", function()
		ns.API:OpenClickCastBinding()
	end)
	self:RegisterChatCommand("kb", function()
		ns.API:OpenQuickKeybindMode()
	end)
    self:RegisterChatCommand("wildudebug", function(input)
		local cmd = input and input:lower() or ""
		
		if cmd == "timer list" then
		print("|cFFFFFF00Active Timers:|r")
		for label, time in pairs(DEBUG.timers) do
			print(string.format("  %s: %.3f s", label, GetTime() - time))
		end
		
		elseif cmd == "events list" then
		print("|cFF0099FFRegistered Events:|r")
		for event, data in pairs(DEBUG.events) do
			print(string.format("  %s (fired %d times)", event, data.firedCount))
		end
		
		elseif cmd == "hooks list" then
		print("|cFFFF9900Registered Hooks:|r")
		for hookType, modules in pairs(DEBUG.hooks) do
			print(string.format("  %s: %d hooks", hookType, #modules))
		end
		
		elseif cmd == "spike trace" then
		local analysis = DEBUG.analyzeSpikeData()
		if analysis.peakDelta then
			print("|cFFFF0000Spike Trace:|r")
			print(string.format("Peak: %.2f ms at %.2f s", analysis.peakDelta, analysis.peakTime / 1000))
			print(string.format("Total spikes detected: %d", analysis.spikeCount))
		else
			print("No spike data available")
		end
		
		elseif cmd == "report" then
		DEBUG.printReport()
		
		else
		print("|cFFFFFF00WilduTools Debug Commands:|r")
		print("/wildudebug timer list - Show active timers")
		print("/wildudebug events list - Show registered events")
		print("/wildudebug hooks list - Show registered hooks")
		print("/wildudebug spike trace - Show spike analysis")
		print("/wildudebug report - Print full debug report")
		end
	end)

	-- create minimap icon via module
	if Minimap then
		local ok, err = Minimap:Init(self.db)
		if not ok then
			print("Minimap icon not created:")
			if err == "missing_libs" then
				print("LibDataBroker or LibDBIcon not found. Minimap icon not created.")
			end
		end
	else 
		print("no minimap")
	end
	DEBUG.checkpointDebugTimer("ADDON_ON_INITIALIZE_END", "ADDON_ON_INITIALIZE_START")

	ns.WilduSettings:DevInit()
end


function addon:ShowConfig()
	Settings.OpenToCategory(ns.WilduSettings.SettingsLayout.rootCategory:GetID())
end

local gameVersion = select(1, GetBuildInfo())
addon.isMidnight = gameVersion:match("^12")
addon.isRetail = gameVersion:match("^11")