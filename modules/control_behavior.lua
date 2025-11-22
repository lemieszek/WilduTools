local _, ns = ...
local ControlBehavior = {}
ns.ControlBehavior = ControlBehavior

local abs = math.abs
local MOVE_THRESHOLD = 4


---@class FreeRightClickMoveFeature
---@field frame Frame
---@field lastX number
---@field lastY number
---@field rmbDown boolean
---@field inLook boolean
---@field initialized boolean

local FreeRightClickMove = {}
ControlBehavior.FreeRightClickMove = FreeRightClickMove

local function StopMouselookIfNeeded()
    if FreeRightClickMove.inLook then
        MouselookStop()
        FreeRightClickMove.inLook = false
    end
    FreeRightClickMove.rmbDown = false
    if FreeRightClickMove.frame then
        FreeRightClickMove.frame:SetScript("OnUpdate", nil)
    end
end

local function OnUpdate(_, elapsed)
    -- If RMB is no longer down, stop watching and exit look mode if active
    if not IsMouseButtonDown(2) then
        StopMouselookIfNeeded()
        return
    end

    -- If feature is configured to be only in combat and we're not in combat, do nothing
    if ns.db
        and ns.db.profile
        and ns.db.profile.controlBehavior_free_right_click_move_in_combat
        and not InCombatLockdown()
    then
        return
    end

    if FreeRightClickMove.inLook then
        return
    end

    local x, y = GetCursorPosition()
    if abs(x - FreeRightClickMove.lastX) > MOVE_THRESHOLD or abs(y - FreeRightClickMove.lastY) > MOVE_THRESHOLD then
            local ok, err = pcall(MouselookStart)
            if not ok then
                -- this only catches *Lua* errors, which MouselookStart normally won’t throw
                -- but doesn’t catch protected-action blocks
                print("WilduTools: Error starting mouselook:", err)
            end
        FreeRightClickMove.inLook = true
    end
end

local function OnEvent(self, event, arg1, arg2)
    if event == "GLOBAL_MOUSE_DOWN" and arg1 == "RightButton" then
        -- Only react if setting is enabled
        if not (ns.db and ns.db.profile and ns.db.profile.controlBehavior_free_right_click_move) then
            return
        end

        FreeRightClickMove.rmbDown = true
        FreeRightClickMove.inLook  = false
        FreeRightClickMove.lastX, FreeRightClickMove.lastY = GetCursorPosition()
        self:SetScript("OnUpdate", OnUpdate)
        return
    end

    if event == "GLOBAL_MOUSE_UP" and arg1 == "RightButton" then
        -- Always exit look when RMB is released, even if combat state changed mid-look
        StopMouselookIfNeeded()
        return
    end

    if event == "PLAYER_REGEN_ENABLED" then
        -- Left combat: if we were in mouselook due to this feature, exit cleanly
        if not IsMouseButtonDown(2) then
            StopMouselookIfNeeded()
        end
    end
end

function ControlBehavior.FreeRightClickMove:Init()
    if self.initialized then
        return
    end

    local f = CreateFrame("Frame")
    self.frame = f

    f:RegisterEvent("GLOBAL_MOUSE_DOWN")
    f:RegisterEvent("GLOBAL_MOUSE_UP")
    f:RegisterEvent("PLAYER_REGEN_ENABLED") -- combat ended

    f:SetScript("OnEvent", OnEvent)

    self.lastX, self.lastY = 0, 0
    self.rmbDown = false
    self.inLook  = false

    self.initialized = true
end

function ControlBehavior.FreeRightClickMove:OnEnable()
    self:Init()

    -- Make sure we're not stuck from some previous state
    StopMouselookIfNeeded()

    if self.frame then
        self.frame:Show()
    end
end

function ControlBehavior.FreeRightClickMove:OnDisable()
    -- When disabling the feature, ensure we exit look mode and stop listening
    StopMouselookIfNeeded()

    if self.frame then
        self.frame:Hide()
    end
end