local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local ACH = E.Libs.ACH

function TUI:BuildDamageMeterConfig(root, tuiName)
    if not (C_DamageMeter and Enum.DamageMeterType) then return end
    local TDM = E:GetModule('TUI_TDM', true)
    if not TDM then return end

    root.damageMeter = ACH:Group("TDM", nil, 2, 'tab')

    local DM_SKIP = { enabled = true, modeIndex = true, autoResetOnComplete = true, embedded = true, windowEnabled = true, extraWindows = true }
    local DM_DEFAULTS = {}
    for k, v in pairs(TUI.defaults.profile.damageMeter) do
        if not DM_SKIP[k] then DM_DEFAULTS[k] = v end
    end
    local dmDisabled = function() return not TUI.db.profile.damageMeter.enabled end

    local function isWindowEnabled(i)
        local we = TUI.db.profile.damageMeter.windowEnabled
        return we and we[i]
    end

    local function getWinDB(i)
        local db = TUI.db.profile.damageMeter
        if i == 1 then return db end
        db.extraWindows[i] = db.extraWindows[i] or {}
        return db.extraWindows[i]
    end

    local function winGet(i, key)
        local wdb = getWinDB(i)
        if i == 1 then return wdb[key] end
        local val = wdb[key]
        if val ~= nil then return val end
        return TUI.db.profile.damageMeter[key]
    end

    local function winSet(i, key, value) getWinDB(i)[key] = value end

    local function winGetColor(i, key)
        local c = winGet(i, key)
        return c.r, c.g, c.b, c.a
    end

    local function winSetColor(i, key, r, g, b, a)
        local wdb = getWinDB(i)
        if not wdb[key] then wdb[key] = {} end
        local c = wdb[key]
        c.r, c.g, c.b, c.a = r, g, b, a
    end

    local winUpdate = function() TDM:UpdateMeterLayout() end
    local winRefresh = function() TDM:RefreshMeter() end

    -- General
    root.damageMeter.args.general = ACH:Group("General", nil, 1)
    root.damageMeter.args.general.inline = true
    local gen = root.damageMeter.args.general.args

    gen.desc = ACH:Description(
        "TDM is a lightweight meter using the built-in API. "
        .. "Left-click the header to choose display mode. "
        .. "Right-click to toggle Current/Overall session. "
        .. "Scroll wheel over the bars to page through all entries.",
        1, "medium")

    E.PopupDialogs.TUI_TDM_DISABLE_DETAILS = {
        text = 'Details! is currently enabled. Enabling TDM will disable Details! and require a reload.',
        wideText = true, showAlert = true,
        button1 = 'Enable TDM', button2 = CANCEL,
        OnAccept = function()
            TUI.db.profile.damageMeter.enabled = true
            TUI.db.profile.compat.damageMeter = 'tui'
            C_AddOns.DisableAddOn('Details')
            E:StaticPopup_Show('CONFIG_RL')
        end,
        whileDead = 1, hideOnEscape = 1,
    }

    gen.enabled = ACH:Toggle(
        function() return TUI.db.profile.damageMeter.enabled and "|cff00ff00Enable|r" or "Enable" end,
        nil, 2, nil, nil, nil,
        function() return TUI.db.profile.damageMeter.enabled end,
        function(_, value)
            if value and TUI:HasExternalAddonLoaded('damageMeter') then
                E:StaticPopup_Show('TUI_TDM_DISABLE_DETAILS'); return
            end
            TUI.db.profile.damageMeter.enabled = value
            E:StaticPopup_Show('CONFIG_RL')
        end)

    gen.showTimer = ACH:Toggle("Show Timer", "Display the session duration timer in the header.", 3, nil, nil, nil,
        function() return TUI.db.profile.damageMeter.showTimer end,
        function(_, v) TUI.db.profile.damageMeter.showTimer = v; winUpdate() end, dmDisabled)

    gen.autoResetOnComplete = ACH:Toggle("Auto-Reset on Entry",
        "Automatically reset meter data when entering a dungeon, raid, or scenario.", 4, nil, nil, nil,
        function() return TUI.db.profile.damageMeter.autoResetOnComplete end,
        function(_, v)
            TUI.db.profile.damageMeter.autoResetOnComplete = v
            SetCVar('damageMeterResetOnNewInstance', v and 1 or 0)
        end, dmDisabled)

    gen.hideInPetBattle = ACH:Toggle("Hide in Pet Battle", nil, 5, nil, nil, nil,
        function() return TUI.db.profile.damageMeter.hideInPetBattle end,
        function(_, v) TUI.db.profile.damageMeter.hideInPetBattle = v end, dmDisabled)

    gen.hideInFlight = ACH:Toggle("Hide in Flight", nil, 6, nil, nil, nil,
        function() return TUI.db.profile.damageMeter.hideInFlight end,
        function(_, v) TUI.db.profile.damageMeter.hideInFlight = v; TDM:UpdateFlightTicker() end, dmDisabled)

    gen.testMode = ACH:Execute("TDM Test", "Toggle placeholder bars.", 7,
        function() TDM:SetMeterTestMode(not TDM.testMode) end,
        nil, nil, nil, nil, nil, dmDisabled)

    -- Per-window tab builder
    local function BuildWindowTab(i)
        local winDis = function() return dmDisabled() or not isWindowEnabled(i) end
        local tab = ACH:Group("Window " .. i, nil, i + 1, 'tree', nil, nil, dmDisabled)

        -- Enable (windows 2-4 only)
        if i > 1 then
            tab.args.enable = ACH:Group("", nil, 0)
            tab.args.enable.inline = true
            tab.args.enable.args.enabled = ACH:Toggle(
                function() return isWindowEnabled(i) and "|cff00ff00Enable|r" or "Enable" end,
                nil, 1, nil, nil, nil,
                function() return isWindowEnabled(i) end,
                function(_, value)
                    local db = TUI.db.profile.damageMeter
                    db.windowEnabled[i] = value
                    if value then
                        db.extraWindows[i] = db.extraWindows[i] or {}
                        local ew = db.extraWindows[i]
                        for key in pairs(DM_DEFAULTS) do
                            local val = db[key]
                            if type(val) == "table" then
                                ew[key] = {}; for k, v in pairs(val) do ew[key][k] = v end
                            else
                                ew[key] = val
                            end
                        end
                        TDM:CreateExtraWindow(i)
                    else
                        TDM:DestroyExtraWindow(i)
                    end
                end)
        end

        -- Window settings
        tab.args.window = ACH:Group("Window", nil, 1)
        local win = tab.args.window.args

        if i == 1 then
            win.embedded = ACH:Toggle("Embed in Right Chat Panel",
                "Nest the meter inside the ElvUI Right Chat Panel.", 0, nil, nil, nil,
                function() return TUI.db.profile.damageMeter.embedded end,
                function(_, v)
                    TUI.db.profile.damageMeter.embedded = v
                    if v then
                        TUI.db.profile.damageMeter.showBackdrop = false
                        TUI.db.profile.damageMeter.showHeaderBackdrop = false
                    end
                    E:StaticPopup_Show('CONFIG_RL')
                end, winDis)
        end

        local sizeDisabled = function()
            return winDis() or (i == 1 and TUI.db.profile.damageMeter.embedded)
        end

        win.standaloneWidth = ACH:Range("Width", nil, 1, { min = 100, max = 600, step = 1 }, nil,
            function()
                if i == 1 and TUI.db.profile.damageMeter.embedded then
                    local panel = _G.RightChatPanel
                    return panel and math.floor(panel:GetWidth()) or winGet(i, 'standaloneWidth')
                end
                return winGet(i, 'standaloneWidth')
            end,
            function(_, v) winSet(i, 'standaloneWidth', v); TDM:ResizeMeterWindow(i) end, sizeDisabled)

        win.standaloneHeight = ACH:Range("Height", nil, 2, { min = 60, max = 600, step = 1 }, nil,
            function()
                if i == 1 and TUI.db.profile.damageMeter.embedded then
                    local panel = _G.RightChatPanel
                    return panel and math.floor(panel:GetHeight()) or winGet(i, 'standaloneHeight')
                end
                return winGet(i, 'standaloneHeight')
            end,
            function(_, v) winSet(i, 'standaloneHeight', v); TDM:ResizeMeterWindow(i) end, sizeDisabled)

        win.showBackdrop = ACH:Toggle("Window Backdrop", nil, 3, nil, nil, nil,
            function() return winGet(i, 'showBackdrop') end,
            function(_, v) winSet(i, 'showBackdrop', v); winUpdate() end, winDis)

        win.backdropColor = ACH:Color("Backdrop Color", nil, 4, true, nil,
            function() return winGetColor(i, 'backdropColor') end,
            function(_, r, g, b, a) winSetColor(i, 'backdropColor', r, g, b, a); winUpdate() end,
            function() return winDis() or not winGet(i, 'showBackdrop') end)

        -- Header
        tab.args.header = ACH:Group("Header", nil, 2)
        local hdr = tab.args.header.args

        hdr.headerFont = ACH:SharedMediaFont("Font", nil, 1, nil,
            function() return winGet(i, 'headerFont') end,
            function(_, v) winSet(i, 'headerFont', v); winUpdate() end, winDis)
        hdr.headerFontSize = ACH:Range("Font Size", nil, 2, { min = 8, max = 24, step = 1 }, nil,
            function() return winGet(i, 'headerFontSize') end,
            function(_, v) winSet(i, 'headerFontSize', v); winUpdate() end, winDis)
        hdr.headerFontOutline = ACH:FontFlags("Font Outline", nil, 3, nil,
            function() return winGet(i, 'headerFontOutline') end,
            function(_, v) winSet(i, 'headerFontOutline', v); winUpdate() end, winDis)
        hdr.headerFontColor = ACH:Color("Font Color", nil, 4, nil, nil,
            function() return winGetColor(i, 'headerFontColor') end,
            function(_, r, g, b) winSetColor(i, 'headerFontColor', r, g, b); winUpdate() end, winDis)
        hdr.showHeaderBackdrop = ACH:Toggle("Header Backdrop", nil, 5, nil, nil, nil,
            function() return winGet(i, 'showHeaderBackdrop') end,
            function(_, v) winSet(i, 'showHeaderBackdrop', v); winUpdate() end, winDis)
        hdr.showHeaderBorder = ACH:Toggle("Header Border", nil, 6, nil, nil, nil,
            function() return winGet(i, 'showHeaderBorder') end,
            function(_, v) winSet(i, 'showHeaderBorder', v); winUpdate() end, winDis)
        hdr.headerBGColor = ACH:Color("Backdrop Color", nil, 7, true, nil,
            function() return winGetColor(i, 'headerBGColor') end,
            function(_, r, g, b, a) winSetColor(i, 'headerBGColor', r, g, b, a); winUpdate() end, winDis)
        hdr.headerMouseover = ACH:Toggle("Mouseover", "Hide the header until moused over.", 8, nil, nil, nil,
            function() return winGet(i, 'headerMouseover') end,
            function(_, v) winSet(i, 'headerMouseover', v); winUpdate() end, winDis)

        -- Bars
        tab.args.bars = ACH:Group("Bars", nil, 3)
        local bars = tab.args.bars.args

        bars.barHeight = ACH:Range("Height", nil, 1, { min = 12, max = 40, step = 1 }, nil,
            function() return winGet(i, 'barHeight') end,
            function(_, v) winSet(i, 'barHeight', v); winUpdate() end, winDis)
        bars.clickInCombat = ACH:Toggle("Click in Combat", nil, 2, nil, nil, nil,
            function() return winGet(i, 'clickInCombat') end,
            function(_, v) winSet(i, 'clickInCombat', v) end, winDis)
        bars.barSpacing = ACH:Range("Spacing", nil, 3, { min = 0, max = 10, step = 1 }, nil,
            function() return winGet(i, 'barSpacing') end,
            function(_, v) winSet(i, 'barSpacing', v); winUpdate() end, winDis)
        bars.barBorderEnabled = ACH:Toggle("Borders", nil, 4, nil, nil, nil,
            function() return winGet(i, 'barBorderEnabled') end,
            function(_, v) winSet(i, 'barBorderEnabled', v); winUpdate() end, winDis)
        bars.showClassIcon = ACH:Toggle("Class Icons", nil, 5, nil, nil, nil,
            function() return winGet(i, 'showClassIcon') end,
            function(_, v) winSet(i, 'showClassIcon', v); winUpdate() end, winDis)

        -- Foreground (inside Bars)
        bars.foreground = ACH:Group("Foreground", nil, 10)
        bars.foreground.inline = true
        local fg = bars.foreground.args
        fg.barClassColor = ACH:Toggle("Class Color", nil, 1, nil, nil, nil,
            function() return winGet(i, 'barClassColor') end,
            function(_, v) winSet(i, 'barClassColor', v); winRefresh() end, winDis)
        fg.barColor = ACH:Color("Color", nil, 2, nil, nil,
            function() return winGetColor(i, 'barColor') end,
            function(_, r, g, b) winSetColor(i, 'barColor', r, g, b); winRefresh() end,
            function() return winDis() or winGet(i, 'barClassColor') end)
        fg.barTexture = ACH:SharedMediaStatusbar("Texture", nil, 3, nil,
            function() local t = winGet(i, 'barTexture'); return (t and t ~= '') and t or E.private.general.normTex end,
            function(_, v) local def = E.private.general.normTex; winSet(i, 'barTexture', (v == def) and '' or v); winUpdate() end, winDis)

        -- Background (inside Bars)
        bars.background = ACH:Group("Background", nil, 20)
        bars.background.inline = true
        local bg = bars.background.args
        bg.barBGClassColor = ACH:Toggle("Class Color", nil, 1, nil, nil, nil,
            function() return winGet(i, 'barBGClassColor') end,
            function(_, v) winSet(i, 'barBGClassColor', v); winRefresh() end, winDis)
        bg.barBGColor = ACH:Color("Color", nil, 2, true, nil,
            function() return winGetColor(i, 'barBGColor') end,
            function(_, r, g, b, a) winSetColor(i, 'barBGColor', r, g, b, a); winRefresh() end,
            function() return winDis() or winGet(i, 'barBGClassColor') end)
        bg.barBGTexture = ACH:SharedMediaStatusbar("Texture", nil, 3, nil,
            function() local t = winGet(i, 'barBGTexture'); return (t and t ~= '') and t or E.private.general.normTex end,
            function(_, v) local def = E.private.general.normTex; winSet(i, 'barBGTexture', (v == def) and '' or v); winUpdate() end, winDis)

        -- Text
        tab.args.text = ACH:Group("Text", nil, 4)
        local txt = tab.args.text.args

        txt.barFont = ACH:SharedMediaFont("Font", nil, 1, nil,
            function() return winGet(i, 'barFont') end,
            function(_, v) winSet(i, 'barFont', v); winUpdate() end, winDis)
        txt.barFontSize = ACH:Range("Font Size", nil, 2, { min = 8, max = 24, step = 1 }, nil,
            function() return winGet(i, 'barFontSize') end,
            function(_, v) winSet(i, 'barFontSize', v); winUpdate() end, winDis)
        txt.barFontOutline = ACH:FontFlags("Font Outline", nil, 3, nil,
            function() return winGet(i, 'barFontOutline') end,
            function(_, v) winSet(i, 'barFontOutline', v); winUpdate() end, winDis)

        -- Name (inside Text)
        txt.name = ACH:Group("Name", nil, 10)
        txt.name.inline = true
        local nm = txt.name.args
        nm.textClassColor = ACH:Toggle("Class Color", nil, 1, nil, nil, nil,
            function() return winGet(i, 'textClassColor') end,
            function(_, v) winSet(i, 'textClassColor', v); winRefresh() end, winDis)
        nm.textColor = ACH:Color("Color", nil, 2, nil, nil,
            function() return winGetColor(i, 'textColor') end,
            function(_, r, g, b) winSetColor(i, 'textColor', r, g, b); winRefresh() end,
            function() return winDis() or winGet(i, 'textClassColor') end)

        -- Value (inside Text)
        txt.value = ACH:Group("Value", nil, 20)
        txt.value.inline = true
        local val = txt.value.args
        val.valueClassColor = ACH:Toggle("Class Color", nil, 1, nil, nil, nil,
            function() return winGet(i, 'valueClassColor') end,
            function(_, v) winSet(i, 'valueClassColor', v); winRefresh() end, winDis)
        val.valueColor = ACH:Color("Color", nil, 2, nil, nil,
            function() return winGetColor(i, 'valueColor') end,
            function(_, r, g, b) winSetColor(i, 'valueColor', r, g, b); winRefresh() end,
            function() return winDis() or winGet(i, 'valueClassColor') end)

        -- Rank (inside Text)
        txt.rank = ACH:Group("Rank", nil, 30)
        txt.rank.inline = true
        local rk = txt.rank.args
        local rkDis = function() return winDis() or not winGet(i, 'showRank') end
        rk.showRank = ACH:Toggle("Show Rank", nil, 1, nil, nil, nil,
            function() return winGet(i, 'showRank') end,
            function(_, v) winSet(i, 'showRank', v); winRefresh() end, winDis)
        rk.rankClassColor = ACH:Toggle("Class Color", nil, 2, nil, nil, nil,
            function() return winGet(i, 'rankClassColor') end,
            function(_, v) winSet(i, 'rankClassColor', v); winRefresh() end, rkDis)
        rk.rankColor = ACH:Color("Color", nil, 3, nil, nil,
            function() return winGetColor(i, 'rankColor') end,
            function(_, r, g, b) winSetColor(i, 'rankColor', r, g, b); winRefresh() end,
            function() return rkDis() or winGet(i, 'rankClassColor') end)

        return tab
    end

    -- Build window tabs
    for i = 1, 4 do
        root.damageMeter.args['window' .. i] = BuildWindowTab(i)
    end

    -- Apply to All button (on Window 1 tab)
    local w1 = root.damageMeter.args.window1.args.window.args
    w1.applyToAll = ACH:Execute("Apply Settings to All",
        "Copy this window's visual settings to all enabled extra windows.", 10,
        function()
            local db = TUI.db.profile.damageMeter
            local liveW, liveH
            if db.embedded then
                local panel = _G.RightChatPanel
                if panel then liveW = math.floor(panel:GetWidth()); liveH = math.floor(panel:GetHeight()) end
            end
            for j = 2, 4 do
                if db.windowEnabled[j] then
                    db.extraWindows[j] = db.extraWindows[j] or {}
                    local ew = db.extraWindows[j]
                    for key in pairs(DM_DEFAULTS) do
                        local v = db[key]
                        if key == 'standaloneWidth' and liveW then v = liveW
                        elseif key == 'standaloneHeight' and liveH then v = liveH end
                        if type(v) == "table" then
                            ew[key] = {}; for k, val in pairs(v) do ew[key][k] = val end
                        else
                            ew[key] = v
                        end
                    end
                end
            end
            winUpdate()
        end, nil, nil, nil, nil, nil, dmDisabled)
end
