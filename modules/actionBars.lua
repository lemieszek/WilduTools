local _, ns = ...
local ActionBars = {}
ns.ActionBars = ActionBars
local DEBUG = ns.DEBUG

-- Generic per-bar toggle helpers. buttonPrefix is e.g. "ActionButton", "MultiBarBottomLeftButton", etc.
function ActionBars.disableMouseOnBar(buttonPrefix)
  if InCombatLockdown() then return end
  if not buttonPrefix then return end
  for i = 1, 12 do
    local btn = _G[buttonPrefix..i]
    if btn and btn.EnableMouse then
      btn:EnableMouse(false)
    end
  end
end

function ActionBars.enableMouseOnBar(buttonPrefix)
  if InCombatLockdown() then return end
  if not buttonPrefix then return end
  for i = 1, 12 do
    local btn = _G[buttonPrefix..i]
    if btn and btn.EnableMouse then
      btn:EnableMouse(true)
    end
  end
end


function ActionBars.disableMouseOnExtraActionBarArt()
	if ExtraActionBarFrame then
		ExtraActionBarFrame:EnableMouse(false)
	end
	if ExtraAbilityContainer then
		ExtraAbilityContainer:EnableMouse(false)
	end
	if ZoneAbilityFrame.Style then
		ZoneAbilityFrame.Style:EnableMouse(false)
	end
end
