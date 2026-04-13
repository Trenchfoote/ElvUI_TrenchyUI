local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local NPS = E:GetModule('TUI_Nameplates')
local NP = E:GetModule('NamePlates')

local IsSpellImportant = C_Spell and C_Spell.IsSpellImportant
local EDGE_FILE = [[Interface\BUTTONS\WHITE8X8]]
local backdropInfo = { edgeFile = EDGE_FILE, edgeSize = 2 }

local trackedPlates = {}

local function GetDB()
	return TUI.db.profile.nameplates.importantCast
end

-- Frame creation helpers

local function GetOrCreateCastbarBorder(castbar)
	if castbar.TUI_ImportantBorder then return castbar.TUI_ImportantBorder end
	local border = CreateFrame('Frame', nil, castbar, 'BackdropTemplate')
	border:SetFrameLevel(castbar:GetFrameLevel() + 5)
	border:Hide()
	castbar.TUI_ImportantBorder = border
	return border
end

local function GetOrCreateHealthBorder(nameplate)
	local health = nameplate.Health
	if not health then return end
	if health.TUI_ImportantBorder then return health.TUI_ImportantBorder end
	local border = CreateFrame('Frame', nil, health, 'BackdropTemplate')
	border:SetFrameLevel(health:GetFrameLevel() + 5)
	border:Hide()
	health.TUI_ImportantBorder = border
	return border
end

local function GetOrCreateHealthOverlay(nameplate)
	local health = nameplate.Health
	if not health then return end
	if health.TUI_ImportantOverlay then return health.TUI_ImportantOverlay end
	local fillTex = health:GetStatusBarTexture()
	local overlay = health:CreateTexture(nil, 'OVERLAY', nil, 7)
	overlay:SetTexture(EDGE_FILE)
	overlay:SetBlendMode('BLEND')
	overlay:SetPoint('TOPLEFT', fillTex, 'TOPLEFT')
	overlay:SetPoint('BOTTOMRIGHT', fillTex, 'BOTTOMRIGHT')
	overlay:SetAlpha(0)
	health.TUI_ImportantOverlay = overlay
	return overlay
end

-- Apply functions (called when isImportant is confirmed)

local function ApplyCastbar(castbar, db)
	local cbDB = db.castbar
	if not cbDB then return end

	-- Border
	if cbDB.borderEnabled then
		local border = GetOrCreateCastbarBorder(castbar)
		local t = cbDB.thickness or 2
		border:ClearAllPoints()
		border:SetPoint('TOPLEFT', castbar, -t, t)
		border:SetPoint('BOTTOMRIGHT', castbar, t, -t)
		backdropInfo.edgeSize = t
		border:SetBackdrop(backdropInfo)
		local r, g, b, a
		if cbDB.classColor then
			local c = E:ClassColor(E.myclass)
			r, g, b, a = c.r, c.g, c.b, cbDB.borderColor.a
		else
			r, g, b, a = cbDB.borderColor.r, cbDB.borderColor.g, cbDB.borderColor.b, cbDB.borderColor.a
		end
		border:SetBackdropBorderColor(r, g, b, a)
		border:Show()
	end

	-- Bar color
	if cbDB.colorEnabled then
		local c = cbDB.barColor
		castbar:SetStatusBarColor(c.r, c.g, c.b)
	end

	-- Bar texture
	if cbDB.texture and cbDB.texture ~= '' then
		local LSM = E.Libs.LSM
		castbar:SetStatusBarTexture(LSM:Fetch('statusbar', cbDB.texture))
	end
end

local function ApplyHealth(nameplate, db)
	local hDB = db.health
	if not hDB then return end

	-- Color overlay
	if hDB.overlayEnabled then
		local overlay = GetOrCreateHealthOverlay(nameplate)
		if overlay then
			local c = hDB.overlayColor
			overlay:SetVertexColor(c.r, c.g, c.b)
			overlay:SetAlpha(c.a or 0.3)
		end
	end

	-- Border
	if hDB.borderEnabled then
		local border = GetOrCreateHealthBorder(nameplate)
		if border then
			local t = hDB.thickness or 2
			border:ClearAllPoints()
			border:SetPoint('TOPLEFT', nameplate.Health, -t, t)
			border:SetPoint('BOTTOMRIGHT', nameplate.Health, t, -t)
			backdropInfo.edgeSize = t
			border:SetBackdrop(backdropInfo)
			local c = hDB.borderColor
			border:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
			border:Show()
		end
	end
end


-- Remove functions (called when cast ends)

local function RemoveCastbar(castbar)
	local border = castbar.TUI_ImportantBorder
	if border then border:Hide() end
end

local function RemoveHealth(nameplate)
	local health = nameplate.Health
	if not health then return end

	local overlay = health.TUI_ImportantOverlay
	if overlay then overlay:SetAlpha(0) end

	local border = health.TUI_ImportantBorder
	if border then border:Hide() end
end


-- Core trigger

local function ApplyImportant(castbar)
	local db = GetDB()
	local nameplate = castbar.__owner
	if not nameplate then return end

	ApplyCastbar(castbar, db)
	ApplyHealth(nameplate, db)

	trackedPlates[nameplate] = true
end

local function RemoveImportant(castbar)
	RemoveCastbar(castbar)

	local nameplate = castbar.__owner
	if not nameplate then return end
	if not trackedPlates[nameplate] then return end

	RemoveHealth(nameplate)
	trackedPlates[nameplate] = nil
end

local function CheckImportant(castbar)
	local spellID = castbar.spellID
	if not spellID then
		RemoveImportant(castbar)
		return
	end

	local isImportant = IsSpellImportant(spellID)
	if E:IsSecretValue(isImportant) then
		-- Secret boolean: show elements, let alpha handle visibility
		local db = GetDB()
		local nameplate = castbar.__owner

		-- Castbar border
		if db.castbar and db.castbar.borderEnabled then
			local border = GetOrCreateCastbarBorder(castbar)
			ApplyCastbar(castbar, db)
			border:SetAlphaFromBoolean(isImportant, 1, 0)
		end

		-- Health overlay
		if nameplate and db.health and db.health.overlayEnabled then
			local overlay = GetOrCreateHealthOverlay(nameplate)
			if overlay then
				local c = db.health.overlayColor
				overlay:SetVertexColor(c.r, c.g, c.b)
				overlay:SetAlphaFromBoolean(isImportant, c.a or 0.3, 0)
			end
		end

		-- Health border
		if nameplate and db.health and db.health.borderEnabled then
			local border = GetOrCreateHealthBorder(nameplate)
			if border then
				ApplyHealth(nameplate, db)
				border:SetAlphaFromBoolean(isImportant, 1, 0)
			end
		end

		if nameplate then trackedPlates[nameplate] = true end
	elseif isImportant then
		ApplyImportant(castbar)
	else
		RemoveImportant(castbar)
	end
end

-- Init

function NPS:HookImportantCast()
	if self._hookedImportantCast then return end
	self._hookedImportantCast = true

	if not IsSpellImportant then return end

	hooksecurefunc(NP, 'Castbar_PostCastStart', function(castbar)
		if castbar then CheckImportant(castbar) end
	end)

	hooksecurefunc(NP, 'Castbar_PostCastStop', function(castbar)
		if castbar then RemoveImportant(castbar) end
	end)

	hooksecurefunc(NP, 'Castbar_PostCastFail', function(castbar)
		if castbar then RemoveImportant(castbar) end
	end)

	hooksecurefunc(NP, 'Castbar_PostCastInterrupted', function(castbar)
		if castbar then RemoveImportant(castbar) end
	end)

	-- Clean up on plate removal
	local cleanupFrame = CreateFrame('Frame')
	cleanupFrame:RegisterEvent('NAME_PLATE_UNIT_REMOVED')
	cleanupFrame:SetScript('OnEvent', function(_, _, unit)
		if not unit then return end
		local plate = C_NamePlate.GetNamePlateForUnit(unit)
		if plate and plate.unitFrame and trackedPlates[plate.unitFrame] then
			RemoveHealth(plate.unitFrame)
			trackedPlates[plate.unitFrame] = nil
		end
	end)
end
