local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local UF = E:GetModule('UnitFrames')
local LSM = E.Libs.LSM

local hooksecurefunc = hooksecurefunc
local GetSpecialization = GetSpecialization
local UnitClass = UnitClass
local CreateFrame = CreateFrame

local SOUL_FRAGMENT_MAX = 6
local SOUL_CLEAVE_SPELL = 228477
local C_Spell_GetSpellCastCount = C_Spell and C_Spell.GetSpellCastCount

local sfBar, sfHolder, sfEventFrame
local sfCells = {}

local function GetClassBarDB()
	return E.db.unitframe and E.db.unitframe.units and E.db.unitframe.units.player and E.db.unitframe.units.player.classbar
end

local function UpdateSoulFragmentColors()
	if not sfBar then return end

	local custom_backdrop = UF.db.colors.customclasspowerbackdrop and UF.db.colors.classpower_backdrop
	local c = TUI.db.profile.fakePower.soulFragmentsColor
	if not c then
		local _, powers, fallback = UF:ClassPower_GetColor(UF.db.colors, 'SOUL_FRAGMENTS')
		c = powers or fallback
	end

	for i = 1, SOUL_FRAGMENT_MAX do
		local cell = sfCells[i]
		if cell then
			UF:SetStatusBarColor(cell, c.r, c.g, c.b, custom_backdrop)
		end
	end
end

local function UpdateSoulFragments()
	if not sfBar then return end

	local current = C_Spell_GetSpellCastCount and C_Spell_GetSpellCastCount(SOUL_CLEAVE_SPELL) or 0

	for i = 1, SOUL_FRAGMENT_MAX do
		local cell = sfCells[i]
		if cell then
			cell:SetMinMaxValues(i - 1, i)
			cell:SetValue(current)
		end
	end

	UpdateSoulFragmentColors()
end

local function LayoutSoulFragments()
	if not sfBar or not sfHolder then return end

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
		CLASSBAR_WIDTH = baseW * (SOUL_FRAGMENT_MAX - 1) / SOUL_FRAGMENT_MAX
	else
		CLASSBAR_WIDTH = playerFrame and E:Scale(playerFrame.CLASSBAR_WIDTH or 250) or 250
	end

	local holderH = cbdb.height or 10

	sfHolder:SetSize(CLASSBAR_WIDTH, holderH)
	sfBar:SetSize(CLASSBAR_WIDTH - SPACING, holderH - SPACING)

	sfBar:ClearAllPoints()
	sfBar:SetPoint('BOTTOMLEFT', sfHolder, 'BOTTOMLEFT', BORDER + UISPACING, BORDER + UISPACING)

	local isMini = (playerFrame and playerFrame.USE_MINI_CLASSBAR) or (playerFrame and playerFrame.CLASSBAR_DETACHED)
	local gap, cellW

	if isMini then
		local spacing = (playerFrame.CLASSBAR_DETACHED and cbdb.spacing or 5)
		gap = spacing + BORDER * 2 + UISPACING * 2
		cellW = (CLASSBAR_WIDTH - (gap * (SOUL_FRAGMENT_MAX - 1)) - BORDER * 2) / SOUL_FRAGMENT_MAX
	else
		gap = BORDER * 2 - UISPACING
		cellW = (CLASSBAR_WIDTH - ((SOUL_FRAGMENT_MAX - 1) * gap)) / SOUL_FRAGMENT_MAX
	end

	local texture = LSM:Fetch('statusbar', E.db.unitframe and E.db.unitframe.statusbar or 'ElvUI Norm')
	local borderColor = E.db.unitframe and E.db.unitframe.colors and E.db.unitframe.colors.borderColor

	for i = 1, SOUL_FRAGMENT_MAX do
		local cell = sfCells[i]
		cell:SetSize(cellW, sfBar:GetHeight())
		cell:ClearAllPoints()

		if i == 1 then
			cell:SetPoint('LEFT', sfBar)
		elseif isMini then
			cell:SetPoint('LEFT', sfCells[i - 1], 'RIGHT', gap, 0)
		elseif i == SOUL_FRAGMENT_MAX then
			cell:SetPoint('LEFT', sfCells[i - 1], 'RIGHT', BORDER - UISPACING, 0)
			cell:SetPoint('RIGHT', sfBar)
		else
			cell:SetPoint('LEFT', sfCells[i - 1], 'RIGHT', BORDER - UISPACING, 0)
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

		cell.bg:SetParent(isMini and cell.backdrop or sfBar)
	end

	if sfBar.backdrop then
		sfBar.backdrop:SetShown(not isMini)
		if not isMini and borderColor and not sfBar.backdrop.forcedBorderColors then
			sfBar.backdrop:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b)
		end
	end

	sfBar:SetFrameStrata(cbdb.strataAndLevel and cbdb.strataAndLevel.useCustomStrata and cbdb.strataAndLevel.frameStrata or 'LOW')

	UpdateSoulFragments()
end

local function CreateSoulFragmentBar()
	if sfHolder then return end

	local anchor = _G['ClassBarMover'] or E.UIParent
	sfHolder = CreateFrame('Frame', 'TUI_SoulFragmentsHolder', E.UIParent)
	sfHolder:SetAllPoints(anchor)

	sfBar = CreateFrame('Frame', 'TUI_SoulFragments', sfHolder)
	sfBar:CreateBackdrop(nil, nil, nil, nil, true)

	for i = 1, SOUL_FRAGMENT_MAX do
		local cell = CreateFrame('StatusBar', 'TUI_SoulFragment' .. i, sfBar)
		cell:SetStatusBarTexture(E.media.blankTex)
		cell:GetStatusBarTexture():SetHorizTile(false)
		cell:SetMinMaxValues(0, 1)
		cell:SetValue(0)

		cell:CreateBackdrop(nil, nil, nil, nil, true)
		cell.backdrop:SetParent(sfBar)

		cell.bg = sfBar:CreateTexture(nil, 'BORDER')
		cell.bg:SetTexture(E.media.blankTex)
		cell.bg:SetInside(cell.backdrop)

		sfCells[i] = cell
	end

	hooksecurefunc(UF, 'Configure_ClassBar', function(_, frame)
		if not sfHolder or not sfHolder:IsShown() then return end
		if frame ~= UF.player then return end
		LayoutSoulFragments()
	end)

	LayoutSoulFragments()
end

local function ShowSoulFragments()
	if not sfHolder then
		CreateSoulFragmentBar()
	end

	if not sfEventFrame then
		sfEventFrame = CreateFrame('Frame')
		sfEventFrame:SetScript('OnEvent', UpdateSoulFragments)
	end

	sfEventFrame:RegisterUnitEvent('UNIT_AURA', 'player')
	sfHolder:Show()
	UpdateSoulFragments()
end

local function HideSoulFragments()
	if sfHolder then sfHolder:Hide() end
	if sfEventFrame then sfEventFrame:UnregisterAllEvents() end
end

local function OnSpecChanged()
	local spec = GetSpecialization()
	if spec == 2 then -- Vengeance
		ShowSoulFragments()
	else
		HideSoulFragments()
	end
end

function TUI:InitSoulFragments()
	local _, class = UnitClass('player')
	if class ~= 'DEMONHUNTER' then return end

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
			if sfHolder then sfHolder:SetAlpha(alpha) end
		end)
	end
end
