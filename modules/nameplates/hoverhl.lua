local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local NP = E:GetModule('NamePlates')

local UnitExists = UnitExists
local C_NamePlate_GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit

local EDGE_FILE = [[Interface\BUTTONS\WHITE8X8]]
local backdropInfo = { edgeFile = EDGE_FILE, edgeSize = 2 }

local function GetOrCreateBorderFrame(nameplate)
	if nameplate.TUI_HoverBorder then return nameplate.TUI_HoverBorder end

	local health = nameplate.Health
	if not health then return nil end

	local border = CreateFrame('Frame', nil, health, 'BackdropTemplate')
	border:SetFrameLevel(health:GetFrameLevel() + 10)
	border:Hide()

	nameplate.TUI_HoverBorder = border
	return border
end

local function ApplyBorderStyle(border, nameplate)
	local db = TUI.db.profile.nameplates.hoverHighlight
	local thickness = db.thickness or 1

	border:ClearAllPoints()
	border:SetPoint('TOPLEFT', nameplate.Health, -thickness, thickness)
	border:SetPoint('BOTTOMRIGHT', nameplate.Health, thickness, -thickness)

	backdropInfo.edgeSize = thickness
	border:SetBackdrop(backdropInfo)

	local r, g, b, a
	if db.classColor then
		local c = E:ClassColor(E.myclass)
		r, g, b, a = c.r, c.g, c.b, db.color.a
	else
		r, g, b, a = db.color.r, db.color.g, db.color.b, db.color.a
	end
	border:SetBackdropBorderColor(r, g, b, a)
end

local function ShowBorder(nameplate)
	local border = nameplate.TUI_HoverBorder
	if border then
		ApplyBorderStyle(border, nameplate)
		border:Show()
	end
end

local function HideBorder(nameplate)
	local border = nameplate.TUI_HoverBorder
	if border then border:Hide() end
end

function TUI:HookHoverHighlight()
	if self._hookedHoverHL then return end
	self._hookedHoverHL = true

	hooksecurefunc(NP, 'Update_Highlight', function(_, nameplate)
		if not nameplate or not nameplate.Highlight then return end

		local hlDB = TUI.db.profile.nameplates.hoverHighlight
		if not hlDB or not hlDB.enabled then return end

		local hl = nameplate.Highlight
		if hl.texture then hl.texture:SetAlpha(0) end

		if not hl.TUI_BorderHooked then
			hl.TUI_BorderHooked = true

			GetOrCreateBorderFrame(nameplate)

			hooksecurefunc(hl, 'Show', function()
				ShowBorder(nameplate)
			end)

			hooksecurefunc(hl, 'Hide', function()
				HideBorder(nameplate)
			end)
		end

		-- Sync border to current highlight state
		if hl:IsShown() then
			ShowBorder(nameplate)
		else
			HideBorder(nameplate)
		end
	end)

	-- Re-check mouseover after target change (mouseover unit briefly clears on click)
	TUI:RegisterEvent('PLAYER_TARGET_CHANGED', function()
		C_Timer.After(0.05, function()
			if not UnitExists('mouseover') then return end
			local plate = C_NamePlate_GetNamePlateForUnit('mouseover')
			if not plate or not plate.unitFrame then return end
			local nameplate = plate.unitFrame
			local hl = nameplate.Highlight
			if hl and hl:IsShown() then
				ShowBorder(nameplate)
			end
		end)
	end)
end
