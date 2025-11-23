local _, ns = ...

--- Range Frame Component
--- Displays the distance range to the current target with color coding based on class
local RangeFrame = {}

local API = ns.API
local DEBUG = ns.DEBUG
local WilduUICore = ns.WilduUICore
local LEM = LibStub('LibEditMode')

-- ============================================================================
-- FRAME SETUP
-- ============================================================================

local rangeFrame = CreateFrame("Frame", "WilduTools Range Frame", UIParent)

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

---Initialize the target range indicator frame
---Shows distance to target with color coding based on player class abilities
function RangeFrame.Initialize()
    DEBUG.startDebugTimer("WILDUUI_INIT_RANGEFRAME_START")
    local CONFIG_KEY = "rangeCheck"
    
    if rangeFrame._wt_initialized then
        WilduUICore.ApplyFramePosition(rangeFrame, CONFIG_KEY, not ns.Addon.db.profile.wilduUI_targetRangeFrame)
        return
    end
    rangeFrame._wt_initialized = true
    
    rangeFrame:SetSize(120, 24)
    local config = WilduUICore.LoadFrameConfig(CONFIG_KEY)
    rangeFrame.text = rangeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    rangeFrame.text:SetPoint("LEFT", rangeFrame, "LEFT")
    rangeFrame.text:SetText("")

    WilduUICore.ApplyFramePosition(rangeFrame, CONFIG_KEY, not ns.Addon.db.profile.wilduUI_targetRangeFrame)
    
    local _, classFilename = UnitClass("player")
    
    local function updateRangeText()
        local min, max = API:GetRange("target")
        if min or max then
            local rangeText = max and string.format("%d - %d", min, max) or string.format("%d+", min)
            rangeText = API:ColorizeRange(rangeText, max and max or min, classFilename)
            rangeFrame.text:SetText(rangeText)
            rangeFrame:SetAlpha(1)
        else
            rangeFrame.text:SetText("")
            rangeFrame:SetAlpha(0)
        end
    end

    WilduUICore.ApplyVisibilityDriverToFrame(rangeFrame, "[target=target,exists] show; hide", false)
    WilduUICore.CreateTickerUpdate(rangeFrame, 0.5, function()
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
    
    WilduUICore.RegisterEditModeCallbacks(rangeFrame, CONFIG_KEY, function()
        return ns.Addon.db.profile.wilduUI_targetRangeFrame
    end)
    
    WilduUICore.RegisterFrameWithLEM(rangeFrame, CONFIG_KEY)
    
    DEBUG.checkpointDebugTimer("WILDUUI_INIT_RANGEFRAME_DONE", "WILDUUI_INIT_RANGEFRAME_START")
end

ns.RangeFrame = RangeFrame
return RangeFrame
