local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local ACH = E.Libs.ACH

function TUI:BuildSkinsConfig(root, tuiName)
    root.skins = ACH:Group("Skins", nil, 5)
    local skins = root.skins.args

    skins.addons = ACH:Group("AddOns", nil, 1)
    skins.addons.inline = true

    local skinDefs = {
        { key = "skinAuctionator", addon = "Auctionator", label = "Auctionator", order = 1 },
        { key = "skinBigWigs",     addon = "BigWigs",     label = "BigWigs",      order = 2 },
        { key = "skinBugSack",     addon = "BugSack",     label = "BugSack",      order = 3 },
        { key = "skinOPie",        addon = "OPie",        label = "OPie",         order = 4 },
        { key = "skinPlatynator",  addon = "Platynator",    label = "Platynator",   order = 5 },
        { key = "skinWarpDeplete",    addon = "WarpDeplete",    label = "WarpDeplete",      order = 6 },
        { key = "skinPremadeGroupsFilter", addon = "PremadeGroupsFilter", label = "Premade Groups Filter", order = 7 },
        { key = "skinTalentLoadoutManager", addon = "TalentLoadoutManager", label = "Talent Loadout Manager", order = 8 },
    }

    for _, def in ipairs(skinDefs) do
        skins.addons.args[def.key] = ACH:Toggle(def.label, nil, def.order, nil, nil, nil,
            function() return TUI.db.profile.addons[def.key] end,
            function(_, value)
                TUI.db.profile.addons[def.key] = value
                E:StaticPopup_Show('CONFIG_RL')
            end,
            function() return not E:IsAddOnEnabled(def.addon) end
        )
    end

    skins.slug = ACH:Group("Slug Font Rendering", nil, 2)
    skins.slug.inline = true
    local slug = skins.slug.args

    slug.desc = ACH:Description(
        "Enable Slug GPU font rendering on addon bar text. Produces sharper outlines that scale with text size.",
        1, "medium"
    )

    slug.slugBigWigs = ACH:Toggle("BigWigs Bars", "Apply Slug rendering to BigWigs bar text.", 2, nil, nil, nil,
        function() return TUI.db.profile.addons.slugBigWigs end,
        function(_, value)
            TUI.db.profile.addons.slugBigWigs = value
            E:StaticPopup_Show('CONFIG_RL')
        end,
        function() return not E:IsAddOnEnabled('BigWigs') end
    )

    slug.slugWarpDeplete = ACH:Toggle("WarpDeplete", "Apply Slug rendering to WarpDeplete text.", 3, nil, nil, nil,
        function() return TUI.db.profile.addons.slugWarpDeplete end,
        function(_, value)
            TUI.db.profile.addons.slugWarpDeplete = value
            E:StaticPopup_Show('CONFIG_RL')
        end,
        function() return not E:IsAddOnEnabled('WarpDeplete') end
    )
end
