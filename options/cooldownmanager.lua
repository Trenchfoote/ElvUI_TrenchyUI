local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local ACH = E.Libs.ACH

function TUI:BuildCooldownManagerConfig(root, tuiName)
    root.cooldownManager = ACH:Group("CDM", nil, 2.5)

    local cdmDB = function() return TUI.db.profile.cooldownManager end
    local cdmDisabled = function() return not cdmDB().enabled end
    local cdmRefresh = function()
        if TUI.RefreshCDM then TUI:RefreshCDM() end
    end
    local selVDB = function() return cdmDB().viewers[cdmDB().selectedViewer] end

    local VIEWER_CHOICES_ORDER = { 'buffIcon', 'essential', 'utility', 'buffBar', 'custom' }
    local VIEWER_CHOICES = { essential = 'Essential', utility = 'Utility', buffIcon = 'Buff Icon', buffBar = 'Buff Bar', custom = 'Custom Tracker' }
    local isBarViewer = function() return cdmDB().selectedViewer == 'buffBar' end
    local isIconViewer = function() return cdmDB().selectedViewer ~= 'buffBar' end
    local isCustomViewer = function() return cdmDB().selectedViewer == 'custom' end
    local isNotCustomViewer = function() return cdmDB().selectedViewer ~= 'custom' end
    local POSITIONS = { CENTER = 'Center', TOP = 'Top', BOTTOM = 'Bottom', LEFT = 'Left', RIGHT = 'Right',
        TOPLEFT = 'Top Left', TOPRIGHT = 'Top Right', BOTTOMLEFT = 'Bottom Left', BOTTOMRIGHT = 'Bottom Right' }

    -- General
    root.cooldownManager.args.general = ACH:Group("General", nil, 1)
    root.cooldownManager.args.general.inline = true
    local cdmGen = root.cooldownManager.args.general.args

    cdmGen.desc = ACH:Description(
        "Reparents Blizzard's CDM icons into TUI containers with ElvUI movers. "
        .. "Overrides ElvUI's CDM text styling with per-viewer font settings."
        .. "\n\nRequires Blizzard's Cooldown Manager to be enabled (Options > Gameplay Enhancements > Enable Cooldown Manager).",
        1, "medium"
    )

    cdmGen.enabled = ACH:Toggle(
        function() return cdmDB().enabled and "|cff00ff00Enable|r" or "Enable" end,
        "Enable TrenchyUI Cooldown Manager customizations.",
        2, nil, nil, nil,
        function() return cdmDB().enabled end,
        function(_, value)
            cdmDB().enabled = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )

    cdmGen.previewText = ACH:Toggle(
        function()
            local S = TUI._cdm
            return S and S.previewActive and "|cff00ff00Preview Text|r" or "Preview Text"
        end,
        "Show sample text on all CDM icons to preview font, size, and position settings.",
        2.5, nil, nil, nil,
        function() local S = TUI._cdm; return S and S.previewActive end,
        function()
            local S = TUI._cdm
            if not S then return end
            if S.previewActive then S.HidePreview() else S.ShowPreview() end
        end,
        cdmDisabled
    )

    cdmGen.hideSwipe = ACH:Toggle(
        "Hide GCD Swipe", "Hide the cooldown swipe overlay on CDM icons.",
        3, nil, nil, nil,
        function() return cdmDB().hideSwipe end,
        function(_, value) cdmDB().hideSwipe = value; cdmRefresh() end,
        cdmDisabled
    )
    cdmGen.hideSwipe.hidden = isBarViewer

    -- Viewer
    root.cooldownManager.args.viewer = ACH:Group("Viewer", nil, 2, nil, nil, nil, cdmDisabled)
    root.cooldownManager.args.viewer.inline = true
    local cdmViewer = root.cooldownManager.args.viewer.args

    cdmViewer.selectedViewer = ACH:Select(
        "Viewer", "Select which CDM viewer to configure.", 1,
        VIEWER_CHOICES, nil, nil,
        function() return cdmDB().selectedViewer end,
        function(_, value)
            cdmDB().selectedViewer = value
        end
    )
    cdmViewer.selectedViewer.sorting = VIEWER_CHOICES_ORDER

    -- Layout group
    cdmViewer.layout = ACH:Group("Layout", nil, 3)
    cdmViewer.layout.inline = true
    local cdmLayout = cdmViewer.layout.args

    cdmLayout.keepSizeRatio = ACH:Toggle("Keep Size Ratio", nil, 1, nil, nil, nil,
        function() return selVDB().keepSizeRatio end,
        function(_, value) selVDB().keepSizeRatio = value; cdmRefresh() end
    )
    cdmLayout.keepSizeRatio.hidden = isBarViewer

    cdmLayout.iconWidth = ACH:Range(
        function() return selVDB().keepSizeRatio and "Icon Size" or "Icon Width" end, nil, 2,
        { min = 16, max = 80, step = 1 }, nil,
        function() return selVDB().iconWidth end,
        function(_, value) selVDB().iconWidth = value; cdmRefresh() end
    )
    cdmLayout.iconWidth.hidden = isBarViewer

    cdmLayout.iconHeight = ACH:Range(
        "Icon Height", nil, 3,
        { min = 16, max = 80, step = 1 }, nil,
        function() return selVDB().iconHeight end,
        function(_, value) selVDB().iconHeight = value; cdmRefresh() end
    )
    cdmLayout.iconHeight.hidden = function() return isBarViewer() or selVDB().keepSizeRatio end

    cdmLayout.iconZoom = ACH:Range(
        "Icon Zoom", "Crop the icon texture inward.", 4,
        { min = 0, max = 0.60, step = 0.01, isPercent = true }, nil,
        function() return selVDB().iconZoom end,
        function(_, value) selVDB().iconZoom = value; cdmRefresh() end
    )
    cdmLayout.iconZoom.hidden = isBarViewer

    cdmLayout.barWidth = ACH:Range(
        "Bar Width", nil, 1.1,
        { min = 80, max = 400, step = 1 }, nil,
        function() return selVDB().barWidth end,
        function(_, value) selVDB().barWidth = value; cdmRefresh() end
    )
    cdmLayout.barWidth.hidden = isIconViewer

    cdmLayout.barHeight = ACH:Range(
        "Bar Height", nil, 1.2,
        { min = 10, max = 40, step = 1 }, nil,
        function() return selVDB().barHeight end,
        function(_, value) selVDB().barHeight = value; cdmRefresh() end
    )
    cdmLayout.barHeight.hidden = isIconViewer

    cdmLayout.spacing = ACH:Range(
        function() return isBarViewer() and "Bar Spacing" or "Spacing" end,
        function() return isBarViewer() and "Gap between bars in pixels." or "Gap between icons in pixels." end, 5,
        { min = 0, max = 20, step = 1 }, nil,
        function() return selVDB().spacing end,
        function(_, value) selVDB().spacing = value; cdmRefresh() end
    )

    cdmLayout.showIcon = ACH:Toggle("Show Icon", nil, 6, nil, nil, nil,
        function() return selVDB().showIcon end,
        function(_, value) selVDB().showIcon = value; cdmRefresh() end
    )
    cdmLayout.showIcon.hidden = isIconViewer

    cdmLayout.iconGap = ACH:Range(
        "Icon Gap", "Space between icon and bar.", 6.1,
        { min = 0, max = 10, step = 1 }, nil,
        function() return selVDB().iconGap end,
        function(_, value) selVDB().iconGap = value; cdmRefresh() end,
        function() return not selVDB().showIcon end
    )
    cdmLayout.iconGap.hidden = isIconViewer

    cdmLayout.showSpark = ACH:Toggle("Show Spark", "Show the bright edge indicator on bars.", 7, nil, nil, nil,
        function() return selVDB().showSpark end,
        function(_, value) selVDB().showSpark = value; cdmRefresh() end
    )
    cdmLayout.showSpark.hidden = isIconViewer

    cdmLayout.mirroredColumns = ACH:Toggle("Mirrored Columns", "Split bars into two mirrored columns.", 8, nil, nil, nil,
        function() return selVDB().mirroredColumns end,
        function(_, value) selVDB().mirroredColumns = value; cdmRefresh() end
    )
    cdmLayout.mirroredColumns.hidden = isIconViewer

    cdmLayout.columnGap = ACH:Range(
        "Column Gap", "Space between the two columns.", 8.1,
        { min = 0, max = 20, step = 1 }, nil,
        function() return selVDB().columnGap end,
        function(_, value) selVDB().columnGap = value; cdmRefresh() end,
        function() return not selVDB().mirroredColumns end
    )
    cdmLayout.columnGap.hidden = isIconViewer

    cdmLayout.iconsPerRow = ACH:Range(
        "Icons Per Row", nil, 6,
        { min = 1, max = 20, step = 1 }, nil,
        function() return selVDB().iconsPerRow end,
        function(_, value) selVDB().iconsPerRow = value; cdmRefresh() end
    )
    cdmLayout.iconsPerRow.hidden = isBarViewer

    cdmLayout.growthDirection = ACH:Select(
        "Vertical Growth", nil, 10,
        { DOWN = 'Down', UP = 'Up' },
        nil, nil,
        function() return selVDB().growthDirection end,
        function(_, value) selVDB().growthDirection = value; cdmRefresh() end
    )
    cdmLayout.growthDirection.hidden = isCustomViewer

    cdmLayout.customGrowth = ACH:Select(
        "Growth Direction", "Direction icons grow from the mover. Center distributes evenly.", 10,
        { CENTER = 'Center', LEFT = 'Left', RIGHT = 'Right', UP = 'Up', DOWN = 'Down' },
        nil, nil,
        function() return selVDB().growthDirection end,
        function(_, value) selVDB().growthDirection = value; E:StaticPopup_Show('CONFIG_RL') end
    )
    cdmLayout.customGrowth.sorting = { 'CENTER', 'LEFT', 'RIGHT', 'UP', 'DOWN' }
    cdmLayout.customGrowth.hidden = isNotCustomViewer

    cdmLayout.visibleSetting = ACH:Select(
        "Visibility", "When to show this viewer. 'Player Fader' mirrors the player unitframe's fader alpha.", 11,
        { ALWAYS = 'Always', INCOMBAT = 'In Combat', FADER = 'Player Fader', HIDDEN = 'Hidden' },
        nil, nil,
        function() return selVDB().visibleSetting end,
        function(_, value)
            selVDB().visibleSetting = value
            if TUI.UpdateCDMVisibility then TUI:UpdateCDMVisibility() end
        end
    )

    cdmLayout.hideWhenInactive = ACH:Toggle(
        "Hide When Inactive",
        "Hide when no buff icons are active.",
        12, nil, nil, nil,
        function() return selVDB().hideWhenInactive end,
        function(_, value)
            selVDB().hideWhenInactive = value
            local v = cdmDB().selectedViewer
            if (v == 'buffIcon' or v == 'buffBar') and TUI.SetEditModeSetting and Enum.EditModeCooldownViewerSetting then
                TUI:SetEditModeSetting(v, Enum.EditModeCooldownViewerSetting.HideWhenInactive, value and 1 or 0)
            end
            E:StaticPopup_Show('CONFIG_RL')
        end
    )
    cdmLayout.hideWhenInactive.hidden = function()
        local v = cdmDB().selectedViewer
        return v ~= 'buffIcon'
    end

    cdmLayout.showTooltips = ACH:Toggle(
        "Show Tooltips", "Show spell tooltips when hovering over icons or bars.", 13, nil, nil, nil,
        function() return selVDB().showTooltips end,
        function(_, value)
            selVDB().showTooltips = value
            local v = cdmDB().selectedViewer
            if v ~= 'custom' and TUI.SetEditModeSetting and Enum.EditModeCooldownViewerSetting then
                TUI:SetEditModeSetting(v, Enum.EditModeCooldownViewerSetting.ShowTooltips, value and 1 or 0)
            end
            if v ~= 'custom' then E:StaticPopup_Show('CONFIG_RL') end
        end
    )

    cdmLayout.showKeybind = ACH:Toggle(
        "Show Keybind", "Display the spell's keybind text on the icon.",
        14, nil, nil, nil,
        function() return selVDB().showKeybind end,
        function(_, value) selVDB().showKeybind = value; cdmRefresh() end
    )
    cdmLayout.showKeybind.hidden = function()
        local v = cdmDB().selectedViewer
        return v ~= 'essential' and v ~= 'utility'
    end

    -- Custom Tracker options (only shown when custom viewer is selected)
    cdmViewer.customTracker = ACH:Group("Custom Tracker", nil, 2.5)
    cdmViewer.customTracker.inline = true
    cdmViewer.customTracker.hidden = isNotCustomViewer
    local cdmCustom = cdmViewer.customTracker.args

    cdmCustom.enabled = ACH:Toggle(
        function() return selVDB().enabled and "|cff00ff00Enable|r" or "Enable" end,
        "Enable the Custom Tracker viewer. Tracks racials, healthstones, and trinkets independently of Blizzard's Cooldown Manager.",
        1, nil, nil, nil,
        function() return selVDB().enabled end,
        function(_, value) selVDB().enabled = value; E:StaticPopup_Show('CONFIG_RL') end
    )

    cdmCustom.showRacials = ACH:Toggle(
        "Show Racials", "Track your racial ability cooldown.", 2, nil, nil, nil,
        function() return selVDB().showRacials end,
        function(_, value) selVDB().showRacials = value; cdmRefresh() end,
        function() return not selVDB().enabled end
    )

    cdmCustom.showHealthstone = ACH:Toggle(
        "Show Healthstone", "Track healthstone cooldown and count.", 3, nil, nil, nil,
        function() return selVDB().showHealthstone end,
        function(_, value) selVDB().showHealthstone = value; cdmRefresh() end,
        function() return not selVDB().enabled end
    )

    cdmCustom.showPotions = ACH:Toggle(
        "Show Healing Potions", "Track Midnight healing potion cooldowns.", 3.5, nil, nil, nil,
        function() return selVDB().showPotions end,
        function(_, value) selVDB().showPotions = value; cdmRefresh() end,
        function() return not selVDB().enabled end
    )

    cdmCustom.showCombatPotions = ACH:Toggle(
        "Show Combat Potions", "Track Midnight combat potion cooldowns.", 3.6, nil, nil, nil,
        function() return selVDB().showCombatPotions end,
        function(_, value) selVDB().showCombatPotions = value; cdmRefresh() end,
        function() return not selVDB().enabled end
    )

    cdmCustom.trinketMode = ACH:Select(
        "Trinkets", "Which trinkets to track.", 4,
        { both = 'Both', slot1 = 'Trinket 1', slot2 = 'Trinket 2', none = 'None' },
        nil, nil,
        function() return selVDB().trinketMode end,
        function(_, value) selVDB().trinketMode = value; cdmRefresh() end,
        function() return not selVDB().enabled end
    )
    cdmCustom.trinketMode.sorting = { 'both', 'slot1', 'slot2', 'none' }

    -- Cooldown Text group (icon viewers only)
    cdmViewer.cooldownText = ACH:Group("Cooldown Text", nil, 4)
    cdmViewer.cooldownText.inline = true
    cdmViewer.cooldownText.hidden = isBarViewer
    local cdmCD = cdmViewer.cooldownText.args

    cdmCD.font = ACH:SharedMediaFont("Font", nil, 1, nil,
        function() return selVDB().cooldownText.font end,
        function(_, value) selVDB().cooldownText.font = value; cdmRefresh() end
    )

    cdmCD.fontSize = ACH:Range(
        "Font Size", nil, 2,
        { min = 6, max = 36, step = 1 }, nil,
        function() return selVDB().cooldownText.fontSize end,
        function(_, value) selVDB().cooldownText.fontSize = value; cdmRefresh() end
    )

    cdmCD.fontOutline = ACH:FontFlags(
        "Font Outline", nil, 3, nil,
        function() return selVDB().cooldownText.fontOutline end,
        function(_, value) selVDB().cooldownText.fontOutline = value; cdmRefresh() end
    )

    cdmCD.classColor = ACH:Toggle(
        "Class Color", "Use custom class color.", 4, nil, nil, nil,
        function() return selVDB().cooldownText.classColor end,
        function(_, value) selVDB().cooldownText.classColor = value; cdmRefresh() end
    )

    cdmCD.color = ACH:Color(
        "Color", nil, 5, nil, nil,
        function()
            local c = selVDB().cooldownText.color
            return c.r, c.g, c.b
        end,
        function(_, r, g, b)
            local c = selVDB().cooldownText.color
            c.r, c.g, c.b = r, g, b
            cdmRefresh()
        end,
        function() return selVDB().cooldownText.classColor end
    )

    cdmCD.position = ACH:Select(
        "Position", nil, 6, POSITIONS, nil, nil,
        function() return selVDB().cooldownText.position end,
        function(_, value) selVDB().cooldownText.position = value; cdmRefresh() end
    )

    cdmCD.xOffset = ACH:Range(
        "X-Offset", nil, 7,
        { min = -45, max = 45, step = 1 }, nil,
        function() return selVDB().cooldownText.xOffset end,
        function(_, value) selVDB().cooldownText.xOffset = value; cdmRefresh() end
    )

    cdmCD.yOffset = ACH:Range(
        "Y-Offset", nil, 8,
        { min = -45, max = 45, step = 1 }, nil,
        function() return selVDB().cooldownText.yOffset end,
        function(_, value) selVDB().cooldownText.yOffset = value; cdmRefresh() end
    )

    -- Count Text group (icon viewers only)
    cdmViewer.countText = ACH:Group("Count Text", nil, 5)
    cdmViewer.countText.inline = true
    cdmViewer.countText.hidden = isBarViewer
    local cdmCT = cdmViewer.countText.args

    cdmCT.font = ACH:SharedMediaFont("Font", nil, 1, nil,
        function() return selVDB().countText.font end,
        function(_, value) selVDB().countText.font = value; cdmRefresh() end
    )

    cdmCT.fontSize = ACH:Range(
        "Font Size", nil, 2,
        { min = 6, max = 36, step = 1 }, nil,
        function() return selVDB().countText.fontSize end,
        function(_, value) selVDB().countText.fontSize = value; cdmRefresh() end
    )

    cdmCT.fontOutline = ACH:FontFlags(
        "Font Outline", nil, 3, nil,
        function() return selVDB().countText.fontOutline end,
        function(_, value) selVDB().countText.fontOutline = value; cdmRefresh() end
    )

    cdmCT.classColor = ACH:Toggle(
        "Class Color", "Use custom class color.", 4, nil, nil, nil,
        function() return selVDB().countText.classColor end,
        function(_, value) selVDB().countText.classColor = value; cdmRefresh() end
    )

    cdmCT.color = ACH:Color(
        "Color", nil, 5, nil, nil,
        function()
            local c = selVDB().countText.color
            return c.r, c.g, c.b
        end,
        function(_, r, g, b)
            local c = selVDB().countText.color
            c.r, c.g, c.b = r, g, b
            cdmRefresh()
        end,
        function() return selVDB().countText.classColor end
    )

    cdmCT.position = ACH:Select(
        "Position", nil, 6, POSITIONS, nil, nil,
        function() return selVDB().countText.position end,
        function(_, value) selVDB().countText.position = value; cdmRefresh() end
    )

    cdmCT.xOffset = ACH:Range(
        "X-Offset", nil, 7,
        { min = -45, max = 45, step = 1 }, nil,
        function() return selVDB().countText.xOffset end,
        function(_, value) selVDB().countText.xOffset = value; cdmRefresh() end
    )

    cdmCT.yOffset = ACH:Range(
        "Y-Offset", nil, 8,
        { min = -45, max = 45, step = 1 }, nil,
        function() return selVDB().countText.yOffset end,
        function(_, value) selVDB().countText.yOffset = value; cdmRefresh() end
    )

    -- Keybind Text group — Essential and Utility only
    cdmViewer.keybindText = ACH:Group("Keybind Text", nil, 5.5)
    cdmViewer.keybindText.inline = true
    cdmViewer.keybindText.hidden = function()
        local v = cdmDB().selectedViewer
        return (v ~= 'essential' and v ~= 'utility') or not selVDB().showKeybind
    end
    local cdmKB = cdmViewer.keybindText.args

    cdmKB.font = ACH:SharedMediaFont("Font", nil, 1, nil,
        function() return selVDB().keybindText.font end,
        function(_, value) selVDB().keybindText.font = value; cdmRefresh() end
    )

    cdmKB.fontSize = ACH:Range(
        "Font Size", nil, 2,
        { min = 6, max = 36, step = 1 }, nil,
        function() return selVDB().keybindText.fontSize end,
        function(_, value) selVDB().keybindText.fontSize = value; cdmRefresh() end
    )

    cdmKB.fontOutline = ACH:FontFlags(
        "Font Outline", nil, 3, nil,
        function() return selVDB().keybindText.fontOutline end,
        function(_, value) selVDB().keybindText.fontOutline = value; cdmRefresh() end
    )

    cdmKB.classColor = ACH:Toggle(
        "Class Color", "Use custom class color.", 4, nil, nil, nil,
        function() return selVDB().keybindText.classColor end,
        function(_, value) selVDB().keybindText.classColor = value; cdmRefresh() end
    )

    cdmKB.color = ACH:Color(
        "Color", nil, 5, nil, nil,
        function()
            local c = selVDB().keybindText.color
            return c.r, c.g, c.b
        end,
        function(_, r, g, b)
            local c = selVDB().keybindText.color
            c.r, c.g, c.b = r, g, b
            cdmRefresh()
        end,
        function() return selVDB().keybindText.classColor end
    )

    cdmKB.position = ACH:Select(
        "Position", nil, 6, POSITIONS, nil, nil,
        function() return selVDB().keybindText.position end,
        function(_, value) selVDB().keybindText.position = value; cdmRefresh() end
    )

    cdmKB.xOffset = ACH:Range(
        "X-Offset", nil, 7,
        { min = -45, max = 45, step = 1 }, nil,
        function() return selVDB().keybindText.xOffset end,
        function(_, value) selVDB().keybindText.xOffset = value; cdmRefresh() end
    )

    cdmKB.yOffset = ACH:Range(
        "Y-Offset", nil, 8,
        { min = -45, max = 45, step = 1 }, nil,
        function() return selVDB().keybindText.yOffset end,
        function(_, value) selVDB().keybindText.yOffset = value; cdmRefresh() end
    )

    -- Proc Glow group — Essential only
    cdmViewer.glow = ACH:Group("Proc Glow", nil, 6)
    cdmViewer.glow.inline = true
    cdmViewer.glow.hidden = function() local v = cdmDB().selectedViewer; return v ~= 'essential' end
    local cdmGlow = cdmViewer.glow.args

    local glowDisabled = function() return not selVDB().glow.enabled end

    cdmGlow.enabled = ACH:Toggle(
        function() return selVDB().glow.enabled and "|cff00ff00Enable|r" or "Enable" end,
        "Apply a glow effect when abilities proc.",
        1, nil, nil, nil,
        function() return selVDB().glow.enabled end,
        function(_, value) selVDB().glow.enabled = value; cdmRefresh() end
    )

    cdmGlow.type = ACH:Select(
        "Type", "Glow animation style.", 2,
        { pixel = 'Pixel', autocast = 'Autocast', button = 'Button', proc = 'Proc' },
        nil, nil,
        function() return selVDB().glow.type end,
        function(_, value) selVDB().glow.type = value; cdmRefresh() end,
        glowDisabled
    )

    cdmGlow.color = ACH:Color(
        "Color", "Glow color.", 3, true, nil,
        function()
            local c = selVDB().glow.color
            return c.r, c.g, c.b, c.a
        end,
        function(_, r, g, b, a)
            local c = selVDB().glow.color
            c.r, c.g, c.b, c.a = r, g, b, a
            cdmRefresh()
        end,
        glowDisabled
    )

    cdmGlow.lines = ACH:Range(
        "Lines", "Number of glow lines (Pixel only).", 4,
        { min = 1, max = 20, step = 1 }, nil,
        function() return selVDB().glow.lines end,
        function(_, value) selVDB().glow.lines = value; cdmRefresh() end,
        function() return glowDisabled() or selVDB().glow.type ~= 'pixel' end
    )

    cdmGlow.speed = ACH:Range(
        "Speed", "Animation speed.", 5,
        { min = 0.05, max = 2, step = 0.05 }, nil,
        function() return selVDB().glow.speed end,
        function(_, value) selVDB().glow.speed = value; cdmRefresh() end,
        glowDisabled
    )

    cdmGlow.thickness = ACH:Range(
        "Thickness", "Line thickness (Pixel only).", 6,
        { min = 1, max = 8, step = 1 }, nil,
        function() return selVDB().glow.thickness end,
        function(_, value) selVDB().glow.thickness = value; cdmRefresh() end,
        function() return glowDisabled() or selVDB().glow.type ~= 'pixel' end
    )

    cdmGlow.particles = ACH:Range(
        "Particles", "Number of particles (Autocast only).", 7,
        { min = 1, max = 16, step = 1 }, nil,
        function() return selVDB().glow.particles end,
        function(_, value) selVDB().glow.particles = value; cdmRefresh() end,
        function() return glowDisabled() or selVDB().glow.type ~= 'autocast' end
    )

    cdmGlow.scale = ACH:Range(
        "Scale", "Glow scale (Autocast only).", 8,
        { min = 0.5, max = 3, step = 0.1 }, nil,
        function() return selVDB().glow.scale end,
        function(_, value) selVDB().glow.scale = value; cdmRefresh() end,
        function() return glowDisabled() or selVDB().glow.type ~= 'autocast' end
    )

    -- Buff Bar: Textures group
    cdmViewer.textures = ACH:Group("Textures", nil, 7)
    cdmViewer.textures.inline = true
    cdmViewer.textures.hidden = isIconViewer
    local cdmTex = cdmViewer.textures.args

    cdmTex.foregroundTexture = ACH:SharedMediaStatusbar("Foreground", nil, 1, nil,
        function() return selVDB().foregroundTexture end,
        function(_, value) selVDB().foregroundTexture = value; cdmRefresh() end
    )

    cdmTex.backgroundTexture = ACH:SharedMediaStatusbar("Background", nil, 2, nil,
        function() return selVDB().backgroundTexture end,
        function(_, value) selVDB().backgroundTexture = value; cdmRefresh() end
    )

    -- Buff Bar: text group builder
    local function BuildBarTextGroup(name, order, dbKey)
        local group = ACH:Group(name, nil, order)
        group.inline = true
        group.hidden = isIconViewer
        local a = group.args
        local getT = function() return selVDB()[dbKey] end

        a.font = ACH:SharedMediaFont("Font", nil, 1, nil,
            function() return getT().font end,
            function(_, v) getT().font = v; cdmRefresh() end
        )
        a.fontSize = ACH:Range("Font Size", nil, 2, { min = 6, max = 36, step = 1 }, nil,
            function() return getT().fontSize end,
            function(_, v) getT().fontSize = v; cdmRefresh() end
        )
        a.fontOutline = ACH:FontFlags("Font Outline", nil, 3, nil,
            function() return getT().fontOutline end,
            function(_, v) getT().fontOutline = v; cdmRefresh() end
        )
        a.classColor = ACH:Toggle("Class Color", nil, 4, nil, nil, nil,
            function() return getT().classColor end,
            function(_, v) getT().classColor = v; cdmRefresh() end
        )
        a.color = ACH:Color("Color", nil, 5, nil, nil,
            function() local c = getT().color; return c.r, c.g, c.b end,
            function(_, r, g, b) local c = getT().color; c.r, c.g, c.b = r, g, b; cdmRefresh() end,
            function() return getT().classColor end
        )
        a.position = ACH:Select("Position", nil, 6, POSITIONS, nil, nil,
            function() return getT().position end,
            function(_, v) getT().position = v; cdmRefresh() end
        )
        a.xOffset = ACH:Range("X-Offset", nil, 7, { min = -45, max = 45, step = 1 }, nil,
            function() return getT().xOffset end,
            function(_, v) getT().xOffset = v; cdmRefresh() end
        )
        a.yOffset = ACH:Range("Y-Offset", nil, 8, { min = -45, max = 45, step = 1 }, nil,
            function() return getT().yOffset end,
            function(_, v) getT().yOffset = v; cdmRefresh() end
        )
        return group
    end

    cdmViewer.nameText = BuildBarTextGroup("Name Text", 8, 'nameText')
    cdmViewer.nameText.args.enable = ACH:Toggle(
        function() return selVDB().showName ~= false and "|cff00ff00Show|r" or "Show" end,
        "Show buff name text on bars.", 0, nil, nil, nil,
        function() return selVDB().showName ~= false end,
        function(_, value) selVDB().showName = value; cdmRefresh() end
    )

    cdmViewer.durationText = BuildBarTextGroup("Duration Text", 9, 'durationText')
    cdmViewer.durationText.args.enable = ACH:Toggle(
        function() return selVDB().showTimer ~= false and "|cff00ff00Show|r" or "Show" end,
        "Show remaining duration text on bars.", 0, nil, nil, nil,
        function() return selVDB().showTimer ~= false end,
        function(_, value) selVDB().showTimer = value; cdmRefresh() end
    )
    cdmViewer.stacksText = BuildBarTextGroup("Stacks Text", 10, 'stacksText')
    cdmViewer.stacksText.args.enable = ACH:Toggle(
        function() return selVDB().showStacks ~= false and "|cff00ff00Show|r" or "Show" end,
        "Show stack count on bars for buffs with multiple applications.", 0, nil, nil, nil,
        function() return selVDB().showStacks ~= false end,
        function(_, value) selVDB().showStacks = value; cdmRefresh() end
    )
    cdmViewer.stacksText.hidden = isIconViewer
end
