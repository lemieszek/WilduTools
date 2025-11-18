local _, ns = ...
local UTM = {}
ns.UTM = UTM

-- Static popup dialogs
StaticPopupDialogs["SETUP_UTM"] = {
    text = 'Setup UTM macros',
    hasEditBox = false,
    button1 = "Setup",
    button2 = "Cancel",
    OnAccept = function(self)
        UTM:SetupMacros()
        self:Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    }

StaticPopupDialogs["UTM"] = {
    text = 'Update target name',
    button1 = "Update Target Macro",
    button2 = "Cancel",
    startDelay = 1,
    delayText = "test deley",
    OnShow = function(self)
        self:Show()
        self.EditBox:SetText("")
        self.EditBox:HighlightText()
    end,
    hasEditBox = true,
    hasWideEditBox = true,
    editBoxWidth = 220,
    timeout = 0,
    whileDead = true,
    OnEditFocusLost = function(self)
        self.EditBox:SetFocus()
        return true
    end,
    preferredIndex = 3,
    OnAccept = function(self)
        local boxText = self.EditBox:GetText()
        if boxText ~= "" then
            UTM:TargetUpdate("[target="..boxText.."] \""..ns.CONSTANTS.TARGET_MACRO_NAME.."\"")
            self:Hide()
        else
            self.EditBox:SetFocus()
        end
        return true
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local boxText = parent.EditBox:GetText()
        if boxText ~= "" then
            UTM:TargetUpdate("[target="..boxText.."] \""..ns.CONSTANTS.TARGET_MACRO_NAME.."\"")
            self:GetParent():Hide()
        else
            parent.EditBox:SetFocus()
        end
        return true
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
}

StaticPopupDialogs["UTM_EXAMPLE"] = {
    text = 'Example targeting macro',
    button1 = "OK",
    OnShow = function(self)
        self.EditBox:SetMultiLine(true)
        self.EditBox:SetHeight(90)
        self.EditBox:DisableDrawLayer("BACKGROUND")
        self.EditBox:SetText(ns.MACRO_TEMPLATES.UTM_EXAMPLE)
        self.EditBox:HighlightText()
        self:Show()
    end,
    hasEditBox = true,
    hasWideEditBox = true,
    editBoxWidth = 220,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Macro setup functions
function UTM:SetupMacros()
    self:SetupUTMMacro()
    self:SetupUTMTargetMacro()
end

function UTM:SetupUTMMacro()
    local macroIndex = GetMacroIndexByName(ns.CONSTANTS.SET_TARGET_MACRO_NAME)
    if macroIndex == 0 then
        local numAccountMacros = GetNumMacros()
        if numAccountMacros == 36 then
            print("Action Bar was unable to create needed macros, since you have exceeded maximum number of possible macros.")
            return
        end
        CreateMacro(ns.CONSTANTS.SET_TARGET_MACRO_NAME, "4335642", ns.MACRO_TEMPLATES.UTM_SET_TARGET, true)
        print("Macro created: " .. ns.CONSTANTS.SET_TARGET_MACRO_NAME)
    else
        EditMacro(ns.CONSTANTS.SET_TARGET_MACRO_NAME, ns.CONSTANTS.SET_TARGET_MACRO_NAME, "4335642", ns.MACRO_TEMPLATES.UTM_SET_TARGET)
    end
end

function UTM:SetupUTMTargetMacro()
    local macroIndex = GetMacroIndexByName(ns.CONSTANTS.TARGET_MACRO_NAME)
    if macroIndex == 0 then
        local numAccountMacros = GetNumMacros()
        if numAccountMacros == 36 then
            print("Action Bar was unable to create needed macros, since you have exceeded maximum number of possible macros.")
            return
        end
        CreateMacro(ns.CONSTANTS.TARGET_MACRO_NAME, "4335643", ns.MACRO_TEMPLATES.UTM_EXAMPLE .. "\n", true)
        print("Macro created: " .. ns.CONSTANTS.TARGET_MACRO_NAME)
    else
        EditMacro(ns.CONSTANTS.TARGET_MACRO_NAME, ns.CONSTANTS.TARGET_MACRO_NAME, "4335643", ns.MACRO_TEMPLATES.UTM_EXAMPLE .. "\n")
    end
end

-- Target update functions
function UTM:TargetUpdate(args)
    if InCombatLockdown() then
        print("Can't adjust macros in combat.")
        return
    end

    local ourArgs, ourTarget = SecureCmdOptionParse(args)
    if not ourArgs or ourArgs == "" then
        return
    end

    local muttCall = {
        macroMutts = 0,
        groupNumber = nil,
        countTargets = 0,
        alterAll = false,
        ourMacro = nil,
        ourMuttlines = {},
        alterTargets = {},
        preserveTag = false,
        mt = {},
        altering = "@"
    }
    setmetatable(muttCall, muttCall.mt)

    if ourArgs:find('"') then
        _, _, muttCall.ourMacro, ourArgs = ourArgs:find('^(%b"")%s*(.*)')
        muttCall.ourMacro = muttCall.ourMacro:gsub('"', "")
    else
        _, _, muttCall.ourMacro, ourArgs = ourArgs:find('^(%S+)%s*(.*)')
    end

    if ourArgs:len() > 0 then
        for step in ourArgs:gmatch("%S+") do
            step = strlower(step)
            if tonumber(step) then
                table.insert(muttCall.alterTargets, tonumber(step))
            elseif step == "all" then
                muttCall.alterAll = true
            end
        end
    end

    if not ourTarget then
        ourTarget = UnitName("target")
    end

    local macroIndex = GetMacroIndexByName(muttCall.ourMacro)
    if macroIndex == 0 then
        print("|cffeeee33Warning: |cffccccccCan't find macro |r"..muttCall.ourMacro.."|cffcccccc, did you create it before using |r /utm |cffcccccc(or is it an add-on macro not a WoW macro)..?")
        return
    end

    local slashAcquire = "/target"
    muttCall.altering = slashAcquire.." "
    muttCall.groupNumber = ourTarget

    local ourName, ourTexture, ourMacroBody, isLocal = GetMacroInfo(macroIndex)
    local _, targetCount = string.gsub(ourMacroBody, "("..slashAcquire..")(%s+)", {})

    if targetCount > 0 then
        if #muttCall.alterTargets == 0 and not muttCall.alterAll then
            table.insert(muttCall.alterTargets, 1)
        end

        local tempTable = {}
        for ourKey, ourValue in pairs(muttCall.alterTargets) do
            if ourValue < 0 then
                ourValue = targetCount + 1 + ourValue
            end
            if ourValue >= 1 and ourValue <= targetCount then
                tempTable[ourValue] = true
            else
                print("Invalid target instance of "..ourValue.." provided, discarding...")
            end
        end
        muttCall.alterTargets = tempTable

        muttCall.mt.__index = self.muttTargetSub
        ourMacroBody = string.gsub(ourMacroBody, slashAcquire.."%s+([^\n]+)", muttCall)
        EditMacro(macroIndex, ourName, nil, ourMacroBody, isLocal)
    else
        print("Couldn't find a an instance of "..slashAcquire.." in macro "..ourName)
    end
end

function UTM.muttTargetSub(slashCall, prevTarget)
    slashCall.countTargets = slashCall.countTargets + 1
    local foo = slashCall.countTargets
    local ourReturn = slashCall.groupNumber
    if slashCall.alterTargets[foo] or slashCall.alterAll then
        if slashCall.preserveTag then
            ourReturn = ourReturn..slashCall.preserveTag
        end
        print("|cffccccccPatching target instance |r"..slashCall.countTargets.."|cffcccccc in macro |r"..slashCall.ourMacro.."|cffcccccc from |r"..slashCall.altering..prevTarget.."|cffcccccc to |r"..slashCall.altering..ourReturn)
        return slashCall.altering..ourReturn
    end
    return nil
end

-- Command handler
function UTM:HandleCommand(input)
    if input == "setup" then
        StaticPopup_Show("SETUP_UTM")
    elseif input == "example" then
        StaticPopup_Show("UTM_EXAMPLE")
    elseif input == "" then
        print("Usage:")
        print("/utm macroName - update <macroName> /target with target or input")
        print("/utm setup - Setup UTM macros")
        print("/utm example - Show example macro")
    else
        if not (UnitExists("target")) then
            ns.API:wait(0.01, StaticPopup_Show, "UTM") -- fix for keybind going in as text
        else
            UTM:TargetUpdate(input)
        end
    end
end 

UTM.helpUsing = [[
Highly inspired by Mutt - all credits to original author - Tuills.
Examples:
|cff999999# The /utm (at their simplest) just
# update the first occurrance of /target in a
# macro to the name of your current target or input value
# If you have a macro named "chain fear" that looks like:|r
/target Murloc Hunter
/cast Fear()
/targetlasttarget

|cff999999# ...and you're targeting a Defias Bandit, then:|r
/utm "chain fear"

|cff999999# ... will update your "chain fear" macro to be:|r
/target Defias Bandit
/cast Fear()
/targetlasttarget

Caveats:

* Update target macro works by editing macros, and macros can't be edited in
combat.

* If you run UTM commands with the WoW macro window open you won't see any changes to your
macro and WoW will overwrite any of UTM's changes when the window closes.

* If your macro has spaces in the name then you must enclose
the name in double-quotes, a-la:
|r
/utm "utm macro"
]]
