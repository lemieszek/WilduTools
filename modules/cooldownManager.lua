local _, ns = ...
local CooldownManager = {}
ns.CooldownManager = CooldownManager

function CooldownManager.centerBuffIconCooldownViewerAnchor()
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
end

function CooldownManager.centerEssentialCooldownViewerAnchor()
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
end
