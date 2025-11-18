local _, ns = ...
local addon = ns.Addon

local Minimap = {}
local DEBUG = ns.DEBUG

function Minimap:Init(db)
	DEBUG.startDebugTimer("MINIMAP_INIT_START")
    self.db = db
	if self._wt_minimap_init then return true end
	self._wt_minimap_init = true
    local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
    local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
    local saved = _G.WilduToolsDB or (db and db.char) or (db and db.profile) or db

    if not LDB or not LDBIcon then
        return false, "missing_libs"
    end

    local iconPath = "Interface\\AddOns\\!WilduTools\\media\\wildutools"

	-- prepare an anchor frame for showing the Blizzard-style menu via addon.API
	if not Minimap.anchorFrame then
		Minimap.anchorFrame = CreateFrame("Frame", "WilduToolsMinimapAnchor", UIParent)
		Minimap.anchorFrame:SetSize(24, 24)
	end

	local function ShowMenu(widget)
		local isDead = UnitIsDeadOrGhost("player")

		local ButtonMenu = {
			tag = "WilduToolsMinimapMenu",
			objects = {
				{
					type = "Button",
					name = "Open Addon Settings",
					OnClick = function()
						if addon and addon.ShowConfig then
							addon:ShowConfig()
						end
					end,
				},
				{
					type = "Button",
					name = "Open Plumber Landing Page",
					IsEnabledFunc = function()
						return Plumber_ToggleLandingPage ~= nil
					end,
					OnClick = function()
						if Plumber_ToggleLandingPage then
							Plumber_ToggleLandingPage()
						end
					end,
				},
				{ type = "Divider" },
				{
					type = "Button",
					name = "Reload UI",
					OnClick = function()
						ReloadUI()
					end,
				},
				{
					type = "Button",
					name = "Release Character",
					IsEnabledFunc = function()
						return isDead
					end,
					tooltip = "/run AcceptResurrect() RetrieveCorpse() RepopMe()",
					OnClick = function()
						if isDead then
							if AcceptResurrect then
								AcceptResurrect()
							end
							if RetrieveCorpse then
								RetrieveCorpse()
							end
							if RepopMe then
								RepopMe()
							end
						end
					end,
				},
			},
		}
		-- if no plumber, remove the landing page button

		local contextData = {}

		ns.API.ShowBlizzardMenu(widget or Minimap.anchorFrame, ButtonMenu, contextData)

	end

	local obj = LDB:NewDataObject("WilduTools", {
        type = "launcher",
        icon = iconPath,
        tip  = "WilduTools",
        OnClick = function(_, button)
			if button == "LeftButton" and IsShiftKeyDown() then
				if ns.db.profile.general_minimapButtonOnClickShiftAction == "Plumber" then
					if Plumber_ToggleLandingPage then
						Plumber_ToggleLandingPage()
					else
						addon:ShowConfig()
					end
				elseif ns.db.profile.general_minimapButtonOnClickShiftAction == "Reload" then
					ReloadUI()
				else
					addon:ShowConfig()
				end
			elseif button == "LeftButton" then
				if ns.db.profile.general_minimapButtonOnClickAction == "Plumber" then
					if Plumber_ToggleLandingPage then
						Plumber_ToggleLandingPage()
					else
						addon:ShowConfig()
					end
				elseif ns.db.profile.general_minimapButtonOnClickAction == "Reload" then
					ReloadUI()
				else
					addon:ShowConfig()
				end
			elseif button == "RightButton" then
				ShowMenu(Minimap.anchorFrame)
			end
        end,
        OnTooltipShow = function(tt)
            if tt and tt.AddLine then
			tt:AddLine("WilduTools")
			local instructions = {
				Settings = "Open WilduTools settings",
				Plumber = "Open Plumber landing page",
				Reload = "Reload UI",
			}
			tt:AddLine("Left-click: "..instructions[ns.db.profile.general_minimapButtonOnClickAction], 0.6, 0.8, 1)
			tt:AddLine("Shit + Click: "..instructions[ns.db.profile.general_minimapButtonOnClickShiftAction], 0.6, 0.8, 1)
			
			tt:AddLine("Right-click: Open menu", 0.6, 0.8, 1)
            end
        end,
    })

	LDBIcon:Register("WilduTools", obj, saved)


	self.obj = obj
	DEBUG.checkpointDebugTimer("MINIMAP_INIT_DONE", "MINIMAP_INIT_START")
	return true
end

ns.Minimap = Minimap

return Minimap
