local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local UF = E:GetModule('UnitFrames')
local LSM = E.Libs.LSM

local hooksecurefunc = hooksecurefunc
local GetSpecialization = GetSpecialization
local UnitClass = UnitClass
local IsFlying = IsFlying

local UnitPower, UnitPowerType, UnitPowerPercent, format = UnitPower, UnitPowerType, UnitPowerPercent, format
local ScaleTo100 = CurveConstants and CurveConstants.ScaleTo100

-- Smart Power tag: shows percentage for mana users, current value otherwise
E:AddTag('tui-smartpower', 'UNIT_DISPLAYPOWER UNIT_POWER_FREQUENT UNIT_MAXPOWER', function(unit)
	local powerType = UnitPowerType(unit)
	if powerType == Enum.PowerType.Mana then
		return format('%d', UnitPowerPercent(unit, nil, true, ScaleTo100))
	else
		return UnitPower(unit)
	end
end)
E:AddTagInfo('tui-smartpower', E:TextGradient('TrenchyUI', 1.00,0.18,0.24, 0.80,0.10,0.20), 'Shows power percentage for mana specs, current power for others')

-- Power tag responsiveness: bypass oUF's 100ms event batching delay
hooksecurefunc(UF, 'Configure_Power', function(_, frame)
	if frame and frame.Power and frame.Power.value then
		frame.Power.value.frequentUpdates = 0.05
	end
end)

-- Fake Power fix
hooksecurefunc(UF, 'Configure_ClassBar', function(_, frame)
	if not frame or not frame.ClassBar then return end
	if frame.ClassBar ~= 'ClassPower' and frame.ClassBar ~= 'Runes' and frame.ClassBar ~= 'Totems' then return end

	local bars = frame[frame.ClassBar]
	if not bars then return end

	local containerW = bars:GetWidth()
	local containerH = bars:GetHeight()
	if not containerW or containerW <= 0 then return end
	if not containerH or containerH <= 0 then return end

	local MAX_CLASS_BAR = frame.MAX_CLASS_BAR or 0
	if MAX_CLASS_BAR < 1 then return end

	for i = 1, MAX_CLASS_BAR do
		local bar = bars[i]
		if not bar then break end
		if bar:GetWidth() > containerW then
			bar:SetWidth(containerW)
		end
		if bar:GetHeight() > containerH then
			bar:SetHeight(containerH)
		end
	end
end)

-- VDH Soul Fragments
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
	local _, powers, fallback = UF:ClassPower_GetColor(UF.db.colors, 'SOUL_FRAGMENTS')
	local color = powers or fallback

	for i = 1, SOUL_FRAGMENT_MAX do
		local cell = sfCells[i]
		if cell then
			UF:SetStatusBarColor(cell, color.r, color.g, color.b, custom_backdrop)
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

		local specFrame = CreateFrame('Frame')
		specFrame:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED')
		specFrame:SetScript('OnEvent', OnSpecChanged)
	end)
end


-- Pixel Glow
local LCG = E.Libs.CustomGlow
local GLOW_KEY = 'TUI_PixelGlow'
local glowColor = { 1, 1, 1, 1 }

local function GetPixelGlowDB()
	local db = TUI.db and TUI.db.profile and TUI.db.profile.pixelGlow
	if not db then return false, 8, 0.25, 2 end
	return db.enabled, db.lines, db.speed, db.thickness
end

function TUI:InitPixelGlow()
	local enabled = GetPixelGlowDB()
	if not enabled then return end
	if not LCG or not LCG.PixelGlow_Start then return end

	hooksecurefunc(UF, 'PostUpdate_AuraHighlight', function(_, frame, _, aura, debuffType)
		if not frame then return end
		local element = frame.AuraHighlight
		if not element then return end

		local _, lines, speed, thickness = GetPixelGlowDB()
		local glowTarget = frame.Health or frame

		if aura or debuffType then
			glowColor[1], glowColor[2], glowColor[3] = element:GetVertexColor()
			element:SetVertexColor(0, 0, 0, 0)
			if frame.AuraHightlightGlow then frame.AuraHightlightGlow:Hide() end
			LCG.PixelGlow_Start(glowTarget, glowColor, lines, speed, nil, thickness, 0, 0, false, GLOW_KEY)
		else
			element:SetVertexColor(0, 0, 0, 0)
			if frame.AuraHightlightGlow then frame.AuraHightlightGlow:Hide() end
			LCG.PixelGlow_Stop(glowTarget, GLOW_KEY)
		end
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

-- Steady Flight fader extension
local sfOverridden = false

local function IsSteadyFlightEnabled()
	local db = TUI.db and TUI.db.profile and TUI.db.profile.fader
	return db and db.steadyFlight
end

local function GetPlayerFaderDB()
	return E.db and E.db.unitframe and E.db.unitframe.units
		and E.db.unitframe.units.player and E.db.unitframe.units.player.fader
end

function TUI:InitSteadyFlight()
	C_Timer.After(0, function()
		local playerFrame = _G.ElvUF_Player
		if not playerFrame then return end

		-- Fix fader count if Configure_Fader runs while we've suppressed DynamicFlight
		hooksecurefunc(UF, 'Configure_Fader', function(_, frame)
			if frame ~= playerFrame or not sfOverridden then return end
			local fader = frame.Fader
			if fader and fader.DynamicFlight and fader.count and fader.count > 0 then
				fader.count = fader.count - 1
			end
			sfOverridden = false
		end)

		-- Poll IsFlying() and suppress the DynamicFlight condition while airborne
		C_Timer.NewTicker(0.2, function()
			local pf = _G.ElvUF_Player
			if not pf or not pf.Fader then return end

			local faderDB = GetPlayerFaderDB()
			local dbEnabled = faderDB and faderDB.dynamicflight

			-- Restore if our feature or DynamicFlight was turned off
			if not IsSteadyFlightEnabled() or not dbEnabled then
				if sfOverridden then
					sfOverridden = false
					pf.Fader.DynamicFlight = dbEnabled or nil
					pf.Fader:ForceUpdate()
				end
				return
			end

			local flying = IsFlying()
			if flying and not sfOverridden then
				pf.Fader.DynamicFlight = false
				sfOverridden = true
				pf.Fader:ForceUpdate()
			elseif not flying and sfOverridden then
				pf.Fader.DynamicFlight = true
				sfOverridden = false
				pf.Fader:ForceUpdate()
			end
		end)
	end)
end
