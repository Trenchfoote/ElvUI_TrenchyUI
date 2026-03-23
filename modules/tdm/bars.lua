local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local S = TUI._tdm
if not S then return end

local floor = math.floor

function S.CreateBar(parent)
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
    bar.statusbar.smoothing = Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.ExponentialEaseOut or nil

    bar.classIcon = bar.statusbar:CreateTexture(nil, "OVERLAY")
    bar.classIcon:SetTexture(S.CLASS_ICONS)
    bar.classIcon:SetSize(16, 16)
    bar.classIcon:SetPoint("LEFT", 1, 0)
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

function S.ApplyBarIconLayout(bar, db)
    local iconSize = max(8, (db.barHeight or 18) - 2)
    bar.classIcon:SetSize(iconSize, iconSize)
    bar.leftText:ClearAllPoints()
    if db.showClassIcon then
        bar.leftText:SetPoint("LEFT", bar.classIcon, "RIGHT", 2, 0)
    else
        bar.leftText:SetPoint("LEFT", 4, 0)
    end
    bar.leftText:SetPoint("RIGHT", bar.rightText, "LEFT", -4, 0)
end

function S.ApplyBarBorder(bar, db)
    if db.barBorderEnabled then
        bar.borderFrame:SetTemplate()
        bar.borderFrame:SetBackdropColor(0, 0, 0, 0)
    else
        bar.borderFrame:SetBackdrop(nil)
    end
end

function S.ComputeNumVisible(win)
    local db    = S.GetWinDB(win.index)
    local barHt = max(1, db.barHeight or 18)
    local availH

    if win.embedded then
        local panel    = _G.RightChatPanel
        local tabPanel = _G.RightChatTab
        if not panel or not tabPanel then return 1 end
        local tabH = tabPanel:GetHeight()
        availH = panel:GetHeight() - (tabH + S.PANEL_INSET * 2) - S.PANEL_INSET
    else
        if not win.window then return 1 end
        availH = win.window:GetHeight() - S.HEADER_HEIGHT
    end

    if not availH or availH < 1 then return 1 end
    local spacing = max(0, db.barSpacing or 1)
    return max(1, floor(availH / (barHt + spacing)))
end

function S.ResizeToPanel(win)
    if not win or not win.frame or not win.embedded then return end

    local panel    = _G.RightChatPanel
    local tabPanel = _G.RightChatTab
    if not panel or not tabPanel then return end

    local tabH      = tabPanel:GetHeight()
    local topOffset = tabH + S.PANEL_INSET * 2

    win.frame:ClearAllPoints()
    win.frame:SetPoint("TOPLEFT",     panel, "TOPLEFT",     S.PANEL_INSET,  -topOffset)
    win.frame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -S.PANEL_INSET,  S.PANEL_INSET)

    local db    = S.GetWinDB(win.index)
    local barHt = max(1, db.barHeight or 18)
    for i = 1, S.MAX_BARS do
        if win.bars[i] then win.bars[i].frame:SetHeight(barHt) end
    end
end

function S.ResizeStandalone(win)
    if not win or not win.window or not win.frame then return end

    local db = S.GetWinDB(win.index)
    local w, h = db.standaloneWidth, db.standaloneHeight
    win.window:SetSize(w, h)

    if win.window.mover then
        win.window.mover:SetSize(w, h)
    end

    local barHt = max(1, db.barHeight or 18)
    for i = 1, S.MAX_BARS do
        if win.bars[i] then win.bars[i].frame:SetHeight(barHt) end
    end
end

function S.EnterDrillDown(win, guid, name, classFilename)
    win.drillSource = { guid = guid, name = name, class = classFilename }
    win.scrollOffset = 0
    S.RefreshWindow(win)
end

function S.ExitDrillDown(win)
    if not win.drillSource then return end
    win.drillSource = nil
    win.scrollOffset = 0
    S.RefreshWindow(win)
end

function S.GetDrillSpellCount(win)
    local ds = win.drillSource
    if not ds then return 0 end

    if S.testMode then
        local tdata = S.GetTestData(win)
        for _, td in ipairs(tdata) do
            if td.name == ds.name then return td.spells and #td.spells or 0 end
        end
        return 0
    end

    local meterType  = S.ResolveMeterType(S.MODE_ORDER[win.modeIndex])
    local sourceData = ds.guid and S.GetSessionSource(win, meterType, ds.guid)
    return (sourceData and sourceData.combatSpells) and #sourceData.combatSpells or 0
end

function S.SetupBarInteraction(bar, win)
    bar.frame:SetScript("OnEnter", function(self)
        if win.drillSource then
            if self.drillSpellID then
                GameTooltip_SetDefaultAnchor(GameTooltip, self)
                GameTooltip:SetSpellByID(self.drillSpellID)
                GameTooltip:Show()
            end
            return
        end

        local unitShown = false
        local guid = self.sourceGUID
        if guid then
            local unit = S.FindUnitByGUID(guid)
            if unit then
                GameTooltip:SetOwner(self, "ANCHOR_NONE")
                GameTooltip_SetDefaultAnchor(GameTooltip, self)
                GameTooltip:SetUnit(unit)
                unitShown = true
            end
        end
        if not unitShown then
            GameTooltip_SetDefaultAnchor(GameTooltip, self)
            if self.sourceName then
                local cls = self.sourceClass
                if not cls and self.testIndex then
                    local td = S.GetTestData(win)[self.testIndex]
                    if td then cls = td.class end
                end
                local cr, cg, cb = 1, 1, 1
                if cls then
                    local r, g, b = TUI:GetClassColor(cls)
                    if r then cr, cg, cb = r, g, b end
                end
                GameTooltip:AddLine(self.sourceName, cr, cg, cb)
            end
        end
        GameTooltip:AddLine("Click for spell breakdown", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)

    bar.frame:SetScript("OnLeave", GameTooltip_Hide)

    bar.frame:SetScript("OnMouseUp", function(self, button)
        if win.drillSource then
            if button == "RightButton" then
                S.ExitDrillDown(win)
            end
            return
        end

        if button == "LeftButton" then
            GameTooltip:Hide()
            if S.testMode and self.testIndex then
                local td = S.GetTestData(win)[self.testIndex]
                if td then
                    S.EnterDrillDown(win, nil, td.name, td.class)
                end
                return
            end
            if self.sourceGUID and self.sourceName then
                S.EnterDrillDown(win, self.sourceGUID, self.sourceName, self.sourceClass)
            end
        end
    end)
end

function S.ApplySessionHighlight(win, db)
    if win.sessionId then
        win.header.sessText:SetTextColor(1, 0.3, 0.3)
    else
        win.header.sessText:SetTextColor(db.headerFontColor.r, db.headerFontColor.g, db.headerFontColor.b)
    end
end

function S.ResetDrillBar(bar, db)
    bar._isDrill = nil
    bar._drillHasIcon = nil
    bar.pctText:Hide()
    bar.rightText:ClearAllPoints()
    bar.rightText:SetPoint("RIGHT", -4, 0)
    bar.classIcon:SetTexture(S.CLASS_ICONS)
    S.ApplyBarIconLayout(bar, db)
end

function S.ResetWindowState(win)
    win.scrollOffset = 0
    win.drillSource  = nil
    win.sessionId    = nil
    win.sessionType  = Enum.DamageMeterSessionType.Current
end
