-- Guardian Druid Ironfur tracker: per-cast tick model with talent-aware duration.
-- Stays event-driven from UNIT_SPELLCAST_SUCCEEDED (no aura sync) so secret-value
-- restrictions in 12.x don't cause drift the way the prior single-bar implementation did.
local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local UFC = E:GetModule('TUI_UnitFrames')
local UF = E:GetModule('UnitFrames')
local LSM = E.Libs.LSM

local CreateFrame = CreateFrame
local GetTime = GetTime
local C_Timer_After = C_Timer.After
local hooksecurefunc = hooksecurefunc
local IsSpellKnown = C_SpellBook.IsSpellKnown
local PlayerBank = Enum.SpellBookSpellBank.Player
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local GetShapeshiftForm = GetShapeshiftForm
local tinsert = table.insert
local tremove = table.remove
local mathmax = math.max

local IRONFUR_ID = 192081
local URSOCS_ENDURANCE = 393611
local GUARDIAN_OF_ELUNE = 155578
local GOE_BONUS = 3
local GOE_WINDOW = 15
local MANGLE = 33917
local FRENZIED_REGEN = 22842
local GUARDIAN_SPEC = 104
local BEAR_FORM = 1

local holder, bar, leftBG, counterText, eventFrame
local activeTicks = {}
local tickPool = {}
local goeReadyUntil = 0
local currentBaseDuration = 7
local cachedW, cachedH = 0, 0

local function GetDB() return TUI.db.profile.ironfurBar end

local function IsGuardianSpec()
	local s = GetSpecialization()
	local id = s and GetSpecializationInfo(s)
	return id == GUARDIAN_SPEC
end

local function BaseDuration()
	return IsSpellKnown(URSOCS_ENDURANCE, PlayerBank) and 9 or 7
end

local function StackColor(count)
	local db = GetDB()
	if not db.useStackColors or count == 0 then return db.tickColor end
	if count >= 4 then return db.stackColors[4] end
	return db.stackColors[count] or db.stackColors[1]
end

-- Tick frame pool (reused across casts; max ~10 alive at once)
local function AcquireTick()
	local tick = tremove(tickPool)
	if not tick then
		tick = CreateFrame('Frame', nil, bar)
		tick.tex = tick:CreateTexture(nil, 'ARTWORK')
		tick.tex:SetAllPoints()
	end
	tick:Show()
	return tick
end

local function ReleaseTick(tick)
	tick:Hide()
	tinsert(tickPool, tick)
end

local function ReleaseAllTicks()
	for i = #activeTicks, 1, -1 do
		ReleaseTick(activeTicks[i])
		activeTicks[i] = nil
	end
end

local function StopTicker()
	if bar then bar:SetScript('OnUpdate', nil) end
end

local function CreateTick(duration)
	if not bar then return end
	local tick = AcquireTick()
	tick.duration = duration
	tick.endTime = GetTime() + duration

	local c = GetDB().tickColor
	tick.tex:SetColorTexture(c.r, c.g, c.b, c.a or 1)

	tinsert(activeTicks, tick)

	if not holder:IsShown() then holder:Show() end
	-- Kick the OnUpdate ticker the moment the first tick appears
	if #activeTicks == 1 then bar:SetScript('OnUpdate', UFC.IronfurOnUpdate) end
end

-- Cast handlers
local function OnIronfurCast()
	local hasGoE = goeReadyUntil > 0
		and GetTime() < goeReadyUntil
		and IsSpellKnown(GUARDIAN_OF_ELUNE, PlayerBank)
	local dur = currentBaseDuration + (hasGoE and GOE_BONUS or 0)
	CreateTick(dur)
	if hasGoE then goeReadyUntil = 0 end
end

local function OnMangleCast()
	if IsSpellKnown(GUARDIAN_OF_ELUNE, PlayerBank) then
		goeReadyUntil = GetTime() + GOE_WINDOW
	end
end

local function OnFrenziedRegenCast()
	goeReadyUntil = 0
end

-- OnUpdate: drain active ticks; update leading bar + counter text
function UFC.IronfurOnUpdate()
	if not holder:IsShown() then return end
	local now = GetTime()
	local db = GetDB()
	local maxDur = currentBaseDuration + GOE_BONUS
	local width = bar:GetWidth()
	local barH = bar:GetHeight()
	local maxProgress, maxRemaining = nil, 0

	for i = #activeTicks, 1, -1 do
		local tick = activeTicks[i]
		local remaining = tick.endTime - now
		if remaining <= 0 then
			ReleaseTick(tick)
			tremove(activeTicks, i)
		else
			local progress
			if db.uniformTickSpeed then
				progress = remaining / maxDur
			else
				progress = remaining / (tick.duration or currentBaseDuration)
			end
			local tickW = db.tickWidth or 2
			tick:SetSize(tickW, barH)
			tick:ClearAllPoints()
			-- Clamp the LEFT anchor so the tick stays fully inside the bar at both edges.
			local x = progress * width
			if x > width - tickW then x = width - tickW end
			if x < 0 then x = 0 end
			tick:SetPoint('LEFT', bar, 'LEFT', x, 0)
			if not maxProgress or progress > maxProgress then
				maxProgress = progress
				maxRemaining = remaining
			end
		end
	end

	if leftBG then
		if maxProgress then
			leftBG:SetWidth(mathmax(1, maxProgress * width))
			local c = StackColor(#activeTicks)
			leftBG:SetVertexColor(c.r, c.g, c.b, c.a or 1)
			leftBG:Show()
		else
			leftBG:Hide()
		end
	end

	if counterText then
		local mode = db.counterMode or 'stacks'
		if mode == 'off' or #activeTicks == 0 then
			counterText:SetText('')
		elseif mode == 'seconds' then
			counterText:SetFormattedText('%d', maxRemaining)
		elseif mode == 'both' then
			counterText:SetFormattedText('%dx %ds', #activeTicks, maxRemaining)
		else
			counterText:SetText(tostring(#activeTicks))
		end
	end

	if #activeTicks == 0 then
		StopTicker()
		if not db.showWhenInactive then holder:Hide() end
	end
end

-- Re-anchor holder to ClassBarMover the moment it appears (e.g. user enables a detached classbar
-- in another spec while we're in Guardian). No-op if already anchored to the same target.
local function AnchorHolder()
	if not holder then return end
	local target = _G.ClassBarMover or E.UIParent
	if holder._tuiAnchorTarget == target then return end
	holder._tuiAnchorTarget = target
	holder:ClearAllPoints()
	holder:SetAllPoints(target)
end

local function LayoutBar()
	if not bar or not holder then return end
	AnchorHolder()

	local BORDER = UF.BORDER or 2
	local UISPACING = UF.SPACING or 1
	local SPACING = (BORDER + UISPACING) * 2

	local width = holder:GetWidth()
	local height = holder:GetHeight()
	if width == cachedW and height == cachedH then return end
	cachedW, cachedH = width, height

	bar:SetSize(width - SPACING, height - SPACING)
	bar:ClearAllPoints()
	bar:SetPoint('BOTTOMLEFT', holder, 'BOTTOMLEFT', BORDER + UISPACING, BORDER + UISPACING)

	local bc = E.db.unitframe.colors and E.db.unitframe.colors.borderColor
	if bar.backdrop and bc and not bar.backdrop.forcedBorderColors then
		bar.backdrop:SetBackdropBorderColor(bc.r, bc.g, bc.b)
	end
end

local function UpdateVisibility()
	if not holder then return end
	local db = GetDB()
	if not IsGuardianSpec() then
		holder:Hide()
		ReleaseAllTicks()
		StopTicker()
		return
	end
	if GetShapeshiftForm() == BEAR_FORM then
		-- Drop ticks that silently expired while we were out of Bear (OnUpdate was
		-- gated by IsShown so didn't release them). Survivors are still accurate
		-- since Ironfur can only be cast in Bear — no missed casts to recover.
		if #activeTicks > 0 then
			local now = GetTime()
			for i = #activeTicks, 1, -1 do
				if activeTicks[i].endTime <= now then
					ReleaseTick(activeTicks[i])
					tremove(activeTicks, i)
				end
			end
		end
		if #activeTicks > 0 or db.showWhenInactive then
			holder:Show()
			if #activeTicks > 0 then bar:SetScript('OnUpdate', UFC.IronfurOnUpdate) end
		end
	else
		-- Hide visually but keep activeTicks intact. Ironfur can't be cast outside
		-- Bear, so our predictive state remains accurate; OnUpdate stays stopped
		-- to save CPU, and surviving ticks are re-shown on Bear return above.
		holder:Hide()
		StopTicker()
	end
end

local function OnEvent(_frame, event, arg1, _arg2, arg3)
	if event == 'UNIT_SPELLCAST_SUCCEEDED' then
		if arg1 ~= 'player' then return end
		local spellID = arg3
		if spellID == IRONFUR_ID then OnIronfurCast()
		elseif spellID == MANGLE then OnMangleCast()
		elseif spellID == FRENZIED_REGEN then OnFrenziedRegenCast() end
	elseif event == 'UPDATE_SHAPESHIFT_FORM' then
		UpdateVisibility()
	elseif event == 'PLAYER_SPECIALIZATION_CHANGED' then
		currentBaseDuration = BaseDuration()
		UpdateVisibility()
	elseif event == 'PLAYER_TALENT_UPDATE' or event == 'TRAIT_CONFIG_UPDATED' then
		currentBaseDuration = BaseDuration()
	end
end

local function CreateBar()
	if holder then return end
	local db = GetDB()

	-- Anchor mirrors ElvUI's ClassBarMover so position/size follow whatever the user has
	-- configured for their classbar. Falls back to UIParent when no detached classbar
	-- exists yet (e.g. Guardian-only Druids who've never detached one in another spec).
	holder = CreateFrame('Frame', 'TUI_IronfurHolder', E.UIParent)
	holder:Hide()

	bar = CreateFrame('Frame', 'TUI_IronfurBar', holder)
	bar:CreateBackdrop(nil, nil, nil, nil, true)

	local tex = LSM:Fetch('statusbar', E.db.unitframe and E.db.unitframe.statusbar or 'ElvUI Norm')
	leftBG = bar:CreateTexture(nil, 'BORDER')
	leftBG:SetTexture(tex)
	leftBG:SetPoint('LEFT', bar, 'LEFT', 0, 0)
	leftBG:SetPoint('TOP', bar, 'TOP', 0, 0)
	leftBG:SetPoint('BOTTOM', bar, 'BOTTOM', 0, 0)
	leftBG:SetWidth(1)
	leftBG:Hide()

	counterText = bar:CreateFontString(nil, 'OVERLAY')
	counterText:FontTemplate(LSM:Fetch('font', 'Expressway'), db.counterFontSize or 14, 'OUTLINE')
	counterText:SetPoint('CENTER', bar, 'CENTER', db.counterOffsetX or 0, db.counterOffsetY or 0)

	LayoutBar()

	-- Re-layout when ElvUI reconfigures the player classbar (geometry change)
	hooksecurefunc(UF, 'Configure_ClassBar', function(_, frame)
		if frame ~= UF.player then return end
		cachedW, cachedH = 0, 0
		C_Timer_After(0, LayoutBar)
	end)

	-- Mirror player-frame fader onto our holder
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
	eventFrame:RegisterEvent('UPDATE_SHAPESHIFT_FORM')
	eventFrame:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED')
	eventFrame:RegisterEvent('PLAYER_TALENT_UPDATE')
	eventFrame:RegisterEvent('TRAIT_CONFIG_UPDATED')
end

function UFC:RefreshIronfurBar()
	if not holder then return end
	local db = GetDB()
	local tex = LSM:Fetch('statusbar', E.db.unitframe and E.db.unitframe.statusbar or 'ElvUI Norm')
	if leftBG then leftBG:SetTexture(tex) end
	if counterText then
		counterText:FontTemplate(LSM:Fetch('font', 'Expressway'), db.counterFontSize or 14, 'OUTLINE')
		counterText:ClearAllPoints()
		counterText:SetPoint('CENTER', bar, 'CENTER', db.counterOffsetX or 0, db.counterOffsetY or 0)
	end
	cachedW, cachedH = 0, 0
	LayoutBar()
	UpdateVisibility()
end

function UFC:InitIronfurBar()
	if E.myclass ~= 'DRUID' then return end
	if self._hookedIronfur then return end
	local db = GetDB()
	if not db or not db.enabled then return end
	self._hookedIronfur = true

	currentBaseDuration = BaseDuration()
	-- Register events eagerly so casts fired before deferred CreateBar still update state.
	RegisterEvents()
	-- Defer frame creation: ElvUI player frame and classbar may not be assembled yet.
	C_Timer_After(0, function()
		CreateBar()
		UpdateVisibility()
	end)
end
