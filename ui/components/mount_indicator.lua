local _, ns = ...

--- Mount Indicator Component
--- Displays an icon when the player is in a mountable area
local MountIndicator = {}

local DEBUG = ns.DEBUG
local WilduUICore = ns.WilduUICore
local LEM = LibStub('LibEditMode')

-- ============================================================================
-- FRAME SETUP
-- ============================================================================

local mountFrame = CreateFrame("Frame", "WilduTools Mount Frame", UIParent)

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

---Initialize the mountable area indicator
---Shows an icon when the player can mount, with options to hide in combat or when already mounted
function MountIndicator.Initialize()
    DEBUG.startDebugTimer("WILDUUI_INIT_MOUNTFRAME_START")
    local CONFIG_KEY = "mountIcon"
    
    if mountFrame._wt_initialized then
        WilduUICore.ApplyFramePosition(mountFrame, CONFIG_KEY, not ns.Addon.db.profile.wilduUI_mountableArea)
        return
    end
    mountFrame._wt_initialized = true
    
    local DEFAULT_CONFIG = { y = 50, hide_incombat = false, hide_whenmounted = false }
    mountFrame:SetSize(32, 32)
    local config = WilduUICore.LoadFrameConfig(CONFIG_KEY, DEFAULT_CONFIG)

    mountFrame.icon = mountFrame:CreateTexture(nil, "OVERLAY")
    mountFrame.icon:SetAllPoints(mountFrame)
    mountFrame.icon:SetAtlas("Fyrakk-Flying-Icon", true)
    
    mountFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    mountFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    mountFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    mountFrame:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
    mountFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    
    local function ApplyMountableVisibility()
        local isMountable = C_Spell.IsSpellUsable(150544)
        if config.hide_incombat and InCombatLockdown() then 
            isMountable = false 
        end

        if config.hide_whenmounted then
            if IsMounted() or GetShapeshiftFormID() == 3 and select(2, UnitClass("player")) == "DRUID" then
                isMountable = false
            end
        end
        
        if isMountable then 
            mountFrame:Show() 
        else 
            mountFrame:Hide() 
        end 
    end
    
    mountFrame:SetScript("OnEvent", function(_, event)
        ApplyMountableVisibility()
    end)
    ApplyMountableVisibility()

    WilduUICore.ApplyFramePosition(mountFrame, CONFIG_KEY, not ns.Addon.db.profile.wilduUI_mountableArea)
    
    WilduUICore.RegisterEditModeCallbacks(mountFrame, CONFIG_KEY, function()
        return ns.Addon.db.profile.wilduUI_mountableArea
    end)

    LEM:RegisterCallback('exit', function()
        ApplyMountableVisibility()
    end)
    
    local additionalSettings = {
        {
			name = 'Hide when already mounted',
			kind = LEM.SettingType.Checkbox,
			default = DEFAULT_CONFIG.hide_whenmounted,
			get = function()
				return ns.Addon.db.profile.editMode[CONFIG_KEY].hide_whenmounted
			end,
			set = function(_, v)
				ns.Addon.db.profile.editMode[CONFIG_KEY].hide_whenmounted = v
			end,
		},
        {
            name = 'Hide in combat (ex. Dimensius or Dawnbreaker)',
            kind = LEM.SettingType.Checkbox,
            default = DEFAULT_CONFIG.hide_incombat,
            get = function()
                return ns.Addon.db.profile.editMode[CONFIG_KEY].hide_incombat
            end,
            set = function(_, v)
                ns.Addon.db.profile.editMode[CONFIG_KEY].hide_incombat = v
            end,
        },
    }

    WilduUICore.RegisterFrameWithLEM(mountFrame, CONFIG_KEY, additionalSettings)
    
    DEBUG.checkpointDebugTimer("WILDUUI_INIT_MOUNTFRAME_DONE", "WILDUUI_INIT_MOUNTFRAME_START")
end

ns.MountIndicator = MountIndicator
return MountIndicator
