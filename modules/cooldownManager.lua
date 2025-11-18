local _, ns = ...
local CooldownManager = {}
ns.CooldownManager = CooldownManager
local DEBUG = ns.DEBUG

function CooldownManager.centerBuffIconCooldownViewerAnchor()
  ns.DEBUG.startDebugTimer("COOLDOWNMANAGER_CENTER_BUFFICON_START")
  local width, height = BuffIconCooldownViewer:GetSize()
  local from,parent,to,x,y= BuffIconCooldownViewer:GetPoint()
  if from then
    from = from:gsub("LEFT", ""):gsub("RIGHT", "")
  end
  if to then
    to = to:gsub("LEFT", ""):gsub("RIGHT", "")
  end
  BuffIconCooldownViewer:ClearAllPoints()
  BuffIconCooldownViewer:SetPoint(from, parent,to, 0, y)
  DEBUG.checkpointDebugTimer("COOLDOWNMANAGER_CENTER_BUFFICON_DONE", "COOLDOWNMANAGER_CENTER_BUFFICON_START")
end

function CooldownManager.centerEssentialCooldownViewerAnchor()
  ns.DEBUG.startDebugTimer("COOLDOWNMANAGER_CENTER_ESSENTIAL_START")
  local width, height = EssentialCooldownViewer:GetSize()
  local from,parent,to,x,y= EssentialCooldownViewer:GetPoint()
  if from then
    from = from:gsub("LEFT", ""):gsub("RIGHT", "")
  end
  if to then
    to = to:gsub("LEFT", ""):gsub("RIGHT", "")
  end
  EssentialCooldownViewer:ClearAllPoints()
  EssentialCooldownViewer:SetPoint(from, parent,to, 0, y) 
  DEBUG.checkpointDebugTimer("COOLDOWNMANAGER_CENTER_ESSENTIAL_DONE", "COOLDOWNMANAGER_CENTER_ESSENTIAL_START")
end
