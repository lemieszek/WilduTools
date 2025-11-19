local _, ns = ...

--- WilduTools API Module
--- Provides core gameplay and utility functions used across the addon
local API = {}
ns.API = API

local LibRangeCheck = LibStub("LibRangeCheck-3.0")

local DEBUG = ns.DEBUG


-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

function API:OpenClickCastBinding()
    C_AddOns.LoadAddOn('Blizzard_ClickBindingUI')
    ClickBindingFrame_Toggle()
end

function API:OpenQuickKeybindMode()
    ShowUIPanel(QuickKeybindFrame)
end

local waitTable = {}
local waitFrame = nil

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
---- WAIT END

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
function API:GetRange(unit, checkVisible)
  return LibRangeCheck:GetRange(unit, checkVisible);
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