local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')

if not C_DamageMeter or not Enum.DamageMeterType then return end

TUI._tdm = {}
local S = TUI._tdm

-- Constants
S.MAX_BARS      = 40
S.PANEL_INSET   = 2
S.HEADER_HEIGHT = 22
-- Use of Fabled class icons with permission from Jiberish, 2026-03-10
S.CLASS_ICONS   = 'Interface\\AddOns\\ElvUI_TrenchyUI\\media\\fabled'

S.COMBINED_DAMAGE  = "CombinedDamage"
S.COMBINED_HEALING = "CombinedHealing"

S.COMBINED_DATA_TYPE = {
    [S.COMBINED_DAMAGE]  = Enum.DamageMeterType.DamageDone,
    [S.COMBINED_HEALING] = Enum.DamageMeterType.HealingDone,
}

S.MODE_ORDER = {
    Enum.DamageMeterType.DamageDone,
    Enum.DamageMeterType.Dps,
    S.COMBINED_DAMAGE,
    Enum.DamageMeterType.HealingDone,
    Enum.DamageMeterType.Hps,
    S.COMBINED_HEALING,
    Enum.DamageMeterType.Absorbs,
    Enum.DamageMeterType.Interrupts,
    Enum.DamageMeterType.Dispels,
    Enum.DamageMeterType.DamageTaken,
    Enum.DamageMeterType.AvoidableDamageTaken,
}
if Enum.DamageMeterType.Deaths           then S.MODE_ORDER[#S.MODE_ORDER + 1] = Enum.DamageMeterType.Deaths           end
if Enum.DamageMeterType.EnemyDamageTaken then S.MODE_ORDER[#S.MODE_ORDER + 1] = Enum.DamageMeterType.EnemyDamageTaken end

function S.ResolveMeterType(modeEntry)
    return S.COMBINED_DATA_TYPE[modeEntry] or modeEntry
end

S.MODE_LABELS = {
    [Enum.DamageMeterType.DamageDone]           = "Damage",
    [Enum.DamageMeterType.Dps]                  = "DPS",
    [S.COMBINED_DAMAGE]                         = "DPS/Damage",
    [Enum.DamageMeterType.HealingDone]          = "Healing",
    [Enum.DamageMeterType.Hps]                  = "HPS",
    [S.COMBINED_HEALING]                        = "HPS/Healing",
    [Enum.DamageMeterType.Absorbs]              = "Absorbs",
    [Enum.DamageMeterType.Interrupts]           = "Interrupts",
    [Enum.DamageMeterType.Dispels]              = "Dispels",
    [Enum.DamageMeterType.DamageTaken]          = "Damage Taken",
    [Enum.DamageMeterType.AvoidableDamageTaken] = "Avoidable Damage Taken",
}
if Enum.DamageMeterType.Deaths           then S.MODE_LABELS[Enum.DamageMeterType.Deaths]           = "|cffF48CBAJib's|r"   end
if Enum.DamageMeterType.EnemyDamageTaken then S.MODE_LABELS[Enum.DamageMeterType.EnemyDamageTaken] = "Enemy Damage Taken"   end

S.MODE_SHORT = {
    [Enum.DamageMeterType.DamageDone]           = "Damage",
    [Enum.DamageMeterType.Dps]                  = "DPS",
    [S.COMBINED_DAMAGE]                         = "DPS/Dmg",
    [Enum.DamageMeterType.HealingDone]          = "Healing",
    [Enum.DamageMeterType.Hps]                  = "HPS",
    [S.COMBINED_HEALING]                        = "HPS/Heal",
    [Enum.DamageMeterType.Absorbs]              = "Absorbs",
    [Enum.DamageMeterType.Interrupts]           = "Interrupts",
    [Enum.DamageMeterType.Dispels]              = "Dispels",
    [Enum.DamageMeterType.DamageTaken]          = "Dmg Taken",
    [Enum.DamageMeterType.AvoidableDamageTaken] = "Avoidable",
}
if Enum.DamageMeterType.Deaths           then S.MODE_SHORT[Enum.DamageMeterType.Deaths]           = "|cffF48CBAJib's|r" end
if Enum.DamageMeterType.EnemyDamageTaken then S.MODE_SHORT[Enum.DamageMeterType.EnemyDamageTaken] = "Enemy Dmg" end

-- 8-value texcoords: ULx, ULy, LLx, LLy, URx, URy, LRx, LRy
S.CLASS_ICON_COORDS = {
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

S.SESSION_LABELS = {
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
        wipe(S.nameCache)
        wipe(S.guidByName)
        wipe(S.specIconCache)
        TUI:RefreshMeter()
    end,
    timeout      = 0,
    whileDead    = true,
    hideOnEscape = true,
}

-- Mutable state
S.windows  = {}
S.testMode = false
S.meterHidden = false
S.meterFadedOut = false
S.flightTicker = nil
S.flightFadeTimer = nil

TUI._meterTestMode = false

-- Caches
S.nameCache  = {}
S.creatureNameCache = {}
S.spellCache = {}
S.winDBCache = {}
S.sessionLabelCache = {}
S.specIconCache = {}

-- Localized globals
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local GetNumGroupMembers = GetNumGroupMembers
local UnitGUID = UnitGUID
local floor = math.floor

S.guidByName = {}

function S.ScanRoster()
    wipe(S.guidByName)
    local pg = UnitGUID('player')
    if pg and not S.IsSecret(pg) then
        local name = UnitName('player')
        S.nameCache[pg] = name
        if name then S.guidByName[name] = pg end
    end
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = 'raid' .. i
            local guid = UnitGUID(unit)
            if guid and not S.IsSecret(guid) then
                local name = UnitName(unit)
                S.nameCache[guid] = name
                if name then S.guidByName[name] = guid end
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            local unit = 'party' .. i
            local guid = UnitGUID(unit)
            if guid and not S.IsSecret(guid) then
                local name = UnitName(unit)
                S.nameCache[guid] = name
                if name then S.guidByName[name] = guid end
            end
        end
    end
end

function S.CacheCreatureNames()
    for _, sessionType in pairs(Enum.DamageMeterSessionType) do
        for _, meterType in pairs(Enum.DamageMeterType) do
            local session = C_DamageMeter.GetCombatSessionFromType(sessionType, meterType)
            if session and session.combatSources then
                for _, src in ipairs(session.combatSources) do
                    local cid = src.sourceCreatureID
                    if cid and not S.IsSecret(cid) and not S.creatureNameCache[cid] then
                        if src.name and not S.IsSecret(src.name) and src.name ~= '' then
                            S.creatureNameCache[cid] = Ambiguate(src.name, 'short')
                        end
                    end
                end
            end
        end
    end
end

function S.IsSecret(val)
    return val ~= nil and issecretvalue and issecretvalue(val)
end

function S.FindUnitByGUID(guid)
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

function S.FindGUIDByName(name)
    if not name or S.IsSecret(name) then return end
    return S.guidByName[name]
end

function S.FindUnitByName(name)
    if not name or S.IsSecret(name) then return end
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


-- Abbreviation config: no decimals (fractionDivisor = 1 at all breakpoints)
local ABBREV_SHORT = E.Abbreviate and E.Abbreviate.short
if not ABBREV_SHORT and AbbreviateNumbers then
    local breakpoints = {
        { breakpoint = 1000000000, abbreviation = 'NUMBER_ABBREVIATION_BILLIONS',  significandDivisor = 1000000000, fractionDivisor = 1 },
        { breakpoint = 1000000,    abbreviation = 'NUMBER_ABBREVIATION_MILLIONS',  significandDivisor = 1000000,    fractionDivisor = 1 },
        { breakpoint = 10000,      abbreviation = 'NUMBER_ABBREVIATION_THOUSANDS', significandDivisor = 1000,       fractionDivisor = 1 },
        { breakpoint = 1000,       abbreviation = 'NUMBER_ABBREVIATION_THOUSANDS', significandDivisor = 100,        fractionDivisor = 1, abbreviationIsGlobal = true },
    }
    if CreateAbbreviateConfig then
        ABBREV_SHORT = { config = CreateAbbreviateConfig(breakpoints) }
    else
        ABBREV_SHORT = { breakpointData = breakpoints }
    end
end
S.ABBREV_SHORT = ABBREV_SHORT

function S.FormatValueText(fontString, val)
    if not val then fontString:SetText('0'); return end
    if S.IsSecret(val) then
        fontString:SetFormattedText('%s', AbbreviateNumbers(val, ABBREV_SHORT))
    else
        fontString:SetText(AbbreviateNumbers(floor(val + 0.5), ABBREV_SHORT))
    end
end

function S.FormatCombinedText(totalFS, dpsFS, total, perSec)
    if not total and not perSec then
        totalFS:SetText('0')
        if dpsFS then dpsFS:SetText('') end
        return
    end
    if S.IsSecret(total) or S.IsSecret(perSec) then
        totalFS:SetFormattedText('(%s)', AbbreviateNumbers(total or 0, ABBREV_SHORT))
        if dpsFS then dpsFS:SetFormattedText('%s', AbbreviateNumbers(perSec or 0, ABBREV_SHORT)) end
    else
        local t = total and AbbreviateNumbers(floor(total + 0.5), ABBREV_SHORT) or '0'
        totalFS:SetText('(' .. t .. ')')
        if dpsFS then
            local p = perSec and AbbreviateNumbers(floor(perSec + 0.5), ABBREV_SHORT) or '0'
            dpsFS:SetText(p)
        end
    end
end

function S.FontFlags(outline)
    return (outline and outline ~= "NONE") and outline or ""
end

function S.GetWinDB(winIndex)
    local mainDB = TUI.db.profile.damageMeter
    if winIndex == 1 then return mainDB end
    local proxy = S.winDBCache[winIndex]
    if not proxy then
        proxy = setmetatable({}, { __index = function(_, k)
            local ew = TUI.db.profile.damageMeter.extraWindows[winIndex]
            if ew then
                local v = ew[k]
                if v ~= nil then return v end
            end
            return TUI.db.profile.damageMeter[k]
        end })
        S.winDBCache[winIndex] = proxy
    end
    return proxy
end

local cachedClassR, cachedClassG, cachedClassB, cachedClassName

local function CacheClassColor(classFilename)
    if classFilename == cachedClassName then return end
    cachedClassName = classFilename
    cachedClassR, cachedClassG, cachedClassB = TUI:GetClassColor(classFilename)
end

function S.ClassOrColor(db, flagKey, colorKey, classFilename)
    if db[flagKey] then
        CacheClassColor(classFilename)
        if cachedClassR then return cachedClassR, cachedClassG, cachedClassB, db[colorKey].a end
    end
    local c = db[colorKey]
    return c.r, c.g, c.b, c.a
end

function S.StyleBarTexts(bar, fontPath, size, flags)
    bar.leftText:FontTemplate(fontPath, size, flags)
    bar.rightText:FontTemplate(fontPath, size, flags)
    bar.pctText:FontTemplate(fontPath, size, flags)
    if bar.dpsText then bar.dpsText:FontTemplate(fontPath, size, flags) end
end

function S.NewWindowState(index, savedModeIndex)
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

function S.GetSession(win, meterType)
    if win.sessionId and C_DamageMeter.GetCombatSessionFromID then
        return C_DamageMeter.GetCombatSessionFromID(win.sessionId, meterType)
    end
    return C_DamageMeter.GetCombatSessionFromType(win.sessionType, meterType)
end

-- Build specIconID -> GUID cache from combatSources when GUIDs are readable
function S.UpdateSpecIconCache(sources)
    if not sources then return end
    local seen = {}
    for _, src in ipairs(sources) do
        local icon = src.specIconID
        if icon and not S.IsSecret(icon) and icon > 0 then
            if seen[icon] then
                S.specIconCache[icon] = nil
            elseif not S.IsSecret(src.sourceGUID) then
                S.specIconCache[icon] = src.sourceGUID
            end
            seen[icon] = true
        end
    end
end

function S.ResolveGUID(guid, specIconID)
    if guid and not S.IsSecret(guid) then return guid end
    if specIconID and not S.IsSecret(specIconID) and S.specIconCache[specIconID] then
        return S.specIconCache[specIconID]
    end
    return nil
end

function S.GetSessionSource(win, meterType, guid, sourceCreatureID)
    if guid and S.IsSecret(guid) then guid = nil end
    if sourceCreatureID and S.IsSecret(sourceCreatureID) then sourceCreatureID = nil end
    if win.sessionId and C_DamageMeter.GetCombatSessionSourceFromID then
        return C_DamageMeter.GetCombatSessionSourceFromID(win.sessionId, meterType, guid, sourceCreatureID)
    end
    return C_DamageMeter.GetCombatSessionSourceFromType(win.sessionType, meterType, guid, sourceCreatureID)
end

function S.GetSessionLabel(win)
    if win.sessionId then
        local cached = S.sessionLabelCache[win.sessionId]
        if cached then return cached end
        if C_DamageMeter.GetAvailableCombatSessions then
            local sessions = C_DamageMeter.GetAvailableCombatSessions()
            if sessions then
                for i, sess in ipairs(sessions) do
                    local sid = sess.sessionId or sess.combatSessionId or sess.id or sess.sessionID
                    if sid == win.sessionId then
                        local label = sess.name or 'Encounter'
                        if label == 'Encounter' then label = 'Encounter ' .. i end
                        S.sessionLabelCache[win.sessionId] = label
                        return label
                    end
                end
            end
        end
        return 'Encounter'
    end
    return S.SESSION_LABELS[win.sessionType] or '?'
end
