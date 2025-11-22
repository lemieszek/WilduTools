local _, ns = ...
local WilduSettings = {}
ns.WilduSettings = WilduSettings

---@type string[]
ns.WilduSettings.expandableSectionInitializers = {}

---@class SettingPreviewItem
---@field text string  # Description text for the setting
---@field image string # Image path or URL for the setting preview

---@class SettingPreview
---@field [string] SettingPreviewItem # Indexed by variableName

--- Preview configuration for settings.
--- Key: variableName
--- Value: { text: string, image: string }
---@type SettingPreview
WilduSettings.settingPreview = {
    -- Example:
    -- mySetting = {
    --     text = "This setting controls X behavior.",
    --     image = "Interface\\AddOns\\MyAddon\\media\\mySettingPreview"
    -- },
}
local variableToPreview = nil

local PreviewFrame = CreateFrame("Frame", "WilduSettings_PreviewFrame", SettingsPanel.CategoryList)
PreviewFrame:SetSize(366, 100) -- height includes image + text
PreviewFrame:SetPoint("TOPRIGHT", SettingsPanel.CategoryList, "TOPRIGHT", -8, 0) -- adjust as needed
PreviewFrame:Hide()

-- Picture frame inside wrapper
PreviewFrame.image = PreviewFrame:CreateTexture(nil, "ARTWORK")
PreviewFrame.image:SetPoint("TOP", 0, -16)
PreviewFrame.image:SetHeight(330)
PreviewFrame.image:SetWidth(330)
PreviewFrame.image:SetTexture("Interface\\AddOns\\!WilduTools\\Media\\SettingsPreview\\preview.png")
PreviewFrame.image:SetTexCoord(0, 1, 0, 1)

-- Text below image
PreviewFrame.text = PreviewFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalMed2Outline")
PreviewFrame.text:SetPoint("TOP", PreviewFrame.image, "BOTTOM", 0, -6)
PreviewFrame.text:SetJustifyH("Left")
PreviewFrame.text:SetWordWrap(true)
PreviewFrame.text:SetWidth(PreviewFrame.image:GetWidth() - 12)
PreviewFrame:SetHeight(350 + WilduSettings_PreviewFrame.text:GetHeight())

local BORDER_SHRINK = 3
local bg = ns.API:CreateNineSliceFrame(PreviewFrame, "Tooltip_Brown");
bg:SetCornerSize(28);
PreviewFrame.Background = bg;
bg:SetFrameLevel(PreviewFrame:GetFrameLevel());
bg:SetPoint("TOPLEFT", PreviewFrame, "TOPLEFT", BORDER_SHRINK, -BORDER_SHRINK);
bg:SetPoint("BOTTOMRIGHT", PreviewFrame, "BOTTOMRIGHT", -BORDER_SHRINK, BORDER_SHRINK);


function WilduSettings:SetVariableToPreview(variable)
    if variable and WilduSettings.settingPreview[variable] then
        if not WilduSettings.settingPreview[variable].image then
            PreviewFrame:Hide()
            return
        end
        PreviewFrame.image:SetTexture("Interface\\AddOns\\!WilduTools\\Media\\SettingsPreview\\"..WilduSettings.settingPreview[variable].image..".png")
        if WilduSettings.settingPreview[variable].text then
            PreviewFrame.text:SetText(WilduSettings.settingPreview[variable].text)
        else
            PreviewFrame.text:SetText("")
        end
        PreviewFrame:SetHeight(350 + WilduSettings_PreviewFrame.text:GetHeight() + 16)
        PreviewFrame:Show()
    else
        PreviewFrame:Hide()
    end
end


ns.WilduSettings.SettingsLayout = {}

local function AddInitializerToLayout(category, initializer)
    local _layout = SettingsPanel:GetLayout(category);
    _layout:AddInitializer(initializer);
end

-----------------------------------------------------------------------
-- Section helper, modeled after TTT Config:MakeExpandableSection
-----------------------------------------------------------------------
-- Returns:
--   expandInitializer (header initializer)
--   isExpanded() -> boolean  (closure used as shown predicate)
local function MakeExpandableSection(layout, sectionName)
    local nameGetter = sectionName
    if type(sectionName) == "string" then
        nameGetter = function() return sectionName end
    end

    local expandInitializer = CreateSettingsExpandableSectionInitializer(nameGetter())
    expandInitializer.data.nameGetter = nameGetter

    -- Ensure expanded by default
    expandInitializer.data.expanded = true

    function expandInitializer:GetExtent()
        return 25
    end

    local origInitFrame = expandInitializer.InitFrame
    function expandInitializer:InitFrame(frame)
        self.data.name = self.data.nameGetter()
        origInitFrame(self, frame)

        function frame:OnExpandedChanged(expanded)
            self:EvaluateVisibility(expanded)
            SettingsInbound.RepairDisplay()
        end

        function frame:EvaluateVisibility(expanded)
            if self.Button and self.Button.Right then
                if expanded then
                    self.Button.Right:SetAtlas("Options_ListExpand_Right_Expanded", TextureKitConstants.UseAtlasSize)
                else
                    self.Button.Right:SetAtlas("Options_ListExpand_Right", TextureKitConstants.UseAtlasSize)
                end
            end
        end

        function frame:CalculateHeight()
            local initializer = self:GetElementData()
            return initializer:GetExtent()
        end

        -- Use our explicit expanded flag
        frame:EvaluateVisibility(self.data.expanded)
    end

    layout:AddInitializer(expandInitializer)

    local function IsExpanded()
        return expandInitializer.data.expanded
    end

    table.insert(ns.WilduSettings.expandableSectionInitializers, expandInitializer)
    return expandInitializer, IsExpanded
end

-----------------------------------------------------------------------
-- Checkbox helpers (unchanged except for optional section predicate)
-----------------------------------------------------------------------
function WilduSettings.WildCreateCheckbox(category, setting, tooltip)
	return WilduSettings.WildCreateCheckboxWithOptions(category, setting, nil, tooltip);
end

function WilduSettings.WildCreateCheckboxWithOptions(category, setting, options, tooltip)
	local initializer = WilduSettings.WildCreateCheckboxInitializer(setting, options, tooltip);
	AddInitializerToLayout(category, initializer);
	return initializer;
end

function WilduSettings.WildCreateCheckboxInitializer(setting, options, tooltip)
	assert(setting:GetVariableType() == "boolean");
	return Settings.CreateControlInitializer("WilduSettingsCheckboxControlTemplate", setting, options, tooltip);
end

local test = false

function WilduSettings:DevInit()
    local category, layout = Settings.RegisterVerticalLayoutCategory("WilduTools")

    Settings.RegisterAddOnCategory(category)
    ns.WilduSettings.SettingsLayout.rootCategory = category
    ns.WilduSettings.SettingsLayout.rootLayout = layout

    -------------------------------------------------
    -- Helper: create checkbox & tie it to a section
    -------------------------------------------------

    ---@param cbData CheckboxData Checkbox configuration object
    local function CreateCheckboxInSection(headerInitializer, isExpandedFunc, cbData)
        local entry = WilduSettings.SettingsCreateCheckbox(category, cbData)

        -- TTT-style: no SetParentInitializer, only order + shown predicate
        if isExpandedFunc then
            entry.element:AddShownPredicate(isExpandedFunc)
        end

        return entry
    end

    -- Slider helper
    local function CreateSliderInSection(headerInitializer, isExpandedFunc, label, variable, minValue, maxValue, step, getValue, setValue, desc, labelFormat)
        local setting = Settings.RegisterProxySetting(
            ns.WilduSettings.SettingsLayout.rootCategory,
            variable,
            Settings.VarType.Number,
            label,
            getValue(),
            getValue,
            setValue
        )
        

        local options = Settings.CreateSliderOptions(minValue, maxValue, step)

        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
            value = math.floor(value * 100 + 0.5) / 100
            labelFormat = labelFormat or "%.0f"
            return string.format(labelFormat, value)
        end)

        local initializer = Settings.CreateSlider(ns.WilduSettings.SettingsLayout.rootCategory, setting, options, desc)

        if isExpandedFunc then
            initializer:AddShownPredicate(isExpandedFunc)
        end

        return initializer, setting
    end

    -- Dropdown helper
    local function CreateDropdownInSection(headerInitializer, isExpandedFunc, label, variable, valuesTable, orderList, getValue, setValue, desc)
        local function GetOptions()
            local container = Settings.CreateControlTextContainer()
            if orderList then
                for _, key in ipairs(orderList) do
                    local text = valuesTable[key]
                    container:Add(key, text, nil)
                end
            else
                for key, text in pairs(valuesTable) do
                    container:Add(key, text, nil)
                end
            end
            return container:GetData()
        end

        local defaultValue = getValue()
        local setting = Settings.RegisterProxySetting(
            ns.WilduSettings.SettingsLayout.rootCategory,
            variable,
            Settings.VarType.String,
            label,
            defaultValue,
            getValue,
            setValue
        )

        local initializer = Settings.CreateDropdown(ns.WilduSettings.SettingsLayout.rootCategory, setting, GetOptions, desc)

        if isExpandedFunc then
            initializer:AddShownPredicate(isExpandedFunc)
        end

        return initializer, setting
    end

    -------------------------------------------------
    -- Automation section + its checkboxes
    -------------------------------------------------
    local automationHeader, automationIsExpanded = MakeExpandableSection(layout, "Automation")

    CreateCheckboxInSection(automationHeader, automationIsExpanded, {
        variable = "automation_gossipEnabled",
        name = "Auto gossip when only one option is available",
        getValue = function() return ns.db.profile.automation_gossipEnabled end,
        setValue = function(v) ns.db.profile.automation_gossipEnabled = v end,
        desc = "Hold Shift to disable the behavior.",
        -- previewImage = "preview", -- todo for each relevant setting
        defaultValue = false
    })

    CreateCheckboxInSection(automationHeader, automationIsExpanded, {
        variable = "automation_autoAcceptGroupInviteEnabled",
        name = "Auto accept group invites",
        getValue = function() return ns.db.profile.automation_autoAcceptGroupInviteEnabled end,
        setValue = function(v)
            ns.db.profile.automation_autoAcceptGroupInviteEnabled = v
            ns.Automation:InitAutoAcceptGroupInvite()
        end,
        desc = "Automatically accept group invites from anyone (friends and guild members in the future)."
    })

    CreateCheckboxInSection(automationHeader, automationIsExpanded, {
        variable = "automation_autoAcceptGroupRoleEnabled",
        name = "Auto accept role check",
        getValue = function() return ns.db.profile.automation_autoAcceptGroupRoleEnabled end,
        setValue = function(v)
            ns.db.profile.automation_autoAcceptGroupRoleEnabled = v
            ns.Automation:InitAutoAcceptRole()
        end,
        desc = "Automatically accept the role check popup when joining a group."
    })

    CreateCheckboxInSection(automationHeader, automationIsExpanded, {
        variable = "automation_druidCancelTravelFormEnabled",
        name = "Auto travel => flying form",
        getValue = function() return ns.db.profile.automation_druidCancelTravelFormEnabled end,
        setValue = function(v) ns.db.profile.automation_druidCancelTravelFormEnabled = v end,
        desc = "Auto cancel travel form and switch to flying form when flying is available."
    })

    CreateCheckboxInSection(automationHeader, automationIsExpanded, {
        variable = "automation_druidFormCombatPreservation",
        name = "Preserve Druid Form (in Combat)",
        getValue = function() return ns.db.profile.automation_druidFormCombatPreservation end,
        setValue = function(v) ns.db.profile.automation_druidFormCombatPreservation = v end,
        desc = "Prevent automatic cancellation of Druid Forms when casting spells that normally cancel them."
    })

    -------------------------------------------------
    -- Control & Behavior section + its checkboxes
    -------------------------------------------------
    local controlBehaviorHeader, controlBehaviorIsExpanded = MakeExpandableSection(layout, "Control & Behavior")
    CreateCheckboxInSection(controlBehaviorHeader, controlBehaviorIsExpanded, {
        variable = "controlBehavior_free_right_click_move",
        name = "Right Mouse Button Camera Unlock |cffff0000(throws taint in combat but.. works)|r",
        defaultValue = false,
        getValue = function() return ns.db.profile.controlBehavior_free_right_click_move end,
        setValue = function(v)
            ns.db.profile.controlBehavior_free_right_click_move = v
            if v then
                ns.ControlBehavior.FreeRightClickMove:OnEnable()
            else
                ns.ControlBehavior.FreeRightClickMove:OnDisable()
            end
         end,
        desc = "Allows free camera movement while holding and dragging the right mouse button over UI frames such as raid frames. Right-click without dragging still opens menus normally. Cursor locks during mouselook and releases when RMB is lifted."
    })

    CreateCheckboxInSection(controlBehaviorHeader, controlBehaviorIsExpanded, {
        variable = "controlBehavior_free_right_click_move_in_combat",
        name = "Only in Combat",
        defaultValue = false,
        getValue = function() return ns.db.profile.controlBehavior_free_right_click_move_in_combat end,
        setValue = function(v) ns.db.profile.controlBehavior_free_right_click_move_in_combat = v end,
    })

    -------------------------------------------------
    -- Action Bars section + its checkboxes
    -------------------------------------------------
    local actionBarsHeader, actionBarsIsExpanded = MakeExpandableSection(layout, "Action Bars")

    CreateCheckboxInSection(actionBarsHeader, actionBarsIsExpanded, {
        variable = "actionBars_disableMouseOnActionBars",
        name = "Disable Mouse on Action Bars",
        getValue = function() return ns.db.profile.actionBars_disableMouseOnActionBars end,
        setValue = function(v)
            ns.db.profile.actionBars_disableMouseOnActionBars = v

            if v and not ns.db.profile.actionBars_disableMouseOnActionBars_onlyInCombat then
                if ns.db.profile.actionBars_disable_mouse_ActionButton then ns.ActionBars.disableMouseOnBar("ActionButton") else ns.ActionBars.enableMouseOnBar("ActionButton") end
                if ns.db.profile.actionBars_disable_mouse_MultiBarBottomLeftButton then ns.ActionBars.disableMouseOnBar("MultiBarBottomLeftButton") else ns.ActionBars.enableMouseOnBar("MultiBarBottomLeftButton") end
                if ns.db.profile.actionBars_disable_mouse_MultiBarBottomRightButton then ns.ActionBars.disableMouseOnBar("MultiBarBottomRightButton") else ns.ActionBars.enableMouseOnBar("MultiBarBottomRightButton") end
                if ns.db.profile.actionBars_disable_mouse_MultiBarLeftButton then ns.ActionBars.disableMouseOnBar("MultiBarLeftButton") else ns.ActionBars.enableMouseOnBar("MultiBarLeftButton") end
                if ns.db.profile.actionBars_disable_mouse_MultiBarRightButton then ns.ActionBars.disableMouseOnBar("MultiBarRightButton") else ns.ActionBars.enableMouseOnBar("MultiBarRightButton") end
                if ns.db.profile.actionBars_disable_mouse_MultiBar5Button then ns.ActionBars.disableMouseOnBar("MultiBar5Button") else ns.ActionBars.enableMouseOnBar("MultiBar5Button") end
                if ns.db.profile.actionBars_disable_mouse_MultiBar6Button then ns.ActionBars.disableMouseOnBar("MultiBar6Button") else ns.ActionBars.enableMouseOnBar("MultiBar6Button") end
                if ns.db.profile.actionBars_disable_mouse_MultiBar7Button then ns.ActionBars.disableMouseOnBar("MultiBar7Button") else ns.ActionBars.enableMouseOnBar("MultiBar7Button") end
            else
                ns.ActionBars.enableMouseOnBar("ActionButton")
                ns.ActionBars.enableMouseOnBar("MultiBarBottomLeftButton")
                ns.ActionBars.enableMouseOnBar("MultiBarBottomRightButton")
                ns.ActionBars.enableMouseOnBar("MultiBarLeftButton")
                ns.ActionBars.enableMouseOnBar("MultiBarRightButton")
                ns.ActionBars.enableMouseOnBar("MultiBar5Button")
                ns.ActionBars.enableMouseOnBar("MultiBar6Button")
                ns.ActionBars.enableMouseOnBar("MultiBar7Button")
            end
        end,
        desc = "Master switch for disabling mouse input on selected action bars."
    })

    CreateCheckboxInSection(actionBarsHeader, actionBarsIsExpanded, {
        variable = "actionBars_disableMouseOnActionBars_onlyInCombat",
        name = "Only in Combat",
        getValue = function() return ns.db.profile.actionBars_disableMouseOnActionBars_onlyInCombat end,
        setValue = function(v)
            ns.db.profile.actionBars_disableMouseOnActionBars_onlyInCombat = v

            if not v and ns.db.profile.actionBars_disableMouseOnActionBars then
                if ns.db.profile.actionBars_disable_mouse_ActionButton then ns.ActionBars.disableMouseOnBar("ActionButton") else ns.ActionBars.enableMouseOnBar("ActionButton") end
                if ns.db.profile.actionBars_disable_mouse_MultiBarBottomLeftButton then ns.ActionBars.disableMouseOnBar("MultiBarBottomLeftButton") else ns.ActionBars.enableMouseOnBar("MultiBarBottomLeftButton") end
                if ns.db.profile.actionBars_disable_mouse_MultiBarBottomRightButton then ns.ActionBars.disableMouseOnBar("MultiBarBottomRightButton") else ns.ActionBars.enableMouseOnBar("MultiBarBottomRightButton") end
                if ns.db.profile.actionBars_disable_mouse_MultiBarLeftButton then ns.ActionBars.disableMouseOnBar("MultiBarLeftButton") else ns.ActionBars.enableMouseOnBar("MultiBarLeftButton") end
                if ns.db.profile.actionBars_disable_mouse_MultiBarRightButton then ns.ActionBars.disableMouseOnBar("MultiBarRightButton") else ns.ActionBars.enableMouseOnBar("MultiBarRightButton") end
                if ns.db.profile.actionBars_disable_mouse_MultiBar5Button then ns.ActionBars.disableMouseOnBar("MultiBar5Button") else ns.ActionBars.enableMouseOnBar("MultiBar5Button") end
                if ns.db.profile.actionBars_disable_mouse_MultiBar6Button then ns.ActionBars.disableMouseOnBar("MultiBar6Button") else ns.ActionBars.enableMouseOnBar("MultiBar6Button") end
                if ns.db.profile.actionBars_disable_mouse_MultiBar7Button then ns.ActionBars.disableMouseOnBar("MultiBar7Button") else ns.ActionBars.enableMouseOnBar("MultiBar7Button") end
            elseif not InCombatLockdown() then
                ns.ActionBars.enableMouseOnBar("ActionButton")
                ns.ActionBars.enableMouseOnBar("MultiBarBottomLeftButton")
                ns.ActionBars.enableMouseOnBar("MultiBarBottomRightButton")
                ns.ActionBars.enableMouseOnBar("MultiBarLeftButton")
                ns.ActionBars.enableMouseOnBar("MultiBarRightButton")
                ns.ActionBars.enableMouseOnBar("MultiBar5Button")
                ns.ActionBars.enableMouseOnBar("MultiBar6Button")
                ns.ActionBars.enableMouseOnBar("MultiBar7Button")
            end
        end,
        desc = "Apply mouse disabling only when entering combat."
    })

    -- Per-bar toggles
    CreateCheckboxInSection(actionBarsHeader, actionBarsIsExpanded, {
        variable = "actionBars_disable_mouse_ActionButton",
        name = "Action Bar 1",
        getValue = function() return ns.db.profile.actionBars_disable_mouse_ActionButton end,
        setValue = function(v)
            ns.db.profile.actionBars_disable_mouse_ActionButton = v
            if ns.db.profile.actionBars_disableMouseOnActionBars then
                if v then ns.ActionBars.disableMouseOnBar("ActionButton") else ns.ActionBars.enableMouseOnBar("ActionButton") end
            end
        end,
        desc = "Per-action-bar mouse disable for Action Bar 1."
    })

    CreateCheckboxInSection(actionBarsHeader, actionBarsIsExpanded, {
        variable = "actionBars_disable_mouse_MultiBarBottomLeftButton",
        name = "Action Bar 2",
        getValue = function() return ns.db.profile.actionBars_disable_mouse_MultiBarBottomLeftButton end,
        setValue = function(v)
            ns.db.profile.actionBars_disable_mouse_MultiBarBottomLeftButton = v
            if ns.db.profile.actionBars_disableMouseOnActionBars then
                if v then ns.ActionBars.disableMouseOnBar("MultiBarBottomLeftButton") else ns.ActionBars.enableMouseOnBar("MultiBarBottomLeftButton") end
            end
        end,
        desc = "Per-action-bar mouse disable for Action Bar 2."
    })

    CreateCheckboxInSection(actionBarsHeader, actionBarsIsExpanded, {
        variable = "actionBars_disable_mouse_MultiBarBottomRightButton",
        name = "Action Bar 3",
        getValue = function() return ns.db.profile.actionBars_disable_mouse_MultiBarBottomRightButton end,
        setValue = function(v)
            ns.db.profile.actionBars_disable_mouse_MultiBarBottomRightButton = v
            if ns.db.profile.actionBars_disableMouseOnActionBars then
                if v then ns.ActionBars.disableMouseOnBar("MultiBarBottomRightButton") else ns.ActionBars.enableMouseOnBar("MultiBarBottomRightButton") end
            end
        end,
        desc = "Per-action-bar mouse disable for Action Bar 3."
    })

    CreateCheckboxInSection(actionBarsHeader, actionBarsIsExpanded, {
        variable = "actionBars_disable_mouse_MultiBarLeftButton",
        name = "Action Bar 4",
        getValue = function() return ns.db.profile.actionBars_disable_mouse_MultiBarLeftButton end,
        setValue = function(v)
            ns.db.profile.actionBars_disable_mouse_MultiBarLeftButton = v
            if ns.db.profile.actionBars_disableMouseOnActionBars then
                if v then ns.ActionBars.disableMouseOnBar("MultiBarLeftButton") else ns.ActionBars.enableMouseOnBar("MultiBarLeftButton") end
            end
        end,
        desc = "Per-action-bar mouse disable for Action Bar 4."
    })

    CreateCheckboxInSection(actionBarsHeader, actionBarsIsExpanded, {
        variable = "actionBars_disable_mouse_MultiBarRightButton",
        name = "Action Bar 5",
        getValue = function() return ns.db.profile.actionBars_disable_mouse_MultiBarRightButton end,
        setValue = function(v)
            ns.db.profile.actionBars_disable_mouse_MultiBarRightButton = v
            if ns.db.profile.actionBars_disableMouseOnActionBars then
                if v then ns.ActionBars.disableMouseOnBar("MultiBarRightButton") else ns.ActionBars.enableMouseOnBar("MultiBarRightButton") end
            end
        end,
        desc = "Per-action-bar mouse disable for Action Bar 5."
    })

    CreateCheckboxInSection(actionBarsHeader, actionBarsIsExpanded, {
        variable = "actionBars_disable_mouse_MultiBar5Button",
        name = "Action Bar 6",
        getValue = function() return ns.db.profile.actionBars_disable_mouse_MultiBar5Button end,
        setValue = function(v)
            ns.db.profile.actionBars_disable_mouse_MultiBar5Button = v
            if ns.db.profile.actionBars_disableMouseOnActionBars then
                if v then ns.ActionBars.disableMouseOnBar("MultiBar5Button") else ns.ActionBars.enableMouseOnBar("MultiBar5Button") end
            end
        end,
        desc = "Per-action-bar mouse disable for Action Bar 6."
    })

    CreateCheckboxInSection(actionBarsHeader, actionBarsIsExpanded, {
        variable = "actionBars_disable_mouse_MultiBar6Button",
        name = "Action Bar 7",
        getValue = function() return ns.db.profile.actionBars_disable_mouse_MultiBar6Button end,
        setValue = function(v)
            ns.db.profile.actionBars_disable_mouse_MultiBar6Button = v
            if ns.db.profile.actionBars_disableMouseOnActionBars then
                if v then ns.ActionBars.disableMouseOnBar("MultiBar6Button") else ns.ActionBars.enableMouseOnBar("MultiBar6Button") end
            end
        end,
        desc = "Per-action-bar mouse disable for Action Bar 7."
    })

    CreateCheckboxInSection(actionBarsHeader, actionBarsIsExpanded, {
        variable = "actionBars_disable_mouse_MultiBar7Button",
        name = "Action Bar 8",
        getValue = function() return ns.db.profile.actionBars_disable_mouse_MultiBar7Button end,
        setValue = function(v)
            ns.db.profile.actionBars_disable_mouse_MultiBar7Button = v
            if ns.db.profile.actionBars_disableMouseOnActionBars then
                if v then ns.ActionBars.disableMouseOnBar("MultiBar7Button") else ns.ActionBars.enableMouseOnBar("MultiBar7Button") end
            end
        end,
        desc = "Per-action-bar mouse disable for Action Bar 8."
    })

    CreateCheckboxInSection(actionBarsHeader, actionBarsIsExpanded, {
        variable = "actionBars_disableMouseOnExtraActionBar",
        name = "Make Art around ExtraActionBar Click-Through",
        getValue = function() return ns.db.profile.actionBars_disableMouseOnExtraActionBar end,
        setValue = function(v) ns.db.profile.actionBars_disableMouseOnExtraActionBar = v end,
        desc = "Disable clicks on the art around ExtraActionBar (button itself remains clickable)."
    })

    -------------------------------------------------
    -- Cooldown Manager section + its checkboxes
    -------------------------------------------------
    if not ns.isMidnight then
        local cooldownHeader, cooldownIsExpanded = MakeExpandableSection(layout, "Cooldown Manager")
        
        CreateCheckboxInSection(cooldownHeader, cooldownIsExpanded, {
            variable = "cooldownManager_centerBuffIcons",
            name = "Center Buff Icons |cffff0000(not working in Midnight)",
            getValue = function() return ns.db.profile.cooldownManager_centerBuffIcons end,
            setValu0e = function(v) ns.db.profile.cool0downManager_centerBuffIcons = v end,
            desc = "Dynamically center the Buff Icon Cooldown Viewer Icons."
        })
    end


    -------------------------------------------------
    -- Blizzard UI Tweaks section + its checkboxes & sliders
    -------------------------------------------------
    local blizzUIHeader, blizzUIIsExpanded = MakeExpandableSection(layout, "Blizzard UI Tweaks")

    CreateCheckboxInSection(blizzUIHeader, blizzUIIsExpanded, {
        variable = "blizzUI_hideBagsFrames",
        name = "Hide Some Blizzard Frames",
        getValue = function() return ns.db.profile.blizzUI_hideBagsFrames end,
        setValue = function(v)
            ns.db.profile.blizzUI_hideBagsFrames = v
            if v and ns.UI and ns.UI.hideBlizzardBagAndReagentFrames then
                ns.UI.hideBlizzardBagAndReagentFrames()
            end
        end,
        desc = "Hide: Bag, Reagent Bag."
    })

    CreateCheckboxInSection(blizzUIHeader, blizzUIIsExpanded, {
        variable = "blizzUI_hideScreenshotText",
        name = "Hide Screenshot Text",
        getValue = function() return ns.db.profile.blizzUI_hideScreenshotText end,
        setValue = function(v) ns.db.profile.blizzUI_hideScreenshotText = v end,
        desc = "Remove screenshot text from the middle of the screen."
    })

    CreateCheckboxInSection(blizzUIHeader, blizzUIIsExpanded, {
        variable = "blizzUI_changeFriendlyNamesFont",
        name = "Friendly Names Font",
        getValue = function() return ns.db.profile.blizzUI_changeFriendlyNamesFont end,
        setValue = function(v) ns.db.profile.blizzUI_changeFriendlyNamesFont = v end,
        desc = "Add outline for friendly names."
    })

    CreateCheckboxInSection(blizzUIHeader, blizzUIIsExpanded, {
        variable = "blizzUI_chatTooltipOnChatLinks",
        name = "Chat Tooltips on Chat Links",
        getValue = function() return ns.db.profile.blizzUI_chatTooltipOnChatLinks end,
        setValue = function(v) ns.db.profile.blizzUI_chatTooltipOnChatLinks = v end,
        desc = "Show item/spell/achievement tooltips when hovering over links in chat."
    })

    CreateCheckboxInSection(blizzUIHeader, blizzUIIsExpanded, {
        variable = "blizzUI_addCastTimeTextOutline",
        name = "Cast Bar Timer",
        getValue = function() return ns.db.profile.blizzUI_addCastTimeTextOutline end,
        setValue = function(v) ns.db.profile.blizzUI_addCastTimeTextOutline = v end,
        desc = "Add outline to player cast bar time text to make it more visible."
    })

    CreateCheckboxInSection(blizzUIHeader, blizzUIIsExpanded, {
        variable = "blizzUI_altPowerBarText",
        name = "Alt Power Bar Text",
        getValue = function() return ns.db.profile.blizzUI_altPowerBarText end,
        setValue = function(v) ns.db.profile.blizzUI_altPowerBarText = v end,
        desc = "Always show Encounter Bar / Extra Power Bar numbers with better visibility."
    })

    CreateCheckboxInSection(blizzUIHeader, blizzUIIsExpanded, {
        variable = "blizzUI_enchanceUIErrorFrame",
        name = "Objective/Error Text Bigger",
        getValue = function() return ns.db.profile.blizzUI_enchanceUIErrorFrame end,
        setValue = function(v) ns.db.profile.blizzUI_enchanceUIErrorFrame = v end,
        desc = "Enlarge objective completed texts and UI error texts."
    })

    CreateCheckboxInSection(blizzUIHeader, blizzUIIsExpanded, {
        variable = "blizzUI_cleanupObjectiveTracker",
        name = "Clean up Objective Tracker",
        getValue = function() return ns.db.profile.blizzUI_cleanupObjectiveTracker end,
        setValue = function(v)
            ns.db.profile.blizzUI_cleanupObjectiveTracker = v
            if v and ns.UI and ns.UI.cleanupObjectiveTracker then
                ns.UI.cleanupObjectiveTracker()
            end
        end,
        desc = "Remove objective tracker header and background."
    })

    CreateCheckboxInSection(blizzUIHeader, blizzUIIsExpanded, {
        variable = "blizzUI_resizeBlizzardObjectiveTracker",
        name = "Scale Blizzard tracker frame",
        getValue = function() return ns.db.profile.blizzUI_resizeBlizzardObjectiveTracker end,
        setValue = function(v)
            ns.db.profile.blizzUI_resizeBlizzardObjectiveTracker = v
            if ns.UI and ns.UI.resizeBlizzardObjectiveTracker then
                if v then
                    ns.UI.resizeBlizzardObjectiveTracker(ns.db.profile.blizzUI_resizeBlizzardObjectiveTrackerRange or 1)
                else
                    ns.UI.resizeBlizzardObjectiveTracker(1)
                end
            end
        end,
        desc = "Enable scaling of the Blizzard objective tracker frame."
    })

    CreateSliderInSection(
        blizzUIHeader,
        blizzUIIsExpanded,
        "Tracker Frame Scale",
        "blizzUI_resizeBlizzardObjectiveTrackerRange",
        0.2, 3.0, 0.01,
        function()
            local v = ns.db.profile.blizzUI_resizeBlizzardObjectiveTrackerRange or 1
            return math.floor(v * 100) / 100
        end,
        function(v)
            v = math.floor(v * 100) / 100
            ns.db.profile.blizzUI_resizeBlizzardObjectiveTrackerRange = v
            if ns.db.profile.blizzUI_resizeBlizzardObjectiveTracker and ns.UI and ns.UI.resizeBlizzardObjectiveTracker then
                ns.UI.resizeBlizzardObjectiveTracker(v)
            end
        end,
        "Adjust the scale of the Blizzard objective tracker frame.",
         "%.2f"
    )

    CreateCheckboxInSection(blizzUIHeader, blizzUIIsExpanded, {
        variable = "blizzUI_expandFriendListHeight",
        name = "Friend List Resize height",
        getValue = function() return ns.db.profile.blizzUI_expandFriendListHeight end,
        setValue = function(v)
            ns.db.profile.blizzUI_expandFriendListHeight = v
            if v and ns.UI and ns.UI.expandFriendListHeight and ns.db.profile.blizzUI_expandFriendListHeightRange then
                ns.UI.expandFriendListHeight(ns.db.profile.blizzUI_expandFriendListHeightRange)
            end
        end,
        desc = "Resize friend list UI height."
    })

    CreateSliderInSection(
        blizzUIHeader,
        blizzUIIsExpanded,
        "Friend List Height",
        "blizzUI_expandFriendListHeightRange",
        400, 900, 10,
        function()
            return ns.db.profile.blizzUI_expandFriendListHeightRange or 600
        end,
        function(v)
            
            v = math.floor(v/10)*10
            ns.db.profile.blizzUI_expandFriendListHeightRange = v
            if ns.db.profile.blizzUI_expandFriendListHeight and ns.UI and ns.UI.expandFriendListHeight then
                ns.UI.expandFriendListHeight(v)
            end
        end,
        "Adjust the height of the friends list frame."
    )

    -------------------------------------------------
    -- Wildu UI Enhancements section + its checkboxes
    -------------------------------------------------
    local wilduUIHeader, wilduUIIsExpanded = MakeExpandableSection(layout, "Wildu UI Enhancements")

    CreateCheckboxInSection(wilduUIHeader, wilduUIIsExpanded, {
        variable = "wilduUI_targetRangeFrame",
        name = "Target Range Frame",
        getValue = function() return ns.db.profile.wilduUI_targetRangeFrame end,
        setValue = function(v)
            ns.db.profile.wilduUI_targetRangeFrame = v
            ns.WilduUI.InitializeRangeFrame()
        end,
        desc = "Displays range to target."
    })

    CreateCheckboxInSection(wilduUIHeader, wilduUIIsExpanded, {
        variable = "wilduUI_mountableArea",
        name = "Mountable Area Indicator",
        getValue = function() return ns.db.profile.wilduUI_mountableArea end,
        setValue = function(v)
            ns.db.profile.wilduUI_mountableArea = v
            ns.WilduUI.InitializeMountableAreaIndicator()
        end,
        desc = "Displays an indicator showing if you can mount in the current area."
    })

    CreateCheckboxInSection(wilduUIHeader, wilduUIIsExpanded, {
        variable = "wilduUI_crosshair",
        name = "Crosshair",
        getValue = function() return ns.db.profile.wilduUI_crosshair end,
        setValue = function(v)
            ns.db.profile.wilduUI_crosshair = v
            ns.WilduUI.InitializeCrosshair()
        end,
        desc = "Show a simple class-colored crosshair in the center of the screen."
    })

    CreateCheckboxInSection(wilduUIHeader, wilduUIIsExpanded, {
        variable = "wilduUI_playerCombat",
        name = "Player in Combat Indicator",
        getValue = function() return ns.db.profile.wilduUI_playerCombat end,
        setValue = function(v)
            ns.db.profile.wilduUI_playerCombat = v
            ns.WilduUI.InitializePlayerCombatIndicator()
        end,
        desc = "Show an icon when the player is in combat."
    })

    CreateCheckboxInSection(wilduUIHeader, wilduUIIsExpanded, {
        variable = "wilduUI_targetCombat",
        name = "Target in Combat Indicator",
        getValue = function() return ns.db.profile.wilduUI_targetCombat end,
        setValue = function(v)
            ns.db.profile.wilduUI_targetCombat = v
            ns.WilduUI.InitializeTargetCombatIndicator()
        end,
        desc = "Show an icon when your target is in combat."
    })

    -------------------------------------------------
    -- Settings + CVars section
    -------------------------------------------------
    local cvarsHeader, cvarsIsExpanded = MakeExpandableSection(layout, "Settings + CVars")

    CreateDropdownInSection(
        cvarsHeader,
        cvarsIsExpanded,
        "On login UI scaling",
        "general_defaultScaling",
        {
            NoScaling = "No scaling",
            Scale1080p = "0.7111 for 1080p",
            Scale1440p = "0.5333 for 1440p",
        },
        {"NoScaling", "Scale1080p", "Scale1440p"},
        function()
            return ns.db.profile.general_defaultScaling or "NoScaling"
        end,
        function(v)
            ns.db.profile.general_defaultScaling = v
            ReloadUI()
        end,
        "Apply a preset UI scale on login."
    )

    CreateDropdownInSection(
        cvarsHeader,
        cvarsIsExpanded,
        "Minimap Button on click",
        "general_minimapButtonOnClickAction",
        {
            Plumber = "Plumber Landing Page",
            Settings = "WilduTools Settings",
            Reload = "Reload UI",
        },
        {"Settings", "Plumber", "Reload"},
        function()
            return ns.db.profile.general_minimapButtonOnClickAction or "Settings"
        end,
        function(v)
            ns.db.profile.general_minimapButtonOnClickAction = v
        end,
        "What the minimap button does when clicked."
    )

    CreateDropdownInSection(
        cvarsHeader,
        cvarsIsExpanded,
        "Minimap Button on click + Shift",
        "general_minimapButtonOnClickShiftAction",
        {
            Plumber = "Plumber Landing Page",
            Settings = "WilduTools Settings",
            Reload = "Reload UI",
        },
        {"Settings", "Plumber", "Reload"},
        function()
            return ns.db.profile.general_minimapButtonOnClickShiftAction or "Settings"
        end,
        function(v)
            ns.db.profile.general_minimapButtonOnClickShiftAction = v
        end,
        "What the minimap button does when clicked while holding Shift."
    )

    -- WilduSettings:CollapseAllSections()
end

---@class CheckboxData
---@field variable string Unique variable name
---@field name string Display label
---@field defaultValue boolean | number | string Initial value
---@field getValue fun(variable: string, variableType: string): any Getter callback
---@field setValue fun(variable: string, variableType: string, value: any) Setter callback
---@field desc string Description of the function
---@field previewImage string Name of preview image file


---@param cat string Settings category identifier
---@param cbData CheckboxData Checkbox configuration object
function WilduSettings.SettingsCreateCheckbox(categoryTbl, cbData)

    if cbData.previewImage then
        ns.WilduSettings.settingPreview[cbData.variable] = { text = cbData.desc, image = cbData.previewImage }
    end
    local setting = Settings.RegisterProxySetting(
        categoryTbl or ns.WilduSettings.SettingsLayout.rootCategory,
        cbData.variable,
        Settings.VarType.Boolean,
        cbData.name,
        cbData.defaultValue,
        cbData.getValue,
        cbData.setValue
    )
    local element = WilduSettings.WildCreateCheckbox(categoryTbl, setting, cbData.desc)

    if cbData.parent then
        element:SetParentInitializer(cbData.element, cbData.parentCheck)
    end

    return { setting = setting, element = element }
end

---@param moduleName string Module identifier
---@param newThings boolean add "New Things inside" test
function WilduSettings:formatModuleName(moduleName, newThings)
    return newThings
        and moduleName .. "    |cffffffff!New|r |cff008945Wildu|r|cff8ccd00Tools|r |cffffffffinisde!|r"
        or moduleName
end


function WilduSettings:ExpandAllSections()
    if not ns.WilduSettings.expandableSectionInitializers then return end

    for _, header in ipairs(ns.WilduSettings.expandableSectionInitializers) do
        if header.data then
            header.data.expanded = true
        end
    end

    if SettingsInbound and SettingsInbound.RepairDisplay then
        SettingsInbound.RepairDisplay()
    end
end

function WilduSettings:CollapseAllSections()
    if not ns.WilduSettings.expandableSectionInitializers then return end

    for _, header in ipairs(ns.WilduSettings.expandableSectionInitializers) do
        if header.data then
            header.data.expanded = false
        end
    end

    if SettingsInbound and SettingsInbound.RepairDisplay then
        SettingsInbound.RepairDisplay()
    end
end

local f = SettingsPanel and SettingsPanel.SearchBox
if not f then
    ns.DEBUG.log("WARN", "Settings Panel not found")
    return
end

f:HookScript("OnTextChanged", function(self, userInput)
    local text = self:GetText()
    if text and text ~= "" then 
        WilduSettings:ExpandAllSections()
    end
end)