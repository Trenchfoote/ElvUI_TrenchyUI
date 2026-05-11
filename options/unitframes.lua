local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local ACH = E.Libs.ACH

function TUI:BuildUnitFramesConfig(root, tuiName)
    root.unitframes = ACH:Group("UnitFrames", nil, 3)

    root.unitframes.args.pixelGlow = ACH:Group("Pixel Glow", nil, 1)
    root.unitframes.args.pixelGlow.inline = true
    local uf = root.unitframes.args.pixelGlow.args

    uf.auraDesc = ACH:Description(
        "Replaces ElvUI's built-in Aura Highlight (GLOW/FILL) with a Pixel Glow "
        .. "on unit frames when a dispellable debuff is detected. "
        .. "Uses ElvUI's existing debuff highlight colors.",
        1, "medium"
    )

    uf.auraEnabled = ACH:Toggle(
        function() return TUI.db.profile.pixelGlow.enabled and "|cff00ff00Enable|r" or "Enable" end,
        "Replace ElvUI's Aura Highlight with a Pixel Glow effect.",
        2, nil, nil, nil,
        function() return TUI.db.profile.pixelGlow.enabled end,
        function(_, value)
            TUI.db.profile.pixelGlow.enabled = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )

    local auraDisabled = function() return not TUI.db.profile.pixelGlow.enabled end

    uf.auraLines = ACH:Range(
        "Lines", "Number of animated glow lines around the frame.", 3,
        { min = 1, max = 20, step = 1 }, nil,
        function() return TUI.db.profile.pixelGlow.lines end,
        function(_, value) TUI.db.profile.pixelGlow.lines = value end,
        auraDisabled
    )

    uf.auraSpeed = ACH:Range(
        "Speed", "Animation speed (cycles per second). Higher = faster.", 4,
        { min = 0.05, max = 1, step = 0.05, isPercent = false }, nil,
        function() return TUI.db.profile.pixelGlow.speed end,
        function(_, value) TUI.db.profile.pixelGlow.speed = value end,
        auraDisabled
    )

    uf.auraThickness = ACH:Range(
        "Thickness", "Pixel thickness of the glow lines.", 5,
        { min = 1, max = 5, step = 1 }, nil,
        function() return TUI.db.profile.pixelGlow.thickness end,
        function(_, value) TUI.db.profile.pixelGlow.thickness = value end,
        auraDisabled
    )

    root.unitframes.args.fader = ACH:Group("Fader", nil, 2)
    root.unitframes.args.fader.inline = true
    local ufFader = root.unitframes.args.fader.args

    ufFader.steadyFlight = ACH:Toggle(
        "Steady Flight",
        "Extend ElvUI's Dynamic Flight fader to also fade during steady (normal) flight. Requires the Player unitframe Fader with Dynamic Flight enabled.",
        1, nil, nil, nil,
        function() return TUI.db.profile.fader.steadyFlight end,
        function(_, value)
            TUI.db.profile.fader.steadyFlight = value
            local pf = _G.ElvUF_Player
            if pf and pf.Fader and pf.Fader.ForceUpdate then
                pf.Fader:ForceUpdate()
            end
        end
    )

    root.unitframes.args.absorbTexture = ACH:Group("Absorb Textures", nil, 2.7)
    root.unitframes.args.absorbTexture.inline = true
    local abs = root.unitframes.args.absorbTexture.args

    abs.desc = ACH:Description(
        "Override the statusbar texture for absorb indicators on unit frames. "
        .. "Applies to both normal and over-absorb states. Leave at default to use ElvUI's health bar texture.",
        1, "medium"
    )

    abs.damageAbsorb = ACH:SharedMediaStatusbar(
        "Absorbs / Over Absorbs", "Texture for damage absorb shields (Power Word: Shield, etc.).", 2, nil,
        function()
            local t = TUI.db.profile.absorbTexture.damageAbsorb
            return (t and t ~= '') and t or E.private.general.normTex
        end,
        function(_, value)
            local def = E.private.general.normTex
            TUI.db.profile.absorbTexture.damageAbsorb = (value == def) and '' or value
            local UF = E:GetModule('UnitFrames')
            UF:Update_AllFrames()
        end
    )

    abs.healAbsorb = ACH:SharedMediaStatusbar(
        "Heal Absorbs / Over Heal Absorbs", "Texture for heal absorption effects (Necrotic Wound, etc.).", 3, nil,
        function()
            local t = TUI.db.profile.absorbTexture.healAbsorb
            return (t and t ~= '') and t or E.private.general.normTex
        end,
        function(_, value)
            local def = E.private.general.normTex
            TUI.db.profile.absorbTexture.healAbsorb = (value == def) and '' or value
            local UF = E:GetModule('UnitFrames')
            UF:Update_AllFrames()
        end
    )

    root.unitframes.args.groupPower = ACH:Group("Group Power", nil, 3)
    root.unitframes.args.groupPower.inline = true
    local gp = root.unitframes.args.groupPower.args

    gp.desc = ACH:Description(
        "Extend ElvUI's 'Only Healer' power bar filter to also show resource bars for Blood Death Knights (Runic Power) and Brewmaster Monks (Stagger) in group frames.",
        1, "medium"
    )

    gp.tankPower = ACH:Toggle(
        "Include Tank Power",
        "Show resource bars for Blood DK (Runic Power) and Brewmaster Monk (Stagger) when 'Only Healer' is enabled in ElvUI's party/raid power settings.",
        2, nil, nil, nil,
        function() return TUI.db.profile.tankPower end,
        function(_, value)
            TUI.db.profile.tankPower = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )

    root.unitframes.args.privateAuras = ACH:Group("Private Aura Preview", nil, 4)
    root.unitframes.args.privateAuras.inline = true
    local pa = root.unitframes.args.privateAuras.args

    pa.desc = ACH:Description(
        "Show fake private aura icons at ElvUI's configured anchors while using ElvUI's Show/Hide Auras preview. "
        .. "Lets you see where real private auras will land — the number of slots mirrors your ElvUI Private Aura settings.",
        1, "medium"
    )

    pa.enabled = ACH:Toggle(
        function() return TUI.db.profile.privateAuras.enabled and "|cff00ff00Include Private Auras|r" or "Include Private Auras" end,
        "Show fake private aura icons during ElvUI's Show/Hide Auras preview.",
        2, nil, nil, nil,
        function() return TUI.db.profile.privateAuras.enabled end,
        function(_, value)
            TUI.db.profile.privateAuras.enabled = value
            local UFC = E:GetModule('TUI_UnitFrames', true)
            if UFC and UFC.RefreshPrivateAuraPreview then UFC:RefreshPrivateAuraPreview() end
        end
    )

    -- Ironfur Bar (Druid only)
    if E.myclass == 'DRUID' then
        local function refreshIronfur()
            local UFC = E:GetModule('TUI_UnitFrames', true)
            if UFC and UFC.RefreshIronfurBar then UFC:RefreshIronfurBar() end
        end
        local function ifDB() return TUI.db.profile.ironfurBar end
        local function ifDisabled() return not ifDB().enabled end
        local function ifStacksDisabled() return not ifDB().enabled or not ifDB().useStackColors end

        root.unitframes.args.ironfur = ACH:Group(E.NewSign .. "Ironfur Bar", nil, 5)
        root.unitframes.args.ironfur.inline = true
        local ifg = root.unitframes.args.ironfur.args

        ifg.desc = ACH:Description(
            "Guardian Druid only. A multi-tick bar showing each active Ironfur stack. "
            .. "Each cast spawns its own tick that drains right-to-left; stack count drives the leading bar color. "
            .. "Talent-aware: Ursoc's Endurance (9s base), Guardian of Elune (+3s after Mangle, consumed by next Ironfur or Frenzied Regeneration).",
            1, "medium"
        )

        ifg.enabled = ACH:Toggle(
            function() return ifDB().enabled and "|cff00ff00Enable|r" or "Enable" end,
            "Enable the Ironfur tracker bar (Guardian spec only).",
            2, nil, nil, nil,
            function() return ifDB().enabled end,
            function(_, value)
                ifDB().enabled = value
                if value then
                    local UFC = E:GetModule('TUI_UnitFrames', true)
                    if UFC and UFC.InitIronfurBar then UFC:InitIronfurBar() end
                end
                E:StaticPopup_Show('CONFIG_RL')
            end
        )

        ifg.counterMode = ACH:Select(
            "Counter Text", "What to display in the center of the bar.", 3, {
                off     = "Off",
                stacks  = "Stack Count",
                seconds = "Seconds Remaining",
                both    = "Both (e.g. 3x 4s)",
            }, nil, nil,
            function() return ifDB().counterMode end,
            function(_, value) ifDB().counterMode = value; refreshIronfur() end,
            ifDisabled
        )

        ifg.counterFontSize = ACH:Range(
            "Counter Font Size", "Font size for the center counter text.", 4,
            { min = 8, max = 32, step = 1 }, nil,
            function() return ifDB().counterFontSize end,
            function(_, value) ifDB().counterFontSize = value; refreshIronfur() end,
            ifDisabled
        )

        ifg.showWhenInactive = ACH:Toggle(
            "Show When Inactive",
            "Keep the bar visible (empty) even when no Ironfur stacks are up.",
            5, nil, nil, nil,
            function() return ifDB().showWhenInactive end,
            function(_, value) ifDB().showWhenInactive = value; refreshIronfur() end,
            ifDisabled
        )

        ifg.uniformTickSpeed = ACH:Toggle(
            "Uniform Tick Speed",
            "All ticks drain at the same visual rate (based on max possible duration). "
            .. "Off: each tick drains at its own rate (so a Guardian-of-Elune-bonused tick visibly moves slower).",
            6, nil, nil, nil,
            function() return ifDB().uniformTickSpeed end,
            function(_, value) ifDB().uniformTickSpeed = value end,
            ifDisabled
        )

        ifg.tickColor = ACH:Color(
            "Tick Color", "Color of Ironfur cast ticks.", 7, true, nil,
            function()
                local c = ifDB().tickColor
                return c.r, c.g, c.b, c.a
            end,
            function(_, r, g, b, a)
                local c = ifDB().tickColor
                c.r, c.g, c.b, c.a = r, g, b, a
                refreshIronfur()
            end,
            ifDisabled
        )

        ifg.useStackColors = ACH:Toggle(
            "Color Leading Bar by Stack Count",
            "Color the leading-tick fill bar by current stack count. Off: uses the tick color.",
            11, nil, nil, nil,
            function() return ifDB().useStackColors end,
            function(_, value) ifDB().useStackColors = value end,
            ifDisabled
        )

        for i, label in ipairs({ "1 Stack", "2 Stacks", "3 Stacks", "4+ Stacks" }) do
            ifg['stack' .. i] = ACH:Color(
                label, "Leading-bar color when " .. label:lower() .. " of Ironfur are active.", 11 + i, true, nil,
                function()
                    local c = ifDB().stackColors[i]
                    return c.r, c.g, c.b, c.a
                end,
                function(_, r, g, b, a)
                    local c = ifDB().stackColors[i]
                    c.r, c.g, c.b, c.a = r, g, b, a
                end,
                ifStacksDisabled
            )
        end
    end

end
