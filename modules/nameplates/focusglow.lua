local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local NP = E:GetModule('NamePlates')

local LSM = E.Libs.LSM
local CreateFrame = CreateFrame
local ipairs = ipairs
local C_NamePlate_GetNamePlates = C_NamePlate.GetNamePlates
local C_NamePlate_GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit

local function GetOrCreateFocusOverlay(nameplate)
	if nameplate.TUI_FocusOverlay then
		return nameplate.TUI_FocusOverlay, nameplate.TUI_FocusOverlayTex
	end

	local holder = CreateFrame('Frame', nil, nameplate.Health)
	holder:SetAllPoints(nameplate.Health)
	holder:SetFrameLevel(9)

	local overlay = holder:CreateTexture(nil, 'OVERLAY')
	overlay:SetAllPoints(holder)
	overlay:SetBlendMode('BLEND')
	holder:Hide()

	nameplate.TUI_FocusOverlay = holder
	nameplate.TUI_FocusOverlayTex = overlay
	return holder, overlay
end

local function UpdateFocusOverlay(nameplate)
	local db = TUI.db.profile.nameplates.focusGlow
	if not nameplate.unit or not nameplate.Health then return end

	if E:UnitIsUnit(nameplate.unit, 'focus') then
		local holder, tex = GetOrCreateFocusOverlay(nameplate)
		tex:SetTexture(LSM:Fetch('statusbar', db.texture or NP.db.statusbar))
		local c = db.color
		tex:SetVertexColor(c.r, c.g, c.b, c.a or 0.3)
		holder:Show()
	elseif nameplate.TUI_FocusOverlay then
		nameplate.TUI_FocusOverlay:Hide()
	end
end

local function UpdateAllFocusOverlays()
	for _, nameplate in ipairs(C_NamePlate_GetNamePlates()) do
		if nameplate.unitFrame then
			UpdateFocusOverlay(nameplate.unitFrame)
		end
	end
end

function TUI:InitFocusGlow()
	if self._initFocusGlow then return end
	self._initFocusGlow = true

	TUI:RegisterEvent('PLAYER_FOCUS_CHANGED', UpdateAllFocusOverlays)
	TUI:RegisterEvent('NAME_PLATE_UNIT_ADDED', function(_, unit)
		local nameplate = C_NamePlate_GetNamePlateForUnit(unit)
		if nameplate and nameplate.unitFrame then
			UpdateFocusOverlay(nameplate.unitFrame)
		end
	end)
	TUI:RegisterEvent('NAME_PLATE_UNIT_REMOVED', function(_, unit)
		local nameplate = C_NamePlate_GetNamePlateForUnit(unit)
		if nameplate and nameplate.unitFrame and nameplate.unitFrame.TUI_FocusOverlay then
			nameplate.unitFrame.TUI_FocusOverlay:Hide()
		end
	end)
end
