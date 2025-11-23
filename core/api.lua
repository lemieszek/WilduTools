local _, ns = ...

--- WilduTools API Module
--- Provides core gameplay and utility functions used across the addon
local API = {}
ns.API = API

local LibRangeCheck = LibStub("LibRangeCheck-3.0-WildFork")

local DEBUG = ns.DEBUG


-- ============================================================================
-- UI HELPER FUNCTIONS
-- ============================================================================

---Open the Click Cast Binding UI
---Loads and toggles the Blizzard click binding interface for click-casting
function API:OpenClickCastBinding()
    C_AddOns.LoadAddOn('Blizzard_ClickBindingUI')
    ClickBindingFrame_Toggle()
end

---Open the Quick Keybind Mode UI
---Shows the Blizzard quick keybind panel for binding actions
function API:OpenQuickKeybindMode()
    ShowUIPanel(QuickKeybindFrame)
end

-- ============================================================================
-- TIMER & DELAY FUNCTIONS
-- ============================================================================

local waitTable = {}
local waitFrame = nil

---Schedule a function to be called after a delay
---Alternative to C_Timer.After that doesn't require secure context
---@param delay number Delay in seconds before calling the function
---@param func function Function to call after delay
---@param ... any Arguments to pass to the function
---@return boolean success True if scheduled successfully, false if invalid parameters
function API:wait(delay, func, ...)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if(waitFrame == nil) then
    waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
    waitFrame:SetScript("onUpdate",function (self,elapse)
      local count = #waitTable;
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(waitTable,{delay,func,{...}});
  return true;
end

---Create and show a Blizzard-style context menu
---@param ownerRegion Frame The frame that owns this menu
---@param schematic table Menu structure definition with tag and objects array
---@param contextData? table Optional context data to pass to menu handlers
function API.ShowBlizzardMenu(ownerRegion, schematic, contextData)
    contextData = contextData or {};

    local menu = MenuUtil.CreateContextMenu(ownerRegion, function(ownerRegion, rootDescription)
        rootDescription:SetTag(schematic.tag, contextData);

        for _, info in ipairs(schematic.objects) do
            local elementDescription;
            if info.type == "Title" then
                elementDescription = rootDescription:CreateTitle();
                elementDescription:AddInitializer(function(f, description, menu)
                    f.fontString:SetText(info.name);
                end);
            elseif info.type == "Divider" then
                elementDescription = rootDescription:CreateDivider();
            elseif info.type == "Spacer" then
                elementDescription = rootDescription:CreateSpacer();
            elseif info.type == "Button" then
                elementDescription = rootDescription:CreateButton(info.name, info.OnClick);
            elseif info.type == "Checkbox" then
                elementDescription = rootDescription:CreateCheckbox(info.name, info.IsSelected, info.ToggleSelected);
            elseif info.type == "Submenu" then
                elementDescription = rootDescription:CreateButton(L["Pin Size"]);

                local function IsSelected(index)
                    --Override
                    return false
                end

                local response = info.response and MenuResponse and MenuResponse[info.response] or 2;

                local function SetSelected(index)
                    info.SetSelected(index);
                    return response
                end

                for index, text in ipairs(info.radios) do
                    elementDescription:CreateRadio(text, info.IsSelected or IsSelected, SetSelected, index);
                end
            elseif info.type == "Radio" then
                local function IsSelected(index)
                    --Override
                    return false
                end

                local response = info.response and MenuResponse and MenuResponse[info.response] or 2;

                local function SetSelected(index)
                    info.SetSelected(index);
                    return response
                end

                for index, text in ipairs(info.radios) do
                    elementDescription = rootDescription:CreateRadio(text, info.IsSelected or IsSelected, SetSelected, index);
                end
            end

            if info.IsEnabledFunc then
                local enabled = info.IsEnabledFunc();
                elementDescription:SetEnabled(enabled);
            end

            if info.tooltip then
                elementDescription:SetTooltip(function(tooltip, elementDescription)
                    --GameTooltip_AddInstructionLine(tooltip, "Test Tooltip Instruction");
                    --GameTooltip_AddErrorLine(tooltip, "Test Tooltip Colored Line");
                    if info.DynamicTooltipFunc then
                        local text, r, g, b = info.DynamicTooltipFunc();
                        if text then
                            GameTooltip_SetTitle(tooltip, MenuUtil.GetElementText(elementDescription));
                            tooltip:AddLine(text, r, g, b, true);
                        end
                    else
                        GameTooltip_SetTitle(tooltip, MenuUtil.GetElementText(elementDescription));
                        GameTooltip_AddNormalLine(tooltip, info.tooltip);
                    end
                end);
            end

            if info.rightText or info.rightTexture then
                local rightText;
                if type(info.rightText) == "function" then
                    rightText = info.rightText();
                else
                    rightText = info.rightText;
                end
                elementDescription:AddInitializer(function(button, description, menu)
                    local rightWidth = 0;

                    if info.rightTexture then
                        local iconSize = 18;
                        local rightTexture = button:AttachTexture();
                        rightTexture:SetSize(iconSize, iconSize);
                        rightTexture:SetPoint("RIGHT");
                        rightTexture:SetTexture(info.rightTexture);
                        rightWidth = rightWidth + iconSize;
                        rightWidth = 20;
                    end

                    local fontString = button.fontString;
                    fontString:SetTextColor(NORMAL_FONT_COLOR:GetRGB());

                    local fontString2;
                    if info.rightText then
                        fontString2 = button:AttachFontString();
                        fontString2:SetHeight(20);
                        fontString2:SetPoint("RIGHT", button, "RIGHT", 0, 0);
                        fontString2:SetJustifyH("RIGHT");
                        fontString2:SetText(rightText);
                        fontString2:SetTextColor(0.5, 0.5, 0.5);
                        rightWidth = fontString2:GetWrappedWidth() + 20;
                    end

                    local width = fontString:GetWrappedWidth() + rightWidth;
                    local height = 20;

                    return width, height;
                end);
            end
        end
    end);

    if schematic.onMenuClosedCallback then
        menu:SetClosedCallback(schematic.onMenuClosedCallback);
    end

    return menu
end

---Get minimum and maximum range for a target
---@param unit string UnitID to check range for (e.g., "target")
---@param checkVisible boolean  
---Get the range to a unit
---Uses LibRangeCheck to determine distance based on spell/item ranges
---@param unit string UnitID (e.g., "target", "player", "focus")
---@return number? minRange Minimum range in yards, or nil if out of range
---@return number? maxRange Maximum range in yards, or nil if exact range unknown
function API:GetRange(unit)
  return LibRangeCheck:GetRange(unit, true);
end



-- ============================================================================
-- PLAYER STATE FUNCTIONS
-- ============================================================================

---Check if player can mount in current state
---@return boolean canMount
function API:CanPlayerMount()
  if InCombatLockdown() then
    return false
  end
  
  if IsFlying() or IsMounted() then
    return false
  end
  
  local _, class = UnitClass("player")
  if class == "DRUID" then
    return C_Spell.IsSpellUsable(150544) -- Druid flying form
  end
  
  return C_Spell.IsSpellUsable(23214) -- General mount ability
end

---Check if player is in stealth or invisible state
---@return boolean IsStealthed
function API:IsPlayerStealthed()
  return IsStealthed()
end


local RANGE_COLORS = {
    MELEE = {r = 0.0, g = 1.0, b = 0.0},        -- Green for melee
    CLOSE = {r = 1.0, g = 1.0, b = 0.0},        -- Yellow for 20-30 yards
    MEDIUM = {r = 1.0, g = 0.65, b = 0.0},      -- Orange for middle
    MEDIUM_FAR = {r = 1.0, g = 0.60, b = 0.0},      -- Orange for middle
    FAR = {r = 1.0, g = 0.55, b = 0.0},         -- Dark orange for approaching out of range
    OUT_OF_RANGE = {r = 1.0, g = 0.0, b = 0.0}, -- Red for out of range
}

-- Class-specific max ranges (from the spell data analysis)
local CLASS_MAX_RANGES = {
    DEATHKNIGHT = 40,
    DEMONHUNTER = 30,
    DRUID = 40,
    EVOKER = 40,
    HUNTER = 40,
    MAGE = 40,
    MONK = 40,
    PALADIN = 40,
    PRIEST = 40,
    ROGUE = 30,
    SHAMAN = 40,
    WARLOCK = 40,
    WARRIOR = 30,
}

local function GetRangeColor(range, playerClass)
    -- Default to 40 yards if class unknown
    local maxRange = CLASS_MAX_RANGES[playerClass] or 40
    
    if range <= 5 then
        return RANGE_COLORS.MELEE
    end
    
    if range <= 10 then
        return RANGE_COLORS.CLOSE
    end
    
    if range <= maxRange -15 then
        return RANGE_COLORS.MEDIUM
    end
    if range <= maxRange -7 then
        return RANGE_COLORS.MEDIUM_FAR
    end
    
    if range <= maxRange  then
        return RANGE_COLORS.FAR
    end
    
    -- Out of range (maxRange-4 and beyond) - Red
    return RANGE_COLORS.OUT_OF_RANGE
end

---Colorize range text based on distance
---Colors range text appropriately for the player's class abilities
---@param rangeText string The range text to colorize (e.g., "10 - 20")
---@param range number The range value in yards
---@param playerClass? string Player's class (unused parameter, can be removed)
---@return string colorizedText The range text wrapped in color codes
function API:ColorizeRange(rangeText, range, playerClass)
    local color = GetRangeColor(range, playerClass)
    local hex = string.format("%02x%02x%02x", 
        math.floor(color.r * 255), 
        math.floor(color.g * 255), 
        math.floor(color.b * 255))
    
    return string.format("|cff%s%s|r", hex, rangeText)
end
    local SliceFrameMixin = {};

    --Use the new Texture Slicing   (https://warcraft.wiki.gg/wiki/Patch_10.2.0/API_changes)
    --The SlicedTexture is pixel-perfect but doesn't scale with parent, so we shelve this and observer Blizzard's implementation
    local function NiceSlice_CreatePieces(frame)
        if not frame.NineSlice then
            frame.NineSlice = frame:CreateTexture(nil, "BACKGROUND");
            --frame.NineSlice:SetTextureSliceMode(0); --Enum.UITextureSliceMode, 0 Stretched(Default)  1 Tiled
            --DisableSharpening(frame.NineSlice);
            frame.TestBG = frame:CreateTexture(nil, "OVERLAY");
            frame.TestBG:SetAllPoints(true);
            frame.TestBG:SetColorTexture(1, 0, 0, 0.5);
        end
    end

    local function NiceSlice_SetCornerSize(frame, a)
        frame.NineSlice:SetTextureSliceMargins(32, 32, 32, 32);
        local offset = 0;
        frame.NineSlice:ClearAllPoints();
        frame.NineSlice:SetPoint("TOPLEFT", frame, "TOPLEFT", -offset, offset);
        frame.NineSlice:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", offset, -offset);
    end

    local function NiceSlice_SetTexture(frame, texture)
        frame.NineSlice:SetTexture(texture);
    end

    function API.CreateThreeSliceTextures(parent, layer, sideWidth, sideHeight, sideOffset, file, disableSharpenging)
        local slices = {};
        slices[1] = parent:CreateTexture(nil, layer);
        slices[2] = parent:CreateTexture(nil, layer);
        slices[3] = parent:CreateTexture(nil, layer);
        slices[1]:SetPoint("LEFT", parent, "LEFT", -sideOffset, 0);
        slices[3]:SetPoint("RIGHT", parent, "RIGHT", sideOffset, 0);
        slices[2]:SetPoint("TOPLEFT", slices[1], "TOPRIGHT", 0, 0);
        slices[2]:SetPoint("BOTTOMRIGHT", slices[3], "BOTTOMLEFT", 0, 0);

        if sideWidth and sideHeight then
            slices[1]:SetSize(sideWidth, sideHeight);
            slices[3]:SetSize(sideWidth, sideHeight);
        end

        if file then
            slices[1]:SetTexture(file);
            slices[2]:SetTexture(file);
            slices[3]:SetTexture(file);
        end

        if disableSharpenging then
            DisableSharpening(slices[1]);
            DisableSharpening(slices[2]);
            DisableSharpening(slices[3]);
        end

        return slices
    end

    function SliceFrameMixin:CreatePieces(n)
        --[[
        if n == 9 then
            NiceSlice_CreatePieces(self);
            NiceSlice_SetCornerSize(self, 16);
            return
        end
        --]]

        if self.pieces then return end;
        self.pieces = {};
        self.numSlices = n;

        -- 1 2 3
        -- 4 5 6
        -- 7 8 9

        for i = 1, n do
            self.pieces[i] = self:CreateTexture(nil, "BORDER");
            -- DisableSharpening(self.pieces[i]);
            self.pieces[i]:ClearAllPoints();
        end

        self:SetCornerSize(16);

        if n == 3 then
            self.pieces[1]:SetPoint("CENTER", self, "LEFT", 0, 0);
            self.pieces[3]:SetPoint("CENTER", self, "RIGHT", 0, 0);
            self.pieces[2]:SetPoint("TOPLEFT", self.pieces[1], "TOPRIGHT", 0, 0);
            self.pieces[2]:SetPoint("BOTTOMRIGHT", self.pieces[3], "BOTTOMLEFT", 0, 0);

            self.pieces[1]:SetTexCoord(0, 0.25, 0, 1);
            self.pieces[2]:SetTexCoord(0.25, 0.75, 0, 1);
            self.pieces[3]:SetTexCoord(0.75, 1, 0, 1);

        elseif n == 9 then
            self.pieces[1]:SetPoint("CENTER", self, "TOPLEFT", 0, 0);
            self.pieces[3]:SetPoint("CENTER", self, "TOPRIGHT", 0, 0);
            self.pieces[7]:SetPoint("CENTER", self, "BOTTOMLEFT", 0, 0);
            self.pieces[9]:SetPoint("CENTER", self, "BOTTOMRIGHT", 0, 0);
            self.pieces[2]:SetPoint("TOPLEFT", self.pieces[1], "TOPRIGHT", 0, 0);
            self.pieces[2]:SetPoint("BOTTOMRIGHT", self.pieces[3], "BOTTOMLEFT", 0, 0);
            self.pieces[4]:SetPoint("TOPLEFT", self.pieces[1], "BOTTOMLEFT", 0, 0);
            self.pieces[4]:SetPoint("BOTTOMRIGHT", self.pieces[7], "TOPRIGHT", 0, 0);
            self.pieces[5]:SetPoint("TOPLEFT", self.pieces[1], "BOTTOMRIGHT", 0, 0);
            self.pieces[5]:SetPoint("BOTTOMRIGHT", self.pieces[9], "TOPLEFT", 0, 0);
            self.pieces[6]:SetPoint("TOPLEFT", self.pieces[3], "BOTTOMLEFT", 0, 0);
            self.pieces[6]:SetPoint("BOTTOMRIGHT", self.pieces[9], "TOPRIGHT", 0, 0);
            self.pieces[8]:SetPoint("TOPLEFT", self.pieces[7], "TOPRIGHT", 0, 0);
            self.pieces[8]:SetPoint("BOTTOMRIGHT", self.pieces[9], "BOTTOMLEFT", 0, 0);

            self.pieces[1]:SetTexCoord(0, 0.25, 0, 0.25);
            self.pieces[2]:SetTexCoord(0.25, 0.75, 0, 0.25);
            self.pieces[3]:SetTexCoord(0.75, 1, 0, 0.25);
            self.pieces[4]:SetTexCoord(0, 0.25, 0.25, 0.75);
            self.pieces[5]:SetTexCoord(0.25, 0.75, 0.25, 0.75);
            self.pieces[6]:SetTexCoord(0.75, 1, 0.25, 0.75);
            self.pieces[7]:SetTexCoord(0, 0.25, 0.75, 1);
            self.pieces[8]:SetTexCoord(0.25, 0.75, 0.75, 1);
            self.pieces[9]:SetTexCoord(0.75, 1, 0.75, 1);
        end
    end

    function SliceFrameMixin:SetCornerSize(a)
        if self.numSlices == 3 then
            self.pieces[1]:SetSize(a, 2*a);
            self.pieces[3]:SetSize(a, 2*a);
        elseif self.numSlices == 9 then
            --if true then
            --    NiceSlice_SetCornerSize(self, a);
            --    return
            --end
            self.pieces[1]:SetSize(a, a);
            self.pieces[3]:SetSize(a, a);
            self.pieces[7]:SetSize(a, a);
            self.pieces[9]:SetSize(a, a);
        end
    end

    function SliceFrameMixin:SetCornerSizeByScale(scale)
        self:SetCornerSize(16 * scale);
    end

    function SliceFrameMixin:SetTexture(tex)
        --if self.NineSlice then
        --    NiceSlice_SetTexture(self, tex);
        --    return
        --end
        for i = 1, #self.pieces do
            self.pieces[i]:SetTexture(tex);
        end
    end

    function SliceFrameMixin:SetDisableSharpening(state)
        for i = 1, #self.pieces do
            self.pieces[i]:SetSnapToPixelGrid(not state);
        end
    end

    function SliceFrameMixin:SetColor(r, g, b)
        for i = 1, #self.pieces do
            self.pieces[i]:SetVertexColor(r, g, b);
        end
    end

    function SliceFrameMixin:CoverParent(padding)
        padding = padding or 0;
        local parent = self:GetParent();
        if parent then
            self:ClearAllPoints();
            self:SetPoint("TOPLEFT", parent, "TOPLEFT", -padding, padding);
            self:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", padding, -padding);
        end
    end

    function SliceFrameMixin:ShowBackground(state)
        for _, piece in ipairs(self.pieces) do
            piece:SetShown(state);
        end
    end

---Available nine-slice layout styles
local NineSliceLayouts = {
    WhiteBorder = true,
    WhiteBorderBlackBackdrop = true,
    Tooltip_Brown = true,
    Menu_Black = true,
    NineSlice_GenericBox = true,
    NineSlice_GenericBox_Border = true,
    NineSlice_GenericBox_Black = true,
    NineSlice_GenericBox_Black_Shadowed = true,
};

---Create a nine-slice frame with custom border texture
---Nine-slice frames scale properly without distorting corners
---@param parent Frame Parent frame to attach the nine-slice to
---@param layoutName? string Layout name from NineSliceLayouts (default: "WhiteBorder")
---@return Frame nineSliceFrame Frame with SliceFrameMixin methods (SetCornerSize, CoverParent, etc.)
function API:CreateNineSliceFrame(parent, layoutName)
    if not (layoutName and NineSliceLayouts[layoutName]) then
        layoutName = "WhiteBorder";
    end
    local f = CreateFrame("Frame", nil, parent);
    Mixin(f, SliceFrameMixin);
    f:CreatePieces(9);
    f:SetTexture("Interface/AddOns/!WilduTools/Media/Art/"..layoutName);
    f:ClearAllPoints();
    return f
end