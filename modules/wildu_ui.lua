local _, ns = ...
local LSM = LibStub("LibSharedMedia-3.0")
local LEM = LibStub('LibEditMode')
local WilduUI = {}

local API = ns.API
ns.WilduUI = WilduUI 
local DEBUG = ns.DEBUG


local rangeFrame = CreateFrame("Frame", "WilduTools Range Frame", UIParent)
function WilduUI.InitilizeRangeFrame()
	DEBUG.startDebugTimer("WILDUUI_INIT_RANGEFRAME_START")
	if rangeFrame._wt_initialized then
		return
	end
	rangeFrame._wt_initialized = true
	rangeFrame:SetSize(120, 24)
	local rangeEdit = (ns.Addon.db.profile.editMode and ns.Addon.db.profile.editMode.rangeCheck) or { point = 'CENTER', x = 0, y = 0, scale = 1 }
	rangeFrame:SetPoint("CENTER", UIParent, rangeEdit.point or 'CENTER', rangeEdit.x or 0, rangeEdit.y or 0)
	rangeFrame:SetScale(rangeEdit.scale or 1)

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
	DEBUG.checkpointDebugTimer("WILDUUI_INIT_RANGEFRAME_DONE", "WILDUUI_INIT_RANGEFRAME_START")

end

-- Mountable area icon
local mountFrame = CreateFrame("Frame", "WilduTools Mount Frame", UIParent)
function WilduUI.InitilizeMountableAreaIndicator()
	DEBUG.startDebugTimer("WILDUUI_INIT_MOUNTFRAME_START")
	if mountFrame._wt_initialized then
		return
	end
	mountFrame._wt_initialized = true
	mountFrame:SetSize(32, 32)
	local mountEdit = (ns.Addon.db.profile.editMode and ns.Addon.db.profile.editMode.mountIcon) or { point = 'CENTER', x = 0, y = 50, scale = 1 }
	mountFrame:SetPoint("CENTER", UIParent, mountEdit.point or 'CENTER', mountEdit.x or 0, mountEdit.y or 50)
	mountFrame:SetScale(mountEdit.scale or 1)

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

		if not ns.Addon.db.profile.wilduUI_mountableArea then
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
		if ns.Addon.db.profile.wilduUI_mountableArea then
			mountFrame:SetPoint("CENTER", UIParent, ns.Addon.db.profile.editMode.mountIcon.point, ns.Addon.db.profile.editMode.mountIcon.x, ns.Addon.db.profile.editMode.mountIcon.y)
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
		if ns.Addon.db.profile.wilduUI_mountableArea then
			mountFrame:SetPoint("CENTER", UIParent, ns.Addon.db.profile.editMode.mountIcon.point, ns.Addon.db.profile.editMode.mountIcon.x, ns.Addon.db.profile.editMode.mountIcon.y)
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
	DEBUG.checkpointDebugTimer("WILDUUI_INIT_MOUNTFRAME_DONE", "WILDUUI_INIT_MOUNTFRAME_START")
end


local spellOnCDFrame = CreateFrame("Frame", "WilduTools_SpellOnCD", UIParent)
spellOnCDFrame:SetSize(30, 30)
spellOnCDFrame:SetPoint("CENTER", _parentForSpellCd, "CENTER", 0, 0)
spellOnCDFrame:SetScale(1)

spellOnCDFrame.icon = spellOnCDFrame:CreateTexture(nil, "OVERLAY")
spellOnCDFrame.icon:SetAllPoints()

spellOnCDFrame.cooldown = CreateFrame("Cooldown", nil, spellOnCDFrame, "CooldownFrameTemplate")
spellOnCDFrame.cooldown:SetAllPoints()

spellOnCDFrame:SetAlpha(0)
spellOnCDFrame._timer = nil
spellOnCDFrame._timer_iterations = 0

-- optional event-driven spell-on-cooldown alert
local spellOnCDEventFrame = nil

function WilduUI.InitilizeSpellOnCD()
	if spellOnCDFrame._wt_initialized then return end
	spellOnCDFrame._wt_initialized = true

	if not ns.Addon.db.profile.editMode then ns.Addon.db.profile.editMode = {} end
	if not ns.Addon.db.profile.editMode.spellOnCD then
		ns.Addon.db.profile.editMode.spellOnCD = { point = 'CENTER', x = 0, y = 0, scale = 1, alpha = 1, zoom = 0 }
	end

	local e = ns.Addon.db.profile.editMode.spellOnCD
	spellOnCDFrame:ClearAllPoints()
	spellOnCDFrame:SetPoint("CENTER", UIParent, e.point or 'CENTER', e.x or 0, e.y or 0)
	spellOnCDFrame:SetScale(e.scale or 1)
	spellOnCDFrame:SetAlpha(e.alpha or 1)
	local zoom = e.zoom or 0

	if not ns.Addon.db.profile.editMode.spellOnCD then
		ns.Addon.db.profile.editMode.spellOnCD = { point = 'CENTER', x = 0, y = 0, scale = 1, alpha = 1, zoom = 0 }
	end


	if spellOnCDFrame.icon then
		local left = (zoom or 0) / 2
		local right = 1 - (zoom or 0) / 2
		spellOnCDFrame.icon:SetTexCoord(left, right, left, right)
	end

	-- Register with LEM
	LEM:AddFrame(spellOnCDFrame, function(frame, layoutName, point, x, y)
		ns.Addon.db.profile.editMode.spellOnCD.point = point
		ns.Addon.db.profile.editMode.spellOnCD.x = x
		ns.Addon.db.profile.editMode.spellOnCD.y = y
	end, ns.Addon.db.profile.editMode.spellOnCD)

	LEM:AddFrameSettings(spellOnCDFrame, {
		{
			name = 'Scale',
			kind = LEM.SettingType.Slider,
			default = 1,
			get = function(layoutName) return ns.Addon.db.profile.editMode.spellOnCD.scale end,
			set = function(layoutName, value) ns.Addon.db.profile.editMode.spellOnCD.scale = value; spellOnCDFrame:SetScale(value) end,
			minValue = 0.1, maxValue = 5, valueStep = 0.1,
			formatter = function(value) return FormatPercentage(value, true) end,
		},
		{
			name = 'Alpha',
			kind = LEM.SettingType.Slider,
			default = 1,
			get = function(layoutName) return ns.Addon.db.profile.editMode.spellOnCD.alpha end,
			set = function(layoutName, value) ns.Addon.db.profile.editMode.spellOnCD.alpha = value; spellOnCDFrame:SetAlpha(value) end,
			minValue = 0, maxValue = 1, valueStep = 0.01,
			formatter = function(value) return string.format("%.2f", value) end,
		},
		{
			name = 'Zoom (%)', kind = LEM.SettingType.Slider, default = 0,
			get = function(layoutName) return (ns.Addon.db.profile.editMode.spellOnCD.zoom or 0) * 100 end,
			set = function(layoutName, value)
				ns.Addon.db.profile.editMode.spellOnCD.zoom = (value or 0) / 100
				local z = ns.Addon.db.profile.editMode.spellOnCD.zoom or 0
				local left = z / 2
				local right = 1 - z / 2
				if spellOnCDFrame.icon then spellOnCDFrame.icon:SetTexCoord(left, right, left, right) end
			end,
			minValue = 0, maxValue = 50, valueStep = 1,
			formatter = function(v) return tostring(v) .. "%" end,
		}
	})

	-- event handler
	spellOnCDEventFrame = CreateFrame("Frame", "WilduTools_SpellOnCD_Event", UIParent)
	spellOnCDEventFrame:RegisterEvent("UNIT_SPELLCAST_FAILED")
	spellOnCDEventFrame:SetScript("OnEvent", function(self, event, unitTarget, _castGUIDISNIL, spellID)
		if not ns.Addon.db.profile.wilduUI_spellOnCD then return end
		if unitTarget ~= "player" then return end

		local spell = C_Spell.GetSpellInfo(spellID)
		if spell and spell.iconID then
			spellOnCDFrame.icon:SetTexture(spell.iconID)
			-- apply current zoom setting
			local z = ns.Addon.db.profile.editMode.spellOnCD and ns.Addon.db.profile.editMode.spellOnCD.zoom or 0
			local left = (z or 0) / 2
			local right = 1 - (z or 0) / 2
			spellOnCDFrame.icon:SetTexCoord(left, right, left, right)

		end

		local cooldownInfo = C_Spell.GetSpellCooldown(spellID)
		if cooldownInfo then
			spellOnCDFrame.icon:SetAlpha(1)
			spellOnCDFrame.cooldown:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration)
		end

		if spellOnCDFrame._timer then spellOnCDFrame._timer:Cancel(); spellOnCDFrame._timer = nil; spellOnCDFrame._timer_iterations = 0 end
		
		spellOnCDFrame._timer = C_Timer.NewTicker(0.025, function()
			spellOnCDFrame._timer_iterations = spellOnCDFrame._timer_iterations + 1
			local a = math.min(4 - (spellOnCDFrame._timer_iterations / 10),1)
			spellOnCDFrame.icon:SetAlpha(a)
			spellOnCDFrame.cooldown:SetAlpha(a)
			if a <= 0 then 
				spellOnCDFrame.cooldown:Clear()
			end
		end, 40)
	end)
end



function WilduUI.InitilizeCrosshair()
	-- create crosshair on demand to avoid global UI objects when disabled
	if WilduTools_Crosshair and WilduTools_Crosshair.parent and WilduTools_Crosshair.parent._wt_initialized then return end

	-- ensure editMode defaults exist
	if not ns.Addon.db.profile.editMode then ns.Addon.db.profile.editMode = {} end
	if not ns.Addon.db.profile.editMode.crosshair then ns.Addon.db.profile.editMode.crosshair = { point = 'CENTER', x = 0, y = 0, scale = 1, alpha = 1, thickness = 4, inner_length = 24, border_size = 4, class_colored = true } end
	local e = ns.Addon.db.profile.editMode.crosshair

	local thickness = e.thickness or 4
	local inner_length = e.inner_length or 24
	local alpha = e.alpha
	local border_size = e.border_size or 4
	local class_colored = (e.class_colored == nil) and true or e.class_colored

	-- create parent frame
	local parent = CreateFrame("Frame", "WilduTools_CrosshairParent", UIParent)
	parent:SetSize(inner_length + thickness + border_size, inner_length + thickness + border_size)
	parent:SetPoint("CENTER", UIParent, e.point or 'CENTER', e.x or 0, e.y or 0)
	parent:EnableMouse(false)

	local function getClassColor()
		local _, class = UnitClass("player")
		local cc = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class]) or RAID_CLASS_COLORS[class]
		if cc then
			return cc.r, cc.g, cc.b
		end
		return 1, 1, 1
	end

	local function makeBar(name, width, height, point, relPoint, x, y, level)
		local f = CreateFrame("Frame", name, parent)
		f:SetSize(width, height)
		f:SetPoint(point, parent, relPoint, x, y)
		f:EnableMouse(false)
		local t = f:CreateTexture(nil, "BACKGROUND")
		t:SetDrawLayer("BACKGROUND",level)
		t:SetAllPoints()
		f.tex = t
		return f
	end

	-- Create bars (outer uses border_size extra)
	local outerVertical = makeBar("Wildu_CrossOuterVertical", thickness + border_size, inner_length + border_size, "CENTER", "CENTER", 0, 0, 0)
	local outerHorizontal = makeBar("Wildu_CrossOuterHorizontal", inner_length + border_size, thickness + border_size, "CENTER", "CENTER", 0, 0, 0)
	local innerVertical = makeBar("Wildu_CrossInnerVertical", thickness, inner_length, "CENTER", "CENTER", 0, 0, 1)
	local innerHorizontal = makeBar("Wildu_CrossInnerHorizontal", inner_length, thickness, "CENTER", "CENTER", 0, 0, 1)

	-- initial coloring
	do local rr, gg, bb = getClassColor()
		if class_colored then
			innerVertical.tex:SetColorTexture(rr, gg, bb, alpha)
			innerHorizontal.tex:SetColorTexture(rr, gg, bb, alpha)
		else
			innerVertical.tex:SetColorTexture(1, 1, 1, alpha)
			innerHorizontal.tex:SetColorTexture(1, 1, 1, alpha)
		end
	end
	outerHorizontal.tex:SetColorTexture(0, 0, 0, alpha)
	outerVertical.tex:SetColorTexture(0, 0, 0, alpha)

	WilduTools_Crosshair = {
		UpdateColor = function()
			local rr, gg, bb = getClassColor()
			local a = alpha
			local class_colored_now = ns.Addon.db.profile.editMode.crosshair.class_colored
			if class_colored_now == nil or class_colored_now then
				innerVertical.tex:SetColorTexture(rr, gg, bb, a)
				innerHorizontal.tex:SetColorTexture(rr, gg, bb, a)
			else
				innerVertical.tex:SetColorTexture(1, 1, 1, a)
				innerHorizontal.tex:SetColorTexture(1, 1, 1, a)
			end
			-- outer border alpha
			outerHorizontal.tex:SetColorTexture(0, 0, 0, a)
			outerVertical.tex:SetColorTexture(0, 0, 0, a)
		end,
	}

	-- update color on login (in case class color table not available earlier)
	local ev = CreateFrame("Frame")
	ev:RegisterEvent("PLAYER_LOGIN")
	ev:SetScript("OnEvent", function()
		WilduTools_Crosshair.UpdateColor()
		ev:UnregisterAllEvents()
	end)

	-- Register with LEM for position persistence
	LEM:AddFrame(parent, function(frame, layoutName, point, x, y)
		ns.Addon.db.profile.editMode.crosshair.point = point
		ns.Addon.db.profile.editMode.crosshair.x = x
		ns.Addon.db.profile.editMode.crosshair.y = y
	end, ns.Addon.db.profile.editMode.crosshair)

	-- LEM settings: scale, alpha, thickness, inner_length, border_size, class_colored
	LEM:AddFrameSettings(parent, {
		{
			name = 'Scale', kind = LEM.SettingType.Slider, default = 1,
			get = function() return ns.Addon.db.profile.editMode.crosshair.scale end,
			set = function(_, v) ns.Addon.db.profile.editMode.crosshair.scale = v; parent:SetScale(v) end,
			minValue = 0.1, maxValue = 5, valueStep = 0.1, formatter = function(v) return FormatPercentage(v, true) end,
		},
		{
			name = 'Alpha', kind = LEM.SettingType.Slider, default = 1,
			get = function() return ns.Addon.db.profile.editMode.crosshair.alpha end,
			set = function(_, v)
				ns.Addon.db.profile.editMode.crosshair.alpha = v
				local rr, gg, bb = getClassColor()
				local class_col = ns.Addon.db.profile.editMode.crosshair.class_colored
				if class_col == nil or class_col then
					innerVertical.tex:SetColorTexture(rr, gg, bb, v)
					innerHorizontal.tex:SetColorTexture(rr, gg, bb, v)
				else
					innerVertical.tex:SetColorTexture(1, 1, 1, v)
					innerHorizontal.tex:SetColorTexture(1, 1, 1, v)
				end
				outerHorizontal.tex:SetColorTexture(0, 0, 0, v)
				outerVertical.tex:SetColorTexture(0, 0, 0, v)
			end,
			minValue = 0, maxValue = 1, valueStep = 0.01, formatter = function(v) return string.format("%.2f", v) end,
		},
		{
			name = 'Thickness', kind = LEM.SettingType.Slider, default = 6,
			get = function() return ns.Addon.db.profile.editMode.crosshair.thickness end,
			set = function(_, v)
				ns.Addon.db.profile.editMode.crosshair.thickness = v
				local b = ns.Addon.db.profile.editMode.crosshair.border_size or border_size
				local il = ns.Addon.db.profile.editMode.crosshair.inner_length or inner_length
				innerVertical:SetSize(v, il)
				innerHorizontal:SetSize(il, v)
				outerVertical:SetSize(v + b, il + b)
				outerHorizontal:SetSize(il + b, v + b)
			end,
			minValue = 1, maxValue = 32, valueStep = 1,
		},
		{
			name = 'Inner length', kind = LEM.SettingType.Slider, default = 24,
			get = function() return ns.Addon.db.profile.editMode.crosshair.inner_length end,
			set = function(_, v)
				ns.Addon.db.profile.editMode.crosshair.inner_length = v
				local t = ns.Addon.db.profile.editMode.crosshair.thickness or thickness
				local b = ns.Addon.db.profile.editMode.crosshair.border_size or border_size
				innerVertical:SetSize(t, v)
				innerHorizontal:SetSize(v, t)
				outerVertical:SetSize(t + b, v + b)
				outerHorizontal:SetSize(v + b, t + b)
			end,
			minValue = 4, maxValue = 256, valueStep = 1,
		},
		{
			name = 'Border size', kind = LEM.SettingType.Slider, default = 4,
			get = function() return ns.Addon.db.profile.editMode.crosshair.border_size end,
			set = function(_, v)
				ns.Addon.db.profile.editMode.crosshair.border_size = v
				local t = ns.Addon.db.profile.editMode.crosshair.thickness or thickness
				local il = ns.Addon.db.profile.editMode.crosshair.inner_length or inner_length
				outerVertical:SetSize(t + v, il + v)
				outerHorizontal:SetSize(il + v, t + v)
			end,
			minValue = 0, maxValue = 64, valueStep = 1,
		},
		{
			name = 'Class colored', kind = LEM.SettingType.Checkbox, default = true,
			get = function() return ns.Addon.db.profile.editMode.crosshair.class_colored end,
			set = function(_, v)
				ns.Addon.db.profile.editMode.crosshair.class_colored = v
				WilduTools_Crosshair.UpdateColor()
			end,
		}
	})

	parent._wt_initialized = true
end