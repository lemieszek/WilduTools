local _, ns = ...
local LSM = LibStub("LibSharedMedia-3.0")
local LEM = LibStub('LibEditMode')
local WilduUI = {}

local API = ns.API
ns.WilduUI = WilduUI
local DEBUG = ns.DEBUG


-- ============================================================================
-- CONSTANTS & CONFIGURATION
-- ============================================================================


local HIDDEN_POSITION = { point = 'TOP', x = 0, y = 500 }
local DEFAULT_SCALE = 1
local DEFAULT_ALPHA = 1


-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================


-- Default configuration fallback
local FRAME_DEFAULT_CONFIG = {
    point = 'CENTER',
    x = 0,
    y = 0,
    scale = DEFAULT_SCALE,
    alpha = DEFAULT_ALPHA,
}

---Ensure and load frame configuration with comprehensive fallback chain
---@param configKey string The database key in editMode (e.g., "rangeCheck", "mountIcon")
---@param defaultConfig table Default position/settings table (applied to profile first)
---@return table The configuration table with all properties resolved
local function LoadFrameConfig(configKey, defaultConfig)
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
local function ApplyFramePosition(frame, configKey, shouldHide)
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


---Create standard position-changed callback for LEM
---@param configKey string The database key
---@return function Callback function for LEM
local function CreateOnPositionChanged(configKey)
    return function(frame, layoutName, point, x, y)
        ns.Addon.db.profile.editMode[configKey].point = point
        ns.Addon.db.profile.editMode[configKey].y = y

		if ns.Addon.db.profile.editMode[configKey].lockHorizontal then
			ns.Addon.db.profile.editMode[configKey].x = 0
			ApplyFramePosition(frame, configKey, false)
			-- print("changed")
		else
			ns.Addon.db.profile.editMode[configKey].x = x
		end
    end
end


---Register standard EditMode callbacks (enter/layout)
---@param frame Frame The frame to register callbacks for
---@param configKey string The database key
---@param enabledCheckFn function Function that returns whether frame should be visible
local function RegisterEditModeCallbacks(frame, configKey, enabledCheckFn)
    LEM:RegisterCallback('enter', function()
        local shouldHide = not enabledCheckFn()
        ApplyFramePosition(frame, configKey, shouldHide)
    end)
    
    LEM:RegisterCallback('layout', function(layoutName)
        LoadFrameConfig(configKey)
        local shouldHide = not enabledCheckFn()
        ApplyFramePosition(frame, configKey, shouldHide)
    end)
end


---Create a Scale slider setting for LEM
---@param configKey string The database key
---@param defaultValue number Default scale value
---@return table LEM setting configuration
local function CreateScaleSetting(configKey, defaultValue)
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
---@param defaultValue number Default alpha value
---@return table LEM setting configuration
local function CreateAlphaSetting(configKey, defaultValue)
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
            -- Actual frame update in settings dict
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
---@param additionalSettings table[] Additional LEM settings beyond Scale
local function RegisterFrameWithLEM(frame, configKey, additionalSettings)
    additionalSettings = additionalSettings or {}
    local config = LoadFrameConfig(configKey)

    LEM:AddFrame(frame, CreateOnPositionChanged(configKey), config)
    
    local settings = {
        CreateScaleSetting(configKey, config.scale or FRAME_DEFAULT_CONFIG.scale),
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


---Wrap frame update logic with throttling
---@param frame Frame The frame to apply throttling to
---@param throttleInterval number Seconds between updates
---@param updateFn function Function to call for update logic
local function CreateThrottledUpdate(frame, throttleInterval, updateFn)
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
---@param checkForIsShown boolean check for frame visibility, if hidden won't call callback
local function CreateTickerUpdate(frame, interval, updateFn,checkForIsShown)
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

---Apply or remove a visibility state driver for a frame
---@param frame Frame The WoW UI frame to manage visibility for
---@param expression string|nil State driver expression (nil to remove driver) - https://warcraft.wiki.gg/wiki/Macro_conditionals - ex "[advflyable, mounted] show; [advflyable, stance:3] show; hide"
local function ApplyVisibilityDriverToFrame(frame, expression)
    if not frame then return end
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


-- ============================================================================
-- RANGE FRAME
-- ============================================================================


local rangeFrame = CreateFrame("Frame", "WilduTools Range Frame", UIParent)


function WilduUI.InitializeRangeFrame()
    DEBUG.startDebugTimer("WILDUUI_INIT_RANGEFRAME_START")
    local CONFIG_KEY = "rangeCheck"
    if rangeFrame._wt_initialized then
        ApplyFramePosition(rangeFrame, CONFIG_KEY, not ns.Addon.db.profile.wilduUI_targetRangeFrame)
        return
    end
    rangeFrame._wt_initialized = true
    
    
    rangeFrame:SetSize(120, 24)
    local config = LoadFrameConfig(CONFIG_KEY)
    rangeFrame.text = rangeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    rangeFrame.text:SetPoint("LEFT", rangeFrame, "LEFT")
    rangeFrame.text:SetText("")

    ApplyFramePosition(rangeFrame, CONFIG_KEY, not ns.Addon.db.profile.wilduUI_targetRangeFrame)
    
    local function updateRangeText()
        local min, max = API:GetRange("target")
        if min or max then
            local rangeText = max and string.format("%d - %d", min, max) or string.format("%d+", min)
            rangeFrame.text:SetText(rangeText)
            rangeFrame:SetAlpha(1)
        else
            rangeFrame.text:SetText("")
            rangeFrame:SetAlpha(0)

        end
    end

    ApplyVisibilityDriverToFrame(rangeFrame, "[target=target,exists] show; hide")
    CreateTickerUpdate(rangeFrame, 0.5, function()
        
        if LEM:IsInEditMode() then
            return
        end
        if not ns.Addon.db.profile.wilduUI_targetRangeFrame then
            rangeFrame.text:SetText("")
            rangeFrame:SetAlpha(0)
            return
        end
        updateRangeText()
    end)
    rangeFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    rangeFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "PLAYER_TARGET_CHANGED" then
            updateRangeText()
        end
    end)
    
    RegisterEditModeCallbacks(rangeFrame, CONFIG_KEY, function()
        return ns.Addon.db.profile.wilduUI_targetRangeFrame
    end)
    
    RegisterFrameWithLEM(rangeFrame, CONFIG_KEY)
    
    DEBUG.checkpointDebugTimer("WILDUUI_INIT_RANGEFRAME_DONE", "WILDUUI_INIT_RANGEFRAME_START")
end


-- ============================================================================
-- MOUNT FRAME
-- ============================================================================


local mountFrame = CreateFrame("Frame", "WilduTools Mount Frame", UIParent)


function WilduUI.InitializeMountableAreaIndicator()
    DEBUG.startDebugTimer("WILDUUI_INIT_MOUNTFRAME_START")
    local CONFIG_KEY = "mountIcon"
    if mountFrame._wt_initialized then
        ApplyFramePosition(mountFrame, CONFIG_KEY, not ns.Addon.db.profile.wilduUI_mountableArea)
        return
    end
    mountFrame._wt_initialized = true
    
    local DEFAULT_CONFIG = { y = 50 }
    mountFrame:SetSize(32, 32)
    local config = LoadFrameConfig(CONFIG_KEY, DEFAULT_CONFIG)

    
    mountFrame.icon = mountFrame:CreateTexture(nil, "OVERLAY")
    mountFrame.icon:SetAllPoints(mountFrame)
    mountFrame.icon:SetAtlas("Fyrakk-Flying-Icon", true)
    
    ApplyFramePosition(mountFrame, CONFIG_KEY, not ns.Addon.db.profile.wilduUI_mountableArea)


    ApplyVisibilityDriverToFrame(mountFrame, "[outdoors,nocombat] show; [advflyable] show; hide")
    
    RegisterEditModeCallbacks(mountFrame, CONFIG_KEY, function()
        return ns.Addon.db.profile.wilduUI_mountableArea
    end)
    
    RegisterFrameWithLEM(mountFrame, CONFIG_KEY)
    
    DEBUG.checkpointDebugTimer("WILDUUI_INIT_MOUNTFRAME_DONE", "WILDUUI_INIT_MOUNTFRAME_START")
end

-- ============================================================================
-- SPELL ON COOLDOWN FRAME
-- ============================================================================


local spellOnCDFrame = CreateFrame("Frame", "WilduTools_SpellOnCD", UIParent)
spellOnCDFrame:SetSize(30, 30)
spellOnCDFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
spellOnCDFrame:SetScale(1)


spellOnCDFrame.icon = spellOnCDFrame:CreateTexture(nil, "OVERLAY")
spellOnCDFrame.icon:SetAllPoints()


spellOnCDFrame.cooldown = CreateFrame("Cooldown", nil, spellOnCDFrame, "CooldownFrameTemplate")
spellOnCDFrame.cooldown:SetAllPoints()


spellOnCDFrame:SetAlpha(0)
spellOnCDFrame._timer = nil
spellOnCDFrame._timer_iterations = 0


local spellOnCDEventFrame = nil


function WilduUI.InitializeSpellOnCD()
    local CONFIG_KEY = "spellOnCD"
    if spellOnCDFrame._wt_initialized then return end
    spellOnCDFrame._wt_initialized = true
    
    local DEFAULT_CONFIG = { x = -50 }
    
    local config = LoadFrameConfig(CONFIG_KEY, DEFAULT_CONFIG)
    
    spellOnCDFrame:ClearAllPoints()
    spellOnCDFrame:SetPoint("CENTER", UIParent, config.point or 'CENTER', 
                             config.x or 0, config.y or 0)
    spellOnCDFrame:SetScale(config.scale)
    spellOnCDFrame:SetAlpha(config.alpha)
    
    -- Apply initial zoom
    local function ApplyZoom(zoomValue)
        if spellOnCDFrame.icon then
            local left = (zoomValue or 0) / 2
            local right = 1 - (zoomValue or 0) / 2
            spellOnCDFrame.icon:SetTexCoord(left, right, left, right)
        end
    end
    
    ApplyZoom(config.zoom or 0)
    
    RegisterEditModeCallbacks(spellOnCDFrame, CONFIG_KEY, function()
        return ns.Addon.db.profile.wilduUI_spellOnCD
    end)
    
    local additionalSettings = {
        CreateAlphaSetting(CONFIG_KEY, DEFAULT_ALPHA),
        {
            name = 'Zoom (%)',
            kind = LEM.SettingType.Slider,
            default = 0,
            get = function()
                return (ns.Addon.db.profile.editMode[CONFIG_KEY].zoom or 0) * 100
            end,
            set = function(layoutName, value)
                ns.Addon.db.profile.editMode[CONFIG_KEY].zoom = (value or 0) / 100
                ApplyZoom(ns.Addon.db.profile.editMode[CONFIG_KEY].zoom)
            end,
            minValue = 0,
            maxValue = 50,
            valueStep = 1,
            formatter = function(v)
                return tostring(v) .. "%"
            end,
        }
    }
    
    RegisterFrameWithLEM(spellOnCDFrame, CONFIG_KEY, DEFAULT_CONFIG, additionalSettings)
    
    -- Event handler for spell cast failure
    spellOnCDEventFrame = CreateFrame("Frame", "WilduTools_SpellOnCD_Event", UIParent)
    spellOnCDEventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    spellOnCDEventFrame:SetScript("OnEvent", function(self, event, unitTarget, _, spellID)
        if not ns.Addon.db.profile.wilduUI_spellOnCD then return end
        if unitTarget ~= "player" then return end
        
        local spell = C_Spell.GetSpellInfo(spellID)
        if spell and spell.iconID then
            spellOnCDFrame.icon:SetTexture(spell.iconID)
            ApplyZoom(ns.Addon.db.profile.editMode[CONFIG_KEY].zoom or 0)
        end
        
        local cooldownInfo = C_Spell.GetSpellCooldown(spellID)
        if cooldownInfo then
            spellOnCDFrame.icon:SetAlpha(1)
            spellOnCDFrame.cooldown:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration)
        end
        
        -- Cancel existing timer
        if spellOnCDFrame._timer then
            spellOnCDFrame._timer:Cancel()
            spellOnCDFrame._timer = nil
            spellOnCDFrame._timer_iterations = 0
        end
        
        -- Fade out animation
        spellOnCDFrame._timer = C_Timer.NewTicker(0.025, function()
            spellOnCDFrame._timer_iterations = spellOnCDFrame._timer_iterations + 1
            local alpha = math.min(4 - (spellOnCDFrame._timer_iterations / 10), 1)
            spellOnCDFrame.icon:SetAlpha(alpha)
            spellOnCDFrame.cooldown:SetAlpha(alpha)
            if alpha <= 0 then
                spellOnCDFrame.cooldown:Clear()
            end
        end, 40)
    end)
end


-- ============================================================================
-- CROSSHAIR FRAME
-- ============================================================================


local crosshairParent = CreateFrame("Frame", "WilduTools Crosshair", UIParent)
crosshairParent._wt_initialized = false

function WilduUI.InitializeCrosshair()
    local CONFIG_KEY = "crosshair"
    if crosshairParent._wt_initialized then 
        ApplyFramePosition(crosshairParent, CONFIG_KEY, not ns.Addon.db.profile.wilduUI_crosshair)
        return
    end
    crosshairParent._wt_initialized = true
    
    local DEFAULT_CONFIG = {
        thickness = 4,
        inner_length = 24,
        border_size = 4,
		lockHorizontal = false,
        class_colored = true,
		customR = 1,
		customG = 1,
		customB = 1,
		visibility = "Always"
    }
    
    local config = LoadFrameConfig(CONFIG_KEY, DEFAULT_CONFIG)
    
    local thickness = config.thickness
    local inner_length = config.inner_length
    local border_size = config.border_size
    local class_colored = config.class_colored

    crosshairParent:SetSize(inner_length + thickness + border_size, 
                            inner_length + thickness + border_size)

    ApplyFramePosition(crosshairParent, CONFIG_KEY, not ns.Addon.db.profile.wilduUI_crosshair)



    local function getClassColor()
        local _, class = UnitClass("player")
        local cc = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class]) or RAID_CLASS_COLORS[class]
        if cc then
            return cc.r, cc.g, cc.b
        end
        return 1, 1, 1
    end
    
    local function makeBar(name, width, height, point, relPoint, x, y, level)
        local f = CreateFrame("Frame", name, crosshairParent)
        f:SetSize(width, height)
        f:SetPoint(point, crosshairParent, relPoint, x, y)
        f:EnableMouse(false)
        local t = f:CreateTexture(nil, "BACKGROUND")
        t:SetDrawLayer("BACKGROUND", level)
        t:SetAllPoints()
        f.tex = t
        return f
    end
    
    local outerVertical = makeBar("Wildu_CrossOuterVertical", thickness + border_size, 
                                  inner_length + border_size, "CENTER", "CENTER", 0, 0, 0)
    local outerHorizontal = makeBar("Wildu_CrossOuterHorizontal", inner_length + border_size, 
                                    thickness + border_size, "CENTER", "CENTER", 0, 0, 0)
    local innerVertical = makeBar("Wildu_CrossInnerVertical", thickness, 
                                  inner_length, "CENTER", "CENTER", 0, 0, 1)
    local innerHorizontal = makeBar("Wildu_CrossInnerHorizontal", inner_length, 
                                    thickness, "CENTER", "CENTER", 0, 0, 1)
    
	local function UpdateColor()
		local a = ns.Addon.db.profile.editMode[CONFIG_KEY].alpha
		local class_col = ns.Addon.db.profile.editMode[CONFIG_KEY].class_colored

		if class_col == nil or class_col then
			-- Use class color
			local rr, gg, bb = getClassColor()
			innerVertical.tex:SetColorTexture(rr, gg, bb, a)
			innerHorizontal.tex:SetColorTexture(rr, gg, bb, a)
		else
			-- Use custom color sliders
			local r = ns.Addon.db.profile.editMode[CONFIG_KEY].customR or 1
			local g = ns.Addon.db.profile.editMode[CONFIG_KEY].customG or 1
			local b = ns.Addon.db.profile.editMode[CONFIG_KEY].customB or 1
			innerVertical.tex:SetColorTexture(r, g, b, a)
			innerHorizontal.tex:SetColorTexture(r, g, b, a)
		end

		outerHorizontal.tex:SetColorTexture(0, 0, 0, a)
		outerVertical.tex:SetColorTexture(0, 0, 0, a)
	end

    
    -- Initial coloring
    UpdateColor()


	CreateThrottledUpdate(crosshairParent, 1, function(self)
		if not ns.Addon.db.profile.wilduUI_crosshair then
			self:SetAlpha(0)
			return
		end
		
		-- PREVIEW IN EDIT MODE
		if LEM:IsInEditMode() then
			self:SetAlpha(1)
			return
		end
		
		local visibility = ns.Addon.db.profile.editMode[CONFIG_KEY].visibility or 'Always'
		local inCombat = UnitAffectingCombat("player")
		local inInstance = IsInInstance()

		local shouldShow = false
		if visibility == 'Always' then
			shouldShow = true
		elseif visibility == 'In Combat' then
			shouldShow = inCombat
		elseif visibility == 'In Instance' then
			shouldShow = inInstance
		elseif visibility == 'In Combat + In Instance' then
			shouldShow = inCombat and inInstance
		end

		self:SetAlpha(shouldShow and 1 or 0)
	end)

    RegisterEditModeCallbacks(crosshairParent, CONFIG_KEY, function()
        return ns.Addon.db.profile.wilduUI_crosshair
    end)
    
    local additionalSettings = {
        CreateAlphaSetting(CONFIG_KEY, DEFAULT_CONFIG.alpha),
        {
            name = 'Thickness',
            kind = LEM.SettingType.Slider,
            default = DEFAULT_CONFIG.thickness,
            get = function()
                return ns.Addon.db.profile.editMode[CONFIG_KEY].thickness
            end,
            set = function(_, v)
                ns.Addon.db.profile.editMode[CONFIG_KEY].thickness = v
                local b = ns.Addon.db.profile.editMode[CONFIG_KEY].border_size or border_size
                local il = ns.Addon.db.profile.editMode[CONFIG_KEY].inner_length or inner_length
                innerVertical:SetSize(v, il)
                innerHorizontal:SetSize(il, v)
                outerVertical:SetSize(v + b, il + b)
                outerHorizontal:SetSize(il + b, v + b)
            end,
            minValue = 1,
            maxValue = 32,
            valueStep = 1,
        },
        {
            name = 'Inner length',
            kind = LEM.SettingType.Slider,
            default = DEFAULT_CONFIG.inner_length,
            get = function()
                return ns.Addon.db.profile.editMode[CONFIG_KEY].inner_length
            end,
            set = function(_, v)
                ns.Addon.db.profile.editMode[CONFIG_KEY].inner_length = v
                local t = ns.Addon.db.profile.editMode[CONFIG_KEY].thickness or thickness
                local b = ns.Addon.db.profile.editMode[CONFIG_KEY].border_size or border_size
                innerVertical:SetSize(t, v)
                innerHorizontal:SetSize(v, t)
                outerVertical:SetSize(t + b, v + b)
                outerHorizontal:SetSize(v + b, t + b)
            end,
            minValue = 4,
            maxValue = 256,
            valueStep = 1,
        },
        {
            name = 'Border size',
            kind = LEM.SettingType.Slider,
            default = DEFAULT_CONFIG.border_size,
            get = function()
                return ns.Addon.db.profile.editMode[CONFIG_KEY].border_size
            end,
            set = function(_, v)
                ns.Addon.db.profile.editMode[CONFIG_KEY].border_size = v
                local t = ns.Addon.db.profile.editMode[CONFIG_KEY].thickness or thickness
                local il = ns.Addon.db.profile.editMode[CONFIG_KEY].inner_length or inner_length
                outerVertical:SetSize(t + v, il + v)
                outerHorizontal:SetSize(il + v, t + v)
            end,
            minValue = 0,
            maxValue = 64,
            valueStep = 1,
        },
		{
			name = 'Lock Horizontal',
			kind = LEM.SettingType.Checkbox,
			default = DEFAULT_CONFIG.lockHorizontal,
			get = function()
				return ns.Addon.db.profile.editMode[CONFIG_KEY].lockHorizontal
			end,
			set = function(_, v)
				ns.Addon.db.profile.editMode[CONFIG_KEY].lockHorizontal = v
				if v then
					ns.Addon.db.profile.editMode[CONFIG_KEY].x = 0
					crosshairParent:ClearAllPoints()
					crosshairParent:SetPoint("CENTER", UIParent, config.point or 'CENTER', 0, config.y or 0)
				end
			end,
		},
        {
            name = 'Class colored',
            kind = LEM.SettingType.Checkbox,
            default = DEFAULT_CONFIG.class_colored,
            get = function()
                return ns.Addon.db.profile.editMode[CONFIG_KEY].class_colored
            end,
            set = function(_, v)
                ns.Addon.db.profile.editMode[CONFIG_KEY].class_colored = v
                UpdateColor()
            end,
        },
		{
			name = 'Red',
			kind = LEM.SettingType.Slider,
			default = DEFAULT_CONFIG.customR,
			disabled = function()
				return ns.Addon.db.profile.editMode[CONFIG_KEY].class_colored
			end,
			get = function()
				return ns.Addon.db.profile.editMode[CONFIG_KEY].customR or 1
			end,
			set = function(_, v)
				ns.Addon.db.profile.editMode[CONFIG_KEY].customR = v
				UpdateColor()
			end,
			minValue = 0,
			maxValue = 1,
			valueStep = 0.01,
			isPercent = false,
			formatter = function(v)
				return string.format("%.2f", v)
			end,
		},
		{
			name = 'Green',
			kind = LEM.SettingType.Slider,
			default = DEFAULT_CONFIG.customG,
			disabled = function()
				return ns.Addon.db.profile.editMode[CONFIG_KEY].class_colored
			end,
			get = function()
				return ns.Addon.db.profile.editMode[CONFIG_KEY].customG or 1
			end,
			set = function(_, v)
				ns.Addon.db.profile.editMode[CONFIG_KEY].customG = v
				UpdateColor()
			end,
			minValue = 0,
			maxValue = 1,
			valueStep = 0.01,
			isPercent = false,
			formatter = function(v)
				return string.format("%.2f", v)
			end,
		},
		{
			name = 'Blue',
			kind = LEM.SettingType.Slider,
			default = DEFAULT_CONFIG.customB,
			disabled = function()
				return ns.Addon.db.profile.editMode[CONFIG_KEY].class_colored
			end,
			get = function()
				return ns.Addon.db.profile.editMode[CONFIG_KEY].customB or 1
			end,
			set = function(_, v)
				ns.Addon.db.profile.editMode[CONFIG_KEY].customB = v
				UpdateColor()
			end,
			minValue = 0,
			maxValue = 1,
			valueStep = 0.01,
			isPercent = false,
			formatter = function(v)
				return string.format("%.2f", v)
			end,
		},
		{
			name = 'Visibility',
			kind = LEM.SettingType.Dropdown,
			default = DEFAULT_CONFIG.visibility,
			get = function()
				return ns.Addon.db.profile.editMode[CONFIG_KEY].visibility or 'Always'
			end,
			set = function(_, v)
				ns.Addon.db.profile.editMode[CONFIG_KEY].visibility = v
			end,
			values = {
				{ text = "Always", isRadio = true },
				{ text = "In Combat", isRadio = true },
				{ text = "In Instance", isRadio = true },
				{ text = "In Combat + In Instance", isRadio = true },
    		},
		},
	}
    RegisterFrameWithLEM(crosshairParent, CONFIG_KEY, DEFAULT_CONFIG, additionalSettings)
    
end

-- ============================================================================
-- PLAYER IN COMBAT INDICATOR
-- ============================================================================

local playerCombatFrame = CreateFrame("Frame", "WilduTools Player Combat", UIParent)

function WilduUI.InitializePlayerCombatIndicator()
    local CONFIG_KEY = "playerCombat"
    if playerCombatFrame._wt_initialized then 
        ApplyFramePosition(playerCombatFrame, CONFIG_KEY, not ns.Addon.db.profile.wilduUI_playerCombat)
        return 
    end
    playerCombatFrame._wt_initialized = true
    
    local DEFAULT_CONFIG = { x = -50, y = -50 }
    
    playerCombatFrame:SetSize(32, 32)
    local config = LoadFrameConfig(CONFIG_KEY, DEFAULT_CONFIG)
    
    playerCombatFrame.icon = playerCombatFrame:CreateTexture(nil, "OVERLAY")
    playerCombatFrame.icon:SetAllPoints(playerCombatFrame)
    playerCombatFrame.icon:SetTexture("Interface\\AddOns\\!WilduTools\\Media\\Icons\\CombatStylized.blp")
    
    ApplyFramePosition(playerCombatFrame, CONFIG_KEY, not ns.Addon.db.profile.wilduUI_playerCombat)
    
    if not ns.Addon.db.profile.wilduUI_playerCombat then
        playerCombatFrame.icon:SetAlpha(0)
    end
    
    ApplyVisibilityDriverToFrame(playerCombatFrame, "[combat] show; hide")
    
    RegisterEditModeCallbacks(playerCombatFrame, CONFIG_KEY, function()
        return ns.Addon.db.profile.wilduUI_playerCombat
    end)
    
    RegisterFrameWithLEM(playerCombatFrame, CONFIG_KEY)
end



-- ============================================================================
-- TARGET IN COMBAT INDICATOR
-- ============================================================================

local targetCombatFrame = CreateFrame("Frame", "WilduTools Target Combat", UIParent)

function WilduUI.InitializeTargetCombatIndicator()
    local CONFIG_KEY = "targetCombat"
    if targetCombatFrame._wt_initialized then
        ApplyFramePosition(targetCombatFrame, CONFIG_KEY, not ns.Addon.db.profile.wilduUI_targetCombat)
        return
    end
    targetCombatFrame._wt_initialized = true
    
    local DEFAULT_CONFIG = { x = 50, y = -50 }
    
    targetCombatFrame:SetSize(32, 32)
    local config = LoadFrameConfig(CONFIG_KEY, DEFAULT_CONFIG)

    
    targetCombatFrame.icon = targetCombatFrame:CreateTexture(nil, "OVERLAY")
    targetCombatFrame.icon:SetAllPoints(targetCombatFrame)
    targetCombatFrame.icon:SetTexture("Interface\\AddOns\\!WilduTools\\Media\\Icons\\CombatStylized.blp")

    ApplyFramePosition(targetCombatFrame, CONFIG_KEY, not ns.Addon.db.profile.wilduUI_targetCombat)
    
    ApplyVisibilityDriverToFrame(rangeFrame, "[target=target,exists] show; hide")
    CreateThrottledUpdate(targetCombatFrame, 0.1, function(self)
		if LEM:IsInEditMode() then
			self:SetAlpha(1)  -- Show at full alpha in edit mode
			return
		end
        
        if UnitExists("target") then
            local inCombat = UnitAffectingCombat("target")
            self:SetAlpha(inCombat and 1 or 0)
        else
            self:SetAlpha(0)
        end
    end)
    
    RegisterEditModeCallbacks(targetCombatFrame, CONFIG_KEY, function()
        return ns.Addon.db.profile.wilduUI_targetCombat
    end)
    
    RegisterFrameWithLEM(targetCombatFrame, CONFIG_KEY)
end