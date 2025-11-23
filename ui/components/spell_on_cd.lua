local _, ns = ...

--- Spell On Cooldown Component
--- Displays a spell icon when the player fails to cast due to cooldown
local SpellOnCD = {}

local DEBUG = ns.DEBUG
local WilduUICore = ns.WilduUICore
local LEM = LibStub('LibEditMode')

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local DEFAULT_ALPHA = 1

-- ============================================================================
-- FRAME SETUP
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

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

---Initialize the spell-on-cooldown indicator
---Shows spell icon briefly when player tries to cast a spell on cooldown
function SpellOnCD.Initialize()
    local CONFIG_KEY = "spellOnCD"
    
    if spellOnCDFrame._wt_initialized then 
        return 
    end
    spellOnCDFrame._wt_initialized = true
    
    local DEFAULT_CONFIG = { x = -50 }
    local config = WilduUICore.LoadFrameConfig(CONFIG_KEY, DEFAULT_CONFIG)
    
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
    
    WilduUICore.RegisterEditModeCallbacks(spellOnCDFrame, CONFIG_KEY, function()
        return ns.Addon.db.profile.wilduUI_spellOnCD
    end)
    
    local additionalSettings = {
        WilduUICore.CreateAlphaSetting(CONFIG_KEY, DEFAULT_ALPHA),
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
    
    WilduUICore.RegisterFrameWithLEM(spellOnCDFrame, CONFIG_KEY, additionalSettings)
    
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

ns.SpellOnCD = SpellOnCD
return SpellOnCD
