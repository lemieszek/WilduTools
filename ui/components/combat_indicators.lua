local _, ns = ...

--- Combat Indicators Component
--- Displays combat status icons for player and target
local CombatIndicators = {}

local DEBUG = ns.DEBUG
local WilduUICore = ns.WilduUICore
local LEM = LibStub('LibEditMode')

-- ============================================================================
-- FRAME SETUP
-- ============================================================================

local playerCombatFrame = CreateFrame("Frame", "WilduTools Player Combat", UIParent)
local targetCombatFrame = CreateFrame("Frame", "WilduTools Target Combat", UIParent)

-- ============================================================================
-- PLAYER COMBAT INDICATOR
-- ============================================================================

---Initialize the player combat indicator
---Shows a combat icon when the player is in combat
function CombatIndicators.InitializePlayerCombatIndicator()
    local CONFIG_KEY = "playerCombat"
    
    if playerCombatFrame._wt_initialized then 
        WilduUICore.ApplyFramePosition(playerCombatFrame, CONFIG_KEY, not ns.Addon.db.profile.wilduUI_playerCombat)
        return 
    end
    playerCombatFrame._wt_initialized = true
    
    local DEFAULT_CONFIG = { x = -50, y = -50 }
    
    playerCombatFrame:SetSize(32, 32)
    local config = WilduUICore.LoadFrameConfig(CONFIG_KEY, DEFAULT_CONFIG)
    
    playerCombatFrame.icon = playerCombatFrame:CreateTexture(nil, "OVERLAY")
    playerCombatFrame.icon:SetAllPoints(playerCombatFrame)
    playerCombatFrame.icon:SetTexture("Interface\\AddOns\\!WilduTools\\Media\\Icons\\CombatStylized.blp")
    
    WilduUICore.ApplyFramePosition(playerCombatFrame, CONFIG_KEY, not ns.Addon.db.profile.wilduUI_playerCombat)
    
    WilduUICore.ApplyVisibilityDriverToFrame(playerCombatFrame, "[combat] show; hide", false)
    
    WilduUICore.RegisterEditModeCallbacks(playerCombatFrame, CONFIG_KEY, function()
        return ns.Addon.db.profile.wilduUI_playerCombat
    end)
    
    WilduUICore.RegisterFrameWithLEM(playerCombatFrame, CONFIG_KEY)
end

-- ============================================================================
-- TARGET COMBAT INDICATOR
-- ============================================================================

---Initialize the target combat indicator
---Shows a combat icon when the current target is in combat
function CombatIndicators.InitializeTargetCombatIndicator()
    local CONFIG_KEY = "targetCombat"
    
    if targetCombatFrame._wt_initialized then
        WilduUICore.ApplyFramePosition(targetCombatFrame, CONFIG_KEY, not ns.Addon.db.profile.wilduUI_targetCombat)
        return
    end
    targetCombatFrame._wt_initialized = true
    
    local DEFAULT_CONFIG = { x = 50, y = -50 }
    
    targetCombatFrame:SetSize(32, 32)
    local config = WilduUICore.LoadFrameConfig(CONFIG_KEY, DEFAULT_CONFIG)

    targetCombatFrame.icon = targetCombatFrame:CreateTexture(nil, "OVERLAY")
    targetCombatFrame.icon:SetAllPoints(targetCombatFrame)
    targetCombatFrame.icon:SetTexture("Interface\\AddOns\\!WilduTools\\Media\\Icons\\CombatStylized.blp")

    WilduUICore.ApplyFramePosition(targetCombatFrame, CONFIG_KEY, not ns.Addon.db.profile.wilduUI_targetCombat)
    
    WilduUICore.ApplyVisibilityDriverToFrame(targetCombatFrame, "[target=target,exists] show; hide", false)
    
    WilduUICore.CreateThrottledUpdate(targetCombatFrame, 0.1, function(self)
		if LEM:IsInEditMode() then
			self:SetAlpha(1)
			return
		end
        
        if UnitExists("target") then
            local inCombat = UnitAffectingCombat("target")
            self:SetAlpha(inCombat and 1 or 0)
        else
            self:SetAlpha(0)
        end
    end)
    
    WilduUICore.RegisterEditModeCallbacks(targetCombatFrame, CONFIG_KEY, function()
        return ns.Addon.db.profile.wilduUI_targetCombat
    end)
    
    WilduUICore.RegisterFrameWithLEM(targetCombatFrame, CONFIG_KEY)
end

ns.CombatIndicators = CombatIndicators
return CombatIndicators
