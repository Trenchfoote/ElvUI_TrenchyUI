local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local ACH = E.Libs.ACH

function TUI:BuildProfilesConfig(root, tuiName)
    root.profiles = ACH:Group("Profiles", nil, 6)
    local prof = root.profiles.args

    prof.resWarning = ACH:Description("|cffff2f3dProfiles are designed for 1440p. If you use a different screen resolution, you will need to adjust frame positions and sizes.|r", 1, "medium")

    prof.installAll = ACH:Group("Install All", nil, 2)
    prof.installAll.inline = true
    local allArgs = prof.installAll.args

    local function elvuiVersionLabel()
        local installed = E.db.TrenchyUI and E.db.TrenchyUI.installedProfileVersion
        if not installed then return "ElvUI" end
        if installed == TUI.profileVersion then
            return "ElvUI (v" .. installed .. ")"
        end
        return "ElvUI (v" .. installed .. " > v" .. TUI.profileVersion .. ")"
    end

    local function elvuiVersionDesc()
        local installed = E.db.TrenchyUI and E.db.TrenchyUI.installedProfileVersion
        if not installed then return "Creates a new profile — your current profile is not modified." end
        if installed == TUI.profileVersion then
            return "Your TrenchyUI profile is up to date. Reinstalling will reset any customizations."
        end
        return "A profile update is available. Installing will overwrite your current TrenchyUI settings."
    end

    allArgs.desc = ACH:Description("Apply ElvUI, BigWigs, WarpDeplete, LS: Toasts, and Platynator profiles in one click.", 1, "medium")
    allArgs.install = ACH:Execute("Install All Profiles", nil, 2, function()
        E:StaticPopup_Show('TUI_INSTALL_ALL')
    end)

    prof.individual = ACH:Group("Individual Profiles", nil, 3)
    prof.individual.inline = true
    local indArgs = prof.individual.args

    indArgs.installElvUI = ACH:Execute(elvuiVersionLabel, elvuiVersionDesc, 1, function()
        E:StaticPopup_Show('TUI_INSTALL_ELVUI')
    end)

    local function addonDisabled(name)
        return function() return not E:IsAddOnEnabled(name) end
    end

    indArgs.installBigWigs = ACH:Execute("BigWigs", "Imports the TrenchyUI layout into BigWigs.", 2, function()
        TUI:ApplyBigWigsProfile(function(accepted)
            if accepted then
                E:Print(tuiName .. ": BigWigs profile applied.")
                E:StaticPopup_Show('CONFIG_RL')
            end
        end)
    end, nil, nil, nil, nil, nil, addonDisabled('BigWigs'))

    indArgs.installWarpDeplete = ACH:Execute("WarpDeplete", "Imports the TrenchyUI M+ timer layout.", 3, function()
        TUI:ApplyWarpDepleteProfile()
        E:Print(tuiName .. ": WarpDeplete profile applied.")
        E:StaticPopup_Show('CONFIG_RL')
    end, nil, nil, nil, nil, nil, addonDisabled('WarpDeplete'))

    indArgs.installLSToasts = ACH:Execute("LS: Toasts", "Imports the TrenchyUI toast layout.", 4, function()
        TUI:ApplyLSToastsProfile()
        E:Print(tuiName .. ": LS: Toasts profile applied.")
        E:StaticPopup_Show('CONFIG_RL')
    end, nil, nil, nil, nil, nil, addonDisabled('ls_Toasts'))

    indArgs.installPlatynator = ACH:Execute("Platynator", "Imports the TrenchyUI nameplate design into Platynator.", 5, function()
        TUI:ApplyPlatynatorProfile()
        E:Print(tuiName .. ": Platynator profile applied.")
        E:StaticPopup_Show('CONFIG_RL')
    end, nil, nil, nil, nil, nil, addonDisabled('Platynator'))

    indArgs.installBaganator = ACH:Execute("Baganator", "Imports TrenchyUI bag categories into Baganator.", 6, function()
        TUI:ApplyBaganatorProfile()
        E:Print(tuiName .. ": Baganator categories applied.")
        E:StaticPopup_Show('CONFIG_RL')
    end, nil, nil, nil, nil, nil, addonDisabled('Baganator'))

    -- Inject TUI datatext options into ElvUI's Customization tab
    do
        local dtSettings = E.Options.args.datatexts.args.settings.args
        local tuiGradient = function(text) return E:TextGradient(text, 1.00,0.18,0.24, 0.80,0.10,0.20) end

        local function dtGet(name, key)
            return E.global.datatexts.settings[name][key]
        end
        local function dtSet(name, key, value)
            E.global.datatexts.settings[name][key] = value
        end

        -- TUI Guild
        local guildOpts = dtSettings['TUI Guild']
        if guildOpts then
            guildOpts.name = tuiGradient('TUI Guild')
            guildOpts.args.hideMOTD = ACH:Toggle('Hide MOTD', 'Hide the guild Message of the Day in the tooltip.', 10)
            guildOpts.args.hideRealm = ACH:Toggle('Hide Realm', 'Remove realm names from guild member names in the tooltip.', 11)
            guildOpts.args.tooltipFontGroup = ACH:Group('Tooltip Font', nil, 20)
            guildOpts.args.tooltipFontGroup.inline = true
            local gf = guildOpts.args.tooltipFontGroup.args
            gf.tooltipFont = ACH:SharedMediaFont('Font', nil, 1, nil,
                function() return dtGet('TUI Guild', 'tooltipFont') end,
                function(_, value) dtSet('TUI Guild', 'tooltipFont', value) end)
            gf.tooltipFontSize = ACH:Range('Size', nil, 2, { min = 6, max = 22, step = 1 }, nil,
                function() return dtGet('TUI Guild', 'tooltipFontSize') end,
                function(_, value) dtSet('TUI Guild', 'tooltipFontSize', value) end)
            gf.tooltipFontOutline = ACH:FontFlags('Outline', nil, 3, nil,
                function() return dtGet('TUI Guild', 'tooltipFontOutline') end,
                function(_, value) dtSet('TUI Guild', 'tooltipFontOutline', value) end)
        end

        -- TUI Friends
        local friendsOpts = dtSettings['TUI Friends']
        if friendsOpts then
            friendsOpts.name = tuiGradient('TUI Friends')
            friendsOpts.args.hideMobile = ACH:Toggle('Hide Mobile', 'Hide friends on the Battle.net Mobile app.', 10)
            friendsOpts.args.tooltipFontGroup = ACH:Group('Tooltip Font', nil, 20)
            friendsOpts.args.tooltipFontGroup.inline = true
            local ff = friendsOpts.args.tooltipFontGroup.args
            ff.tooltipFont = ACH:SharedMediaFont('Font', nil, 1, nil,
                function() return dtGet('TUI Friends', 'tooltipFont') end,
                function(_, value) dtSet('TUI Friends', 'tooltipFont', value) end)
            ff.tooltipFontSize = ACH:Range('Size', nil, 2, { min = 6, max = 22, step = 1 }, nil,
                function() return dtGet('TUI Friends', 'tooltipFontSize') end,
                function(_, value) dtSet('TUI Friends', 'tooltipFontSize', value) end)
            ff.tooltipFontOutline = ACH:FontFlags('Outline', nil, 3, nil,
                function() return dtGet('TUI Friends', 'tooltipFontOutline') end,
                function(_, value) dtSet('TUI Friends', 'tooltipFontOutline', value) end)
        end
    end

    -- Inject Click Casting shortcut button into ElvUI ActionBars config
    do
        local abArgs = E.Options.args.actionbar and E.Options.args.actionbar.args
        if abArgs then
            abArgs.clickCasting = ACH:Execute(E:TextGradient('Click Casting', 1.00,0.18,0.24, 0.80,0.10,0.20), nil, 2.5, function()
                if not _G['ClickBindingFrame'] then
                    C_AddOns.LoadAddOn('Blizzard_ClickBindingUI')
                end
                if _G['ClickBindingFrame_Toggle'] then
                    _G['ClickBindingFrame_Toggle']()
                end
            end, nil, nil, 160)
        end
    end

    -- Popup dialogs for profile installation
    local function installAllText()
        local installed = E.db.TrenchyUI and E.db.TrenchyUI.installedProfileVersion
        if not installed then
            return "This will install the " .. tuiName .. " profile for ElvUI and all supported addons.\n\nYour current ElvUI profile will not be modified \226\128\148 a new one will be created.\n\nProceed?"
        end
        return "This will update the " .. tuiName .. " profile for ElvUI and all supported addons.\n\nYour current " .. tuiName .. " settings will be overwritten.\n\nProceed?"
    end

    local function installElvUIText()
        local installed = E.db.TrenchyUI and E.db.TrenchyUI.installedProfileVersion
        if not installed then
            return "This will install the |cff1784d1ElvUI|r profile only.\n\nA new profile called " .. tuiName .. " will be created \226\128\148 your current profile is not modified.\n\nProceed?"
        end
        return "This will update the " .. tuiName .. " profile.\n\nYour current ElvUI settings will be overwritten.\n\nProceed?"
    end

    E.PopupDialogs.TUI_INSTALL_ALL = {
        text = installAllText(),
        button1 = "Install",
        button2 = "Cancel",
        OnAccept = function()
            TUI:ApplyElvUIProfile()
            if E:IsAddOnEnabled('WarpDeplete') and TUI.ApplyWarpDepleteProfile then TUI:ApplyWarpDepleteProfile() end
            if E:IsAddOnEnabled('ls_Toasts') and TUI.ApplyLSToastsProfile then TUI:ApplyLSToastsProfile() end
            if E:IsAddOnEnabled('Platynator') and TUI.ApplyPlatynatorProfile then TUI:ApplyPlatynatorProfile() end
            if E:IsAddOnEnabled('Baganator') and TUI.ApplyBaganatorProfile then TUI:ApplyBaganatorProfile() end

            if _G['BigWigsAPI'] and TUI.ApplyBigWigsProfile then
                E.db.TrenchyUI._pendingBigWigsProfile = true
            end

            E.db.TrenchyUI._profileJustInstalled = 'all'
            -- Switch private profile last — triggers ReloadUI via ElvUI callback.
            TUI:SwitchPrivateProfile()
            ReloadUI() -- fallback if already on this private profile
        end,
        whileDead = 1,
        hideOnEscape = true,
    }

    E.PopupDialogs.TUI_INSTALL_ELVUI = {
        text = installElvUIText(),
        button1 = "Install",
        button2 = "Cancel",
        OnAccept = function()
            TUI:ApplyElvUIProfile()
            E.db.TrenchyUI._profileJustInstalled = 'elvui'
            -- Switch private profile last — triggers ReloadUI via ElvUI callback.
            TUI:SwitchPrivateProfile()
            ReloadUI() -- fallback if already on this private profile
        end,
        whileDead = 1,
        hideOnEscape = true,
    }
end
