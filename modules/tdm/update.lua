local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local S = TUI._tdm
if not S then return end

local LSM = E.Libs.LSM
local floor = math.floor
local wipe = wipe
local GetPlayerInfoByGUID = GetPlayerInfoByGUID

function S.RefreshWindow(win)
    if not win or not win.frame or not win.header then return end

    local db = S.GetWinDB(win.index)

    if win.drillSource then
        local ds = win.drillSource
        local modeEntry = S.MODE_ORDER[win.modeIndex]
        local modeLabel = S.MODE_SHORT[modeEntry] or S.MODE_LABELS[modeEntry] or "?"
        local sessLabel = S.GetSessionLabel(win)
        local drillName = ds.name
        if (not drillName or drillName == '?') and (ds.secretGUID or ds.guid) then
            local resolved = select(6, GetPlayerInfoByGUID(ds.secretGUID or ds.guid))
            if resolved and not S.IsSecret(resolved) and resolved ~= '' then
                drillName = Ambiguate(resolved, 'short')
                ds.name = drillName
            end
        end
        drillName = drillName or "?"

        local cr, cg, cb = TUI:GetClassColor(ds.class)
        local nameHex = cr and format("%02x%02x%02x", cr * 255, cg * 255, cb * 255) or "ffffff"
        win.header.modeText:SetText(format("|cff%s%s|r \226\128\148 %s", nameHex, drillName, modeLabel))
        win.header.sessText:SetText(" (" .. sessLabel .. ")")
        S.ApplySessionHighlight(win, db)
        win.header.timer:Hide()

        local spells, sourceMaxAmount, sourceTotalAmount
        if S.testMode then
            local tdata = S.GetTestData(win)
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
            local meterType = S.ResolveMeterType(modeEntry)
            local sourceData = ds.sourceData

            -- Use sourceIndex to resolve metadata (name, class, guid) from the summary list
            if ds.sourceIndex then
                local session = S.GetSession(win, meterType)
                local src = session and session.combatSources and session.combatSources[ds.sourceIndex]
                if src then
                    if (not ds.name or ds.name == '?') and not S.IsSecret(src.name) and src.name and src.name ~= '' then
                        ds.name = Ambiguate(src.name, 'short')
                    end
                    if (not ds.class) and src.classFilename and not S.IsSecret(src.classFilename) then
                        ds.class = src.classFilename
                    end
                    if (not ds.guid) and src.sourceGUID and not S.IsSecret(src.sourceGUID) then
                        ds.guid = src.sourceGUID
                    end
                    if not ds.secretGUID and src.sourceGUID then
                        ds.secretGUID = src.sourceGUID
                    end
                    if (not ds.sourceCreatureID) and src.sourceCreatureID and not S.IsSecret(src.sourceCreatureID) then
                        ds.sourceCreatureID = src.sourceCreatureID
                    end
                end
            end

            -- GetSessionSource returns full source data including combatSpells
            local lookupGUID = ds.guid or S.ResolveGUID(ds.secretGUID, ds.specIconID)
            if lookupGUID or ds.sourceCreatureID then
                local fullSource = S.GetSessionSource(win, meterType, lookupGUID, ds.sourceCreatureID)
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
            for i = 1, S.MAX_BARS do
                if win.bars[i] then win.bars[i].frame:Hide() end
            end
            return
        end

        local numVisible = S.ComputeNumVisible(win)
        local total = #spells
        win.scrollOffset = max(0, min(win.scrollOffset, max(0, total - numVisible)))

        local topVal = sourceMaxAmount or 1
        local totalAmt = sourceTotalAmount or 1

        local fgR, fgG, fgB = S.ClassOrColor(db, 'barClassColor', 'barColor', ds.class)
        local bgR, bgG, bgB, bgA = S.ClassOrColor(db, 'barBGClassColor', 'barBGColor', ds.class)
        local tR, tG, tB = S.ClassOrColor(db, 'textClassColor', 'textColor', ds.class)
        local vR, vG, vB = S.ClassOrColor(db, 'valueClassColor', 'valueColor', ds.class)

        for i = 1, S.MAX_BARS do
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
                local isSecretID = rawSpellID and issecretvalue(rawSpellID)
                local spellID = (rawSpellID and not isSecretID) and rawSpellID or nil
                local spellName = (type(s[1]) == "string" and s[1]) or nil
                local amt = s.totalAmount or s[2] or 0

                local iconID
                if spellID then
                    local cached = S.spellCache[spellID]
                    if cached then
                        spellName = cached.name or spellName
                        iconID = cached.icon
                    else
                        spellName = C_Spell.GetSpellName(spellID) or spellName
                        iconID = C_Spell.GetSpellTexture(spellID)
                        S.spellCache[spellID] = { name = spellName, icon = iconID }
                    end
                elseif isSecretID then
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

                bar.statusbar:SetValue(amt)

                -- Value in parens
                if issecretvalue(amt) then
                    bar.rightText:SetFormattedText('(%s)', AbbreviateNumbers(amt, S.ABBREV_SHORT))
                else
                    bar.rightText:SetText('(' .. S.TruncateDecimals(AbbreviateNumbers(floor(amt + 0.5))) .. ')')
                end

                -- DPS
                local dps = s.amountPerSecond
                if bar.dpsText then
                    bar.dpsText:SetFont(bar.rightText:GetFont())
                    bar.dpsText:SetTextColor(vR, vG, vB)
                    if dps then
                        S.FormatValueText(bar.dpsText, dps)
                    else
                        bar.dpsText:SetText('')
                    end
                end

                -- Percentage
                if not issecretvalue(amt) and not S.IsSecret(totalAmt) and totalAmt > 0 then
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

    if S.testMode then
        win.header.modeText:SetText("|cffff6600[Test Mode]|r")
        win.header.sessText:SetText("")
        win.header.timer:Hide()
        local tdata      = S.GetTestData(win)
        local numVisible = S.ComputeNumVisible(win)
        local maxVal     = tdata[1] and tdata[1].value or 1
        local total      = #tdata
        win.scrollOffset = max(0, min(win.scrollOffset, max(0, total - numVisible)))
        for i = 1, S.MAX_BARS do
            local bar = win.bars[i]
            if not bar then break end
            local srcIdx = win.scrollOffset + i
            local td     = tdata[srcIdx]
            if i > numVisible or not td then
                bar.frame:Hide()
            else
                bar.frame:Show()
                local fgR, fgG, fgB = S.ClassOrColor(db, 'barClassColor', 'barColor', td.class)
                bar.statusbar:SetStatusBarColor(fgR, fgG, fgB)
                bar.statusbar:SetMinMaxValues(0, maxVal)
                bar.statusbar:SetValue(td.value)
                local bgR, bgG, bgB, bgA = S.ClassOrColor(db, 'barBGClassColor', 'barBGColor', td.class)
                bar.background:SetVertexColor(bgR, bgG, bgB, bgA)
                local tR, tG, tB = S.ClassOrColor(db, 'textClassColor', 'textColor', td.class)
                if db.showRank then
                    local rr, rg, rb = S.ClassOrColor(db, 'rankClassColor', 'rankColor', td.class)
                    bar.leftText:SetText(format("|cff%02x%02x%02x%d.|r %s",
                        rr * 255, rg * 255, rb * 255, srcIdx, td.name))
                else
                    bar.leftText:SetText(td.name)
                end
                bar.leftText:SetTextColor(tR, tG, tB)
                local modeEntry = S.MODE_ORDER[win.modeIndex]
                if modeEntry == S.COMBINED_DAMAGE or modeEntry == S.COMBINED_HEALING then
                    S.FormatCombinedText(bar.rightText, td.value, td.value / 20)
                else
                    S.FormatValueText(bar.rightText, td.value)
                end
                local vR, vG, vB = S.ClassOrColor(db, 'valueClassColor', 'valueColor', td.class)
                bar.rightText:SetTextColor(vR, vG, vB)
                if bar._isDrill then S.ResetDrillBar(bar, db) end
                if db.showClassIcon then
                    local coords = S.CLASS_ICON_COORDS[td.class]
                    if coords then
                        bar.classIcon:SetTexCoord(unpack(coords))
                        bar.classIcon:Show()
                    else
                        bar.classIcon:Hide()
                    end
                else
                    bar.classIcon:Hide()
                end
                bar.frame.sourceGUID   = nil
                bar.frame.sourceClass  = td.class
                bar.frame.sourceName   = td.name
                bar.frame.testIndex    = srcIdx
                bar.frame.drillSpellID = nil
            end
        end
        return
    end

    local modeEntry = S.MODE_ORDER[win.modeIndex]
    local meterType = S.ResolveMeterType(modeEntry)
    local modeLabel = S.MODE_SHORT[modeEntry] or S.MODE_LABELS[modeEntry] or "?"
    local sessLabel = S.GetSessionLabel(win)

    win.header.modeText:SetText(modeLabel)
    win.header.sessText:SetText(" \226\128\148 " .. sessLabel)
    S.ApplySessionHighlight(win, db)

    if win.sessionType then
        local dur = C_DamageMeter.GetSessionDurationSeconds(win.sessionType)
        if dur then
            win.header.timer:SetText(format('%d:%02d', floor(dur / 60), floor(dur % 60)))
        else
            win.header.timer:SetText('')
        end
    else
        win.header.timer:SetText('')
    end

    local session    = S.GetSession(win, meterType)
    local sources    = session and session.combatSources
    S.UpdateSpecIconCache(sources)
    local usePerSec  = (modeEntry == Enum.DamageMeterType.Dps or modeEntry == Enum.DamageMeterType.Hps)
    local useCombined = (modeEntry == S.COMBINED_DAMAGE or modeEntry == S.COMBINED_HEALING)
    local numVisible = S.ComputeNumVisible(win)
    local total      = sources and #sources or 0
    win.scrollOffset = max(0, min(win.scrollOffset, max(0, total - numVisible)))

    for i = 1, S.MAX_BARS do
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
                local guid = (not S.IsSecret(src.sourceGUID)) and src.sourceGUID
                    or S.ResolveGUID(src.sourceGUID, specIcon)
                bar.frame.sourceGUID   = guid
                bar.frame.specIconID   = specIcon
                bar.frame.sourceCreatureID = src.sourceCreatureID
                bar.frame.sourceData = src
                bar.frame.sourceIndex  = srcIdx
                bar.frame.testIndex    = nil
                bar.frame.drillSpellID = nil

                local classFilename = src.classFilename
                bar.frame.sourceClass = classFilename

                local fgR, fgG, fgB = S.ClassOrColor(db, 'barClassColor', 'barColor', classFilename)
                bar.statusbar:SetStatusBarColor(fgR, fgG, fgB)
                bar.statusbar:SetMinMaxValues(0, session.maxAmount or 1)
                bar.statusbar:SetValue(src.totalAmount or 0)

                local bgR, bgG, bgB, bgA = S.ClassOrColor(db, 'barBGClassColor', 'barBGColor', classFilename)
                bar.background:SetVertexColor(bgR, bgG, bgB, bgA)

                -- Name resolution: roster cache > GetPlayerInfoByGUID > C_DamageMeter
                local isLocal = src.isLocalPlayer
                local plainName, sourceUnit
                if isLocal then
                    local pg = UnitGUID('player')
                    plainName = (pg and S.nameCache[pg]) or UnitName('player') or '?'
                    sourceUnit = 'player'
                elseif guid and S.nameCache[guid] then
                    plainName = S.nameCache[guid]
                    sourceUnit = S.FindUnitByGUID(guid)
                elseif not S.IsSecret(src.name) and src.name and src.name ~= '' then
                    plainName = Ambiguate(src.name, 'short')
                end
                bar.frame.sourceName = plainName or '?'
                if not sourceUnit and plainName then
                    sourceUnit = S.FindUnitByName(plainName)
                end
                bar.frame.sourceUnit = sourceUnit

                -- Unit token fallback: resolves secret GUIDs to real unit/name/GUID
                if not sourceUnit and src.sourceGUID then
                    local token = UnitTokenFromGUID(src.sourceGUID)
                    if token and not S.IsSecret(token) then
                        sourceUnit = token
                        bar.frame.sourceUnit = token
                        if not plainName then
                            plainName = UnitName(token)
                            bar.frame.sourceName = plainName or '?'
                        end
                        if not guid then
                            local realGUID = UnitGUID(token)
                            if realGUID and not S.IsSecret(realGUID) then
                                guid = realGUID
                                bar.frame.sourceGUID = guid
                            end
                        end
                        if not classFilename or S.IsSecret(classFilename) then
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

                local tR, tG, tB = S.ClassOrColor(db, 'textClassColor', 'textColor', classFilename)
                if plainName then
                    if db.showRank then
                        local rr, rg, rb = S.ClassOrColor(db, 'rankClassColor', 'rankColor', classFilename)
                        bar.leftText:SetText(format('|cff%02x%02x%02x%d.|r %s',
                            rr * 255, rg * 255, rb * 255, srcIdx, plainName))
                    else
                        bar.leftText:SetText(plainName)
                    end
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

                if useCombined then
                    S.FormatCombinedText(bar.rightText, src.totalAmount, src.amountPerSecond)
                else
                    local rawValue = usePerSec and src.amountPerSecond or src.totalAmount
                    S.FormatValueText(bar.rightText, rawValue)
                end
                local vR, vG, vB = S.ClassOrColor(db, 'valueClassColor', 'valueColor', classFilename)
                bar.rightText:SetTextColor(vR, vG, vB)
                if bar._isDrill then S.ResetDrillBar(bar, db) end

                if db.showClassIcon then
                    local coords = classFilename and S.CLASS_ICON_COORDS[classFilename]
                    if coords then
                        bar.classIcon:SetTexCoord(unpack(coords))
                        bar.classIcon:Show()
                    else
                        bar.classIcon:Hide()
                    end
                else
                    bar.classIcon:Hide()
                end
            else
                bar.frame:Hide()
                bar.frame.sourceGUID = nil
                bar.frame.sourceName = nil
                bar.frame.sourceData = nil
            end
        end
    end
end

function TUI:RefreshMeter()
    for _, win in pairs(S.windows) do
        S.RefreshWindow(win)
    end
end

function TUI:SetMeterTestMode(enabled)
    S.testMode           = enabled
    TUI._meterTestMode = enabled
    TUI:RefreshMeter()
end

-- Fade helpers for flight visibility
local function GetPlayerFaderSettings()
    local fdb = E.db and E.db.unitframe and E.db.unitframe.units
        and E.db.unitframe.units.player and E.db.unitframe.units.player.fader
    if not fdb or not fdb.enable then return nil, nil end
    return fdb.smooth, fdb.delay
end

local function FadeMeterOut(smooth)
    for _, win in pairs(S.windows) do
        if win.embedded then
            if win.frame then E:UIFrameFadeOut(win.frame, smooth, win.frame:GetAlpha(), 0) end
            local wdb = S.GetWinDB(win.index)
            if not (wdb and wdb.headerMouseover) then
                if win.header then E:UIFrameFadeOut(win.header, smooth, win.header:GetAlpha(), 0) end
                if win.headerBorder then E:UIFrameFadeOut(win.headerBorder, smooth, win.headerBorder:GetAlpha(), 0) end
            end
        elseif win.window then
            E:UIFrameFadeOut(win.window, smooth, win.window:GetAlpha(), 0)
        end
    end
    S.meterFadedOut = true
end

local function FadeMeterIn(smooth)
    for _, win in pairs(S.windows) do
        if win.embedded then
            if win.frame then E:UIFrameFadeIn(win.frame, smooth, win.frame:GetAlpha(), 1) end
            local wdb = S.GetWinDB(win.index)
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
    S.meterFadedOut = false
end

local function CancelFlightFade()
    if S.flightFadeTimer then
        E:CancelTimer(S.flightFadeTimer)
        S.flightFadeTimer = nil
    end
end

function TUI:UpdateMeterVisibility()
    local db = TUI.db.profile.damageMeter
    local petBattle = db.hideInPetBattle and C_PetBattles and C_PetBattles.IsInBattle()
    local inFlight = not petBattle and db.hideInFlight and IsFlying()
    local shouldHide = petBattle or inFlight

    if shouldHide == S.meterHidden then return end
    S.meterHidden = shouldHide
    CancelFlightFade()

    if shouldHide then
        if inFlight then
            local smooth, delay = GetPlayerFaderSettings()
            if smooth and smooth > 0 then
                if delay and delay > 0 then
                    S.flightFadeTimer = E:ScheduleTimer(FadeMeterOut, delay, smooth)
                else
                    FadeMeterOut(smooth)
                end
                return
            end
        end
        -- Instant hide (pet battle or no fader settings)
        for _, win in pairs(S.windows) do
            if win.embedded then
                if win.frame then win.frame:Hide() end
                if win.header then win.header:Hide() end
                if win.headerBorder then win.headerBorder:Hide() end
            elseif win.window then
                win.window:Hide()
            end
        end
    else
        if S.meterFadedOut then
            local smooth = GetPlayerFaderSettings()
            FadeMeterIn((smooth and smooth > 0) and smooth or 0)
            return
        end
        -- Instant show
        for _, win in pairs(S.windows) do
            if win.embedded then
                if win.frame then win.frame:Show() end
                if win.header then win.header:Show() end
                if win.headerBorder then win.headerBorder:Show() end
            elseif win.window then
                win.window:Show()
            end
            local wdb = S.GetWinDB(win.index)
            if wdb and wdb.headerMouseover then
                if win.header then win.header:SetAlpha(0) end
                if win.headerBorder then win.headerBorder:SetAlpha(0) end
            end
        end
    end
end

function TUI:UpdateFlightTicker()
    local db = TUI.db.profile.damageMeter
    if db.hideInFlight and not S.flightTicker then
        S.flightTicker = C_Timer.NewTicker(0.25, function() TUI:UpdateMeterVisibility() end)
    elseif not db.hideInFlight and S.flightTicker then
        S.flightTicker:Cancel()
        S.flightTicker = nil
        TUI:UpdateMeterVisibility()
    end
end

local function UpdateTimers()
    for _, win in pairs(S.windows) do
        if not win.header or not win.header.timer then break end
        if win.sessionType then
            local dur = C_DamageMeter.GetSessionDurationSeconds(win.sessionType)
            if dur then
                win.header.timer:SetText(format('%d:%02d', floor(dur / 60), floor(dur % 60)))
            end
        end
    end
end

function TUI:ResizeMeterWindow(index)
    S.ResizeStandalone(S.windows[index])
end

function TUI:CreateExtraWindow(index)
    if S.windows[index] then return end
    local db = TUI.db.profile.damageMeter
    local ewdb = db.extraWindows[index] or {}
    local win = S.NewWindowState(index, ewdb.modeIndex)
    S.windows[index] = win
    S.CreateMeterFrame(win, false)
    S.RefreshWindow(win)
end

function TUI:DestroyExtraWindow(index)
    local win = S.windows[index]
    if not win then return end
    local winName = "TrenchyUIMeter" .. index
    if win.window then
        E:DisableMover(winName)
        win.window:Hide()
    end
    S.windows[index] = nil
end

function TUI:UpdateMeterLayout()
    if not next(S.windows) then return end

    for _, win in pairs(S.windows) do
        local db       = S.GetWinDB(win.index)
        local fontPath = LSM:Fetch("font", db.barFont)
        local flags    = S.FontFlags(db.barFontOutline)

        local fgTex = (db.barTexture and db.barTexture ~= '') and LSM:Fetch("statusbar", db.barTexture) or E.media.normTex
        local bgTex = (db.barBGTexture and db.barBGTexture ~= '') and LSM:Fetch("statusbar", db.barBGTexture) or E.media.normTex

        S.ApplyHeaderStyle(win, db)
        S.RespaceBarAnchors(win, db)
        for i = 1, S.MAX_BARS do
            local bar = win.bars[i]
            if bar then
                S.StyleBarTexts(bar, fontPath, db.barFontSize, flags)
                bar.statusbar:SetStatusBarTexture(fgTex)
                bar.background:SetTexture(bgTex)
                S.ApplyBarIconLayout(bar, db)
                S.ApplyBarBorder(bar, db)
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
            S.SetupHeaderMouseover(win)
            if db.headerMouseover then
                win.header:SetAlpha(0)
                if win.headerBorder then win.headerBorder:SetAlpha(0) end
            else
                win.header:SetAlpha(1)
                if win.headerBorder then win.headerBorder:SetAlpha(1) end
            end
        end

        if win.embedded then
            S.ResizeToPanel(win)
        else
            S.ResizeStandalone(win)
        end
    end

    self:RefreshMeter()
end

function TUI:InitDamageMeter()
    if not self.db or not self.db.profile.damageMeter.enabled then return end

    SetCVar('damageMeterEnabled', 0)

    C_Timer.After(0, function()
        local CH = E:GetModule('Chat')
        local db = TUI.db.profile.damageMeter

        local win1 = S.NewWindowState(1, db.modeIndex)
        S.windows[1] = win1
        S.CreateMeterFrame(win1, db.embedded)

        local we = db.windowEnabled
        for i = 2, 4 do
            if we and we[i] then
                local ewdb = db.extraWindows[i] or {}
                local win  = S.NewWindowState(i, ewdb.modeIndex)
                S.windows[i] = win
                S.CreateMeterFrame(win, false)
            end
        end

        if not win1.frame then return end

        local function OnTDMEvent(event)
            if event == 'PET_BATTLE_OPENING_START' or event == 'PET_BATTLE_CLOSE' then
                TUI:UpdateMeterVisibility()
                return
            elseif event == 'PLAYER_REGEN_DISABLED' then
                S.ScanRoster()
                for _, w in pairs(S.windows) do
                    S.ExitDrillDown(w)
                end
                return
            elseif event == 'PLAYER_REGEN_ENABLED' then
                S.ScanRoster()
                TUI:RefreshMeter()
                return
            elseif event == 'GROUP_ROSTER_UPDATE' then
                wipe(S.nameCache)
                wipe(S.specIconCache)
                S.ScanRoster()
                return
            elseif event == 'PLAYER_ENTERING_WORLD' then
                S.ScanRoster()
                for _, w in pairs(S.windows) do
                    S.ResetWindowState(w)
                end
                if TUI.db.profile.damageMeter.autoResetOnComplete then
                    local _, instanceType = IsInInstance()
                    if instanceType == 'party' or instanceType == 'raid' or instanceType == 'scenario' then
                        C_DamageMeter.ResetAllCombatSessions()
                        wipe(S.nameCache)
                        wipe(S.guidByName)
                        wipe(S.specIconCache)
                        wipe(S.sessionLabelCache)
                    end
                end
            elseif event == 'DAMAGE_METER_RESET' then
                wipe(S.sessionLabelCache)
                for _, w in pairs(S.windows) do
                    S.ResetWindowState(w)
                end
                TUI:RefreshMeter()
            else
                wipe(S.sessionLabelCache)
                TUI:RefreshMeter()
            end
        end

        S.ScanRoster()
        TUI:RegisterEvent('DAMAGE_METER_COMBAT_SESSION_UPDATED', OnTDMEvent)
        TUI:RegisterEvent('DAMAGE_METER_CURRENT_SESSION_UPDATED', OnTDMEvent)
        TUI:RegisterEvent('DAMAGE_METER_RESET', OnTDMEvent)
        TUI:RegisterEvent('PLAYER_ENTERING_WORLD', OnTDMEvent)
        TUI:RegisterEvent('PLAYER_REGEN_DISABLED', OnTDMEvent)
        TUI:RegisterEvent('PLAYER_REGEN_ENABLED', OnTDMEvent)
        TUI:RegisterEvent('GROUP_ROSTER_UPDATE', OnTDMEvent)
        TUI:RegisterEvent('PET_BATTLE_OPENING_START', OnTDMEvent)
        TUI:RegisterEvent('PET_BATTLE_CLOSE', OnTDMEvent)
        C_Timer.NewTicker(0.5, UpdateTimers)

        TUI:UpdateFlightTicker()

        hooksecurefunc(CH, "PositionChats", function()
            if db.embedded then
                S.ResizeToPanel(win1)
                if CH.RightChatWindow then CH.RightChatWindow:Hide() end
            end
        end)

        TUI:RefreshMeter()
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
