local _, ns = ...
local DEBUG = {}
ns.DEBUG = DEBUG

-- FLAGS
local DEBUG_FLAG = false
local DEBUG_VERBOSE_ONLY_RELEVANT = true

-- Debugging Timers

local debugTimers = {}
function DEBUG.startDebugTimer(name)
    debugTimers[name] = GetTimePreciseSec()
end

function DEBUG.checkpointDebugTimer(name, fromPoint)
	if not DEBUG_FLAG then
		return
	end

    local currentTime = GetTimePreciseSec()
	debugTimers[name] = currentTime
    local startTime = debugTimers["FILE_START_TIME"]
    local fromTime = debugTimers[fromPoint] or startTime -- Default to own start if fromPoint not found

    if not fromTime then
        ns.Addon:Print(string.format("[DEBUG] |cffffffff%s|r\n|cffff0000No time recorded for debugging.|r", name))
        return
    end

    -- local elapsed = (currentTime - fromTime) * 1000000000 -- Convert to milliseconds
    local elapsed = (currentTime - fromTime) * 1000 -- Convert to milliseconds

    local timeColor
	if elapsed < 0.3 then
		timeColor = "|cff00ff00" -- Green
    elseif elapsed < 0.6 then
        timeColor = "|cffffff00" -- Yellowish
    elseif elapsed < 3 then
        timeColor = "|cffffff00" -- Yellow
    else -- 5ms or more
        timeColor = "|cffff0000" -- Red
    end

    local nameColor = "|cff8080ff" -- Light blue for the name
    local eventColor = "|cff88c0d0" -- Cyan-like for the event description

	if DEBUG_VERBOSE_ONLY_RELEVANT and elapsed <= 0.2 then 
		return 
	end

	ns.Addon:Print(string.format("%s[DEBUG]|r\n%s%.2fms|r %s%s|r", 
		nameColor, timeColor, elapsed, nameColor, name))

end