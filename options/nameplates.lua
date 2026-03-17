local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local ACH = E.Libs.ACH

function TUI:BuildNameplatesConfig(root, tuiName)
    root.nameplates = ACH:Group("Nameplates", nil, 4)

    root.nameplates.args.target = ACH:Group("Target Indicator", nil, 0)
    root.nameplates.args.target.inline = true
    root.nameplates.args.target.args.classColorTargetIndicator = ACH:Toggle(
        "Class Color",
        "Override the target indicator color with your class color.",
        1, nil, nil, nil,
        function() return TUI.db.profile.nameplates.classColorTargetIndicator end,
        function(_, value)
            TUI.db.profile.nameplates.classColorTargetIndicator = value
        end
    )

    root.nameplates.args.threat = ACH:Group("Threat", nil, 1)
    root.nameplates.args.threat.inline = true
    local npThreat = root.nameplates.args.threat.args

    npThreat.classificationOverThreat = ACH:Toggle(
        "Classification Over Threat",
        "When threat status is 'good' (tank securely tanking, DPS/healer no aggro), skip the flat threat color "
        .. "and show normal health colors (Classification, Class, Selection) instead. "
        .. "Bad/transitional threat still shows the standard warning color.",
        1, nil, nil, nil,
        function() return TUI.db.profile.nameplates.classificationOverThreat end,
        function(_, value)
            TUI.db.profile.nameplates.classificationOverThreat = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )
    npThreat.classificationOverThreat.customWidth = 250

    root.nameplates.args.interrupt = ACH:Group("Interrupt Ready", nil, 2)
    root.nameplates.args.interrupt.inline = true
    local npInt = root.nameplates.args.interrupt.args

    local blinkii = '|CFF6559F1B|r|CFF7A4DEFl|r|CFF8845ECi|r|CFFA037E9n|r|CFFB32DE6k|r|CFFBC26E5i|r|CFFCB1EE3i|r'
    npInt.interruptCredit = ACH:Description(
        "Interrupt Ready changes the color of your castbar based on whether or not your interrupt is on or off cooldown."
        .. " If your interrupt will come off cooldown during an interruptible cast, a green marker will show when it is ready."
        .. " Special thanks goes out to " .. blinkii .. " for originally creating this function, and allowing " .. tuiName .. " to use it!",
        1, "medium"
    )

    npInt.interruptCastbarColors = ACH:Toggle(
        function() return TUI.db.profile.nameplates.interruptCastbarColors and "|cff00ff00Enable|r" or "Enable" end,
        "Color interruptible castbars based on your interrupt cooldown status:\n"
        .. "  \226\128\162 Ready \226\128\148 interrupt is off cooldown\n"
        .. "  \226\128\162 On CD \226\128\148 interrupt is on cooldown\n\n"
        .. "A marker line is drawn on the castbar showing when your interrupt becomes available.",
        2, nil, nil, nil,
        function() return TUI.db.profile.nameplates.interruptCastbarColors end,
        function(_, value)
            TUI.db.profile.nameplates.interruptCastbarColors = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )

    local intDisabled = function() return not TUI.db.profile.nameplates.interruptCastbarColors end

    npInt.castbarInterruptReady = ACH:Color(
        "Interrupt Ready", "Castbar color when your interrupt is off cooldown.",
        3, nil, nil,
        function()
            local c = TUI.db.profile.nameplates.castbarInterruptReady
            return c.r, c.g, c.b
        end,
        function(_, r, g, b)
            local c = TUI.db.profile.nameplates.castbarInterruptReady
            c.r, c.g, c.b = r, g, b
        end,
        intDisabled
    )

    npInt.castbarInterruptOnCD = ACH:Color(
        "On Cooldown", "Castbar color when your interrupt is on CD and won't be ready in time.",
        4, nil, nil,
        function()
            local c = TUI.db.profile.nameplates.castbarInterruptOnCD
            return c.r, c.g, c.b
        end,
        function(_, r, g, b)
            local c = TUI.db.profile.nameplates.castbarInterruptOnCD
            c.r, c.g, c.b = r, g, b
        end,
        intDisabled
    )

    npInt.castbarMarkerColor = ACH:Color(
        "Ready Marker",
        "Color of the vertical marker line showing when your interrupt becomes available during a cast.",
        5, nil, nil,
        function()
            local c = TUI.db.profile.nameplates.castbarMarkerColor
            return c.r, c.g, c.b
        end,
        function(_, r, g, b)
            local c = TUI.db.profile.nameplates.castbarMarkerColor
            c.r, c.g, c.b = r, g, b
        end,
        intDisabled
    )

    root.nameplates.args.quest = ACH:Group("Quest Color", nil, 3)
    root.nameplates.args.quest.inline = true
    local npQuest = root.nameplates.args.quest.args

    npQuest.questColorEnabled = ACH:Toggle(
        function() return TUI.db.profile.nameplates.questColor.enabled and "|cff00ff00Enable|r" or "Enable" end,
        "Override the health bar color for quest NPCs with a custom color. "
        .. "Overrides selection, classification, and threat colors.",
        1, nil, nil, nil,
        function() return TUI.db.profile.nameplates.questColor.enabled end,
        function(_, value)
            TUI.db.profile.nameplates.questColor.enabled = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )

    npQuest.questColorColor = ACH:Color(
        "Color", "Health bar color for quest NPCs.", 2, nil, nil,
        function()
            local c = TUI.db.profile.nameplates.questColor.color
            return c.r, c.g, c.b
        end,
        function(_, r, g, b)
            local c = TUI.db.profile.nameplates.questColor.color
            c.r, c.g, c.b = r, g, b
        end,
        function() return not TUI.db.profile.nameplates.questColor.enabled end
    )

    root.nameplates.args.highlight = ACH:Group("Friendly Nameplates", nil, 5)
    root.nameplates.args.highlight.inline = true
    local npHL = root.nameplates.args.highlight.args

    npHL.disableFriendlyHighlight = ACH:Toggle(
        "Disable Friendly Highlight",
        "Remove the mouseover highlight effect from friendly nameplates.",
        1, nil, nil, nil,
        function() return TUI.db.profile.nameplates.disableFriendlyHighlight end,
        function(_, value)
            TUI.db.profile.nameplates.disableFriendlyHighlight = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )
    npHL.disableFriendlyHighlight.customWidth = 250

    npHL.hideFriendlyRealm = ACH:Toggle(
        "Hide Friendly Realm Names",
        "Remove realm name suffixes from friendly nameplates.",
        2, nil, nil, nil,
        function() return TUI.db.profile.nameplates.hideFriendlyRealm end,
        function(_, value)
            TUI.db.profile.nameplates.hideFriendlyRealm = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )
    npHL.hideFriendlyRealm.customWidth = 250

    root.nameplates.args.focus = ACH:Group("Focus Indicator", nil, 4)
    root.nameplates.args.focus.inline = true
    local npFocus = root.nameplates.args.focus.args

    local focusDisabled = function() return not TUI.db.profile.nameplates.focusGlow.enabled end

    npFocus.focusGlowEnabled = ACH:Toggle(
        function() return TUI.db.profile.nameplates.focusGlow.enabled and "|cff00ff00Enable|r" or "Enable" end,
        "Overlay a colored statusbar texture on the nameplate of your focus target.",
        1, nil, nil, nil,
        function() return TUI.db.profile.nameplates.focusGlow.enabled end,
        function(_, value)
            TUI.db.profile.nameplates.focusGlow.enabled = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )

    npFocus.focusGlowTexture = ACH:SharedMediaStatusbar(
        "Texture", "Statusbar texture for the focus overlay.", 2, nil,
        function() return TUI.db.profile.nameplates.focusGlow.texture end,
        function(_, value) TUI.db.profile.nameplates.focusGlow.texture = value end,
        focusDisabled
    )

    npFocus.focusGlowColor = ACH:Color(
        "Color", "Color and opacity of the focus overlay.", 3, true, nil,
        function()
            local c = TUI.db.profile.nameplates.focusGlow.color
            return c.r, c.g, c.b, c.a
        end,
        function(_, r, g, b, a)
            local c = TUI.db.profile.nameplates.focusGlow.color
            c.r, c.g, c.b, c.a = r, g, b, a
        end,
        focusDisabled
    )
end
