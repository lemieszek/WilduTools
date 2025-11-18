local _, ns = ...
local ActionBars = {}
ns.ActionBars = ActionBars

local changeShortenKeybindTextHooked = false
function ActionBars.changeShortenKeybindText()
  local map = {
    ["Middle Mouse"] = "M3",
    ["Mouse Wheel Down"] = "DWN",
    ["Mouse Wheel Up"] = "UP",
    ["Home"] = "Hm",
    ["Insert"] = "Ins",
    ["Spacebar"] = "SpB",
    ["F6"] = "R1",
    ["F7"] = "R2",
    ["F8"] = "R3",
    ["F9"] = "R4",
    ["F10"] = "R5",
    ["F11"] = "R6",
    ["7"] = "R7",
    ["8"] = "R8",
    ["9"] = "R9",
    ["0"] = "R10",
    ["-"] = "R11",
    ["="] = "R12",
    [";"] = "M6",
    ["'"] = "M7",
    ["S;"] = "SM6",
    ["S'"] = "SM7"
  }

  local patterns = {
    ["Mouse Button "] = "M", -- M4, M5
    ["Num Pad "] = "N",
    ["a%-"] = "A", -- alt
    ["c%-"] = "C", -- ctrl
    ["s%-"] = "S", -- shift
  }

  local bars = {
    "ActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarLeftButton",
    "MultiBarRightButton",
    "MultiBar5Button",
    "MultiBar6Button",
    "MultiBar7Button",
  }

  local function UpdateHotkey(self, actionButtonType)
    local hotkey = self.HotKey
    local text = hotkey:GetText()
    if not text or text == "" or text == RANGE_INDICATOR then
      return
    end
    for k, v in pairs(patterns) do
      text = text:gsub(k, v)
    end
    hotkey:SetText(map[text] or text)
  end

  if not changeShortenKeybindTextHooked then
    changeShortenKeybindTextHooked = true
    for _, bar in pairs(bars) do
      for i = 1, NUM_ACTIONBAR_BUTTONS do
        hooksecurefunc(_G[bar..i], "UpdateHotkeys", UpdateHotkey)
      end
    end
    ActionBarButtonEventsFrame:GetScript("OnEvent")(ActionBarButtonEventsFrame, "UPDATE_BINDINGS")
  end
  -- HIDE KEYBIND TEXT FOR MULTI 6 AND 7 BUTTONS (1-12)
  for j = 5,7 do
    for i = 1, 12 do
      local button = _G["MultiBar"..j.."Button"..i] 
      if button then
        local hotkey = _G[button:GetName().."HotKey"]
        if hotkey then
          hotkey:Hide()
          hotkey:SetAlpha(0)
        end
      end
    end
  end
end


function ActionBars.disableMouseOnActionBar7() -- ActionBar 7 is actually MultiBar6
  for i = 1, 12 do
    local button = _G["MultiBar6Button"..i] 
    if button then
      button:EnableMouse(false)
    end
  end
end

function ActionBars.enableMouseOnActionBar7()
  for i = 1, 12 do
    local button = _G["MultiBar6Button"..i] 
    if button then
      button:EnableMouse(true)
    end
  end
end

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
