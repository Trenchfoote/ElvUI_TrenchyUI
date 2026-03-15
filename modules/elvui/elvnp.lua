local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local NP = E:GetModule('NamePlates')

local CreateFrame = CreateFrame
local ipairs = ipairs

function TUI:InitElvNP()
	local np = self.db.profile.nameplates
	if not np then return end

	-- Pending removal based on ElvUI updates
	if NamePlateFriendlyFrameOptions and TextureLoadingGroupMixin
		and NamePlateFriendlyFrameOptions.updateNameUsesGetUnitName then
		local wrapper = { textures = NamePlateFriendlyFrameOptions }
		NamePlateFriendlyFrameOptions.updateNameUsesGetUnitName = 0
		TextureLoadingGroupMixin.RemoveTexture(wrapper, 'updateNameUsesGetUnitName')
	end

	if np.classificationInstanceOnly then
		self:HookClassificationInstanceOnly()
	end

	-- Pending removal based on ElvUI updates
	if np.classificationOverThreat then
		self:HookNameplateThreat()
	end

	if np.interruptCastbarColors then
		self:HookCastbarInterrupt()
	end

	-- Pending removal based on ElvUI updates
	if np.focusGlow and np.focusGlow.enabled then
		self:InitFocusGlow()
	end

	if np.disableFriendlyHighlight then
		self:HookDisableFriendlyHighlight()
	end

	if np.questColor and np.questColor.enabled then
		self:HookQuestColor()
	end

end

do -- Classification Instance Only
	local IsInInstance = IsInInstance

	function TUI:HookClassificationInstanceOnly()
		if self._hookedClassificationInstance then return end
		self._hookedClassificationInstance = true

		hooksecurefunc(NP, 'Health_SetColors', function(_, nameplate, threatColors)
			if threatColors then return end
			if not IsInInstance() then
				nameplate.Health.colorClassification = nil
			end
		end)
	end
end

do -- Threat Override
	local UnitIsTapDenied = UnitIsTapDenied

	function TUI:HookNameplateThreat()
		if self._hookedThreatPost then return end
		self._hookedThreatPost = true

		hooksecurefunc(NP, 'ThreatIndicator_PostUpdate', function(Indicator, unit, status)
			local nameplate = Indicator.__owner

			if not status then
				-- Abrupt combat drop (Shadowmeld, Feign Death, etc.): restore color flags
				NP:Health_SetColors(nameplate, false)
				NP.Health_UpdateColor(nameplate, nil, unit)
				return
			end

			local db = NP.db.threat
			if not db or not db.enable or not db.useThreatColor or UnitIsTapDenied(unit) then return end

			local isTank = Indicator.isTank
			local isGoodThreat = isTank and (status == 3) or (not isTank and status == 0)
			if not isGoodThreat then return end

			nameplate.threatStatus = status
			nameplate.threatScale = 1
			NP:ScalePlate(nameplate, 1)
			NP:Health_SetColors(nameplate, false)
			NP.Health_UpdateColor(nameplate, nil, unit)
		end)
	end
end

-- Interrupt on CD (adapted from mMediaTag with permission from Blinkii, 2026-03-14)
do
	local GetSpellCooldownDuration = C_Spell.GetSpellCooldownDuration
	local EvalColorBool = C_CurveUtil.EvaluateColorValueFromBoolean
	local EvalColor = C_CurveUtil.EvaluateColorFromBoolean
	local UnitCanAttack = UnitCanAttack
	local UnitChannelInfo = UnitChannelInfo
	local GetSpecialization = GetSpecialization
	local GetSpecializationInfo = GetSpecializationInfo
	local IsPlayerSpell = IsPlayerSpell

	local INTERRUPT_BY_SPEC = {
		[71] = 6552, [72] = 6552, [73] = 6552,
		[65] = 96231, [66] = 96231, [70] = 96231,
		[253] = 147362, [254] = 147362, [255] = 187707,
		[259] = 1766, [260] = 1766, [261] = 1766,
		[256] = nil, [257] = nil, [258] = 15487,
		[250] = 47528, [251] = 47528, [252] = 47528,
		[262] = 57994, [263] = 57994, [264] = 57994,
		[62] = 2139, [63] = 2139, [64] = 2139,
		[265] = 119910, [266] = 119914, [267] = 119910,
		[268] = 116705, [269] = 116705, [270] = 116705,
		[102] = 78675, [103] = 106839, [104] = 106839, [105] = 106839,
		[577] = 183752, [581] = 183752, [1480] = 183752,
		[1467] = 351338, [1468] = 351338, [1473] = 351338,
	}

	local interruptSpellId
	local colors

	local function UpdateInterruptSpell()
		local spec = GetSpecialization()
		if not spec then return end
		local specId = GetSpecializationInfo(spec)

		if E.myclass == 'WARLOCK' then
			for _, spellId in ipairs({ 89766, 212619, 119914 }) do
				if IsPlayerSpell(spellId) then
					INTERRUPT_BY_SPEC[specId] = spellId
					break
				end
			end
		end

		interruptSpellId = INTERRUPT_BY_SPEC[specId]
	end

	local function CacheColors()
		local db = TUI.db.profile.nameplates
		colors = {
			ready = CreateColor(db.castbarInterruptReady.r, db.castbarInterruptReady.g, db.castbarInterruptReady.b),
			onCD = CreateColor(db.castbarInterruptOnCD.r, db.castbarInterruptOnCD.g, db.castbarInterruptOnCD.b),
			marker = db.castbarMarkerColor,
		}
	end

	local function GetInterruptCooldown()
		if interruptSpellId then return GetSpellCooldownDuration(interruptSpellId) end
	end

	local function PostCastFailInterrupted(castbar)
		local c = NP.db.colors.castInterruptedColor
		if c then castbar:SetStatusBarColor(c.r, c.g, c.b) end
		castbar.TUI_IsInterruptedOrFailed = true
	end

	local function SetKickSpark(castbar, castStart, cooldown)
		local unit = castbar.unit or castbar.__owner.unit
		if not (unit and UnitCanAttack('player', unit)) then return end

		local kickBar = castbar.TUI_KickBar
		local indicator = kickBar.TUI_Indicator
		if cooldown == nil then return end

		if castStart then
			local isChannel = UnitChannelInfo(unit) ~= nil
			local fillStyle = isChannel and Enum.StatusBarFillStyle.Reverse or Enum.StatusBarFillStyle.Standard
			local barAnchor = isChannel and 'LEFT' or 'RIGHT'
			local indicatorAnchor = isChannel and 'RIGHT' or 'LEFT'

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
			local c = colors.ready
			castbar:SetStatusBarColor(c.r, c.g, c.b)
			return
		end

		local unit = castbar.unit or castbar.__owner.unit
		if not (unit and UnitCanAttack('player', unit)) then return end

		local color = EvalColor(cooldown:IsZero(), colors.ready, colors.onCD)
		if castbar.notInterruptible ~= nil then color = EvalColor(castbar.notInterruptible, colors.ready, color) end
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
		if castbar._kickThrottle < 0.25 then return end
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

	function TUI:HookCastbarInterrupt()
		if self._hookedCastbarInterrupt then return end
		self._hookedCastbarInterrupt = true

		CacheColors()

		local f = CreateFrame('Frame')
		f:RegisterEvent('PLAYER_ENTERING_WORLD')
		f:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
		f:RegisterEvent('PLAYER_TALENT_UPDATE')
		f:SetScript('OnEvent', UpdateInterruptSpell)

		hooksecurefunc(NP, 'Castbar_PostCastStart', PostCastStart)
		hooksecurefunc(NP, 'Castbar_PostCastFail', PostCastFailInterrupted)
		hooksecurefunc(NP, 'Castbar_PostCastInterrupted', PostCastFailInterrupted)
	end
end

do -- Focus Overlay
	local LSM = E.Libs.LSM
	local UnitIsUnit = UnitIsUnit
	local C_NamePlate_GetNamePlates = C_NamePlate.GetNamePlates
	local C_NamePlate_GetNamePlateForUnit = C_NamePlate.GetNamePlateForUnit

	local function GetOrCreateFocusOverlay(nameplate)
		if nameplate.TUI_FocusOverlay then
			return nameplate.TUI_FocusOverlay
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

		if UnitIsUnit(nameplate.unit, 'focus') then
			local holder, tex = GetOrCreateFocusOverlay(nameplate)
			tex = tex or nameplate.TUI_FocusOverlayTex
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

		local f = CreateFrame('Frame')
		f:RegisterEvent('PLAYER_FOCUS_CHANGED')
		f:RegisterEvent('NAME_PLATE_UNIT_ADDED')
		f:RegisterEvent('NAME_PLATE_UNIT_REMOVED')
		f:SetScript('OnEvent', function(_, event, unit)
			if event == 'PLAYER_FOCUS_CHANGED' then
				UpdateAllFocusOverlays()
			elseif event == 'NAME_PLATE_UNIT_ADDED' then
				local nameplate = C_NamePlate_GetNamePlateForUnit(unit)
				if nameplate and nameplate.unitFrame then
					UpdateFocusOverlay(nameplate.unitFrame)
				end
			elseif event == 'NAME_PLATE_UNIT_REMOVED' then
				local nameplate = C_NamePlate_GetNamePlateForUnit(unit)
				if nameplate and nameplate.unitFrame and nameplate.unitFrame.TUI_FocusOverlay then
					nameplate.unitFrame.TUI_FocusOverlay:Hide()
				end
			end
		end)
	end
end

do -- Disable Friendly Highlight
	function TUI:HookDisableFriendlyHighlight()
		if self._hookedFriendlyHighlight then return end
		self._hookedFriendlyHighlight = true

		hooksecurefunc(NP, 'Update_Highlight', function(_, nameplate)
			if not nameplate or not nameplate.frameType then return end
			local ft = nameplate.frameType
			if (ft == 'FRIENDLY_PLAYER' or ft == 'FRIENDLY_NPC') and nameplate:IsElementEnabled('Highlight') then
				nameplate:DisableElement('Highlight')
			end
		end)
	end
end

do -- Quest Color
	local IsInInstance = IsInInstance

	local function ApplyQuestColor(nameplate)
		if IsInInstance() then return end
		if nameplate.TUI_QuestGUID ~= nameplate.unitGUID then return end
		local c = TUI.db.profile.nameplates.questColor.color
		NP:SetStatusBarColor(nameplate.Health, c.r, c.g, c.b)
	end

	function TUI:HookQuestColor()
		if self._hookedQuestColor then return end
		self._hookedQuestColor = true

		hooksecurefunc(NP, 'Health_UpdateColor', function(nameplate, _, unit)
			if not unit then return end
			ApplyQuestColor(nameplate)
		end)

		hooksecurefunc(NP, 'ThreatIndicator_PostUpdate', function(Indicator, _, status)
			if not status then return end
			ApplyQuestColor(Indicator.__owner)
		end)

		-- QuestIcons PostUpdate fires after tooltip scan; stamp GUID so stale data is never trusted
		local function QuestIconsPostUpdate(element)
			local nameplate = element.__owner
			if not nameplate or not nameplate.Health then return end
			nameplate.TUI_QuestGUID = element.lastQuests and nameplate.unitGUID or nil
			ApplyQuestColor(nameplate)
		end

		hooksecurefunc(NP, 'Update_QuestIcons', function(_, nameplate)
			local qi = nameplate and nameplate.QuestIcons
			if qi and qi.PostUpdate ~= QuestIconsPostUpdate then
				qi.PostUpdate = QuestIconsPostUpdate
			end
		end)
	end
end
