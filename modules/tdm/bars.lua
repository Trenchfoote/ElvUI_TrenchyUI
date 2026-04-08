local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local TDM = E:GetModule('TUI_TDM')

local floor = math.floor

function TDM.CreateBar(parent)
    local bar = {}

    bar.frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")

    bar.background = bar.frame:CreateTexture(nil, "BACKGROUND")
    bar.background:SetAllPoints()
    bar.background:SetTexture(E.media.normTex)
    bar.background:SetVertexColor(0.15, 0.15, 0.15, 0.35)

    bar.statusbar = CreateFrame("StatusBar", nil, bar.frame)
    bar.statusbar:SetAllPoints()
    bar.statusbar:SetStatusBarTexture(E.media.normTex)
    bar.statusbar:SetMinMaxValues(0, 1)
    bar.statusbar:SetValue(0)

    bar.classIconBG = bar.statusbar:CreateTexture(nil, "ARTWORK")
    bar.classIconBG:SetTexture(E.media.blankTex)
    bar.classIconBG:SetVertexColor(0, 0, 0, 0.5)
    bar.classIconBG:SetSize(16, 16)
    bar.classIconBG:SetPoint("LEFT", 1, 0)
    bar.classIconBG:Hide()

    bar.classIcon = bar.statusbar:CreateTexture(nil, "OVERLAY")
    bar.classIcon:SetTexture(TDM.CLASS_ICONS)
    bar.classIcon:SetSize(16, 16)
    bar.classIcon:SetPoint("CENTER", bar.classIconBG, "CENTER", 0, 0)
    bar.classIcon:Hide()

    bar.pctText = bar.statusbar:CreateFontString(nil, "OVERLAY")
    bar.pctText:SetPoint("RIGHT", -4, 0)
    bar.pctText:SetJustifyH("RIGHT")
    bar.pctText:SetWordWrap(false)
    bar.pctText:SetShadowOffset(1, -1)
    bar.pctText:Hide()

    bar.rightText = bar.statusbar:CreateFontString(nil, "OVERLAY")
    bar.rightText:SetPoint("RIGHT", -4, 0)
    bar.rightText:SetJustifyH("RIGHT")
    bar.rightText:SetWordWrap(false)
    bar.rightText:SetShadowOffset(1, -1)

    bar.leftText = bar.statusbar:CreateFontString(nil, "OVERLAY")
    bar.leftText:SetPoint("LEFT", 4, 0)
    bar.leftText:SetPoint("RIGHT", bar.rightText, "LEFT", -4, 0)
    bar.leftText:SetJustifyH("LEFT")
    bar.leftText:SetWordWrap(false)
    bar.leftText:SetShadowOffset(1, -1)

    bar.borderFrame = CreateFrame("Frame", nil, bar.frame, "BackdropTemplate")
    bar.borderFrame:SetAllPoints()
    bar.borderFrame:SetFrameLevel(bar.statusbar:GetFrameLevel() + 2)

    bar.textFrame = CreateFrame("Frame", nil, bar.frame)
    bar.textFrame:SetAllPoints()
    bar.textFrame:SetFrameLevel(bar.borderFrame:GetFrameLevel() + 1)

    bar.leftText:SetParent(bar.textFrame)
    bar.rightText:SetParent(bar.textFrame)
    bar.pctText:SetParent(bar.textFrame)

    bar.frame:EnableMouse(true)
    bar.frame:Hide()
    return bar
end

function TDM.ApplyBarIconLayout(bar, db)
    local iconSize = max(8, (db.barHeight or 18) - 2)
    bar.classIcon:SetSize(iconSize, iconSize)
    bar.classIconBG:SetSize(iconSize, iconSize)
    local showBG = db.showClassIcon and TUI.db.profile.colorMode == 'color'
    if showBG then bar.classIconBG:Show() else bar.classIconBG:Hide() end
    bar.leftText:ClearAllPoints()
    if db.showClassIcon then
        bar.leftText:SetPoint("LEFT", bar.classIconBG, "RIGHT", 2, 0)
    else
        bar.leftText:SetPoint("LEFT", 4, 0)
    end
    bar.leftText:SetPoint("RIGHT", bar.rightText, "LEFT", -4, 0)
end

function TDM.ApplyBarBorder(bar, db)
    if db.barBorderEnabled then
        bar.borderFrame:SetTemplate()
        bar.borderFrame:SetBackdropColor(0, 0, 0, 0)
    else
        bar.borderFrame:SetBackdrop(nil)
    end
end

function TDM.ComputeNumVisible(win)
    local db    = TDM.GetWinDB(win.index)
    local barHt = max(1, db.barHeight or 18)
    local availH

    if win.embedded then
        local panel    = _G.RightChatPanel
        local tabPanel = _G.RightChatTab
        if not panel or not tabPanel then return 1 end
        local tabH = tabPanel:GetHeight()
        availH = panel:GetHeight() - (tabH + TDM.PANEL_INSET * 2) - TDM.PANEL_INSET
    else
        if not win.window then return 1 end
        availH = win.window:GetHeight() - TDM.HEADER_HEIGHT
    end

    if not availH or availH < 1 then return 1 end
    local spacing = max(0, db.barSpacing or 1)
    return max(1, floor(availH / (barHt + spacing)))
end

function TDM.ResizeToPanel(win)
    if not win or not win.frame or not win.embedded then return end

    local panel    = _G.RightChatPanel
    local tabPanel = _G.RightChatTab
    if not panel or not tabPanel then return end

    local tabH      = tabPanel:GetHeight()
    local topOffset = tabH + TDM.PANEL_INSET * 2

    win.frame:ClearAllPoints()
    win.frame:SetPoint("TOPLEFT",     panel, "TOPLEFT",     TDM.PANEL_INSET,  -topOffset)
    win.frame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -TDM.PANEL_INSET,  TDM.PANEL_INSET)

    local db    = TDM.GetWinDB(win.index)
    local barHt = max(1, db.barHeight or 18)
    for i = 1, TDM.MAX_BARS do
        if win.bars[i] then win.bars[i].frame:SetHeight(barHt) end
    end
end

function TDM.ResizeStandalone(win)
    if not win or not win.window or not win.frame then return end

    local db = TDM.GetWinDB(win.index)
    local w, h = db.standaloneWidth, db.standaloneHeight
    win.window:SetSize(w, h)

    if win.window.mover then
        win.window.mover:SetSize(w, h)
    end

    local barHt = max(1, db.barHeight or 18)
    for i = 1, TDM.MAX_BARS do
        if win.bars[i] then win.bars[i].frame:SetHeight(barHt) end
    end
end

function TDM.EnterDrillDown(win, guid, name, classFilename, sourceIndex, secretGUID, sourceCreatureID, sourceUnit, sourceData, specIconID, deathRecapID)
    local safeName = (name and E:NotSecretValue(name)) and name or nil

    if not guid and sourceUnit then
        local unitGUID = UnitGUID(sourceUnit)
        if unitGUID and E:NotSecretValue(unitGUID) then
            guid = unitGUID
        end
    end

    if not guid and safeName then
        guid = TDM.FindGUIDByName(safeName)
    end

    if sourceIndex then
        local meterType = TDM.ResolveMeterType(TDM.MODE_ORDER[win.modeIndex])
        local session = TDM.GetSession(win, meterType)
        local src = session and session.combatSources and session.combatSources[sourceIndex]
        if src then
            sourceData = sourceData or src
            if not guid and E:NotSecretValue(src.sourceGUID) then
                guid = src.sourceGUID
            end
            if not secretGUID and src.sourceGUID then
                secretGUID = src.sourceGUID
            end
            if not sourceCreatureID and E:NotSecretValue(src.sourceCreatureID) then
                sourceCreatureID = src.sourceCreatureID
            end
            if (not safeName or safeName == '?') and E:NotSecretValue(src.name) and src.name and src.name ~= '' then
                safeName = Ambiguate(src.name, 'short')
            end
            if (not safeName or safeName == '?') and src.sourceGUID then
                local secretName = select(6, GetPlayerInfoByGUID(src.sourceGUID))
                if secretName and E:NotSecretValue(secretName) then
                    safeName = secretName
                end
            end
        end
    end

    -- Resolve GUID via specIconID cache if still secret
    if not guid and specIconID then
        guid = TDM.ResolveGUID(nil, specIconID)
    end

    win.drillSource = {
        guid = guid,
        name = safeName,
        class = classFilename,
        sourceIndex = sourceIndex,
        secretGUID = secretGUID,
        sourceCreatureID = sourceCreatureID,
        sourceData = sourceData,
        specIconID = specIconID,
        deathRecapID = deathRecapID,
    }
    win.scrollOffset = 0
    TDM.RefreshWindow(win)
end

function TDM.ExitDrillDown(win)
    if not win.drillSource then return end
    win.drillSource = nil
    win.scrollOffset = 0
    TDM.RefreshWindow(win)
end

function TDM.GetDrillSpellCount(win)
    local ds = win.drillSource
    if not ds then return 0 end

    if ds.deathRecapID then
        local events = C_DeathRecap and C_DeathRecap.GetRecapEvents(ds.deathRecapID)
        return events and #events or 0
    end

    if TDM.testMode then
        local tdata = TDM.GetTestData(win)
        for _, td in ipairs(tdata) do
            if td.name == ds.name then return td.spells and #td.spells or 0 end
        end
        return 0
    end

    local meterType = TDM.ResolveMeterType(TDM.MODE_ORDER[win.modeIndex])
    local lookupGUID = ds.guid or TDM.ResolveGUID(ds.secretGUID, ds.specIconID)
    local sourceData
    if lookupGUID or ds.sourceCreatureID then
        sourceData = TDM.GetSessionSource(win, meterType, lookupGUID, ds.sourceCreatureID)
    end
    return (sourceData and sourceData.combatSpells) and #sourceData.combatSpells or 0
end

function TDM.SetupBarInteraction(bar, win)
    bar.frame:SetScript("OnEnter", function(self)
        if win.drillSource then
            if self.drillSpellID then
                GameTooltip_SetDefaultAnchor(GameTooltip, self)
                GameTooltip:SetSpellByID(self.drillSpellID)
                GameTooltip:Show()
            end
            return
        end

        -- Try full unit tooltip: cached unit > GUID lookup > name lookup > secret GUID match
        local unit = self.sourceUnit
        if not unit and self.sourceGUID then
            unit = TDM.FindUnitByGUID(self.sourceGUID)
        end
        if not unit and self.sourceName and not E:IsSecretValue(self.sourceName) and self.sourceName ~= '?' then
            unit = TDM.FindUnitByName(self.sourceName)
        end
        if not unit and self.sourceGUID then
            for i = 1, 4 do
                local token = 'party' .. i
                if UnitGUID(token) == self.sourceGUID then unit = token; break end
            end
        end

        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        if unit then
            GameTooltip:SetUnit(unit)
        else
            local name = self.sourceName
            if (not name or (not E:IsSecretValue(name) and name == '?')) and self.secretName then name = self.secretName end
            if name and not E:IsSecretValue(name) then
                local cls = self.sourceClass or (self.testIndex and TDM.GetTestData(win)[self.testIndex] and TDM.GetTestData(win)[self.testIndex].class)
                local cr, cg, cb = 1, 1, 1
                if cls then
                    local r, g, b = TUI:GetClassColor(cls)
                    if r then cr, cg, cb = r, g, b end
                end
                GameTooltip:AddLine(name, cr, cg, cb)
            elseif name then
                GameTooltip:AddDoubleLine(name, '', 1, 1, 1)
            end
        end
        local modeEntry = TDM.MODE_ORDER[win.modeIndex]
        if Enum.DamageMeterType.Deaths and modeEntry == Enum.DamageMeterType.Deaths then
            GameTooltip:AddLine("Click for death recap", 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine("Click for spell breakdown", 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end)

    bar.frame:SetScript("OnLeave", GameTooltip_Hide)

    bar.frame:SetScript("OnMouseUp", function(self, button)
        if win.drillSource then
            if button == "RightButton" then
                TDM.ExitDrillDown(win)
            end
            return
        end

        if button == "LeftButton" then
            local db = TDM.GetWinDB(win.index)
            if InCombatLockdown() and db and not db.clickInCombat then return end
            GameTooltip:Hide()
            if TDM.testMode and self.testIndex then
                local td = TDM.GetTestData(win)[self.testIndex]
                if td then
                    TDM.EnterDrillDown(win, nil, td.name, td.class)
                end
                return
            end
            local sourceName = self.sourceName
            if (not sourceName or (not E:IsSecretValue(sourceName) and sourceName == '?')) and self.secretName then
                sourceName = self.secretName
            end
            local deathRecapID
            local modeEntry = TDM.MODE_ORDER[win.modeIndex]
            if Enum.DamageMeterType.Deaths and modeEntry == Enum.DamageMeterType.Deaths then
                local srcData = self.sourceData
                if srcData and srcData.deathRecapID and E:NotSecretValue(srcData.deathRecapID) and srcData.deathRecapID ~= 0 then
                    deathRecapID = srcData.deathRecapID
                end
                if not deathRecapID then return end
            end
            TDM.EnterDrillDown(win, self.sourceGUID, sourceName or '?', self.sourceClass, self.sourceIndex, self.secretGUID, self.sourceCreatureID, self.sourceUnit, self.sourceData, self.specIconID, deathRecapID)
        end
    end)
end

function TDM.ApplySessionHighlight(win, db)
    if win.sessionId then
        win.header.sessText:SetTextColor(1, 0.3, 0.3)
    else
        win.header.sessText:SetTextColor(db.headerFontColor.r, db.headerFontColor.g, db.headerFontColor.b)
    end
end

function TDM.ResetDrillBar(bar, db)
    bar._isDrill = nil
    bar._drillHasIcon = nil
    bar._mainCombined = nil
    bar.pctText:Hide()
    if bar.dpsText then
        bar.dpsText:Hide()
        bar.dpsText:ClearAllPoints()
        bar.dpsText:SetWidth(0)
    end
    bar.rightText:ClearAllPoints()
    bar.rightText:SetWidth(0)
    bar.rightText:SetPoint("RIGHT", -4, 0)
    bar.classIcon:SetTexture(TDM.CLASS_ICONS)
    TDM.ApplyBarIconLayout(bar, db)
end

function TDM.ResetWindowState(win)
    win.scrollOffset = 0
    win.drillSource  = nil
    win.sessionId    = nil
    win.sessionType  = Enum.DamageMeterSessionType.Current
end
