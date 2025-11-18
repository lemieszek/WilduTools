local _, ns = ...
local Nameplates = {}
ns.Nameplates = Nameplates
local DEBUG = ns.DEBUG

-- unused
function Nameplates.HideDefaultBuffFrame()
    DEBUG.startDebugTimer("NAMEPLATES_HIDE_BUFFFRAME_START")
    if Nameplates._wt_hooked then return end
    Nameplates._wt_hooked = true
    local eventFrame = CreateFrame("Frame")
    local eventHandlers = {}

    function eventHandlers:NAME_PLATE_UNIT_ADDED(unitId)
        local nameplate = C_NamePlate.GetNamePlateForUnit(unitId)
        local unitFrame = nameplate.UnitFrame
        if not nameplate or unitFrame:IsForbidden() then return end
        unitFrame.BuffFrame:ClearAllPoints()
        unitFrame.BuffFrame:SetAlpha(0)
        unitFrame.BuffFrame:Hide()
    end

    for eventName, handler in pairs(eventHandlers) do
        eventFrame:RegisterEvent(eventName)
    end

    eventFrame:SetScript("OnEvent", function(self, event, ...) eventHandlers[event](self, ...) end)
    DEBUG.checkpointDebugTimer("NAMEPLATES_HIDE_BUFFFRAME_DONE", "NAMEPLATES_HIDE_BUFFFRAME_START")
  end