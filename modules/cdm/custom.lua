local E = unpack(ElvUI)
local CDM = E:GetModule('TUI_CDM')

local LSM = CDM.LSM
local GetInventoryItemID = GetInventoryItemID
local GetInventoryItemCooldown = GetInventoryItemCooldown
local GetInventoryItemTexture = GetInventoryItemTexture
local IsSpellKnown = C_SpellBook and C_SpellBook.IsSpellKnown

local HEALTHSTONES = { 5512, 224464 }
local BELT_SLOT = 6
local TRINKET_SLOTS = { 13, 14 }
local MAX_ICONS = 12

local HEALING_POTIONS = {
	241305, -- Silvermoon Health Potion
	241307, -- Refreshing Serum
	241299, -- Amani Extract
	258138, -- Potent Healing Potion
	244835, -- Invigorating Healing Potion
}

local COMBAT_POTIONS = {
	241309, -- Light's Potential
	241297, -- Potion of Zealotry
	241289, -- Potion of Recklessness
	241293, -- Draught of Rampant Abandon
	241303, -- Void-Shrouded Tincture
}

-- Racial abilities with cooldowns, keyed by raceEng from UnitRace
-- Multiple candidates per race handle class-specific variants (filtered by IsPlayerSpell at init)
local RACIAL_SPELLS = {
	Orc           = { 33697, 33702, 20572 },
	Troll         = { 26297 },
	Dwarf         = { 20594 },
	NightElf      = { 58984 },
	Human         = { 59752 },
	Gnome         = { 20589 },
	Draenei       = { 59542, 59543, 59544, 59545, 59547, 59548, 121093 },
	Worgen        = { 68992 },
	Tauren        = { 20549 },
	Scourge       = { 7744 },
	BloodElf      = { 28730, 50613, 80483, 129597, 155145, 202719, 232633 },
	Goblin        = { 69041 },
	Pandaren      = { 107079 },
	VoidElf       = { 256948 },
	LightforgedDraenei = { 255647 },
	HighmountainTauren = { 255654 },
	Nightborne    = { 260364 },
	MagharOrc     = { 274738 },
	DarkIronDwarf = { 265221 },
	ZandalariTroll = { 291944 },
	KulTiran      = { 287712 },
	Vulpera       = { 312411 },
	Mechagnome    = { 312924 },
	Dracthyr      = { 357214, 368970 },
	EarthenDwarf  = { 424283 },
}

local customIcons = {}
local activeIcons = {}
local racialSpells = {}

-- Icon frame creation
local function CreateCustomIcon(parent, index)
	local frame = CreateFrame('Button', 'TUI_CDM_CustomIcon' .. index, parent, 'BackdropTemplate')
	frame:SetTemplate('Default')
	frame:SetFrameStrata('MEDIUM')
	frame:SetFrameLevel(6)

	local icon = frame:CreateTexture(nil, 'ARTWORK')
	icon:SetInside(frame)
	frame.icon = icon
	frame.Icon = icon

	local cooldown = CreateFrame('Cooldown', nil, frame, 'CooldownFrameTemplate')
	cooldown:SetAllPoints(icon)
	cooldown:SetDrawEdge(false)
	cooldown:SetHideCountdownNumbers(false)

	local cdText = cooldown:CreateFontString(nil, 'OVERLAY')
	cdText:SetPoint('CENTER', 0, 0)
	cdText:FontTemplate(LSM:Fetch('font', 'Expressway'), 14, 'OUTLINE')
	cooldown.Text = cdText

	E:RegisterCooldown(cooldown, 'cdmanager')
	frame.Cooldown = cooldown

	local countText = frame:CreateFontString(nil, 'OVERLAY')
	countText:FontTemplate(LSM:Fetch('font', 'Expressway'), 11, 'OUTLINE')
	countText:SetPoint('BOTTOMRIGHT', 0, 0)
	frame.countText = countText

	frame:SetScript('OnEnter', function(self)
		if not self.tuiTrackType then return end
		local vdb = CDM.GetViewerDB('custom')
		if vdb and vdb.showTooltips == false then return end
		GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
		if self.tuiTrackType == 'racial' and self.tuiSpellID then
			GameTooltip:SetSpellByID(self.tuiSpellID)
		elseif self.tuiTrackType == 'trinket' and self.tuiSlot then
			GameTooltip:SetInventoryItem('player', self.tuiSlot)
		elseif self.tuiTrackType == 'item' and self.tuiItemID then
			GameTooltip:SetItemByID(self.tuiItemID)
		end
		GameTooltip:Show()
	end)
	frame:SetScript('OnLeave', GameTooltip_Hide)

	frame:Hide()
	return frame
end

-- Detect player's racial abilities at init
local function DetectRacials()
	wipe(racialSpells)
	local _, raceEng = UnitRace('player')
	local candidates = RACIAL_SPELLS[raceEng]
	if not candidates then return end

	for _, spellID in ipairs(candidates) do
		if IsSpellKnown and IsSpellKnown(spellID) then
			racialSpells[#racialSpells + 1] = spellID
		end
	end
end

-- Update individual icon types
local function UpdateRacialIcon(frame, spellID)
	frame.tuiTrackType = 'racial'
	frame.tuiSpellID = spellID
	frame.icon:SetTexture(C_Spell.GetSpellTexture(spellID))
	frame.countText:SetText('')

	local dur = C_Spell.GetSpellCooldownDuration(spellID)
	if dur then
		frame.Cooldown:SetCooldownFromDurationObject(dur)
	else
		frame.Cooldown:Clear()
	end
end

local function UpdateTrinketIcon(frame, slot)
	local itemID = GetInventoryItemID('player', slot)
	if not itemID then
		frame:Hide()
		return false
	end

	frame.tuiTrackType = 'trinket'
	frame.tuiSlot = slot
	frame.icon:SetTexture(GetInventoryItemTexture('player', slot))
	frame.countText:SetText('')

	local start, duration, enable = GetInventoryItemCooldown('player', slot)
	if enable and enable ~= 0 then
		frame.Cooldown:SetCooldown(start, duration)
	else
		frame.Cooldown:Clear()
	end
	frame:Show()
	return true
end

local function UpdateItemIcon(frame, itemID, trackType)
	local count = C_Item.GetItemCount(itemID, false, true)
	if count == 0 then
		frame:Hide()
		return false
	end

	frame.tuiTrackType = trackType
	frame.tuiItemID = itemID
	frame.tuiSpellID = nil
	frame.tuiSlot = nil
	frame.icon:SetTexture(C_Item.GetItemIconByID(itemID))
	frame.countText:SetText(count > 1 and count or '')

	local start, duration, enable = C_Container.GetItemCooldown(itemID)
	if enable and enable ~= 0 then
		frame.Cooldown:SetCooldown(start, duration)
	else
		frame.Cooldown:Clear()
	end
	frame:Show()
	return true
end

-- Master update: populate icons based on config toggles
local function UpdateAllIcons()
	local vdb = CDM.GetViewerDB('custom')
	if not vdb or not vdb.enabled then return end

	wipe(activeIcons)
	local idx = 0

	-- Racials
	if vdb.showRacials then
		for _, spellID in ipairs(racialSpells) do
			idx = idx + 1
			if idx > MAX_ICONS then break end
			local frame = customIcons[idx]
			UpdateRacialIcon(frame, spellID)
			frame:Show()
			activeIcons[#activeIcons + 1] = frame
		end
	end

	-- Healthstones
	if vdb.showHealthstone then
		for _, itemID in ipairs(HEALTHSTONES) do
			if C_Item.GetItemCount(itemID) > 0 then
				idx = idx + 1
				if idx > MAX_ICONS then break end
				local frame = customIcons[idx]
				UpdateItemIcon(frame, itemID, 'item')
				activeIcons[#activeIcons + 1] = frame
			end
		end
	end

	-- Healing Potions
	if vdb.showPotions then
		for _, itemID in ipairs(HEALING_POTIONS) do
			if C_Item.GetItemCount(itemID) > 0 then
				idx = idx + 1
				if idx > MAX_ICONS then break end
				local frame = customIcons[idx]
				UpdateItemIcon(frame, itemID, 'item')
				activeIcons[#activeIcons + 1] = frame
			end
		end
	end

	-- Combat Potions
	if vdb.showCombatPotions then
		for _, itemID in ipairs(COMBAT_POTIONS) do
			if C_Item.GetItemCount(itemID) > 0 then
				idx = idx + 1
				if idx > MAX_ICONS then break end
				local frame = customIcons[idx]
				UpdateItemIcon(frame, itemID, 'item')
				activeIcons[#activeIcons + 1] = frame
			end
		end
	end

	-- Belt tinker — GetInventoryItemCooldown returns enable=1 only when the slot has an on-use (i.e. a tinker is applied)
	if vdb.showBeltTinker then
		local _, _, enable = GetInventoryItemCooldown('player', BELT_SLOT)
		if enable == 1 then
			idx = idx + 1
			if idx <= MAX_ICONS then
				local frame = customIcons[idx]
				if UpdateTrinketIcon(frame, BELT_SLOT) then
					activeIcons[#activeIcons + 1] = frame
				end
			end
		end
	end

	-- Trinkets
	local tMode = vdb.trinketMode or 'both'
	if tMode ~= 'none' then
		local slots
		if tMode == 'both' then slots = TRINKET_SLOTS
		elseif tMode == 'slot1' then slots = { 13 }
		elseif tMode == 'slot2' then slots = { 14 }
		end

		if slots then
			for _, slot in ipairs(slots) do
				idx = idx + 1
				if idx <= MAX_ICONS then
					local frame = customIcons[idx]
					if UpdateTrinketIcon(frame, slot) then
						activeIcons[#activeIcons + 1] = frame
					end
				end
			end
		end
	end

	-- Hide unused icons
	for i = idx + 1, MAX_ICONS do
		customIcons[i]:Hide()
	end

	CDM.LayoutCustomViewer()
end

-- Layout: position active icons in the container
function CDM.LayoutCustomViewer()
	local container = CDM.containers['custom']
	if not container then return end

	local vdb = CDM.GetViewerDB('custom')
	if not vdb then return end

	local iconW = E:Scale(vdb.iconWidth or 36)
	local iconH = (vdb.keepSizeRatio and iconW) or E:Scale(vdb.iconHeight or 36)
	local spacing = E:Scale(vdb.spacing or 4)
	local perRow = vdb.iconsPerRow or 6
	local grow = vdb.growthDirection or 'CENTER'
	local zoom = vdb.iconZoom

	local count = #activeIcons
	if count == 0 then
		container:Hide()
		return
	end
	if not container:IsShown() and CDM.ShouldShowContainer('custom') then
		container:Show()
	end

	local db = CDM.GetDB()
	for _, icon in ipairs(activeIcons) do
		icon:SetSize(iconW, iconH)
		icon.icon:SetTexCoord(E:GetTexCoords())
		CDM.ApplyIconZoom(icon, zoom)
		CDM.ApplyCooldownText(icon.Cooldown, vdb.cooldownText)
		CDM.ApplySwipeOverride(icon.Cooldown, db)
		CDM.StyleFontString(icon.countText, vdb.countText)
		CDM.SetPreviewText(icon, CDM.previewActive, vdb)
	end

	local cols = count < perRow and count or perRow
	local rows = math.ceil(count / perRow)
	local totalW = cols * iconW + (cols - 1) * spacing
	local totalH = rows * iconH + (rows - 1) * spacing
	CDM.SetContainerSize(container, totalW, totalH)

	-- Determine icon anchor based on growth direction
	local anchor
	if grow == 'LEFT' then anchor = 'RIGHT'
	elseif grow == 'UP' then anchor = 'BOTTOMLEFT'
	else anchor = 'TOPLEFT' end

	local xDir = grow == 'LEFT' and -1 or 1
	local yDir = grow == 'UP' and 1 or -1
	local isVertical = grow == 'UP' or grow == 'DOWN'

	for i, icon in ipairs(activeIcons) do
		local row, col
		if isVertical then
			row = i - 1
			col = 0
		else
			row = math.floor((i - 1) / perRow)
			col = (i - 1) % perRow
		end
		icon:ClearAllPoints()
		icon:SetPoint(anchor, container, anchor, xDir * col * (iconW + spacing), yDir * row * (iconH + spacing))
	end

	local info = CDM.VIEWER_KEYS['custom']
	local mover = _G[info.mover .. 'Mover']
	if mover then
		container:ClearAllPoints()
		if grow == 'CENTER' then
			if not InCombatLockdown() then mover:SetSize(totalW, totalH) end
			container:SetAllPoints(mover)
		else
			if not InCombatLockdown() then mover:SetSize(iconW, iconH) end
			container:SetPoint(anchor, mover, anchor)
		end
	end
end

-- Debounced update: coalesces rapid event bursts into one update
local updatePending = false
local function ScheduleUpdate()
	if updatePending then return end
	updatePending = true
	C_Timer.After(0.1, function()
		updatePending = false
		UpdateAllIcons()
	end)
end

-- Event handler
local function OnEvent(event, ...)
	if event == 'SPELL_UPDATE_COOLDOWN' or event == 'BAG_UPDATE_COOLDOWN' or event == 'BAG_UPDATE' or event == 'PLAYER_ENTERING_WORLD' then
		ScheduleUpdate()
	elseif event == 'PLAYER_EQUIPMENT_CHANGED' then
		local slot = ...
		if slot == 13 or slot == 14 then
			ScheduleUpdate()
		end
	elseif event == 'ACTIVE_TALENT_GROUP_CHANGED' or event == 'PLAYER_TALENT_UPDATE' then
		DetectRacials()
		ScheduleUpdate()
	end
end

local function CDMDisabled() local d = CDM.GetDB(); return not (d and d.enabled) end
local function IgnoreQuadrant() end

local function CreateCustomContainer()
	local info = CDM.VIEWER_KEYS['custom']
	local vdb = CDM.GetViewerDB('custom')
	local iconW = vdb and vdb.iconWidth or 36
	local iconH = (vdb and vdb.keepSizeRatio and iconW) or (vdb and vdb.iconHeight or 36)

	local frame = CreateFrame('Frame', info.mover .. 'Holder', E.UIParent)
	frame:SetSize(iconW, iconH)
	frame:SetPoint('CENTER', E.UIParent, 'CENTER', 0, -200)
	frame:SetFrameStrata('MEDIUM')
	frame:SetFrameLevel(5)

	local configStr = 'TrenchyUI,cooldownManager,custom'
	E:CreateMover(frame, info.mover .. 'Mover', 'TUI ' .. info.label, nil, nil, IgnoreQuadrant, 'ALL,TRENCHYUI', CDMDisabled, configStr, true)
	CDM.containers['custom'] = frame
end

function CDM.InitCustomViewer()
	local vdb = CDM.GetViewerDB('custom')
	if not vdb or not vdb.enabled then return end

	CreateCustomContainer()

	local container = CDM.containers['custom']
	for i = 1, MAX_ICONS do
		customIcons[i] = CreateCustomIcon(container, i)
	end

	DetectRacials()

	CDM:RegisterEvent('SPELL_UPDATE_COOLDOWN', OnEvent)
	CDM:RegisterEvent('BAG_UPDATE_COOLDOWN', OnEvent)
	CDM:RegisterEvent('BAG_UPDATE', OnEvent)
	CDM:RegisterEvent('PLAYER_EQUIPMENT_CHANGED', OnEvent)
	CDM:RegisterEvent('PLAYER_ENTERING_WORLD', OnEvent)
	CDM:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED', OnEvent)
	CDM:RegisterEvent('PLAYER_TALENT_UPDATE', OnEvent)

	UpdateAllIcons()
end

function CDM.RefreshCustomViewer()
	if not CDM.containers['custom'] then return end
	UpdateAllIcons()
end
