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

end
