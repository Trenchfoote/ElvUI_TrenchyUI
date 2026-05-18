-- Battle Rez + Bloodlust tracker. Independent implementation (BResLustTracker read
-- only for API behavior, permitted by the Originality Rule). ElvUI-leveraged:
-- backdrop/font helpers, LSM, secret-safe guards, and an ElvUI mover.
local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local QOL = E:GetModule('TUI_QoL')
local LSM = E.Libs.LSM
local LCG = E.Libs.CustomGlow

local GLOW_KEY = 'TUI_BResLust'
local glowColor = { 1, 0.4, 0, 1 }

local CreateFrame = CreateFrame
local GetTime = GetTime
local GetInstanceInfo = GetInstanceInfo
local GetSpellCharges = C_Spell.GetSpellCharges
local GetPlayerAuraBySpellID = C_UnitAuras.GetPlayerAuraBySpellID
local format = format

-- Factual game data
local BRES_PROBE = 20484 -- Rebirth; probes the instance-wide shared battle-rez pool
local DEFAULT_LUST_ICON = 136012

local LUST_BUFFS = {
	[2825] = true, [32182] = true, [80353] = true, [264667] = true, [390386] = true,
	[178207] = true, [230935] = true, [256740] = true, [381301] = true, [146555] = true,
}
local SATED_DEBUFFS = {
	[57724] = true, [57723] = true, [80354] = true, [264689] = true, [390435] = true,
	[95809] = true,
}

-- Seconds after Sated is applied to treat lust as still active (haste window
-- is 40s for Bloodlust/Heroism/Time Warp/Primal Rage/Fury of the Aspects)
local LUST_ACTIVE_WINDOW = 40

local GetSpellTexture = C_Spell.GetSpellTexture
local UnitFactionGroup = UnitFactionGroup

-- Icon choice: dropdown key -> representative spell ID (icon resolved at runtime)
local BRES_ICON_SPELL = { rebirth = 20484, soulstone = 20707, raiseally = 61999, intercession = 391054 }
local LUST_ICON_SPELL = { bloodlust = 2825, heroism = 32182, timewarp = 80353, primalrage = 264667, furyofaspects = 390386 }
local CLASS_BRES = { DRUID = 'rebirth', WARLOCK = 'soulstone', DEATHKNIGHT = 'raiseally', PALADIN = 'intercession' }
local CLASS_LUST = { MAGE = 'timewarp', HUNTER = 'primalrage', EVOKER = 'furyofaspects' }

local holder, bres, lust, eventFrame, ticker
local previewMode = false

local function GetDB() return TUI.db.profile.qol.bresLust end

local function ResolveBResTexture()
	local key = GetDB().bresIcon or 'auto'
	if key == 'auto' then key = CLASS_BRES[E.myclass] or 'rebirth' end
	return GetSpellTexture(BRES_ICON_SPELL[key] or BRES_PROBE) or DEFAULT_LUST_ICON
end

local function ResolveLustTexture()
	local key = GetDB().lustIcon or 'auto'
	if key == 'auto' then
		if E.myclass == 'SHAMAN' then
			key = (UnitFactionGroup('player') == 'Alliance') and 'heroism' or 'bloodlust'
		else
			key = CLASS_LUST[E.myclass] or 'bloodlust'
		end
	end
	return GetSpellTexture(LUST_ICON_SPELL[key] or 2825) or DEFAULT_LUST_ICON
end

-- Set a texture and apply the configured icon zoom in one place
local function SetIcon(tex, fileOrID)
	tex:SetTexture(fileOrID)
	local z = GetDB().iconZoom or 0.08
	tex:SetTexCoord(z, 1 - z, z, 1 - z)
end

-- Cooldown swipe is optional; the timer text already conveys the countdown
local function ShowSwipe(cd, start, dur)
	if GetDB().cooldownSwipe then cd:SetCooldown(start, dur) else cd:Clear() end
end

local function FmtTime(sec)
	if sec <= 0 then return '' end
	if sec >= 60 then return format('%d:%02d', sec / 60, sec % 60) end
	return format('%ds', sec)
end

-- Per-text font size + offset from config; base anchor differs per text
local function StyleText(fs, anchor, parent, cfg, fontPath, outline)
	fs:FontTemplate(fontPath, (cfg and cfg.size) or 14, outline)
	fs:ClearAllPoints()
	fs:SetPoint(anchor, parent, anchor, (cfg and cfg.x) or 0, (cfg and cfg.y) or 0)
end

local function ApplyTextStyles()
	local db = GetDB()
	local fontPath = LSM:Fetch('font', db.font or 'Expressway')
	local outline = db.fontOutline or 'OUTLINE'
	local t = db.text or {}
	if bres then
		StyleText(bres.count, 'BOTTOMRIGHT', bres, t.bresCount, fontPath, outline)
		StyleText(bres.timer, 'CENTER', bres, t.bresTimer, fontPath, outline)
	end
	if lust then
		StyleText(lust.timer, 'CENTER', lust, t.lustTimer, fontPath, outline)
	end
end

local function CreateTracker()
	local f = CreateFrame('Frame', nil, holder)
	f:CreateBackdrop('Transparent')

	f.icon = f:CreateTexture(nil, 'ARTWORK')
	f.icon:SetAllPoints(f)

	f.cd = CreateFrame('Cooldown', nil, f, 'CooldownFrameTemplate')
	f.cd:SetAllPoints(f)
	f.cd:SetHideCountdownNumbers(true)
	f.cd:SetDrawEdge(false)

	-- Text on a frame above the cooldown so it isn't covered by the swipe
	f.textFrame = CreateFrame('Frame', nil, f)
	f.textFrame:SetAllPoints(f)
	f.textFrame:SetFrameLevel(f.cd:GetFrameLevel() + 1)

	f.count = f.textFrame:CreateFontString(nil, 'OVERLAY')
	f.count:SetJustifyH('CENTER')

	f.timer = f.textFrame:CreateFontString(nil, 'OVERLAY')
	f.timer:SetJustifyH('CENTER')

	-- Default font now so an early SetText can't error before ApplyTextStyles
	local fp = LSM:Fetch('font', 'Expressway')
	f.count:FontTemplate(fp, 14, 'OUTLINE')
	f.timer:FontTemplate(fp, 14, 'OUTLINE')

	return f
end

-- Re-resolve the static BRes/idle-Lust icons (choice + zoom). The active/sated
-- Lust icon is set live in UpdateLust from the real aura.
local function ApplyIcons()
	if bres then SetIcon(bres.icon, ResolveBResTexture()) end
	if lust then SetIcon(lust.icon, ResolveLustTexture()) end
end

local function Layout()
	local db = GetDB()
	local s = db.iconSize or 36
	local gap = db.iconSpacing or 6
	holder:SetSize(s, s * 2 + gap)

	bres:SetSize(s, s)
	bres:ClearAllPoints()
	bres:SetPoint('TOP', holder, 'TOP', 0, 0)

	lust:SetSize(s, s)
	lust:ClearAllPoints()
	lust:SetPoint('TOP', bres, 'BOTTOM', 0, -gap)
end

-- Battle rez: shared pool via GetSpellCharges. currentCharges/cooldownStartTime
-- are SecretWhenCooldownsRestricted; maxCharges/isActive are NeverSecret.
local function UpdateBRes()
	local info = GetSpellCharges(BRES_PROBE)
	if not info or not info.maxCharges or info.maxCharges == 0 then
		bres.icon:SetDesaturated(true)
		bres.count:SetText('')
		bres.timer:SetText('')
		bres.cd:Clear()
		return
	end

	local cur = info.currentCharges
	if E:NotSecretValue(cur) then
		bres.count:SetText(cur)
		bres.count:SetTextColor(cur > 0 and 0 or 1, cur > 0 and 1 or 0, 0)
		bres.icon:SetDesaturated(cur == 0)
	else
		bres.count:SetText('?')
		bres.count:SetTextColor(1, 1, 1)
		bres.icon:SetDesaturated(false)
	end

	if info.isActive and info.cooldownStartTime and info.cooldownDuration then
		ShowSwipe(bres.cd, info.cooldownStartTime, info.cooldownDuration)
		if E:NotSecretValue(info.cooldownStartTime) and E:NotSecretValue(info.cooldownDuration) then
			bres.timer:SetText(FmtTime((info.cooldownStartTime + info.cooldownDuration) - GetTime()))
		else
			bres.timer:SetText('')
		end
	else
		bres.cd:Clear()
		bres.timer:SetText('')
	end
end

-- Lust: GetPlayerAuraBySpellID is RequiresNonSecretAura, so a returned aura is
-- safe to read. Active lust buff = remaining; else sated debuff = cooldown
-- until the group can lust again; else idle.
local function FindAura(set)
	for id in pairs(set) do
		local aura = GetPlayerAuraBySpellID(id)
		if aura then return aura end
	end
end

-- Pixel glow on the Lust icon while a lust is active (idempotent via _glowing)
local function SetLustGlow(on)
	if not (LCG and LCG.PixelGlow_Start and lust) then return end
	local g = GetDB().glow or {}
	-- nil enabled = default ON (AceDB nested defaults aren't always injected)
	if on and g.enabled ~= false then
		if not lust._glowing then
			local c = g.color or {}
			if g.classColor then c = E:ClassColor(E.myclass) or c end
			glowColor[1], glowColor[2], glowColor[3], glowColor[4] = c.r or 1, c.g or 0.4, c.b or 0, 1
			LCG.PixelGlow_Start(lust, glowColor, g.lines or 8, g.speed or 0.25, nil, g.thickness or 2, 0, 0, false, GLOW_KEY)
			lust._glowing = true
		end
	elseif lust._glowing then
		LCG.PixelGlow_Stop(lust, GLOW_KEY)
		lust._glowing = false
	end
end

-- Force the glow to re-pull params on the next Update (config changed live)
local function ResetLustGlow()
	if lust and lust._glowing and LCG and LCG.PixelGlow_Stop then
		LCG.PixelGlow_Stop(lust, GLOW_KEY)
		lust._glowing = false
	end
end

-- The fleeting lust buff often can't be read in restricted instance combat, but
-- the Sated debuff (applied at the same instant, ~600s) reads reliably. Treat
-- the first LUST_ACTIVE_WINDOW seconds of Sated as the active lust window.
local function UpdateLust()
	local buff = FindAura(LUST_BUFFS)
	local sated = FindAura(SATED_DEBUFFS)
	local now = GetTime()

	local active, remaining, cdStart, cdDur
	if buff then
		active = true
		if buff.expirationTime and buff.duration and buff.duration > 0 then
			remaining = buff.expirationTime - now
			cdStart, cdDur = buff.expirationTime - buff.duration, buff.duration
		end
	elseif sated and sated.expirationTime and sated.duration and sated.duration > 0 then
		local elapsed = sated.duration - (sated.expirationTime - now)
		if elapsed >= 0 and elapsed < LUST_ACTIVE_WINDOW then
			active = true
			remaining = LUST_ACTIVE_WINDOW - elapsed
			cdStart, cdDur = now - elapsed, LUST_ACTIVE_WINDOW
		end
	end

	if active then
		lust.icon:SetDesaturated(false)
		SetIcon(lust.icon, (buff and buff.icon) or ResolveLustTexture())
		if cdStart then ShowSwipe(lust.cd, cdStart, cdDur) else lust.cd:Clear() end
		lust.timer:SetText(remaining and FmtTime(remaining) or '')
		lust.timer:SetTextColor(0, 1, 0)
	elseif sated and sated.expirationTime and sated.duration and sated.duration > 0 then
		lust.icon:SetDesaturated(true)
		SetIcon(lust.icon, ResolveLustTexture())
		ShowSwipe(lust.cd, sated.expirationTime - sated.duration, sated.duration)
		lust.timer:SetText(FmtTime(sated.expirationTime - now))
		lust.timer:SetTextColor(1, 0.2, 0.2)
	else
		SetIcon(lust.icon, ResolveLustTexture())
		lust.icon:SetDesaturated(false)
		lust.timer:SetText('')
		lust.cd:Clear()
	end
	SetLustGlow(active and true or false)
end

local function ShouldShow()
	local db = GetDB()
	if not db.enabled then return false end
	local _, instanceType = GetInstanceInfo()
	if instanceType == 'party' then return db.showInDungeon end
	if instanceType == 'raid' then return db.showInRaid end
	return db.showOutdoors
end

-- Preview: representative values so text size/offsets can be tuned without
-- needing real charges or an active lust. Cooldown swipes are set once in
-- ToggleBResLustPreview so they don't reset each tick.
local function RenderPreview()
	holder:Show()
	SetIcon(bres.icon, ResolveBResTexture())
	bres.icon:SetDesaturated(false)
	bres.count:SetText('3')
	bres.count:SetTextColor(0, 1, 0)
	bres.timer:SetText('2:00')
	bres.timer:SetTextColor(1, 1, 1)
	SetIcon(lust.icon, ResolveLustTexture())
	lust.icon:SetDesaturated(false)
	lust.timer:SetText('0:40')
	lust.timer:SetTextColor(0, 1, 0)
	SetLustGlow(true)
end

local function Update()
	if not holder then return end
	if previewMode then RenderPreview() return end
	if not ShouldShow() then SetLustGlow(false) holder:Hide() return end
	holder:Show()
	UpdateBRes()
	UpdateLust()
end

function QOL:IsBResLustPreview() return previewMode end

function QOL:ToggleBResLustPreview(v)
	previewMode = v
	if not (holder and bres and lust) then return end
	if v then
		local now = GetTime()
		ShowSwipe(bres.cd, now, 120)
		ShowSwipe(lust.cd, now, 40)
	else
		bres.cd:Clear()
		lust.cd:Clear()
	end
	Update()
end

local function CreateFrames()
	-- Idempotent per element so a partial/failed prior run can be completed
	-- on a later call without leaking a second holder or mover.
	if holder and bres and lust then return end

	if not holder then
		holder = CreateFrame('Frame', 'TUI_BResLustHolder', E.UIParent)
		holder:SetPoint('CENTER', E.UIParent, 'CENTER', 0, 200)
	end
	if not bres then bres = CreateTracker() end
	if not lust then lust = CreateTracker() end

	Layout()
	ApplyTextStyles()
	ApplyIcons()

	if not E.CreatedMovers['TUI_BResLustMover'] then
		local function Disabled() return not (TUI.db and TUI.db.profile and TUI.db.profile.qol.bresLust and TUI.db.profile.qol.bresLust.enabled) end
		E:CreateMover(holder, 'TUI_BResLustMover', 'TUI Battle Rez / Lust', nil, nil, nil, 'ALL,TRENCHYUI', Disabled, 'TrenchyUI,qol')
	end
end

function QOL:RefreshBResLust()
	if not holder or not bres then return end
	Layout()
	ApplyTextStyles()
	ApplyIcons()
	ResetLustGlow()
	Update()
end

function QOL:InitBResLust()
	if self._hookedBResLust then return end
	if not GetDB().enabled then return end

	CreateFrames()
	-- Only mark initialized once frames exist, so a transient creation failure
	-- can be retried by toggling the option again rather than poisoning state.
	if not (holder and bres and lust) then return end
	self._hookedBResLust = true

	eventFrame = CreateFrame('Frame')
	eventFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
	eventFrame:RegisterEvent('ZONE_CHANGED_NEW_AREA')
	eventFrame:RegisterEvent('SPELL_UPDATE_CHARGES')
	eventFrame:RegisterUnitEvent('UNIT_AURA', 'player')
	eventFrame:RegisterEvent('ENCOUNTER_START')
	eventFrame:RegisterEvent('ENCOUNTER_END')
	eventFrame:SetScript('OnEvent', Update)

	ticker = C_Timer.NewTicker(0.5, Update)
	Update()
end
