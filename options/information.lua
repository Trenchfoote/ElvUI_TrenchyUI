local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local ACH = E.Libs.ACH

function TUI:BuildInformationConfig(root, tuiName)
    root.info = ACH:Group("Information", nil, 7)
    local info = root.info.args

    info.about = ACH:Group("About", nil, 1)
    info.about.inline = true
    info.about.args.desc = ACH:Description(tuiName .. " is a minimalistic quality of life plugin for ElvUI.", 1, "medium")

    info.links = ACH:Group("Links", nil, 2)
    info.links.inline = true
    info.links.args.discord = ACH:Input(E:TextGradient('The Igloo Community Discord', 0.89,0.99,1.00, 0.84,1.00,1.00, 0.45,0.66,0.67, 0.42,0.72,0.95, 0.15,0.49,0.64, 0.04,0.37,0.57), nil, 1, nil, 255, function() return 'https://discord.gg/24wXBTPD' end)
    info.links.args.discord.focusSelect = true

    info.credits = ACH:Group("Credits", nil, 3)
    info.credits.inline = true
    info.credits.args.desc = ACH:Description(
        E:TextGradient('Jiberish', 1.00,0.08,0.56, 1.00,0.41,0.71) .. " — For the encouragement to actually do this, permission to use his Fabled icons, and for letting me die in keys while you were tinkering with your UI.\n\n"
        .. E:TextGradient('Requiem', 0.13,0.37,0.13, 0.30,0.57,0.25) .. " — For entertaining me while making this, and being the first tester and adopter of " .. tuiName .. ", your feedback has helped shape this plugin.\n\n"
        .. E:TextGradient('Menios', 0.64,0.19,0.79, 0.46,0.33,0.80) .. " — For the 10+ years of trolling and entertainment, and helping me kill 4+ Guilds during Legion.\n\n"
        .. E:TextGradient('Nessa', 0.00,0.43,1.00, 0.30,0.65,1.00) .. " — For years of splashing me with the shaman heals and being the best healer ever.\n\n"
        .. "|cFFb8bb26Thurin|r — For bouncing all the ideas off of and balancing Jib's uncontrollable \"push the buttons\".\n\n"
        .. "|cFFAAD372Tsxy|r — For testing and helping with iterative ideas on TDM and MBB.\n\n"
        .. E:TextGradient('Simpy but my name needs to be longer', 0.28,0.79,0.96, 0.50,0.77,0.38, 1.00,0.95,0.38, 0.96,0.53,0.37, 0.80,0.51,0.72, 0.34,0.80,0.96)
        .. " — For the chats and discussion while testing some ElvUI stuff. It's been a pleasure getting to dig in.\n\n"
        .. "|CFF6559F1B|r|CFF7A4DEFl|r|CFF8845ECi|r|CFFA037E9n|r|CFFB32DE6k|r|CFFBC26E5i|r|CFFCB1EE3i|r — For allowing me to use his module for the interrupt ready, and for always being receptive to new ideas with |CFF6559F1m|r|CFF7A4DEFM|r|CFF8845ECe|r|CFFA037E9d|r|CFFA435E8i|r|CFFB32DE6a|r|CFFBC26E5T|r|CFFCB1EE3a|r|CFFDD14E0g|r|CFFE609DFs|r.\n\n"
        .. "And, " .. E:TextGradient('The Igloo Community', 0.89,0.99,1.00, 0.84,1.00,1.00, 0.45,0.66,0.67, 0.42,0.72,0.95, 0.15,0.49,0.64, 0.04,0.37,0.57) .. ", for the constant feedback on this simplistic UI...you guys are awesome!",
        1, "medium"
    )
end
