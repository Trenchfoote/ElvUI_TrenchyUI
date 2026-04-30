local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local ACH = E.Libs.ACH

function TUI:BuildQoLConfig(root, tuiName)
    local QOL = E:GetModule('TUI_QoL', true)
    root.qol = ACH:Group("QoL", nil, 1, 'tree')

    -- General
    root.qol.args.general = ACH:Group("General", nil, 1)
    local qolGen = root.qol.args.general.args

    qolGen.hideTalkingHead = ACH:Toggle("Hide Talking Head", "Permanently suppress the Talking Head popup.", 1, nil, nil, nil,
        function() return TUI.db.profile.qol.hideTalkingHead end,
        function(_, v) TUI.db.profile.qol.hideTalkingHead = v; E:StaticPopup_Show('CONFIG_RL') end)

    qolGen.autoFillDelete = ACH:Toggle("Auto-fill Delete", "Automatically type DELETE in the item destruction popup.", 2, nil, nil, nil,
        function() return TUI.db.profile.qol.autoFillDelete end,
        function(_, v) TUI.db.profile.qol.autoFillDelete = v; E:StaticPopup_Show('CONFIG_RL') end)

    qolGen.moveableFrames = ACH:Toggle("Moveable Frames", "Click and drag most Blizzard and addon frames to reposition.", 3, nil, nil, nil,
        function() return TUI.db.profile.qol.moveableFrames end,
        function(_, v) TUI.db.profile.qol.moveableFrames = v; E:StaticPopup_Show('CONFIG_RL') end)

    qolGen.fastLoot = ACH:Toggle("Fast Loot", "Instantly loot all items, skipping the default pickup delay.", 4, nil, nil, nil,
        function() return TUI.db.profile.qol.fastLoot end,
        function(_, v) TUI.db.profile.qol.fastLoot = v; E:StaticPopup_Show('CONFIG_RL') end)

    qolGen.hideObjectiveInCombat = ACH:Toggle("Hide Objectives in Combat", "Hide the objective tracker during combat.", 5, nil, nil, nil,
        function() return TUI.db.profile.qol.hideObjectiveInCombat end,
        function(_, v) TUI.db.profile.qol.hideObjectiveInCombat = v; E:StaticPopup_Show('CONFIG_RL') end)

    qolGen.shortenEnchantStrings = ACH:Toggle("Shorten Enchant Names", "Abbreviate enchant names on character and inspect frames.", 6, nil, nil, nil,
        function() return TUI.db.profile.qol.shortenEnchantStrings end,
        function(_, v) TUI.db.profile.qol.shortenEnchantStrings = v; E:StaticPopup_Show('CONFIG_RL') end)

    -- Cursor Circle
    root.qol.args.cursorCircle = ACH:Group("Cursor Circle", nil, 2)
    local ccArgs = root.qol.args.cursorCircle.args

    ccArgs.enabled = ACH:Toggle(
        function() return TUI.db.profile.qol.cursorCircle and "|cff00ff00Enable|r" or "Enable" end,
        "Show a circle around the cursor.", 1, nil, nil, nil,
        function() return TUI.db.profile.qol.cursorCircle end,
        function(_, v) TUI.db.profile.qol.cursorCircle = v; if QOL then QOL:ToggleCursorCircle(v) end end)

    local ccDisabled = function() return not TUI.db.profile.qol.cursorCircle end

    ccArgs.size = ACH:Range("Size", nil, 2, { min = 16, max = 256, step = 1 }, nil,
        function() return TUI.db.profile.qol.cursorCircleSize end,
        function(_, v) TUI.db.profile.qol.cursorCircleSize = v; if QOL then QOL:UpdateCursorCircle() end end, ccDisabled)

    ccArgs.thickness = ACH:Select("Thickness", nil, 3, { thin = 'Thin', medium = 'Medium', thick = 'Thick' }, nil, nil,
        function() return TUI.db.profile.qol.cursorCircleThickness end,
        function(_, v) TUI.db.profile.qol.cursorCircleThickness = v; if QOL then QOL:UpdateCursorCircle() end end, ccDisabled)
    ccArgs.thickness.sorting = { 'thin', 'medium', 'thick' }

    ccArgs.classColor = ACH:Toggle("Class Color", nil, 4, nil, nil, nil,
        function() return TUI.db.profile.qol.cursorCircleClassColor end,
        function(_, v) TUI.db.profile.qol.cursorCircleClassColor = v; if QOL then QOL:UpdateCursorCircle() end end, ccDisabled)

    ccArgs.color = ACH:Color("Color", nil, 5, true, nil,
        function() local c = TUI.db.profile.qol.cursorCircleColor; return c.r, c.g, c.b, c.a end,
        function(_, r, g, b, a) local c = TUI.db.profile.qol.cursorCircleColor; c.r, c.g, c.b, c.a = r, g, b, a; if QOL then QOL:UpdateCursorCircle() end end,
        function() return ccDisabled() or TUI.db.profile.qol.cursorCircleClassColor end)

    -- Instance Difficulty
    root.qol.args.difficulty = ACH:Group("Instance Difficulty", nil, 3)
    local qolDiff = root.qol.args.difficulty.args

    qolDiff.difficultyText = ACH:Toggle(
        function() return TUI.db.profile.qol.difficultyText and "|cff00ff00Enable|r" or "Enable" end,
        "Replace the minimap difficulty flag icon with readable text.", 1, nil, nil, nil,
        function() return TUI.db.profile.qol.difficultyText end,
        function(_, v) TUI.db.profile.qol.difficultyText = v; E:StaticPopup_Show('CONFIG_RL') end)

    local diffDisabled = function() return not TUI.db.profile.qol.difficultyText end

    qolDiff.diffFont = ACH:SharedMediaFont("Font", nil, 2, nil,
        function() return TUI.db.profile.qol.difficultyFont end,
        function(_, v) TUI.db.profile.qol.difficultyFont = v; if QOL then QOL:UpdateDifficultyFont() end end, diffDisabled)

    qolDiff.diffFontSize = ACH:Range("Font Size", nil, 3, { min = 6, max = 32, step = 1 }, nil,
        function() return TUI.db.profile.qol.difficultyFontSize end,
        function(_, v) TUI.db.profile.qol.difficultyFontSize = v; if QOL then QOL:UpdateDifficultyFont() end end, diffDisabled)

    qolDiff.diffFontOutline = ACH:FontFlags("Font Outline", nil, 4, nil,
        function() return TUI.db.profile.qol.difficultyFontOutline end,
        function(_, v) TUI.db.profile.qol.difficultyFontOutline = v; if QOL then QOL:UpdateDifficultyFont() end end, diffDisabled)

    qolDiff.colors = ACH:Group("Colors", nil, 5)
    qolDiff.colors.inline = true
    local diffColors = qolDiff.colors.args

    local function ensureDiffColor(key)
        local qol = TUI.db.profile.qol
        if not qol.difficultyColors then qol.difficultyColors = {} end
        if not qol.difficultyColors[key] then qol.difficultyColors[key] = { r = 1, g = 1, b = 1 } end
        return qol.difficultyColors[key]
    end

    local diffColorDefs = {
        { key = "normal",      label = "Normal" },
        { key = "heroic",      label = "Heroic" },
        { key = "mythic",      label = "Mythic" },
        { key = "keystoneMod", label = "Mythic+" },
        { key = "timewalking", label = "Timewalking" },
        { key = "lfr",         label = "LFR" },
        { key = "follower",    label = "Follower" },
        { key = "delve",       label = "Delve" },
    }

    for i, def in ipairs(diffColorDefs) do
        diffColors[def.key] = ACH:Color(def.label, nil, i, nil, nil,
            function() local c = ensureDiffColor(def.key); return c.r, c.g, c.b end,
            function(_, r, g, b) local c = ensureDiffColor(def.key); c.r, c.g, c.b = r, g, b end, diffDisabled)
    end

    -- Minimap Buttons
    root.qol.args.minimapButtonBar = ACH:Group("Minimap Buttons", nil, 4)
    local mbb = root.qol.args.minimapButtonBar.args

    local mbbUpdate = function() if QOL and QOL.UpdateMinimapButtonBar then QOL:UpdateMinimapButtonBar() end end
    local mbbDB = function() return TUI.db.profile.minimapButtonBar end
    local mbbDisabled = function() return not mbbDB().enabled end

    mbb.enabled = ACH:Toggle(
        function() return mbbDB().enabled and "|cff00ff00Enable|r" or "Enable" end,
        "Collect minimap addon buttons into a bar.", 1, nil, nil, nil,
        function() return mbbDB().enabled end,
        function(_, v) mbbDB().enabled = v; E:StaticPopup_Show('CONFIG_RL') end)

    mbb.layout = ACH:Group("Layout", nil, 2)
    mbb.layout.inline = true
    local mbbLayout = mbb.layout.args

    mbbLayout.orientation = ACH:Select("Orientation", nil, 1, { HORIZONTAL = 'Horizontal', VERTICAL = 'Vertical' }, nil, nil,
        function() return mbbDB().orientation or 'HORIZONTAL' end,
        function(_, v) mbbDB().orientation = v; mbbDB().growthDirection = (v == 'HORIZONTAL') and 'RIGHTDOWN' or 'DOWNRIGHT'; mbbUpdate() end, mbbDisabled)

    mbbLayout.growthDirection = ACH:Select("Growth Direction", nil, 2,
        function()
            if (mbbDB().orientation or 'HORIZONTAL') == 'HORIZONTAL' then
                return { RIGHTDOWN = 'Right, then Down', RIGHTUP = 'Right, then Up', LEFTDOWN = 'Left, then Down', LEFTUP = 'Left, then Up' }
            else
                return { DOWNRIGHT = 'Down, then Right', DOWNLEFT = 'Down, then Left', UPRIGHT = 'Up, then Right', UPLEFT = 'Up, then Left' }
            end
        end, nil, nil,
        function() return mbbDB().growthDirection or 'RIGHTDOWN' end,
        function(_, v) mbbDB().growthDirection = v; mbbUpdate() end, mbbDisabled)

    mbbLayout.buttonSize = ACH:Range("Button Size", nil, 3, { min = 16, max = 48, step = 1 }, nil,
        function() return mbbDB().buttonSize end, function(_, v) mbbDB().buttonSize = v; mbbUpdate() end, mbbDisabled)

    mbbLayout.buttonSpacing = ACH:Range("Button Spacing", nil, 4, { min = 0, max = 10, step = 1 }, nil,
        function() return mbbDB().buttonSpacing end, function(_, v) mbbDB().buttonSpacing = v; mbbUpdate() end, mbbDisabled)

    mbbLayout.buttonsPerRow = ACH:Range("Buttons Per Row", nil, 5, { min = 1, max = 24, step = 1 }, nil,
        function() return mbbDB().buttonsPerRow end, function(_, v) mbbDB().buttonsPerRow = v; mbbUpdate() end, mbbDisabled)

    mbb.buttonAppearance = ACH:Group("Button Appearance", nil, 10)
    mbb.buttonAppearance.inline = true
    local mbbBtn = mbb.buttonAppearance.args

    mbbBtn.buttonBackdrop = ACH:Toggle("Background", nil, 1, nil, nil, nil,
        function() return mbbDB().buttonBackdrop end, function(_, v) mbbDB().buttonBackdrop = v; mbbUpdate() end, mbbDisabled)
    mbbBtn.buttonBackdropColor = ACH:Color("BG Color", nil, 2, true, nil,
        function() local c = mbbDB().buttonBackdropColor; return c.r, c.g, c.b, c.a end,
        function(_, r, g, b, a) local c = mbbDB().buttonBackdropColor; c.r, c.g, c.b, c.a = r, g, b, a; mbbUpdate() end,
        function() return mbbDisabled() or not mbbDB().buttonBackdrop end)
    mbbBtn.buttonBorder = ACH:Toggle("Border", nil, 3, nil, nil, nil,
        function() return mbbDB().buttonBorder end, function(_, v) mbbDB().buttonBorder = v; mbbUpdate() end, mbbDisabled)
    mbbBtn.buttonBorderColor = ACH:Color("Border Color", nil, 4, true, nil,
        function() local c = mbbDB().buttonBorderColor; return c.r, c.g, c.b, c.a end,
        function(_, r, g, b, a) local c = mbbDB().buttonBorderColor; c.r, c.g, c.b, c.a = r, g, b, a; mbbUpdate() end,
        function() return mbbDisabled() or not mbbDB().buttonBorder end)
    mbbBtn.buttonBorderSize = ACH:Range("Border Thickness", nil, 5, { min = 1, max = 4, step = 1 }, nil,
        function() return mbbDB().buttonBorderSize end, function(_, v) mbbDB().buttonBorderSize = v; mbbUpdate() end,
        function() return mbbDisabled() or not mbbDB().buttonBorder end)

    mbb.barAppearance = ACH:Group("Bar Appearance", nil, 20)
    mbb.barAppearance.inline = true
    local mbbBar = mbb.barAppearance.args

    mbbBar.backdrop = ACH:Toggle("Background", nil, 1, nil, nil, nil,
        function() return mbbDB().backdrop end, function(_, v) mbbDB().backdrop = v; mbbUpdate() end, mbbDisabled)
    mbbBar.backdropColor = ACH:Color("BG Color", nil, 2, true, nil,
        function() local c = mbbDB().backdropColor; return c.r, c.g, c.b, c.a end,
        function(_, r, g, b, a) local c = mbbDB().backdropColor; c.r, c.g, c.b, c.a = r, g, b, a; mbbUpdate() end,
        function() return mbbDisabled() or not mbbDB().backdrop end)
    mbbBar.border = ACH:Toggle("Border", nil, 3, nil, nil, nil,
        function() return mbbDB().border end, function(_, v) mbbDB().border = v; mbbUpdate() end, mbbDisabled)
    mbbBar.borderColor = ACH:Color("Border Color", nil, 4, true, nil,
        function() local c = mbbDB().borderColor; return c.r, c.g, c.b, c.a end,
        function(_, r, g, b, a) local c = mbbDB().borderColor; c.r, c.g, c.b, c.a = r, g, b, a; mbbUpdate() end,
        function() return mbbDisabled() or not mbbDB().border end)
    mbbBar.borderSize = ACH:Range("Border Thickness", nil, 5, { min = 1, max = 4, step = 1 }, nil,
        function() return mbbDB().borderSize end, function(_, v) mbbDB().borderSize = v; mbbUpdate() end,
        function() return mbbDisabled() or not mbbDB().border end)

    mbb.visibility = ACH:Group("Visibility", nil, 30)
    mbb.visibility.inline = true
    local mbbVis = mbb.visibility.args

    mbbVis.mouseover = ACH:Toggle("Mouseover", nil, 1, nil, nil, nil,
        function() return mbbDB().mouseover end, function(_, v) mbbDB().mouseover = v; mbbUpdate() end, mbbDisabled)
    mbbVis.mouseoverAlpha = ACH:Range("Mouseover Alpha", nil, 2, { min = 0, max = 1, step = 0.05, isPercent = true }, nil,
        function() return mbbDB().mouseoverAlpha end, function(_, v) mbbDB().mouseoverAlpha = v; mbbUpdate() end,
        function() return mbbDisabled() or not mbbDB().mouseover end)
    mbbVis.hideInCombat = ACH:Toggle("Hide in Combat", nil, 3, nil, nil, nil,
        function() return mbbDB().hideInCombat end, function(_, v) mbbDB().hideInCombat = v; mbbUpdate() end, mbbDisabled)

    -- Buff/Debuff Mouseover
    root.qol.args.auraFader = ACH:Group("Buff/Debuff Mouseover", nil, 5)
    local af = root.qol.args.auraFader.args

    af.buffMouseover = ACH:Toggle("Buffs", "Only show buff icons when mousing over them.", 1, nil, nil, nil,
        function() return TUI.db.profile.qol.buffMouseover end,
        function(_, v) TUI.db.profile.qol.buffMouseover = v; E:StaticPopup_Show('CONFIG_RL') end)

    af.buffMouseoverAlpha = ACH:Range("Buffs Hidden Alpha", nil, 2, { min = 0, max = 1, step = 0.05, isPercent = true }, nil,
        function() return TUI.db.profile.qol.buffMouseoverAlpha end,
        function(_, v) TUI.db.profile.qol.buffMouseoverAlpha = v; E:StaticPopup_Show('CONFIG_RL') end,
        function() return not TUI.db.profile.qol.buffMouseover end)

    af.debuffMouseover = ACH:Toggle("Debuffs", "Only show debuff icons when mousing over them.", 3, nil, nil, nil,
        function() return TUI.db.profile.qol.debuffMouseover end,
        function(_, v) TUI.db.profile.qol.debuffMouseover = v; E:StaticPopup_Show('CONFIG_RL') end)

    af.debuffMouseoverAlpha = ACH:Range("Debuffs Hidden Alpha", nil, 4, { min = 0, max = 1, step = 0.05, isPercent = true }, nil,
        function() return TUI.db.profile.qol.debuffMouseoverAlpha end,
        function(_, v) TUI.db.profile.qol.debuffMouseoverAlpha = v; E:StaticPopup_Show('CONFIG_RL') end,
        function() return not TUI.db.profile.qol.debuffMouseover end)

    -- Mute Annoying Sounds
    root.qol.args.muteSounds = ACH:Group(E.NewSign .. "Mute Annoying Sounds", nil, 6)
    local ms = root.qol.args.muteSounds.args
    local function msDB() return TUI.db.profile.qol.muteSounds end

    ms.desc = ACH:Description("Mute specific item proc / loop sounds. Toggling takes effect immediately.", 0, "medium")

    if QOL and QOL.MUTE_SOUND_ENTRIES then
        for i, entry in ipairs(QOL.MUTE_SOUND_ENTRIES) do
            local key = entry.key
            ms[key] = ACH:Toggle(entry.label, nil, i, nil, nil, nil,
                function() return msDB()[key] end,
                function(_, v)
                    msDB()[key] = v
                    if QOL and QOL.RefreshMutedSounds then QOL:RefreshMutedSounds() end
                end)
        end
    end
end
