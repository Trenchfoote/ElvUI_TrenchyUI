-- CDM Reminders: instance-only icons for missing buffs, consumables, and pets
local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local CDM = E:GetModule('TUI_CDM')

local LCG = CDM.LCG
local LSM = CDM.LSM
local wipe = wipe
local ipairs = ipairs
local pcall = pcall
local UnitExists = UnitExists
local UnitClass = UnitClass
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local IsInInstance = IsInInstance
local GetNumGroupMembers = GetNumGroupMembers
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local IsPlayerSpell = IsPlayerSpell
local InCombatLockdown = InCombatLockdown
local GetItemCount = C_Item.GetItemCount
local GetWeaponEnchantInfo = GetWeaponEnchantInfo
local GetAuraDataByIndex = C_UnitAuras.GetAuraDataByIndex
local GetTime = GetTime
local math_floor = math.floor

local MAX_ICONS = 12
local TICKER_INTERVAL = 3
local GLOW_COLOR = { 0.95, 0.95, 0.32, 1 }
local GLOW_KEY = 'TUI_Reminder'
local DEFAULT_EXPIRATION_THRESHOLD = 600

-- Raid buff data
local RAID_BUFFS = {
	{ key = 'intellect',   buffID = 1459,   provider = 'MAGE' },
	{ key = 'fortitude',   buffID = 21562,  provider = 'PRIEST' },
	{ key = 'attackPower', buffID = 6673,   provider = 'WARRIOR' },
	{ key = 'markOfWild',  buffID = 1126,   provider = 'DRUID' },
	{ key = 'bronze',      buffID = 381732, provider = 'EVOKER' },
	{ key = 'skyfury',     buffID = 462854, provider = 'SHAMAN' },
}

-- Flask buff aura IDs (Midnight)
local FLASK_BUFFS = {
	[1235111] = true, -- Flask of the Shattered Sun (Crit)
	[1235108] = true, -- Flask of the Magisters (Mastery)
	[1235110] = true, -- Flask of the Blood Knights (Haste)
	[1235057] = true, -- Flask of Thalassian Resistance (Versatility)
	[1239355] = true, -- Vicious Thalassian Flask of Honor
}
local FLASK_ITEMS = {
	241320, 241321, 241322, 241323, 241324, 241325, 241326, 241327,
	241334, 241335,
	245926, 245927, 245928, 245929, 245930, 245931, 245932, 245933,
}
local FLASK_ICON = 1235111

-- Food: all Well Fed buffs share icon texture 136000
local FOOD_BUFF_ICON = 136000
local FOOD_ICON = 136000

-- Weapon enhancement items
local WEAPON_ITEMS = {
	243733, 243734, 243735, 243736, -- Oils
	237367, 237369, 237370, 237371, -- Stones
	243737, 243738,                 -- Smuggler's Edge
	257749, 257750, 257751, 257752, -- Engineering
}
local WEAPON_ICON = 1237008

-- Augment rune
local RUNE_BUFFS = { [1264426] = true }
local RUNE_ITEMS = { 259085 }
local RUNE_ICON = 1264426

-- Healthstone
local HEALTHSTONE_IDS = { 5512, 224464 }
local HEALTHSTONE_ICON = 5512

-- Warlock Soulwell
local CREATE_SOULWELL = 29893
local SOULWELL_ICON = 29893

-- Pet spec detection
local LONE_WOLF = 155228
local LONELY_WINTER = 205024
local PET_ICON = 883
local PET_SPECS = {
	[253] = true, [254] = true, [255] = true,
	[265] = true, [266] = true, [267] = true,
	[252] = true, [64] = true,
}

-- Raid buff set for scan lookup
local RAID_BUFF_SET = {}
for _, info in ipairs(RAID_BUFFS) do RAID_BUFF_SET[info.buffID] = true end

-- State
local reminderIcons = {}
local activeReminders = {}
local groupClasses = {}
local playerClass
local playerIsWarlock = false
local ticker

-- Scan results (reused table, wiped each cycle)
local scan = {
	hasFlask = false, flaskRemaining = nil,
	hasFood = false, foodRemaining = nil,
	hasRune = false, runeRemaining = nil,
	hasWeapon = false, weaponRemaining = nil,
	raidBuffs = {},
	restricted = false,
}

-- Single-pass aura scan: iterates all player buffs once, checks every category
-- If ANY field read fails (secret value), we mark restricted and assume buffed
local function ScanPlayerBuffs()
	scan.hasFlask = false; scan.flaskRemaining = nil
	scan.hasFood = false; scan.foodRemaining = nil
	scan.hasRune = false; scan.runeRemaining = nil
	scan.restricted = false
	wipe(scan.raidBuffs)

	local now = GetTime()
	local i = 1
	local data = GetAuraDataByIndex('player', i, 'HELPFUL')
	while data do
		local ok, _ = pcall(function()
			local id = data.spellId
			local remaining
			if data.expirationTime and data.expirationTime > 0 then
				remaining = data.expirationTime - now
			end

			-- Flask: check by spell ID and by name pattern
			if not scan.hasFlask then
				if id and FLASK_BUFFS[id] then
					scan.hasFlask = true
					scan.flaskRemaining = remaining
				elseif data.name and data.name:find('^Flask of') then
					scan.hasFlask = true
					scan.flaskRemaining = remaining
				end
			end

			-- Food: check by icon texture (all Well Fed buffs share 136000)
			if not scan.hasFood and data.icon == FOOD_BUFF_ICON then
				scan.hasFood = true
				scan.foodRemaining = remaining
			end

			-- Rune: check by spell ID and by name pattern
			if not scan.hasRune then
				if id and RUNE_BUFFS[id] then
					scan.hasRune = true
					scan.runeRemaining = remaining
				elseif data.name and data.name:find('Void%-Touched') then
					scan.hasRune = true
					scan.runeRemaining = remaining
				end
			end

			-- Raid buffs: mark present by spell ID
			if id and RAID_BUFF_SET[id] then
				scan.raidBuffs[id] = true
			end
		end)

		if not ok then
			scan.restricted = true
		end

		i = i + 1
		data = GetAuraDataByIndex('player', i, 'HELPFUL')
	end

	-- Weapon enchant: separate API, not aura-based
	local hasMain, mainExp = GetWeaponEnchantInfo()
	scan.hasWeapon = hasMain or false
	scan.weaponRemaining = hasMain and mainExp and (mainExp / 1000) or nil
end

-- Helpers
local function HasAnyItem(idList)
	for _, itemID in ipairs(idList) do
		if GetItemCount(itemID) > 0 then return true end
	end
	return false
end

local function FindFirstItem(idList)
	for _, itemID in ipairs(idList) do
		if GetItemCount(itemID) > 0 then return itemID end
	end
end

local function ScanGroupClasses()
	wipe(groupClasses)
	if playerClass then groupClasses[playerClass] = true end
	if not IsInGroup() then return end
	local prefix = IsInRaid() and 'raid' or 'party'
	for i = 1, GetNumGroupMembers() do
		local unit = prefix .. i
		if UnitExists(unit) then
			local _, cls = UnitClass(unit)
			if cls then groupClasses[cls] = true end
		end
	end
end

local function ShouldHavePet()
	local specIndex = GetSpecialization()
	if not specIndex then return false end
	local specID = GetSpecializationInfo(specIndex)
	if not specID or not PET_SPECS[specID] then return false end
	if specID == 254 and IsPlayerSpell(LONE_WOLF) then return false end
	if specID == 64 and IsPlayerSpell(LONELY_WINTER) then return false end
	return true
end

local function HasHealthstone()
	return HasAnyItem(HEALTHSTONE_IDS)
end

local function FormatDuration(seconds)
	if not seconds or seconds <= 0 then return '' end
	local m = math_floor(seconds / 60)
	if m >= 60 then return math_floor(m / 60) .. 'h' end
	if m > 0 then return m .. 'm' end
	return '<1m'
end

local function SoulwellOffCooldown()
	if not IsPlayerSpell(CREATE_SOULWELL) then return false end
	local dur = C_Spell.GetSpellCooldownDuration(CREATE_SOULWELL)
	if not dur then return true end
	return dur:IsZero()
end

-- Secure action helpers
local function SetSpellAction(frame, spellID)
	local name = C_Spell.GetSpellName(spellID)
	if name then
		frame:SetAttribute('type', 'spell')
		frame:SetAttribute('spell', name)
	end
end

local function SetItemAction(frame, itemID)
	local name = C_Item.GetItemInfo(itemID)
	if name then
		frame:SetAttribute('type', 'item')
		frame:SetAttribute('item', name)
	else
		frame:SetAttribute('type', nil)
	end
end

local function ClearAction(frame)
	frame:SetAttribute('type', nil)
	frame:SetAttribute('spell', nil)
	frame:SetAttribute('item', nil)
end

-- Glow helpers
local function StartGlow(frame)
	if not LCG then return end
	LCG.PixelGlow_Start(frame, GLOW_COLOR, 8, 0.25, nil, 2, nil, nil, nil, GLOW_KEY)
	frame.tuiGlowing = true
end

local function StopGlow(frame)
	if not LCG or not frame.tuiGlowing then return end
	LCG.PixelGlow_Stop(frame, GLOW_KEY)
	frame.tuiGlowing = false
end

-- Icon frame creation
local function CreateReminderIcon(parent, index)
	local frame = CreateFrame('Button', 'TUI_CDM_Reminder' .. index, parent, 'SecureActionButtonTemplate,BackdropTemplate')
	frame:SetTemplate('Default')
	frame:SetFrameStrata('MEDIUM')
	frame:SetFrameLevel(6)
	frame:RegisterForClicks('AnyDown', 'AnyUp')

	local icon = frame:CreateTexture(nil, 'ARTWORK')
	icon:SetInside(frame)
	frame.icon = icon

	local duration = frame:CreateFontString(nil, 'OVERLAY')
	duration:SetPoint('CENTER', 0, 0)
	duration:FontTemplate(LSM:Fetch('font', 'Expressway'), 28, 'SLUGOUTLINE')
	duration:SetTextColor(1, 1, 1)
	frame.duration = duration

	frame:SetScript('OnEnter', function(self)
		if not self.tuiSpellID and not self.tuiItemID and not self.tuiLabel then return end
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
		if self.tuiItemID then
			GameTooltip:SetItemByID(self.tuiItemID)
		elseif self.tuiSpellID then
			GameTooltip:SetSpellByID(self.tuiSpellID)
		end
		if self.tuiLabel then
			GameTooltip:AddLine(' ')
			GameTooltip:AddLine(self.tuiLabel, 1, 0.2, 0.2)
		end
		GameTooltip:Show()
	end)
	frame:SetScript('OnLeave', GameTooltip_Hide)

	frame:Hide()
	return frame
end

-- Add a reminder to the active list
local function AddReminder(iconID, label, remaining, actionType, actionID, isItemIcon)
	local idx = #activeReminders + 1
	if idx > MAX_ICONS then return end

	local frame = reminderIcons[idx]
	if not frame then return end

	frame.tuiSpellID = nil
	frame.tuiItemID = nil
	frame.tuiLabel = label

	if isItemIcon then
		frame.icon:SetTexture(C_Item.GetItemIconByID(iconID))
		frame.tuiItemID = iconID
	else
		local tex = C_Spell.GetSpellTexture(iconID)
		if tex then
			frame.icon:SetTexture(tex)
			frame.tuiSpellID = iconID
		else
			frame.icon:SetTexture(iconID)
		end
	end

	if remaining then
		frame.icon:SetDesaturated(false)
		frame.icon:SetAlpha(1)
		frame.duration:SetText(FormatDuration(remaining))
	else
		frame.icon:SetDesaturated(true)
		frame.icon:SetAlpha(0.7)
		frame.duration:SetText('')
	end

	ClearAction(frame)

	local wantGlow = (actionType == 'spell' and actionID) or (actionType == 'item' and actionID)
	if wantGlow then
		if actionType == 'spell' then
			SetSpellAction(frame, actionID)
		else
			SetItemAction(frame, actionID)
		end
		if not frame.tuiGlowing then StartGlow(frame) end
	else
		StopGlow(frame)
	end

	frame:Show()
	activeReminders[idx] = frame
end

-- Clear all icons (defer glow stop to avoid restart flicker)
local function ClearAllIcons()
	for i = 1, MAX_ICONS do
		ClearAction(reminderIcons[i])
		reminderIcons[i]:Hide()
	end
	wipe(activeReminders)
end

-- Master update
local function UpdateReminders()
	if InCombatLockdown() then return end

	local rdb = TUI.db and TUI.db.profile and TUI.db.profile.cooldownManager and TUI.db.profile.cooldownManager.reminders
	if not rdb or not rdb.enabled then return end

	if not IsInInstance() then
		ClearAllIcons()
		local container = CDM.containers['reminders']
		if container then container:Hide() end
		return
	end

	ClearAllIcons()

	-- Single pass: scan all player buffs once
	ScanPlayerBuffs()

	-- If aura fields were restricted (secret values), don't show any consumable reminders
	-- We can't tell what's missing vs what's just unreadable
	if scan.restricted then
		CDM.LayoutReminders()
		return
	end

	if IsInGroup() then ScanGroupClasses() end
	local threshold = rdb.expirationThreshold or DEFAULT_EXPIRATION_THRESHOLD

	-- Raid buffs
	if rdb.raidBuffs and IsInGroup() then
		for _, info in ipairs(RAID_BUFFS) do
			if groupClasses[info.provider] and not scan.raidBuffs[info.buffID] then
				local isProvider = (info.provider == playerClass)
				if isProvider then
					AddReminder(info.buffID, 'Cast your raid buff', nil, 'spell', info.buffID)
				else
					AddReminder(info.buffID, 'Missing raid buff')
				end
			end
		end
	end

	-- Flask
	if rdb.flask and HasAnyItem(FLASK_ITEMS) then
		if not scan.hasFlask then
			local itemID = FindFirstItem(FLASK_ITEMS)
			AddReminder(FLASK_ICON, 'Use your flask', nil, 'item', itemID)
		elseif scan.flaskRemaining and scan.flaskRemaining < threshold then
			local itemID = FindFirstItem(FLASK_ITEMS)
			AddReminder(FLASK_ICON, 'Flask expiring', scan.flaskRemaining, 'item', itemID)
		end
	end

	-- Food
	if rdb.food then
		if not scan.hasFood then
			AddReminder(FOOD_ICON, 'No food buff active')
		elseif scan.foodRemaining and scan.foodRemaining < threshold then
			AddReminder(FOOD_ICON, 'Food buff expiring', scan.foodRemaining)
		end
	end

	-- Weapon enhancement
	if rdb.weaponOil and HasAnyItem(WEAPON_ITEMS) then
		if not scan.hasWeapon then
			local itemID = FindFirstItem(WEAPON_ITEMS)
			AddReminder(WEAPON_ICON, 'Apply your weapon enhancement', nil, 'item', itemID)
		elseif scan.weaponRemaining and scan.weaponRemaining < threshold then
			local itemID = FindFirstItem(WEAPON_ITEMS)
			AddReminder(WEAPON_ICON, 'Weapon enhancement expiring', scan.weaponRemaining, 'item', itemID)
		end
	end

	-- Augment rune
	if rdb.rune and HasAnyItem(RUNE_ITEMS) then
		if not scan.hasRune then
			local itemID = FindFirstItem(RUNE_ITEMS)
			AddReminder(RUNE_ICON, 'Use your augment rune', nil, 'item', itemID)
		elseif scan.runeRemaining and scan.runeRemaining < threshold then
			local itemID = FindFirstItem(RUNE_ITEMS)
			AddReminder(RUNE_ICON, 'Augment rune expiring', scan.runeRemaining, 'item', itemID)
		end
	end

	-- Pet
	if rdb.pet and ShouldHavePet() and not UnitExists('pet') then
		AddReminder(PET_ICON, 'No pet summoned')
	end

	-- Healthstone
	if rdb.healthstone and IsInGroup() then
		if playerIsWarlock then
			if SoulwellOffCooldown() then
				AddReminder(SOULWELL_ICON, 'Drop your Soulwell', nil, 'spell', CREATE_SOULWELL)
			end
		elseif groupClasses['WARLOCK'] then
			if not HasHealthstone() then
				AddReminder(HEALTHSTONE_ICON, 'No healthstone in bags', nil, nil, nil, true)
			end
		end
	end

	-- Stop glows on icons no longer in use
	for i = #activeReminders + 1, MAX_ICONS do
		StopGlow(reminderIcons[i])
	end

	CDM.LayoutReminders()
end

-- Layout
function CDM.LayoutReminders()
	local container = CDM.containers['reminders']
	if not container then return end

	local rdb = TUI.db and TUI.db.profile and TUI.db.profile.cooldownManager and TUI.db.profile.cooldownManager.reminders
	if not rdb then return end

	local iconSize = E:Scale(rdb.iconSize or 32)
	local spacing = E:Scale(rdb.spacing or 4)
	local grow = rdb.growthDirection or 'RIGHT'

	local count = #activeReminders
	if count == 0 then
		container:Hide()
		return
	end

	if not container:IsShown() then container:Show() end

	for _, icon in ipairs(activeReminders) do
		icon:SetSize(iconSize, iconSize)
		icon.icon:SetTexCoord(E:GetTexCoords())
	end

	local totalW, totalH
	if grow == 'UP' or grow == 'DOWN' then
		totalW = iconSize
		totalH = count * iconSize + (count - 1) * spacing
	else
		totalW = count * iconSize + (count - 1) * spacing
		totalH = iconSize
	end
	container:SetSize(totalW, totalH)

	local anchor, xDir, yDir
	if grow == 'LEFT' then
		anchor, xDir, yDir = 'TOPRIGHT', -1, 0
	elseif grow == 'UP' then
		anchor, xDir, yDir = 'BOTTOMLEFT', 0, 1
	elseif grow == 'DOWN' then
		anchor, xDir, yDir = 'TOPLEFT', 0, -1
	else
		anchor, xDir, yDir = 'TOPLEFT', 1, 0
	end

	for i, icon in ipairs(activeReminders) do
		local offset = (i - 1) * (iconSize + spacing)
		icon:ClearAllPoints()
		icon:SetPoint(anchor, container, anchor, xDir * offset, yDir * offset)
	end

	local mover = _G['TUI_CDM_RemindersMover']
	if mover then
		container:ClearAllPoints()
		if not InCombatLockdown() then mover:SetSize(totalW, totalH) end
		container:SetAllPoints(mover)
	end
end

-- Container creation
local function CreateRemindersContainer()
	local rdb = TUI.db and TUI.db.profile and TUI.db.profile.cooldownManager and TUI.db.profile.cooldownManager.reminders
	local iconSize = rdb and rdb.iconSize or 32

	local frame = CreateFrame('Frame', 'TUI_CDM_RemindersHolder', E.UIParent)
	frame:SetSize(iconSize, iconSize)
	frame:SetPoint('CENTER', E.UIParent, 'CENTER', 0, -250)
	frame:SetFrameStrata('MEDIUM')
	frame:SetFrameLevel(5)

	E:CreateMover(frame, 'TUI_CDM_RemindersMover', 'TUI Reminders', nil, nil, nil, 'ALL,TRENCHYUI', nil, 'TrenchyUI,cooldownManager,reminders')
	CDM.containers['reminders'] = frame
end

-- Event handlers
local function OnCombatEvent(event)
	if event == 'PLAYER_REGEN_ENABLED' then
		if not ticker then
			ticker = C_Timer.NewTicker(TICKER_INTERVAL, UpdateReminders)
		end
		C_Timer.After(2, function()
			if not InCombatLockdown() then UpdateReminders() end
		end)
	elseif event == 'PLAYER_REGEN_DISABLED' then
		if ticker then ticker:Cancel(); ticker = nil end
		local container = CDM.containers['reminders']
		if container then container:Hide() end
	end
end

local function OnZoneEvent()
	if not InCombatLockdown() then
		C_Timer.After(2, function()
			if not InCombatLockdown() then UpdateReminders() end
		end)
	end
end

local function OnGroupEvent()
	if not InCombatLockdown() then UpdateReminders() end
end

function CDM.InitReminders()
	local rdb = TUI.db and TUI.db.profile and TUI.db.profile.cooldownManager and TUI.db.profile.cooldownManager.reminders
	if not rdb or not rdb.enabled then return end

	local _, cls = UnitClass('player')
	playerClass = cls
	playerIsWarlock = (cls == 'WARLOCK')

	CreateRemindersContainer()

	local container = CDM.containers['reminders']
	for i = 1, MAX_ICONS do
		reminderIcons[i] = CreateReminderIcon(container, i)
	end

	CDM:RegisterEvent('PLAYER_REGEN_ENABLED', OnCombatEvent)
	CDM:RegisterEvent('PLAYER_REGEN_DISABLED', OnCombatEvent)
	CDM:RegisterEvent('GROUP_ROSTER_UPDATE', OnGroupEvent)
	CDM:RegisterEvent('UNIT_PET', OnGroupEvent)
	CDM:RegisterEvent('PLAYER_ENTERING_WORLD', OnZoneEvent)
	CDM:RegisterEvent('CHALLENGE_MODE_START', OnZoneEvent)

	if not InCombatLockdown() then
		ticker = C_Timer.NewTicker(TICKER_INTERVAL, UpdateReminders)
		UpdateReminders()
	end
end

function CDM.RefreshReminders()
	if not CDM.containers['reminders'] then return end
	if not InCombatLockdown() then UpdateReminders() end
end
