function UI.lowerBlizzardGryphons() 
  if MainMenuBar and MainMenuBar.EndCaps then
    MainMenuBar.EndCaps:SetFrameStrata("BACKGROUND")
  end
end

function UI.setBuffExpandState(value)
  if BuffFrame and BuffFrame.SetBuffsExpandedState then
    BuffFrame:SetBuffsExpandedState(value)
  end
end 

function UI.refreshBattlefieldMapFrame()
  if BattlefieldMapFrame and BattlefieldMapFrame:IsShown()  then
    BattlefieldMapFrame:Hide()
    C_Timer.After(0.02, function()
      BattlefieldMapFrame:Show()
    end)
  end
end

-- TODO create options for it
function UI.hideExtraActionBarArtwork()
	if ZoneAbilityFrame then
		if ZoneAbilityFrame.Style then

			ZoneAbilityFrame.Style:SetAlpha(0)
			ZoneAbilityFrame.Style:Hide()
		end
	end

	if ExtraActionButton1 then
		ExtraActionButton1.style:SetAlpha(0)
		ExtraActionButton1.style:Hide()
	end
	if ExtraActionButton2 then
		ExtraActionButton2.style:SetAlpha(0)
		ExtraActionButton2.style:Hide()
	end
	if ExtraActionBarFrame then
		ExtraActionBarFrame:SetWidth(52)
		ExtraActionBarFrame:SetHeight(52)
	end
	if ExtraAbilityContainer then
		ExtraAbilityContainer:SetWidth(52)
		ExtraAbilityContainer:SetHeight(52)
	end
end

-- Experimental feature - move frames around to remove gaps when groups are horizontal
  --[[
  for i = 1, 8 do
    local skip = 0

    local groupFrame = _G["CompactRaidGroup" .. i]
    
    if groupFrame and groupFrame:IsShown() then
      local RAID_FRAME_HEIGHT = 72
        local point, relativeTo, relativePoint, xOfs, yOfs = groupFrame:GetPoint()
        local x = 0
        local y = RAID_FRAME_HEIGHT * (i - 1 - skip)
        if (xOfs ~= x or yOfs ~= y or point ~= "BOTTOMRIGHT") then
          groupFrame:ClearAllPoints()
          groupFrame:SetPoint("BOTTOMRIGHT",CompactRaidFrameContainer, "BOTTOMRIGHT", 0, y)
        end
    else
      skip = skip + 1
    end
  end    
  ]]--

  
-- Detect Atlas: /run local t=PlayerFrame_GetManaBar():GetStatusBarTexture(); print("tex:", t:GetTexture(), "atlas:", t:GetAtlas()); local a,b,c,d,e,f,g,h=t:GetTexCoord(); print("tc:",a,b,c,d,e,f,g,h)
-- Healthbar: /run local t=PlayerFrame_GetHealthBar():GetStatusBarTexture(); print("tex:", t:GetTexture(), "atlas:", t:GetAtlas()); local a,b,c,d,e,f,g,h=t:GetTexCoord(); print("tc:",a,b,c,d,e,f,g,h)
-- from demon hunter DemonHunterSoulFragmentsBar /run local t=DemonHunterSoulFragmentsBar:GetStatusBarTexture(); print("tex:", t:GetTexture(), "atlas:", t:GetAtlas()); local a,b,c,d,e,f,g,h=t:GetTexCoord(); print("tc:",a,b,c,d,e,f,g,h)


local atlasByPower = {
    LUNAR_POWER = "Unit_Druid_AstralPower_Fill",
    MAELSTROM = "Unit_Shaman_Maelstrom_Fill",
    INSANITY = "Unit_Priest_Insanity_Fill",
    FURY = "Unit_DemonHunter_Fury_Fill",
    RUNIC_POWER = "UI-HUD-UnitFrame-Player-PortraitOn-Bar-RunicPower",
    ENERGY = "UI-HUD-UnitFrame-Player-PortraitOn-ClassResource-Bar-Energy",
    FOCUS = "UI-HUD-UnitFrame-Player-PortraitOn-Bar-Focus",
    RAGE = "UI-HUD-UnitFrame-Player-PortraitOn-Bar-Rage",
    MANA = "UI-HUD-UnitFrame-Player-PortraitOn-Bar-Mana",
    HEALTH = "UI-HUD-UnitFrame-Player-PortraitOn-Bar-Health",
    VOID_META = "UF-DDH-VoidMeta-Bar"
  }

local function configureSpecialTexture(bar, pType)
  if not bar then return end
  local atlas = atlasByPower[pType]
  if not atlas then return end
  local tex = bar:GetStatusBarTexture()
  if tex and tex.SetAtlas then
    
    -- if force then 
      -- tex:SetAtlas(nil, true)
    -- end
    local currentAtlas = tex.GetAtlas and tex:GetAtlas()
    -- if currentAtlas ~= atlas then tex:SetAtlas(atlas, true) end
    if tex.SetHorizTile then tex:SetHorizTile(false) end
    if tex.SetVertTile then tex:SetVertTile(false) end
    
    bar:SetStatusBarColor(1, 1, 1, 1)
    bar._baseColor = bar._baseColor or {}
    bar._baseColor[1], bar._baseColor[2], bar._baseColor[3], bar._baseColor[4] = 1, 1, 1, 1
    bar._lastColor = bar._lastColor or {}
    bar._lastColor[1], bar._lastColor[2], bar._lastColor[3], bar._lastColor[4] = 1, 1, 1, 1
    bar._usingMaxColor = false
    
  end
end

UI.betterTexturesForBlizzPersonalResourceDisplayFrame = function()
    if PersonalResourceDisplayFrame.HealthBarsContainer.healthBar then
      PersonalResourceDisplayFrame.HealthBarsContainer:SetHeight(1)
      PersonalResourceDisplayFrame.HealthBarsContainer:SetAlpha(0)
      -- configureSpecialTexture(PersonalResourceDisplayFrame.HealthBarsContainer.healthBar, "HEALTH")
    end
    
    PersonalResourceDisplayFrame:SetScale(1.5)
    
    local pNum, pType = UnitPowerType("player")
    if PersonalResourceDisplayFrame.PowerBar then 
      PersonalResourceDisplayFrame.PowerBar:SetWidth(150)
      PersonalResourceDisplayFrame.PowerBar.Border:SetAlpha(0)
      PersonalResourceDisplayFrame.PowerBar.Border:Hide()
      configureSpecialTexture(PersonalResourceDisplayFrame.PowerBar, pType)
    end

    
      configureSpecialTexture(PersonalResourceDisplayFrame.AlternatePowerBar, "ENERGY")
    if pType == "FURY" and PersonalResourceDisplayFrame.AlternatePowerBar then 
      PersonalResourceDisplayFrame.AlternatePowerBar:SetWidth(150)
      PersonalResourceDisplayFrame.AlternatePowerBar.Border:SetAlpha(0)
      PersonalResourceDisplayFrame.AlternatePowerBar.Border:Hide()  
      configureSpecialTexture(PersonalResourceDisplayFrame.AlternatePowerBar, "VOID_META")
    end
end


-- @deprecated not sure if it works in midnight
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

function Nameplates.SetNameplateSizes()
  C_NamePlate.SetNamePlateFriendlySize(55, 1)
end
  -- @deprecated
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

-- @deprecated
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

local changeShortenKeybindTextHooked = false
function ActionBars.changeShortenKeybindText()
  DEBUG.startDebugTimer("ACTIONBARS_CHANGE_SHORTEN_KEYBIND_START")
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
    if map[text] or text then
      hotkey:SetText(map[text] or text)
    end
  end
  DEBUG.checkpointDebugTimer("ACTIONBARS_CHANGE_SHORTEN_KEYBIND_PRE_HOOK", "ACTIONBARS_CHANGE_SHORTEN_KEYBIND_START")
  if not changeShortenKeybindTextHooked then
    changeShortenKeybindTextHooked = true
    for _, bar in pairs(bars) do
      for i = 1, NUM_ACTIONBAR_BUTTONS do
        hooksecurefunc(_G[bar..i], "UpdateHotkeys", UpdateHotkey)
      end
    end
    ActionBarButtonEventsFrame:GetScript("OnEvent")(ActionBarButtonEventsFrame, "UPDATE_BINDINGS")
  end
  DEBUG.checkpointDebugTimer("ACTIONBARS_CHANGE_SHORTEN_KEYBIND_POST_HOOK", "ACTIONBARS_CHANGE_SHORTEN_KEYBIND_PRE_HOOK")
  -- HIDE KEYBIND TEXT FOR ACTION BAR 7 BUTTONS (1-12)
  -- TODO make option for it
  -- for j = 5 do
  --   for i = 1, 12 do
  --     local button = _G["MultiBar"..j.."Button"..i] 
  --     if button then
  --       local hotkey = _G[button:GetName().."HotKey"]
  --       if hotkey then
  --         hotkey:Hide()
  --         hotkey:SetAlpha(0)
  --       end
  --     end
  --   end
  -- end
  DEBUG.checkpointDebugTimer("ACTIONBARS_CHANGE_SHORTEN_KEYBIND_POST_HIDE_HOTKEY", "ACTIONBARS_CHANGE_SHORTEN_KEYBIND_POST_HOOK")
  DEBUG.checkpointDebugTimer("ACTIONBARS_CHANGE_SHORTEN_KEYBIND_DONE", "ACTIONBARS_CHANGE_SHORTEN_KEYBIND_START")
end