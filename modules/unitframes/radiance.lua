-- Discipline Priest Power Word: Radiance charge tracker. Self-tracks from cast
-- events + a flat recharge so it never reads the secret charge data in combat
-- (12.x); the real API is read only out of combat, to seed/re-sync.
local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local UFC = E:GetModule('TUI_UnitFrames')
local UF = E:GetModule('UnitFrames')
local LSM = E.Libs.LSM

local CreateFrame = CreateFrame
local GetTime = GetTime
local ceil = math.ceil
local C_Timer_After = C_Timer.After
local hooksecurefunc = hooksecurefunc
local GetSpellCharges = C_Spell.GetSpellCharges
local IsSpellKnown = C_SpellBook.IsSpellKnown
local PlayerBank = Enum.SpellBookSpellBank.Player
local GetSpecialization = (C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or GetSpecialization
local GetSpecializationInfo = (C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo) or GetSpecializationInfo

local RADIANCE_ID = 194509
local DISC_SPEC = 256
local DEFAULT_MAX = 2
local DEFAULT_RECHARGE = 18

local holder, segments, eventFrame
local charges = DEFAULT_MAX
local maxCharges = DEFAULT_MAX
local recharge = DEFAULT_RECHARGE
local rechargeEnd
local cachedW, cachedH = 0, 0

local function GetDB() return TUI.db.profile.radianceBar end

local function IsDiscSpec()
	local s = GetSpecialization()
	return (s and GetSpecializationInfo(s) == DISC_SPEC) or false
end

local function ChargeColor(db)
	if db.useClassColor then
		local c = E:ClassColor(E.myclass)
		if c then return c end
	end
	return db.color
end

-- Re-read real charge state; only trusts non-secret values (out of combat) so it never errors while tainted in a fight.
local function Seed()
	local info = GetSpellCharges(RADIANCE_ID)
	if not info then return end
	if info.maxCharges and info.maxCharges > 0 then maxCharges = info.maxCharges end
	if not E:NotSecretValue(info.currentCharges) then return end
	charges = info.currentCharges
	if E:NotSecretValue(info.cooldownDuration) and info.cooldownDuration > 0 then
		recharge = info.cooldownDuration
	end
	if charges < maxCharges and E:NotSecretValue(info.cooldownStartTime) and info.cooldownStartTime > 0 then
		rechargeEnd = info.cooldownStartTime + recharge
	else
		rechargeEnd = nil
	end
end

-- Fill = 1 for an available charge, the partial recharge for the next one, 0 beyond.
local function Render()
	if not holder or not segments then return end
	local db = GetDB()
	local c = ChargeColor(db)
	local now = GetTime()
	for i = 1, maxCharges do
		local seg = segments[i]
		if seg then
			local fill
			if i <= charges then
				fill = 1
			elseif i == charges + 1 and rechargeEnd then
				fill = (recharge - (rechargeEnd - now)) / recharge
				if fill < 0 then fill = 0 elseif fill > 1 then fill = 1 end
			else
				fill = 0
			end
			seg:SetValue(fill)
			seg:SetStatusBarColor(c.r, c.g, c.b, c.a or 1)
			if seg.text then
				if i == charges + 1 and rechargeEnd and db.showCooldownText then
					seg.text:SetFormattedText('%d', ceil(rechargeEnd - now))
				else
					seg.text:SetText('')
				end
			end
		end
	end
end

local function StartTicker() if holder then holder:SetScript('OnUpdate', UFC.RadianceOnUpdate) end end
local function StopTicker() if holder then holder:SetScript('OnUpdate', nil) end end

function UFC.RadianceOnUpdate()
	if not holder or not holder:IsShown() then return end
	local now = GetTime()
	while rechargeEnd and now >= rechargeEnd and charges < maxCharges do
		charges = charges + 1
		rechargeEnd = (charges < maxCharges) and (rechargeEnd + recharge) or nil
	end
	Render()
	if not rechargeEnd then
		StopTicker()
		if not GetDB().showWhenInactive then holder:Hide() end
	end
end

-- Button-press is the only combat-safe signal: consume a charge + start the recharge if one isn't already running (charges recharge sequentially).
local function OnRadianceCast()
	if charges > 0 then charges = charges - 1 end
	if charges < maxCharges and not rechargeEnd then
		rechargeEnd = GetTime() + recharge
	end
	if holder then
		holder:Show()
		StartTicker()
		Render()
	end
end

-- Mirror ElvUI's ClassBarMover so the bar inherits the player class power bar's position/size (Disc has one like every spec).
local function AnchorHolder()
	if not holder then return end
	local target = _G.ClassBarMover or E.UIParent
	if holder._tuiAnchorTarget == target then return end
	holder._tuiAnchorTarget = target
	holder:ClearAllPoints()
	holder:SetAllPoints(target)
end

local function LayoutBar()
	if not holder or not segments then return end
	AnchorHolder()

	local BORDER = UF.BORDER or 2
	local UISPACING = UF.SPACING or 1
	local SPACING = (BORDER + UISPACING) * 2

	local width, height = holder:GetWidth(), holder:GetHeight()
	if width == cachedW and height == cachedH then return end
	cachedW, cachedH = width, height

	local gap = GetDB().spacing or 2
	local segW = (width - SPACING - gap * (maxCharges - 1)) / maxCharges
	local segH = height - SPACING
	for i = 1, maxCharges do
		local seg = segments[i]
		if seg then
			seg:SetSize(segW, segH)
			seg:ClearAllPoints()
			seg:SetPoint('BOTTOMLEFT', holder, 'BOTTOMLEFT', BORDER + UISPACING + (i - 1) * (segW + gap), BORDER + UISPACING)
			seg:Show()
		end
	end
	for i = maxCharges + 1, #segments do
		if segments[i] then segments[i]:Hide() end
	end
end

local function UpdateVisibility()
	if not holder then return end
	if not IsDiscSpec() or not IsSpellKnown(RADIANCE_ID, PlayerBank) then
		holder:Hide()
		StopTicker()
		return
	end
	Seed()
	LayoutBar()
	holder:Show()
	Render()
	if rechargeEnd then
		StartTicker()
	else
		StopTicker()
		if not GetDB().showWhenInactive then holder:Hide() end
	end
end

local function OnEvent(_frame, event, arg1, _arg2, arg3)
	if event == 'UNIT_SPELLCAST_SUCCEEDED' then
		if arg1 == 'player' and arg3 == RADIANCE_ID then OnRadianceCast() end
	elseif event == 'PLAYER_REGEN_ENABLED' then
		-- correct any drift on leaving combat (the API is readable again here)
		Seed()
		Render()
		if rechargeEnd then StartTicker() end
	else
		UpdateVisibility()
	end
end

local function CreateBar()
	if holder then return end
	holder = CreateFrame('Frame', 'TUI_RadianceHolder', E.UIParent)
	holder:Hide()

	local db = GetDB()
	local tex = LSM:Fetch('statusbar', E.db.unitframe and E.db.unitframe.statusbar or 'ElvUI Norm')
	local font = LSM:Fetch('font', 'Expressway')
	segments = {}
	for i = 1, DEFAULT_MAX do
		local seg = CreateFrame('StatusBar', nil, holder)
		seg:SetStatusBarTexture(tex)
		seg:SetMinMaxValues(0, 1)
		seg:SetValue(0)
		seg:CreateBackdrop(nil, nil, nil, nil, true)
		seg.text = seg:CreateFontString(nil, 'OVERLAY')
		seg.text:FontTemplate(font, db.cooldownFontSize or 12, 'OUTLINE')
		seg.text:SetPoint('CENTER', seg, 'CENTER', 0, 0)
		segments[i] = seg
	end

	LayoutBar()

	hooksecurefunc(UF, 'Configure_ClassBar', function(_, frame)
		if frame ~= UF.player then return end
		cachedW, cachedH = 0, 0
		C_Timer_After(0, LayoutBar)
	end)

	local pf = UF.player
	if pf then
		hooksecurefunc(pf, 'SetAlpha', function(_, alpha)
			if holder then holder:SetAlpha(alpha) end
		end)
	end
end

local function RegisterEvents()
	if eventFrame then return end
	eventFrame = CreateFrame('Frame')
	eventFrame:SetScript('OnEvent', OnEvent)
	eventFrame:RegisterUnitEvent('UNIT_SPELLCAST_SUCCEEDED', 'player')
	eventFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
	eventFrame:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED')
	eventFrame:RegisterEvent('PLAYER_TALENT_UPDATE')
	eventFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
end

function UFC:RefreshRadianceBar()
	if not holder then return end
	local db = GetDB()
	local tex = LSM:Fetch('statusbar', E.db.unitframe and E.db.unitframe.statusbar or 'ElvUI Norm')
	local font = LSM:Fetch('font', 'Expressway')
	for i = 1, #segments do
		local seg = segments[i]
		if seg then
			seg:SetStatusBarTexture(tex)
			if seg.text then seg.text:FontTemplate(font, db.cooldownFontSize or 12, 'OUTLINE') end
		end
	end
	cachedW, cachedH = 0, 0
	LayoutBar()
	UpdateVisibility()
end

function UFC:InitRadianceBar()
	if E.myclass ~= 'PRIEST' then return end
	if self._hookedRadiance then return end
	local db = GetDB()
	if not db or not db.enabled then return end
	self._hookedRadiance = true

	RegisterEvents()
	C_Timer_After(0, function()
		CreateBar()
		UpdateVisibility()
	end)
end
