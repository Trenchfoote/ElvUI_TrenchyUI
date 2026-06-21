local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local QOL = E:GetModule('TUI_QoL')
local LSM = E.Libs.LSM

local CreateFrame = CreateFrame
local C_Timer_NewTicker = C_Timer.NewTicker
local IsInInstance, IsInRaid, IsInGroup = IsInInstance, IsInRaid, IsInGroup
local GetNumGroupMembers = GetNumGroupMembers
local UnitExists, UnitIsDead, UnitIsFeignDeath = UnitExists, UnitIsDead, UnitIsFeignDeath
local PlaySound, PlaySoundFile = PlaySound, PlaySoundFile
local ipairs, pairs, wipe, tonumber, type = ipairs, pairs, wipe, tonumber, type

local POLL_INTERVAL = 0.5

local units = {}
local deadState = {}
local ticker
local active = false

local function GetDB() return TUI.db.profile.qol.partyDeath end

-- Dispatch a stored sound key: 'cdm:<soundKitID>' is a Cooldown Manager alert sound (PlaySound); anything else is an LSM sound (PlaySoundFile).
local function PlayKey(key)
	if not key or key == 'None' then return end
	local kit = key:match('^cdm:(%d+)')
	if kit then
		PlaySound(tonumber(kit))
	else
		local file = LSM:Fetch('sound', key, true)
		if file then PlaySoundFile(file, 'Master') end
	end
end

-- Watched group units, including the player. CLEU/UNIT_DIED is restricted in 12.x, so we poll death state instead.
local function RebuildUnits()
	wipe(units)
	if IsInRaid() then
		for i = 1, GetNumGroupMembers() do units[#units + 1] = 'raid' .. i end
	elseif IsInGroup() then
		for i = 1, GetNumGroupMembers() - 1 do units[#units + 1] = 'party' .. i end
		units[#units + 1] = 'player'
	else
		units[#units + 1] = 'player'
	end
end

-- UnitIsDead/UnitIsFeignDeath return plain (non-secret) bools; feign death is excluded. Simultaneous deaths play one sound.
local function Poll()
	local db = GetDB()
	if not db.enabled then return end
	local newDeath = false
	for _, unit in ipairs(units) do
		if UnitExists(unit) and UnitIsDead(unit) and not UnitIsFeignDeath(unit) then
			if not deadState[unit] then deadState[unit] = true; newDeath = true end
		elseif deadState[unit] then
			deadState[unit] = nil
		end
	end
	if newDeath then PlayKey(GetDB().sound) end
end

-- Run only where the player has enabled it (outside / dungeon / raid).
local function ShouldRun()
	local db = GetDB()
	if not db.enabled then return false end
	local _, itype = IsInInstance()
	if itype == 'raid' then return db.useInRaid end
	if itype == 'party' then return db.useInDungeon end
	if itype == 'none' then return db.useOutside end
	return false
end

local function UpdateActive()
	local shouldRun = ShouldRun()
	if shouldRun and not active then
		active = true
		wipe(deadState)
		RebuildUnits()
		ticker = C_Timer_NewTicker(POLL_INTERVAL, Poll)
	elseif not shouldRun and active then
		active = false
		if ticker then ticker:Cancel(); ticker = nil end
		wipe(units)
		wipe(deadState)
	end
end

-- Recurse Blizzard's nested CooldownViewerSoundData (the Cooldown Manager "New Alert" list, grouped by category) collecting playable entries.
local function CollectCDMSounds(tbl, out)
	for _, value in pairs(tbl) do
		if type(value) == 'table' then
			if value.soundEnum and value.text and value.soundKitID then
				out['cdm:' .. value.soundKitID] = '|cff82c5ff' .. value.text .. '|r'
			else
				CollectCDMSounds(value, out)
			end
		end
	end
end

-- Merged dropdown list: LSM sounds + the Cooldown Manager "New Alert" sounds (tinted, keyed 'cdm:<soundKitID>').
function QOL:GetDeathSoundList()
	local t = { None = 'None' }
	for name in pairs(LSM:HashTable('sound')) do t[name] = name end
	if CooldownViewerSoundData then CollectCDMSounds(CooldownViewerSoundData, t) end
	return t
end

function QOL:PreviewDeathSound(key)
	PlayKey(key)
end

-- Dedicated frame: difficultyText already owns PLAYER_ENTERING_WORLD / ZONE_CHANGED_NEW_AREA on the QoL AceEvent object, so a separate frame avoids clobbering its handlers.
local eventFrame = CreateFrame('Frame')
eventFrame:SetScript('OnEvent', function(_, event)
	if event == 'GROUP_ROSTER_UPDATE' then
		if active then RebuildUnits() end
	else
		UpdateActive()
	end
end)

function QOL:InitPartyDeath()
	if eventFrame.tuiInit then return end
	eventFrame.tuiInit = true
	-- defer: Frame:RegisterEvent is protected during ElvUI's InitializeModules callstack
	C_Timer.After(0, function()
		eventFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
		eventFrame:RegisterEvent('ZONE_CHANGED_NEW_AREA')
		eventFrame:RegisterEvent('GROUP_ROSTER_UPDATE')
		UpdateActive()
	end)
end

function QOL:RefreshPartyDeath()
	UpdateActive()
end
