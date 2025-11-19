local _, ns = ...

--- WilduTools UI Module
--- Handles Blizzard UI modifications and enhancements
local UI = {}
ns.UI = UI

local LSM = LibStub("LibSharedMedia-3.0")
local DEBUG = ns.DEBUG

-- ============================================================================
-- CONSTANTS & CONFIGURATION
-- ============================================================================

local ALTPOWER_THROTTLE = 0.25 -- seconds between alt power bar updates
local OBJECTIVE_TRACKER_SCALE = 0.9
local FONT_NAOWH = LSM:Fetch('font', 'Naowh') or "Fonts\\FRIZQT__.TTF"

-- ============================================================================
-- MODULE STATE
-- ============================================================================

UI._initialized = {
  objectiveTracker = false,
  fonts = false,
  altPowerBar = false,
  screenshots = false,
  tooltips = false,
}

UI._hooks = {
  altPowerBar = nil,
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

---Create throttled update function
---@param throttleTime number Seconds between updates
---@param updateFn function Function to call on update
---@return function throttledUpdate
local function CreateThrottledCallback(throttleTime, updateFn)
  local lastTime = 0
  
  return function(...)
    local currentTime = GetTime()
    if (currentTime - lastTime) >= throttleTime then
      lastTime = currentTime
      updateFn(...)
    end
  end
end

---Safely set font on object
---@param obj table Object to set font on
---@param font string Font path
---@param size number Font size
---@param flags string Font flags (e.g., "OUTLINE")
---@return boolean success
local function SafeSetFont(obj, font, size, flags)
  if not obj then
    return false
  end
  
  if not obj.SetFont then
    DEBUG.log("WARN", "SafeSetFont: Object has no SetFont method")
    return false
  end
  
  obj:SetFont(font, size, flags)
  return true
end

-- ============================================================================
-- OBJECTIVE TRACKER MODIFICATIONS
-- ============================================================================

---Resize Blizzard Objective Tracker
---@param scale number Scale value (0.1 to 5.0)
function UI.resizeBlizzardObjectiveTracker(scale)
  DEBUG.startDebugTimer("UI_RESIZE_OBJECTIVE_TRACKER_START")
  
  if UI._initialized.objectiveTracker then
    DEBUG.checkpointDebugTimer("UI_RESIZE_OBJECTIVE_TRACKER_SKIPPED", "UI_RESIZE_OBJECTIVE_TRACKER_START")
    return
  end
  
  UI._initialized.objectiveTracker = true
  scale = scale or OBJECTIVE_TRACKER_SCALE
  
  if _G["ObjectiveTrackerFrame"] then
    _G["ObjectiveTrackerFrame"]:SetScale(scale)
    DEBUG.log("INFO", "Objective tracker scaled to "..scale)
  else
    DEBUG.log("WARN", "ObjectiveTrackerFrame not found")
  end
  
  DEBUG.checkpointDebugTimer("UI_RESIZE_OBJECTIVE_TRACKER_DONE", "UI_RESIZE_OBJECTIVE_TRACKER_START")
end

---Clean up Objective Tracker header
function UI.cleanupObjectiveTracker()
  DEBUG.startDebugTimer("UI_CLEANUP_OBJECTIVE_TRACKER_START")
  
  if _G["ObjectiveTrackerFrame"] then
    local header = _G["ObjectiveTrackerFrame"].Header
    if header then
      if header.Background then header.Background:Hide() end
      if header.Text then header.Text:Hide() end
      DEBUG.log("INFO", "Objective tracker header cleaned up")
    end
  else
    DEBUG.log("WARN", "ObjectiveTrackerFrame not found")
  end
  
  DEBUG.checkpointDebugTimer("UI_CLEANUP_OBJECTIVE_TRACKER_DONE", "UI_CLEANUP_OBJECTIVE_TRACKER_START")
end

-- ============================================================================
-- FRAMES VISIBILITY MODIFICATIONS
-- ============================================================================

---Hide Blizzard bag and reagent frames
function UI.hideBlizzardBagAndReagentFrames()
  DEBUG.startDebugTimer("UI_HIDE_BAG_REAGENT_FRAMES_START")
  
  if _G["CharacterReagentBag0Slot"] then
    _G["CharacterReagentBag0Slot"]:Hide()
    DEBUG.log("INFO", "Reagent bag frame hidden")
  end
  
  if _G["BagsBar"] then
    _G["BagsBar"]:Hide()
    DEBUG.log("INFO", "Bags bar hidden")
  end
  
  DEBUG.checkpointDebugTimer("UI_HIDE_BAG_REAGENT_FRAMES_DONE", "UI_HIDE_BAG_REAGENT_FRAMES_START")
end

---Hide raid/party frame titles
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
  
  DEBUG.log("INFO", "Party/raid frame titles hidden")
  DEBUG.checkpointDebugTimer("UI_HIDE_PARTY_RAID_TITLES_DONE", "UI_HIDE_PARTY_RAID_TITLES_START")
end

-- ============================================================================
-- FONT MODIFICATIONS
-- ============================================================================

---Change friendly nameplate fonts
function UI.changeFriendlyNamesFonts()
  DEBUG.startDebugTimer("UI_CHANGE_FRIENDLY_NAMES_FONTS_START")
  
  if UI._initialized.fonts then
    DEBUG.checkpointDebugTimer("UI_CHANGE_FRIENDLY_NAMES_FONTS_SKIPPED", "UI_CHANGE_FRIENDLY_NAMES_FONTS_START")
    return
  end
  
  UI._initialized.fonts = true
  
  SafeSetFont(_G.SystemFont_NamePlate, FONT_NAOWH, 9, 'OUTLINE')
  SafeSetFont(_G.SystemFont_NamePlateFixed, FONT_NAOWH, 9, 'OUTLINE')
  SafeSetFont(_G.SystemFont_LargeNamePlate, FONT_NAOWH, 11, 'OUTLINE')
  SafeSetFont(_G.SystemFont_LargeNamePlateFixed, FONT_NAOWH, 11, 'OUTLINE')
  
  DEBUG.log("INFO", "Nameplate fonts updated to Naowh")
  DEBUG.checkpointDebugTimer("UI_CHANGE_FRIENDLY_NAMES_FONTS_DONE", "UI_CHANGE_FRIENDLY_NAMES_FONTS_START")
end

-- ============================================================================
-- SCREENSHOT TEXT HIDING
-- ============================================================================

---Hide screenshot confirmation text
function UI.hideScreenshotText()
  DEBUG.startDebugTimer("UI_HIDE_SCREENSHOT_TEXT_START")
  
  if UI._initialized.screenshots then
    DEBUG.checkpointDebugTimer("UI_HIDE_SCREENSHOT_TEXT_SKIPPED", "UI_HIDE_SCREENSHOT_TEXT_START")
    return
  end
  
  UI._initialized.screenshots = true
  
  if ActionStatus then
    ActionStatus:UnregisterEvent("SCREENSHOT_STARTED")
    ActionStatus:UnregisterEvent("SCREENSHOT_SUCCEEDED")
    ActionStatus:UnregisterEvent("SCREENSHOT_FAILED")
    DEBUG.log("INFO", "Screenshot text hidden")
  end
  
  DEBUG.checkpointDebugTimer("UI_HIDE_SCREENSHOT_TEXT_DONE", "UI_HIDE_SCREENSHOT_TEXT_START")
end

-- ============================================================================
-- CAST TIME TEXT ENHANCEMENT
-- ============================================================================

---Add outline to cast time text
function UI.addCastTimeTextOutline()
  DEBUG.startDebugTimer("UI_ADD_CASTTIME_OUTLINE_START")
  
  if not PlayerCastingBarFrame then
    DEBUG.checkpointDebugTimer("UI_ADD_CASTTIME_OUTLINE_NO_FRAME", "UI_ADD_CASTTIME_OUTLINE_START")
    return
  end
  
  if not PlayerCastingBarFrame._wt_castTimeHooked then
    PlayerCastingBarFrame._wt_castTimeHooked = true
    
    PlayerCastingBarFrame:HookScript("OnShow", function(self)
      if self.CastTimeText then
        local font, size, flags = self.CastTimeText:GetFont()
        self.CastTimeText:SetFont(font, 14, "OUTLINE")
      end
    end)
    
    DEBUG.log("INFO", "Cast time text outline hook installed")
  end
  
  DEBUG.checkpointDebugTimer("UI_ADD_CASTTIME_OUTLINE_DONE", "UI_ADD_CASTTIME_OUTLINE_START")
end

-- ============================================================================
-- ALT POWER BAR ENHANCEMENT
-- ============================================================================

---Enhance Alt Power Bar status text visibility
function UI.enhanceAltPowerBarStatusText()
  DEBUG.startDebugTimer("UI_ENHANCE_ALTPOWER_START")
  
  if UI._initialized.altPowerBar then
    DEBUG.checkpointDebugTimer("UI_ENHANCE_ALTPOWER_SKIPPED", "UI_ENHANCE_ALTPOWER_START")
    return
  end
  
  UI._initialized.altPowerBar = true
  
  if not PlayerPowerBarAlt then
    DEBUG.log("WARN", "PlayerPowerBarAlt not found")
    DEBUG.checkpointDebugTimer("UI_ENHANCE_ALTPOWER_NO_FRAME", "UI_ENHANCE_ALTPOWER_START")
    return
  end
  
  if PlayerPowerBarAlt._wt_enhanced then
    DEBUG.checkpointDebugTimer("UI_ENHANCE_ALTPOWER_ALREADY_DONE", "UI_ENHANCE_ALTPOWER_START")
    return
  end
  
  PlayerPowerBarAlt._wt_enhanced = true
  PlayerPowerBarAlt.statusFrame:Show()
  
  DEBUG.trackHookRegistered("OnShow", "UI.enhanceAltPowerBar")
  DEBUG.trackHookRegistered("OnUpdate", "UI.enhanceAltPowerBar")
  
  PlayerPowerBarAlt:HookScript("OnShow", function(self)
    PlayerPowerBarAlt.statusFrame:Show()
    DEBUG.log("DEBUG", "Alt power bar shown")
  end)
  
  -- Create throttled update for performance
  local updateAltPowerBar = CreateThrottledCallback(ALTPOWER_THROTTLE, function()
    PlayerPowerBarAlt.statusFrame:Show()
    
    if PlayerPowerBarAlt.statusFrame.text then
      PlayerPowerBarAlt.statusFrame.text:ClearAllPoints()
      PlayerPowerBarAlt.statusFrame.text:SetPoint("CENTER", PlayerPowerBarAlt.statusFrame, "CENTER", 0, 0)
      local font, size = PlayerPowerBarAlt.statusFrame.text:GetFont()
      PlayerPowerBarAlt.statusFrame.text:SetFont(font, 14, "OUTLINE")
      PlayerPowerBarAlt.statusFrame:SetFrameStrata(PlayerPowerBarAlt:GetFrameStrata())
      PlayerPowerBarAlt.statusFrame:SetFrameLevel((PlayerPowerBarAlt:GetFrameLevel() or 0) + 5)
      
      -- Setup background
      local bg = PlayerPowerBarAlt.statusFrame.bg
      if not bg then
        bg = PlayerPowerBarAlt.statusFrame:CreateTexture(nil, "BACKGROUND")
        bg:SetAtlas("evergreen-scenario-titlebg", true)
        bg:SetPoint("CENTER", PlayerPowerBarAlt.statusFrame.text, "CENTER", 0, 0)
        PlayerPowerBarAlt.statusFrame.bg = bg
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
  
  PlayerPowerBarAlt.statusFrame:HookScript("OnUpdate", updateAltPowerBar)
  
  if not PlayerPowerBarAlt.statusFrame._wt_hideHooked then
    PlayerPowerBarAlt.statusFrame._wt_hideHooked = true
    PlayerPowerBarAlt.statusFrame:HookScript("OnHide", function(self)
      PlayerPowerBarAlt.statusFrame:Show()
    end)
  end
  
  DEBUG.log("INFO", "Alt power bar enhancement installed")
  DEBUG.checkpointDebugTimer("UI_ENHANCE_ALTPOWER_DONE", "UI_ENHANCE_ALTPOWER_START")
end

-- ============================================================================
-- TOOLTIP IMPROVEMENTS
-- ============================================================================

---Hide tooltip unit frame instruction text
function UI.hideTooltipUnitFrameInstruction()
  DEBUG.startDebugTimer("UI_HIDE_TOOLTIP_UNITFRAME_START")
  
  if UI._initialized.tooltips then
    DEBUG.checkpointDebugTimer("UI_HIDE_TOOLTIP_UNITFRAME_SKIPPED", "UI_HIDE_TOOLTIP_UNITFRAME_START")
    return
  end
  
  UI._initialized.tooltips = true
  
  if GameTooltipStatusBarTexture then
    GameTooltipStatusBarTexture:SetTexture("")
    DEBUG.log("INFO", "Tooltip status bar hidden")
  end
  
  DEBUG.trackHookRegistered("UnitFrame_UpdateTooltip", "UI.hideTooltips")
  
  hooksecurefunc("UnitFrame_UpdateTooltip", function(self)
    GameTooltip_SetDefaultAnchor(GameTooltip, self)
    GameTooltip:SetUnit(self.unit, true)
    GameTooltip:Show()
  end)
  
  DEBUG.log("INFO", "Tooltip unit frame instruction removed")
  DEBUG.checkpointDebugTimer("UI_HIDE_TOOLTIP_UNITFRAME_DONE", "UI_HIDE_TOOLTIP_UNITFRAME_START")
end

-- ============================================================================
-- UI ERROR FRAME
-- ============================================================================

---Enhance UI error frame appearance
function UI.enhanceUIErrorFrame()
  DEBUG.startDebugTimer("UI_ENHANCE_ERROR_FRAME_START")
  
  if UIErrorsFrame then
    UIErrorsFrame:SetScale(1)
    UIErrorsFrame:SetFont(FONT_NAOWH, 22, "OUTLINE")
    UIErrorsFrame:SetWidth(800)
    UIErrorsFrame:SetHeight(120)
    DEBUG.log("INFO", "UI error frame enhanced")
  else
    DEBUG.log("WARN", "UIErrorsFrame not found")
  end
  
  DEBUG.checkpointDebugTimer("UI_ENHANCE_ERROR_FRAME_DONE", "UI_ENHANCE_ERROR_FRAME_START")
end

-- ============================================================================
-- FRIEND LIST EXPANSION
-- ============================================================================

---Expand friend list height for better visibility
---@param height number Height value in pixels
function UI.expandFriendListHeight(height)
  DEBUG.startDebugTimer("UI_EXPAND_FRIEND_LIST_START")
  
  height = height or 842
  
  if FriendsFrame then
    FriendsFrame:SetHeight(height + 118)
    if FriendsListFrame and FriendsListFrame.ScrollBox then
      FriendsListFrame.ScrollBox:SetHeight(height)
    end
    DEBUG.log("INFO", "Friend list expanded to height " .. height)
  else
    DEBUG.log("WARN", "FriendsFrame not found")
  end
  
  if not FriendsFrame._wt_expandedHooked then
    FriendsFrame._wt_expandedHooked = true
    DEBUG.trackHookRegistered("OnShow", "UI.friendList")
    
    FriendsFrame:HookScript("OnShow", function()
      if FriendGroups_SavedVars and FriendGroups_SavedVars.collapsed then
        for groupName, _ in pairs(FriendGroups_SavedVars.collapsed) do
          FriendGroups_SavedVars.collapsed[groupName] = false
        end
      end
    end)
  end
  
  DEBUG.checkpointDebugTimer("UI_EXPAND_FRIEND_LIST_DONE", "UI_EXPAND_FRIEND_LIST_START")
end

-- ============================================================================
-- CHAT LINK TOOLTIPS
-- ============================================================================

local chatLinkTooltipInitialized = false

---Enable tooltips for chat links (item, spell, quest, etc.)
function UI.TooltipChatLinks()
  DEBUG.startDebugTimer("UI_TOOLTIP_CHAT_LINKS_START")
  
  if chatLinkTooltipInitialized then
    DEBUG.checkpointDebugTimer("UI_TOOLTIP_CHAT_LINKS_ALREADY_DONE", "UI_TOOLTIP_CHAT_LINKS_START")
    return
  end
  
  chatLinkTooltipInitialized = true
  
  local linkTypes = {
    item = true, enchant = true, spell = true, quest = true, unit = true,
    talent = true, achievement = true, glyph = true, instancelock = true,
    currency = true, BNplayer = true, keystone = true, battlepet = true,
  }
  
  local ChatTooltip = GameTooltip
  local originalCallbacks = {}
  
  for windowNum = 1, NUM_CHAT_WINDOWS do
    local chatFrame = _G["ChatFrame" .. windowNum]
    if chatFrame then
      originalCallbacks[windowNum] = {
        onEnter = chatFrame:GetScript("OnHyperlinkEnter"),
        onLeave = chatFrame:GetScript("OnHyperlinkLeave"),
      }
      
      chatFrame:SetScript("OnHyperlinkEnter", function(self, link)
        local linkType = link:match("^([^:]+):")
        if linkType and linkTypes[linkType] then
          ChatTooltip:SetOwner(self, "ANCHOR_CURSOR")
          ChatTooltip:SetHyperlink(link)
        end
      end)
      
      chatFrame:SetScript("OnHyperlinkLeave", function()
        ChatTooltip:Hide()
      end)
    end
  end
  
  DEBUG.log("INFO", "Chat link tooltips enabled")
  DEBUG.checkpointDebugTimer("UI_TOOLTIP_CHAT_LINKS_DONE", "UI_TOOLTIP_CHAT_LINKS_START")
end

return UI
