local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local ACH = E.Libs.ACH

function TUI:BuildDamageMeterConfig(root, tuiName)
    if not (C_DamageMeter and Enum.DamageMeterType) then return end

    root.damageMeter = ACH:Group("TDM", nil, 2)

    -- Per-window keys from the shared damageMeter defaults (excludes global-only keys)
    local DM_SKIP = { enabled = true, modeIndex = true, autoResetOnComplete = true, embedded = true, windowEnabled = true, extraWindows = true }
    local DM_DEFAULTS = {}
    for k, v in pairs(TUI.defaults.profile.damageMeter) do
        if not DM_SKIP[k] then DM_DEFAULTS[k] = v end
    end
    TUI.DM_DEFAULTS = DM_DEFAULTS

    local dmDisabled = function() return not TUI.db.profile.damageMeter.enabled end

    TUI._selectedMeterWindow = TUI._selectedMeterWindow or 1

    local function isWindowEnabled(i)
        local we = TUI.db.profile.damageMeter.windowEnabled
        return we and we[i]
    end

    local function selWinDisabled()
        return dmDisabled() or not isWindowEnabled(TUI._selectedMeterWindow)
    end

    local function getWinDB()
        local db = TUI.db.profile.damageMeter
        if TUI._selectedMeterWindow == 1 then return db end
        db.extraWindows[TUI._selectedMeterWindow] = db.extraWindows[TUI._selectedMeterWindow] or {}
        return db.extraWindows[TUI._selectedMeterWindow]
    end

    local function winGet(key)
        local wdb = getWinDB()
        if TUI._selectedMeterWindow == 1 then return wdb[key] end
        local val = wdb[key]
        if val ~= nil then return val end
        return TUI.db.profile.damageMeter[key]
    end

    local function winSet(key, value) getWinDB()[key] = value end

    local function winGetColor(key)
        local c = winGet(key)
        return c.r, c.g, c.b, c.a
    end

    local function winSetColor(key, r, g, b, a)
        local wdb = getWinDB()
        if not wdb[key] then wdb[key] = {} end
        local c = wdb[key]
        c.r, c.g, c.b, c.a = r, g, b, a
    end

    local function winUpdate() TUI:UpdateMeterLayout() end
    local function winRefresh() TUI:RefreshMeter() end

    local WHITE, GREY = '|cFFFFFFFF', '|cFF888888'

    root.damageMeter.args.general = ACH:Group("General", nil, 1)
    root.damageMeter.args.general.inline = true
    local dmGen = root.damageMeter.args.general.args

    dmGen.desc = ACH:Description(
        "TDM is a lightweight meter using the built-in API. "
        .. "Options below to enable additional windows and embed window 1 into the right chat panel. "
        .. "Additional windows can be moved via the movers button at the top of the config.\n\n"
        .. "Left-click the header to choose display mode. "
        .. "Right-click to toggle Current/Overall session. "
        .. "Scroll wheel over the bars to page through all entries.",
        1, "medium"
    )

    E.PopupDialogs.TUI_TDM_DISABLE_DETAILS = {
        text = 'Details! is currently enabled. Enabling TDM will disable Details! and require a reload.',
        wideText = true,
        showAlert = true,
        button1 = 'Enable TDM',
        button2 = CANCEL,
        OnAccept = function()
            TUI.db.profile.damageMeter.enabled = true
            TUI.db.profile.compat.damageMeter = 'tui'
            C_AddOns.DisableAddOn('Details')
            E:StaticPopup_Show('CONFIG_RL')
        end,
        whileDead = 1,
        hideOnEscape = 1,
    }

    dmGen.enabled = ACH:Toggle(
        function() return TUI.db.profile.damageMeter.enabled and "|cff00ff00Enable|r" or "Enable" end,
        "Show TDM.",
        2, nil, nil, nil,
        function() return TUI.db.profile.damageMeter.enabled end,
        function(_, value)
            if value and TUI:HasExternalAddonLoaded('damageMeter') then
                E:StaticPopup_Show('TUI_TDM_DISABLE_DETAILS')
                return
            end
            TUI.db.profile.damageMeter.enabled = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )

    dmGen.showTimer = ACH:Toggle(
        "Show Timer", "Display the session duration timer in the header.",
        3, nil, nil, nil,
        function() return TUI.db.profile.damageMeter.showTimer end,
        function(_, value) TUI.db.profile.damageMeter.showTimer = value; winUpdate() end,
        dmDisabled
    )

    dmGen.autoResetOnComplete = ACH:Toggle(
        "Auto-Reset on Entry",
        "Automatically reset all meter data when entering a dungeon, raid, or scenario.",
        4, nil, nil, nil,
        function() return TUI.db.profile.damageMeter.autoResetOnComplete end,
        function(_, value) TUI.db.profile.damageMeter.autoResetOnComplete = value end,
        dmDisabled
    )

    dmGen.hideInPetBattle = ACH:Toggle(
        "Hide in Pet Battle", "Hide all meter windows during pet battles.",
        5, nil, nil, nil,
        function() return TUI.db.profile.damageMeter.hideInPetBattle end,
        function(_, value) TUI.db.profile.damageMeter.hideInPetBattle = value end,
        dmDisabled
    )

    dmGen.hideInFlight = ACH:Toggle(
        "Hide in Flight", "Hide all meter windows while flying.",
        6, nil, nil, nil,
        function() return TUI.db.profile.damageMeter.hideInFlight end,
        function(_, value)
            TUI.db.profile.damageMeter.hideInFlight = value
            TUI:UpdateFlightTicker()
        end,
        dmDisabled
    )

    dmGen.testMode = ACH:Execute(
        "TDM Test", "Toggle placeholder bars to preview the meter appearance.",
        7,
        function() TUI:SetMeterTestMode(not TUI._meterTestMode) end,
        nil, nil, nil, nil, nil,
        dmDisabled
    )

    root.damageMeter.args.windows = ACH:Group("Windows", nil, 2)
    root.damageMeter.args.windows.inline = true
    local dmWinSel = root.damageMeter.args.windows.args

    dmWinSel.windowSelect = ACH:Select(
        "Window", "Select which window to configure below.", 1,
        function()
            local t = {}
            for i = 1, 4 do
                local color = isWindowEnabled(i) and WHITE or GREY
                t[i] = color .. "Window " .. i .. '|r'
            end
            return t
        end,
        nil, nil,
        function() return TUI._selectedMeterWindow end,
        function(_, value) TUI._selectedMeterWindow = value end,
        dmDisabled
    )

    dmWinSel.windowEnabled = ACH:Toggle(
        function() return isWindowEnabled(TUI._selectedMeterWindow) and "|cff00ff00Enable|r" or "Enable" end,
        "Enable or disable this window. Window 1 is always enabled.",
        2, nil, nil, nil,
        function() return isWindowEnabled(TUI._selectedMeterWindow) end,
        function(_, value)
            local db = TUI.db.profile.damageMeter
            db.windowEnabled[TUI._selectedMeterWindow] = value
            if value and TUI._selectedMeterWindow > 1 then
                db.extraWindows[TUI._selectedMeterWindow] = db.extraWindows[TUI._selectedMeterWindow] or {}
                local ew = db.extraWindows[TUI._selectedMeterWindow]
                for key in pairs(DM_DEFAULTS) do
                    local val = db[key]
                    if type(val) == "table" then
                        ew[key] = {}
                        for k, v in pairs(val) do ew[key][k] = v end
                    else
                        ew[key] = val
                    end
                end
            end
            if value then
                TUI:CreateExtraWindow(TUI._selectedMeterWindow)
            else
                TUI:DestroyExtraWindow(TUI._selectedMeterWindow)
            end
        end,
        function() return dmDisabled() or TUI._selectedMeterWindow == 1 end
    )

    dmWinSel.embedded = ACH:Toggle(
        "Embed in Right Chat Panel",
        "Nest the meter inside the ElvUI Right Chat Panel instead of a standalone window.",
        3, nil, nil, nil,
        function() return TUI.db.profile.damageMeter.embedded end,
        function(_, value)
            TUI.db.profile.damageMeter.embedded = value
            if value then
                TUI.db.profile.damageMeter.showBackdrop = false
                TUI.db.profile.damageMeter.showHeaderBackdrop = false
            end
            E:StaticPopup_Show('CONFIG_RL')
        end,
        function() return dmDisabled() or TUI._selectedMeterWindow ~= 1 end,
        function() return TUI._selectedMeterWindow ~= 1 end
    )

    dmWinSel.applyToAll = ACH:Execute(
        "Apply Settings to All",
        "Copy Window 1's visual settings to all enabled extra windows.",
        4,
        function()
            local db = TUI.db.profile.damageMeter
            local liveW, liveH
            if db.embedded then
                local panel = _G.RightChatPanel
                if panel then
                    liveW = math.floor(panel:GetWidth())
                    liveH = math.floor(panel:GetHeight())
                end
            end
            for i = 2, 4 do
                if db.windowEnabled[i] then
                    db.extraWindows[i] = db.extraWindows[i] or {}
                    local ew = db.extraWindows[i]
                    for key in pairs(DM_DEFAULTS) do
                        local val = db[key]
                        if key == 'standaloneWidth' and liveW then
                            val = liveW
                        elseif key == 'standaloneHeight' and liveH then
                            val = liveH
                        end
                        if type(val) == "table" then
                            ew[key] = {}
                            for k, v in pairs(val) do ew[key][k] = v end
                        else
                            ew[key] = val
                        end
                    end
                end
            end
            winUpdate()
        end,
        nil, nil, nil, nil, nil,
        function() return dmDisabled() or TUI._selectedMeterWindow ~= 1 end,
        function() return TUI._selectedMeterWindow ~= 1 end
    )

    root.damageMeter.args.window = ACH:Group("Window", nil, 3, nil, nil, nil, selWinDisabled)
    root.damageMeter.args.window.inline = true
    local dmWin = root.damageMeter.args.window.args

    local function sizeDisabled()
        return selWinDisabled() or (TUI._selectedMeterWindow == 1 and TUI.db.profile.damageMeter.embedded)
    end

    dmWin.standaloneWidth = ACH:Range(
        "Width", "Width of this window in pixels.", 1,
        { min = 100, max = 600, step = 1 }, nil,
        function()
            if TUI._selectedMeterWindow == 1 and TUI.db.profile.damageMeter.embedded then
                local panel = _G.RightChatPanel
                return panel and math.floor(panel:GetWidth()) or winGet('standaloneWidth')
            end
            return winGet('standaloneWidth')
        end,
        function(_, value)
            winSet('standaloneWidth', value)
            TUI:ResizeMeterWindow(TUI._selectedMeterWindow)
        end,
        sizeDisabled
    )

    dmWin.standaloneHeight = ACH:Range(
        "Height", "Height of this window in pixels.", 2,
        { min = 60, max = 600, step = 1 }, nil,
        function()
            if TUI._selectedMeterWindow == 1 and TUI.db.profile.damageMeter.embedded then
                local panel = _G.RightChatPanel
                return panel and math.floor(panel:GetHeight()) or winGet('standaloneHeight')
            end
            return winGet('standaloneHeight')
        end,
        function(_, value)
            winSet('standaloneHeight', value)
            TUI:ResizeMeterWindow(TUI._selectedMeterWindow)
        end,
        sizeDisabled
    )

    dmWin.showBackdrop = ACH:Toggle(
        "Window Backdrop", "Show a backdrop behind the bar area.",
        3, nil, nil, nil,
        function() return winGet('showBackdrop') end,
        function(_, value) winSet('showBackdrop', value); winUpdate() end,
        selWinDisabled
    )

    dmWin.backdropColor = ACH:Color(
        "Backdrop Color", "Color and transparency of the window backdrop.",
        4, true, nil,
        function() return winGetColor('backdropColor') end,
        function(_, r, g, b, a) winSetColor('backdropColor', r, g, b, a); winUpdate() end,
        function() return selWinDisabled() or not winGet('showBackdrop') end
    )

    root.damageMeter.args.header = ACH:Group("Header", nil, 4, nil, nil, nil, selWinDisabled)
    root.damageMeter.args.header.inline = true
    local dmHdr = root.damageMeter.args.header.args

    dmHdr.headerFont = ACH:SharedMediaFont(
        "Font", "Font used for the header title and timer.", 1, nil,
        function() return winGet('headerFont') end,
        function(_, value) winSet('headerFont', value); winUpdate() end,
        selWinDisabled
    )

    dmHdr.headerFontSize = ACH:Range(
        "Font Size", "Size of the header text.", 2,
        { min = 8, max = 24, step = 1 }, nil,
        function() return winGet('headerFontSize') end,
        function(_, value) winSet('headerFontSize', value); winUpdate() end,
        selWinDisabled
    )

    dmHdr.headerFontOutline = ACH:FontFlags(
        "Font Outline", "Outline style for the header text.", 3, nil,
        function() return winGet('headerFontOutline') end,
        function(_, value) winSet('headerFontOutline', value); winUpdate() end,
        selWinDisabled
    )

    dmHdr.headerFontColor = ACH:Color(
        "Font Color", "Color for the mode label and timer text.",
        4, nil, nil,
        function() return winGetColor('headerFontColor') end,
        function(_, r, g, b) winSetColor('headerFontColor', r, g, b); winUpdate() end,
        selWinDisabled
    )

    dmHdr.showHeaderBackdrop = ACH:Toggle(
        "Header Backdrop", "Show a backdrop behind the header bar.",
        5, nil, nil, nil,
        function() return winGet('showHeaderBackdrop') end,
        function(_, value) winSet('showHeaderBackdrop', value); winUpdate() end,
        selWinDisabled
    )

    dmHdr.showHeaderBorder = ACH:Toggle(
        "Header Border", "Show a border around the header section.",
        6, nil, nil, nil,
        function() return winGet('showHeaderBorder') end,
        function(_, value) winSet('showHeaderBorder', value); winUpdate() end,
        selWinDisabled
    )

    dmHdr.headerBGColor = ACH:Color(
        "Backdrop Color", "Background color and transparency of the header.",
        7, true, nil,
        function() return winGetColor('headerBGColor') end,
        function(_, r, g, b, a) winSetColor('headerBGColor', r, g, b, a); winUpdate() end,
        selWinDisabled
    )

    dmHdr.headerMouseover = ACH:Toggle(
        "Mouseover", "Hide the header until the meter is moused over.",
        8, nil, nil, nil,
        function() return winGet('headerMouseover') end,
        function(_, value) winSet('headerMouseover', value); winUpdate() end,
        selWinDisabled
    )

    root.damageMeter.args.bars = ACH:Group("Bars", nil, 5, nil, nil, nil, selWinDisabled)
    root.damageMeter.args.bars.inline = true
    local dmBars = root.damageMeter.args.bars.args

    dmBars.barHeight = ACH:Range(
        "Height", "Fixed height of each bar in pixels.", 1,
        { min = 12, max = 40, step = 1 }, nil,
        function() return winGet('barHeight') end,
        function(_, value) winSet('barHeight', value); winUpdate() end,
        selWinDisabled
    )

    dmBars.clickInCombat = ACH:Toggle(
        E.NewSign .. "Click in Combat", "Allow clicking bars to drill down during combat. When disabled, bars are only interactive out of combat.",
        1.5, nil, nil, nil,
        function() return winGet('clickInCombat') end,
        function(_, value) winSet('clickInCombat', value) end,
        selWinDisabled
    )

    dmBars.barSpacing = ACH:Range(
        "Spacing", "Vertical gap between bars in pixels.", 2,
        { min = 0, max = 10, step = 1 }, nil,
        function() return winGet('barSpacing') end,
        function(_, value) winSet('barSpacing', value); winUpdate() end,
        selWinDisabled
    )

    dmBars.barBorderEnabled = ACH:Toggle(
        "Borders", "Draw ElvUI-styled borders around each bar.",
        3, nil, nil, nil,
        function() return winGet('barBorderEnabled') end,
        function(_, value) winSet('barBorderEnabled', value); winUpdate() end,
        selWinDisabled
    )

    dmBars.showClassIcon = ACH:Toggle(
        "Class Icons", "Show Jiberish Fabled class icons to the left of each player name.",
        4, nil, nil, nil,
        function() return winGet('showClassIcon') end,
        function(_, value) winSet('showClassIcon', value); winUpdate() end,
        selWinDisabled
    )

    dmBars.foreground = ACH:Group("Foreground", nil, 10)
    dmBars.foreground.inline = true
    local dmFG = dmBars.foreground.args

    dmFG.barClassColor = ACH:Toggle(
        "Class Color", "Use ElvUI class colors for bar foregrounds.",
        1, nil, nil, nil,
        function() return winGet('barClassColor') end,
        function(_, value) winSet('barClassColor', value); winRefresh() end,
        selWinDisabled
    )

    dmFG.barColor = ACH:Color(
        "Color", "Fixed bar foreground color (used when Class Color is off).",
        2, nil, nil,
        function() return winGetColor('barColor') end,
        function(_, r, g, b) winSetColor('barColor', r, g, b); winRefresh() end,
        function() return selWinDisabled() or winGet('barClassColor') end
    )

    dmFG.barTexture = ACH:SharedMediaStatusbar(
        "Texture", "Statusbar texture for bar foregrounds. Defaults to the ElvUI primary texture.",
        3, nil,
        function() local t = winGet('barTexture'); return (t and t ~= '') and t or E.private.general.normTex end,
        function(_, value)
            local def = E.private.general.normTex
            winSet('barTexture', (value == def) and '' or value)
            winUpdate()
        end,
        selWinDisabled
    )

    dmBars.background = ACH:Group("Background", nil, 20)
    dmBars.background.inline = true
    local dmBG = dmBars.background.args

    dmBG.barBGClassColor = ACH:Toggle(
        "Class Color", "Use ElvUI class colors for bar backgrounds.",
        1, nil, nil, nil,
        function() return winGet('barBGClassColor') end,
        function(_, value) winSet('barBGClassColor', value); winRefresh() end,
        selWinDisabled
    )

    dmBG.barBGColor = ACH:Color(
        "Color", "Bar background color and alpha.",
        2, true, nil,
        function() return winGetColor('barBGColor') end,
        function(_, r, g, b, a) winSetColor('barBGColor', r, g, b, a); winRefresh() end,
        function() return selWinDisabled() or winGet('barBGClassColor') end
    )

    dmBG.barBGTexture = ACH:SharedMediaStatusbar(
        "Texture", "Statusbar texture for bar backgrounds. Defaults to the ElvUI primary texture.",
        3, nil,
        function() local t = winGet('barBGTexture'); return (t and t ~= '') and t or E.private.general.normTex end,
        function(_, value)
            local def = E.private.general.normTex
            winSet('barBGTexture', (value == def) and '' or value)
            winUpdate()
        end,
        selWinDisabled
    )

    root.damageMeter.args.text = ACH:Group("Text", nil, 6, nil, nil, nil, selWinDisabled)
    root.damageMeter.args.text.inline = true
    local dmText = root.damageMeter.args.text.args

    dmText.barFont = ACH:SharedMediaFont(
        "Font", "Font used for bar name and value text.", 1, nil,
        function() return winGet('barFont') end,
        function(_, value) winSet('barFont', value); winUpdate() end,
        selWinDisabled
    )

    dmText.barFontSize = ACH:Range(
        "Font Size", "Size of bar text.", 2,
        { min = 8, max = 24, step = 1 }, nil,
        function() return winGet('barFontSize') end,
        function(_, value) winSet('barFontSize', value); winUpdate() end,
        selWinDisabled
    )

    dmText.barFontOutline = ACH:FontFlags(
        "Font Outline", "Outline style for bar text.", 3, nil,
        function() return winGet('barFontOutline') end,
        function(_, value) winSet('barFontOutline', value); winUpdate() end,
        selWinDisabled
    )

    dmText.name = ACH:Group("Name", nil, 10)
    dmText.name.inline = true
    local dmName = dmText.name.args

    dmName.textClassColor = ACH:Toggle(
        "Class Color", "Use ElvUI class colors for player name text.",
        1, nil, nil, nil,
        function() return winGet('textClassColor') end,
        function(_, value) winSet('textClassColor', value); winRefresh() end,
        selWinDisabled
    )

    dmName.textColor = ACH:Color(
        "Color", "Fixed name text color (used when Class Color is off).",
        2, nil, nil,
        function() return winGetColor('textColor') end,
        function(_, r, g, b) winSetColor('textColor', r, g, b); winRefresh() end,
        function() return selWinDisabled() or winGet('textClassColor') end
    )

    dmText.value = ACH:Group("Value", nil, 20)
    dmText.value.inline = true
    local dmValue = dmText.value.args

    dmValue.valueClassColor = ACH:Toggle(
        "Class Color", "Use ElvUI class colors for value text.",
        1, nil, nil, nil,
        function() return winGet('valueClassColor') end,
        function(_, value) winSet('valueClassColor', value); winRefresh() end,
        selWinDisabled
    )

    dmValue.valueColor = ACH:Color(
        "Color", "Fixed value text color (used when Class Color is off).",
        2, nil, nil,
        function() return winGetColor('valueColor') end,
        function(_, r, g, b) winSetColor('valueColor', r, g, b); winRefresh() end,
        function() return selWinDisabled() or winGet('valueClassColor') end
    )

    dmText.rank = ACH:Group("Rank", nil, 30)
    dmText.rank.inline = true
    local dmRank = dmText.rank.args

    local rankDisabled = function() return selWinDisabled() or not winGet('showRank') end

    dmRank.showRank = ACH:Toggle(
        "Show Rank", "Show the rank number before each player name.",
        1, nil, nil, nil,
        function() return winGet('showRank') end,
        function(_, value) winSet('showRank', value); winRefresh() end,
        selWinDisabled
    )

    dmRank.rankClassColor = ACH:Toggle(
        "Class Color", "Use ElvUI class colors for the rank number.",
        2, nil, nil, nil,
        function() return winGet('rankClassColor') end,
        function(_, value) winSet('rankClassColor', value); winRefresh() end,
        rankDisabled
    )

    dmRank.rankColor = ACH:Color(
        "Color", "Fixed rank number color (used when Class Color is off).",
        3, nil, nil,
        function() return winGetColor('rankColor') end,
        function(_, r, g, b) winSetColor('rankColor', r, g, b); winRefresh() end,
        function() return rankDisabled() or winGet('rankClassColor') end
    )
end
