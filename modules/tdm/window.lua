local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local TDM = E:GetModule('TUI_TDM')

local LSM = E.Libs.LSM
local Skins = E:GetModule('Skins')
local floor = math.floor

local function OpenMenuAnchored(menuItems, header)
	E:ComplicatedMenu(menuItems, E.EasyMenu, nil, nil, nil, "MENU")
	local mgr = Menu and Menu.GetManager and Menu.GetManager()
	local openMenu = mgr and mgr:GetOpenMenu()
	if openMenu then
		openMenu:ClearAllPoints()
		openMenu:SetPoint("BOTTOMLEFT", header, "TOPLEFT", -1, -3)
	end
end

function TDM.SetupScrollWheel(win)
    win.frame:EnableMouseWheel(true)
    win.frame:SetScript("OnMouseWheel", function(_, delta)
        local total
        if win.drillSource then
            total = TDM.GetDrillSpellCount(win)
        elseif TDM.testMode then
            total = #TDM.GetTestData(win)
        else
            local meterType = TDM.ResolveMeterType(TDM.MODE_ORDER[win.modeIndex])
            local session   = TDM.GetSession(win, meterType)
            total = (session and session.combatSources and #session.combatSources) or 0
        end
        local numVis = TDM.ComputeNumVisible(win)
        local maxOff = max(0, total - numVis)
        win.scrollOffset = max(0, min(maxOff, win.scrollOffset - delta))
        TDM.RefreshWindow(win)
    end)
end

function TDM.FadeHeaderIn(win)
    local db = TDM.GetWinDB(win.index)
    if not db.headerMouseover then return end
    if win.header then E:UIFrameFadeIn(win.header, 0.2, win.header:GetAlpha(), 1) end
    if win.headerBorder then E:UIFrameFadeIn(win.headerBorder, 0.2, win.headerBorder:GetAlpha(), 1) end
end

function TDM.FadeHeaderOut(win)
    local db = TDM.GetWinDB(win.index)
    if not db.headerMouseover then return end
    if win.header then E:UIFrameFadeOut(win.header, 0.2, win.header:GetAlpha(), 0) end
    if win.headerBorder then E:UIFrameFadeOut(win.headerBorder, 0.2, win.headerBorder:GetAlpha(), 0) end
end

function TDM.SetupHeaderMouseover(win)
    if win._headerMouseoverHooked then return end
    win._headerMouseoverHooked = true

    local function OnEnter() TDM.FadeHeaderIn(win) end
    local function OnLeave() TDM.FadeHeaderOut(win) end

    if win.header then
        win.header:HookScript("OnEnter", OnEnter)
        win.header:HookScript("OnLeave", OnLeave)
        for _, child in pairs({ win.header.modeArea, win.header.sessArea, win.header.reset }) do
            if child then
                child:HookScript("OnEnter", OnEnter)
                child:HookScript("OnLeave", OnLeave)
            end
        end
    end
end

function TDM.ApplyHeaderStyle(win, db)
    local header = win.header
    if not header then return end

    local fontPath = LSM:Fetch("font", db.headerFont)
    local flags    = TDM.FontFlags(db.headerFontOutline)

    local hc = db.headerBGColor
    if db.showHeaderBackdrop then
        header.bg:SetVertexColor(hc.r, hc.g, hc.b, hc.a)
    else
        header.bg:SetVertexColor(0, 0, 0, 0)
    end

    local tc = db.headerFontColor
    header.modeText:FontTemplate(fontPath, db.headerFontSize + 1, flags)
    header.modeText:SetTextColor(tc.r, tc.g, tc.b)

    header.sessText:FontTemplate(fontPath, db.headerFontSize + 1, flags)
    header.sessText:SetTextColor(tc.r, tc.g, tc.b)

    header.timer:FontTemplate(fontPath, db.headerFontSize, flags)
    header.timer:SetTextColor(tc.r, tc.g, tc.b, 0.7)
    header.timer:ClearAllPoints()
    if db.showTimer then
        header.timer:SetPoint("RIGHT", header.reset, "LEFT", -4, 0)
        header.timer:Show()
    else
        header.timer:SetText('')
        header.timer:Hide()
    end
end

function TDM.MakeModeEntry(win, mtype)
    local idx
    for i, mt in ipairs(TDM.MODE_ORDER) do
        if mt == mtype then idx = i; break end
    end
    if not idx then return nil end

    local label = TDM.MODE_LABELS[mtype] or "?"
    return {
        text         = (idx == win.modeIndex) and ("|cffffd100" .. label .. "|r") or label,
        notCheckable = true,
        func         = function()
            win.modeIndex  = idx
            win.drillSource = nil
            win.scrollOffset = 0
            local db = TUI.db.profile.damageMeter
            if win.index == 1 then
                db.modeIndex = idx
            else
                db.extraWindows[win.index] = db.extraWindows[win.index] or {}
                db.extraWindows[win.index].modeIndex = idx
            end
            TDM.RefreshWindow(win)
        end,
    }
end

function TDM.BuildModeMenu(win)
    local dmg = {
        TDM.MakeModeEntry(win, Enum.DamageMeterType.DamageDone),
        TDM.MakeModeEntry(win, Enum.DamageMeterType.Dps),
        TDM.MakeModeEntry(win, TDM.COMBINED_DAMAGE),
        TDM.MakeModeEntry(win, Enum.DamageMeterType.DamageTaken),
        TDM.MakeModeEntry(win, Enum.DamageMeterType.AvoidableDamageTaken),
    }
    if Enum.DamageMeterType.EnemyDamageTaken then
        dmg[#dmg + 1] = TDM.MakeModeEntry(win, Enum.DamageMeterType.EnemyDamageTaken)
    end

    local heal = {
        TDM.MakeModeEntry(win, Enum.DamageMeterType.HealingDone),
        TDM.MakeModeEntry(win, Enum.DamageMeterType.Hps),
        TDM.MakeModeEntry(win, TDM.COMBINED_HEALING),
        TDM.MakeModeEntry(win, Enum.DamageMeterType.Absorbs),
    }

    local actions = {
        TDM.MakeModeEntry(win, Enum.DamageMeterType.Interrupts),
        TDM.MakeModeEntry(win, Enum.DamageMeterType.Dispels),
    }
    if Enum.DamageMeterType.Deaths then
        actions[#actions + 1] = TDM.MakeModeEntry(win, Enum.DamageMeterType.Deaths)
    end

    return {
        { text = "Damage",  notCheckable = true, hasArrow = true, menuList = dmg },
        { text = "Healing", notCheckable = true, hasArrow = true, menuList = heal },
        { text = "Actions", notCheckable = true, hasArrow = true, menuList = actions },
    }
end

function TDM.BuildSessionMenu(win)
    local menu = {}

    -- Encounter sessions first (oldest at top, newest at bottom)
    if C_DamageMeter.GetAvailableCombatSessions then
        local sessions = C_DamageMeter.GetAvailableCombatSessions()
        if sessions and #sessions > 0 then
            for _, sess in ipairs(sessions) do
                local sid = sess.sessionId or sess.combatSessionId or sess.id or sess.sessionID
                local label = sess.name or 'Encounter'
                local dur = sess.durationSeconds or sess.duration
                if dur and E:NotSecretValue(dur) then
                    label = label .. format(' [%d:%02d]', floor(dur / 60), floor(dur % 60))
                end
                menu[#menu + 1] = {
                    text = (win.sessionId == sid) and ("|cffffd100" .. label .. "|r") or label,
                    notCheckable = true,
                    func = function()
                        win.sessionId    = sid
                        win.sessionType  = nil
                        win.scrollOffset = 0
                        win.drillSource  = nil
                        TDM.RefreshWindow(win)
                    end,
                }
            end
            menu[#menu + 1] = { text = "", notCheckable = true, disabled = true }
        end
    end

    -- Current / Overall at the bottom
    menu[#menu + 1] = {
        text = (win.sessionId == nil and win.sessionType == Enum.DamageMeterSessionType.Current)
            and "|cffffd100Current Segment|r" or "Current Segment",
        notCheckable = true,
        func = function()
            win.sessionId    = nil
            win.sessionType  = Enum.DamageMeterSessionType.Current
            win.scrollOffset = 0
            win.drillSource  = nil
            TDM.RefreshWindow(win)
        end,
    }

    menu[#menu + 1] = {
        text = (win.sessionId == nil and win.sessionType == Enum.DamageMeterSessionType.Overall)
            and "|cffffd100Overall|r" or "Overall",
        notCheckable = true,
        func = function()
            win.sessionId    = nil
            win.sessionType  = Enum.DamageMeterSessionType.Overall
            win.scrollOffset = 0
            win.drillSource  = nil
            TDM.RefreshWindow(win)
        end,
    }

    return menu
end

function TDM.ToggleSession(win)
    win.sessionId = nil
    if win.sessionType == Enum.DamageMeterSessionType.Current then
        win.sessionType = Enum.DamageMeterSessionType.Overall
    else
        win.sessionType = Enum.DamageMeterSessionType.Current
    end
    win.scrollOffset = 0
    win.drillSource  = nil
    TDM.RefreshWindow(win)
end

function TDM.SetupHeaderContent(win, db)
    local header = win.header

    header.bg = header:CreateTexture(nil, "BACKGROUND")
    header.bg:SetAllPoints()
    header.bg:SetTexture(E.media.normTex)

    header.modeText = header:CreateFontString(nil, "OVERLAY")
    header.modeText:SetPoint("LEFT", 4, 0)
    header.modeText:SetShadowOffset(1, -1)

    header.sessText = header:CreateFontString(nil, "OVERLAY")
    header.sessText:SetPoint("LEFT", header.modeText, "RIGHT", 0, 0)
    header.sessText:SetShadowOffset(1, -1)

    header.reset = CreateFrame("Button", nil, header)
    header.reset:SetSize(16, 16)
    header.reset:SetPoint("RIGHT", -4, 0)
    Skins:HandleCloseButton(header.reset)
    header.reset:SetHitRectInsets(0, 0, 0, 0)
    header.reset:SetScript("OnClick", function(_, btn)
        if btn == "LeftButton" then
            E:StaticPopup_Show('TUI_METER_RESET')
        end
    end)
    header.reset:HookScript("OnEnter", function(self)
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        GameTooltip:AddLine("Reset Meter", 1, 0.3, 0.3)
        GameTooltip:AddLine("Clears all session data.", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    header.reset:HookScript("OnLeave", GameTooltip_Hide)

    header.timer = header:CreateFontString(nil, "OVERLAY")
    header.timer:SetShadowOffset(1, -1)

    TDM.ApplyHeaderStyle(win, db)

    -- Mode click area (left portion)
    header.modeArea = CreateFrame("Frame", nil, header)
    header.modeArea:SetPoint("TOPLEFT",     header.modeText, "TOPLEFT",     0, 0)
    header.modeArea:SetPoint("BOTTOMRIGHT", header.modeText, "BOTTOMRIGHT", 0, 0)
    header.modeArea:EnableMouse(true)
    header.modeArea:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            if win.drillSource then
                TDM.ExitDrillDown(win)
            else
                OpenMenuAnchored(TDM.BuildModeMenu(win), header)
            end
        elseif button == "RightButton" then
            TDM.ToggleSession(win)
        end
    end)
    header.modeArea:SetScript("OnEnter", function(self)
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        if win.drillSource then
            GameTooltip:AddLine("|cffffd100Left-click:|r return to overview", 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine("|cffffd100Left-click:|r choose display mode", 0.7, 0.7, 0.7)
        end
        GameTooltip:AddLine("|cffffd100Right-click:|r toggle Current / Overall", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    header.modeArea:SetScript("OnLeave", GameTooltip_Hide)

    -- Session click area (right portion)
    header.sessArea = CreateFrame("Frame", nil, header)
    header.sessArea:SetPoint("TOPLEFT",     header.sessText, "TOPLEFT",     0, 0)
    header.sessArea:SetPoint("BOTTOMRIGHT", header.sessText, "BOTTOMRIGHT", 0, 0)
    header.sessArea:EnableMouse(true)
    header.sessArea:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            OpenMenuAnchored(TDM.BuildSessionMenu(win), header)
        elseif button == "RightButton" then
            TDM.ToggleSession(win)
        end
    end)
    header.sessArea:SetScript("OnEnter", function(self)
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        GameTooltip:AddLine("|cffffd100Left-click:|r choose encounter", 0.7, 0.7, 0.7)
        GameTooltip:AddLine("|cffffd100Right-click:|r toggle Current / Overall", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    header.sessArea:SetScript("OnLeave", GameTooltip_Hide)
end

function TDM.SetupWindowContent(win, db, parent)
    local i       = win.index
    local winName = i == 1 and "TrenchyUIMeter" or ("TrenchyUIMeter" .. i)
    local hdrName = i == 1 and "TrenchyUIMeterHeader" or ("TrenchyUIMeterHeader" .. i)

    -- Determine header anchor: embedded uses RightChatTab, standalone uses win.window
    local headerAnchor = win.embedded and _G.RightChatTab or win.window

    -- Header border (border-only, no fill)
    local headerBorder = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    headerBorder:SetPoint("TOPLEFT",  headerAnchor, "TOPLEFT",  0, 0)
    headerBorder:SetPoint("TOPRIGHT", headerAnchor, "TOPRIGHT", 0, 0)
    if win.embedded then
        headerBorder:SetPoint("BOTTOMRIGHT", headerAnchor, "BOTTOMRIGHT")
    else
        headerBorder:SetHeight(TDM.HEADER_HEIGHT + 1)
    end
    win.headerBorder = headerBorder

    -- Header
    win.header = CreateFrame("Frame", hdrName, parent)
    win.header:SetPoint("TOPLEFT",  headerAnchor, "TOPLEFT",  0, 0)
    win.header:SetPoint("TOPRIGHT", headerAnchor, "TOPRIGHT", 0, 0)
    if win.embedded then
        win.header:SetPoint("BOTTOMRIGHT", headerAnchor, "BOTTOMRIGHT")
    else
        win.header:SetHeight(TDM.HEADER_HEIGHT)
    end
    win.header:SetFrameLevel(headerAnchor:GetFrameLevel() + 1)

    -- Header border sits above the header so it renders over the backdrop
    headerBorder:SetFrameLevel(win.header:GetFrameLevel() + 1)
    if db.showHeaderBorder then
        headerBorder:SetTemplate()
        headerBorder:SetBackdropColor(0, 0, 0, 0)
    end
    win.header:EnableMouse(true)

    TDM.SetupHeaderContent(win, db)

    -- Bar area frame
    local frameName = win.embedded and winName or nil
    win.frame = CreateFrame("Frame", frameName, parent, "BackdropTemplate")
    win.frame:SetFrameStrata("MEDIUM")
    win.frame:SetClipsChildren(true)
    if not win.embedded then
        win.frame:SetPoint("TOPLEFT",     win.window, "TOPLEFT",     0, -TDM.HEADER_HEIGHT)
        win.frame:SetPoint("BOTTOMRIGHT", win.window, "BOTTOMRIGHT", 0,  0)
    end

    -- Backdrop
    if db.showBackdrop then
        win.frame:SetTemplate('Transparent')
        local bc = db.backdropColor
        if bc then win.frame:SetBackdropColor(bc.r, bc.g, bc.b, bc.a) end
    end

    -- Header backdrop
    if not db.showHeaderBackdrop and win.header.bg then
        win.header.bg:Hide()
    end

    -- Bars
    local fontPath = LSM:Fetch("font", db.barFont)
    local flags    = TDM.FontFlags(db.barFontOutline)

    for j = 1, TDM.MAX_BARS do
        local bar = TDM.CreateBar(win.frame)
        TDM.StyleBarTexts(bar, fontPath, db.barFontSize, flags)
        TDM.ApplyBarIconLayout(bar, db)
        TDM.ApplyBarBorder(bar, db)

        local sp = max(0, db.barSpacing or 1)
        local borderAdj = (db.barBorderEnabled and sp == 0) and 1 or 0
        if j == 1 then
            bar.frame:SetPoint("TOPLEFT",  win.frame, "TOPLEFT",  0, 0)
            bar.frame:SetPoint("TOPRIGHT", win.frame, "TOPRIGHT", 0, 0)
        else
            bar.frame:SetPoint("TOPLEFT",  win.bars[j-1].frame, "BOTTOMLEFT",  0, -sp + borderAdj)
            bar.frame:SetPoint("TOPRIGHT", win.bars[j-1].frame, "BOTTOMRIGHT", 0, -sp + borderAdj)
        end
        win.bars[j] = bar
        TDM.SetupBarInteraction(bar, win)
    end

    TDM.SetupScrollWheel(win)

    -- Header mouseover: set up hooks and apply initial alpha
    TDM.SetupHeaderMouseover(win)
    if db.headerMouseover then
        win.header:SetAlpha(0)
        if win.headerBorder then win.headerBorder:SetAlpha(0) end
    end
end

function TDM.CreateMeterFrame(win, isEmbedded)
    local CH = E:GetModule('Chat')
    local db = TDM.GetWinDB(win.index)
    win.embedded = isEmbedded

    if isEmbedded then
        local panel = _G.RightChatPanel
        if not panel or not _G.RightChatTab then return end

        TDM.SetupWindowContent(win, db, panel)
        TDM.ResizeToPanel(win)

        if CH.RightChatWindow then CH.RightChatWindow:Hide() end
    else
        local i       = win.index
        local winName = i == 1 and "TrenchyUIMeter" or ("TrenchyUIMeter" .. i)

        local w, h = db.standaloneWidth, db.standaloneHeight

        local window = CreateFrame("Frame", winName, UIParent, "BackdropTemplate")
        window:SetSize(w, h)
        if i == 1 then
            window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        elseif i == 2 then
            window:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -2, 189)
        elseif i == 3 then
            window:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -416, 2)
        elseif i == 4 then
            window:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -416, 189)
        end
        window:SetMovable(true)
        window:SetClampedToScreen(true)
        window:SetFrameStrata('BACKGROUND')
        window:SetFrameLevel(300)
        win.window = window

        TDM.SetupWindowContent(win, db, window)
        TDM.ResizeStandalone(win)

        local moverLabel = i == 1 and "TDM" or ("TDM " .. i)
        local function TDMDisabled() return not (TUI.db and TUI.db.profile and TUI.db.profile.damageMeter and TUI.db.profile.damageMeter.enabled) end
        E:CreateMover(window, winName, moverLabel, nil, nil, nil, 'ALL,TRENCHYUI', TDMDisabled, 'TrenchyUI,damageMeter,window' .. i)

    end
end

function TDM.RespaceBarAnchors(win, db)
    local sp = max(0, db.barSpacing or 1)
    local borderAdj = (db.barBorderEnabled and sp == 0) and 1 or 0
    for i = 1, TDM.MAX_BARS do
        local bar = win.bars[i]
        if not bar then break end
        bar.frame:ClearAllPoints()
        if i == 1 then
            bar.frame:SetPoint("TOPLEFT",  win.frame, "TOPLEFT",  0, 0)
            bar.frame:SetPoint("TOPRIGHT", win.frame, "TOPRIGHT", 0, 0)
        else
            bar.frame:SetPoint("TOPLEFT",  win.bars[i-1].frame, "BOTTOMLEFT",  0, -sp + borderAdj)
            bar.frame:SetPoint("TOPRIGHT", win.bars[i-1].frame, "BOTTOMRIGHT", 0, -sp + borderAdj)
        end
    end
end
