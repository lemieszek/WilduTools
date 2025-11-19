-- WilduTools Configuration
local _, ns = ...
WilduTools = LibStub("AceAddon-3.0"):NewAddon("WilduTools", "AceConsole-3.0")
ns.Addon = WilduTools

-- Default Settings
ns.DEFAULT_SETTINGS = {
    profile = {
        actionBars_disable_mouse_ActionButton = false,
        actionBars_disable_mouse_MultiBar5Button = false,
        actionBars_disable_mouse_MultiBar6Button = false,
        actionBars_disable_mouse_MultiBar7Button = false,
        actionBars_disable_mouse_MultiBarBottomLeftButton = false,
        actionBars_disable_mouse_MultiBarBottomRightButton = false,
        actionBars_disable_mouse_MultiBarLeftButton = false,
        actionBars_disable_mouse_MultiBarRightButton = false,
        actionBars_disableMouseOnActionBars = false,
        actionBars_disableMouseOnActionBars_onlyInCombat = false,
        actionBars_disableMouseOnExtraActionBar = false,

        automation_autoAcceptGroupInviteEnabled = false,
        automation_autoAcceptGroupRoleEnabled = false,
        automation_druidCancelTravelFormEnabled = false,
        automation_druidFormCombatPreservation = false,
        automation_gossipEnabled = false,

        blizzUI_addCastTimeTextOutline = false,
        blizzUI_altPowerBarText = false,
        blizzUI_changeFriendlyNamesFont = false,
        blizzUI_chatTooltipOnChatLinks = false,
        blizzUI_cleanupObjectiveTracker = false,
        blizzUI_enchanceUIErrorFrame = false,
        blizzUI_expandFriendListHeight = false,
        blizzUI_expandFriendListHeightRange = 600,
        blizzUI_hideBagsFrames = false,
        blizzUI_hideScreenshotText = false,
        blizzUI_hideTooltipUnitFrameInstruction = false,
        blizzUI_resizeBlizzardObjectiveTracker = false,
        blizzUI_resizeBlizzardObjectiveTrackerRange = 1,

        cooldownManager_centerBuffIcons = false,
        cooldownManager_centerBuffIconsAnchor = false,
        cooldownManager_centerEssentialAnchor = false,

        general_alwaysEnableAllActionBars = false,
        general_defaultScaling = "NoScaling",
        general_minimapButtonOnClickAction = "Settings",
        general_minimapButtonOnClickShiftAction = "Settings",

        partyRaid_hidePartyRaidFramesTitles = false,

        wilduUI_mountableArea = false,
        wilduUI_targetRangeFrame = false,
        wilduUI_spellOnCD = false,
        wilduUI_crosshair = false,

        -- Edit mode movable frames defaults
        editMode = {
            rangeCheck = {
                point = 'CENTER',
                x = 0,
                y = 0,
                scale = 1,
            },
            mountIcon = {
                point = 'CENTER',
                x = 0,
                y = 50,
                scale = 1,
            },
            spellOnCD = {
                point = 'CENTER',
                x = 0,
                y = 0,
                scale = 1,
                alpha = 1,
                zoom = 0, -- percentage 0..0.5 represented as 0..0.5
            },
            crosshair = {
                point = 'CENTER',
                x = 0,
                y = 0,
                scale = 1,
                alpha = 1,
                thickness = 4,
                inner_length = 24,
                border_size = 4,
                class_colored = true,
                customR = 1,
                customG = 1,
                customB = 1,
                visibility = "Always"
            },
        },
    }
}

-- Addon Constants
ns.CONSTANTS = {
    -- Macro Names
    SET_TARGET_MACRO_NAME = "wilduToolsUTM",
    TARGET_MACRO_NAME = "wilduToolsTarget",
    
    -- Class Abilities - unused at the moment
    ABILITIES_PER_CLASS = {
        [1] = 'Titanic Throw',    -- Warrior
        [2] = 'Judgment',         -- Paladin
        [3] = 'Arcane Shot',      -- Hunter
        [4] = 'Shuriken Toss',    -- Rogue
        [5] = 'Shadow Word: Pain',-- Priest
        [6] = 'Death Coil',       -- Death Knight
        [7] = 'Flame Shock',      -- Shaman
        [8] = 'Fire Blast',       -- Mage
        [9] = 'Drain Life',       -- Warlock
        [10] = 'Crackling Jade Lightning', -- Monk
        [11] = 'Moonfire',        -- Druid
        [12] = 'Throw Glaive'     -- Demon Hunter
    },

    -- Special NPC IDs for AutoGossip
    SPECIAL_NPCS = {
        -- Quest NPCs
        ADYEN_LIGHTWARDEN = 18537,    -- Shattrath Aldor Rise
        SEAN_WILKERS = {155261, 155264, 155270, 155346}, -- Statholme Pet Dungeon
        
        -- Option 1 Auto-Select NPCs
        OPTION_1_NPCS = {
            93188,  -- Mongar (Legion Dalaran)
            96782,  -- Lucian Trias (Legion Dalaran)
            97004,  -- "Red" Jack Findle (Legion Dalaran)
            138708, -- Garona Halforcen (BFA)
            135614, -- Master Mathias Shaw (BFA)
            131287, -- Natal'hakata (Horde Zandalari Emissary)
            138097, -- Muka Stormbreaker (Stormsong Valley Horde flight master)
            57850   -- Teleportologist Fozlebub (Darkmoon Faire)
        },
        
        -- Option 2 Auto-Select NPCs
        OPTION_2_NPCS = {
            35004,  -- Jaeren Sunsworn (Trial of the Champion)
            35005,  -- Arelas Brightstar (Trial of the Champion)
            35642   -- Jeeves
        },
        
        -- Special Case NPCs
        INNKEEPER_ALLISON = 6740  -- Stormwind Innkeeper
    }
}


-- Macro Templates
ns.MACRO_TEMPLATES = {
    UTM_EXAMPLE = [[
/cleartarget
/target Defias Trapper
/cleartarget [dead]
/stopmacro [target=target,noexists]
/ping [@target]
/tm 4]],

    UTM_SET_TARGET = [[
/utm wilduToolsTarget
-- use this macro to set new targets for target macro
]]
} 