local _, ns = ...

--- WilduTools Automation Module
--- Handles automatic gossip, group invite acceptance, and form preservation
local Automation = {}
ns.Automation = Automation

local addon = LibStub("AceAddon-3.0"):GetAddon("WilduTools")
local DEBUG = ns.DEBUG

-- ============================================================================
-- CONSTANTS & CONFIGURATION
-- ============================================================================

local GOSSIP_THROTTLE = 0.2 -- seconds between gossip handlers
local GROUP_INVITE_THROTTLE = 0.1 -- seconds between invite handlers

local SPECIAL_NPC_CONFIG = {
  GOSSIP_TIMEOUT = 5, -- Consider gossip closed after 5 seconds
  MAX_RETRIES = 3,
}

-- ============================================================================
-- MODULE STATE
-- ============================================================================

Automation._initialized = {
  gossips = false,
  autoAcceptRole = false,
  autoAcceptInvite = false,
  formPreservation = false,
}

-- Throttle state tracking for performance
local gossipThrottle = {
  lastTime = 0,
  enabled = true,
}

local inviteThrottle = {
  lastTime = 0,
  enabled = true,
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

---Check if a value exists in a table
---@param tbl table Table to search
---@param value any Value to find
---@return boolean found
local function TableContains(tbl, value)
  if not tbl then return false end
  
  for _, v in ipairs(tbl) do
    if v == value then
      return true
    end
  end
  return false
end

---Extract NPC ID from unit GUID
---@param unit string UnitID to extract NPC ID from
---@return number|nil npcID
local function GetTargetNPCID(unit)
  unit = unit or "target"
  
  if not UnitExists(unit) then
    return nil
  end
  
  local guid = UnitGUID(unit)
  if not guid then
    return nil
  end
  
  local npcID = tonumber(string.match(guid, "-([^-]+)-[^-]+$"))
  return npcID
end

---Throttle function execution
---@param throttleState table Throttle state object with lastTime and enabled
---@param throttleTime number Minimum time between calls (seconds)
---@return boolean shouldExecute
local function ShouldThrottle(throttleState, throttleTime)
  if not throttleState.enabled then
    return false
  end
  
  if (GetTime() - throttleState.lastTime) < throttleTime then
    return true -- throttled
  end
  
  throttleState.lastTime = GetTime()
  return false -- should execute
end

-- ============================================================================
-- GOSSIP AUTOMATION
-- ============================================================================

---Handle automatic gossip selection
function Automation:HandleGossip()
  DEBUG.startDebugTimer("AUTOMATION_HANDLE_GOSSIP_START")
  
  if not ns.db.profile.automation_gossipEnabled then
    DEBUG.checkpointDebugTimer("AUTOMATION_HANDLE_GOSSIP_SKIPPED_DISABLED", "AUTOMATION_HANDLE_GOSSIP_START")
    return
  end
  
  -- Skip if modifier held down (allow manual override)
  if IsModifierKeyDown() then
    DEBUG.checkpointDebugTimer("AUTOMATION_HANDLE_GOSSIP_SKIPPED_MODIFIER", "AUTOMATION_HANDLE_GOSSIP_START")
    return
  end
  
  local targetID = GetTargetNPCID("target")
  if not targetID then
    DEBUG.checkpointDebugTimer("AUTOMATION_HANDLE_GOSSIP_NO_TARGET", "AUTOMATION_HANDLE_GOSSIP_START")
    return
  end
  
  -- Get gossip info with fallbacks for compatibility
  local GetNumGossipAvailableQuests = GetNumGossipAvailableQuests or C_GossipInfo.GetNumAvailableQuests
  local GetNumGossipActiveQuests = GetNumGossipActiveQuests or C_GossipInfo.GetNumActiveQuests
  local GetNumGossipOptions = GetNumGossipOptions or C_GossipInfo.GetNumOptions or 
    function() return #C_GossipInfo.GetOptions() end
  
  -- Abort if NPC has quests (player needs to interact manually)
  if GetNumGossipActiveQuests() > 0 or GetNumGossipAvailableQuests() > 0 then
    DEBUG.checkpointDebugTimer("AUTOMATION_HANDLE_GOSSIP_HAS_QUESTS", "AUTOMATION_HANDLE_GOSSIP_START")
    return
  end
  
  -- Special case: Sean Wilkers NPCs
  if TableContains(ns.CONSTANTS.SPECIAL_NPCS.SEAN_WILKERS, targetID) then
    DEBUG.checkpointDebugTimer("AUTOMATION_HANDLE_GOSSIP_SPECIAL_NPC", "AUTOMATION_HANDLE_GOSSIP_START")
    return
  end
  
  -- Special case: Adyen the Lightwarden
  if targetID == ns.CONSTANTS.SPECIAL_NPCS.ADYEN_LIGHTWARDEN then
    SelectGossipAvailableQuest(2)
    addon:Print("|cFF00ff99Automation Gossip|r")
    DEBUG.checkpointDebugTimer("AUTOMATION_HANDLE_GOSSIP_SPECIAL_ADYEN", "AUTOMATION_HANDLE_GOSSIP_START")
    return
  end
  
  local numOptions = GetNumGossipOptions()
  
  -- Single option: always select it
  if numOptions == 1 then
    self:SelectGossipOption(1, targetID)
    DEBUG.checkpointDebugTimer("AUTOMATION_HANDLE_GOSSIP_SINGLE_OPTION", "AUTOMATION_HANDLE_GOSSIP_START")
    return
  end
  
  -- Multiple options: check for special NPCs
  if numOptions > 1 then
    -- Option 1 NPCs
    if TableContains(ns.CONSTANTS.SPECIAL_NPCS.OPTION_1_NPCS, targetID) then
      self:SelectGossipOption(1, targetID)
      DEBUG.checkpointDebugTimer("AUTOMATION_HANDLE_GOSSIP_OPTION1", "AUTOMATION_HANDLE_GOSSIP_START")
      return
    end
    
    -- Option 2 NPCs
    if TableContains(ns.CONSTANTS.SPECIAL_NPCS.OPTION_2_NPCS, targetID) then
      self:SelectGossipOption(2, targetID)
      DEBUG.checkpointDebugTimer("AUTOMATION_HANDLE_GOSSIP_OPTION2", "AUTOMATION_HANDLE_GOSSIP_START")
      return
    end
    
    -- Special case: Innkeeper Allison
    if targetID == ns.CONSTANTS.SPECIAL_NPCS.INNKEEPER_ALLISON then
      if numOptions == 4 then
        self:SelectGossipOption(3, targetID)
      elseif numOptions == 3 or numOptions == 2 then
        self:SelectGossipOption(2, targetID)
      end
      DEBUG.checkpointDebugTimer("AUTOMATION_HANDLE_GOSSIP_INNKEEPER", "AUTOMATION_HANDLE_GOSSIP_START")
      return
    end
  end
  
  DEBUG.checkpointDebugTimer("AUTOMATION_HANDLE_GOSSIP_NO_MATCH", "AUTOMATION_HANDLE_GOSSIP_START")
end

---Select gossip option with logging
---@param optionIndex number Gossip option index
---@param npcID number NPC being spoken to
local function SelectGossipOption(optionIndex, npcID)
  DEBUG.startDebugTimer("AUTOMATION_SELECT_GOSSIP_START")
  
  local tbl = C_GossipInfo.GetOptions()
  if tbl and tbl[optionIndex] then
    addon:Print("|cFF00ff99Automation Gossip|r: " .. tbl[optionIndex].name)
    SelectGossipOption(optionIndex)
    DEBUG.log("EVENT", "Selected gossip option "..optionIndex.." for NPC "..npcID)
  else
    DEBUG.log("WARN", "Gossip option "..optionIndex.." not found")
  end
  
  DEBUG.checkpointDebugTimer("AUTOMATION_SELECT_GOSSIP_DONE", "AUTOMATION_SELECT_GOSSIP_START")
end

Automation.SelectGossipOption = SelectGossipOption

---Initialize gossip automation
function Automation:InitializeGossips()
  DEBUG.startDebugTimer("AUTOMATION_INIT_GOSSIPS_START")
  
  if self._initialized.gossips then
    DEBUG.checkpointDebugTimer("AUTOMATION_INIT_GOSSIPS_SKIPPED", "AUTOMATION_INIT_GOSSIPS_START")
    return
  end
  
  self._initialized.gossips = true
  
  DEBUG.trackEventRegistered("GOSSIP_SHOW", "Automation")
  
  GossipFrame:HookScript("OnShow", function()
    if ShouldThrottle(gossipThrottle, GOSSIP_THROTTLE) then
      return
    end
    
    self:HandleGossip()
  end)
  
  DEBUG.checkpointDebugTimer("AUTOMATION_INIT_GOSSIPS_DONE", "AUTOMATION_INIT_GOSSIPS_START")
end

-- ============================================================================
-- GROUP INVITE AUTOMATION
-- ============================================================================

---Initialize group invite auto-accept
function Automation:InitAutoAcceptGroupInvite()
  DEBUG.startDebugTimer("AUTOMATION_INIT_AUTO_ACCEPT_INVITE_START")
  
  if self._initialized.autoAcceptInvite then
    DEBUG.checkpointDebugTimer("AUTOMATION_INIT_AUTO_ACCEPT_INVITE_SKIPPED", "AUTOMATION_INIT_AUTO_ACCEPT_INVITE_START")
    return
  end
  
  self._initialized.autoAcceptInvite = true
  
  if not ns.db.profile.automation_autoAcceptGroupInviteEnabled then
    DEBUG.checkpointDebugTimer("AUTOMATION_INIT_AUTO_ACCEPT_INVITE_DISABLED", "AUTOMATION_INIT_AUTO_ACCEPT_INVITE_START")
    return
  end
  
  local inviteFrame = CreateFrame("Frame", "WilduTools_GroupInviteFrame")
  
  DEBUG.trackEventRegistered("GROUP_INVITE_CONFIRMATION", "Automation")
  DEBUG.trackEventRegistered("PARTY_INVITE_REQUEST", "Automation")
  
  inviteFrame:RegisterEvent("GROUP_INVITE_CONFIRMATION")
  inviteFrame:RegisterEvent("PARTY_INVITE_REQUEST")
  
  inviteFrame:SetScript("OnEvent", function(self, event)
    if ShouldThrottle(inviteThrottle, GROUP_INVITE_THROTTLE) then
      return
    end
    
    if event == "PARTY_INVITE_REQUEST" then
      AcceptGroup()
      DEBUG.log("EVENT", "Auto-accepted group invite")
    elseif event == "GROUP_INVITE_CONFIRMATION" then
      local popup = StaticPopup_FindVisible("GROUP_INVITE_CONFIRMATION")
      if popup and popup.data then
        RespondToInviteConfirmation(popup.data, true)
        DEBUG.log("EVENT", "Auto-confirmed group invite")
      end
    end
  end)
  
  addon:Print("|cFF00ff99Automatic Group Invite Accept enabled|r")
  DEBUG.checkpointDebugTimer("AUTOMATION_INIT_AUTO_ACCEPT_INVITE_DONE", "AUTOMATION_INIT_AUTO_ACCEPT_INVITE_START")
end

---Initialize group role auto-accept
function Automation:InitAutoAcceptRole()
  DEBUG.startDebugTimer("AUTOMATION_INIT_AUTO_ACCEPT_ROLE_START")
  
  if self._initialized.autoAcceptRole then
    DEBUG.checkpointDebugTimer("AUTOMATION_INIT_AUTO_ACCEPT_ROLE_SKIPPED", "AUTOMATION_INIT_AUTO_ACCEPT_ROLE_START")
    return
  end
  
  self._initialized.autoAcceptRole = true
  
  if not ns.db.profile.automation_autoAcceptGroupRoleEnabled then
    DEBUG.checkpointDebugTimer("AUTOMATION_INIT_AUTO_ACCEPT_ROLE_DISABLED", "AUTOMATION_INIT_AUTO_ACCEPT_ROLE_START")
    return
  end
  
  DEBUG.trackEventRegistered("LFD_ROLE_CHECK_SHOW", "Automation")
  
  LFDRoleCheckPopupAcceptButton:HookScript("OnShow", function()
    LFDRoleCheckPopupAcceptButton:Click()
    DEBUG.log("EVENT", "Auto-accepted role check")
  end)
  
  addon:Print("|cFF00ff99Automatic Group Role enabled|r")
  DEBUG.checkpointDebugTimer("AUTOMATION_INIT_AUTO_ACCEPT_ROLE_DONE", "AUTOMATION_INIT_AUTO_ACCEPT_ROLE_START")
end

---Initialize EditMode default layout setting
function Automation:SetDefaultEditModeManagerLayout()
  DEBUG.startDebugTimer("AUTOMATION_SET_DEFAULT_EDITMODE_LAYOUT_START")
  
  if EditModeManagerFrame and EditModeManagerFrame.layoutInfo and 
    (EditModeManagerFrame.layoutInfo.activeLayout == 1 or EditModeManagerFrame.layoutInfo.activeLayout == 2) then
    EditModeManagerFrame:SelectLayout(3)
    DEBUG.log("INFO", "Set EditMode layout to layout 3")
  end
  
  DEBUG.checkpointDebugTimer("AUTOMATION_SET_DEFAULT_EDITMODE_LAYOUT_DONE", "AUTOMATION_SET_DEFAULT_EDITMODE_LAYOUT_START")
end

---Set Druid form preservation
---@param enabled boolean Whether to preserve form across combat
function Automation:SetFormPreservation(enabled)
  DEBUG.startDebugTimer("AUTOMATION_SET_FORM_PRESERVATION_START")
  
  if self._initialized.formPreservation then
    DEBUG.checkpointDebugTimer("AUTOMATION_SET_FORM_PRESERVATION_SKIPPED", "AUTOMATION_SET_FORM_PRESERVATION_START")
    return
  end
  
  self._initialized.formPreservation = true
  
  if enabled then
    C_CVar.SetCVar("autoUnshift", "0")
    DEBUG.log("INFO", "Form preservation enabled (autoUnshift=0)")
  else
    C_CVar.SetCVar("autoUnshift", "1")
    DEBUG.log("INFO", "Form preservation disabled (autoUnshift=1)")
  end
  
  DEBUG.checkpointDebugTimer("AUTOMATION_SET_FORM_PRESERVATION_DONE", "AUTOMATION_SET_FORM_PRESERVATION_START")
end

return Automation
