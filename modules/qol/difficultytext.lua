local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')

local LSM = E.Libs.LSM
local CreateFrame = CreateFrame
local tonumber, GetInstanceInfo = tonumber, GetInstanceInfo

local DIFF_CATEGORY = {
	[1]   = 'normal',  [14]  = 'normal',  [38]  = 'normal',
	[173] = 'normal',  [198] = 'normal',  [201] = 'normal',
	[2]   = 'heroic',  [15]  = 'heroic',  [39]  = 'heroic',
	[174] = 'heroic',
	[16]  = 'mythic',  [23]  = 'mythic',  [40]  = 'mythic',
	[8]   = 'keystoneMod',
	[24]  = 'timewalking', [33] = 'timewalking', [151] = 'timewalking',
	[7]   = 'lfr',     [17]  = 'lfr',
	[205] = 'follower',
	[208] = 'delve',
	[3]   = 'normal',  [4]   = 'normal',  [9]   = 'normal',
	[175] = 'normal',  [176] = 'normal',  [186] = 'normal',
	[148] = 'normal',  [185] = 'normal',  [215] = 'normal',
	[5]   = 'heroic',  [6]   = 'heroic',
	[193] = 'heroic',  [194] = 'heroic',
}

local DIFF_LABEL = {
	normal      = 'N',
	heroic      = 'H',
	mythic      = 'M',
	keystoneMod = 'M+',
	timewalking = 'TW',
	lfr         = 'LFR',
	follower    = 'FD',
	delve       = 'D',
	other       = '?',
}

local fallbackWhite = { r = 1, g = 1, b = 1 }
local fallbackKeystone = { r = 1, g = 0.5, b = 0 }
local fallbackDelve = { r = 0.8, g = 0.6, b = 0.2 }

local diffTextFrame, diffFontString, diffLevelString

local function CreateDifficultyText()
	if diffTextFrame then return end

	diffTextFrame = CreateFrame('Frame', 'TUI_DifficultyText', Minimap)
	diffTextFrame:SetSize(60, 20)
	diffTextFrame:SetFrameStrata('LOW')
	diffTextFrame:SetFrameLevel(10)

	local M = E:GetModule('Minimap')
	local iconDb = M and M.db and M.db.icons and M.db.icons.difficulty
	local position = iconDb and iconDb.position or 'TOPLEFT'
	local xOff = iconDb and iconDb.xOffset or 10
	local yOff = iconDb and iconDb.yOffset or 1
	diffTextFrame:SetPoint(position, Minimap, position, xOff, yOff)

	E:CreateMover(diffTextFrame, 'TUI_DifficultyTextMover', 'Difficulty Text', nil, nil, nil, 'ALL,TRENCHYUI', nil, 'TrenchyUI,qol')

	local db = TUI.db.profile.qol
	local fontPath = LSM:Fetch('font', db.difficultyFont or 'Expressway')
	local fontSize = db.difficultyFontSize or 14
	local fontOutline = db.difficultyFontOutline or 'OUTLINE'

	diffFontString = diffTextFrame:CreateFontString(nil, 'OVERLAY')
	diffFontString:FontTemplate(fontPath, fontSize, fontOutline)
	diffFontString:SetPoint('CENTER', diffTextFrame, 'CENTER', 0, 0)
	diffFontString:SetJustifyH('CENTER')

	diffLevelString = diffTextFrame:CreateFontString(nil, 'OVERLAY')
	diffLevelString:FontTemplate(fontPath, fontSize, fontOutline)
	diffLevelString:SetPoint('LEFT', diffFontString, 'RIGHT', 1, 0)
	diffLevelString:SetJustifyH('CENTER')
end

function TUI:UpdateDifficultyFont()
	if not diffFontString then return end
	local db = self.db.profile.qol
	local fontPath = LSM:Fetch('font', db.difficultyFont or 'Expressway')
	local fontSize = db.difficultyFontSize or 14
	local fontOutline = db.difficultyFontOutline or 'OUTLINE'
	diffFontString:FontTemplate(fontPath, fontSize, fontOutline)
	diffLevelString:FontTemplate(fontPath, fontSize, fontOutline)
end

local function UpdateDifficultyText()
	if not diffTextFrame then CreateDifficultyText() end

	local _, instanceType, difficultyID = GetInstanceInfo()
	if not difficultyID or difficultyID == 0 or instanceType == 'none' then
		diffTextFrame:Hide()
		return
	end

	local db = TUI.db.profile.qol
	local colors = db.difficultyColors or {}
	local category = DIFF_CATEGORY[difficultyID] or 'other'
	local label = DIFF_LABEL[category] or '?'
	local c = colors[category] or colors.other or fallbackWhite

	diffFontString:SetText(label)
	diffFontString:SetTextColor(c.r, c.g, c.b, 1)

	if category == 'keystoneMod' then
		local level = C_ChallengeMode.IsChallengeModeActive()
			and C_ChallengeMode.GetActiveKeystoneInfo()
		if level and level > 0 then
			local kc = colors.keystoneMod or fallbackKeystone
			diffLevelString:SetText(level)
			diffLevelString:SetTextColor(kc.r, kc.g, kc.b, 1)
			diffLevelString:Show()
		else
			diffLevelString:Hide()
		end
	elseif category == 'delve' then
		local info = C_UIWidgetManager
			and C_UIWidgetManager.GetScenarioHeaderDelvesWidgetVisualizationInfo
			and C_UIWidgetManager.GetScenarioHeaderDelvesWidgetVisualizationInfo(6183)
		local tier = info and tonumber(info.tierText)
		if tier and tier > 0 then
			local dc = colors.delve or fallbackDelve
			diffLevelString:SetText(tier)
			diffLevelString:SetTextColor(dc.r, dc.g, dc.b, 1)
			diffLevelString:Show()
		else
			diffLevelString:Hide()
		end
	else
		diffLevelString:Hide()
	end

	diffTextFrame:Show()
end

local function HideBlizzardDifficultyFlag()
	local difficulty = MinimapCluster and MinimapCluster.InstanceDifficulty
	if not difficulty then return end

	difficulty:SetAlpha(0)
	difficulty:SetSize(1, 1)

	for _, childName in ipairs({ 'Instance', 'Guild', 'ChallengeMode' }) do
		local child = difficulty[childName]
		if child then child:SetAlpha(0); child:Hide() end
	end

	for _, region in ipairs({ difficulty:GetRegions() }) do
		region:SetAlpha(0)
		if region.Hide then region:Hide() end
	end
end

function TUI:InitDifficultyText()
	HideBlizzardDifficultyFlag()
	CreateDifficultyText()
	UpdateDifficultyText()

	local function OnDifficultyEvent()
		HideBlizzardDifficultyFlag()
		UpdateDifficultyText()
	end

	TUI:RegisterEvent('PLAYER_DIFFICULTY_CHANGED', OnDifficultyEvent)
	TUI:RegisterEvent('ZONE_CHANGED', OnDifficultyEvent)
	TUI:RegisterEvent('ZONE_CHANGED_INDOORS', OnDifficultyEvent)
	TUI:RegisterEvent('ZONE_CHANGED_NEW_AREA', OnDifficultyEvent)
	TUI:RegisterEvent('PLAYER_ENTERING_WORLD', OnDifficultyEvent)
	TUI:RegisterEvent('CHALLENGE_MODE_START', OnDifficultyEvent)
	TUI:RegisterEvent('CHALLENGE_MODE_COMPLETED', OnDifficultyEvent)
	TUI:RegisterEvent('CHALLENGE_MODE_RESET', OnDifficultyEvent)
	TUI:RegisterEvent('UPDATE_INSTANCE_INFO', OnDifficultyEvent)
end
