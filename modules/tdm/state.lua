local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')

if not C_DamageMeter or not Enum.DamageMeterType then return end

local TDM = E:NewModule('TUI_TDM', 'AceEvent-3.0', 'AceHook-3.0')

-- Constants
TDM.MAX_BARS      = 40
TDM.PANEL_INSET   = 2
TDM.HEADER_HEIGHT = 22
-- Use of Fabled class icons with permission from Jiberish, 2026-03-10
TDM.CLASS_ICONS   = 'Interface\\AddOns\\ElvUI_TrenchyUI\\media\\fabled'
TDM.BLIZZ_CLASS_ICONS = 'Interface\\TargetingFrame\\UI-Classes-Circles'

TDM.COMBINED_DAMAGE  = "CombinedDamage"
TDM.COMBINED_HEALING = "CombinedHealing"

TDM.COMBINED_DATA_TYPE = {
    [TDM.COMBINED_DAMAGE]  = Enum.DamageMeterType.DamageDone,
    [TDM.COMBINED_HEALING] = Enum.DamageMeterType.HealingDone,
}

TDM.MODE_ORDER = {
    Enum.DamageMeterType.DamageDone,
    Enum.DamageMeterType.Dps,
    TDM.COMBINED_DAMAGE,
    Enum.DamageMeterType.HealingDone,
    Enum.DamageMeterType.Hps,
    TDM.COMBINED_HEALING,
    Enum.DamageMeterType.Absorbs,
    Enum.DamageMeterType.Interrupts,
    Enum.DamageMeterType.Dispels,
    Enum.DamageMeterType.DamageTaken,
    Enum.DamageMeterType.AvoidableDamageTaken,
}
if Enum.DamageMeterType.Deaths           then TDM.MODE_ORDER[#TDM.MODE_ORDER + 1] = Enum.DamageMeterType.Deaths           end

function TDM.ResolveMeterType(modeEntry)
    return TDM.COMBINED_DATA_TYPE[modeEntry] or modeEntry
end

TDM.MODE_LABELS = {
    [Enum.DamageMeterType.DamageDone]           = "Damage",
    [Enum.DamageMeterType.Dps]                  = "DPS",
    [TDM.COMBINED_DAMAGE]                         = "DPS/Damage",
    [Enum.DamageMeterType.HealingDone]          = "Healing",
    [Enum.DamageMeterType.Hps]                  = "HPS",
    [TDM.COMBINED_HEALING]                        = "HPS/Healing",
    [Enum.DamageMeterType.Absorbs]              = "Absorbs",
    [Enum.DamageMeterType.Interrupts]           = "Interrupts",
    [Enum.DamageMeterType.Dispels]              = "Dispels",
    [Enum.DamageMeterType.DamageTaken]          = "Damage Taken",
    [Enum.DamageMeterType.AvoidableDamageTaken] = "Avoidable Damage Taken",
}
if Enum.DamageMeterType.Deaths           then TDM.MODE_LABELS[Enum.DamageMeterType.Deaths]           = "|cffF48CBAJib's|r"   end

TDM.MODE_SHORT = {
    [Enum.DamageMeterType.DamageDone]           = "Damage",
    [Enum.DamageMeterType.Dps]                  = "DPS",
    [TDM.COMBINED_DAMAGE]                         = "DPS/Dmg",
    [Enum.DamageMeterType.HealingDone]          = "Healing",
    [Enum.DamageMeterType.Hps]                  = "HPS",
    [TDM.COMBINED_HEALING]                        = "HPS/Heal",
    [Enum.DamageMeterType.Absorbs]              = "Absorbs",
    [Enum.DamageMeterType.Interrupts]           = "Interrupts",
    [Enum.DamageMeterType.Dispels]              = "Dispels",
    [Enum.DamageMeterType.DamageTaken]          = "Dmg Taken",
    [Enum.DamageMeterType.AvoidableDamageTaken] = "Avoidable",
}
if Enum.DamageMeterType.Deaths           then TDM.MODE_SHORT[Enum.DamageMeterType.Deaths]           = "|cffF48CBAJib's|r" end

-- 8-value texcoords: ULx, ULy, LLx, LLy, URx, URy, LRx, LRy
TDM.FABLED_COORDS = {
    WARRIOR     = { 0,     0,     0,     0.125, 0.125, 0,     0.125, 0.125 },
    MAGE        = { 0.125, 0,     0.125, 0.125, 0.25,  0,     0.25,  0.125 },
    ROGUE       = { 0.25,  0,     0.25,  0.125, 0.375, 0,     0.375, 0.125 },
    DRUID       = { 0.375, 0,     0.375, 0.125, 0.5,   0,     0.5,   0.125 },
    EVOKER      = { 0.5,   0,     0.5,   0.125, 0.625, 0,     0.625, 0.125 },
    HUNTER      = { 0,     0.125, 0,     0.25,  0.125, 0.125, 0.125, 0.25  },
    SHAMAN      = { 0.125, 0.125, 0.125, 0.25,  0.25,  0.125, 0.25,  0.25  },
    PRIEST      = { 0.25,  0.125, 0.25,  0.25,  0.375, 0.125, 0.375, 0.25  },
    WARLOCK     = { 0.375, 0.125, 0.375, 0.25,  0.5,   0.125, 0.5,   0.25  },
    PALADIN     = { 0,     0.25,  0,     0.375, 0.125, 0.25,  0.125, 0.375 },
    DEATHKNIGHT = { 0.125, 0.25,  0.125, 0.375, 0.25,  0.25,  0.25,  0.375 },
    MONK        = { 0.25,  0.25,  0.25,  0.375, 0.375, 0.25,  0.375, 0.375 },
    DEMONHUNTER = { 0.375, 0.25,  0.375, 0.375, 0.5,   0.25,  0.5,   0.375 },
}

-- Set the class/spec icon on a bar based on the current style
-- style: 'none', 'fabled', 'class', 'spec'
function TDM.SetBarClassIcon(bar, style, classFilename, specIconID)
    if style == 'none' or not classFilename then
        bar.classIcon:Hide()
        return false
    end

    if style == 'spec' and specIconID and E:NotSecretValue(specIconID) and specIconID > 0 then
        bar.classIcon:SetTexture(specIconID)
        bar.classIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        bar.classIcon:Show()
        return true
    end

    if style == 'class' then
        local coords = CLASS_ICON_TCOORDS[classFilename]
        if coords then
            bar.classIcon:SetTexture(TDM.BLIZZ_CLASS_ICONS)
            bar.classIcon:SetTexCoord(unpack(coords))
            bar.classIcon:Show()
            return true
        end
        bar.classIcon:Hide()
        return false
    end

    -- Default: fabled
    local coords = TDM.FABLED_COORDS[classFilename]
    if coords then
        bar.classIcon:SetTexture(TDM.CLASS_ICONS)
        bar.classIcon:SetTexCoord(unpack(coords))
        bar.classIcon:Show()
        return true
    end
    bar.classIcon:Hide()
    return false
end

TDM.SESSION_LABELS = {
    [Enum.DamageMeterSessionType.Current] = "Current",
    [Enum.DamageMeterSessionType.Overall] = "Overall",
}

-- Static popup
E.PopupDialogs.TUI_METER_RESET = {
    text         = "Reset all Trenchy Damage Meter data?",
    button1      = ACCEPT,
    button2      = CANCEL,
    OnAccept     = function()
        C_DamageMeter.ResetAllCombatSessions()
        wipe(TDM.guidByName)
        wipe(TDM.specIconCache)
        TDM:RefreshMeter()
    end,
    timeout      = 0,
    whileDead    = true,
    hideOnEscape = true,
}

-- Mutable state
TDM.windows  = {}
TDM.testMode = false
TDM.meterHidden = false
TDM.meterFadedOut = false
TDM.flightTicker = nil
TDM.flightFadeTimer = nil

-- Caches
TDM.creatureNameCache = {}
TDM.spellCache = {}
TDM.winDBCache = {}
TDM.sessionLabelCache = {}
TDM.specIconCache = {}

-- Localized globals
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local GetNumGroupMembers = GetNumGroupMembers
local UnitGUID = UnitGUID

TDM.guidByName = {}

function TDM.ScanRoster()
    wipe(TDM.guidByName)
    local pg = UnitGUID('player')
    if pg and E:NotSecretValue(pg) then
        local name = UnitName('player')
        if name then TDM.guidByName[name] = pg end
    end
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = 'raid' .. i
            local guid = UnitGUID(unit)
            if guid and E:NotSecretValue(guid) then
                local name = UnitName(unit)
                if name then TDM.guidByName[name] = guid end
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            local unit = 'party' .. i
            local guid = UnitGUID(unit)
            if guid and E:NotSecretValue(guid) then
                local name = UnitName(unit)
                if name then TDM.guidByName[name] = guid end
            end
        end
    end
end

function TDM.CacheCreatureNames()
    for _, sessionType in pairs(Enum.DamageMeterSessionType) do
        for _, meterType in pairs(Enum.DamageMeterType) do
            local session = C_DamageMeter.GetCombatSessionFromType(sessionType, meterType)
            if session and session.combatSources then
                for _, src in ipairs(session.combatSources) do
                    local cid = src.sourceCreatureID
                    if cid and E:NotSecretValue(cid) and not TDM.creatureNameCache[cid] then
                        if src.name and (E:IsSecretValue(src.name) or src.name ~= '') then
                            TDM.creatureNameCache[cid] = Ambiguate(src.name, 'short')
                        end
                    end
                end
            end
        end
    end
end


function TDM.FindUnitByGUID(guid)
    if UnitGUID('player') == guid then return 'player' end
    for i = 1, 40 do
        local unit = 'raid' .. i
        if UnitGUID(unit) == guid then return unit end
    end
    for i = 1, 4 do
        local unit = 'party' .. i
        if UnitGUID(unit) == guid then return unit end
    end
end

function TDM.FindGUIDByName(name)
    if not name or E:IsSecretValue(name) then return end
    return TDM.guidByName[name]
end

function TDM.FindUnitByName(name)
    if not name or E:IsSecretValue(name) then return end
    if UnitName('player') == name then return 'player' end
    for i = 1, 40 do
        local unit = 'raid' .. i
        if UnitName(unit) == name then return unit end
    end
    for i = 1, 4 do
        local unit = 'party' .. i
        if UnitName(unit) == name then return unit end
    end
end


-- One-decimal abbreviation via Blizzard's AbbreviateNumbers (C-side, secret-safe).
-- Formula: finalValue = floor(value / significandDivisor) / fractionDivisor.
-- sd one order less than the magnitude + fd=10 yields one-decimal precision (Details! ToK style).
local ABBREV_SHORT
if AbbreviateNumbers then
    local breakpoints = {
        { breakpoint = 1e9, abbreviation = 'THIRD_NUMBER_CAP_NO_SPACE',  significandDivisor = 1e8, fractionDivisor = 10, abbreviationIsGlobal = true },
        { breakpoint = 1e6, abbreviation = 'SECOND_NUMBER_CAP_NO_SPACE', significandDivisor = 1e5, fractionDivisor = 10, abbreviationIsGlobal = true },
        { breakpoint = 1e3, abbreviation = 'FIRST_NUMBER_CAP_NO_SPACE',  significandDivisor = 1e2, fractionDivisor = 10, abbreviationIsGlobal = true },
        { breakpoint = 1,   abbreviation = '',                           significandDivisor = 1,   fractionDivisor = 1,  abbreviationIsGlobal = false },
    }
    if CreateAbbreviateConfig then
        ABBREV_SHORT = { config = CreateAbbreviateConfig(breakpoints) }
    else
        ABBREV_SHORT = { breakpointData = breakpoints }
    end
end
TDM.ABBREV_SHORT = ABBREV_SHORT

local function FormatShort(value)
    return AbbreviateNumbers(value, ABBREV_SHORT)
end
TDM.FormatShort = FormatShort

function TDM.FormatValueText(fontString, val)
    if not val then fontString:SetText('0'); return end
    fontString:SetFormattedText('%s', FormatShort(val))
end

function TDM.FormatCombinedText(totalFS, dpsFS, total, perSec)
    if not total and not perSec then
        totalFS:SetText('0')
        if dpsFS then dpsFS:SetText('') end
        return
    end
    totalFS:SetFormattedText('(%s)', FormatShort(total or 0))
    if dpsFS then
        dpsFS:SetFormattedText('%s', FormatShort(perSec or 0))
    end
end

function TDM.FontFlags(outline)
    return (outline and outline ~= "NONE") and outline or ""
end

function TDM.GetWinDB(winIndex)
    local mainDB = TUI.db.profile.damageMeter
    if winIndex == 1 then return mainDB end
    local proxy = TDM.winDBCache[winIndex]
    if not proxy then
        proxy = setmetatable({}, { __index = function(_, k)
            local ew = TUI.db.profile.damageMeter.extraWindows[winIndex]
            if ew then
                local v = ew[k]
                if v ~= nil then return v end
            end
            return TUI.db.profile.damageMeter[k]
        end })
        TDM.winDBCache[winIndex] = proxy
    end
    return proxy
end

local cachedClassR, cachedClassG, cachedClassB, cachedClassName

local function CacheClassColor(classFilename)
    if classFilename == cachedClassName then return end
    cachedClassName = classFilename
    cachedClassR, cachedClassG, cachedClassB = TUI:GetClassColor(classFilename)
end

function TDM.ClassOrColor(db, flagKey, colorKey, classFilename)
    if db[flagKey] then
        CacheClassColor(classFilename)
        if cachedClassR then return cachedClassR, cachedClassG, cachedClassB, db[colorKey].a end
    end
    local c = db[colorKey]
    return c.r, c.g, c.b, c.a
end

function TDM.StyleBarTexts(bar, fontPath, size, flags)
    bar.leftText:FontTemplate(fontPath, size, flags)
    bar.rightText:FontTemplate(fontPath, size, flags)
    bar.pctText:FontTemplate(fontPath, size, flags)
    if bar.dpsText then bar.dpsText:FontTemplate(fontPath, size, flags) end
end

function TDM.NewWindowState(index, savedModeIndex)
    return {
        index         = index,
        frame         = nil,
        header        = nil,
        window        = nil,
        bars          = {},
        modeIndex     = savedModeIndex or 1,
        sessionType   = Enum.DamageMeterSessionType.Current,
        sessionId     = nil,
        embedded      = false,
        scrollOffset  = 0,
        drillSource   = nil,
    }
end

function TDM.GetSession(win, meterType)
    if win.sessionId and C_DamageMeter.GetCombatSessionFromID then
        return C_DamageMeter.GetCombatSessionFromID(win.sessionId, meterType)
    end
    return C_DamageMeter.GetCombatSessionFromType(win.sessionType, meterType)
end

-- Build specIconID -> GUID cache from combatSources when GUIDs are readable
function TDM.UpdateSpecIconCache(sources)
    if not sources then return end
    local seen = {}
    for _, src in ipairs(sources) do
        local icon = src.specIconID
        if icon and E:NotSecretValue(icon) and icon > 0 then
            if seen[icon] then
                TDM.specIconCache[icon] = nil
            elseif E:NotSecretValue(src.sourceGUID) then
                TDM.specIconCache[icon] = src.sourceGUID
            end
            seen[icon] = true
        end
    end
end

function TDM.ResolveGUID(guid, specIconID)
    if guid and E:NotSecretValue(guid) then return guid end
    if specIconID and E:NotSecretValue(specIconID) and TDM.specIconCache[specIconID] then
        return TDM.specIconCache[specIconID]
    end
    return nil
end

function TDM.GetSessionSource(win, meterType, guid, sourceCreatureID)
    if guid and E:IsSecretValue(guid) then guid = nil end
    if sourceCreatureID and E:IsSecretValue(sourceCreatureID) then sourceCreatureID = nil end
    if win.sessionId and C_DamageMeter.GetCombatSessionSourceFromID then
        return C_DamageMeter.GetCombatSessionSourceFromID(win.sessionId, meterType, guid, sourceCreatureID)
    end
    return C_DamageMeter.GetCombatSessionSourceFromType(win.sessionType, meterType, guid, sourceCreatureID)
end

function TDM.GetSessionLabel(win)
    if win.sessionId then
        local cached = TDM.sessionLabelCache[win.sessionId]
        if cached then return cached end
        if C_DamageMeter.GetAvailableCombatSessions then
            local sessions = C_DamageMeter.GetAvailableCombatSessions()
            if sessions then
                for i, sess in ipairs(sessions) do
                    local sid = sess.sessionID
                    if sid == win.sessionId then
                        local label = sess.name or 'Encounter'
                        if label == 'Encounter' then label = 'Encounter ' .. i end
                        TDM.sessionLabelCache[win.sessionId] = label
                        return label
                    end
                end
            end
        end
        return 'Encounter'
    end
    return TDM.SESSION_LABELS[win.sessionType] or '?'
end
