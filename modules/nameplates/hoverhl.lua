local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local NP = E:GetModule('NamePlates')

local hooksecurefunc = hooksecurefunc
local CreateFrame = CreateFrame

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

function TUI:HookHoverHighlight()
	if self._hookedHoverHL then return end
	self._hookedHoverHL = true

	hooksecurefunc(NP, 'Update_Highlight', function(_, nameplate)
		if not nameplate or not nameplate.Highlight then return end

		local hlDB = TUI.db.profile.nameplates.hoverHighlight
		if not hlDB or not hlDB.enabled then return end

		local hl = nameplate.Highlight
		-- Hide the default texture overlay
		if hl.texture then hl.texture:SetAlpha(0) end

		if not hl.TUI_BorderHooked then
			hl.TUI_BorderHooked = true

			local border = GetOrCreateBorderFrame(nameplate)
			if not border then return end

			hooksecurefunc(hl, 'Show', function()
				local bf = nameplate.TUI_HoverBorder
				if bf then
					ApplyBorderStyle(bf, nameplate)
					bf:Show()
				end
			end)

			hooksecurefunc(hl, 'Hide', function()
				local bf = nameplate.TUI_HoverBorder
				if bf then bf:Hide() end
			end)
		end
	end)
end
