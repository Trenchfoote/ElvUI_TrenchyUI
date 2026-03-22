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
if Enum.DamageMeterType.Deaths           then S.MODE_LABELS[Enum.DamageMeterType.Deaths]           = "Deaths"              end
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
if Enum.DamageMeterType.Deaths           then S.MODE_SHORT[Enum.DamageMeterType.Deaths]           = "Deaths"    end
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
        wipe(S.classCache)
        wipe(S.specNameCache)
        wipe(S.specCollisions)
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
S.classCache = {}
S.specNameCache = {}
S.specCollisions = {}
S.spellCache = {}
S.winDBCache = {}
S.sessionLabelCache = {}

-- Localized globals
local strsplit = strsplit
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local GetNumGroupMembers = GetNumGroupMembers
local UnitGUID = UnitGUID
local floor = math.floor

function S.ScanRoster()
    local pg = UnitGUID('player')
    if pg and not S.IsSecret(pg) then
        S.nameCache[pg] = UnitName('player')
        S.classCache[pg] = select(2, UnitClass('player'))
    end
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = 'raid' .. i
            local guid = UnitGUID(unit)
            if guid and not S.IsSecret(guid) then
                S.nameCache[guid] = UnitName(unit)
                S.classCache[guid] = select(2, UnitClass(unit))
            end
        end
    elseif IsInGroup() then
        for i = 1, GetNumGroupMembers() - 1 do
            local unit = 'party' .. i
            local guid = UnitGUID(unit)
            if guid and not S.IsSecret(guid) then
                S.nameCache[guid] = UnitName(unit)
                S.classCache[guid] = select(2, UnitClass(unit))
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

function S.RoundIfPlain(val)
    if val and not S.IsSecret(val) then
        return floor(val + 0.5)
    end
    return val
end

-- Strip decimals from sub-1K abbreviated strings (e.g. "209.385" -> "209")
function S.TruncateDecimals(text)
    if type(text) ~= 'string' or S.IsSecret(text) then return text end
    if text:match('%a') then return text end
    return (strsplit('.', text))
end

function S.FormatValueText(fontString, val)
    if not val then
        fontString:SetText('0')
        return
    end
    fontString:SetText(S.TruncateDecimals(AbbreviateNumbers(S.RoundIfPlain(val))))
end

function S.FormatCombinedText(fontString, total, perSec)
    if not total and not perSec then
        fontString:SetText('0')
        return
    end
    local ok = pcall(function()
        local p = S.TruncateDecimals(perSec and AbbreviateNumbers(S.RoundIfPlain(perSec)) or '0')
        local t = S.TruncateDecimals(total and AbbreviateNumbers(S.RoundIfPlain(total)) or '0')
        fontString:SetText(p .. ' (' .. t .. ')')
    end)
    if not ok then
        if total then
            fontString:SetText(S.TruncateDecimals(AbbreviateNumbers(S.RoundIfPlain(total))))
        else
            fontString:SetText('0')
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

function S.GetSessionSource(win, meterType, guid)
    if win.sessionId and C_DamageMeter.GetCombatSessionSourceFromID then
        return C_DamageMeter.GetCombatSessionSourceFromID(win.sessionId, meterType, guid)
    end
    return C_DamageMeter.GetCombatSessionSourceFromType(win.sessionType, meterType, guid)
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
