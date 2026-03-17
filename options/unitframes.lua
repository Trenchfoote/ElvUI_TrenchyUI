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

    root.unitframes.args.fakePower = ACH:Group("Custom Class Bars", nil, 3)
    root.unitframes.args.fakePower.inline = true
    local fp = root.unitframes.args.fakePower.args

    fp.soulFragments = ACH:Toggle(
        "VDH: Soul Fragments",
        "Show a Soul Fragments class bar for Vengeance Demon Hunters. Anchors to the ElvUI class bar mover.",
        1, nil, nil, nil,
        function() return TUI.db.profile.fakePower.soulFragments end,
        function(_, value)
            TUI.db.profile.fakePower.soulFragments = value
            E:StaticPopup_Show('CONFIG_RL')
        end
    )
end
