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
        { key = "skinWorldQuestTab",          addon = "WorldQuestTab",       label = "World Quest Tab",       order = 7 },
        { key = "skinPremadeGroupsFilter", addon = "PremadeGroupsFilter", label = "Premade Groups Filter", order = 8 },
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
end
