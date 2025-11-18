local _, ns = ...
local Addons = {}
local addon = LibStub("AceAddon-3.0"):GetAddon("WilduTools")

function Addons.scaleAddOnsSize()
  if (DUIQuestFrame) then
    DUIQuestFrame:SetScale(0.7)
  end
end

-- Remove in midnight
function Addons.checkForWAModels()
  local function checkForModel(a)
    if a.regionType == "model" then
      return 1
    end
    for i, s in pairs(a.subRegions or {}) do
      if s.type == "submodel" then
        return 1
      end
    end
  end
  -- DevTools_Dump(_)
  if (not WeakAurasSaved) or (not WeakAurasSaved.displays) then
    -- addon:Print("WeakAuras not found")
    return
  end
  local count = 0
  for n, a in pairs(WeakAurasSaved.displays) do
    if checkForModel(a) then
      print("Model found in: ", n)
      count = count + 1
    end
  end
  if count > 0 then
    print("Models count: ", count)
  end
end

ns.Addons = Addons 