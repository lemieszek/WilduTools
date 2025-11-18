local _, ns = ...
local CVars = {}
ns.CVars = CVars
local DEBUG = ns.DEBUG

local function stringToBoolean(value) return value == "1" end

-- Low-level CVar helpers (operate directly via C_CVar)
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

-- Setting helpers (use Settings API when available)
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

-- deprecated
function CVars.setDefaults()
  -- Background
  C_CVar.SetCVar("advancedCombatLogging", 1)

  -- Dynamic flying / sky riding settings
  C_CVar.SetCVar("motionSicknessLandscapeDarkening", 0)
  C_CVar.SetCVar("DisableAdvancedFlyingFullScreenEffects", 0)
  C_CVar.SetCVar("DisableAdvancedFlyingVelocityVFX", 0)

  -- Graphic - performance
  C_CVar.SetCVar("ResampleAlwaysSharpen", 1)
  C_CVar.SetCVar("spellVisualDensityFilterSetting",1)
  C_CVar.SetCVar("spellVisuals",0);
  C_CVar.SetCVar("spellClutter",1);
  C_CVar.SetCVar("RAIDspellClutter",1);
  C_CVar.SetCVar("unitClutterPlayerThreshold", 4)
  
  -- UI
  C_CVar.SetCVar("whisperMode", "popout")

  -- Gameplay
  C_CVar.SetCVar("autolootDefault", 1)
  -- C_CVar.SetCVar("cameraDistanceMaxZoomFactor", 1.8) -- do it in advanced interface options
  C_CVar.SetCVar("AutoPushSpellToActionBar", 1) -- consider disabling?
  C_CVar.SetCVar("countdownForCooldowns", 1)
  C_CVar.SetCVar("showDungeonEntrancesOnMap", 1)
end

-- Apply CVars using values from the addon's saved variables (db.profile)
-- deprecated
function CVars.setCVars(db)
  DEBUG.startDebugTimer("CVARS_SETCVARS_START")
  if not db or not db.profile then return end
  local p = db.profile

  -- nameplates
  if p.cvars_nameplateOtherAtBase ~= nil then
    C_CVar.SetCVar("nameplateOtherAtBase", p.cvars_nameplateOtherAtBase and 1 or 0)
  end

  -- background / logging
  if p.cvars_advancedCombatLogging ~= nil then
    C_CVar.SetCVar("advancedCombatLogging", p.cvars_advancedCombatLogging and 1 or 0)
  end

  -- Dynamic flying / sky riding settings
  if p.cvars_motionSicknessLandscapeDarkening ~= nil then
    C_CVar.SetCVar("motionSicknessLandscapeDarkening", p.cvars_motionSicknessLandscapeDarkening and 1 or 0)
  end
  if p.cvars_DisableAdvancedFlyingFullScreenEffects ~= nil then
    C_CVar.SetCVar("DisableAdvancedFlyingFullScreenEffects", p.cvars_DisableAdvancedFlyingFullScreenEffects and 1 or 0)
  end
  if p.cvars_DisableAdvancedFlyingVelocityVFX ~= nil then
    C_CVar.SetCVar("DisableAdvancedFlyingVelocityVFX", p.cvars_DisableAdvancedFlyingVelocityVFX and 1 or 0)
  end

  -- Graphic - performance
  if p.cvars_ResampleAlwaysSharpen ~= nil then
    C_CVar.SetCVar("ResampleAlwaysSharpen", p.cvars_ResampleAlwaysSharpen and 1 or 0)
  end

  -- Spell density slider (1..4)
  if p.cvars_spellVisualDensityFilterSetting ~= nil then
    local v = tonumber(p.cvars_spellVisualDensityFilterSetting) or 1
    v = math.max(1, math.min(4, v))
    C_CVar.SetCVar("spellVisualDensityFilterSetting", v)
  end

  -- Reduce spell clutter grouped toggle
  if p.cvars_reduceSpellClutter ~= nil then
    if p.cvars_reduceSpellClutter then
      C_CVar.SetCVar("spellVisuals", 0)
      C_CVar.SetCVar("spellClutter", 1)
      C_CVar.SetCVar("RAIDspellClutter", 1)
      C_CVar.SetCVar("unitClutterPlayerThreshold", 4)
    else
      -- leave as-is; no safe default to revert to
    end
  end

  -- whisper mode dropdown
  if p.cvars_whisperMode ~= nil then
    C_CVar.SetCVar("whisperMode", tostring(p.cvars_whisperMode))
  end

  -- Gameplay
  if p.cvars_autolootDefault ~= nil then
    C_CVar.SetCVar("autolootDefault", p.cvars_autolootDefault and 1 or 0)
  end
  if p.cvars_AutoPushSpellToActionBar ~= nil then
    C_CVar.SetCVar("AutoPushSpellToActionBar", p.cvars_AutoPushSpellToActionBar and 1 or 0)
  end
  if p.cvars_countdownForCooldowns ~= nil then
    C_CVar.SetCVar("countdownForCooldowns", p.cvars_countdownForCooldowns and 1 or 0)
  end
  if p.cvars_showDungeonEntrancesOnMap ~= nil then
    C_CVar.SetCVar("showDungeonEntrancesOnMap", p.cvars_showDungeonEntrancesOnMap and 1 or 0)
  end
  
  DEBUG.checkpointDebugTimer("CVARS_SETCVARS_DONE", "CVARS_SETCVARS_START")
end

function CVars.SetTTSSettings()
  -- DevTools_Dump(C_VoiceChat.GetTtsVoices())
  -- [1]={
  --   [1]={
  --     voiceID=0,
  --     name="Microsoft Hazel Desktop - English (Great Britain)"
  --   },
  --   [2]={
  --     voiceID=1,
  --     name="Microsoft Ryan (Natural) - English (United Kingdom)"
  --   },
  --   [3]={
  --     voiceID=2,
  --     name="Microsoft Jenny(Natural) - English (United States)"
  --   },
  --   [4]={
  --     voiceID=3,
  --     name="Microsoft Zira Desktop - English (United States)"
  --   }
  -- }
  C_TTSSettings.SetSpeechRate(2)
  C_TTSSettings.SetSpeechVolume(100)
  C_TTSSettings.SetVoiceOption(0, 0)  -- Microsoft Jenny(Natural)
  -- C_TTSSettings.SetVoiceOption(1, 1)  -- Microsoft Ryan(Natural)
  -- C_VoiceChat.SpeakText(0, "Hello world 0", Enum.VoiceTtsDestination.LocalPlayback, 0, 100)
  -- C_VoiceChat.SpeakText(1, "Hello world 1", Enum.VoiceTtsDestination.LocalPlayback, 0, 100)
  -- C_VoiceChat.SpeakText(2, "Hello world 2", Enum.VoiceTtsDestination.LocalPlayback, 0, 100)
  -- C_VoiceChat.SpeakText(2, "Hello world 3", Enum.VoiceTtsDestination.LocalPlayback, 0, 100)

end   

function CVars.SetNameplateSettings()
  C_NamePlate.SetNamePlateFriendlySize(55, 1)
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


-- TODO
-- local spellDensityOptions = configBuilder:MakeSliderOptions(1, 4, 1, function(value)
--     local labels = { "Low", "Medium", "High", "Ultra" }
--     return labels[value] or tostring(value)
-- end)
-- configBuilder:MakeSlider(
--     "Spell Visual Density",
--     "spellVisualDensityFilterSetting",
--     "Adjust the density of spell visual effects (1=Low, 4=Ultra).",
--     spellDensityOptions,
--     createCVarCallback("spellVisualDensityFilterSetting", false),
--     defaults.spellVisualDensityFilterSetting,
--     defaults
-- )

-- configBuilder:MakeCheckbox(
--     "Reduce Spell Clutter (Grouped)",
--     "reduceSpellClutter",
--     "Enables a set of CVars to reduce visual spell clutter (spellVisuals=0, spellClutter=1, RAIDspellClutter=1, unitClutterPlayerThreshold=4).",
--     function(_, value)
--         if value then
--             C_CVar.SetCVar("spellVisuals", 0)
--             C_CVar.SetCVar("spellClutter", 1)
--             C_CVar.SetCVar("RAIDspellClutter", 1)
--             C_CVar.SetCVar("unitClutterPlayerThreshold", 4)
--         else
--             -- When disabling this grouped setting, we *do not* revert the individual CVars
--             -- to arbitrary "default" values. They remain at whatever state they were in.
--         end
--     end,
--     defaults.reduceSpellClutter,
--     defaults
-- )

-- configBuilder:MakeHeader("UI Settings", "General user interface settings.");
-- local whisperModeOptions = function()
--     return {
--         { value = "popout", text = "Popout Windows" },
--         { value = "inline", text = "Inline" },
--     }
-- end


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