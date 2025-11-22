local _, ns = ...

WilduDefaultTooltipMixin = {};

function WilduDefaultTooltipMixin:InitDefaultTooltipScriptHandlers()
	self:SetScript("OnEnter", self.OnEnter);
	self:SetScript("OnLeave", self.OnLeave);
end

function WilduDefaultTooltipMixin:OnLoad()
	self:SetDefaultTooltipAnchors();
	self:InitDefaultTooltipScriptHandlers();
end

function WilduDefaultTooltipMixin:SetDefaultTooltipAnchors()
	self.tooltipAnchorParent = nil;
	self.tooltipAnchoring = "ANCHOR_RIGHT";
	self.tooltipXOffset = -10;
	self.tooltipYOffset = 0;
end

function WilduDefaultTooltipMixin:SetTooltipFunc(tooltipFunc)
	self.tooltipFunc = tooltipFunc;
end

function WilduDefaultTooltipMixin:SetTooltipHideFunc(tooltipHideFunc)
	self.tooltipHideFunc = tooltipHideFunc;
end

function WilduDefaultTooltipMixin:OnEnter()
	if self.tooltipAnchorParent then
		SettingsTooltip:SetOwner(self.tooltipAnchorParent, self.tooltipAnchoring, self.tooltipXOffset, self.tooltipYOffset);
	else
		SettingsTooltip:SetOwner(self, self.tooltipAnchoring, self.tooltipXOffset, self.tooltipYOffset);
	end
    

	if self.tooltipFunc then
		self.tooltipFunc();
	elseif self.tooltipText then
		SettingsTooltip:SetText(self.tooltipText, nil, nil, nil, nil, true);
	end
    if not self.tooltipHideFunc then
	    SettingsTooltip:Show();
    end

	if self.HoverBackground then
		self.HoverBackground:Show();
	end
end

function WilduDefaultTooltipMixin:OnLeave()
	SettingsTooltip:Hide();

    if self.tooltipHideFunc then
        self.tooltipHideFunc();
    end

    if self.HoverBackground then
		self.HoverBackground:Hide();
	end
end

function WilduDefaultTooltipMixin:SetCustomTooltipAnchoring(parent, anchoring, xOffset, yOffset)
	self.tooltipAnchorParent = parent;
	self.tooltipAnchoring = anchoring;
	self.tooltipXOffset = xOffset;
	self.tooltipYOffset = yOffset;
end

WilduSettingsListElementMixin = {};

function WilduSettingsListElementMixin:OnLoad()
	self.cbrHandles = Settings.CreateCallbackHandleContainer();
end

function WilduSettingsListElementMixin:OnEnter()
    -- self.Tooltip:OnEnter()
end

function WilduSettingsListElementMixin:OnLeave()
    -- self.Tooltip:OnLeave()
end

function WilduSettingsListElementMixin:DisplayEnabled(enabled)
	local color = enabled and NORMAL_FONT_COLOR or GRAY_FONT_COLOR;
	self.Text:SetTextColor(color:GetRGB());
	self:DesaturateHierarchy(enabled and 0 or 1);
end

function WilduSettingsListElementMixin:GetIndent()
	local initializer = self:GetElementData();
	return initializer:GetIndent();
end

function WilduSettingsListElementMixin:SetTooltipFunc(tooltipFunc)
	WilduDefaultTooltipMixin.SetTooltipFunc(self.Tooltip, tooltipFunc);
end

function WilduSettingsListElementMixin:SetTooltipHideFunc(tooltipFunc)
	WilduDefaultTooltipMixin.SetTooltipHideFunc(self.Tooltip, tooltipFunc);
end

local function InitializeSettingTooltip(initializer)
	Settings.InitTooltip(initializer:GetName(), initializer:GetTooltip());
end

local function SetSettingPreview(initializer)
    ns.WilduSettings:SetVariableToPreview(initializer.data.setting.variable)
end

function WilduSettingsListElementMixin:Init(initializer)
    assert(self.cbrHandles:IsEmpty());
    self.data = initializer.data;

    local parentInitializer = initializer:GetParentInitializer();
    if parentInitializer then
        local setting = nil
        if parentInitializer.GetSetting then
            setting = parentInitializer:GetSetting()
        end
        if setting then
            self.cbrHandles:SetOnValueChangedCallback(
                setting:GetVariable(),
                self.OnParentSettingValueChanged,
                self
            );
        end
    end

    local font = initializer:IsParentInitializerInLayout() and "GameFontNormalSmall" or "GameFontNormal";
    self.Text:SetFontObject(font);
    self.Text:SetText(initializer:GetName());
    self.Text:SetPoint("TOPLEFT", self, "TOPLEFT", (self:GetIndent() + 57), 0);
    self.Text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -40, 0);

    if initializer.hideText then
        self.Text:Hide();
    end

    if self.data and self.data.setting and ns.WilduSettings.settingPreview[self.data.setting.variable] then 
        self:SetTooltipFunc(function()
            GenerateClosure(SetSettingPreview, initializer)();
            GenerateClosure(InitializeSettingTooltip, initializer)();
        end);
        self:SetTooltipHideFunc(function() ns.WilduSettings:SetVariableToPreview(nil) end)
    else
        self:SetTooltipFunc(GenerateClosure(InitializeSettingTooltip, initializer));
    end
  
    local newTagShown = nil
    if initializer.IsNewTagShown then
        newTagShown = initializer:IsNewTagShown()
    end
    self.NewFeature:SetShown(newTagShown);
    if newTagShown then
        initializer:MarkSettingAsSeen();
    end
end

function WilduSettingsListElementMixin:Release()
	self.cbrHandles:Unregister();
	self.data = nil;
end

function WilduSettingsListElementMixin:OnSettingValueChanged(setting, value)
end

function WilduSettingsListElementMixin:OnParentSettingValueChanged(setting, value)
	self:EvaluateState();
end

function WilduSettingsListElementMixin:EvaluateState()
	local initializer = self:GetElementData();
	self:SetShown(initializer:ShouldShow());
end

WilduSettingsControlMixin = CreateFromMixins(WilduSettingsListElementMixin);

function WilduSettingsControlMixin:OnLoad()
	WilduSettingsListElementMixin.OnLoad(self);
end

function WilduSettingsControlMixin:OnEnter()
    WilduSettingsListElementMixin.OnEnter(self);
end

function WilduSettingsControlMixin:OnLeave()
    WilduSettingsListElementMixin.OnLeave(self);
end

function WilduSettingsControlMixin:Init(initializer)
	WilduSettingsListElementMixin.Init(self, initializer);

    -- DEFENSIVE: Some initializers (e.g. section headers) have no setting.
    local setting = self:GetSetting();
    if not setting then
        return;
    end

	self.cbrHandles:SetOnValueChangedCallback(setting:GetVariable(), self.OnSettingValueChanged, self);

	local evaluateStateFrameEvents = initializer.GetEvaluateStateFrameEvents and initializer:GetEvaluateStateFrameEvents();
	if evaluateStateFrameEvents then
		for index, event in ipairs(evaluateStateFrameEvents) do
			self.cbrHandles:AddHandle(EventRegistry:RegisterFrameEventAndCallbackWithHandle(event, self.EvaluateState, self));
		end
	end
end

function WilduSettingsControlMixin:Release()
	WilduSettingsListElementMixin.Release(self);
end

function WilduSettingsControlMixin:GetSetting()
	return self.data and self.data.setting or nil;
end

function WilduSettingsControlMixin:SetValue(value)
	-- Implement in derived
end

function WilduSettingsControlMixin:OnSettingValueChanged(setting, value)
	self:SetValue(value);
end

function WilduSettingsControlMixin:IsEnabled()
	local initializer = self:GetElementData();
	local prereqs = initializer.GetModifyPredicates and initializer:GetModifyPredicates();
	if prereqs then
		for index, prereq in ipairs(prereqs) do
			if not prereq() then
				return false;
			end
		end
	end
	return true;
end

function WilduSettingsControlMixin:ShouldInterceptSetting(value)
	local initializer = self:GetElementData();
	local intercept = initializer.GetSettingIntercept and initializer:GetSettingIntercept();
	if intercept then
		local result = intercept(value);
		assert(result ~= nil);
		return result;
	end
	return false;
end

WilduSettingsCheckboxControlMixin = CreateFromMixins(WilduSettingsControlMixin);

function WilduSettingsCheckboxControlMixin:OnLoad()
	WilduSettingsControlMixin.OnLoad(self);

	self.Checkbox = CreateFrame("CheckButton", nil, self, "SettingsCheckboxTemplate");
	self.Checkbox:SetPoint("LEFT", self, "LEFT", 46, 0);
    self.Checkbox:SetScale(0.6)

	self.Tooltip:SetScript("OnMouseUp", function()
		if self.Checkbox:IsEnabled() then
			self.Checkbox:Click();
		end
	end);
end

function WilduSettingsCheckboxControlMixin:OnEnter()
    if self.data and self.data.setting and self.data.setting.variable then
        ns.WilduSettings:SetVariableToPreview(self.data.setting.variable)
    end
    WilduSettingsControlMixin.OnEnter(self)
end

function WilduSettingsCheckboxControlMixin:OnLeave()
    WilduSettingsControlMixin.OnLeave(self)
    ns.WilduSettings:SetVariableToPreview(nil)
end

function WilduSettingsCheckboxControlMixin:Init(initializer)
	WilduSettingsControlMixin.Init(self, initializer);

    local setting = self:GetSetting();
    if not setting then
        return;
    end

	local options = initializer.GetOptions and initializer:GetOptions() or nil;
	local initTooltip = Settings.CreateOptionsInitTooltip(setting, initializer:GetName(), initializer:GetTooltip(), options);

	self.Checkbox:Init(setting:GetValue(), initTooltip);
	
	self.cbrHandles:RegisterCallback(self.Checkbox, SettingsCheckboxMixin.Event.OnValueChanged, self.OnCheckboxValueChanged, self);

	self:EvaluateState();
end

function WilduSettingsCheckboxControlMixin:OnSettingValueChanged(setting, value)
	WilduSettingsControlMixin.OnSettingValueChanged(self, setting, value);

	self.Checkbox:SetChecked(value);
end

function WilduSettingsCheckboxControlMixin:OnCheckboxValueChanged(value)
	if self:ShouldInterceptSetting(value) then
		self.Checkbox:SetChecked(not value);
	else
		self:GetSetting():SetValue(value);
	end
end

function WilduSettingsCheckboxControlMixin:SetValue(value)
	self.Checkbox:SetChecked(value);
	if value then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	else 
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
	end
end

function WilduSettingsCheckboxControlMixin:EvaluateState()
	SettingsListElementMixin.EvaluateState(self);
	local enabled = WilduSettingsControlMixin.IsEnabled(self);

	local initializer = self:GetElementData();
	local options = initializer.GetOptions and initializer:GetOptions() or nil;
	if options then
		local optionData = type(options) == 'function' and options() or options;
		local value = self:GetSetting():GetValue();
		for index, option in ipairs(optionData) do
			if option.disabled and option.value ~= value then
				enabled = false;
			end
		end
	end

	self.Checkbox:SetEnabled(enabled);
	self:DisplayEnabled(enabled);
end

function WilduSettingsCheckboxControlMixin:Release()
	self.Checkbox:Release();
	WilduSettingsControlMixin.Release(self);
end


-------------------------------------------------
-- Expandable Section (collapsible header) support
-------------------------------------------------

-- This mirrors SettingsExpandableSectionMixin from Blizzard_SettingControls.lua
WilduSettingsExpandableSectionMixin = {};

function WilduSettingsExpandableSectionMixin:OnLoad()
	-- Expect a Button child with a Text fontstring like Blizzard's template
	self.Button:SetScript("OnClick", function(button, buttonName, down)
		local initializer = self:GetElementData();
		local data = initializer.data;
		data.expanded = not data.expanded;

		-- Let the initializer/layout recompute height; we just change visual state.
		self:OnExpandedChanged(data.expanded);
	end);
end

function WilduSettingsExpandableSectionMixin:OnExpandedChanged(expanded)
	-- Implement your visual feedback here if you add an arrow/plus-minus texture.
	-- For now we just set a simple highlight state on the button text.
	if expanded then
		self.Button.Text:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB());
	else
		self.Button.Text:SetTextColor(NORMAL_FONT_COLOR:GetRGB());
	end
end

function WilduSettingsExpandableSectionMixin:Init(initializer)
	local data = initializer.data;
	self.Button.Text:SetText(data.name or "");
	-- Ensure initial visual state matches expanded flag (default collapsed = false)
	self:OnExpandedChanged(data.expanded == true);
end

-- Factory for section initializer, like CreateSettingsExpandableSectionInitializer
function ns.WilduSettings_CreateExpandableSectionInitializer(name)
	-- Reuse Blizzard's SettingsExpandableSectionInitializer type:
	--   local initializer = CreateFromMixins(SettingsExpandableSectionInitializer);
	--   initializer:Init("SettingsExpandableSectionTemplate");
	--   initializer.data = { name = name };
	-- See Blizzard_SettingControls.lua
	local initializer = CreateFromMixins(SettingsExpandableSectionInitializer);
	initializer:Init("SettingsExpandableSectionTemplate");
	initializer.data = { name = name, expanded = false };
	return initializer;
end


-------------------------------------------------
-- Expandable Section (collapsible header) support
-------------------------------------------------

WilduSettingsExpandableSectionInitializer = CreateFromMixins(ScrollBoxFactoryInitializerMixin, SettingsSearchableElementMixin)

function WilduSettingsExpandableSectionInitializer:Init(frameTemplate, name)
    ScrollBoxFactoryInitializerMixin.Init(self, frameTemplate)
    self.data = {
        name = name,
        expanded = true,
        extent = 24,
    }
end

function WilduSettingsExpandableSectionInitializer:GetExtent()
    return self.data.extent
end

function WilduSettingsExpandableSectionInitializer:GetName()
    return self.data.name
end

function WilduSettingsExpandableSectionInitializer:IsExpanded()
    return self.data.expanded
end

function ns.WilduSettings_CreateExpandableSectionInitializer(name)
    local initializer = CreateFromMixins(WilduSettingsExpandableSectionInitializer)
    initializer:Init("WilduSettings_ExpandableSectionTemplate", name)
    return initializer
end

WilduSettingsExpandableSectionMixin = {}

function WilduSettingsExpandableSectionMixin:OnLoad()
    self.Button:SetScript("OnClick", function()
        local initializer = self:GetElementData()
        local data = initializer.data
        data.expanded = not data.expanded

        self:OnExpandedChanged(data.expanded)
        SettingsPanel:FullRefreshIfVisible()
    end)
end

function WilduSettingsExpandableSectionMixin:OnExpandedChanged(expanded)
    if expanded then
        self.Button.Text:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
    else
        self.Button.Text:SetTextColor(DISABLED_FONT_COLOR:GetRGB())
    end
end

function WilduSettingsExpandableSectionMixin:Init(initializer)
    local data = initializer.data
    self.Button.Text:SetText(data.name or "")
    self:OnExpandedChanged(data.expanded)
end