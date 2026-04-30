local E = unpack(ElvUI)
local QOL = E:GetModule('TUI_QoL')
local M = E:GetModule('Misc')

local hooksecurefunc = hooksecurefunc
local strmatch = strmatch
local gsub = string.gsub

-- Midnight enchant name → short display label
local ENCHANT_MAP = {
	-- Weapon (Enchanting - Midnight)
	["Strength of Halazzi"]      = "Halazzi",
	["Jan'alai's Precision"]     = "Jan'alai",
	["Berserker's Rage"]         = "Berserker",
	["Flames of the Sin'dorei"]  = "Sin'dorei",
	["Acuity of the Ren'dorei"] = "Ren'dorei",
	["Arcane Mastery"]           = "Arcane Mastery",
	["Worldsoul Aegis"]          = "WS Aegis",
	["Worldsoul Cradle"]         = "WS Cradle",
	["Worldsoul Tenacity"]       = "WS Tenacity",

	-- Weapon (TWW)
	["Authority of Air"]           = "Air",
	["Authority of Fiery Resolve"] = "Fiery Resolve",
	["Authority of Radiant Power"] = "Radiant Power",
	["Authority of Storms"]        = "Storms",
	["Authority of the Depths"]    = "Depths",
	["Council's Guile"]            = "Council's Guile",
	["Oathsworn's Tenacity"]       = "Oathsworn",
	["Stonebound Artistry"]        = "Stonebound",
	["Stormrider's Fury"]          = "Stormrider",

	-- Weapon (DK Runeforges)
	["Rune of the Fallen Crusader"]    = "Fallen Crusader",
	["Rune of Razorice"]               = "Razorice",
	["Rune of the Stoneskin Gargoyle"] = "Stoneskin",
	["Rune of Hysteria"]               = "Hysteria",
	["Rune of Unending Thirst"]        = "Unending Thirst",
	["Rune of Spellwarding"]           = "Spellwarding",
	["Rune of Sanguination"]           = "Sanguination",
	["Rune of the Apocalypse"]         = "Apocalypse",

	-- Helm
	["Hex of Leeching"]              = "Hex of Leech",
	["Empowered Hex of Leeching"]    = "Emp. Hex of Leech",
	["Rune of Avoidance"]            = "Avoidance",
	["Empowered Rune of Avoidance"]  = "Emp. Avoidance",
	["Blessing of Speed"]            = "Blessing of Speed",
	["Empowered Blessing of Speed"]  = "Emp. Speed",

	-- Shoulder
	["Flight of the Eagle"]    = "Eagle",
	["Akil'zon's Swiftness"]   = "Akil'zon",
	["Nature's Grace"]         = "Nature's Grace",
	["Amirdrassil's Grace"]    = "Amirdrassil",
	["Thalassian Recovery"]    = "Thalassian",
	["Silvermoon's Mending"]   = "Silvermoon",

	-- Chest (Midnight)
	["Mark of Nalorakk"]       = "Nalorakk",
	["Mark of the Rootwarden"] = "Rootwarden",
	["Mark of the Worldsoul"]  = "Worldsoul",
	["Mark of the Magister"]   = "Magister",

	-- Chest (TWW)
	["Council's Intellect"]   = "Council's Int",
	["Crystalline Radiance"]  = "Radiance",
	["Oathsworn's Strength"]  = "Oathsworn Str",
	["Stormrider's Agility"]  = "Stormrider Agi",

	-- Legs (Leatherworking)
	["Thalassian Scout Armor Kit"] = "Scout Kit",
	["Blood Knight's Armor Kit"]   = "BK Kit",
	["Forest Hunter's Armor Kit"]  = "Hunter Kit",
	["Stormbound Armor Kit"]       = "Stormbound Kit",
	["Defender's Armor Kit"]       = "Defender Kit",

	-- Legs (Tailoring)
	["Bright Linen Spellthread"]  = "Linen Thread",
	["Arcanoweave Spellthread"]   = "Arcanoweave",
	["Sunfire Silk Spellthread"]  = "Sunfire Thread",

	-- Boots (Midnight)
	["Lynx's Dexterity"]     = "Lynx",
	["Shaladrassil's Roots"] = "Shaladrassil",
	["Farstrider's Hunt"]    = "Farstrider",

	-- Boots (TWW)
	["Cavalry's March"]  = "Cavalry",
	["Defender's March"]  = "Defender",
	["Scout's March"]     = "Scout",

	-- Rings (Midnight)
	["Amani Mastery"]           = "Amani Mastery",
	["Eyes of the Eagle"]       = "Eagle Eye",
	["Zul'jin's Mastery"]       = "Zul'jin",
	["Nature's Wrath"]          = "Nature's Wrath",
	["Nature's Fury"]           = "Nature's Fury",
	["Thalassian Versatility"]  = "Thalassian Vers",
	["Silvermoon's Alacrity"]   = "SM Alacrity",
	["Silvermoon's Tenacity"]   = "SM Tenacity",

	-- Rings (TWW)
	["Cursed Critical Strike"]     = "Cursed Crit",
	["Cursed Haste"]               = "Cursed Haste",
	["Cursed Mastery"]             = "Cursed Mastery",
	["Cursed Versatility"]         = "Cursed Vers",
	["Glimmering Critical Strike"] = "Glim. Crit",
	["Glimmering Haste"]           = "Glim. Haste",
	["Glimmering Mastery"]         = "Glim. Mastery",
	["Glimmering Versatility"]     = "Glim. Vers",
	["Radiant Critical Strike"]    = "Radiant Crit",
	["Radiant Haste"]              = "Radiant Haste",
	["Radiant Mastery"]            = "Radiant Mastery",
	["Radiant Versatility"]        = "Radiant Vers",

	-- Cloak (TWW)
	["Chant of Winged Grace"]       = "Winged Grace",
	["Chant of Leeching Fangs"]     = "Leeching Fangs",
	["Chant of Burrowing Rapidity"] = "Burrowing",
	["Whisper of Silken Avoidance"] = "Silken Avoid",
	["Whisper of Silken Leech"]     = "Silken Leech",
	["Whisper of Silken Speed"]     = "Silken Speed",

	-- Bracer (TWW)
	["Chant of Armored Avoidance"]   = "Armored Avoid",
	["Chant of Armored Leech"]       = "Armored Leech",
	["Chant of Armored Speed"]       = "Armored Speed",
	["Whisper of Armored Avoidance"] = "Armored Avoid",
	["Whisper of Armored Leech"]     = "Armored Leech",
	["Whisper of Armored Speed"]     = "Armored Speed",
}

function QOL:InitEnchantStrings()
	if not E.db.general.itemLevel.showEnchants then return end

	local matchPattern = _G.ENCHANTED_TOOLTIP_LINE and _G.ENCHANTED_TOOLTIP_LINE:gsub('%%s', '(.+)')
	if not matchPattern then return end

	hooksecurefunc(M, 'UpdatePageStrings', function(_, _, _, slot, slotInfo)
		if not slot or not slot.enchantText or not slotInfo then return end
		local raw = slotInfo.enchantTextReal
		if not raw then return end

		-- Strip color codes, atlas icons, and "Enchant Slot - " prefix
		local clean = gsub(gsub(gsub(raw, '%s?|A.-|a', ''), '|cn.-:(.-)|r', '%1'), '|c%x%x%x%x%x%x%x%x', '')
		clean = gsub(clean, '|r', '')
		clean = gsub(gsub(clean, '^%s+', ''), '%s+$', '')
		clean = gsub(clean, '^Enchant %w+ %- ', '')

		local short = ENCHANT_MAP[clean]
		if not short then return end

		-- Preserve original color codes from the enchant
		local color1, color2 = strmatch(raw, '(|cn.-:).-(|r)')
		local display = color1 and (color1 .. short .. color2) or short
		slot.enchantText:SetText(display)
	end)
end

function QOL:Initialize()
	local TUI = E:GetModule('TrenchyUI')
	local db = TUI.db.profile.qol
	if db.hideTalkingHead then self:InitHideTalkingHead() end
	if db.autoFillDelete then self:InitAutoFillDelete() end
	if db.difficultyText then self:InitDifficultyText() end
	if db.fastLoot then self:InitFastLoot() end
	if db.moveableFrames and not TUI:IsCompatBlocked('moveableFrames') then self:InitMoveableFrames() end
	if db.hideObjectiveInCombat then self:InitHideObjectiveInCombat() end
	if self.InitMinimapButtonBar then self:InitMinimapButtonBar() end
	if db.cursorCircle then self:InitCursorCircle() end
	if db.shortenEnchantStrings and self.InitEnchantStrings then self:InitEnchantStrings() end
	if self.InitAuraFader then self:InitAuraFader() end
	if self.InitMutedSounds then self:InitMutedSounds() end
end

E:RegisterModule(QOL:GetName())
