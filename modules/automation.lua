local _, ns = ...
local Automation = {}
ns.Automation = Automation
local addon = LibStub("AceAddon-3.0"):GetAddon("WilduTools")
local DEBUG = ns.DEBUG

Automation.initialized = {
    gossip = false
}

-- Helper function to check if a value exists in a table
local function tableContains(tbl, value)
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
local function getTargetNPCID()
  local unit = "target"
  
  local guid = UnitGUID(unit)
  if not guid then
    return nil
  end
  
  return tonumber(string.match(guid, "-([^-]+)-[^-]+$"))
end

-- Helper function to handle gossip selection
local function handleGossipSelection(optionIndex)
    local tbl = C_GossipInfo.GetOptions()
    if tbl and tbl[optionIndex] then
        addon:Print("|cFF00ff99Automation Gossip|r: " .. tbl[optionIndex].name)
        SelectGossipOption(optionIndex)
    end
end

-- Main gossip handler
function Automation:HandleGossip()
    -- Check if feature is enabled
    if not ns.db.profile.automation_gossipEnabled then
        return
    end

    -- Stop if modifier key is held down
    if IsModifierKeyDown() then
        return
    end

    local targetID = getTargetNPCID()
    if not targetID then
        return
    end

    -- Get gossip functions with fallbacks
    local GetNumGossipAvailableQuests = GetNumGossipAvailableQuests or C_GossipInfo.GetNumAvailableQuests
    local GetNumGossipActiveQuests = GetNumGossipActiveQuests or C_GossipInfo.GetNumActiveQuests
    local GetNumGossipOptions = GetNumGossipOptions or C_GossipInfo.GetNumOptions or function() return #C_GossipInfo.GetOptions() end

    -- Stop if NPC has quests
    if GetNumGossipActiveQuests() > 0 or GetNumGossipAvailableQuests() > 0 then
        return
    end

    -- Special case: Sean Wilkers NPCs
    if tableContains(ns.CONSTANTS.SPECIAL_NPCS.SEAN_WILKERS, targetID) then
        return
    end

    -- Special case: Adyen the Lightwarden
    if targetID == ns.CONSTANTS.SPECIAL_NPCS.ADYEN_LIGHTWARDEN then
        SelectGossipAvailableQuest(2)
        addon:Print("|cFF00ff99Automation Gossip|r")
        return
    end

    local numOptions = GetNumGossipOptions()
    if numOptions == 1 then
        handleGossipSelection(1)
        return
    end

    -- Handle multiple options for specific NPCs
    if numOptions > 1 then
        -- Option 1 NPCs
        if tableContains(ns.CONSTANTS.SPECIAL_NPCS.OPTION_1_NPCS, targetID) then
            handleGossipSelection(1)
            return
        end

        -- Option 2 NPCs
        if tableContains(ns.CONSTANTS.SPECIAL_NPCS.OPTION_2_NPCS, targetID) then
            handleGossipSelection(2)
            return
        end

        -- Special case: Innkeeper Allison
        if targetID == ns.CONSTANTS.SPECIAL_NPCS.INNKEEPER_ALLISON then
            if numOptions == 4 then
                handleGossipSelection(3)
            elseif numOptions == 3 or numOptions == 2 then
                handleGossipSelection(2)
            end
            return
        end
    end
end

local Automation_InitializeGossips_Throttle = nil
-- Initialize the gossips automation
function Automation:InitializeGossips()
  DEBUG.startDebugTimer("AUTOMATION_INIT_GOSSIPS_START")
  
  if Automation.initialized.gossips then
    DEBUG.checkpointDebugTimer("AUTOMATION_INIT_GOSSIPS_SKIPPED", "AUTOMATION_INIT_GOSSIPS_START")
    return
  end
  
  Automation.initialized.gossips = true
  
  DEBUG.trackEventRegistered("GOSSIP_SHOW", "Automation")
  
  GossipFrame:HookScript("OnShow", function()
    if Automation_InitializeGossips_Throttle ~= nil and UpdateFrameLasAutomation_InitializeGossips_ThrottletUpdate > GetTime() - 0.2 then
        return
    end
    Automation_InitializeGossips_Throttle = GetTime()
    
    self:HandleGossip()
  end)
  
  DEBUG.checkpointDebugTimer("AUTOMATION_INIT_GOSSIPS_DONE", "AUTOMATION_INIT_GOSSIPS_START")
end


function Automation:InitAutoAcceptRole()
    DEBUG.startDebugTimer("AUTOMATION_INIT_AUTOACCEPT_ROLE_START")
    if ns.db.profile.automation_autoAcceptGroupRoleEnabled then
        LFDRoleCheckPopupAcceptButton:SetScript("OnShow", function()
            local leader, leaderGUID  = "", ""
            for i = 1, GetNumSubgroupMembers() do
                if UnitIsGroupLeader("party" .. i) then
                    leader = UnitName("party" .. i)
                    leaderGUID = UnitGUID("party" .. i)
                    break
                end
            end
            LFDRoleCheckPopupAcceptButton:Click()
        end)
        
        addon:Print("|cFF00ff99Automatic Group Role enabled|r")
    else
        LFDRoleCheckPopupAcceptButton:SetScript("OnShow", nil)
    end
    DEBUG.checkpointDebugTimer("AUTOMATION_INIT_AUTOACCEPT_ROLE_DONE", "AUTOMATION_INIT_AUTOACCEPT_ROLE_START")
end

local groupInviteFrame = CreateFrame("FRAME")
groupInviteFrame:SetScript("OnEvent", function()
    if ns.db.profile.automation_autoAcceptGroupInviteEnabled then
        AcceptGroup()
        StaticPopup_ForEachShownDialog(function(self)
            if self.which == "PARTY_INVITE" then
                self.inviteAccepted = 1
                StaticPopup_Hide("PARTY_INVITE")
                return
            elseif self.which == "PARTY_INVITE_XREALM" then
                self.inviteAccepted = 1
                StaticPopup_Hide("PARTY_INVITE_XREALM")
                return
            end
        end)
        local groupInvitePopUp = StaticPopup_FindVisible("GROUP_INVITE_CONFIRMATION")
        if groupInvitePopUp and groupInvitePopUp.data then
            RespondToInviteConfirmation(groupInvitePopUp.data, true)
            -- StaticPopup_Hide("GROUP_INVITE_CONFIRMATION")
        end
    end
end)

function Automation:InitAutoAcceptGroupInvite()
    DEBUG.startDebugTimer("AUTOMATION_INIT_AUTOACCEPT_INVITE_START")
    if ns.db.profile.automation_autoAcceptGroupInviteEnabled then
        groupInviteFrame:RegisterEvent("GROUP_INVITE_CONFIRMATION")
        groupInviteFrame:RegisterEvent("PARTY_INVITE_REQUEST")
        
        addon:Print("|cFF00ff99Automatic Group Invite Accept enabled|r")
    else
        groupInviteFrame:UnregisterEvent("GROUP_INVITE_CONFIRMATION")
        groupInviteFrame:UnregisterEvent("PARTY_INVITE_REQUEST")
    end
    DEBUG.checkpointDebugTimer("AUTOMATION_INIT_AUTOACCEPT_INVITE_DONE", "AUTOMATION_INIT_AUTOACCEPT_INVITE_START")
end


function Automation:SetFormPreservation(enabled)
    DEBUG.startDebugTimer("AUTOMATION_SET_FORM_PRESERVATION_START")
    if enabled then
        SetCVar("autoUnshift", "0")
    else
        SetCVar("autoUnshift", "1")
    end
    DEBUG.checkpointDebugTimer("AUTOMATION_SET_FORM_PRESERVATION_DONE", "AUTOMATION_SET_FORM_PRESERVATION_START")
end
