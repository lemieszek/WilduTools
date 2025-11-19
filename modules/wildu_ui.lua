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
local DEFAULT_THROTTLE = 0.1


-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================


---Ensure editMode database structure exists for a frame config key
---@param configKey string The database key in editMode (e.g., "rangeCheck", "mountIcon")
---@param defaultConfig table Default position/settings table
---@return table The configuration table
local function EnsureEditModeConfig(configKey, defaultConfig)
    if not ns.Addon.db.profile.editMode then
        ns.Addon.db.profile.editMode = {}
    end
    if not ns.Addon.db.profile.editMode[configKey] then
        ns.Addon.db.profile.editMode[configKey] = CopyTable(defaultConfig)
    end
    return ns.Addon.db.profile.editMode[configKey]
end


---Load position and scale from database with fallbacks
---@param configKey string The database key
---@param defaultConfig table Fallback defaults
---@return table Config with point, x, y, scale
local function LoadFrameConfig(configKey, defaultConfig)
    local config = EnsureEditModeConfig(configKey, defaultConfig)
    return {
        point = config.point or defaultConfig.point,
        x = config.x or defaultConfig.x,
        y = config.y or defaultConfig.y,
        scale = config.scale or DEFAULT_SCALE,
        alpha = config.alpha or DEFAULT_ALPHA,
    }
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
    
    frame:SetScale(config.scale or DEFAULT_SCALE)
    if frame.SetAlpha then
        frame:SetAlpha(config.alpha or DEFAULT_ALPHA)
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
        EnsureEditModeConfig(configKey, { point = 'CENTER', x = 0, y = 0 })
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
            -- This will be called on the actual frame in the settings dict
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
---@param defaultConfig table Default configuration
---@param additionalSettings table[] Additional LEM settings beyond Scale
local function RegisterFrameWithLEM(frame, configKey, defaultConfig, additionalSettings)
    additionalSettings = additionalSettings or {}
    
    LEM:AddFrame(frame, CreateOnPositionChanged(configKey), defaultConfig)
    
    local settings = {
        CreateScaleSetting(configKey, defaultConfig.scale or DEFAULT_SCALE),
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
    frame._throttle = 0
    frame:SetScript("OnUpdate", function(self)
        if GetTime() < self._throttle then
            return
        end
        self._throttle = GetTime() + throttleInterval
        updateFn(self)
    end)
end


-- ============================================================================
-- RANGE FRAME
-- ============================================================================


local rangeFrame = CreateFrame("Frame", "WilduTools Range Frame", UIParent)


function WilduUI.InitializeRangeFrame()
    DEBUG.startDebugTimer("WILDUUI_INIT_RANGEFRAME_START")
    if rangeFrame._wt_initialized then
        return
    end
    rangeFrame._wt_initialized = true
    
    local CONFIG_KEY = "rangeCheck"
    local DEFAULT_CONFIG = { point = 'CENTER', x = 0, y = 0, scale = 1 }
    
    rangeFrame:SetSize(120, 24)
    local config = LoadFrameConfig(CONFIG_KEY, DEFAULT_CONFIG)
    rangeFrame:SetPoint("CENTER", UIParent, config.point, config.x, config.y)
    rangeFrame:SetScale(config.scale)
    
    rangeFrame.text = rangeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    rangeFrame.text:SetPoint("LEFT", rangeFrame, "LEFT")
    rangeFrame.text:SetText("No Target")
    rangeFrame:Show()
    
    -- Throttled update
    CreateThrottledUpdate(rangeFrame, DEFAULT_THROTTLE, function(self)
        if not ns.Addon.db.profile.wilduUI_targetRangeFrame then
            self.text:SetText("")
            self:SetAlpha(0)
            return
        end
        
        self:SetAlpha(1)
        
        if not LEM:IsInEditMode() then
            if UnitExists("target") and not UnitIsDeadOrGhost("target") then
                local min, max = API:GetRange("target", true)
                if min or max then
                    local rangeText = max and string.format("%d - %d", min, max) or 
                                      string.format("%d+", min)
                    self.text:SetText(rangeText)
                else
                    self.text:SetText("")
                end
            else
                self.text:SetText("")
            end
        end
    end)
    
    RegisterEditModeCallbacks(rangeFrame, CONFIG_KEY, function()
        return ns.Addon.db.profile.wilduUI_targetRangeFrame
    end)
    
    RegisterFrameWithLEM(rangeFrame, CONFIG_KEY, DEFAULT_CONFIG, {})
    
    DEBUG.checkpointDebugTimer("WILDUUI_INIT_RANGEFRAME_DONE", "WILDUUI_INIT_RANGEFRAME_START")
end


-- ============================================================================
-- MOUNT FRAME
-- ============================================================================


local mountFrame = CreateFrame("Frame", "WilduTools Mount Frame", UIParent)


function WilduUI.InitializeMountableAreaIndicator()
    DEBUG.startDebugTimer("WILDUUI_INIT_MOUNTFRAME_START")
    if mountFrame._wt_initialized then
        return
    end
    mountFrame._wt_initialized = true
    
    local CONFIG_KEY = "mountIcon"
    local DEFAULT_CONFIG = { point = 'CENTER', x = 0, y = 50, scale = 1 }
    
    mountFrame:SetSize(32, 32)
    local config = LoadFrameConfig(CONFIG_KEY, DEFAULT_CONFIG)
    mountFrame:SetPoint("CENTER", UIParent, config.point, config.x, config.y)
    mountFrame:SetScale(config.scale)
    
    mountFrame.icon = mountFrame:CreateTexture(nil, "OVERLAY")
    mountFrame.icon:SetAllPoints(mountFrame)
    mountFrame.icon:SetAtlas("Fyrakk-Flying-Icon", true)
    mountFrame.icon:SetAlpha(0)
    mountFrame:Show()
    
    -- Throttled update (0.25 for mount check)
    CreateThrottledUpdate(mountFrame, 0.25, function(self)
        if not ns.Addon.db.profile.wilduUI_mountableArea then
            self.icon:SetAlpha(0)
            return
        end
        if LEM:IsInEditMode() then
			self.icon:SetAlpha(1)
			return
		end
        local canMount = C_Spell.IsSpellUsable(150544)
        self.icon:SetAlpha(canMount and 1 or 0)
    end)
    
    RegisterEditModeCallbacks(mountFrame, CONFIG_KEY, function()
        return ns.Addon.db.profile.wilduUI_mountableArea
    end)
    
    RegisterFrameWithLEM(mountFrame, CONFIG_KEY, DEFAULT_CONFIG, {})
    
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
    if spellOnCDFrame._wt_initialized then return end
    spellOnCDFrame._wt_initialized = true
    
    local CONFIG_KEY = "spellOnCD"
    local DEFAULT_CONFIG = { point = 'CENTER', x = 0, y = 0, scale = 1, alpha = 1, zoom = 0 }
    
    EnsureEditModeConfig(CONFIG_KEY, DEFAULT_CONFIG)
    local config = ns.Addon.db.profile.editMode[CONFIG_KEY]
    
    spellOnCDFrame:ClearAllPoints()
    spellOnCDFrame:SetPoint("CENTER", UIParent, config.point or 'CENTER', 
                             config.x or 0, config.y or 0)
    spellOnCDFrame:SetScale(config.scale or DEFAULT_SCALE)
    spellOnCDFrame:SetAlpha(config.alpha or DEFAULT_ALPHA)
    
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
crosshairParent:EnableMouse(false)
crosshairParent._wt_initialized = false


function WilduUI.InitializeCrosshair()
    if crosshairParent._wt_initialized then return end
    crosshairParent._wt_initialized = true
    
    local CONFIG_KEY = "crosshair"
    local DEFAULT_CONFIG = {
        point = 'CENTER',
        x = 0,
        y = 0,
        scale = 1,
        alpha = 1,
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
    
    local config = EnsureEditModeConfig(CONFIG_KEY, DEFAULT_CONFIG)
    
    local thickness = config.thickness or 4
    local inner_length = config.inner_length or 24
    local border_size = config.border_size or 4
    local class_colored = (config.class_colored == nil) and true or config.class_colored
    local alpha = config.alpha or 1
    local scale = config.scale or 1
    
    crosshairParent:SetSize(inner_length + thickness + border_size, 
                            inner_length + thickness + border_size)
    ApplyFramePosition(crosshairParent, CONFIG_KEY)
    crosshairParent:SetAlpha(alpha)


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
		local a = ns.Addon.db.profile.editMode[CONFIG_KEY].alpha or alpha
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


	CreateThrottledUpdate(crosshairParent, 0.1, function(self)
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


function WilduUI.UnInitializeCrosshair()
    crosshairParent:SetAlpha(0)
end


-- ============================================================================
-- PLAYER IN COMBAT INDICATOR
-- ============================================================================

local playerCombatFrame = CreateFrame("Frame", "WilduTools Player Combat", UIParent)

function WilduUI.InitializePlayerCombatIndicator()
    if playerCombatFrame._wt_initialized then return end
    playerCombatFrame._wt_initialized = true
    
    local CONFIG_KEY = "playerCombat"
    local DEFAULT_CONFIG = { point = 'CENTER', x = -50, y = 0, scale = 1 }
    
    playerCombatFrame:SetSize(32, 32)
    local config = LoadFrameConfig(CONFIG_KEY, DEFAULT_CONFIG)
    playerCombatFrame:SetPoint("CENTER", UIParent, config.point, config.x, config.y)
    playerCombatFrame:SetScale(config.scale)
    
    playerCombatFrame.icon = playerCombatFrame:CreateTexture(nil, "OVERLAY")
    playerCombatFrame.icon:SetAllPoints(playerCombatFrame)
    playerCombatFrame.icon:SetTexture("Interface\\AddOns\\!WilduTools\\Media\\Icons\\CombatStylized.blp")
    playerCombatFrame.icon:SetAlpha(0)
    playerCombatFrame:Show()
    
    -- Throttled update (0.1 for combat status)
    CreateThrottledUpdate(playerCombatFrame, 0.1, function(self)
        if not ns.Addon.db.profile.wilduUI_playerCombat then
            self.icon:SetAlpha(0)
            return
        end
		-- PREVIEW IN EDIT MODE
		if LEM:IsInEditMode() then
			self.icon:SetAlpha(1)  -- Show at full alpha in edit mode
			return
		end
        
        local inCombat = UnitAffectingCombat("player")
        self.icon:SetAlpha(inCombat and 1 or 0)
    end)
    
    RegisterEditModeCallbacks(playerCombatFrame, CONFIG_KEY, function()
        return ns.Addon.db.profile.wilduUI_playerCombat
    end)
    
    RegisterFrameWithLEM(playerCombatFrame, CONFIG_KEY, DEFAULT_CONFIG, {})
end

function WilduUI.UnInitializePlayerCombatIndicator()
    playerCombatFrame:SetAlpha(0)
end


-- ============================================================================
-- TARGET IN COMBAT INDICATOR
-- ============================================================================

local targetCombatFrame = CreateFrame("Frame", "WilduTools Target Combat", UIParent)

function WilduUI.InitializeTargetCombatIndicator()
    if targetCombatFrame._wt_initialized then return end
    targetCombatFrame._wt_initialized = true
    
    local CONFIG_KEY = "targetCombat"
    local DEFAULT_CONFIG = { point = 'CENTER', x = 50, y = 0, scale = 1 }
    
    targetCombatFrame:SetSize(32, 32)
    local config = LoadFrameConfig(CONFIG_KEY, DEFAULT_CONFIG)
    targetCombatFrame:SetPoint("CENTER", UIParent, config.point, config.x, config.y)
    targetCombatFrame:SetScale(config.scale)
    
    targetCombatFrame.icon = targetCombatFrame:CreateTexture(nil, "OVERLAY")
    targetCombatFrame.icon:SetAllPoints(targetCombatFrame)
    targetCombatFrame.icon:SetTexture("Interface\\AddOns\\!WilduTools\\Media\\Icons\\CombatStylized.blp")
    targetCombatFrame.icon:SetAlpha(0)
    targetCombatFrame:Show()
    
    -- Throttled update (0.1 for combat status)
    CreateThrottledUpdate(targetCombatFrame, 0.1, function(self)
        if not ns.Addon.db.profile.wilduUI_targetCombat then
            self.icon:SetAlpha(0)
            return
        end

		if LEM:IsInEditMode() then
			self.icon:SetAlpha(1)  -- Show at full alpha in edit mode
			return
		end
        
        if UnitExists("target") then
            local inCombat = UnitAffectingCombat("target")
            self.icon:SetAlpha(inCombat and 1 or 0)
        else
            self.icon:SetAlpha(0)
        end
    end)
    
    RegisterEditModeCallbacks(targetCombatFrame, CONFIG_KEY, function()
        return ns.Addon.db.profile.wilduUI_targetCombat
    end)
    
    RegisterFrameWithLEM(targetCombatFrame, CONFIG_KEY, DEFAULT_CONFIG, {})
end

function WilduUI.UnInitializeTargetCombatIndicator()
    targetCombatFrame:SetAlpha(0)
end