local _, ns = ...

--- WilduUI Module
--- Main entry point for WilduUI components - provides unified initialization API
--- All UI components are split into separate modules under ui/components/
local WilduUI = {}
ns.WilduUI = WilduUI

-- Components are loaded separately via TOC file
-- ns.WilduUICore - Core helpers for EditMode, positioning, throttling
-- ns.RangeFrame - Target range indicator
-- ns.MountIndicator - Mountable area indicator  
-- ns.SpellOnCD - Spell on cooldown indicator
-- ns.Crosshair - Crosshair overlay
-- ns.CombatIndicators - Player and target combat indicators

-- ============================================================================
-- PUBLIC API
-- ============================================================================

---Initialize the target range indicator frame
---Delegates to RangeFrame component
function WilduUI.InitializeRangeFrame()
    if ns.RangeFrame then
        ns.RangeFrame.Initialize()
    end
end

---Initialize the mountable area indicator
---Delegates to MountIndicator component
function WilduUI.InitializeMountableAreaIndicator()
    if ns.MountIndicator then
        ns.MountIndicator.Initialize()
    end
end

---Initialize the spell-on-cooldown indicator
---Delegates to SpellOnCD component
function WilduUI.InitializeSpellOnCD()
    if ns.SpellOnCD then
        ns.SpellOnCD.Initialize()
    end
end

---Initialize the crosshair overlay
---Delegates to Crosshair component
function WilduUI.InitializeCrosshair()
    if ns.Crosshair then
        ns.Crosshair.Initialize()
    end
end

---Initialize the player combat indicator
---Delegates to CombatIndicators component
function WilduUI.InitializePlayerCombatIndicator()
    if ns.CombatIndicators then
        ns.CombatIndicators.InitializePlayerCombatIndicator()
    end
end

---Initialize the target combat indicator
---Delegates to CombatIndicators component
function WilduUI.InitializeTargetCombatIndicator()
    if ns.CombatIndicators then
        ns.CombatIndicators.InitializeTargetCombatIndicator()
    end
end

return WilduUI
