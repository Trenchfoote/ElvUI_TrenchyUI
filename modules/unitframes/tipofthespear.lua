local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local UF = E:GetModule('UnitFrames')
local LSM = E.Libs.LSM

local hooksecurefunc = hooksecurefunc
local GetSpecialization = GetSpecialization
local UnitClass = UnitClass
local CreateFrame = CreateFrame
local GetPlayerAuraBySpellID = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID

local TOTS_BUFF_ID = 260286
local TOTS_MAX_STACKS = 3

local totsBar, totsHolder, totsEventFrame
local totsCells = {}

local function GetClassBarDB()
	return E.db.unitframe and E.db.unitframe.units and E.db.unitframe.units.player and E.db.unitframe.units.player.classbar
end

local function UpdateTOTSColors()
	if not totsBar then return end

	local custom_backdrop = UF.db.colors.customclasspowerbackdrop and UF.db.colors.classpower_backdrop
	local c = TUI.db.profile.fakePower.tipOfTheSpearColor or { r = 0.89, g = 0.49, b = 0.04 }

	for i = 1, TOTS_MAX_STACKS do
		local cell = totsCells[i]
		if cell then
			UF:SetStatusBarColor(cell, c.r, c.g, c.b, custom_backdrop)
		end
	end
end

local function UpdateTOTS()
	if not totsBar then return end

	local aura = GetPlayerAuraBySpellID and GetPlayerAuraBySpellID(TOTS_BUFF_ID)
	local current = aura and aura.applications or 0

	for i = 1, TOTS_MAX_STACKS do
		local cell = totsCells[i]
		if cell then
			cell:SetMinMaxValues(i - 1, i)
			cell:SetValue(current)
		end
	end

	UpdateTOTSColors()
end

local function LayoutTOTS()
	if not totsBar or not totsHolder then return end

	local cbdb = GetClassBarDB()
	if not cbdb then return end

	local BORDER = UF.BORDER or 2
	local UISPACING = UF.SPACING or 1
	local SPACING = (BORDER + UISPACING) * 2

	local playerFrame = UF.player
	local CLASSBAR_WIDTH
	if playerFrame and playerFrame.CLASSBAR_DETACHED then
		CLASSBAR_WIDTH = cbdb.detachedWidth or 250
	elseif playerFrame and playerFrame.USE_MINI_CLASSBAR then
		local baseW = E:Scale(playerFrame.CLASSBAR_WIDTH or 250)
		CLASSBAR_WIDTH = baseW * (TOTS_MAX_STACKS - 1) / TOTS_MAX_STACKS
	else
		CLASSBAR_WIDTH = playerFrame and E:Scale(playerFrame.CLASSBAR_WIDTH or 250) or 250
	end

	local holderH = cbdb.height or 10

	totsHolder:SetSize(CLASSBAR_WIDTH, holderH)
	totsBar:SetSize(CLASSBAR_WIDTH - SPACING, holderH - SPACING)

	totsBar:ClearAllPoints()
	totsBar:SetPoint('BOTTOMLEFT', totsHolder, 'BOTTOMLEFT', BORDER + UISPACING, BORDER + UISPACING)

	local isMini = (playerFrame and playerFrame.USE_MINI_CLASSBAR) or (playerFrame and playerFrame.CLASSBAR_DETACHED)
	local gap, cellW

	if isMini then
		local spacing = (playerFrame.CLASSBAR_DETACHED and cbdb.spacing or 5)
		gap = spacing + BORDER * 2 + UISPACING * 2
		cellW = (CLASSBAR_WIDTH - (gap * (TOTS_MAX_STACKS - 1)) - BORDER * 2) / TOTS_MAX_STACKS
	else
		gap = BORDER * 2 - UISPACING
		cellW = (CLASSBAR_WIDTH - ((TOTS_MAX_STACKS - 1) * gap)) / TOTS_MAX_STACKS
	end

	local texture = LSM:Fetch('statusbar', E.db.unitframe and E.db.unitframe.statusbar or 'ElvUI Norm')
	local borderColor = E.db.unitframe and E.db.unitframe.colors and E.db.unitframe.colors.borderColor

	for i = 1, TOTS_MAX_STACKS do
		local cell = totsCells[i]
		cell:SetSize(cellW, totsBar:GetHeight())
		cell:ClearAllPoints()

		if i == 1 then
			cell:SetPoint('LEFT', totsBar)
		elseif isMini then
			cell:SetPoint('LEFT', totsCells[i - 1], 'RIGHT', gap, 0)
		elseif i == TOTS_MAX_STACKS then
			cell:SetPoint('LEFT', totsCells[i - 1], 'RIGHT', BORDER - UISPACING, 0)
			cell:SetPoint('RIGHT', totsBar)
		else
			cell:SetPoint('LEFT', totsCells[i - 1], 'RIGHT', BORDER - UISPACING, 0)
		end

		cell:SetStatusBarTexture(texture)
		cell:GetStatusBarTexture():SetHorizTile(false)
		cell.bg:SetTexture(texture)
		cell.bg:SetInside(cell.backdrop)

		if cell.backdrop then
			cell.backdrop:SetShown(isMini)
			if borderColor and not cell.backdrop.forcedBorderColors then
				cell.backdrop:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b)
			end
		end

		cell.bg:SetParent(isMini and cell.backdrop or totsBar)
	end

	if totsBar.backdrop then
		totsBar.backdrop:SetShown(not isMini)
		if not isMini and borderColor and not totsBar.backdrop.forcedBorderColors then
			totsBar.backdrop:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b)
		end
	end

	totsBar:SetFrameStrata(cbdb.strataAndLevel and cbdb.strataAndLevel.useCustomStrata and cbdb.strataAndLevel.frameStrata or 'LOW')

	UpdateTOTS()
end

local function CreateTOTSBar()
	if totsHolder then return end

	local anchor = _G['ClassBarMover'] or E.UIParent
	totsHolder = CreateFrame('Frame', 'TUI_TipOfTheSpearHolder', E.UIParent)
	totsHolder:SetAllPoints(anchor)

	totsBar = CreateFrame('Frame', 'TUI_TipOfTheSpear', totsHolder)
	totsBar:CreateBackdrop(nil, nil, nil, nil, true)

	for i = 1, TOTS_MAX_STACKS do
		local cell = CreateFrame('StatusBar', 'TUI_TipOfTheSpear' .. i, totsBar)
		cell:SetStatusBarTexture(E.media.blankTex)
		cell:GetStatusBarTexture():SetHorizTile(false)
		cell:SetMinMaxValues(0, 1)
		cell:SetValue(0)

		cell:CreateBackdrop(nil, nil, nil, nil, true)
		cell.backdrop:SetParent(totsBar)

		cell.bg = totsBar:CreateTexture(nil, 'BORDER')
		cell.bg:SetTexture(E.media.blankTex)
		cell.bg:SetInside(cell.backdrop)

		totsCells[i] = cell
	end

	hooksecurefunc(UF, 'Configure_ClassBar', function(_, frame)
		if not totsHolder or not totsHolder:IsShown() then return end
		if frame ~= UF.player then return end
		LayoutTOTS()
	end)

	LayoutTOTS()
end

local function ShowTOTS()
	if not totsHolder then
		CreateTOTSBar()
	end

	if not totsEventFrame then
		totsEventFrame = CreateFrame('Frame')
		totsEventFrame:SetScript('OnEvent', UpdateTOTS)
	end

	totsEventFrame:RegisterUnitEvent('UNIT_AURA', 'player')
	totsHolder:Show()
	UpdateTOTS()
end

local function HideTOTS()
	if totsHolder then totsHolder:Hide() end
	if totsEventFrame then totsEventFrame:UnregisterAllEvents() end
end

local function OnSpecChanged()
	local spec = GetSpecialization()
	if spec == 3 then -- Survival
		ShowTOTS()
	else
		HideTOTS()
	end
end

function TUI:InitTipOfTheSpear()
	local _, class = UnitClass('player')
	if class ~= 'HUNTER' then return end

	C_Timer.After(0, function()
		self:InitFakePowerFader()
		OnSpecChanged()

		TUI:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED', OnSpecChanged)
	end)
end

-- Sync fake power bar alpha with player frame fader
do
	local hooked = false
	function TUI:InitFakePowerFader()
		if hooked then return end
		local playerFrame = _G.ElvUF_Player
		if not playerFrame then return end
		hooked = true

		hooksecurefunc(playerFrame, 'SetAlpha', function(_, alpha)
			if totsHolder then totsHolder:SetAlpha(alpha) end
		end)
	end
end
