local _, ns = ...
local CooldownManager = {}
ns.CooldownManager = CooldownManager
local DEBUG = ns.DEBUG

function CooldownManager.centerBuffIcons()
  local itemFrameContainer = BuffIconCooldownViewer:GetLayoutChildren()
  for i = #itemFrameContainer, 1, -1 do
    local itemFrame = itemFrameContainer[i]
    if not itemFrame.isActive then
      table.remove(itemFrameContainer, i)
    end
  end
  for i, itemFrame in ipairs(itemFrameContainer) do
    itemFrame:SetParent(BuffIconCooldownViewer)
    itemFrame:ClearAllPoints()
    local itemSizeX = itemFrame:GetWidth() 
    local itemSizeY = itemFrame:GetHeight()
    local padding = 2

    local displayIndex = i - 1
    local itemsInLine = #itemFrameContainer
    local centerOffsetX, centerOffsetY = 0, 0

    local totalLineWidth = itemsInLine * itemSizeX + (itemsInLine - 1) * padding
    centerOffsetX = -totalLineWidth / 2 + itemSizeX / 2
      
    local iconXOffset = itemSizeX + padding

    local x, y

    x = displayIndex * iconXOffset + centerOffsetX
    y = 0

    local anchorPoint = (secondDirection == 1) and "BOTTOM" or "TOP"

    itemFrame:SetPoint(anchorPoint, BuffIconCooldownViewer, anchorPoint, x, y)
  end
end

