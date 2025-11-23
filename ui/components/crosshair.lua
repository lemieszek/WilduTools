local _, ns = ...

--- Crosshair Component
--- Displays a customizable crosshair at the center of the screen
local Crosshair = {}

local DEBUG = ns.DEBUG
local WilduUICore = ns.WilduUICore
local LEM = LibStub('LibEditMode')

-- ============================================================================
-- FRAME SETUP
-- ============================================================================

local crosshairParent = CreateFrame("Frame", "WilduTools Crosshair", UIParent)
crosshairParent._wt_initialized = false

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

---Initialize the crosshair overlay
---Creates a customizable crosshair with configurable size, color, and visibility options
function Crosshair.Initialize()
    local CONFIG_KEY = "crosshair"
    
    if crosshairParent._wt_initialized then 
        WilduUICore.ApplyFramePosition(crosshairParent, CONFIG_KEY, not ns.Addon.db.profile.wilduUI_crosshair)
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
    
    local config = WilduUICore.LoadFrameConfig(CONFIG_KEY, DEFAULT_CONFIG)
    
    local thickness = config.thickness
    local inner_length = config.inner_length
    local border_size = config.border_size
    local class_colored = config.class_colored

    crosshairParent:SetSize(inner_length + thickness + border_size, 
                            inner_length + thickness + border_size)

    WilduUICore.ApplyFramePosition(crosshairParent, CONFIG_KEY, not ns.Addon.db.profile.wilduUI_crosshair)

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

	WilduUICore.CreateThrottledUpdate(crosshairParent, 1, function(self)
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
		local inCombat = InCombatLockdown()
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

    WilduUICore.RegisterEditModeCallbacks(crosshairParent, CONFIG_KEY, function()
        return ns.Addon.db.profile.wilduUI_crosshair
    end)
    
    local additionalSettings = {
        WilduUICore.CreateAlphaSetting(CONFIG_KEY, DEFAULT_CONFIG.alpha),
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
    
    WilduUICore.RegisterFrameWithLEM(crosshairParent, CONFIG_KEY, additionalSettings)
end

ns.Crosshair = Crosshair
return Crosshair
