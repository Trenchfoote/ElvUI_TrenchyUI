local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local ACH = E.Libs.ACH

function TUI:BuildQoLConfig(root, tuiName)
    root.qol = ACH:Group("QoL", nil, 1)

    root.qol.args.general = ACH:Group("General", nil, 1)
    root.qol.args.general.inline = true
    local qolGen = root.qol.args.general.args

    qolGen.hideTalkingHead = ACH:Toggle(
        "Hide Talking Head",
        "Permanently suppress the Talking Head popup.",
        1, nil, nil, nil,
        function() return TUI.db.profile.qol.hideTalkingHead end,
        function(_, value)
            TUI.db.profile.qol.hideTalkingHead = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )

    qolGen.autoFillDelete = ACH:Toggle(
        "Auto-fill Delete",
        "Automatically type DELETE in the item destruction confirmation popup.",
        2, nil, nil, nil,
        function() return TUI.db.profile.qol.autoFillDelete end,
        function(_, value)
            TUI.db.profile.qol.autoFillDelete = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )

    qolGen.moveableFrames = ACH:Toggle(
        "Moveable Frames",
        "Click and drag most Blizzard and addon frames to reposition them freely. "
        .. "Also removes the shift-drag requirement from ElvUI bags.",
        3, nil, nil, nil,
        function() return TUI.db.profile.qol.moveableFrames end,
        function(_, value)
            TUI.db.profile.qol.moveableFrames = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )

    qolGen.fastLoot = ACH:Toggle(
        "Fast Loot",
        "Instantly loot all items when opening a loot window, skipping the default pickup delay.",
        4, nil, nil, nil,
        function() return TUI.db.profile.qol.fastLoot end,
        function(_, value)
            TUI.db.profile.qol.fastLoot = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )

    qolGen.hideObjectiveInCombat = ACH:Toggle(
        "Hide Objectives in Combat",
        "Automatically hide the objective tracker when entering combat and restore it when leaving combat.",
        5, nil, nil, nil,
        function() return TUI.db.profile.qol.hideObjectiveInCombat end,
        function(_, value)
            TUI.db.profile.qol.hideObjectiveInCombat = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )
    qolGen.hideObjectiveInCombat.customWidth = 250

    -- qolGen.borderMode = ACH:Toggle(
    --     "Custom Borders",
    --     "Replace ElvUI's 1px borders with a custom border from LS: Borders. Requires the ls_Borders addon.",
    --     7, nil, nil, nil,
    --     function() return TUI.db.profile.borderMode end,
    --     function(_, value)
    --         TUI.db.profile.borderMode = value
    --         E:StaticPopup_Show('CONFIG_RL')
    --     end,
    --     function() return not E:IsAddOnEnabled('ls_Borders') end
    -- )

    qolGen.shortenEnchantStrings = ACH:Toggle(
        "Shorten Enchant Names",
        "Abbreviate enchant names on the character and inspect frames to save space.",
        6, nil, nil, nil,
        function() return TUI.db.profile.qol.shortenEnchantStrings end,
        function(_, value)
            TUI.db.profile.qol.shortenEnchantStrings = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )
    qolGen.shortenEnchantStrings.customWidth = 250

    root.qol.args.cursorCircle = ACH:Group("Cursor Circle", nil, 1.5)
    root.qol.args.cursorCircle.inline = true
    local ccArgs = root.qol.args.cursorCircle.args

    ccArgs.enabled = ACH:Toggle(
        function() return TUI.db.profile.qol.cursorCircle and "|cff00ff00Enable|r" or "Enable" end,
        "Show a circle around the cursor to make it easier to locate.",
        1, nil, nil, nil,
        function() return TUI.db.profile.qol.cursorCircle end,
        function(_, value)
            TUI.db.profile.qol.cursorCircle = value
            if TUI.ToggleCursorCircle then TUI:ToggleCursorCircle(value) end
        end
    )

    local ccDisabled = function() return not TUI.db.profile.qol.cursorCircle end

    ccArgs.size = ACH:Range(
        "Size", "Diameter of the circle in pixels.", 2,
        { min = 16, max = 256, step = 1 }, nil,
        function() return TUI.db.profile.qol.cursorCircleSize end,
        function(_, value)
            TUI.db.profile.qol.cursorCircleSize = value
            if TUI.UpdateCursorCircle then TUI:UpdateCursorCircle() end
        end,
        ccDisabled
    )

    ccArgs.thickness = ACH:Select(
        "Thickness", "Ring thickness of the circle.", 3,
        { thin = 'Thin', medium = 'Medium', thick = 'Thick' }, nil, nil,
        function() return TUI.db.profile.qol.cursorCircleThickness end,
        function(_, value)
            TUI.db.profile.qol.cursorCircleThickness = value
            if TUI.UpdateCursorCircle then TUI:UpdateCursorCircle() end
        end,
        ccDisabled
    )
    ccArgs.thickness.sorting = { 'thin', 'medium', 'thick' }

    ccArgs.classColor = ACH:Toggle(
        "Class Color", "Use your class color for the circle.",
        4, nil, nil, nil,
        function() return TUI.db.profile.qol.cursorCircleClassColor end,
        function(_, value)
            TUI.db.profile.qol.cursorCircleClassColor = value
            if TUI.UpdateCursorCircle then TUI:UpdateCursorCircle() end
        end,
        ccDisabled
    )

    ccArgs.color = ACH:Color(
        "Color", nil, 5, true, nil,
        function()
            local c = TUI.db.profile.qol.cursorCircleColor
            return c.r, c.g, c.b, c.a
        end,
        function(_, r, g, b, a)
            local c = TUI.db.profile.qol.cursorCircleColor
            c.r, c.g, c.b, c.a = r, g, b, a
            if TUI.UpdateCursorCircle then TUI:UpdateCursorCircle() end
        end,
        function() return ccDisabled() or TUI.db.profile.qol.cursorCircleClassColor end
    )

    root.qol.args.difficulty = ACH:Group("Difficulty Text", nil, 2)
    root.qol.args.difficulty.inline = true
    local qolDiff = root.qol.args.difficulty.args

    qolDiff.difficultyText = ACH:Toggle(
        function() return TUI.db.profile.qol.difficultyText and "|cff00ff00Enable|r" or "Enable" end,
        "Replace the minimap difficulty flag icon with readable text (N, H, M, M+, TW, etc.).",
        1, nil, nil, nil,
        function() return TUI.db.profile.qol.difficultyText end,
        function(_, value)
            TUI.db.profile.qol.difficultyText = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )

    local diffDisabled = function() return not TUI.db.profile.qol.difficultyText end

    qolDiff.diffFont = ACH:SharedMediaFont(
        "Font", "Font used for difficulty text.", 2, nil,
        function() return TUI.db.profile.qol.difficultyFont end,
        function(_, value)
            TUI.db.profile.qol.difficultyFont = value
            TUI:UpdateDifficultyFont()
        end,
        diffDisabled
    )

    qolDiff.diffFontSize = ACH:Range(
        "Font Size", "Size of the difficulty text.", 3,
        { min = 6, max = 32, step = 1 }, nil,
        function() return TUI.db.profile.qol.difficultyFontSize end,
        function(_, value)
            TUI.db.profile.qol.difficultyFontSize = value
            TUI:UpdateDifficultyFont()
        end,
        diffDisabled
    )

    qolDiff.diffFontOutline = ACH:FontFlags(
        "Font Outline", "Outline style for difficulty text.", 4, nil,
        function() return TUI.db.profile.qol.difficultyFontOutline end,
        function(_, value)
            TUI.db.profile.qol.difficultyFontOutline = value
            TUI:UpdateDifficultyFont()
        end,
        diffDisabled
    )

    qolDiff.colors = ACH:Group("Difficulty Colors", nil, 5)
    qolDiff.colors.inline = true
    local diffColors = qolDiff.colors.args

    local function ensureDiffColor(key)
        local qol = TUI.db.profile.qol
        if not qol.difficultyColors then qol.difficultyColors = {} end
        if not qol.difficultyColors[key] then qol.difficultyColors[key] = { r = 1, g = 1, b = 1 } end
        return qol.difficultyColors[key]
    end

    local diffColorDefs = {
        { key = "normal",      label = "Normal",       desc = "Color for Normal difficulty." },
        { key = "heroic",      label = "Heroic",       desc = "Color for Heroic difficulty." },
        { key = "mythic",      label = "Mythic",       desc = "Color for Mythic (non-keystone) difficulty." },
        { key = "keystoneMod", label = "Mythic+",      desc = "Color for Mythic Keystone (M+) text and level number." },
        { key = "timewalking", label = "Timewalking",  desc = "Color for Timewalking difficulty." },
        { key = "lfr",         label = "LFR",          desc = "Color for Looking For Raid difficulty." },
        { key = "follower",    label = "Follower",     desc = "Color for Follower Dungeon difficulty." },
        { key = "delve",       label = "Delve",        desc = "Color for Delve difficulty." },
    }

    for i, def in ipairs(diffColorDefs) do
        diffColors[def.key] = ACH:Color(
            def.label, def.desc, i, nil, nil,
            function() local c = ensureDiffColor(def.key); return c.r, c.g, c.b end,
            function(_, r, g, b) local c = ensureDiffColor(def.key); c.r, c.g, c.b = r, g, b end,
            diffDisabled
        )
    end

    root.qol.args.minimapButtonBar = ACH:Group("Minimap Buttons", nil, 3)
    root.qol.args.minimapButtonBar.inline = true
    local mbb = root.qol.args.minimapButtonBar.args

    local mbbUpdate = function() if TUI.UpdateMinimapButtonBar then TUI:UpdateMinimapButtonBar() end end
    local mbbDB = function() return TUI.db.profile.minimapButtonBar end
    local mbbDisabled = function() return not mbbDB().enabled end

    mbb.enabled = ACH:Toggle(
        function() return mbbDB().enabled and "|cff00ff00Enable|r" or "Enable" end,
        "Collect minimap addon buttons into a bar.", 1, nil, nil, nil,
        function() return mbbDB().enabled end,
        function(_, value) mbbDB().enabled = value; E:StaticPopup_Show('CONFIG_RL') end)

    mbb.layout = ACH:Group("Layout", nil, 2)
    mbb.layout.inline = true
    local mbbLayout = mbb.layout.args

    mbbLayout.orientation = ACH:Select(
        "Orientation", "Primary direction the bar extends.", 1,
        { HORIZONTAL = 'Horizontal', VERTICAL = 'Vertical' }, nil, nil,
        function() return mbbDB().orientation or 'HORIZONTAL' end,
        function(_, v)
            mbbDB().orientation = v
            mbbDB().growthDirection = (v == 'HORIZONTAL') and 'RIGHTDOWN' or 'DOWNRIGHT'
            mbbUpdate()
        end,
        mbbDisabled
    )

    mbbLayout.growthDirection = ACH:Select(
        "Growth Direction", "How buttons fill and wrap.", 2,
        function()
            if (mbbDB().orientation or 'HORIZONTAL') == 'HORIZONTAL' then
                return { RIGHTDOWN = 'Right, then Down', RIGHTUP = 'Right, then Up', LEFTDOWN = 'Left, then Down', LEFTUP = 'Left, then Up' }
            else
                return { DOWNRIGHT = 'Down, then Right', DOWNLEFT = 'Down, then Left', UPRIGHT = 'Up, then Right', UPLEFT = 'Up, then Left' }
            end
        end,
        nil, nil,
        function() return mbbDB().growthDirection or 'RIGHTDOWN' end,
        function(_, v) mbbDB().growthDirection = v; mbbUpdate() end,
        mbbDisabled
    )

    mbbLayout.buttonSize = ACH:Range("Button Size", "Size of each button.", 3, { min = 16, max = 48, step = 1 },
        nil, function() return mbbDB().buttonSize end,
        function(_, v) mbbDB().buttonSize = v; mbbUpdate() end, mbbDisabled)

    mbbLayout.buttonSpacing = ACH:Range("Button Spacing", "Space between buttons.", 4, { min = 0, max = 10, step = 1 },
        nil, function() return mbbDB().buttonSpacing end,
        function(_, v) mbbDB().buttonSpacing = v; mbbUpdate() end, mbbDisabled)

    mbbLayout.buttonsPerRow = ACH:Range("Buttons Per Row", "Number of buttons before wrapping to the next row/column.", 5, { min = 1, max = 24, step = 1 },
        nil, function() return mbbDB().buttonsPerRow end,
        function(_, v) mbbDB().buttonsPerRow = v; mbbUpdate() end, mbbDisabled)

    mbb.buttonAppearance = ACH:Group("Button Appearance", nil, 10)
    mbb.buttonAppearance.inline = true
    local mbbBtn = mbb.buttonAppearance.args

    mbbBtn.buttonBackdrop = ACH:Toggle("Background", "Show a background behind each button icon.", 1, nil, nil, nil,
        function() return mbbDB().buttonBackdrop end,
        function(_, v) mbbDB().buttonBackdrop = v; mbbUpdate() end, mbbDisabled)

    mbbBtn.buttonBackdropColor = ACH:Color("BG Color", nil, 2, true, nil,
        function() local c = mbbDB().buttonBackdropColor; return c.r, c.g, c.b, c.a end,
        function(_, r, g, b, a) local c = mbbDB().buttonBackdropColor; c.r, c.g, c.b, c.a = r, g, b, a; mbbUpdate() end,
        function() return mbbDisabled() or not mbbDB().buttonBackdrop end)

    mbbBtn.buttonBorder = ACH:Toggle("Border", "Show a border around each button.", 3, nil, nil, nil,
        function() return mbbDB().buttonBorder end,
        function(_, v) mbbDB().buttonBorder = v; mbbUpdate() end, mbbDisabled)

    mbbBtn.buttonBorderColor = ACH:Color("Border Color", nil, 4, true, nil,
        function() local c = mbbDB().buttonBorderColor; return c.r, c.g, c.b, c.a end,
        function(_, r, g, b, a) local c = mbbDB().buttonBorderColor; c.r, c.g, c.b, c.a = r, g, b, a; mbbUpdate() end,
        function() return mbbDisabled() or not mbbDB().buttonBorder end)

    mbbBtn.buttonBorderSize = ACH:Range("Border Thickness", nil, 5, { min = 1, max = 4, step = 1 },
        nil, function() return mbbDB().buttonBorderSize end,
        function(_, v) mbbDB().buttonBorderSize = v; mbbUpdate() end,
        function() return mbbDisabled() or not mbbDB().buttonBorder end)

    mbb.barAppearance = ACH:Group("Bar Appearance", nil, 20)
    mbb.barAppearance.inline = true
    local mbbBar = mbb.barAppearance.args

    mbbBar.backdrop = ACH:Toggle("Background", "Show a backdrop behind the button bar.", 1, nil, nil, nil,
        function() return mbbDB().backdrop end,
        function(_, v) mbbDB().backdrop = v; mbbUpdate() end, mbbDisabled)

    mbbBar.backdropColor = ACH:Color("BG Color", nil, 2, true, nil,
        function() local c = mbbDB().backdropColor; return c.r, c.g, c.b, c.a end,
        function(_, r, g, b, a) local c = mbbDB().backdropColor; c.r, c.g, c.b, c.a = r, g, b, a; mbbUpdate() end,
        function() return mbbDisabled() or not mbbDB().backdrop end)

    mbbBar.border = ACH:Toggle("Border", "Show a border around the button bar.", 3, nil, nil, nil,
        function() return mbbDB().border end,
        function(_, v) mbbDB().border = v; mbbUpdate() end, mbbDisabled)

    mbbBar.borderColor = ACH:Color("Border Color", nil, 4, true, nil,
        function() local c = mbbDB().borderColor; return c.r, c.g, c.b, c.a end,
        function(_, r, g, b, a) local c = mbbDB().borderColor; c.r, c.g, c.b, c.a = r, g, b, a; mbbUpdate() end,
        function() return mbbDisabled() or not mbbDB().border end)

    mbbBar.borderSize = ACH:Range("Border Thickness", nil, 5, { min = 1, max = 4, step = 1 },
        nil, function() return mbbDB().borderSize end,
        function(_, v) mbbDB().borderSize = v; mbbUpdate() end,
        function() return mbbDisabled() or not mbbDB().border end)

    mbb.visibility = ACH:Group("Visibility", nil, 30)
    mbb.visibility.inline = true
    local mbbVis = mbb.visibility.args

    mbbVis.mouseover = ACH:Toggle("Mouseover", "Only show the bar when mousing over it.", 1, nil, nil, nil,
        function() return mbbDB().mouseover end,
        function(_, v) mbbDB().mouseover = v; mbbUpdate() end, mbbDisabled)

    mbbVis.mouseoverAlpha = ACH:Range("Mouseover Alpha", "Bar opacity when visible on mouseover.", 2, { min = 0, max = 1, step = 0.05, isPercent = true },
        nil, function() return mbbDB().mouseoverAlpha end,
        function(_, v) mbbDB().mouseoverAlpha = v; mbbUpdate() end,
        function() return mbbDisabled() or not mbbDB().mouseover end)

    mbbVis.hideInCombat = ACH:Toggle("Hide in Combat", "Automatically hide the button bar during combat.", 3, nil, nil, nil,
        function() return mbbDB().hideInCombat end,
        function(_, v) mbbDB().hideInCombat = v; mbbUpdate() end, mbbDisabled)
end
