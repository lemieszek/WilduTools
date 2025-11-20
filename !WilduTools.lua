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

-- Load configuration
local config = LibStub("AceConfig-3.0")
local configDialog = LibStub("AceConfigDialog-3.0")
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
		if isEnabled("general_alwaysEnableAllActionBars") then
			CVars.enableAllActionBars()
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
InitFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
InitFrame:SetScript("OnEvent", function()
    DEBUG.startDebugTimer("INIT_FRAME_EVENT_START")
	C_Timer.After(1, function()
        DEBUG.startDebugTimer("INIT_FRAME_DELAYED_START")
		Addons.scaleAddOnsSize()
		Addons.checkForWAModels()
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
			if isEnabled("cooldownManager_centerBuffIconsAnchor") then
				CooldownManager.centerBuffIconCooldownViewerAnchor()
			end
			if isEnabled("cooldownManager_centerEssentialAnchor") then
				CooldownManager.centerEssentialCooldownViewerAnchor()
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
		if isEnabled("automation_druidFormCombatPreservation") then
			Automation:SetFormPreservation(false)
		end
		if not InCombatLockdown() then
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
		end
	end
    DEBUG.checkpointDebugTimer("COMBAT_FRAME_EVENT_END", "COMBAT_FRAME_EVENT_START")
end)
DEBUG.checkpointDebugTimer("COMBAT_FRAME_INIT_DONE", "COMBAT_FRAME_INIT")

DEBUG.startDebugTimer("EDIT_MODE_CALLBACKS_INIT")
EventRegistry:RegisterCallback("EditMode.Enter", function()
    DEBUG.startDebugTimer("EDIT_MODE_ENTER_START")
	if isEnabled("cooldownManager_centerBuffIconsAnchor") then
		CooldownManager.centerBuffIconCooldownViewerAnchor()
	end
	if isEnabled("cooldownManager_centerEssentialAnchor") then
		CooldownManager.centerEssentialCooldownViewerAnchor()
	end
    DEBUG.checkpointDebugTimer("EDIT_MODE_ENTER_END", "EDIT_MODE_ENTER_START")
end)
EventRegistry:RegisterCallback("EditMode.Exit", function()
    DEBUG.startDebugTimer("EDIT_MODE_EXIT_START")
	if isEnabled("cooldownManager_centerBuffIconsAnchor") then
		CooldownManager.centerBuffIconCooldownViewerAnchor()
	end
	if isEnabled("cooldownManager_centerEssentialAnchor") then
		CooldownManager.centerEssentialCooldownViewerAnchor()
	end
    DEBUG.checkpointDebugTimer("EDIT_MODE_EXIT_END", "EDIT_MODE_EXIT_START")
end)
DEBUG.checkpointDebugTimer("EDIT_MODE_CALLBACKS_INIT_DONE", "EDIT_MODE_CALLBACKS_INIT")

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

	if isEnabled("cooldownManager_centerBuffIcons") then 
		if GetNumExpansions() == 12 then
			return
		end
		-- TODO make it a module function
		-- TODO remove in midnight
		-- 
		local itemFrameContainer = BuffIconCooldownViewer:GetLayoutChildren()
		for i = #itemFrameContainer, 1, -1 do
			local itemFrame = itemFrameContainer[i]
			if not itemFrame.isActive then
				table.remove(itemFrameContainer, i)
			end
		end
		for i, itemFrame in ipairs(itemFrameContainer) do
			itemFrame:SetParent(BuffIconCooldownViewer)
			itemFrame:ClearAllPoints()
			local itemSizeX = itemFrame:GetWidth() 
			local itemSizeY = itemFrame:GetHeight()
			local padding = 2

			local displayIndex = i - 1
			local itemsInLine = #itemFrameContainer
			local centerOffsetX, centerOffsetY = 0, 0

			local totalLineWidth = itemsInLine * itemSizeX + (itemsInLine - 1) * padding
			centerOffsetX = -totalLineWidth / 2 + itemSizeX / 2
				
			local iconXOffset = itemSizeX + padding

			local x, y

			x = displayIndex * iconXOffset + centerOffsetX
			y = 0

			local anchorPoint = (secondDirection == 1) and "BOTTOM" or "TOP"

			itemFrame:SetPoint(anchorPoint, BuffIconCooldownViewer, anchorPoint, x, y)
		end
	end 
    -- DEBUG.checkpointDebugTimer("UPDATE_FRAME_ONUPDATE_COOLDOWN_MANAGER_DONE", "UPDATE_FRAME_ONUPDATE_DRUID_AUTOMATION_DONE")

	if UpdateFrameLastUpdate ~= nil and UpdateFrameLastUpdate > GetTime() - 0.1 then
		return
	end
	UpdateFrameLastUpdate = GetTime()
	
	if not UnitAffectingCombat("player") then
		if isEnabled("cooldownManager_centerBuffIconsAnchor") then
			CooldownManager.centerBuffIconCooldownViewerAnchor()
		end
		if isEnabled("cooldownManager_centerEssentialAnchor") then
			CooldownManager.centerEssentialCooldownViewerAnchor()
		end
	end
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
	-- Create options table
	local options = {
		name = "WilduTools",
		type = "group",
		args = {
			general = {
				type = "group",
				name = "Settings",
				args = {
					automation_group = {
						type = "group",
						name = "Automation",
						order = 1,
						args = {
							generalHeader = {
								type = "header",
								name = "General Automation Settings",
								order = 1,
							},
							automation_gossip = {
								type = "toggle",
								width = "full",
								order = 2,
								get = function(info)
									return self.db.profile.automation_gossipEnabled
								end,
								set = function(info, v)
									self.db.profile.automation_gossipEnabled = v
								end,
								name = "Auto gossip when only one option is available",
								desc = "hold Shift to disable the behavior",
								descStyle = "inline",
							},
							automation_groupInvite = {
								type = "toggle",
								width = "full",
								order = 3,
								get = function(info) 
									return self.db.profile.automation_autoAcceptGroupInviteEnabled 
								end,
								set = function(info, v) 
									self.db.profile.automation_autoAcceptGroupInviteEnabled = v
									Automation:InitAutoAcceptGroupInvite()
								end,
								name = "Auto accept group invites",
								desc = "Automatically accept group invites from anyone (friends and guild members in the future)",
								descStyle = "inline",
							},
							automation_roleCheck = {
								type = "toggle",
								width = "full",
								order = 4,
								get = function(info) 
									return self.db.profile.automation_autoAcceptGroupRoleEnabled 
								end,
								set = function(info, v) 
									self.db.profile.automation_autoAcceptGroupRoleEnabled = v
									Automation:InitAutoAcceptRole()
								end,
								name = "Auto accept role check",
								desc = "Automatically accept the role check popup when joining a group (in future - only if the group leader is a friend or guild member)",
								descStyle = "inline",
							},

							druidHeader = {
								type = "header",
								name = "Druid Specific Automation Settings",
								order = 10,
							},
							automation_cancelTravelForm = {
								type = "toggle",
								width = "full",
								order = 11,
								get = function(info)
									return self.db.profile.automation_druidCancelTravelFormEnabled
								end,
								set = function(info, v)
									self.db.profile.automation_druidCancelTravelFormEnabled = v
								end,
								name = "Auto travel => flying form",
								desc = "Auto cancel form when in travel form and flying is available. This causes you to automatically switch to flying form.",
								descStyle = "inline",
							},
							automation_druidPreserveBearForm = {
								type = "toggle",
								width = "full",
								order = 12,
								get = function(info)
									return self.db.profile.automation_druidFormCombatPreservation
								end,
								set = function(info, v)
									self.db.profile.automation_druidFormCombatPreservation = v
								end,
								name = "Preserve Druid Form (in Combat)",
								desc = "Prevent automatic cancellation of any (ex. Bear) Form when casting spells that would normally cancel it.",
								descStyle = "inline",
							}
						},
					},
					-- Cooldown manager options
					
					action_bars = {
						type = "group",
						name = "Action Bars",
						order = 2,
						args = {
							disableMouseOnActionBars = {
								type = "toggle",
								width = "full",
								order = 1,
								name = "Disable Mouse on Action Bars",
								desc = "Master switch: when enabled, per-bar settings will be applied to disable mouse input on the selected bars",
								descStyle = "inline",
								get = function(info) return self.db.profile.actionBars_disableMouseOnActionBars end,
								set = function(info, v) 
									self.db.profile.actionBars_disableMouseOnActionBars = v 
									if v and not self.db.profile.actionBars_disableMouseOnActionBars_onlyInCombat then
										-- Apply per-bar settings
										if self.db.profile.actionBars_disable_mouse_ActionButton then ns.ActionBars.disableMouseOnBar("ActionButton") else ns.ActionBars.enableMouseOnBar("ActionButton") end
										if self.db.profile.actionBars_disable_mouse_MultiBarBottomLeftButton then ns.ActionBars.disableMouseOnBar("MultiBarBottomLeftButton") else ns.ActionBars.enableMouseOnBar("MultiBarBottomLeftButton") end
										if self.db.profile.actionBars_disable_mouse_MultiBarBottomRightButton then ns.ActionBars.disableMouseOnBar("MultiBarBottomRightButton") else ns.ActionBars.enableMouseOnBar("MultiBarBottomRightButton") end
										if self.db.profile.actionBars_disable_mouse_MultiBarLeftButton then ns.ActionBars.disableMouseOnBar("MultiBarLeftButton") else ns.ActionBars.enableMouseOnBar("MultiBarLeftButton") end
										if self.db.profile.actionBars_disable_mouse_MultiBarRightButton then ns.ActionBars.disableMouseOnBar("MultiBarRightButton") else ns.ActionBars.enableMouseOnBar("MultiBarRightButton") end
										if self.db.profile.actionBars_disable_mouse_MultiBar5Button then ns.ActionBars.disableMouseOnBar("MultiBar5Button") else ns.ActionBars.enableMouseOnBar("MultiBar5Button") end
										if self.db.profile.actionBars_disable_mouse_MultiBar6Button then ns.ActionBars.disableMouseOnBar("MultiBar6Button") else ns.ActionBars.enableMouseOnBar("MultiBar6Button") end
										if self.db.profile.actionBars_disable_mouse_MultiBar7Button then ns.ActionBars.disableMouseOnBar("MultiBar7Button") else ns.ActionBars.enableMouseOnBar("MultiBar7Button") end
									else
										-- Enable mouse on all bars
										ns.ActionBars.enableMouseOnBar("ActionButton")
										ns.ActionBars.enableMouseOnBar("MultiBarBottomLeftButton")
										ns.ActionBars.enableMouseOnBar("MultiBarBottomRightButton")
										ns.ActionBars.enableMouseOnBar("MultiBarLeftButton")
										ns.ActionBars.enableMouseOnBar("MultiBarRightButton")
										ns.ActionBars.enableMouseOnBar("MultiBar5Button")
										ns.ActionBars.enableMouseOnBar("MultiBar6Button")
										ns.ActionBars.enableMouseOnBar("MultiBar7Button")
									end
								end,
							},
							disableMouseOnActionBars_onlyInCombat = {
								type = "toggle",
								width = "full",
								order = 2,
								name = "Only in Combat",
								desc = "Apply mouse disabling only when entering combat",
								descStyle = "inline",
								get = function(info) return self.db.profile.actionBars_disableMouseOnActionBars_onlyInCombat end,
								set = function(info, v) 
									self.db.profile.actionBars_disableMouseOnActionBars_onlyInCombat = v 

									if not v and self.db.profile.actionBars_disableMouseOnActionBars then
										-- Apply per-bar settings
										if self.db.profile.actionBars_disable_mouse_ActionButton then ns.ActionBars.disableMouseOnBar("ActionButton") else ns.ActionBars.enableMouseOnBar("ActionButton") end
										if self.db.profile.actionBars_disable_mouse_MultiBarBottomLeftButton then ns.ActionBars.disableMouseOnBar("MultiBarBottomLeftButton") else ns.ActionBars.enableMouseOnBar("MultiBarBottomLeftButton") end
										if self.db.profile.actionBars_disable_mouse_MultiBarBottomRightButton then ns.ActionBars.disableMouseOnBar("MultiBarBottomRightButton") else ns.ActionBars.enableMouseOnBar("MultiBarBottomRightButton") end
										if self.db.profile.actionBars_disable_mouse_MultiBarLeftButton then ns.ActionBars.disableMouseOnBar("MultiBarLeftButton") else ns.ActionBars.enableMouseOnBar("MultiBarLeftButton") end
										if self.db.profile.actionBars_disable_mouse_MultiBarRightButton then ns.ActionBars.disableMouseOnBar("MultiBarRightButton") else ns.ActionBars.enableMouseOnBar("MultiBarRightButton") end
										if self.db.profile.actionBars_disable_mouse_MultiBar5Button then ns.ActionBars.disableMouseOnBar("MultiBar5Button") else ns.ActionBars.enableMouseOnBar("MultiBar5Button") end
										if self.db.profile.actionBars_disable_mouse_MultiBar6Button then ns.ActionBars.disableMouseOnBar("MultiBar6Button") else ns.ActionBars.enableMouseOnBar("MultiBar6Button") end
										if self.db.profile.actionBars_disable_mouse_MultiBar7Button then ns.ActionBars.disableMouseOnBar("MultiBar7Button") else ns.ActionBars.enableMouseOnBar("MultiBar7Button") end
									elseif not InCombatLockdown() then
										-- Enable mouse on all bars
										ns.ActionBars.enableMouseOnBar("ActionButton")
										ns.ActionBars.enableMouseOnBar("MultiBarBottomLeftButton")
										ns.ActionBars.enableMouseOnBar("MultiBarBottomRightButton")
										ns.ActionBars.enableMouseOnBar("MultiBarLeftButton")
										ns.ActionBars.enableMouseOnBar("MultiBarRightButton")
										ns.ActionBars.enableMouseOnBar("MultiBar5Button")
										ns.ActionBars.enableMouseOnBar("MultiBar6Button")
										ns.ActionBars.enableMouseOnBar("MultiBar7Button")
									end
								end,
							},
							-- Per-bar toggles
							per_bar_disable = {
								type = "group",
								order = 3,
								guiInline = true,
								name = "Per-action-bar mouse disable",
								args = {
									bar1 = {
										type = "toggle",
										name = "Action Bar 1",
										get = function(info) return self.db.profile.actionBars_disable_mouse_ActionButton end,
										set = function(info, v)
											self.db.profile.actionBars_disable_mouse_ActionButton = v
											if self.db.profile.actionBars_disableMouseOnActionBars then
												if v then ns.ActionBars.disableMouseOnBar("ActionButton") else ns.ActionBars.enableMouseOnBar("ActionButton") end
											end
										end,
									},
									bar2 = {
										type = "toggle",
										name = "Action Bar 2",
										get = function(info) return self.db.profile.actionBars_disable_mouse_MultiBarBottomLeftButton end,
										set = function(info, v)
											self.db.profile.actionBars_disable_mouse_MultiBarBottomLeftButton = v
											if self.db.profile.actionBars_disableMouseOnActionBars then
												if v then ns.ActionBars.disableMouseOnBar("MultiBarBottomLeftButton") else ns.ActionBars.enableMouseOnBar("MultiBarBottomLeftButton") end
											end
										end,
									},
									bar3 = {
										type = "toggle",
										name = "Action Bar 3",
										get = function(info) return self.db.profile.actionBars_disable_mouse_MultiBarBottomRightButton end,
										set = function(info, v)
											self.db.profile.actionBars_disable_mouse_MultiBarBottomRightButton = v
											if self.db.profile.actionBars_disableMouseOnActionBars then
												if v then ns.ActionBars.disableMouseOnBar("MultiBarBottomRightButton") else ns.ActionBars.enableMouseOnBar("MultiBarBottomRightButton") end
											end
										end,
									},
									bar4 = {
										type = "toggle",
										name = "Action Bar 4",
										get = function(info) return self.db.profile.actionBars_disable_mouse_MultiBarLeftButton end,
										set = function(info, v)
											self.db.profile.actionBars_disable_mouse_MultiBarLeftButton = v
											if self.db.profile.actionBars_disableMouseOnActionBars then
												if v then ns.ActionBars.disableMouseOnBar("MultiBarLeftButton") else ns.ActionBars.enableMouseOnBar("MultiBarLeftButton") end
											end
										end,
									},
									bar5 = {
										type = "toggle",
										name = "Action Bar 5",
										get = function(info) return self.db.profile.actionBars_disable_mouse_MultiBarRightButton end,
										set = function(info, v)
											self.db.profile.actionBars_disable_mouse_MultiBarRightButton = v
											if self.db.profile.actionBars_disableMouseOnActionBars then
												if v then ns.ActionBars.disableMouseOnBar("MultiBarRightButton") else ns.ActionBars.enableMouseOnBar("MultiBarRightButton") end
											end
										end,
									},
									bar6 = {
										type = "toggle",
										name = "Action Bar 6",
										get = function(info) return self.db.profile.actionBars_disable_mouse_MultiBar5Button end,
										set = function(info, v)
											self.db.profile.actionBars_disable_mouse_MultiBar5Button = v
											if self.db.profile.actionBars_disableMouseOnActionBars then
												if v then ns.ActionBars.disableMouseOnBar("MultiBar5Button") else ns.ActionBars.enableMouseOnBar("MultiBar5Button") end
											end
										end,
									},
									bar7 = {
										type = "toggle",
										name = "Action Bar 7",
										get = function(info) return self.db.profile.actionBars_disable_mouse_MultiBar6Button end,
										set = function(info, v)
											self.db.profile.actionBars_disable_mouse_MultiBar6Button = v
											if self.db.profile.actionBars_disableMouseOnActionBars then
												if v then ns.ActionBars.disableMouseOnBar("MultiBar6Button") else ns.ActionBars.enableMouseOnBar("MultiBar6Button") end
											end
										end,
									},
									bar8 = {
										type = "toggle",
										name = "Action Bar 8",
										get = function(info) return self.db.profile.actionBars_disable_mouse_MultiBar7Button end,
										set = function(info, v)
											self.db.profile.actionBars_disable_mouse_MultiBar7Button = v
											if self.db.profile.actionBars_disableMouseOnActionBars then
												if v then ns.ActionBars.disableMouseOnBar("MultiBar7Button") else ns.ActionBars.enableMouseOnBar("MultiBar7Button") end
											end
										end,
									},
								},
							},
							noMouseClickExtraActionBar = {
								type = "toggle",
								order = 4,
								width = "full",
								name = "Make Art around ExtraActionBar Click-Through",
								desc = "Prevent accidental 'empty clicks' by disabling mouse clicks on the Art around ExtraActionBar art. Button itself is still clickable",
								descStyle = "inline",
								get = function(info) return self.db.profile.actionBars_disableMouseOnExtraActionBar end,
								set = function(info, v) self.db.profile.actionBars_disableMouseOnExtraActionBar = v end,
							},
						},
					},
					cooldown_manager = {
						type = "group",
						name = "Cooldown Manager",
						hidden = function() return GetNumExpansions() == 12 end,
						order = 3,
						args = {
							centerBuffIconsAnchor = {
								order = 1,
								type = "toggle",
								width = "full",
								name = "Center Buff Anchor",
								desc = "Dynamically center the Buff Icon Cooldown Viewer Anchor to keep it centered",
								descStyle = "inline",
								get = function(info) return self.db.profile.cooldownManager_centerBuffIconsAnchor end,
								set = function(info, v)
									self.db.profile.cooldownManager_centerBuffIconsAnchor = v
									if v and ns.CooldownManager and ns.CooldownManager.centerBuffIconCooldownViewerAnchor then
										ns.CooldownManager.centerBuffIconCooldownViewerAnchor()
									end
								end,
							},
							centerBuffsIcons = {
								order = 2,
								type = "toggle",
								width = "full",
								name = "Center Buff Icons (not working in Midnight)",
								desc = "Dynamically center the Buff Icon Cooldown Viewer Icons to keep them aligned center aligned",
								descStyle = "inline",
								get = function(info) return self.db.profile.cooldownManager_centerBuffIcons end,
								set = function(info, v) self.db.profile.cooldownManager_centerBuffIcons = v end,
							},
							centerEssentialAnchor = {
								type = "toggle",
								width = "full",
								name = "Center Essential Cooldowns Anchor",
								desc = "Dynamically center the Essential Cooldown Viewer Anchor to keep it centered",
								descStyle = "inline",
								get = function(info) return self.db.profile.cooldownManager_centerEssentialAnchor end,
								set = function(info, v)
									self.db.profile.cooldownManager_centerEssentialAnchor = v
									if v and ns.CooldownManager and ns.CooldownManager.centerEssentialCooldownViewerAnchor then
										ns.CooldownManager.centerEssentialCooldownViewerAnchor()
									end
								end,
							},
						},
					},
					-- UI group
					blizz_ui_group = {
						type = "group",
						name = "UI Tweaks",
						order = 10,
						args = {
							header0 = {
								order = 0,
								type = "header",
								name = "Blizzard UI Tweaks",
							},
							reloadAction = {
								order = 0.2,
								type = "execute",
								name = "Reload UI",
								
								func = function() ReloadUI() end,
							},
							desc0 = {
								order = 0.3,
								type = "description",
								name = "Various tweaks and improvements for the default Blizzard UI elements. |cffff0000Most of the settings require reload (*)|r",
							},
							header1 = {
								order = 0.9,
								type = "header",
								width = "full",
								name = "Hiding",
							},
							blizzUI_hideBagsFrames = {
								order = 1,
								type = "toggle",
								width = "full",
								name = "Hide Some Blizzard Frames |cffff0000(*)|r",
								desc = "Hide: Bag, Reagent Bag",
								descStyle = "inline",
								get = function(info) return self.db.profile.blizzUI_hideBagsFrames end,
								set = function(info, v) self.db.profile.blizzUI_hideBagsFrames = v; if v then UI.hideBlizzardBagAndReagentFrames() end; end,
							},
							hideScreenshotText = {
								order = 2,
								type = "toggle",
								width = "full",
								name = "Hide Screenshot Text |cffff0000(*)|r",
								desc = "Remove screenshot text from the middle of the screen",
								descStyle = "inline",
								get = function(info) return self.db.profile.blizzUI_hideScreenshotText end,
								set = function(info, v) self.db.profile.blizzUI_hideScreenshotText = v end,
							},
							improvementsHeader = {
								order = 20,
								type = "header",
								width = "full",
								name = "Improvements / Visual Tweaks",
							},
							blizzUI_changeFriendlyNamesFont = {
								order = 21,
								type = "toggle",
								width = "full",
								name = "Friendly Names Font",
								desc = "Add outline for friendly names",
								descStyle = "inline",
								hidden = function() return GetNumExpansions() == 12 end,
								get = function(info) return self.db.profile.blizzUI_changeFriendlyNamesFont end,
								set = function(info, v) self.db.profile.blizzUI_changeFriendlyNamesFont = v end,
							},
							chatTooltipOnChatLinks ={
								order = 22,
								type = "toggle",
								width = "full",
								name = "Chat Tooltips on Chat Links |cffff0000(*)|r",
								desc = "Show item/spell/achievement tooltips when hovering over links in chat",
								descStyle = "inline",
								get = function(info) return self.db.profile.blizzUI_chatTooltipOnChatLinks end,
								set = function(info, v) self.db.profile.blizzUI_chatTooltipOnChatLinks = v end,
							},
							blizzUI_addCastTimeTextOutline = {
								order = 23,
								type = "toggle",
								width = "full",
								name = "Cast Bar Timer |cffff0000(*)|r",
								desc = "Add outline to player cast bar time text to make it more visible (required enabling 'Show Cast Time' in edit mode on cast bar)",
								descStyle = "inline",
								get = function(info) return self.db.profile.blizzUI_addCastTimeTextOutline end,
								set = function(info, v) self.db.profile.blizzUI_addCastTimeTextOutline = v end,
							},
							blizzUI_altPowerBarText = {
								order = 24,
								type = "toggle",
								width = "full",
								name = "Alt Power Bar Text |cffff0000(*)|r",
								desc = "Always show Encaounter Bar / Extra Power Bar numbers with with additional background for better visibility",
								descStyle = "inline",
								get = function(info) return self.db.profile.blizzUI_altPowerBarText end,
								set = function(info, v) self.db.profile.blizzUI_altPowerBarText = v end,
							},
							uiError = {
								order = 25,
								type = "toggle",
								width = "full",
								name = "Objective/Error Text Bigger |cffff0000(*)|r",
								desc = "Enlarge objective completed texts and ui error texts font (top of the screen)",
								descStyle = "inline",
								get = function(info) return self.db.profile.blizzUI_enchanceUIErrorFrame end,
								set = function(info, v) self.db.profile.blizzUI_enchanceUIErrorFrame = v end,
							},

							resizeHeader = {
								order = 40,
								type = "header",
								width = "full",
								name = "Resizing",
							},
							cleanupObjectiveTracker = {
								order = 41,
								type = "toggle",
								width = "full",
								name = "Clean up Objective Tracker |cffff0000(*)|r",
								desc = "Remove header and header backgroud",
								descStyle = "inline",
								get = function(info) return self.db.profile.blizzUI_cleanupObjectiveTracker end,
								set = function(info, v)
									self.db.profile.blizzUI_cleanupObjectiveTracker = v 
									if v then
										UI.cleanupObjectiveTracker()
									end
								end,
							},
							resizeBlizzardObjectiveTracker = {
								order = 42,
								type = "toggle",
								width = "full",
								name = "Scale Blizzard tracker frame",
								descStyle = "inline",
								get = function(info) 		return self.db.profile.blizzUI_resizeBlizzardObjectiveTracker end,
								set = function(info, v) 
									self.db.profile.blizzUI_resizeBlizzardObjectiveTracker = v 
									if v then
										UI.resizeBlizzardObjectiveTracker(self.db.profile.blizzUI_resizeBlizzardObjectiveTrackerRange or 1)
									else
										UI.resizeBlizzardObjectiveTracker(1)
									end
								end,
							},
							resizeTrackerFrameRange = {
								order = 43,
								type = "range",
								width = "full",
								name = "Tracker Frame Scale",
								min = 0.2,
								max = 3.0,
								step = 0.02,
								get = function(info) return self.db.profile.blizzUI_resizeBlizzardObjectiveTrackerRange end,
								set = function(info, v) 
									self.db.profile.blizzUI_resizeBlizzardObjectiveTrackerRange = v 
									if self.db.profile.blizzUI_resizeBlizzardObjectiveTracker then
										UI.resizeBlizzardObjectiveTracker(v)
									end
								end,
							},
							expandFriendListHeight = {
								order = 45,
								type = "toggle",
								width = "full",
								name = "Friend List Resize height",
								descStyle = "inline",
								get = function(info) return self.db.profile.blizzUI_expandFriendListHeight end,
								set = function(info, v) self.db.profile.blizzUI_expandFriendListHeight = v end,
							},
							expandFriendListHeightRange = {
								order = 46,
								type = "range",
								width = "full",
								name = "Tracker Frame Scale",
								min = 400,
								max = 900,
								step = 10,
								get = function(info) return self.db.profile.blizzUI_expandFriendListHeightRange end,
								set = function(info, v) 
									self.db.profile.blizzUI_expandFriendListHeightRange = v 
									if self.db.profile.blizzUI_expandFriendListHeight then
										UI.expandFriendListHeight(v)
									end
								end,
							},
						},
					},
					wildu_ui_group = {
						type = "group",
						name = "Wildu's UI",
						order = 20,
						args = {
							header1 = {
								order = 0,
								type = "header",
								width = "full",
								name = "Wildu's UI Enhancements",
							},
							desc1 = {
								order = 0.1,
								type = "description",
								width = "full",
								name = "All frames are movable in edit mode",
							},
							rangeDisplay = {
								order = 1,
								type = "toggle",
								width = "full",
								name = "Target Range Frame",
								desc = "Displays a range to target",
								descStyle = "inline",
								get = function(info) return self.db.profile.wilduUI_targetRangeFrame end,
								set = function(info, v) 
									self.db.profile.wilduUI_targetRangeFrame = v
									if v then WilduUI.InitializeRangeFrame() end
								end,
							},
							mountableArea = {
								order = 2,
								type = "toggle",
								width = "full",
								name = "Mountable Area Indicator",
								desc = "Displays an indicator showing if you can mount in the current area",
								descStyle = "inline",
								get = function(info) return self.db.profile.wilduUI_mountableArea end,
								set = function(info, v) 
									self.db.profile.wilduUI_mountableArea = v
									WilduUI.InitializeMountableAreaIndicator()
								end,
							},
							-- spellOnCD = {
							-- 	type = "toggle",
							-- 	width = "full",
							-- 	name = "WORK IN PROGRESS: Spell-on-CD Alert",
							-- 	desc = "Show an alert icon when a player's spell fails to cast",
							-- 	descStyle = "inline",
							-- 	get = function(info) return self.db.profile.wilduUI_spellOnCD end,
							-- 	set = function(info, v) self.db.profile.wilduUI_spellOnCD = v; if v then WilduUI.InitializeSpellOnCD() end end,
							-- },
							crosshair = {
								type = "toggle",
								width = "full",
								name = "Crosshair",
								desc = "Show a simple class-colored crosshair in the center of the screen",
								descStyle = "inline",
								get = function(info) return self.db.profile.wilduUI_crosshair end,
								set = function(info, v) self.db.profile.wilduUI_crosshair = v; WilduUI.InitializeCrosshair() end,
							},
							playerCombat = {
								type = "toggle",
								width = "full",
								name = "Player in Combat Indicator",
								desc = "Show an icon when the player is in combat",
								descStyle = "inline",
								get = function(info) return self.db.profile.wilduUI_playerCombat end,
								set = function(info, v) self.db.profile.wilduUI_playerCombat = v; WilduUI.InitializePlayerCombatIndicator() end,
							},
							targetCombat = {
								type = "toggle",
								width = "full",
								name = "Target in Combat Indicator",
								desc = "Show an icon when your target is in combat",
								descStyle = "inline",
								get = function(info) return self.db.profile.wilduUI_targetCombat end,
								set = function(info, v) self.db.profile.wilduUI_targetCombat = v; WilduUI.InitializeTargetCombatIndicator() end,
							},

						},
					},
					utm = {
						type = "group",
						name = "Macros",
						order = 70,
						args = {
							description = {
								type = "description",
								name = UTM.helpUsing,
							},
							setup = {
								type = "execute",
								name = "Setup Macros for this character",
								width = "full",
								func = function()
									if ns.UTM then
										ns.UTM:SetupMacros()
									end
								end,
							},
						},
					},
					Settings = {
						type = "group",
						name = "Settings (+CVars)",
						order = 80,
						args = {
							header = {
								type= "header",
								name = "Settings",
								order = 0,
							},
							autoscale = {
								type = "select",
								name = "On login UI scaling",
								order = 1,
								values = {
									NoScaling = "No scaling",
									Scale1080p = "0.7111 for 1080p",
									Scale1440p = "0.5333 for 1440p",
								},
								sorting= {"NoScaling", "Scale1080p", "Scale1440p"},
								get = function(info)
									return self.db.profile.general_defaultScaling or "NoScaling"
								end,
								set = function(info, v)
									self.db.profile.general_defaultScaling = v
									ReloadUI()
								end,
							},
							spacing1 = {
								type = "description",
								name = "",
								order = 1.5,
								width = "full",
							},
							enableAllActionBars = {
								type = "execute",
								name = "Enable All Action Bars",
								order = 2,
								width = 1.2,
								func = function()
									CVars.enableAllActionBars()
								end,
							},
							alwaysEnableOnLogin = {
								type = "toggle",
								name = "Always enable",
								order = 2.1,
								desc = "Automatically enable all action bars every time you log in (usefull on fresh alts)",
								get = function(info) return self.db.profile.general_alwaysEnableAllActionBars end,
								set = function(info, v) self.db.profile.general_alwaysEnableAllActionBars = v end,
							},
							minimapButtonOnClick = {
								type = "select",
								name = "Minimap Button on click",
								order = 3,
								values = {
									Plumber = "Plumber Landing Page",
									Settings = "WilduTools Settings",
									Reload = "Reload UI",
								},
								sorting= {"Settings", "Plumber", "Reload"},
								get = function(info)
									return self.db.profile.general_minimapButtonOnClickAction or "Settings"
								end,
								set = function(info, v)
									self.db.profile.general_minimapButtonOnClickAction = v
								end,
							},
							
							minimapButtonOnShiftClick = {
								type = "select",
								name = "Minimap Button on click + shift",
								order = 3.1,
								values = {
									Plumber = "Plumber Landing Page",
									Settings = "WilduTools Settings",
									Reload = "Reload UI",
								},
								sorting= {"Settings", "Plumber", "Reload"},
								get = function(info)
									return self.db.profile.general_minimapButtonOnClickShiftAction or "Settings"
								end,
								set = function(info, v)
									self.db.profile.general_minimapButtonOnClickShiftAction = v
								end,
							},
							toEnable = {
								type = "group",
								name = "Recommended to Enable",
								order = 4,
								guiInline = true,
								args = {
									advancedCombatLogging = {
										type = "toggle",
										name = "Advanced Combat Logging",
										order = 2,
										width = "full",
										desc = "Enable advanced combat logging",
										get = function(info) return CVars.getCVar("advancedCombatLogging") end,
										set = function(info, v) CVars.setCVar("advancedCombatLogging", v) end,
									},
									-- Todo fix - replace getCVar with actual "set setting" as it doesnt work for all vars like we would like to, 
									-- TOOD make it a select as in blizz options
									motionSicknessLandscapeDarkening = {
										type = "toggle",
										name = "Disable Motion Sickness Landscape Darkening",
										order = 3,
										width = "full",
										desc = "Disable landscape darkening that is used to reduce motion sickness",
										get = function(info) return CVars.getCVar("motionSicknessLandscapeDarkening") == false end,
										set = function(info, v) CVars.setCVar("motionSicknessLandscapeDarkening", v and "0" or "1") end,
									},

									advancedFlyingFullScreenEffects = {
										type = "toggle",
										name = "Skyriding Screen Effects",
										order = 4,
										width = "full",
										desc = "Advanced flying fullscreen visual effects",
										get = function(info) return CVars.getSettingValue("DisableAdvancedFlyingFullScreenEffects") end,
										set = function(info, v) CVars.applySetting("DisableAdvancedFlyingFullScreenEffects", v) end,
									},
									advancedFlyingVelocityVFX = {
										type = "toggle",
										name = "Skyriding Speed Effects",
										order = 5,
										width = "full",
										desc = "Flying velocity visual effects",
										get = function(info) return CVars.getSettingValue("DisableAdvancedFlyingVelocityVFX") end,
										set = function(info, v) CVars.applySetting("DisableAdvancedFlyingVelocityVFX", v) end,
									},
									ResampleAlwaysSharpen = {
										type = "toggle",
										name = "Resample Always Sharpen",
										order = 6,
										width = "full",
										desc = "Toggle resample always sharpen setting",
										get = function(info) return CVars.getCVar("ResampleAlwaysSharpen") end,
										set = function(info, v) CVars.setCVar("ResampleAlwaysSharpen", v) end,
									},
									whisperMode = {
										type = "select",
										name = "Whisper Mode",
										order = 7,
										width = "full",
										desc = "The action new whispers take by default",
										values = {
											popout = "Popout",
											inline = "Inline",
											popout_and_inline = "Popout and Inline",
										},
										sorting = {
											"popout",
											"inline",
											"popout_and_inline",
										},
										get = function(info) return CVars.getCVar("whisperMode") end,
										set = function(info, v) CVars.setCVar("whisperMode", v) end,
									},
									AutoPushSpellToActionBar = {
										type = "toggle",
										name = "Auto Push Spell To Action Bar",
										order = 8,
										width = "full",
										desc = "Automatically push spells to the action bar when learned",
										get = function(info) return CVars.getCVar("AutoPushSpellToActionBar") end,
										set = function(info, v) CVars.setCVar("AutoPushSpellToActionBar", v) end,
									},
									countdownForCooldowns = {
										type = "toggle",
										name = "Countdown For Cooldowns",
										order = 9,
										width = "full",
										desc = "Show countdown for cooldowns",
										get = function(info) return CVars.getCVar("countdownForCooldowns") end,
										set = function(info, v) CVars.setCVar("countdownForCooldowns", v) end,
									},
									showDungeonEntrancesOnMap = {
										type = "toggle",
										name = "Show Dungeon Entrances On Map",
										order = 10,
										width = "full",
										desc = "Toggle showing dungeon entrances on the world map",
										get = function(info) return CVars.getCVar("showDungeonEntrancesOnMap") end,
										set = function(info, v) CVars.setCVar("showDungeonEntrancesOnMap", v) end,
									}
								}
							}
						}
					},
				},
			},
		},
	}

	-- Register options
	config:RegisterOptionsTable("WilduTools", options)
	self.optionsFrames = {}
	self.optionsFrames.general = configDialog:AddToBlizOptions("WilduTools", "WilduTools", nil, "general")


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
end


function addon:ShowConfig()
	Settings.OpenToCategory("WilduTools")
end



local MountableEventFrame = CreateFrame("Frame", nil, UIParent)
MountableEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
MountableEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
MountableEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
MountableEventFrame:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
MountableEventFrame:SetScript("OnEvent", function(ev1, e2)
	print(e1, e2)
	-- Do druid form and mount icon logic HERE
	-- Mount logic - if mount usable - true
	-- if flyable area - flying icon
	-- if ground area - ground mount icon (maybe different mount ids?)
	
	-- mountable icon option - hide in combat

	-- all icon options - strata 
end)