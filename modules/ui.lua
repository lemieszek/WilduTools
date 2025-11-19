local _, ns = ...
local LSM = LibStub("LibSharedMedia-3.0")
local UI = {}
ns.UI = UI 
local DEBUG = ns.DEBUG

function UI.resizeBlizzardObjectiveTracker(value)
  ns.DEBUG.startDebugTimer("UI_RESIZE_OBJECTIVE_TRACKER_START")
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



function UI.enhanceUIErrorFrame()
  if UIErrorsFrame then 
    UIErrorsFrame:SetScale(1)
    UIErrorsFrame:SetFont(LSM:Fetch("font", "Naowh"), 22, "OUTLINE")
    UIErrorsFrame:SetWidth(800)
    UIErrorsFrame:SetHeight(120)
  end
end

function UI.expandFriendListHeight(v)
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
