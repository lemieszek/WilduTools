local _, ns = ...

--- Comprehensive Debug & Profiling System for WilduTools
--- Provides timing analysis, event tracking, and performance monitoring
local DEBUG = {}
ns.DEBUG = DEBUG

-- ============================================================================
-- DEBUG STATE & CONFIGURATION
-- ============================================================================

DEBUG.enabled = true
DEBUG.verbose = false
DEBUG.timers = {}
DEBUG.events = {}
DEBUG.hooks = {}
DEBUG.spikeSamples = {}
DEBUG.moduleTimings = {}

local SPIKE_THRESHOLD = 5 -- milliseconds
local SPIKE_SAMPLE_WINDOW = 2000 -- sample from init to 6 seconds
local SPIKE_SAMPLE_INTERVAL = 160 -- check every 50ms

-- ============================================================================
-- TIMER FUNCTIONS (EXISTING - Enhanced)
-- ============================================================================

---Start a debug timer with unique label
---@param label string Unique timer identifier
function DEBUG.startDebugTimer(label)
  if not DEBUG.enabled then return end
  DEBUG.timers[label] = GetTimePreciseSec()
end

---Check elapsed time since timer start, print checkpoint
---@param checkpointLabel string Checkpoint name
---@param timerLabel string Original timer label
---@return number elapsedTime Time in seconds
function DEBUG.checkpointDebugTimer(checkpointLabel, timerLabel)
  if not DEBUG.enabled then return 0 end
  
  local startTime = DEBUG.timers[timerLabel]
  if not startTime then
    DEBUG.log("WARN", checkpointLabel..": Timer '"..timerLabel.."' not found")
    return 0
  end
  
  local elapsed = (GetTimePreciseSec() - startTime) * 1000 -- convert to ms
  
  -- Track module timing
  local moduleName = checkpointLabel:match("^([A-Z_]+)_") or "UNKNOWN"
  DEBUG.moduleTimings[moduleName] = (DEBUG.moduleTimings[moduleName] or 0) + elapsed
  
  if elapsed > 1 then -- Only log operations taking >1ms
    DEBUG.log("TIMER", checkpointLabel.." took "..string.format("%.2f", elapsed).."ms")
  end
  
  DEBUG.timers[timerLabel] = nil
  return elapsed
end

-- ============================================================================
-- ENHANCED LOGGING SYSTEM
-- ============================================================================

---Centralized debug logging with color coding
---@param category string Log category (TIMER, EVENT, HOOK, ERROR, WARN, INFO)
---@param message string Log message
function DEBUG.log(category, message)
  if not DEBUG.enabled then return end
  
  local colorMap = {
    TIMER = "|cFF00FF00",  -- Green
    EVENT = "|cFF0099FF",  -- Blue
    HOOK  = "|cFFFF9900",  -- Orange
    ERROR = "|cFFFF0000",  -- Red
    WARN  = "|cFFFFFF00",  -- Yellow
    INFO  = "|cFFCCCCCC",  -- Gray
  }
  
  local color = colorMap[category] or "|cFFFFFFFF"
  local timestamp = string.format("%.3f", GetTimePreciseSec() % 100)
  
  if DEBUG.verbose then
    print(color.."[WilduTools "..category.." @ "..timestamp.."s] |r"..message)
  end
end

-- ============================================================================
-- EVENT TRACKING
-- ============================================================================

---Track event registration for profiling
---@param eventName string Event name being registered
---@param moduleName string Module registering the event
function DEBUG.trackEventRegistered(eventName, moduleName)
  if not DEBUG.enabled then return end
  
  if not DEBUG.events[eventName] then
    DEBUG.events[eventName] = {
      registeredBy = {},
      firedCount = 0,
      cumulativeTime = 0,
    }
  end
  
  table.insert(DEBUG.events[eventName].registeredBy, moduleName)
  DEBUG.log("EVENT", "Event '"..eventName.."' registered by "..moduleName)
end

---Track event firing for performance analysis
---@param eventName string Event being fired
---@param duration number Time spent in event handler (ms)
function DEBUG.trackEventFired(eventName, duration)
  if not DEBUG.enabled then return end
  
  if DEBUG.events[eventName] then
    DEBUG.events[eventName].firedCount = DEBUG.events[eventName].firedCount + 1
    DEBUG.events[eventName].cumulativeTime = DEBUG.events[eventName].cumulativeTime + duration
    
    if duration > SPIKE_THRESHOLD then
      DEBUG.log("EVENT", eventName.." took "..string.format("%.2f", duration).."ms (slow)")
    end
  end
end

-- ============================================================================
-- HOOK TRACKING
-- ============================================================================

---Track script hook registration
---@param frameType string Type of hook (OnUpdate, OnShow, OnHide, etc.)
---@param moduleName string Module creating the hook
function DEBUG.trackHookRegistered(frameType, moduleName)
  if not DEBUG.enabled then return end
  
  if not DEBUG.hooks[frameType] then
    DEBUG.hooks[frameType] = {}
  end
  
  table.insert(DEBUG.hooks[frameType], moduleName)
  DEBUG.log("HOOK", frameType.." hook registered by "..moduleName)
end

-- ============================================================================
-- SPIKE DETECTION & ANALYSIS
-- ============================================================================

---Initialize real-time spike detection during addon load
function DEBUG.initializeSpikeDetection()
  if not DEBUG.enabled then return end
  
  local spikeDetectionFrame = CreateFrame("Frame")
  local initTime = GetTimePreciseSec()
  local lastSampleTime = initTime
  local lastFrameTime = 0
  
  spikeDetectionFrame:SetScript("OnUpdate", function(self)
    local currentTime = GetTimePreciseSec()
    local timeSinceInit = (currentTime - initTime) * 1000 -- ms
    
    -- Only sample during first 6 seconds
    if timeSinceInit > SPIKE_SAMPLE_WINDOW then
      self:SetScript("OnUpdate", nil)
      DEBUG.log("INFO", "Spike detection complete")
      return
    end
    
    -- Sample every SPIKE_SAMPLE_INTERVAL ms
    if (currentTime - lastSampleTime) * 1000 >= SPIKE_SAMPLE_INTERVAL then
      local deltaTime = (currentTime - lastFrameTime) * 1000
      
      table.insert(DEBUG.spikeSamples, {
        time = timeSinceInit,
        delta = deltaTime / 1000,
        timestamp = currentTime,
      })
      
      if deltaTime > SPIKE_THRESHOLD then
        DEBUG.log("WARN", string.format("Spike detected at %.2fs: %.2fms", timeSinceInit / 1000, deltaTime))
      end
      
      lastSampleTime = currentTime
    end
    
    lastFrameTime = currentTime
  end)
end

---Analyze spike samples and report findings
---@return table Analysis results with peak times and affected modules
function DEBUG.analyzeSpikeData()
  if not DEBUG.enabled or #DEBUG.spikeSamples == 0 then
    return {}
  end
  
  local analysis = {
    samples = #DEBUG.spikeSamples,
    peakDelta = 0,
    peakTime = 0,
    avgDelta = 0,
    spikeCount = 0,
    spikeTimes = {},
  }
  
  local totalDelta = 0
  
  for _, sample in ipairs(DEBUG.spikeSamples) do
    totalDelta = totalDelta + sample.delta
    
    if sample.delta > analysis.peakDelta then
      analysis.peakDelta = sample.delta
      analysis.peakTime = sample.time
    end
    
    if sample.delta > SPIKE_THRESHOLD then
      analysis.spikeCount = analysis.spikeCount + 1
      table.insert(analysis.spikeTimes, sample.time)
    end
  end
  
  analysis.avgDelta = totalDelta / #DEBUG.spikeSamples
  
  return analysis
end

-- ============================================================================
-- REPORTING FUNCTIONS
-- ============================================================================

---Print comprehensive debug report
function DEBUG.printReport()
  if not DEBUG.enabled then return end
  
  print("\n|cFFFFFF00=== WilduTools Debug Report ===|r")
  
  print("\n|cFFFF9900Module Timings:|r")
  for module, time in pairs(DEBUG.moduleTimings) do
    print(string.format("  %s: %.2f ms", module, time))
  end
  
  print("\n|cFF0099FFEvent Analysis:|r")
  for event, data in pairs(DEBUG.events) do
    if data.firedCount > 0 then
      local avgTime = data.cumulativeTime / data.firedCount
      print(string.format("  %s: fired %d times, avg %.2f ms", event, data.firedCount, avgTime))
    end
  end
  
  local spikeAnalysis = DEBUG.analyzeSpikeData()
  if spikeAnalysis.spikeCount and spikeAnalysis.spikeCount > 0 then
    print("\n|cFFFF0000Spike Analysis:|r")
    print(string.format("  Peak: %.2f ms at %.2f s", spikeAnalysis.peakDelta, spikeAnalysis.peakTime / 1000))
    print(string.format("  Average: %.2f ms", spikeAnalysis.avgDelta))
    print(string.format("  Spike count: %d", spikeAnalysis.spikeCount))
  end
end

-- Initialize spike detection on load
-- DEBUG.initializeSpikeDetection()

return DEBUG
