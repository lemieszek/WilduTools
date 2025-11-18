local _, ns = ...
local Nameplates = {}
ns.Nameplates = Nameplates

-- unused
function Nameplates.HideDefaultBuffFrame()
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
  end