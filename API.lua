local _, ns = ...

--- WilduTools API Module
--- Provides core gameplay and utility functions used across the addon
local API = {}
ns.API = API

local DEBUG = ns.DEBUG

-- ============================================================================
-- CONSTANTS & CONFIGURATION
-- ============================================================================

local RANGE_CHECK_THROTTLE = 0.1 -- seconds

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

---Safely wait for a specified duration before executing callback
---@param delay number Delay in seconds
---@param callback function Function to execute
---@param ... any Arguments to pass to callback
local function WaitAndExecute(delay, callback, ...)
  DEBUG.startDebugTimer("API_WAIT_AND_EXECUTE_START")
  
  if not callback or type(callback) ~= "function" then
    DEBUG.log("ERROR", "WaitAndExecute: callback is not a function")
    return
  end
  
  local args = {...}
  C_Timer.After(delay, function()
    xpcall(callback, function(err)
      DEBUG.log("ERROR", "WaitAndExecute callback error: "..tostring(err))
    end, unpack(args))
  end)
  
  DEBUG.checkpointDebugTimer("API_WAIT_AND_EXECUTE_DONE", "API_WAIT_AND_EXECUTE_START")
end

-- Public alias
function API:wait(delay, callback, ...)
  WaitAndExecute(delay, callback, ...)
end

-- ============================================================================
-- RANGE CHECK FUNCTIONS
-- ============================================================================

---Get minimum and maximum range for a target
---@param unit string UnitID to check range for (e.g., "target")
---@param estimateIfNoRangeTable boolean If true, estimate range from combat range
---@return number|nil minRange Minimum range or nil
---@return number|nil maxRange Maximum range or nil
function API:GetRange(unit, estimateIfNoRangeTable)
  if not UnitExists(unit) then
    return nil, nil
  end
  
  -- Try to get range from C_Spell.GetSpellRange (most accurate)
  local actionSlot = FindSpellActionButton("Fireball") -- example spell, adjust as needed
  if actionSlot then
    local rangeTable = C_Spell.GetSpellRange(actionSlot)
    if rangeTable then
      return rangeTable[1], rangeTable[2]
    end
  end
  
  -- Fallback: Estimate from combat range
  if estimateIfNoRangeTable then
    if CheckInteractDistance(unit, 4) then
      return 5, 5
    elseif CheckInteractDistance(unit, 3) then
      return 28, 28
    elseif IsSpellInRange("Fireball", unit) == 1 then
      return 40, 40
    end
  end
  
  return nil, nil
end

---Check if player can interact with unit (simple distance check)
---@param unit string UnitID to check
---@param distance number Distance threshold in yards
---@return boolean canInteract
function API:CanInteractWithUnit(unit, distance)
  if not UnitExists(unit) then
    return false
  end
  
  distance = distance or 4 -- default interact distance
  
  for i = 1, 4 do
    if CheckInteractDistance(unit, i) then
      return true
    end
  end
  
  return false
end

-- ============================================================================
-- UNIT INFORMATION FUNCTIONS
-- ============================================================================

---Get unit's threat status in simple terms
---@param unit string UnitID to check threat for
---@return string threatLevel One of: "high", "medium", "low", "none"
function API:GetSimpleThreatStatus(unit)
  if not UnitExists(unit) then
    return "none"
  end
  
  local isThreat, threatStatus = UnitThreatSituation("player", unit)
  
  if not isThreat then
    return "none"
  end
  
  if threatStatus >= 2 then
    return "high"
  elseif threatStatus == 1 then
    return "medium"
  else
    return "low"
  end
end

---Check if target is hostile to player
---@param unit string UnitID to check
---@return boolean isHostile
function API:IsUnitHostile(unit)
  if not UnitExists(unit) then
    return false
  end
  
  return UnitCanAttack("player", unit) and not UnitIsFriend("player", unit)
end

---Check if target is friendly to player
---@param unit string UnitID to check
---@return boolean isFriendly
function API:IsUnitFriendly(unit)
  if not UnitExists(unit) then
    return false
  end
  
  return UnitIsFriend("player", unit)
end

-- ============================================================================
-- SPELL INFORMATION FUNCTIONS
-- ============================================================================

---Check if spell is currently usable (not on cooldown, have resources, etc.)
---@param spellID number Spell ID to check
---@return boolean isUsable Whether spell can be cast
function API:IsSpellUsable(spellID)
  if not spellID then
    return false
  end
  
  local spell = C_Spell.GetSpellInfo(spellID)
  if not spell then
    return false
  end
  
  return C_Spell.IsSpellUsable(spellID)
end

---Get remaining cooldown for a spell
---@param spellID number Spell ID to check
---@return number|nil cooldownRemaining Seconds remaining on cooldown, or nil if not on cooldown
function API:GetSpellCooldownRemaining(spellID)
  if not spellID then
    return nil
  end
  
  local cooldownInfo = C_Spell.GetSpellCooldown(spellID)
  if not cooldownInfo then
    return nil
  end
  
  if cooldownInfo.duration == 0 then
    return nil -- not on cooldown
  end
  
  local timeRemaining = (cooldownInfo.startTime + cooldownInfo.duration) - GetTime()
  return math.max(0, timeRemaining)
end

-- ============================================================================
-- PLAYER STATE FUNCTIONS
-- ============================================================================

---Check if player is in a form/shape
---@return string|nil currentForm Form name or nil if no form
function API:GetCurrentPlayerForm()
  local powerType, powerTypeString = UnitPowerType("player")
  return powerTypeString
end

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
---@return boolean isHidden
function API:IsPlayerHidden()
  return C_PlayerInfo.IsPlayerStealthed() or C_PlayerInfo.IsPlayerInvisible()
end

-- ============================================================================
-- ERROR HANDLING & SAFETY
-- ============================================================================

---Safely execute function with error catching
---@param func function Function to execute
---@param ... any Arguments to pass to function
---@return boolean success Whether function executed without error
---@return any result Function result or error message
function API:SafeCall(func, ...)
  if not func or type(func) ~= "function" then
    DEBUG.log("ERROR", "SafeCall: argument is not a function")
    return false, "Not a function"
  end
  
  return xpcall(func, function(err)
    DEBUG.log("ERROR", "SafeCall error: "..tostring(err))
    return tostring(err)
  end, ...)
end

return API
