local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local TDM = E:GetModule('TUI_TDM')

local LSM = E.Libs.LSM
local floor = math.floor
local wipe = wipe
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local SMOOTH = Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.ExponentialEaseOut
local refreshPending = false

local function ScheduleMeterRefresh()
    if refreshPending then return end
    refreshPending = true
    C_Timer.After(0, function()
        refreshPending = false
        TDM:RefreshMeter()
    end)
end

function TDM.RefreshWindow(win)
    if not win or not win.frame or not win.header then return end

    local db = TDM.GetWinDB(win.index)

    if win.drillSource then
        local ds = win.drillSource
        local modeEntry = TDM.MODE_ORDER[win.modeIndex]
        local modeLabel = TDM.MODE_SHORT[modeEntry] or TDM.MODE_LABELS[modeEntry] or "?"
        local sessLabel = TDM.GetSessionLabel(win)
        local drillName = ds.name
        if (not drillName or drillName == '?') and (ds.secretGUID or ds.guid) then
            local resolved = select(6, GetPlayerInfoByGUID(ds.secretGUID or ds.guid))
            if resolved and E:NotSecretValue(resolved) and resolved ~= '' then
                drillName = Ambiguate(resolved, 'short')
                ds.name = drillName
            end
        end
        drillName = drillName or "?"

        local cr, cg, cb = TUI:GetClassColor(ds.class)
        local nameHex = cr and format("%02x%02x%02x", cr * 255, cg * 255, cb * 255) or "ffffff"
        win.header.modeText:SetText(format("|cff%s%s|r \226\128\148 %s", nameHex, drillName, modeLabel))
        win.header.sessText:SetText(" (" .. sessLabel .. ")")
        TDM.ApplySessionHighlight(win, db)
        win.header.timer:Hide()

        if ds.deathRecapID then
            TDM.RenderDeathRecap(win, ds, db)
            return
        end

        local spells, sourceMaxAmount, sourceTotalAmount
        if TDM.testMode then
            local tdata = TDM.GetTestData(win)
            for _, td in ipairs(tdata) do
                if td.name == ds.name then
                    spells = td.spells
                    sourceMaxAmount = td.spells[1] and (td.spells[1].totalAmount or td.spells[1][2]) or 1
                    local sum = 0
                    for _, sp in ipairs(td.spells) do sum = sum + (sp.totalAmount or sp[2] or 0) end
                    sourceTotalAmount = sum
                    break
                end
            end
        else
            local meterType = TDM.ResolveMeterType(modeEntry)
            local sourceData = ds.sourceData

            -- Use sourceIndex to resolve metadata (name, class, guid) from the summary list
            if ds.sourceIndex then
                local session = TDM.GetSession(win, meterType)
                local src = session and session.combatSources and session.combatSources[ds.sourceIndex]
                if src then
                    if (not ds.name or ds.name == '?') and src.name and (E:IsSecretValue(src.name) or src.name ~= '') then
                        ds.name = Ambiguate(src.name, 'short')
                    end
                    if (not ds.class) and src.classFilename and E:NotSecretValue(src.classFilename) then
                        ds.class = src.classFilename
                    end
                    if (not ds.guid) and src.sourceGUID and E:NotSecretValue(src.sourceGUID) then
                        ds.guid = src.sourceGUID
                    end
                    if not ds.secretGUID and src.sourceGUID then
                        ds.secretGUID = src.sourceGUID
                    end
                    if (not ds.sourceCreatureID) and src.sourceCreatureID and E:NotSecretValue(src.sourceCreatureID) then
                        ds.sourceCreatureID = src.sourceCreatureID
                    end
                end
            end

            -- GetSessionSource returns full source data including combatSpells
            local lookupGUID = ds.guid or TDM.ResolveGUID(ds.secretGUID, ds.specIconID)
            if lookupGUID or ds.sourceCreatureID then
                local fullSource = TDM.GetSessionSource(win, meterType, lookupGUID, ds.sourceCreatureID)
                if fullSource then
                    sourceData = fullSource
                    ds.sourceData = fullSource
                end
            end
            spells = sourceData and sourceData.combatSpells
            sourceMaxAmount = sourceData and sourceData.maxAmount
            sourceTotalAmount = sourceData and sourceData.totalAmount
        end

        if not spells or #spells == 0 then
            for i = 1, TDM.MAX_BARS do
                if win.bars[i] then win.bars[i].frame:Hide() end
            end
            return
        end

        local numVisible = TDM.ComputeNumVisible(win)
        local total = #spells
        win.scrollOffset = max(0, min(win.scrollOffset, max(0, total - numVisible)))

        local topVal = sourceMaxAmount or 1
        local totalAmt = sourceTotalAmount or 1

        local fgR, fgG, fgB = TDM.ClassOrColor(db, 'barClassColor', 'barColor', ds.class)
        local bgR, bgG, bgB, bgA = TDM.ClassOrColor(db, 'barBGClassColor', 'barBGColor', ds.class)
        local tR, tG, tB = TDM.ClassOrColor(db, 'textClassColor', 'textColor', ds.class)
        local vR, vG, vB = TDM.ClassOrColor(db, 'valueClassColor', 'valueColor', ds.class)

        for i = 1, TDM.MAX_BARS do
            local bar = win.bars[i]
            if not bar then break end
            local spIdx = win.scrollOffset + i
            local s = spells[spIdx]

            if i > numVisible or not s then
                bar.frame:Hide()
                bar.frame.drillSpellID = nil
            else
                bar.frame:Show()
                local rawSpellID = s.spellID or (type(s[1]) == "number" and s[1]) or nil
                local isSecretID = rawSpellID and E:IsSecretValue(rawSpellID)
                local spellID = (rawSpellID and not isSecretID) and rawSpellID or nil
                local spellName = (type(s[1]) == "string" and s[1]) or nil
                local amt = s.totalAmount or s[2] or 0

                local iconID
                if spellID then
                    local cached = TDM.spellCache[spellID]
                    if cached then
                        spellName = cached.name or spellName
                        iconID = cached.icon
                    else
                        spellName = C_Spell.GetSpellName(spellID) or spellName
                        iconID = C_Spell.GetSpellTexture(spellID)
                        TDM.spellCache[spellID] = { name = spellName, icon = iconID }
                    end
                elseif isSecretID and rawSpellID then
                    spellName = C_Spell.GetSpellName(rawSpellID)
                    iconID = C_Spell.GetSpellTexture(rawSpellID)
                end
                if not spellName then spellName = "?" end

                bar.frame.drillSpellID = spellID
                bar.frame.sourceGUID   = nil
                bar.frame.testIndex    = nil

                if iconID then
                    bar.classIcon:SetTexture(iconID)
                    bar.classIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    bar.classIcon:Show()
                else
                    bar.classIcon:Hide()
                end

                if not bar._isDrill then
                    bar._isDrill = true
                    if not bar.dpsText then
                        bar.dpsText = bar.statusbar:CreateFontString(nil, 'OVERLAY')
                        bar.dpsText:SetJustifyH('RIGHT')
                        bar.dpsText:SetWordWrap(false)
                        bar.dpsText:SetShadowOffset(1, -1)
                        bar.dpsText:SetParent(bar.textFrame)
                        bar.dpsText:SetFont(bar.rightText:GetFont())
                    end
                    bar.rightText:ClearAllPoints()
                    bar.rightText:SetPoint('RIGHT', -4, 0)
                    bar.dpsText:ClearAllPoints()
                    bar.dpsText:SetPoint('RIGHT', bar.rightText, 'LEFT', -4, 0)
                    bar.dpsText:Show()
                    bar.pctText:ClearAllPoints()
                    bar.pctText:SetPoint('RIGHT', bar.dpsText, 'LEFT', -4, 0)
                    bar.pctText:Show()
                    bar.leftText:ClearAllPoints()
                    if iconID then
                        bar.leftText:SetPoint("LEFT", bar.classIcon, "RIGHT", 2, 0)
                    else
                        bar.leftText:SetPoint("LEFT", 4, 0)
                    end
                    bar.leftText:SetPoint("RIGHT", bar.pctText, "LEFT", -4, 0)
                elseif iconID then
                    if bar._drillHasIcon ~= spellID then
                        bar.leftText:ClearAllPoints()
                        bar.leftText:SetPoint("LEFT", bar.classIcon, "RIGHT", 2, 0)
                        bar.leftText:SetPoint("RIGHT", bar.rightText, "LEFT", -4, 0)
                    end
                else
                    if bar._drillHasIcon then
                        bar.leftText:ClearAllPoints()
                        bar.leftText:SetPoint("LEFT", 4, 0)
                        bar.leftText:SetPoint("RIGHT", bar.rightText, "LEFT", -4, 0)
                    end
                end
                bar._drillHasIcon = iconID and spellID or nil

                bar.statusbar:SetStatusBarColor(fgR, fgG, fgB)
                bar.statusbar:SetMinMaxValues(0, topVal)
                bar.background:SetVertexColor(bgR, bgG, bgB, bgA)
                bar.leftText:SetFormattedText('%s', spellName)
                bar.leftText:SetTextColor(tR, tG, tB)

                bar.statusbar:SetValue(amt, SMOOTH)

                -- Value in parens
                if E:IsSecretValue(amt) then
                    bar.rightText:SetFormattedText('(%s)', AbbreviateNumbers(amt, TDM.ABBREV_SHORT))
                else
                    bar.rightText:SetText('(' .. AbbreviateNumbers(floor(amt + 0.5), TDM.ABBREV_SHORT) .. ')')
                end

                -- DPS
                local dps = s.amountPerSecond
                if bar.dpsText then
                    bar.dpsText:SetFont(bar.rightText:GetFont())
                    bar.dpsText:SetTextColor(vR, vG, vB)
                    if dps then
                        TDM.FormatValueText(bar.dpsText, dps)
                    else
                        bar.dpsText:SetText('')
                    end
                end

                -- Percentage
                if E:NotSecretValue(amt) and E:NotSecretValue(totalAmt) and totalAmt > 0 then
                    bar.pctText:SetText(format('%.1f%%', (amt / totalAmt) * 100))
                else
                    bar.pctText:SetText('')
                end
                bar.rightText:SetTextColor(vR, vG, vB)
                bar.pctText:SetTextColor(vR * 0.7, vG * 0.7, vB * 0.7)
            end
        end
        return
    end

    if TDM.testMode then
        win.header.modeText:SetText("|cffff6600[Test Mode]|r")
        win.header.sessText:SetText("")
        win.header.timer:Hide()
        local tdata      = TDM.GetTestData(win)
        local numVisible = TDM.ComputeNumVisible(win)
        local maxVal     = tdata[1] and tdata[1].value or 1
        local total      = #tdata
        win.scrollOffset = max(0, min(win.scrollOffset, max(0, total - numVisible)))
        for i = 1, TDM.MAX_BARS do
            local bar = win.bars[i]
            if not bar then break end
            local srcIdx = win.scrollOffset + i
            local td     = tdata[srcIdx]
            if i > numVisible or not td then
                bar.frame:Hide()
            else
                bar.frame:Show()
                local fgR, fgG, fgB = TDM.ClassOrColor(db, 'barClassColor', 'barColor', td.class)
                bar.statusbar:SetStatusBarColor(fgR, fgG, fgB)
                bar.statusbar:SetMinMaxValues(0, maxVal)
                bar.statusbar:SetValue(td.value, SMOOTH)
                local bgR, bgG, bgB, bgA = TDM.ClassOrColor(db, 'barBGClassColor', 'barBGColor', td.class)
                bar.background:SetVertexColor(bgR, bgG, bgB, bgA)
                local tR, tG, tB = TDM.ClassOrColor(db, 'textClassColor', 'textColor', td.class)
                if db.showRank then
                    local rr, rg, rb = TDM.ClassOrColor(db, 'rankClassColor', 'rankColor', td.class)
                    bar.leftText:SetText(format("|cff%02x%02x%02x%d.|r %s",
                        rr * 255, rg * 255, rb * 255, srcIdx, td.name))
                else
                    bar.leftText:SetText(td.name)
                end
                bar.leftText:SetTextColor(tR, tG, tB)
                if bar._isDrill then TDM.ResetDrillBar(bar, db) end
                local modeEntry = TDM.MODE_ORDER[win.modeIndex]
                if modeEntry == TDM.COMBINED_DAMAGE or modeEntry == TDM.COMBINED_HEALING then
                    if not bar.dpsText then
                        bar.dpsText = bar.statusbar:CreateFontString(nil, 'OVERLAY')
                        bar.dpsText:SetJustifyH('RIGHT')
                        bar.dpsText:SetWordWrap(false)
                        bar.dpsText:SetShadowOffset(1, -1)
                        bar.dpsText:SetParent(bar.textFrame)
                        bar.dpsText:SetFont(bar.rightText:GetFont())
                    end
                    if not bar._mainCombined then
                        bar._mainCombined = true
                        bar.dpsText:ClearAllPoints()
                        bar.dpsText:SetPoint('RIGHT', bar.rightText, 'LEFT', -4, 0)
                        bar.dpsText:Show()
                        bar.leftText:ClearAllPoints()
                        if db.classIconStyle and db.classIconStyle ~= 'none' then
                            bar.leftText:SetPoint("LEFT", bar.classIcon, "RIGHT", 2, 0)
                        else
                            bar.leftText:SetPoint("LEFT", 4, 0)
                        end
                        bar.leftText:SetPoint("RIGHT", bar.dpsText, "LEFT", -4, 0)
                    end
                    TDM.FormatCombinedText(bar.rightText, bar.dpsText, td.value, td.value / 20)
                else
                    if bar._mainCombined then
                        bar._mainCombined = nil
                        if bar.dpsText then bar.dpsText:Hide() end
                        TDM.ApplyBarIconLayout(bar, db)
                    end
                    TDM.FormatValueText(bar.rightText, td.value)
                end
                local vR, vG, vB = TDM.ClassOrColor(db, 'valueClassColor', 'valueColor', td.class)
                bar.rightText:SetTextColor(vR, vG, vB)
                if bar.dpsText then bar.dpsText:SetTextColor(vR, vG, vB) end
                TDM.SetBarClassIcon(bar, db.classIconStyle, td.class)
                bar.frame.sourceGUID   = nil
                bar.frame.sourceClass  = td.class
                bar.frame.sourceName   = td.name
                bar.frame.testIndex    = srcIdx
                bar.frame.drillSpellID = nil
            end
        end
        return
    end

    local modeEntry = TDM.MODE_ORDER[win.modeIndex]
    local meterType = TDM.ResolveMeterType(modeEntry)
    local modeLabel = TDM.MODE_SHORT[modeEntry] or TDM.MODE_LABELS[modeEntry] or "?"
    local sessLabel = TDM.GetSessionLabel(win)

    win.header.modeText:SetText(modeLabel)
    win.header.sessText:SetText(" \226\128\148 " .. sessLabel)
    TDM.ApplySessionHighlight(win, db)

    if db.showTimer and win.sessionType then
        local dur = C_DamageMeter.GetSessionDurationSeconds(win.sessionType)
        if dur then
            win.header.timer:SetText(format('%d:%02d', floor(dur / 60), floor(dur % 60)))
        else
            win.header.timer:SetText('')
        end
    else
        win.header.timer:SetText('')
    end

    local session    = TDM.GetSession(win, meterType)
    local sources    = session and session.combatSources
    TDM.UpdateSpecIconCache(sources)
    local usePerSec  = (modeEntry == Enum.DamageMeterType.Dps or modeEntry == Enum.DamageMeterType.Hps)
    local useCombined = (modeEntry == TDM.COMBINED_DAMAGE or modeEntry == TDM.COMBINED_HEALING)
    local numVisible = TDM.ComputeNumVisible(win)
    local total      = sources and #sources or 0
    win.scrollOffset = max(0, min(win.scrollOffset, max(0, total - numVisible)))

    for i = 1, TDM.MAX_BARS do
        local bar = win.bars[i]
        if not bar then break end

        if i > numVisible then
            bar.frame:Hide()
        else
            local srcIdx = win.scrollOffset + i
            local src    = sources and sources[srcIdx]
            if src then
                bar.frame:Show()

                local specIcon = src.specIconID
                local guid = (E:NotSecretValue(src.sourceGUID)) and src.sourceGUID
                    or TDM.ResolveGUID(src.sourceGUID, specIcon)
                bar.frame.sourceGUID   = guid
                bar.frame.secretGUID   = src.sourceGUID
                bar.frame.specIconID   = specIcon
                bar.frame.sourceCreatureID = src.sourceCreatureID
                bar.frame.sourceData = src
                bar.frame.sourceIndex  = srcIdx
                bar.frame.testIndex    = nil
                bar.frame.drillSpellID = nil

                local classFilename = src.classFilename
                bar.frame.sourceClass = classFilename

                local fgR, fgG, fgB = TDM.ClassOrColor(db, 'barClassColor', 'barColor', classFilename)
                bar.statusbar:SetStatusBarColor(fgR, fgG, fgB)
                local isDeathsMode = Enum.DamageMeterType.Deaths and meterType == Enum.DamageMeterType.Deaths
                if isDeathsMode then
                    bar.statusbar:SetMinMaxValues(0, 1)
                    bar.statusbar:SetValue(1, SMOOTH)
                else
                    bar.statusbar:SetMinMaxValues(0, session.maxAmount or 1)
                    bar.statusbar:SetValue(src.totalAmount or 0, SMOOTH)
                end

                local bgR, bgG, bgB, bgA = TDM.ClassOrColor(db, 'barBGClassColor', 'barBGColor', classFilename)
                bar.background:SetVertexColor(bgR, bgG, bgB, bgA)

                -- Name resolution: Ambiguate accepts secret src.name directly in 12.0.5+
                local isLocal = src.isLocalPlayer
                local plainName, sourceUnit
                if isLocal then
                    plainName = UnitName('player') or '?'
                    sourceUnit = 'player'
                elseif src.name and (E:IsSecretValue(src.name) or src.name ~= '') then
                    plainName = Ambiguate(src.name, 'short')
                end
                bar.frame.sourceName = plainName or '?'
                if not sourceUnit and plainName and E:NotSecretValue(plainName) then
                    sourceUnit = TDM.FindUnitByName(plainName)
                end
                bar.frame.sourceUnit = sourceUnit

                -- Unit token fallback: resolves secret GUIDs to real unit/name/GUID
                if not sourceUnit and src.sourceGUID then
                    local token = UnitTokenFromGUID(src.sourceGUID)
                    if token and E:NotSecretValue(token) then
                        sourceUnit = token
                        bar.frame.sourceUnit = token
                        if not plainName then
                            local tokenName = UnitName(token)
                            if tokenName and E:NotSecretValue(tokenName) then
                                plainName = tokenName
                                bar.frame.sourceName = plainName
                                local cid = src.sourceCreatureID
                                if cid and E:NotSecretValue(cid) then
                                    TDM.creatureNameCache[cid] = plainName
                                end
                            end
                        end
                        if not guid then
                            local realGUID = UnitGUID(token)
                            if realGUID and E:NotSecretValue(realGUID) then
                                guid = realGUID
                                bar.frame.sourceGUID = guid
                            end
                        end
                        if not classFilename or E:IsSecretValue(classFilename) then
                            local _, cls = UnitClass(token)
                            if cls then
                                classFilename = cls
                                bar.frame.sourceClass = cls
                            end
                        end
                    end
                end

                -- Secret name fallback for display when unit token unavailable
                local secretName = (not plainName) and src.sourceGUID and select(6, GetPlayerInfoByGUID(src.sourceGUID))
                bar.frame.secretName = secretName

                local tR, tG, tB = TDM.ClassOrColor(db, 'textClassColor', 'textColor', classFilename)
                if plainName and E:NotSecretValue(plainName) then
                    if db.showRank then
                        local rr, rg, rb = TDM.ClassOrColor(db, 'rankClassColor', 'rankColor', classFilename)
                        bar.leftText:SetText(format('|cff%02x%02x%02x%d.|r %s',
                            rr * 255, rg * 255, rb * 255, srcIdx, plainName))
                    else
                        bar.leftText:SetText(plainName)
                    end
                elseif plainName then
                    bar.leftText:SetFormattedText('%s', plainName)
                elseif secretName then
                    if db.showRank then
                        bar.leftText:SetFormattedText('%d. %s', srcIdx, secretName)
                    else
                        bar.leftText:SetFormattedText('%s', secretName)
                    end
                else
                    bar.leftText:SetText('?')
                end
                bar.leftText:SetTextColor(tR, tG, tB)

                if bar._isDrill then TDM.ResetDrillBar(bar, db) end

                local isDeaths = Enum.DamageMeterType.Deaths and meterType == Enum.DamageMeterType.Deaths
                if isDeaths then
                    local deathTime = src.deathTimeSeconds
                    if deathTime and E:NotSecretValue(deathTime) and deathTime > 0 then
                        bar.rightText:SetText(format('%d:%02d', floor(deathTime / 60), floor(deathTime % 60)))
                    else
                        bar.rightText:SetText('')
                    end
                    if bar._mainCombined then
                        bar._mainCombined = nil
                        if bar.dpsText then bar.dpsText:Hide() end
                        TDM.ApplyBarIconLayout(bar, db)
                    end
                elseif useCombined then
                    if not bar.dpsText then
                        bar.dpsText = bar.statusbar:CreateFontString(nil, 'OVERLAY')
                        bar.dpsText:SetJustifyH('RIGHT')
                        bar.dpsText:SetWordWrap(false)
                        bar.dpsText:SetShadowOffset(1, -1)
                        bar.dpsText:SetParent(bar.textFrame)
                        bar.dpsText:SetFont(bar.rightText:GetFont())
                    end
                    if not bar._mainCombined then
                        bar._mainCombined = true
                        bar.dpsText:ClearAllPoints()
                        bar.dpsText:SetPoint('RIGHT', bar.rightText, 'LEFT', -4, 0)
                        bar.dpsText:Show()
                        bar.leftText:ClearAllPoints()
                        if db.classIconStyle and db.classIconStyle ~= 'none' then
                            bar.leftText:SetPoint("LEFT", bar.classIcon, "RIGHT", 2, 0)
                        else
                            bar.leftText:SetPoint("LEFT", 4, 0)
                        end
                        bar.leftText:SetPoint("RIGHT", bar.dpsText, "LEFT", -4, 0)
                    end
                    TDM.FormatCombinedText(bar.rightText, bar.dpsText, src.totalAmount, src.amountPerSecond)
                else
                    if bar._mainCombined then
                        bar._mainCombined = nil
                        if bar.dpsText then bar.dpsText:Hide() end
                        TDM.ApplyBarIconLayout(bar, db)
                    end
                    local rawValue = usePerSec and src.amountPerSecond or src.totalAmount
                    TDM.FormatValueText(bar.rightText, rawValue)
                end
                local vR, vG, vB = TDM.ClassOrColor(db, 'valueClassColor', 'valueColor', classFilename)
                bar.rightText:SetTextColor(vR, vG, vB)
                if bar.dpsText then bar.dpsText:SetTextColor(vR, vG, vB) end

                TDM.SetBarClassIcon(bar, db.classIconStyle, classFilename, specIcon)
            else
                bar.frame:Hide()
                bar.frame.sourceGUID = nil
                bar.frame.sourceName = nil
                bar.frame.sourceData = nil
            end
        end
    end
end

function TDM:RefreshMeter()
    for _, win in pairs(TDM.windows) do
        TDM.RefreshWindow(win)
    end
end

function TDM:SetMeterTestMode(enabled)
    TDM.testMode = enabled
    ScheduleMeterRefresh()
end

-- Fade helpers for flight visibility
local function GetPlayerFaderSettings()
    local fdb = E.db and E.db.unitframe and E.db.unitframe.units
        and E.db.unitframe.units.player and E.db.unitframe.units.player.fader
    if not fdb or not fdb.enable then return nil, nil end
    return fdb.smooth, fdb.delay
end

local function FadeMeterOut(smooth)
    for _, win in pairs(TDM.windows) do
        if win.embedded then
            if win.frame then E:UIFrameFadeOut(win.frame, smooth, win.frame:GetAlpha(), 0) end
            local wdb = TDM.GetWinDB(win.index)
            if not (wdb and wdb.headerMouseover) then
                if win.header then E:UIFrameFadeOut(win.header, smooth, win.header:GetAlpha(), 0) end
                if win.headerBorder then E:UIFrameFadeOut(win.headerBorder, smooth, win.headerBorder:GetAlpha(), 0) end
            end
        elseif win.window then
            E:UIFrameFadeOut(win.window, smooth, win.window:GetAlpha(), 0)
        end
    end
    TDM.meterFadedOut = true
end

local function FadeMeterIn(smooth)
    for _, win in pairs(TDM.windows) do
        if win.embedded then
            if win.frame then E:UIFrameFadeIn(win.frame, smooth, win.frame:GetAlpha(), 1) end
            local wdb = TDM.GetWinDB(win.index)
            if wdb and wdb.headerMouseover then
                if win.header then win.header:SetAlpha(0) end
                if win.headerBorder then win.headerBorder:SetAlpha(0) end
            else
                if win.header then E:UIFrameFadeIn(win.header, smooth, win.header:GetAlpha(), 1) end
                if win.headerBorder then E:UIFrameFadeIn(win.headerBorder, smooth, win.headerBorder:GetAlpha(), 1) end
            end
        elseif win.window then
            E:UIFrameFadeIn(win.window, smooth, win.window:GetAlpha(), 1)
        end
    end
    TDM.meterFadedOut = false
end

local function CancelFlightFade()
    if TDM.flightFadeTimer then
        E:CancelTimer(TDM.flightFadeTimer)
        TDM.flightFadeTimer = nil
    end
end

function TDM:UpdateMeterVisibility()
    local db = TUI.db.profile.damageMeter
    local petBattle = db.hideInPetBattle and C_PetBattles and C_PetBattles.IsInBattle()
    local inFlight = not petBattle and db.hideInFlight and IsFlying()
    local shouldHide = petBattle or inFlight

    if shouldHide == TDM.meterHidden then return end
    TDM.meterHidden = shouldHide
    CancelFlightFade()

    if shouldHide then
        if inFlight then
            local smooth, delay = GetPlayerFaderSettings()
            if smooth and smooth > 0 then
                if delay and delay > 0 then
                    TDM.flightFadeTimer = E:ScheduleTimer(FadeMeterOut, delay, smooth)
                else
                    FadeMeterOut(smooth)
                end
                return
            end
        end
        -- Instant hide (pet battle or no fader settings)
        for _, win in pairs(TDM.windows) do
            if win.embedded then
                if win.frame then win.frame:Hide() end
                if win.header then win.header:Hide() end
                if win.headerBorder then win.headerBorder:Hide() end
            elseif win.window then
                win.window:Hide()
            end
        end
    else
        if TDM.meterFadedOut then
            local smooth = GetPlayerFaderSettings()
            FadeMeterIn((smooth and smooth > 0) and smooth or 0)
            return
        end
        -- Instant show
        for _, win in pairs(TDM.windows) do
            if win.embedded then
                if win.frame then win.frame:Show() end
                if win.header then win.header:Show() end
                if win.headerBorder then win.headerBorder:Show() end
            elseif win.window then
                win.window:Show()
            end
            local wdb = TDM.GetWinDB(win.index)
            if wdb and wdb.headerMouseover then
                if win.header then win.header:SetAlpha(0) end
                if win.headerBorder then win.headerBorder:SetAlpha(0) end
            end
        end
    end
end

function TDM:UpdateFlightTicker()
    local db = TUI.db.profile.damageMeter
    if db.hideInFlight and not TDM.flightTicker then
        TDM.flightTicker = C_Timer.NewTicker(0.25, function() TDM:UpdateMeterVisibility() end)
    elseif not db.hideInFlight and TDM.flightTicker then
        TDM.flightTicker:Cancel()
        TDM.flightTicker = nil
        TDM:UpdateMeterVisibility()
    end
end

local function UpdateTimers()
    for _, win in pairs(TDM.windows) do
        if win.header and win.header.timer and not win.drillSource then
            local wdb = TDM.GetWinDB(win.index)
            if not wdb.showTimer then
                win.header.timer:SetText('')
            elseif win.sessionType then
                local dur = C_DamageMeter.GetSessionDurationSeconds(win.sessionType)
                if dur then
                    win.header.timer:SetText(format('%d:%02d', floor(dur / 60), floor(dur % 60)))
                end
            end
        end
    end
end

function TDM:ResizeMeterWindow(index)
    TDM.ResizeStandalone(TDM.windows[index])
end

function TDM:CreateExtraWindow(index)
    if TDM.windows[index] then return end
    local db = TUI.db.profile.damageMeter
    local ewdb = db.extraWindows[index] or {}
    local win = TDM.NewWindowState(index, ewdb.modeIndex)
    TDM.windows[index] = win
    TDM.CreateMeterFrame(win, false)
    TDM.RefreshWindow(win)
end

function TDM:DestroyExtraWindow(index)
    local win = TDM.windows[index]
    if not win then return end
    local winName = "TrenchyUIMeter" .. index
    if win.window then
        E:DisableMover(winName)
        win.window:Hide()
    end
    TDM.windows[index] = nil
end

function TDM:UpdateMeterLayout()
    if not next(TDM.windows) then return end

    for _, win in pairs(TDM.windows) do
        local db       = TDM.GetWinDB(win.index)
        local fontPath = LSM:Fetch("font", db.barFont)
        local flags    = TDM.FontFlags(db.barFontOutline)

        local fgTex = (db.barTexture and db.barTexture ~= '') and LSM:Fetch("statusbar", db.barTexture) or E.media.normTex
        local bgTex = (db.barBGTexture and db.barBGTexture ~= '') and LSM:Fetch("statusbar", db.barBGTexture) or E.media.normTex

        TDM.ApplyHeaderStyle(win, db)
        TDM.RespaceBarAnchors(win, db)
        for i = 1, TDM.MAX_BARS do
            local bar = win.bars[i]
            if bar then
                TDM.StyleBarTexts(bar, fontPath, db.barFontSize, flags)
                bar.statusbar:SetStatusBarTexture(fgTex)
                bar.background:SetTexture(bgTex)
                TDM.ApplyBarIconLayout(bar, db)
                TDM.ApplyBarBorder(bar, db)
            end
        end

        if win.frame then
            if db.showBackdrop then
                win.frame:SetTemplate('Transparent')
                local bc = db.backdropColor
                if bc then
                    win.frame:SetBackdropColor(bc.r, bc.g, bc.b, bc.a)
                end
            else
                win.frame:SetBackdrop(nil)
            end
        end

        if win.headerBorder then
            if db.showHeaderBorder then
                win.headerBorder:SetTemplate()
                win.headerBorder:SetBackdropColor(0, 0, 0, 0)
            else
                win.headerBorder:SetBackdrop(nil)
            end
        end

        if win.header and win.header.bg then
            if db.showHeaderBackdrop then
                win.header.bg:Show()
            else
                win.header.bg:Hide()
            end
        end

        -- Header mouseover: hide header unless moused over
        if win.header then
            TDM.SetupHeaderMouseover(win)
            if db.headerMouseover then
                win.header:SetAlpha(0)
                if win.headerBorder then win.headerBorder:SetAlpha(0) end
            else
                win.header:SetAlpha(1)
                if win.headerBorder then win.headerBorder:SetAlpha(1) end
            end
        end

        if win.embedded then
            TDM.ResizeToPanel(win)
        else
            TDM.ResizeStandalone(win)
        end
    end

    TDM:RefreshMeter()
end

-- Death recap drilldown
function TDM.RenderDeathRecap(win, ds, db)
    local events = C_DeathRecap and C_DeathRecap.GetRecapEvents and C_DeathRecap.GetRecapEvents(ds.deathRecapID)
    if not events or #events == 0 then
        for i = 1, TDM.MAX_BARS do
            if win.bars[i] then win.bars[i].frame:Hide() end
        end
        return
    end

    local maxHealth = C_DeathRecap.GetRecapMaxHealth(ds.deathRecapID) or 1

    -- Reverse so oldest event (healthy) is at top, killing blow at bottom
    local reversed = {}
    for idx = #events, 1, -1 do
        reversed[#reversed + 1] = events[idx]
    end

    local numVisible = TDM.ComputeNumVisible(win)
    local total = #reversed
    win.scrollOffset = max(0, min(win.scrollOffset, max(0, total - numVisible)))

    local vR, vG, vB = TDM.ClassOrColor(db, 'valueClassColor', 'valueColor', ds.class)
    local fontPath = LSM:Fetch('font', db.barFont)
    local flags = TDM.FontFlags(db.barFontOutline)
    local fontSize = db.barFontSize

    for i = 1, TDM.MAX_BARS do
        local bar = win.bars[i]
        if not bar then break end
        local evIdx = win.scrollOffset + i
        local ev = reversed[evIdx]

        if i > numVisible or not ev then
            bar.frame:Hide()
            bar.frame.drillSpellID = nil
        else
            bar.frame:Show()
            TDM.StyleBarTexts(bar, fontPath, fontSize, flags)

            local spellID = ev.spellId
            local spellName = ev.spellName
            local iconID
            if spellID and E:NotSecretValue(spellID) then
                iconID = C_Spell.GetSpellTexture(spellID)
                if not spellName then spellName = C_Spell.GetSpellName(spellID) end
                bar.frame.drillSpellID = spellID
            else
                bar.frame.drillSpellID = nil
            end

            if not spellName or (E:NotSecretValue(spellName) and spellName == '') then
                local evType = ev.event
                if evType == 'SWING_DAMAGE' then
                    spellName = ACTION_SWING
                    if not iconID then iconID = 132223 end
                elseif evType and evType:find('ENVIRONMENTAL') then
                    spellName = 'Environment'
                else
                    spellName = '?'
                end
            end

            -- Layout: rightText for HP%, dpsText for (-damage)
            if not bar._isDrill then
                bar._isDrill = true
                if not bar.dpsText then
                    bar.dpsText = bar.statusbar:CreateFontString(nil, 'OVERLAY')
                    bar.dpsText:SetJustifyH('RIGHT')
                    bar.dpsText:SetWordWrap(false)
                    bar.dpsText:SetShadowOffset(1, -1)
                    bar.dpsText:SetParent(bar.textFrame)
                    bar.dpsText:SetFont(bar.rightText:GetFont())
                end
                bar.dpsText:ClearAllPoints()
                bar.dpsText:SetPoint('RIGHT', -4, 0)
                bar.dpsText:SetWidth(90)
                bar.rightText:ClearAllPoints()
                bar.rightText:SetPoint('RIGHT', bar.dpsText, 'LEFT', -2, 0)
                bar.dpsText:Show()
                bar.pctText:Hide()
            end
            if iconID then
                bar.classIcon:SetTexture(iconID)
                bar.classIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                bar.classIcon:Show()
                bar.leftText:ClearAllPoints()
                bar.leftText:SetPoint("LEFT", bar.classIcon, "RIGHT", 2, 0)
                bar.leftText:SetPoint("RIGHT", bar.rightText, "LEFT", -4, 0)
            else
                bar.classIcon:Hide()
                bar.leftText:ClearAllPoints()
                bar.leftText:SetPoint("LEFT", 4, 0)
                bar.leftText:SetPoint("RIGHT", bar.rightText, "LEFT", -4, 0)
            end

            -- Bar colors: use standard db colors
            local fgR, fgG, fgB = TDM.ClassOrColor(db, 'barClassColor', 'barColor', ds.class)
            local bgR, bgG, bgB, bgA = TDM.ClassOrColor(db, 'barBGClassColor', 'barBGColor', ds.class)
            bar.statusbar:SetStatusBarColor(fgR, fgG, fgB)
            bar.background:SetVertexColor(bgR, bgG, bgB, bgA)

            local hp = ev.currentHP or 0
            bar.statusbar:SetMinMaxValues(0, maxHealth)
            bar.statusbar:SetValue(E:IsSecretValue(hp) and 0 or hp, SMOOTH)

            -- Left text: spell name colored by type, source in gray
            local isKillingBlow = evIdx == total
            local nameStr = E:NotSecretValue(spellName) and spellName or '?'
            if isKillingBlow then
                nameStr = '|cffff3333' .. nameStr .. '|r'
            elseif ev.avoidable then
                nameStr = '|cffffcc00' .. nameStr .. '|r'
            end
            bar.leftText:SetText(nameStr)
            bar.leftText:SetTextColor(1, 1, 1)

            -- Right: HP% in rightText, (-damage) in dpsText
            if E:IsSecretValue(hp) or maxHealth <= 0 then
                bar.rightText:SetText('')
                bar.dpsText:SetText('')
            else
                bar.rightText:SetText(floor(hp / maxHealth * 100 + 0.5) .. '%')
                local amt = ev.amount
                if amt and E:NotSecretValue(amt) and amt > 0 then
                    bar.dpsText:SetText('(-' .. AbbreviateNumbers(floor(amt + 0.5), TDM.ABBREV_SHORT) .. ')')
                else
                    bar.dpsText:SetText('')
                end
            end
            bar.rightText:SetTextColor(vR, vG, vB)
            if isKillingBlow then
                bar.dpsText:SetTextColor(1, 0.2, 0.2)
            elseif ev.avoidable then
                bar.dpsText:SetTextColor(1, 0.8, 0)
            else
                bar.dpsText:SetTextColor(0.6, 0.6, 0.6)
            end
        end
    end
end

function TDM:Initialize()
    if TUI:IsCompatBlocked('damageMeter') then return end
    if not TUI.db or not TUI.db.profile.damageMeter.enabled then return end
    if TDM._initialized then return end
    TDM._initialized = true

    SetCVar('damageMeterEnabled', 0)
    SetCVar('damageMeterResetOnNewInstance', TUI.db.profile.damageMeter.autoResetOnComplete and 1 or 0)

    C_Timer.After(0, function()
        local CH = E:GetModule('Chat')
        local db = TUI.db.profile.damageMeter

        local win1 = TDM.NewWindowState(1, db.modeIndex)
        TDM.windows[1] = win1
        TDM.CreateMeterFrame(win1, db.embedded)

        local we = db.windowEnabled
        for i = 2, 4 do
            if we and we[i] then
                local ewdb = db.extraWindows[i] or {}
                local win  = TDM.NewWindowState(i, ewdb.modeIndex)
                TDM.windows[i] = win
                TDM.CreateMeterFrame(win, false)
            end
        end

        if not win1.frame then return end

        local function OnTDMEvent(event)
            if event == 'PET_BATTLE_OPENING_START' or event == 'PET_BATTLE_CLOSE' then
                TDM:UpdateMeterVisibility()
                return
            elseif event == 'PLAYER_REGEN_DISABLED' then
                TDM.ScanRoster()
                return
            elseif event == 'PLAYER_REGEN_ENABLED' then
                TDM.ScanRoster()
                TDM.CacheCreatureNames()
                ScheduleMeterRefresh()
                return
            elseif event == 'GROUP_ROSTER_UPDATE' then
                wipe(TDM.specIconCache)
                TDM.ScanRoster()
                return
            elseif event == 'PLAYER_ENTERING_WORLD' then
                TDM.ScanRoster()
                TDM.CacheCreatureNames()
                ScheduleMeterRefresh()
                return
            elseif event == 'DAMAGE_METER_RESET' then
                wipe(TDM.sessionLabelCache)
                for _, w in pairs(TDM.windows) do
                    TDM.ResetWindowState(w)
                end
                ScheduleMeterRefresh()
            else
                wipe(TDM.sessionLabelCache)
                ScheduleMeterRefresh()
            end
        end

        TDM.ScanRoster()
        TDM:RegisterEvent('DAMAGE_METER_COMBAT_SESSION_UPDATED', OnTDMEvent)
        TDM:RegisterEvent('DAMAGE_METER_CURRENT_SESSION_UPDATED', OnTDMEvent)
        TDM:RegisterEvent('DAMAGE_METER_RESET', OnTDMEvent)
        TDM:RegisterEvent('PLAYER_ENTERING_WORLD', OnTDMEvent)
        TDM:RegisterEvent('PLAYER_REGEN_DISABLED', OnTDMEvent)
        TDM:RegisterEvent('PLAYER_REGEN_ENABLED', OnTDMEvent)
        TDM:RegisterEvent('GROUP_ROSTER_UPDATE', OnTDMEvent)
        TDM:RegisterEvent('PET_BATTLE_OPENING_START', OnTDMEvent)
        TDM:RegisterEvent('PET_BATTLE_CLOSE', OnTDMEvent)
        if not TDM.timerTicker then
            TDM.timerTicker = C_Timer.NewTicker(0.5, UpdateTimers)
        end

        TDM:UpdateFlightTicker()

        hooksecurefunc(CH, "PositionChats", function()
            if db.embedded then
                TDM.ResizeToPanel(win1)
                if CH.RightChatWindow then CH.RightChatWindow:Hide() end
            end
        end)

        ScheduleMeterRefresh()
    end)
end

SLASH_TUITDM1 = '/tdm'
SlashCmdList['TUITDM'] = function()
    local open = E.Libs.AceConfigDialog and E.Libs.AceConfigDialog.OpenFrames and E.Libs.AceConfigDialog.OpenFrames['ElvUI']
    if not open then E:ToggleOptions('TrenchyUI') end
    C_Timer.After(0.1, function()
        E.Libs.AceConfigDialog:SelectGroup('ElvUI', 'TrenchyUI', 'damageMeter')
    end)
end

E:RegisterModule(TDM:GetName())
