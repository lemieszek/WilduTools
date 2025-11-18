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
  if ns.db.profile.general_defaultScaling == "Scale1440p" then
    UIParent:SetScale(0.53333333333333) -- 1440p
  elseif ns.db.profile.general_defaultScaling == "Scale1080p" then
    UIParent:SetScale(0.71111111111111) -- 1080p
  else
    -- UIParent:SetScale(1.0) -- No scaling
  end
  DEBUG.checkpointDebugTimer("CVARS_SET_INTERFACE_SCALE_DONE", "CVARS_SET_INTERFACE_SCALE_START")
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