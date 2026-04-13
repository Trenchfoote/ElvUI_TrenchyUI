local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local ACH = E.Libs.ACH

local elvEnabled = E.private.nameplates.enable
local platyEnabled = E:IsAddOnEnabled('Platynator')

function TUI:BuildNameplatesConfig(root, tuiName)
    root.nameplates = ACH:Group("Nameplates", nil, 4, "tree")

    -- ElvUI Nameplates sub-group
    root.nameplates.args.elvui = ACH:Group("ElvUI", nil, 1)
    root.nameplates.args.elvui.disabled = not elvEnabled
    local elv = root.nameplates.args.elvui.args

    elv.target = ACH:Group("Target Indicator", nil, 0)
    elv.target.inline = true
    elv.target.args = {}
    elv.target.args.classColorTargetIndicator = ACH:Toggle(
        "Class Color",
        "Override the target indicator color with your class color.",
        1, nil, nil, nil,
        function() return TUI.db.profile.nameplates.classColorTargetIndicator end,
        function(_, value)
            TUI.db.profile.nameplates.classColorTargetIndicator = value
        end
    )

    elv.interrupt = ACH:Group("Interrupt Ready", nil, 1)
    elv.interrupt.inline = true
    local npInt = elv.interrupt.args

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

    elv.importantCast = ACH:Group("Important Cast", nil, 2)
    elv.importantCast.inline = true
    local npImp = elv.importantCast.args

    npImp.desc = ACH:Description(
        "Enhance nameplates when a mob is casting a spell flagged as important by Blizzard.",
        1, "medium"
    )

    npImp.enabled = ACH:Toggle(
        function() return TUI.db.profile.nameplates.importantCast.enabled and "|cff00ff00Enable|r" or "Enable" end,
        nil, 2, nil, nil, nil,
        function() return TUI.db.profile.nameplates.importantCast.enabled end,
        function(_, value)
            TUI.db.profile.nameplates.importantCast.enabled = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )

    local impDB = function() return TUI.db.profile.nameplates.importantCast end
    local impDisabled = function() return not impDB().enabled end

    -- Castbar
    npImp.castbar = ACH:Group("Castbar", nil, 10)
    npImp.castbar.inline = true
    local cb = npImp.castbar.args
    local cbDB = function() return impDB().castbar end

    cb.borderEnabled = ACH:Toggle("Show Border", nil, 1, nil, nil, nil,
        function() return cbDB().borderEnabled end,
        function(_, v) cbDB().borderEnabled = v end, impDisabled)

    cb.classColor = ACH:Toggle("Class Color", "Use your class color for the border.", 2, nil, nil, nil,
        function() return cbDB().classColor end,
        function(_, v) cbDB().classColor = v end,
        function() return impDisabled() or not cbDB().borderEnabled end)

    cb.thickness = ACH:Range("Thickness", nil, 3, { min = 1, max = 5, step = 1 }, nil,
        function() return cbDB().thickness end,
        function(_, v) cbDB().thickness = v end,
        function() return impDisabled() or not cbDB().borderEnabled end)

    cb.borderColor = ACH:Color("Border Color", nil, 4, true, nil,
        function() local c = cbDB().borderColor; return c.r, c.g, c.b, c.a end,
        function(_, r, g, b, a) local c = cbDB().borderColor; c.r, c.g, c.b, c.a = r, g, b, a end,
        function() return impDisabled() or not cbDB().borderEnabled or cbDB().classColor end)

    cb.colorEnabled = ACH:Toggle("Override Bar Color", nil, 5, nil, nil, nil,
        function() return cbDB().colorEnabled end,
        function(_, v) cbDB().colorEnabled = v end, impDisabled)

    cb.barColor = ACH:Color("Bar Color", nil, 6, nil, nil,
        function() local c = cbDB().barColor; return c.r, c.g, c.b end,
        function(_, r, g, b) local c = cbDB().barColor; c.r, c.g, c.b = r, g, b end,
        function() return impDisabled() or not cbDB().colorEnabled end)

    cb.texture = ACH:SharedMediaStatusbar("Texture", nil, 7, nil,
        function() local t = cbDB().texture; return (t and t ~= '') and t or E.private.general.normTex end,
        function(_, v) local def = E.private.general.normTex; cbDB().texture = (v == def) and '' or v end, impDisabled)

    -- Health
    npImp.health = ACH:Group("Health Bar", nil, 20)
    npImp.health.inline = true
    local hp = npImp.health.args
    local hpDB = function() return impDB().health end

    hp.overlayEnabled = ACH:Toggle("Color Overlay", "Show a colored overlay on the health bar during important casts.", 1, nil, nil, nil,
        function() return hpDB().overlayEnabled end,
        function(_, v) hpDB().overlayEnabled = v end, impDisabled)

    hp.overlayColor = ACH:Color("Overlay Color", nil, 2, true, nil,
        function() local c = hpDB().overlayColor; return c.r, c.g, c.b, c.a end,
        function(_, r, g, b, a) local c = hpDB().overlayColor; c.r, c.g, c.b, c.a = r, g, b, a end,
        function() return impDisabled() or not hpDB().overlayEnabled end)

    hp.borderEnabled = ACH:Toggle("Show Border", nil, 3, nil, nil, nil,
        function() return hpDB().borderEnabled end,
        function(_, v) hpDB().borderEnabled = v end, impDisabled)

    hp.borderColor = ACH:Color("Border Color", nil, 4, true, nil,
        function() local c = hpDB().borderColor; return c.r, c.g, c.b, c.a end,
        function(_, r, g, b, a) local c = hpDB().borderColor; c.r, c.g, c.b, c.a = r, g, b, a end,
        function() return impDisabled() or not hpDB().borderEnabled end)

    hp.thickness = ACH:Range("Border Thickness", nil, 5, { min = 1, max = 5, step = 1 }, nil,
        function() return hpDB().thickness end,
        function(_, v) hpDB().thickness = v end,
        function() return impDisabled() or not hpDB().borderEnabled end)

    elv.hover = ACH:Group("Hover Highlight", nil, 3)
    elv.hover.inline = true
    local npHover = elv.hover.args

    npHover.hoverEnabled = ACH:Toggle(
        function() return TUI.db.profile.nameplates.hoverHighlight.enabled and "|cff00ff00Enable|r" or "Enable" end,
        "Replace the default mouseover overlay with a colored border around the nameplate health bar.",
        1, nil, nil, nil,
        function() return TUI.db.profile.nameplates.hoverHighlight.enabled end,
        function(_, value)
            TUI.db.profile.nameplates.hoverHighlight.enabled = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )

    npHover.classColor = ACH:Toggle(
        "Class Color",
        "Use your class color for the hover border instead of a custom color.",
        2, nil, nil, nil,
        function() return TUI.db.profile.nameplates.hoverHighlight.classColor end,
        function(_, value)
            TUI.db.profile.nameplates.hoverHighlight.classColor = value
        end,
        function() return not TUI.db.profile.nameplates.hoverHighlight.enabled end
    )

    npHover.thickness = ACH:Range(
        "Thickness", "Pixel thickness of the hover border.", 3,
        { min = 1, max = 5, step = 1 }, nil,
        function() return TUI.db.profile.nameplates.hoverHighlight.thickness end,
        function(_, value) TUI.db.profile.nameplates.hoverHighlight.thickness = value end,
        function() return not TUI.db.profile.nameplates.hoverHighlight.enabled end
    )

    npHover.hoverColor = ACH:Color(
        "Border Color", "Color of the hover highlight border.", 4, true, nil,
        function()
            local c = TUI.db.profile.nameplates.hoverHighlight.color
            return c.r, c.g, c.b, c.a
        end,
        function(_, r, g, b, a)
            local c = TUI.db.profile.nameplates.hoverHighlight.color
            c.r, c.g, c.b, c.a = r, g, b, a
        end,
        function()
            local h = TUI.db.profile.nameplates.hoverHighlight
            return not h.enabled or h.classColor
        end
    )

    elv.quest = ACH:Group("Quest Color", nil, 3)
    elv.quest.inline = true
    local npQuest = elv.quest.args

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

    elv.highlight = ACH:Group("Friendly Nameplates", nil, 5)
    elv.highlight.inline = true
    local npHL = elv.highlight.args

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

    elv.focus = ACH:Group("Focus Indicator", nil, 4)
    elv.focus.inline = true
    local npFocus = elv.focus.args

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

    -- Platynator sub-group
    root.nameplates.args.platynator = ACH:Group("Platynator", nil, 2)
    root.nameplates.args.platynator.disabled = not platyEnabled
    local platy = root.nameplates.args.platynator.args

    platy.highlights = ACH:Group("Highlights", nil, 1)
    platy.highlights.inline = true
    platy.highlights.args.classColorTarget = ACH:Toggle(
        "Class Color Target",
        "Color the target highlight with your class color instead of the design default.",
        1, nil, nil, nil,
        function() return TUI.db.profile.platynator.classColorTarget end,
        function(_, value)
            TUI.db.profile.platynator.classColorTarget = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )
    platy.highlights.args.classColorTarget.customWidth = 250
    platy.highlights.args.classColorMouseover = ACH:Toggle(
        "Class Color Mouseover",
        "Color the mouseover highlight with your class color instead of the design default.",
        2, nil, nil, nil,
        function() return TUI.db.profile.platynator.classColorMouseover end,
        function(_, value)
            TUI.db.profile.platynator.classColorMouseover = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )
    platy.highlights.args.classColorMouseover.customWidth = 250

    platy.playerNames = ACH:Group("Player Names", nil, 2)
    platy.playerNames.inline = true
    platy.playerNames.args.classColorNames = ACH:Toggle(
        "Custom Class Color Names",
        "Use ElvUI custom class colors for friendly player names instead of Blizzard defaults.",
        1, nil, nil, nil,
        function() return TUI.db.profile.platynator.classColorNames end,
        function(_, value)
            TUI.db.profile.platynator.classColorNames = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )
    platy.playerNames.args.classColorNames.customWidth = 250
end
