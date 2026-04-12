local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local NPS = E:GetModule('TUI_Nameplates')
local NP = E:GetModule('NamePlates')
local LSM = E.Libs.LSM

local IsSpellImportant = C_Spell and C_Spell.IsSpellImportant

local EDGE_FILE = [[Interface\BUTTONS\WHITE8X8]]
local backdropInfo = { edgeFile = EDGE_FILE, edgeSize = 2 }

local function GetDB()
	return TUI.db.profile.nameplates.importantCast
end

-- Castbar border
local function GetOrCreateBorder(castbar)
	if castbar.TUI_ImportantBorder then return castbar.TUI_ImportantBorder end
	local border = CreateFrame('Frame', nil, castbar, 'BackdropTemplate')
	border:SetFrameLevel(castbar:GetFrameLevel() + 5)
	border:Hide()
	castbar.TUI_ImportantBorder = border
	return border
end

local function ApplyBorderStyle(border, castbar)
	local db = GetDB()
	local thickness = db.thickness or 2
	border:ClearAllPoints()
	border:SetPoint('TOPLEFT', castbar, -thickness, thickness)
	border:SetPoint('BOTTOMRIGHT', castbar, thickness, -thickness)
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

-- Health border
local function GetOrCreateHealthBorder(nameplate)
	if nameplate.TUI_ImportantHealthBorder then return nameplate.TUI_ImportantHealthBorder end
	local health = nameplate.Health
	if not health then return end
	local border = CreateFrame('Frame', nil, health, 'BackdropTemplate')
	border:SetFrameLevel(health:GetFrameLevel() + 5)
	border:Hide()
	nameplate.TUI_ImportantHealthBorder = border
	return border
end

-- Apply all important cast enhancements
local function ApplyImportantStyle(castbar)
	local db = GetDB()
	local nameplate = castbar.__owner
	if not nameplate then return end

	-- Castbar border
	local border = GetOrCreateBorder(castbar)
	ApplyBorderStyle(border, castbar)
	border:Show()

	-- Raise frame level
	if db.raiseLevel and nameplate.SetFrameLevel then
		nameplate._tuiOrigLevel = nameplate._tuiOrigLevel or nameplate:GetFrameLevel()
		nameplate:SetFrameLevel(nameplate._tuiOrigLevel + 50)
	end

	-- Scale
	if db.scale and db.scale ~= 1.0 then
		nameplate._tuiOrigScale = nameplate._tuiOrigScale or nameplate:GetScale()
		nameplate:SetScale(nameplate._tuiOrigScale * db.scale)
	end

	-- Health color
	if db.healthColor and nameplate.Health then
		local c = db.healthColorValue
		nameplate.Health:SetStatusBarColor(c.r, c.g, c.b)
		nameplate.Health._tuiImportantColored = true
	end

	-- Health texture
	if db.healthTexture and db.healthTexture ~= '' and nameplate.Health then
		nameplate.Health._tuiOrigTexture = nameplate.Health._tuiOrigTexture or nameplate.Health:GetStatusBarTexture():GetTexture()
		nameplate.Health:SetStatusBarTexture(LSM:Fetch('statusbar', db.healthTexture))
		nameplate.Health._tuiImportantTextured = true
	end

	-- Health border
	if db.healthBorder and nameplate.Health then
		local hBorder = GetOrCreateHealthBorder(nameplate)
		if hBorder then
			local thickness = db.thickness or 2
			hBorder:ClearAllPoints()
			hBorder:SetPoint('TOPLEFT', nameplate.Health, -thickness, thickness)
			hBorder:SetPoint('BOTTOMRIGHT', nameplate.Health, thickness, -thickness)
			backdropInfo.edgeSize = thickness
			hBorder:SetBackdrop(backdropInfo)
			local c = db.healthBorderColor
			hBorder:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
			hBorder:Show()
		end
	end

	-- Castbar color
	if db.castbarColor then
		local c = db.castbarColorValue
		castbar:SetStatusBarColor(c.r, c.g, c.b)
		castbar._tuiImportantCBColored = true
	end

	-- Castbar texture
	if db.castbarTexture and db.castbarTexture ~= '' then
		castbar._tuiOrigCBTexture = castbar._tuiOrigCBTexture or castbar:GetStatusBarTexture():GetTexture()
		castbar:SetStatusBarTexture(LSM:Fetch('statusbar', db.castbarTexture))
		castbar._tuiImportantCBTextured = true
	end

	-- Castbar border (separate from the existing outline border)
	if db.castbarBorder then
		local cbBorder = GetOrCreateBorder(castbar)
		local c = db.castbarBorderColor
		cbBorder:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
	end

	nameplate._tuiImportantActive = true
end

-- Remove all important cast enhancements
local function RemoveImportantStyle(castbar)
	local border = castbar.TUI_ImportantBorder
	if border and border:IsShown() then border:Hide() end

	local nameplate = castbar.__owner
	if not nameplate or not nameplate._tuiImportantActive then return end
	nameplate._tuiImportantActive = nil

	-- Restore frame level
	if nameplate._tuiOrigLevel then
		nameplate:SetFrameLevel(nameplate._tuiOrigLevel)
		nameplate._tuiOrigLevel = nil
	end

	-- Restore scale
	if nameplate._tuiOrigScale then
		nameplate:SetScale(nameplate._tuiOrigScale)
		nameplate._tuiOrigScale = nil
	end

	-- Force health color restore
	if nameplate.Health and nameplate.Health._tuiImportantColored then
		nameplate.Health._tuiImportantColored = nil
		if nameplate.unit then
			nameplate.Health:ForceUpdate()
		end
	end

	-- Restore health texture
	if nameplate.Health and nameplate.Health._tuiImportantTextured then
		if nameplate.Health._tuiOrigTexture then
			nameplate.Health:SetStatusBarTexture(nameplate.Health._tuiOrigTexture)
			nameplate.Health._tuiOrigTexture = nil
		end
		nameplate.Health._tuiImportantTextured = nil
	end

	-- Hide health border
	if nameplate.TUI_ImportantHealthBorder then
		nameplate.TUI_ImportantHealthBorder:Hide()
	end

	-- Restore castbar color — ElvUI re-applies on next cast start
	if castbar._tuiImportantCBColored then
		castbar._tuiImportantCBColored = nil
		local db = NP.db and NP.db.colors
		if db then
			castbar:SetStatusBarColor(db.castColor.r, db.castColor.g, db.castColor.b)
		end
	end

	-- Restore castbar texture
	if castbar._tuiImportantCBTextured then
		if castbar._tuiOrigCBTexture then
			castbar:SetStatusBarTexture(castbar._tuiOrigCBTexture)
			castbar._tuiOrigCBTexture = nil
		end
		castbar._tuiImportantCBTextured = nil
	end
end

local function CheckImportant(castbar)
	local spellID = castbar.spellID
	if not spellID then
		RemoveImportantStyle(castbar)
		return
	end

	local isImportant = IsSpellImportant(spellID)
	if E:IsSecretValue(isImportant) then
		ApplyImportantStyle(castbar)
		local border = castbar.TUI_ImportantBorder
		if border then border:SetAlphaFromBoolean(isImportant, 1, 0) end
	elseif isImportant then
		ApplyImportantStyle(castbar)
	else
		RemoveImportantStyle(castbar)
	end
end

function NPS:HookImportantCast()
	if self._hookedImportantCast then return end
	self._hookedImportantCast = true

	if not IsSpellImportant then return end

	hooksecurefunc(NP, 'Castbar_PostCastStart', function(castbar)
		if not castbar then return end
		CheckImportant(castbar)
	end)

	hooksecurefunc(NP, 'Castbar_PostCastStop', function(castbar)
		RemoveImportantStyle(castbar)
	end)

	hooksecurefunc(NP, 'Castbar_PostCastFail', function(castbar)
		RemoveImportantStyle(castbar)
	end)

	hooksecurefunc(NP, 'Castbar_PostCastInterrupted', function(castbar)
		RemoveImportantStyle(castbar)
	end)
end
