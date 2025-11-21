local _, ns = ...
local WilduSettings = {}
ns.WilduSettings = WilduSettings

WilduSettings.settingPreview = {}

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
        PreviewFrame.text:SetText(WilduSettings.settingPreview[variable].text)
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
    local category, layout = Settings.RegisterVerticalLayoutCategory("WilduTools2")

    Settings.RegisterAddOnCategory(category)
    ns.WilduSettings.SettingsLayout.rootCategory = category
    ns.WilduSettings.SettingsLayout.rootLayout = layout
    -- local baseHeader = Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", "Base header")
    -- Settings.RegisterInitializer(ns.WilduSettings.SettingsLayout.rootCategory, baseHeader)

    WilduSettings.SettingsCreateCheckbox(ns.WilduSettings.SettingsLayout.rootCategory, {
        variable = "free_right_click_move",
        name = "Right Mouse Button Camera Unlock",
        defaultValue = false,
        getValue = function() return test end,
        setValue = function(v) print("set:", v); test = v end,
        desc = "Allows free camera movement while holding and dragging the right mouse button over UI frames such as raid frames. Right-click without dragging still opens menus normally. Cursor locks during mouselook and releases when RMB is lifted."
    })
    WilduSettings.SettingsCreateCheckbox(ns.WilduSettings.SettingsLayout.rootCategory, {
        variable = "free_right_click_move1",
        name = "Second setting",
        defaultValue = false,
        getValue = function() return test end,
        setValue = function(v) print("set:", v); test = v end,
        desc = "Second settings"
    })
    WilduSettings.SettingsCreateCheckbox(ns.WilduSettings.SettingsLayout.rootCategory, {
        variable = "free_right_click_move2",
        name = "Right Mouse Button Camera Unlock 2",
        defaultValue = false,
        getValue = function() return test end,
        setValue = function(v) print("set:", v); test = v end,
        desc = "Allows free camera movement while holding and dragging the right mouse button over UI frames such as raid frames. Right-click without dragging still opens menus normally. Cursor locks during mouselook and releases when RMB is lifted.. Allows free camera movement while holding and dragging the right mouse button over UI frames such as raid frames. Right-click without dragging still opens menus normally. Cursor locks during mouselook and releases when RMB is lifted."
    })
end

---@class CheckboxData
---@field variable string Unique variable name
---@field name string Display label
---@field defaultValue boolean | number | string Initial value
---@field getValue fun(variable: string, variableType: string): any Getter callback
---@field setValue fun(variable: string, variableType: string, value: any) Setter callback


---@param cat string Settings category identifier
---@param cbData CheckboxData Checkbox configuration object
function WilduSettings.SettingsCreateCheckbox(categoryTbl, cbData)
    -- Settings.RegisterProxySetting(categoryTbl, variable, variableType, name, defaultValue, getValue, setValue)
    
    ns.WilduSettings.settingPreview[cbData.variable] = { text = cbData.desc }
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
    

    if cbData.parent then element:SetParentInitializer(cbData.element, cbData.parentCheck) end
    return { setting = setting, element = element }
end

