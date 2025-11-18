local _, ns = ...
local LSM = LibStub("LibSharedMedia-3.0")
local LEM = LibStub('LibEditMode')
local WilduUI = {}

local API = ns.API
ns.WilduUI = WilduUI 


local rangeFrame = CreateFrame("Frame", "WilduTools Range Frame", UIParent)
function WilduUI.InitilizeRangeFrame()
	if rangeFrame._wt_initialized then
		return
	end
	rangeFrame._wt_initialized = true
	rangeFrame:SetSize(120, 24)
	rangeFrame:SetPoint("CENTER", ns.Addon.db.profile.editMode.rangeCheck.x or 0, ns.Addon.db.profile.editMode.rangeCheck.y or 0)
	rangeFrame:SetScale(ns.Addon.db.profile.editMode.rangeCheck.scale or 1)

	rangeFrame.text = rangeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	rangeFrame.text:SetPoint("LEFT", rangeFrame, "LEFT")
	rangeFrame.text:SetText("No Target")
	rangeFrame._throttle = 0
	rangeFrame:Show()
	rangeFrame:SetScript("OnUpdate", function(self)
		if GetTime() < self._throttle then
			return
		end
		if ns.Addon.db.profile.wilduUI_targetRangeFrame then 
			rangeFrame._throttle = GetTime() + 0.1
		else
			rangeFrame._throttle = GetTime() + 1
		end

		if ns.Addon.db.profile.wilduUI_targetRangeFrame then
			rangeFrame:SetAlpha(1)
			if not LEM:IsInEditMode() then
				if UnitExists("target") and not UnitIsDeadOrGhost("target") then
					local min, max = API:GetRange("target", true)
					if min or max then
						if max then
							rangeFrame.text:SetText(tostring(tostring(min) .. " - " .. tostring(max)))
						else 
							rangeFrame.text:SetText(tostring(min).. "+")
						end
					else
						-- TODO more debugging data
						-- ns.Addon:Print("Range check error:", result)
					end
				else
					rangeFrame.text:SetText("")
				end
			end
		else
			rangeFrame.text:SetText("")
			rangeFrame:SetAlpha(0)
		end
	end)
	

	local defaultPosition = {
		point = 'CENTER',
		x = 0,
		y = 0,
	}

	local function onPositionChanged(frame, layoutName, point, x, y)
		ns.Addon.db.profile.editMode.rangeCheck.point = point
		ns.Addon.db.profile.editMode.rangeCheck.x = x
		ns.Addon.db.profile.editMode.rangeCheck.y = y
	end


	LEM:RegisterCallback('enter', function()
		rangeFrame.text:SetText("12-15")
		if ns.Addon.db.profile.wilduUI_targetRangeFrame then
			rangeFrame:SetPoint("CENTER",UIParent,ns.Addon.db.profile.editMode.rangeCheck.point, ns.Addon.db.profile.editMode.rangeCheck.x, ns.Addon.db.profile.editMode.rangeCheck.y)
		else
			rangeFrame:SetPoint("TOP", UIParent, "TOP", 0, -500)
		end
	end)
	LEM:RegisterCallback('exit', function()
		-- from here you can hide your button if it's supposed to be hidden
	end)
	LEM:RegisterCallback('layout', function(layoutName)
		-- this will be called every time the Edit Mode layout is changed (which also happens at login),
		-- use it to load the saved button position from savedvariables and position it
		if not ns.Addon.db.profile.editMode.rangeCheck then
			ns.Addon.db.profile.editMode.rangeCheck = CopyTable(defaultPosition)
		end

		rangeFrame:ClearAllPoints()
		if ns.Addon.db.profile.wilduUI_targetRangeFrame then
			rangeFrame:SetPoint("CENTER",UIParent,ns.Addon.db.profile.editMode.rangeCheck.point, ns.Addon.db.profile.editMode.rangeCheck.x, ns.Addon.db.profile.editMode.rangeCheck.y)
		else
			rangeFrame:SetPoint("TOP", UIParent, "TOP", 0, -500)
		end
		-- rangeFrame:SetPoint(ns.Addon.db.profile.editMode.rangeCheck.point, ns.Addon.db.profile.editMode.rangeCheck.x, ns.Addon.db.profile.editMode.rangeCheck.y)
	end)

	LEM:AddFrame(rangeFrame, onPositionChanged, defaultPosition)
	LEM:AddFrameSettings(rangeFrame, {
		{
			name = 'Scale',
			kind = LEM.SettingType.Slider,
			default = 1,
			get = function(layoutName)
				return ns.Addon.db.profile.editMode.rangeCheck.scale
			end,
			set = function(layoutName, value)
				ns.Addon.db.profile.editMode.rangeCheck.scale = value
				rangeFrame:SetScale(value)
			end,
			minValue = 0.1,
			maxValue = 5,
			valueStep = 0.1,
			formatter = function(value)
				return FormatPercentage(value, true)
			end,
		}
	})

end

-- Mountable area icon
local mountFrame = CreateFrame("Frame", "WilduTools Mount Frame", UIParent)
function WilduUI.InitilizeMountableAreaIndicator()
	if mountFrame._wt_initialized then
		return
	end
	mountFrame._wt_initialized = true
	mountFrame:SetSize(32, 32)
	mountFrame:SetPoint("CENTER", ns.Addon.db.profile.editMode.mountIcon.x or 0, ns.Addon.db.profile.editMode.mountIcon.y or 0)
	mountFrame:SetScale(ns.Addon.db.profile.editMode.mountIcon.scale or 1)

	mountFrame.icon = mountFrame:CreateTexture(nil, "OVERLAY")
	mountFrame.icon:SetAllPoints(mountFrame)
	mountFrame.icon:SetAtlas("Fyrakk-Flying-Icon", true)
	mountFrame.icon:SetAlpha(0)

	mountFrame._throttle = 0
	mountFrame:Show()
	mountFrame:SetScript("OnUpdate", function(self)
		if GetTime() < self._throttle then
			return
		end
		self._throttle = GetTime() + 0.25

		if not ns.Addon.db.profile.wilduUI_mountableArea  then
			self.icon:SetAlpha(0)
			return
		end

		-- Simple can-mount checks
		local canMount = C_Spell.IsSpellUsable(150544)

		if canMount then
			self.icon:SetAlpha(1)
		else
			self.icon:SetAlpha(0)
		end
	end)

	local defaultPosition = {
		point = 'CENTER',
		x = 0,
		y = 50,
	}

	local function onPositionChanged(frame, layoutName, point, x, y)
		ns.Addon.db.profile.editMode.mountIcon.point = point
		ns.Addon.db.profile.editMode.mountIcon.x = x
		ns.Addon.db.profile.editMode.mountIcon.y = y
	end

	LEM:RegisterCallback('enter', function()
		if ns.Addon.db.profile.wilduUI_mountableArea or true then
			mountFrame:SetPoint("CENTER",UIParent,ns.Addon.db.profile.editMode.mountIcon.point, ns.Addon.db.profile.editMode.mountIcon.x, ns.Addon.db.profile.editMode.mountIcon.y)
		else
			mountFrame:SetPoint("TOP", UIParent, "TOP", 0, -500)
		end
	end)
	LEM:RegisterCallback('exit', function()
	end)
	LEM:RegisterCallback('layout', function(layoutName)
		if not ns.Addon.db.profile.editMode.mountIcon then
			ns.Addon.db.profile.editMode.mountIcon = CopyTable(defaultPosition)
		end

		mountFrame:ClearAllPoints()
		if ns.Addon.db.profile.wilduUI_mountableArea or true then
			mountFrame:SetPoint("CENTER",UIParent,ns.Addon.db.profile.editMode.mountIcon.point, ns.Addon.db.profile.editMode.mountIcon.x, ns.Addon.db.profile.editMode.mountIcon.y)
		else
			mountFrame:SetPoint("TOP", UIParent, "TOP", 0, -500)
		end
	end)

	LEM:AddFrame(mountFrame, onPositionChanged, defaultPosition)
	LEM:AddFrameSettings(mountFrame, {
		{
			name = 'Scale',
			kind = LEM.SettingType.Slider,
			default = 1,
			get = function(layoutName)
				return ns.Addon.db.profile.editMode.mountIcon.scale
			end,
			set = function(layoutName, value)
				ns.Addon.db.profile.editMode.mountIcon.scale = value
				mountFrame:SetScale(value)
			end,
			minValue = 0.1,
			maxValue = 5,
			valueStep = 0.1,
			formatter = function(value)
				return FormatPercentage(value, true)
			end,
		}
	})
end
