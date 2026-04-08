-- Adapted from mMediaTag with permission from Blinkii, 2026-03-14
local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local NPS = E:GetModule('TUI_Nameplates')
local NP = E:GetModule('NamePlates')
local UF = E:GetModule('UnitFrames')

local GetSpellCooldownDuration = C_Spell.GetSpellCooldownDuration
local EvalColorBool = C_CurveUtil.EvaluateColorValueFromBoolean
local EvalColor = C_CurveUtil.EvaluateColorFromBoolean
local IsSpellKnown = C_SpellBook and C_SpellBook.IsSpellKnown

local INTERRUPT_BY_SPEC = {
	-- Warrior
	[71] = 6552, [72] = 6552, [73] = 6552,
	-- Paladin
	[65] = 96231, [66] = 96231, [70] = 96231,
	-- Hunter
	[253] = 147362, [254] = 147362, [255] = 187707,
	-- Rogue
	[259] = 1766, [260] = 1766, [261] = 1766,
	-- Priest (Shadow only)
	[256] = nil, [257] = nil, [258] = 15487,
	-- Death Knight
	[250] = 47528, [251] = 47528, [252] = 47528,
	-- Shaman
	[262] = 57994, [263] = 57994, [264] = 57994,
	-- Mage
	[62] = 2139, [63] = 2139, [64] = 2139,
	-- Warlock
	[265] = 119910, [266] = 119914, [267] = 119910,
	-- Monk
	[268] = 116705, [269] = 116705, [270] = 116705,
	-- Druid
	[102] = 78675, [103] = 106839, [104] = 106839, [105] = 106839,
	-- Demon Hunter
	[577] = 183752, [581] = 183752, [1480] = 183752,
	-- Evoker
	[1467] = 351338, [1468] = 351338, [1473] = 351338,
}

local interruptSpellId
local colors

local function UpdateInterruptSpell()
	local specId = select(1, GetSpecializationInfo(GetSpecialization()))

	if E.myclass == 'WARLOCK' then
		for _, spellId in ipairs({ 89766, 212619, 119914 }) do
			if IsSpellKnown and IsSpellKnown(spellId) then
				INTERRUPT_BY_SPEC[specId] = spellId
				break
			end
		end
	end

	interruptSpellId = INTERRUPT_BY_SPEC[specId]
end

local function PostCastFailInterrupted(castbar)
	local c = NP.db.colors.castInterruptedColor
	if c then castbar:SetStatusBarColor(c.r, c.g, c.b) end
	castbar.TUI_IsInterruptedOrFailed = true
end

local function GetInterruptCooldown()
	if interruptSpellId then return GetSpellCooldownDuration(interruptSpellId) end
end

local function SetKickSpark(castbar, castStart, cooldown)
	local unit = castbar.unit or castbar.__owner.unit
	if not (unit and UnitCanAttack('player', unit)) then return end

	local kickBar = castbar.TUI_KickBar
	local indicator = kickBar.TUI_Indicator
	if cooldown == nil then return end

	if castStart then
		local isChannelOrReverse = castbar.channeling or castbar:GetReverseFill()
		local fillStyle = isChannelOrReverse and Enum.StatusBarFillStyle.Reverse or Enum.StatusBarFillStyle.Standard
		local barAnchor = isChannelOrReverse and 'LEFT' or 'RIGHT'
		local indicatorAnchor = isChannelOrReverse and 'RIGHT' or 'LEFT'

		kickBar:SetFillStyle(fillStyle)
		indicator:ClearAllPoints()
		indicator:SetPoint(indicatorAnchor, kickBar:GetStatusBarTexture(), barAnchor)

		local totalDuration = castbar:GetTimerDuration():GetTotalDuration()
		kickBar:SetMinMaxValues(0, totalDuration)
		kickBar:SetValue(cooldown:GetRemainingDuration())

		local shieldAlpha = 0
		if castbar.notInterruptible ~= nil then shieldAlpha = EvalColorBool(castbar.notInterruptible, 0, 1) end
		kickBar:SetAlphaFromBoolean(cooldown:IsZero(), 0, shieldAlpha)
	else
		kickBar:SetAlphaFromBoolean(cooldown:IsZero(), 0, kickBar:GetAlpha())
		if castbar.interrupted then kickBar:SetAlpha(0) end
	end
end

local function SetCastbarColor(castbar, cooldown)
	if castbar.failed or castbar.interrupted or castbar.finished or cooldown == nil then
		local c = colors.normal
		castbar:SetStatusBarColor(c.r, c.g, c.b, c.a)
		return
	end

	local unit = castbar.unit or castbar.__owner.unit
	if not (unit and UnitCanAttack('player', unit)) then return end

	local color = EvalColor(cooldown:IsZero(), colors.normal, colors.onCD)
	castbar:SetStatusBarColor(color:GetRGBA())
end

local function UpdateCast(castbar, castStart)
	local cooldown = GetInterruptCooldown()
	SetKickSpark(castbar, castStart, cooldown)
	SetCastbarColor(castbar, cooldown)
end

local function ConstructKickBar(castbar)
	if castbar.TUI_KickBar then return end

	local kickBar = CreateFrame('StatusBar', nil, castbar)
	kickBar:SetClipsChildren(true)
	kickBar:SetStatusBarTexture(E.media.blankTex)
	kickBar:GetStatusBarTexture():SetAlpha(0)
	kickBar:ClearAllPoints()
	kickBar:SetAllPoints(castbar)
	kickBar:SetFrameLevel(castbar:GetFrameLevel() + 3)

	local c = colors.marker
	local indicator = kickBar:CreateTexture(nil, 'OVERLAY')
	indicator:SetColorTexture(c.r, c.g, c.b)
	indicator:SetSize(2, castbar:GetHeight())

	kickBar.TUI_Indicator = indicator
	castbar.TUI_KickBar = kickBar
end

local function OnUpdate(castbar, elapsed)
	if castbar.TUI_IsInterruptedOrFailed then return end
	castbar._kickThrottle = (castbar._kickThrottle or 0) + elapsed
	if castbar._kickThrottle < 0.1 then return end
	castbar._kickThrottle = 0
	UpdateCast(castbar, false)
end

local function PostCastStart(castbar, unit)
	if not (castbar and unit) then return end
	if not (castbar.casting or castbar.channeling) then return end
	if not UnitCanAttack('player', unit) then return end
	if not interruptSpellId then return end

	castbar.TUI_IsInterruptedOrFailed = false
	ConstructKickBar(castbar)
	UpdateCast(castbar, true)

	if not castbar.TUI_OnUpdateHooked then
		castbar:HookScript('OnUpdate', OnUpdate)
		castbar.TUI_OnUpdateHooked = true
	end
end

function NPS:HookCastbarInterrupt()
	if self._hookedCastbarInterrupt then return end
	self._hookedCastbarInterrupt = true

	local db = TUI.db.profile.nameplates
	colors = {
		onCD = CreateColor(db.castbarInterruptOnCD.r, db.castbarInterruptOnCD.g, db.castbarInterruptOnCD.b),
		normal = CreateColor(db.castbarInterruptReady.r, db.castbarInterruptReady.g, db.castbarInterruptReady.b),
		marker = db.castbarMarkerColor,
	}

	NPS:RegisterEvent('PLAYER_ENTERING_WORLD', UpdateInterruptSpell)
	NPS:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED', UpdateInterruptSpell)
	NPS:RegisterEvent('PLAYER_TALENT_UPDATE', UpdateInterruptSpell)

	hooksecurefunc(NP, 'Castbar_PostCastStart', PostCastStart)
	hooksecurefunc(UF, 'PostCastStart', PostCastStart)
	hooksecurefunc(NP, 'Castbar_PostCastFail', PostCastFailInterrupted)
	hooksecurefunc(NP, 'Castbar_PostCastInterrupted', PostCastFailInterrupted)
end
