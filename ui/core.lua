local _, ns = ...

--- WilduUI Core Module
--- Provides shared helper functions for UI frame management, EditMode integration,
--- and visibility drivers used across all WilduUI components.
local WilduUICore = {}
ns.WilduUICore = WilduUICore

local LEM = LibStub('LibEditMode')

-- ============================================================================
-- CONSTANTS & CONFIGURATION
-- ============================================================================

local HIDDEN_POSITION = { point = 'TOP', x = 0, y = 500 }
local DEFAULT_SCALE = 1
local DEFAULT_ALPHA = 1

-- Default configuration fallback
local FRAME_DEFAULT_CONFIG = {
    point = 'CENTER',
    x = 0,
    y = 0,
    scale = DEFAULT_SCALE,
    alpha = DEFAULT_ALPHA,
}

-- ============================================================================
-- FRAME CONFIGURATION HELPERS
-- ============================================================================

---Ensure and load frame configuration with comprehensive fallback chain
---@param configKey string The database key in editMode (e.g., "rangeCheck", "mountIcon")
---@param defaultConfig? table Default position/settings table (applied to profile first)
---@return table config The configuration table with all properties resolved
function WilduUICore.LoadFrameConfig(configKey, defaultConfig)
    -- Ensure editMode database structure exists
    defaultConfig = defaultConfig or {}
    if not ns.Addon.db.profile.editMode then
        ns.Addon.db.profile.editMode = {}
    end

    -- Initialize config entry if missing
    if not ns.Addon.db.profile.editMode[configKey] then
        ns.Addon.db.profile.editMode[configKey] = {}
    end

    local storedConfig = ns.Addon.db.profile.editMode[configKey]

    -- Build result with three-tier fallback: stored → defaultConfig → DEFAULT_CONFIG
    local result = {}
    
    -- Get all unique keys from all sources
    local allKeys = {}
    for key in pairs(FRAME_DEFAULT_CONFIG) do
        allKeys[key] = true
    end
    for key in pairs(defaultConfig) do
        allKeys[key] = true
    end
    for key in pairs(storedConfig) do
        allKeys[key] = true
    end

    -- Apply fallback chain for each property
    for key in pairs(allKeys) do
        result[key] = storedConfig[key] or defaultConfig[key] or FRAME_DEFAULT_CONFIG[key]
    end

    -- Update stored config to ensure missing properties are persisted
    for key, value in pairs(result) do
        if storedConfig[key] == nil then
            storedConfig[key] = value
        end
    end

    return result
end

---Apply position and scale to a frame from config
---@param frame Frame The frame to position
---@param configKey string The database key
---@param shouldHide boolean Whether to hide (move off-screen) the frame
function WilduUICore.ApplyFramePosition(frame, configKey, shouldHide)
    local config = ns.Addon.db.profile.editMode[configKey]
    
    frame:ClearAllPoints()
	
    if shouldHide then
        frame:SetPoint(HIDDEN_POSITION.point, UIParent, HIDDEN_POSITION.point, 
                       HIDDEN_POSITION.x, HIDDEN_POSITION.y)
    else
        frame:SetPoint("CENTER", UIParent, config.point or 'CENTER', 
                       config.x or 0, config.y or 0)
    end
    
    frame:SetScale(config.scale)
    if frame.SetAlpha then
        frame:SetAlpha(config.alpha)
    end
end

-- ============================================================================
-- EDITMODE INTEGRATION HELPERS
-- ============================================================================

---Create standard position-changed callback for LEM
---@param configKey string The database key
---@return function callback Callback function for LEM
function WilduUICore.CreateOnPositionChanged(configKey)
    return function(frame, layoutName, point, x, y)
        ns.Addon.db.profile.editMode[configKey].point = point
        ns.Addon.db.profile.editMode[configKey].y = y

		if ns.Addon.db.profile.editMode[configKey].lockHorizontal then
			ns.Addon.db.profile.editMode[configKey].x = 0
			WilduUICore.ApplyFramePosition(frame, configKey, false)
		else
			ns.Addon.db.profile.editMode[configKey].x = x
		end
    end
end

---Register standard EditMode callbacks (enter/layout)
---@param frame Frame The frame to register callbacks for
---@param configKey string The database key
---@param enabledCheckFn function Function that returns whether frame should be visible
function WilduUICore.RegisterEditModeCallbacks(frame, configKey, enabledCheckFn)
    LEM:RegisterCallback('enter', function()
        local shouldHide = not enabledCheckFn()
         if frame._wt_VisibilityDriver then 
            if UnregisterStateDriver then pcall(UnregisterStateDriver, frame, "visibility") end
        end
        if not frame:IsShown() then 
            frame:Show()
            frame._wt_hideOnEditModeExit = true
        end
        WilduUICore.ApplyFramePosition(frame, configKey, shouldHide)
    end)
    
    LEM:RegisterCallback('exit', function()
        if frame._wt_VisibilityDriver then 
            if RegisterStateDriver then pcall(RegisterStateDriver, frame, "visibility", frame._wt_VisibilityDriver) end
        end
        if frame._wt_hideOnEditModeExit then
            frame._wt_hideOnEditModeExit = nil
            frame:Hide()
        end
    end)

    LEM:RegisterCallback('layout', function(layoutName)
        WilduUICore.LoadFrameConfig(configKey)
        local shouldHide = not enabledCheckFn()
        WilduUICore.ApplyFramePosition(frame, configKey, shouldHide)
    end)
end

---Create a Scale slider setting for LEM
---@param configKey string The database key
---@param defaultValue? number Default scale value
---@return table setting LEM setting configuration
function WilduUICore.CreateScaleSetting(configKey, defaultValue)
    defaultValue = defaultValue or DEFAULT_SCALE
    return {
        name = 'Scale',
        kind = LEM.SettingType.Slider,
        default = defaultValue,
        get = function()
            return ns.Addon.db.profile.editMode[configKey].scale or defaultValue
        end,
        set = function(layoutName, value)
            ns.Addon.db.profile.editMode[configKey].scale = value
        end,
        minValue = 0.1,
        maxValue = 5,
        valueStep = 0.1,
        formatter = function(value)
            return FormatPercentage(value, true)
        end,
    }
end

---Create an Alpha slider setting for LEM
---@param configKey string The database key
---@param defaultValue? number Default alpha value
---@return table setting LEM setting configuration
function WilduUICore.CreateAlphaSetting(configKey, defaultValue)
    defaultValue = defaultValue or DEFAULT_ALPHA
    return {
        name = 'Alpha',
        kind = LEM.SettingType.Slider,
        default = defaultValue,
        get = function()
            return ns.Addon.db.profile.editMode[configKey].alpha or defaultValue
        end,
        set = function(layoutName, value)
            ns.Addon.db.profile.editMode[configKey].alpha = value
        end,
        minValue = 0,
        maxValue = 1,
        valueStep = 0.01,
        formatter = function(value)
            return string.format("%.2f", value)
        end,
    }
end

---Register a frame with LEM and apply settings
---@param frame Frame The frame to register
---@param configKey string The database key
---@param additionalSettings? table[] Additional LEM settings beyond Scale
function WilduUICore.RegisterFrameWithLEM(frame, configKey, additionalSettings)
    additionalSettings = additionalSettings or {}
    local config = WilduUICore.LoadFrameConfig(configKey)

    LEM:AddFrame(frame, WilduUICore.CreateOnPositionChanged(configKey), config)
    
    local settings = {
        WilduUICore.CreateScaleSetting(configKey, config.scale or FRAME_DEFAULT_CONFIG.scale),
    }
    
    -- Add scale update to frame
    settings[1].set = function(layoutName, value)
        ns.Addon.db.profile.editMode[configKey].scale = value
        frame:SetScale(value)
    end
    
    -- Append additional settings
    for _, setting in ipairs(additionalSettings) do
        table.insert(settings, setting)
    end
    
    LEM:AddFrameSettings(frame, settings)
end

-- ============================================================================
-- UPDATE & THROTTLING HELPERS
-- ============================================================================

---Wrap frame update logic with throttling
---@param frame Frame The frame to apply throttling to
---@param throttleInterval number Seconds between updates
---@param updateFn function Function to call for update logic
function WilduUICore.CreateThrottledUpdate(frame, throttleInterval, updateFn)
    frame._wt_throttle = 0
    frame:SetScript("OnUpdate", function(self)
        if GetTime() < self._wt_throttle then
            return
        end
        self._wt_throttle = GetTime() + throttleInterval
        updateFn(self)
    end)
end

---Wrap update logic with a repeating C_Timer.NewTicker
---@param frame Frame The frame to associate the ticker with
---@param interval number Seconds between updates
---@param updateFn function Function to call for update logic
---@param checkForIsShown? boolean Check for frame visibility, if hidden won't call callback
function WilduUICore.CreateTickerUpdate(frame, interval, updateFn, checkForIsShown)
    if not frame or not interval or not updateFn then
        return
    end

    -- Cancel previous ticker if it exists
    if frame._wt_ticker and frame._wt_ticker.Cancel then
        frame._wt_ticker:Cancel()
        frame._wt_ticker = nil
    end

    -- Create new repeating ticker
    frame._wt_ticker = C_Timer.NewTicker(interval, function()
        if not checkForIsShown or frame:IsShown() then
            updateFn(frame)
        end
    end)
end

-- ============================================================================
-- VISIBILITY DRIVER HELPERS
-- ============================================================================

local ApplyVisibilityDriverToFrame
local visiblityDriverPostCombatFrame = CreateFrame("Frame", nil, UIParent)
visiblityDriverPostCombatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
visiblityDriverPostCombatFrame.delayedApplications = {}
visiblityDriverPostCombatFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" and not InCombatLockdown() then
        for i, application in ipairs(visiblityDriverPostCombatFrame.delayedApplications) do
            ApplyVisibilityDriverToFrame(application.frame, application.expression)
        end
        visiblityDriverPostCombatFrame.delayedApplications = {}
    end
end)

---Apply or remove a visibility state driver for a frame
---Automatically defers application until after combat if currently in combat
---@param frame Frame The WoW UI frame to manage visibility for
---@param expression? string State driver expression (nil to remove driver) - https://warcraft.wiki.gg/wiki/Macro_conditionals
---@param shouldHideInCombat? boolean If true, hides frame immediately when in combat
---
---Example expressions:
---  "[target=target,exists] show; hide"
---  "[advflyable, mounted] show; [advflyable, stance:3] show; hide"
ApplyVisibilityDriverToFrame = function (frame, expression, shouldHideInCombat)
    if not frame then return end
    if InCombatLockdown() then
        if shouldHideInCombat then
            frame:Hide()
        end
        table.insert(visiblityDriverPostCombatFrame.delayedApplications, {
            frame = frame,
            expression = expression
        })
        return
    end
    if not expression then
        if frame._wt_VisibilityDriver then
            if UnregisterStateDriver then pcall(UnregisterStateDriver, frame, "visibility") end
            frame._wt_VisibilityDriver = nil
        end
        return
    end
    if frame._wt_VisibilityDriver == expression then return end
    if RegisterStateDriver then
        local ok = pcall(RegisterStateDriver, frame, "visibility", expression)
        if ok then frame._wt_VisibilityDriver = expression end
    end
end

WilduUICore.ApplyVisibilityDriverToFrame = ApplyVisibilityDriverToFrame

return WilduUICore
