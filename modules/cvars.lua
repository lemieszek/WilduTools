local _, ns = ...
local CVars = {}
ns.CVars = CVars
local DEBUG = ns.DEBUG

local function stringToBoolean(value) return value == "1" end

function CVars.getCVar(cvarName)
  local value = C_CVar.GetCVar(cvarName)
  if value == "0" or value == "1" then
    return stringToBoolean(value)
  end
  return value
end

function CVars.setCVar(cvarName, value)
  if type(value) == "boolean" then
    value = value and "1" or "0"
  end
  C_CVar.SetCVar(cvarName, value)
end

function CVars.applySetting(cvarName, value, isBoolean, isReverse)
  local setting = Settings.GetSetting(cvarName)
  if not setting or setting.locked then
    ns.Addon:Print("Cannot apply setting, not found or locked:", cvarName)
    return false
  end
  local v = value
  -- Settings expect booleans for many CVars; normalize from "1"/"0" strings
  if type(v) == "string" and isBoolean then
    v = stringToBoolean(v)
  end
  if isReverse then
    v = not v
  end
  setting:ApplyValue(v)
  return true
end

function CVars.getSettingValue(cvarName)
  local setting = Settings.GetSetting(cvarName)
  if not setting then return nil end
  return setting:GetValue()
end

function CVars.setInterfaceScale()
  ns.DEBUG.startDebugTimer("CVARS_SET_INTERFACE_SCALE_START")
  
  local scalePresets = {
    Scale1440p = 0.533333333333,
    Scale1080p = 0.711111111111,
  }
  
  local targetScale = scalePresets[ns.db.profile.general_defaultScaling]
  
  if targetScale then
    local function compareScale(a, b)
      return math.floor(a * 10000) / 10000 == math.floor(b * 10000) / 10000
    end
    
    if not compareScale(UIParent:GetScale(), targetScale) then
      UIParent:SetScale(targetScale)
    end
  end
  
  ns.DEBUG.checkpointDebugTimer("CVARS_SET_INTERFACE_SCALE_DONE", "CVARS_SET_INTERFACE_SCALE_START")
end


function CVars.enableAllActionBars()
  DEBUG.startDebugTimer("CVARS_ENABLE_ALL_ACTIONBARS_START")
  local list = {GetActionBarToggles()};
  for i = 1, 7 do
    list[i] = true
  end
  SetActionBarToggles(unpack(list));
  MultiActionBar_Update()
  DEBUG.checkpointDebugTimer("CVARS_ENABLE_ALL_ACTIONBARS_DONE", "CVARS_ENABLE_ALL_ACTIONBARS_START")
end