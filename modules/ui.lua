local _, ns = ...
local LSM = LibStub("LibSharedMedia-3.0")
local UI = {}
ns.UI = UI 
local DEBUG = ns.DEBUG

function UI.resizeBlizzardObjectiveTracker(value)
  ns.DEBUG.startDebugTimer("UI_RESIZE_OBJECTIVE_TRACKER_START")
  -- if (SuperTrackedFrame) then
  --   -- SuperTrackedFrame:SetScale(1.5)
  --   SuperTrackedFrame.Arrow:SetScale(1.5)
  --   SuperTrackedFrame.Arrow:SetAtlas("glues-characterSelect-icon-arrowUp" , true)
  --   -- SuperTrackedFrame.Icon:SetScale(1)
  --   SuperTrackedFrame.DistanceText:SetFont(SuperTrackedFrame.DistanceText:GetFont(), 13, "OUTLINE")
  --   SuperTrackedFrame:SetFrameStrata("HIGH")
  -- end


  if (_G["ObjectiveTrackerFrame"] ~= nil) then
    _G["ObjectiveTrackerFrame"]:SetScale(value or 0.9)
  end
  DEBUG.checkpointDebugTimer("UI_RESIZE_OBJECTIVE_TRACKER_DONE", "UI_RESIZE_OBJECTIVE_TRACKER_START")
end

function UI.cleanupObjectiveTracker()
  ns.DEBUG.startDebugTimer("UI_CLEANUP_OBJECTIVE_TRACKER_START")
  if (_G["ObjectiveTrackerFrame"] ~= nil) then
    _G["ObjectiveTrackerFrame"].Header.Background:Hide()
    _G["ObjectiveTrackerFrame"].Header.Text:Hide()
  end
  DEBUG.checkpointDebugTimer("UI_CLEANUP_OBJECTIVE_TRACKER_DONE", "UI_CLEANUP_OBJECTIVE_TRACKER_START")
end

function UI.hideBlizzardBagAndReagentFrames()
  ns.DEBUG.startDebugTimer("UI_HIDE_BAG_REAGENT_FRAMES_START")
  if (_G["CharacterReagentBag0Slot"] ~= nil) then
    CharacterReagentBag0Slot:Hide()
  end
  if (_G["BagsBar"] ~= nil) then
    BagsBar:Hide()
  end
  DEBUG.checkpointDebugTimer("UI_HIDE_BAG_REAGENT_FRAMES_DONE", "UI_HIDE_BAG_REAGENT_FRAMES_START")
end

-- @deprecated @unused
function UI.lowerBlizzardGryphons() 
  if MainMenuBar and MainMenuBar.EndCaps then
    MainMenuBar.EndCaps:SetFrameStrata("BACKGROUND")
  end
end

function UI.changeFriendlyNamesFonts()
  ns.DEBUG.startDebugTimer("UI_CHANGE_FRIENDLY_NAMES_FONTS_START")
  local FONT = LSM:Fetch('font', 'Naowh')
  local function SetFont(obj, font, size, style)
    if not obj then return end
    obj:SetFont(font, size, style)
  end
  
  SetFont(_G.SystemFont_NamePlate, FONT, 9, 'OUTLINE')
  SetFont(_G.SystemFont_NamePlateFixed, FONT, 9, 'OUTLINE')
  SetFont(_G.SystemFont_LargeNamePlate, FONT, 11, 'OUTLINE')
  SetFont(_G.SystemFont_LargeNamePlateFixed, FONT, 11, 'OUTLINE')
  ns.DEBUG.checkpointDebugTimer("UI_CHANGE_FRIENDLY_NAMES_FONTS_DONE", "UI_CHANGE_FRIENDLY_NAMES_FONTS_START")
end

function UI.hideScreenshotText()
  ns.DEBUG.startDebugTimer("UI_HIDE_SCREENSHOT_TEXT_START")
  ActionStatus:UnregisterEvent("SCREENSHOT_STARTED")
  ActionStatus:UnregisterEvent("SCREENSHOT_SUCCEEDED")
  ActionStatus:UnregisterEvent("SCREENSHOT_FAILED")
  ns.DEBUG.checkpointDebugTimer("UI_HIDE_SCREENSHOT_TEXT_DONE", "UI_HIDE_SCREENSHOT_TEXT_START")
end

function UI.setBuffExpandState(value)
  if BuffFrame and BuffFrame.SetBuffsExpandedState then
    BuffFrame:SetBuffsExpandedState(value)
  end
end 



local enhanceAltPowerBarStatusTextThrottle = nil

function UI.enhanceAltPowerBarStatusText()
  DEBUG.startDebugTimer("UI_ENHANCE_ALTPOWER_START")
  if PlayerPowerBarAlt then
    if PlayerPowerBarAlt._enhanceAltPowerBarStatusText_hooked then return end
    PlayerPowerBarAlt._enhanceAltPowerBarStatusText_hooked = true
    PlayerPowerBarAlt.statusFrame:Show()
    PlayerPowerBarAlt:HookScript("OnShow", function (self)
      PlayerPowerBarAlt.statusFrame:Show()
    end)
    PlayerPowerBarAlt.statusFrame:HookScript("OnUpdate", function (self)
      if enhanceAltPowerBarStatusTextThrottle and enhanceAltPowerBarStatusTextThrottle + 0.25 > GetTime() then return end
      enhanceAltPowerBarStatusTextThrottle = GetTime()
      PlayerPowerBarAlt.statusFrame:Show()
      if PlayerPowerBarAlt.statusFrame.text then
        PlayerPowerBarAlt.statusFrame.text:ClearAllPoints()
        PlayerPowerBarAlt.statusFrame.text:SetPoint("CENTER", PlayerPowerBarAlt.statusFrame, "CENTER", 0, 0)
        PlayerPowerBarAlt.statusFrame.text:SetFont(PlayerPowerBarAlt.statusFrame.text:GetFont(), 14, "OUTLINE")
        PlayerPowerBarAlt.statusFrame:SetFrameStrata(PlayerPowerBarAlt:GetFrameStrata())
        PlayerPowerBarAlt.statusFrame:SetFrameLevel((PlayerPowerBarAlt:GetFrameLevel() or 0) +5)
        local bg
        if not PlayerPowerBarAlt.statusFrame.bg then
          bg = PlayerPowerBarAlt.statusFrame:CreateTexture(nil, "BACKGROUND")
          bg:SetAtlas("evergreen-scenario-titlebg", true)
          bg:SetPoint("CENTER", PlayerPowerBarAlt.statusFrame.text, "CENTER", 0, 0)
          
          PlayerPowerBarAlt.statusFrame.bg = bg
        else 
          bg = PlayerPowerBarAlt.statusFrame.bg
        end
        if PlayerPowerBarAlt.statusFrame.text:GetHeight() > 2 then
          bg:SetAlpha(0.7)
          local width = math.floor(math.max(PlayerPowerBarAlt.statusFrame.text:GetWidth() + 40, PlayerPowerBarAlt:GetWidth() - 60))
          local height = math.floor(PlayerPowerBarAlt.statusFrame.text:GetHeight() + 48)
          bg:SetSize(width, height)
        else 
          bg:SetAlpha(0)
        end
      end
    end)
    if not PlayerPowerBarAlt.statusFrame._enhanceAltPowerBarStatusText_hooked then
      PlayerPowerBarAlt.statusFrame._enhanceAltPowerBarStatusText_hooked = true
      PlayerPowerBarAlt.statusFrame:HookScript("OnHide", function (self)
        PlayerPowerBarAlt.statusFrame:Show()
      end)
    end
  end
  DEBUG.checkpointDebugTimer("UI_ENHANCE_ALTPOWER_DONE", "UI_ENHANCE_ALTPOWER_START")
end


function UI.hideTooltipUnitFrameInstruction()
  if UI._wt_enhancedTooltips then return end
  UI._wt_enhancedTooltips = true
  ns.DEBUG.startDebugTimer("UI_HIDE_TOOLTIP_UNITFRAME_START")
  -- Hide the default GameTooltipStatusBar (health bar)
  GameTooltipStatusBarTexture:SetTexture("")
  -- Remove the right-click for frame settings instruction (UNIT_POPUP_RIGHT_CLICK)
  hooksecurefunc("UnitFrame_UpdateTooltip", function(self)
    GameTooltip_SetDefaultAnchor(GameTooltip, self)
    GameTooltip:SetUnit(self.unit, true)
    GameTooltip:Show()
  end)

  -- hooksecurefunc("GameTooltip_SetDefaultAnchor", function(self,parent) 
  --     self:SetOwner(parent,"ANCHOR_NONE")
  -- end)    
  DEBUG.checkpointDebugTimer("UI_HIDE_TOOLTIP_UNITFRAME_DONE", "UI_HIDE_TOOLTIP_UNITFRAME_START")
end

---------------------------------
-- Tooltip in chat
---------------------------------
local tooltipChatLinksInitialized = false
local LazyHelper = {}

LazyHelper.ChatframeOrig1, LazyHelper.ChatframeOrig2 = {}, {}
LazyHelper.ChatTooltip = GameTooltip

local linkTypes = {
	item = true,
	enchant = true,
	spell = true,
	quest = true,
	unit = true,
	talent = true,
	achievement = true,
	glyph = true,
	instancelock = true,
	currency = true,
	BNplayer = true,
	keystone = true,
	battlepet = true,
 }

function UI.TooltipChatLinks()
  DEBUG.startDebugTimer("UI_TOOLTIP_CHAT_LINKS_START")
  -- Tooltip in chat hook
  if tooltipChatLinksInitialized then
    DEBUG.checkpointDebugTimer("UI_TOOLTIP_CHAT_LINKS_SKIPPED", "UI_TOOLTIP_CHAT_LINKS_START")
    return
  end
  tooltipChatLinksInitialized = true
  
  local _G = getfenv(0)
  for WindowNumber=1, NUM_CHAT_WINDOWS do
    local LazyHelper_ChatframeItemTooltip = _G["ChatFrame"..WindowNumber]
    LazyHelper.ChatframeOrig1[LazyHelper_ChatframeItemTooltip] = LazyHelper_ChatframeItemTooltip:GetScript("OnHyperlinkEnter")
    LazyHelper_ChatframeItemTooltip:SetScript("OnHyperlinkEnter", function(LazyHelper_ChatframeItemTooltip, LazyHelper_link, ...) LazyHelper:OnHyperlinkEnter(LazyHelper_ChatframeItemTooltip, LazyHelper_link, ...) end)

    LazyHelper.ChatframeOrig2[LazyHelper_ChatframeItemTooltip] = LazyHelper_ChatframeItemTooltip:GetScript("OnHyperlinkLeave")
    LazyHelper_ChatframeItemTooltip:SetScript("OnHyperlinkLeave", function(LazyHelper_ChatframeItemTooltip, LazyHelper_link, ...) LazyHelper:OnHyperlinkLeave(LazyHelper_ChatframeItemTooltip, LazyHelper_link, ...) end)
  end
  DEBUG.checkpointDebugTimer("UI_TOOLTIP_CHAT_LINKS_DONE", "UI_TOOLTIP_CHAT_LINKS_START")
end

function LazyHelper:OnHyperlinkEnter(ItemTooltip, link, ...)

  local linkType, linkContent = link:match("^([^:]+):(.+)")
  if (linkType) then
    if linkType == "player1" then
      linkType, linkName, linkId = link:match("^([^:]+):([^:]+):([^:]+):(.+)")
      LazyHelper.ChatTooltip:SetOwner(ItemTooltip, "ANCHOR_CURSOR")
      LazyHelper.ChatTooltip:AddLine("|cFFFFFFFF" .. linkName)
      LazyHelper.ChatTooltip:AddLine("|cFFFFFFFF" .. linkId)
      --LazyHelper.ChatTooltip:Show()
    elseif linkTypes[linkType] then
      LazyHelper.ChatTooltip:SetOwner(ItemTooltip, "ANCHOR_CURSOR")
      LazyHelper.ChatTooltip:SetHyperlink(link)
      --LazyHelper.ChatTooltip:Show()
    end
  end

  if LazyHelper.ChatframeOrig1[ItemTooltip] then return LazyHelper.ChatframeOrig1[ItemTooltip](ItemTooltip, link, ...) end

end

function LazyHelper:OnHyperlinkLeave(ItemTooltip, ...)

  LazyHelper.ChatTooltip:Hide()
  if LazyHelper.ChatframeOrig2[ItemTooltip] then return LazyHelper.ChatframeOrig2[ItemTooltip](ItemTooltip, ...) end

end

---------------------------------

function UI.addCastTimeTextOutline()
  DEBUG.startDebugTimer("UI_ADD_CASTTIME_OUTLINE_START")
  if PlayerCastingBarFrame then
    if not PlayerCastingBarFrame._wt_blizzUI_addCastTimeTextOutline_hooked then
      PlayerCastingBarFrame._wt_blizzUI_addCastTimeTextOutline_hooked = true
      PlayerCastingBarFrame:HookScript("OnShow", function (self)
        if self.CastTimeText then
          local font, size, flags = self.CastTimeText:GetFont()
          self.CastTimeText:SetFont(font, 14, "OUTLINE")
        end
      end)
    end
  end
  DEBUG.checkpointDebugTimer("UI_ADD_CASTTIME_OUTLINE_DONE", "UI_ADD_CASTTIME_OUTLINE_START")
end


function UI.refreshBattlefieldMapFrame()
  if BattlefieldMapFrame and BattlefieldMapFrame:IsShown()  then
    BattlefieldMapFrame:Hide()
    C_Timer.After(0.02, function()
      BattlefieldMapFrame:Show()
    end)
  end
end

function UI.enhanceUIErrorFrame()
  if UIErrorsFrame then 
    UIErrorsFrame:SetScale(1)
    UIErrorsFrame:SetFont(LSM:Fetch("font", "Naowh"), 22, "OUTLINE")
    UIErrorsFrame:SetWidth(800)
    UIErrorsFrame:SetHeight(120)
  end
end

function UI.expandblizzUI_expandFriendListHeightHeight(v)
  v = v or 842
  if FriendsFrame then
    FriendsFrame:SetHeight(v + 118)
    FriendsListFrame.ScrollBox:SetHeight(v)
  end

  if not FriendsFrame._wt_expandblizzUI_expandFriendListHeightHeight_hooked then
    FriendsFrame._wt_expandblizzUI_expandFriendListHeightHeight_hooked = true
    FriendsFrame:HookScript("OnShow", function()
      if FriendGroups_SavedVars and FriendGroups_SavedVars.collapsed then
        for collapseGroupName, _ in pairs(FriendGroups_SavedVars.collapsed) do
          FriendGroups_SavedVars.collapsed[collapseGroupName] = false
        end
      end
    end)
  end
end


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

function UI.hidePartyRaidFramesTitles()
	DEBUG.startDebugTimer("UI_HIDE_PARTY_RAID_TITLES_START")
	if CompactPartyFrameTitle then
		CompactPartyFrameTitle:SetAlpha(0)
    CompactPartyFrameTitle:Hide()
	end
	for i = 1, 8 do
		local titleFrame = _G["CompactRaidGroup" .. i .. "Title"]
		if titleFrame then
			titleFrame:SetAlpha(0)
      titleFrame:Hide()
		end
	end
	DEBUG.checkpointDebugTimer("UI_HIDE_PARTY_RAID_TITLES_DONE", "UI_HIDE_PARTY_RAID_TITLES_START")
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