local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local ACH = E.Libs.ACH

local function cdmDB() return TUI.db.profile.cooldownManager end
local function cdmDisabled() return not cdmDB().enabled end
local function getCDM() return E:GetModule('TUI_CDM', true) end
local function cdmRefresh() local CDM = getCDM(); if CDM then CDM:RefreshCDM() end end

local POSITIONS = {
    CENTER = 'Center', TOP = 'Top', BOTTOM = 'Bottom', LEFT = 'Left', RIGHT = 'Right',
    TOPLEFT = 'Top Left', TOPRIGHT = 'Top Right', BOTTOMLEFT = 'Bottom Left', BOTTOMRIGHT = 'Bottom Right',
}

local VIS_OPTIONS = { ALWAYS = 'Always', INCOMBAT = 'In Combat', INPARTY = 'In Party/Raid', FADER = 'Player Fader', HIDDEN = 'Hidden' }

-- Shared builder: text settings
local function BuildTextGroup(name, order, getDB, hidden)
    local g = ACH:Group(name, nil, order)
    if hidden then g.hidden = hidden end
    local a = g.args

    a.font = ACH:SharedMediaFont("Font", nil, 1, nil,
        function() return getDB().font end,
        function(_, v) getDB().font = v; cdmRefresh() end)
    a.fontSize = ACH:Range("Font Size", nil, 2, { min = 6, max = 36, step = 1 }, nil,
        function() return getDB().fontSize end,
        function(_, v) getDB().fontSize = v; cdmRefresh() end)
    a.fontOutline = ACH:FontFlags("Font Outline", nil, 3, nil,
        function() return getDB().fontOutline end,
        function(_, v) getDB().fontOutline = v; cdmRefresh() end)
    a.classColor = ACH:Toggle("Class Color", nil, 4, nil, nil, nil,
        function() return getDB().classColor end,
        function(_, v) getDB().classColor = v; cdmRefresh() end)
    a.color = ACH:Color("Color", nil, 5, nil, nil,
        function() local c = getDB().color; return c.r, c.g, c.b end,
        function(_, r, g, b) local c = getDB().color; c.r, c.g, c.b = r, g, b; cdmRefresh() end,
        function() return getDB().classColor end)
    a.position = ACH:Select("Position", nil, 6, POSITIONS, nil, nil,
        function() return getDB().position end,
        function(_, v) getDB().position = v; cdmRefresh() end)
    a.xOffset = ACH:Range("X-Offset", nil, 7, { min = -45, max = 45, step = 1 }, nil,
        function() return getDB().xOffset end,
        function(_, v) getDB().xOffset = v; cdmRefresh() end)
    a.yOffset = ACH:Range("Y-Offset", nil, 8, { min = -45, max = 45, step = 1 }, nil,
        function() return getDB().yOffset end,
        function(_, v) getDB().yOffset = v; cdmRefresh() end)
    return g
end

-- Shared builder: icon viewer tab (essential, utility, buffIcon)
local function BuildIconViewerTab(viewerKey, label, order)
    local vdb = function() return cdmDB().viewers[viewerKey] end
    local tab = ACH:Group(label, nil, order, 'tree', nil, nil, cdmDisabled)

    -- Layout
    tab.args.layout = ACH:Group("Layout", nil, 1)
    local lay = tab.args.layout.args

    lay.keepSizeRatio = ACH:Toggle("Keep Size Ratio", nil, 1, nil, nil, nil,
        function() return vdb().keepSizeRatio end,
        function(_, v) vdb().keepSizeRatio = v; cdmRefresh() end)
    lay.iconWidth = ACH:Range(
        function() return vdb().keepSizeRatio and "Icon Size" or "Icon Width" end, nil, 2,
        { min = 16, max = 80, step = 1 }, nil,
        function() return vdb().iconWidth end,
        function(_, v) vdb().iconWidth = v; cdmRefresh() end)
    lay.iconHeight = ACH:Range("Icon Height", nil, 3, { min = 16, max = 80, step = 1 }, nil,
        function() return vdb().iconHeight end,
        function(_, v) vdb().iconHeight = v; cdmRefresh() end)
    lay.iconHeight.hidden = function() return vdb().keepSizeRatio end
    lay.iconZoom = ACH:Range("Icon Zoom", "Crop the icon texture inward.", 4,
        { min = 0, max = 0.60, step = 0.01, isPercent = true }, nil,
        function() return vdb().iconZoom end,
        function(_, v) vdb().iconZoom = v; cdmRefresh() end)
    lay.spacing = ACH:Range("Spacing", nil, 5, { min = 0, max = 20, step = 1 }, nil,
        function() return vdb().spacing end,
        function(_, v) vdb().spacing = v; cdmRefresh() end)
    lay.iconsPerRow = ACH:Range("Icons Per Row", nil, 6, { min = 1, max = 20, step = 1 }, nil,
        function() return vdb().iconsPerRow end,
        function(_, v) vdb().iconsPerRow = v; cdmRefresh() end)
    lay.growthDirection = ACH:Select("Vertical Growth", nil, 7, { DOWN = 'Down', UP = 'Up' }, nil, nil,
        function() return vdb().growthDirection end,
        function(_, v) vdb().growthDirection = v; cdmRefresh() end)

    -- Visibility
    tab.args.visibility = ACH:Group("Visibility", nil, 2)
    local vis = tab.args.visibility.args

    vis.visibleSetting = ACH:Select("When to Show", nil, 1, VIS_OPTIONS, nil, nil,
        function() return vdb().visibleSetting end,
        function(_, v) vdb().visibleSetting = v; local CDM = getCDM(); if CDM then CDM:UpdateCDMVisibility() end end)
    vis.showTooltips = ACH:Toggle("Show Tooltips", nil, 2, nil, nil, nil,
        function() return vdb().showTooltips end,
        function(_, v)
            vdb().showTooltips = v
            local CDM = getCDM(); if CDM and Enum.EditModeCooldownViewerSetting then
                CDM:SetEditModeSetting(viewerKey, Enum.EditModeCooldownViewerSetting.ShowTooltips, v and 1 or 0)
            end
            E:StaticPopup_Show('CONFIG_RL')
        end)

    if viewerKey == 'essential' or viewerKey == 'utility' then
        vis.showKeybind = ACH:Toggle("Show Keybind", nil, 3, nil, nil, nil,
            function() return vdb().showKeybind end,
            function(_, v) vdb().showKeybind = v; cdmRefresh() end)
    end

    if viewerKey == 'buffIcon' then
        vis.hideWhenInactive = ACH:Toggle("Hide When Inactive", nil, 3, nil, nil, nil,
            function() return vdb().hideWhenInactive end,
            function(_, v)
                vdb().hideWhenInactive = v
                local CDM = getCDM(); if CDM and Enum.EditModeCooldownViewerSetting then
                    CDM:SetEditModeSetting(viewerKey, Enum.EditModeCooldownViewerSetting.HideWhenInactive, v and 1 or 0)
                end
                E:StaticPopup_Show('CONFIG_RL')
            end)
    end

    -- Cooldown Text
    tab.args.cooldownText = BuildTextGroup("Cooldown Text", 3, function() return vdb().cooldownText end)

    -- Count Text
    tab.args.countText = BuildTextGroup("Count Text", 4, function() return vdb().countText end)

    -- Keybind Text (essential/utility only)
    if viewerKey == 'essential' or viewerKey == 'utility' then
        tab.args.keybindText = BuildTextGroup("Keybind Text", 5, function() return vdb().keybindText end,
            function() return not vdb().showKeybind end)
    end

    -- Glow (essential only)
    if viewerKey == 'essential' then
        tab.args.glow = ACH:Group("Proc Glow", nil, 6)
        local gl = tab.args.glow.args
        local glDis = function() return not vdb().glow.enabled end

        gl.enabled = ACH:Toggle(
            function() return vdb().glow.enabled and "|cff00ff00Enable|r" or "Enable" end,
            nil, 1, nil, nil, nil,
            function() return vdb().glow.enabled end,
            function(_, v) vdb().glow.enabled = v; cdmRefresh() end)
        gl.type = ACH:Select("Type", nil, 2,
            { pixel = 'Pixel', autocast = 'Autocast', button = 'Button', proc = 'Proc' }, nil, nil,
            function() return vdb().glow.type end,
            function(_, v) vdb().glow.type = v; cdmRefresh() end, glDis)
        gl.color = ACH:Color("Color", nil, 3, true, nil,
            function() local c = vdb().glow.color; return c.r, c.g, c.b, c.a end,
            function(_, r, g, b, a) local c = vdb().glow.color; c.r, c.g, c.b, c.a = r, g, b, a; cdmRefresh() end, glDis)
        gl.lines = ACH:Range("Lines", "Pixel only.", 4, { min = 1, max = 20, step = 1 }, nil,
            function() return vdb().glow.lines end,
            function(_, v) vdb().glow.lines = v; cdmRefresh() end,
            function() return glDis() or vdb().glow.type ~= 'pixel' end)
        gl.speed = ACH:Range("Speed", nil, 5, { min = 0.05, max = 2, step = 0.05 }, nil,
            function() return vdb().glow.speed end,
            function(_, v) vdb().glow.speed = v; cdmRefresh() end, glDis)
        gl.thickness = ACH:Range("Thickness", "Pixel only.", 6, { min = 1, max = 8, step = 1 }, nil,
            function() return vdb().glow.thickness end,
            function(_, v) vdb().glow.thickness = v; cdmRefresh() end,
            function() return glDis() or vdb().glow.type ~= 'pixel' end)
        gl.particles = ACH:Range("Particles", "Autocast only.", 7, { min = 1, max = 16, step = 1 }, nil,
            function() return vdb().glow.particles end,
            function(_, v) vdb().glow.particles = v; cdmRefresh() end,
            function() return glDis() or vdb().glow.type ~= 'autocast' end)
        gl.scale = ACH:Range("Scale", "Autocast only.", 8, { min = 0.5, max = 3, step = 0.1 }, nil,
            function() return vdb().glow.scale end,
            function(_, v) vdb().glow.scale = v; cdmRefresh() end,
            function() return glDis() or vdb().glow.type ~= 'autocast' end)
    end

    return tab
end

-- Shared builder: buff bar viewer tab
local function BuildBarViewerTab(viewerKey, label, order)
    local vdb = function() return cdmDB().viewers[viewerKey] end
    local tab = ACH:Group(label, nil, order, 'tree', nil, nil, cdmDisabled)

    -- Layout
    tab.args.layout = ACH:Group("Layout", nil, 1)
    local lay = tab.args.layout.args

    lay.barWidth = ACH:Range("Bar Width", nil, 1, { min = 80, max = 400, step = 1 }, nil,
        function() return vdb().barWidth end,
        function(_, v) vdb().barWidth = v; cdmRefresh() end)
    lay.barHeight = ACH:Range("Bar Height", nil, 2, { min = 10, max = 40, step = 1 }, nil,
        function() return vdb().barHeight end,
        function(_, v) vdb().barHeight = v; cdmRefresh() end)
    lay.spacing = ACH:Range("Bar Spacing", nil, 3, { min = 0, max = 20, step = 1 }, nil,
        function() return vdb().spacing end,
        function(_, v) vdb().spacing = v; cdmRefresh() end)
    lay.showIcon = ACH:Toggle("Show Icon", nil, 4, nil, nil, nil,
        function() return vdb().showIcon end,
        function(_, v) vdb().showIcon = v; cdmRefresh() end)
    lay.iconGap = ACH:Range("Icon Gap", nil, 5, { min = 0, max = 10, step = 1 }, nil,
        function() return vdb().iconGap end,
        function(_, v) vdb().iconGap = v; cdmRefresh() end,
        function() return not vdb().showIcon end)
    lay.showSpark = ACH:Toggle("Show Spark", nil, 6, nil, nil, nil,
        function() return vdb().showSpark end,
        function(_, v) vdb().showSpark = v; cdmRefresh() end)
    lay.mirroredColumns = ACH:Toggle("Mirrored Columns", nil, 7, nil, nil, nil,
        function() return vdb().mirroredColumns end,
        function(_, v) vdb().mirroredColumns = v; cdmRefresh() end)
    lay.columnGap = ACH:Range("Column Gap", nil, 8, { min = 0, max = 20, step = 1 }, nil,
        function() return vdb().columnGap end,
        function(_, v) vdb().columnGap = v; cdmRefresh() end,
        function() return not vdb().mirroredColumns end)
    lay.growthDirection = ACH:Select("Vertical Growth", nil, 9, { DOWN = 'Down', UP = 'Up' }, nil, nil,
        function() return vdb().growthDirection end,
        function(_, v) vdb().growthDirection = v; cdmRefresh() end)

    -- Visibility
    tab.args.visibility = ACH:Group("Visibility", nil, 2)
    local vis = tab.args.visibility.args

    vis.visibleSetting = ACH:Select("When to Show", nil, 1, VIS_OPTIONS, nil, nil,
        function() return vdb().visibleSetting end,
        function(_, v) vdb().visibleSetting = v; local CDM = getCDM(); if CDM then CDM:UpdateCDMVisibility() end end)
    vis.hideWhenInactive = ACH:Toggle("Hide When Inactive", nil, 2, nil, nil, nil,
        function() return vdb().hideWhenInactive end,
        function(_, v) vdb().hideWhenInactive = v; E:StaticPopup_Show('CONFIG_RL') end)
    vis.showTooltips = ACH:Toggle("Show Tooltips", nil, 3, nil, nil, nil,
        function() return vdb().showTooltips end,
        function(_, v)
            vdb().showTooltips = v
            local CDM = getCDM(); if CDM and Enum.EditModeCooldownViewerSetting then
                CDM:SetEditModeSetting(viewerKey, Enum.EditModeCooldownViewerSetting.ShowTooltips, v and 1 or 0)
            end
            E:StaticPopup_Show('CONFIG_RL')
        end)

    -- Textures
    tab.args.textures = ACH:Group("Textures", nil, 3)
    local tex = tab.args.textures.args

    tex.foregroundTexture = ACH:SharedMediaStatusbar("Foreground", nil, 1, nil,
        function() return vdb().foregroundTexture end,
        function(_, v) vdb().foregroundTexture = v; cdmRefresh() end)
    tex.backgroundTexture = ACH:SharedMediaStatusbar("Background", nil, 2, nil,
        function() return vdb().backgroundTexture end,
        function(_, v) vdb().backgroundTexture = v; cdmRefresh() end)

    -- Name Text
    tab.args.nameText = BuildTextGroup("Name Text", 4, function() return vdb().nameText end)
    tab.args.nameText.args.enable = ACH:Toggle(
        function() return vdb().showName ~= false and "|cff00ff00Show|r" or "Show" end,
        nil, 0, nil, nil, nil,
        function() return vdb().showName ~= false end,
        function(_, v) vdb().showName = v; cdmRefresh() end)

    -- Duration Text
    tab.args.durationText = BuildTextGroup("Duration Text", 5, function() return vdb().durationText end)
    tab.args.durationText.args.enable = ACH:Toggle(
        function() return vdb().showTimer ~= false and "|cff00ff00Show|r" or "Show" end,
        nil, 0, nil, nil, nil,
        function() return vdb().showTimer ~= false end,
        function(_, v) vdb().showTimer = v; cdmRefresh() end)

    -- Stacks Text
    tab.args.stacksText = BuildTextGroup("Stacks Text", 6, function() return vdb().stacksText end)
    tab.args.stacksText.args.enable = ACH:Toggle(
        function() return vdb().showStacks ~= false and "|cff00ff00Show|r" or "Show" end,
        nil, 0, nil, nil, nil,
        function() return vdb().showStacks ~= false end,
        function(_, v) vdb().showStacks = v; cdmRefresh() end)

    return tab
end

function TUI:BuildCooldownManagerConfig(root, tuiName)
    root.cooldownManager = ACH:Group("CDM", nil, 2.5, 'tab')

    -- General (always visible)
    root.cooldownManager.args.general = ACH:Group("General", nil, 1)
    root.cooldownManager.args.general.inline = true
    local gen = root.cooldownManager.args.general.args

    gen.desc = ACH:Description(
        "Reparents Blizzard's CDM icons into TUI containers with ElvUI movers. "
        .. "Overrides ElvUI's CDM text styling with per-viewer font settings."
        .. "\n\nRequires Blizzard's Cooldown Manager to be enabled (Options > Gameplay Enhancements > Enable Cooldown Manager).",
        1, "medium")
    gen.enabled = ACH:Toggle(
        function() return cdmDB().enabled and "|cff00ff00Enable|r" or "Enable" end,
        nil, 2, nil, nil, nil,
        function() return cdmDB().enabled end,
        function(_, v) cdmDB().enabled = v; E:StaticPopup_Show('CONFIG_RL') end)
    gen.previewText = ACH:Toggle(
        function()
            local CDM = getCDM()
            return CDM and CDM.previewActive and "|cff00ff00Preview Text|r" or "Preview Text"
        end,
        "Show sample text on icons to preview font settings.", 3, nil, nil, nil,
        function() local CDM = getCDM(); return CDM and CDM.previewActive end,
        function()
            local CDM = getCDM()
            if not CDM then return end
            if CDM.previewActive then CDM.HidePreview() else CDM.ShowPreview() end
        end, cdmDisabled)
    gen.hideSwipe = ACH:Toggle("Hide GCD Swipe", nil, 4, nil, nil, nil,
        function() return cdmDB().hideSwipe end,
        function(_, v) cdmDB().hideSwipe = v; cdmRefresh() end, cdmDisabled)

    -- Per-viewer tabs
    root.cooldownManager.args.buffIcon  = BuildIconViewerTab('buffIcon',  'Buff Icons',  2)
    root.cooldownManager.args.essential = BuildIconViewerTab('essential', 'Essential',    3)
    root.cooldownManager.args.utility   = BuildIconViewerTab('utility',   'Utility',      4)
    root.cooldownManager.args.buffBar   = BuildBarViewerTab('buffBar',    'Buff Bars',    5)

    -- Custom Tracker tab
    local customVDB = function() return cdmDB().viewers.custom end
    local customTab = ACH:Group("Custom", nil, 6, 'tree', nil, nil, cdmDisabled)
    root.cooldownManager.args.custom = customTab

    -- Custom: General
    customTab.args.general = ACH:Group("General", nil, 1)
    local ct = customTab.args.general.args

    ct.enabled = ACH:Toggle(
        function() return customVDB().enabled and "|cff00ff00Enable|r" or "Enable" end,
        nil, 1, nil, nil, nil,
        function() return customVDB().enabled end,
        function(_, v) customVDB().enabled = v; E:StaticPopup_Show('CONFIG_RL') end)
    local ctDis = function() return not customVDB().enabled end
    ct.showRacials = ACH:Toggle("Show Racials", nil, 2, nil, nil, nil,
        function() return customVDB().showRacials end,
        function(_, v) customVDB().showRacials = v; cdmRefresh() end, ctDis)
    ct.showHealthstone = ACH:Toggle("Show Healthstone", nil, 3, nil, nil, nil,
        function() return customVDB().showHealthstone end,
        function(_, v) customVDB().showHealthstone = v; cdmRefresh() end, ctDis)
    ct.showPotions = ACH:Toggle("Show Healing Potions", nil, 4, nil, nil, nil,
        function() return customVDB().showPotions end,
        function(_, v) customVDB().showPotions = v; cdmRefresh() end, ctDis)
    ct.showCombatPotions = ACH:Toggle("Show Combat Potions", nil, 5, nil, nil, nil,
        function() return customVDB().showCombatPotions end,
        function(_, v) customVDB().showCombatPotions = v; cdmRefresh() end, ctDis)
    ct.showBeltTinker = ACH:Toggle(E.NewSign .. "Show Belt Tinker", "Track belt on-use tinker cooldown.", 6, nil, nil, nil,
        function() return customVDB().showBeltTinker end,
        function(_, v) customVDB().showBeltTinker = v; cdmRefresh() end, ctDis)
    ct.trinketMode = ACH:Select("Trinkets", nil, 7,
        { both = 'Both', slot1 = 'Trinket 1', slot2 = 'Trinket 2', none = 'None' }, nil, nil,
        function() return customVDB().trinketMode end,
        function(_, v) customVDB().trinketMode = v; cdmRefresh() end, ctDis)
    ct.trinketMode.sorting = { 'both', 'slot1', 'slot2', 'none' }

    -- Custom: Layout
    customTab.args.layout = ACH:Group("Layout", nil, 2)
    local cLay = customTab.args.layout.args

    cLay.keepSizeRatio = ACH:Toggle("Keep Size Ratio", nil, 1, nil, nil, nil,
        function() return customVDB().keepSizeRatio end,
        function(_, v) customVDB().keepSizeRatio = v; cdmRefresh() end, ctDis)
    cLay.iconWidth = ACH:Range(
        function() return customVDB().keepSizeRatio and "Icon Size" or "Icon Width" end, nil, 2,
        { min = 16, max = 80, step = 1 }, nil,
        function() return customVDB().iconWidth end,
        function(_, v) customVDB().iconWidth = v; cdmRefresh() end, ctDis)
    cLay.iconHeight = ACH:Range("Icon Height", nil, 3, { min = 16, max = 80, step = 1 }, nil,
        function() return customVDB().iconHeight end,
        function(_, v) customVDB().iconHeight = v; cdmRefresh() end, ctDis)
    cLay.iconHeight.hidden = function() return customVDB().keepSizeRatio end
    cLay.iconZoom = ACH:Range("Icon Zoom", nil, 4,
        { min = 0, max = 0.60, step = 0.01, isPercent = true }, nil,
        function() return customVDB().iconZoom end,
        function(_, v) customVDB().iconZoom = v; cdmRefresh() end, ctDis)
    cLay.spacing = ACH:Range("Spacing", nil, 5, { min = 0, max = 20, step = 1 }, nil,
        function() return customVDB().spacing end,
        function(_, v) customVDB().spacing = v; cdmRefresh() end, ctDis)
    cLay.iconsPerRow = ACH:Range("Icons Per Row", nil, 6, { min = 1, max = 20, step = 1 }, nil,
        function() return customVDB().iconsPerRow end,
        function(_, v) customVDB().iconsPerRow = v; cdmRefresh() end, ctDis)
    cLay.growthDirection = ACH:Select("Growth Direction", nil, 7,
        { CENTER = 'Center', LEFT = 'Left', RIGHT = 'Right', UP = 'Up', DOWN = 'Down' }, nil, nil,
        function() return customVDB().growthDirection end,
        function(_, v) customVDB().growthDirection = v; E:StaticPopup_Show('CONFIG_RL') end, ctDis)
    cLay.growthDirection.sorting = { 'CENTER', 'LEFT', 'RIGHT', 'UP', 'DOWN' }

    -- Custom: Visibility
    customTab.args.visibility = ACH:Group("Visibility", nil, 3)
    local cVis = customTab.args.visibility.args

    cVis.visibleSetting = ACH:Select("When to Show", nil, 1, VIS_OPTIONS, nil, nil,
        function() return customVDB().visibleSetting end,
        function(_, v) customVDB().visibleSetting = v; local CDM = getCDM(); if CDM then CDM:UpdateCDMVisibility() end end, ctDis)
    cVis.showTooltips = ACH:Toggle("Show Tooltips", nil, 2, nil, nil, nil,
        function() return customVDB().showTooltips end,
        function(_, v) customVDB().showTooltips = v end, ctDis)

    -- Custom: Text
    customTab.args.cooldownText = BuildTextGroup("Cooldown Text", 4, function() return customVDB().cooldownText end)
    customTab.args.countText = BuildTextGroup("Count Text", 5, function() return customVDB().countText end)
end
