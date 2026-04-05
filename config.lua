local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local ACH = E.Libs.ACH

TUI.defaults = {
    profile = {
        installedProfileVersion = nil,
        colorMode = 'dark',
        borderMode = false,
        compat = {},
        qol = {
            hideTalkingHead = false,
            autoFillDelete  = false,
            moveableFrames  = false,
            fastLoot        = false,
            hideObjectiveInCombat = false,
            shortenEnchantStrings = false,
            cursorCircle    = false,
            cursorCircleSize = 64,
            cursorCircleThickness = 'medium',
            cursorCircleClassColor = false,
            cursorCircleColor = { r = 1.0, g = 1.0, b = 1.0, a = 0.6 },
            difficultyText  = false,
            difficultyFont    = 'Expressway',
            difficultyFontSize = 14,
            difficultyFontOutline = 'OUTLINE',
            difficultyColors = {
                normal      = { r = 0.60, g = 0.60, b = 0.60 },
                heroic      = { r = 0.00, g = 0.44, b = 0.87 },
                mythic      = { r = 0.78, g = 0.00, b = 1.00 },
                keystoneMod = { r = 1.00, g = 0.50, b = 0.00 },
                timewalking = { r = 0.00, g = 0.80, b = 0.60 },
                lfr         = { r = 0.00, g = 0.80, b = 0.00 },
                follower    = { r = 0.80, g = 0.80, b = 0.80 },
                delve       = { r = 0.80, g = 0.60, b = 0.20 },
                other       = { r = 1.00, g = 1.00, b = 1.00 },
            },
        },
        addons = {
            skinWarpDeplete = false,
            skinBigWigs     = false,
            skinAuctionator = false,
            skinOPie        = false,
            skinBugSack     = false,
            skinPlatynator  = false,
        },
        nameplates = {
            classColorTargetIndicator = false,
            interruptCastbarColors      = false,
            castbarInterruptReady       = { r = 0.2, g = 0.8, b = 0.2 },
            castbarInterruptOnCD        = { r = 0.9, g = 0.4, b = 0.1 },
            castbarMarkerColor          = { r = 1.0, g = 1.0, b = 1.0 },
            questColor = {
                enabled = false,
                color   = { r = 1.0, g = 0.8, b = 0.0 },
            },
            hideFriendlyRealm = false,
            disableFriendlyHighlight = false,
            importantCast = {
                enabled = false,
                classColor = false,
                thickness = 2,
                color   = { r = 1.0, g = 0.0, b = 0.0, a = 1.0 },
            },
            hoverHighlight = {
                enabled = false,
                classColor = false,
                thickness = 2,
                color   = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
            },
            focusGlow = {
                enabled = false,
                color   = { r = 0.5, g = 0.3, b = 0.9, a = 0.3 },
                texture = 'TrenchyFocus',
            },
        },
        platynator = {
            classColorTarget   = false,
            classColorMouseover = false,
            classColorNames = false,
        },
        pixelGlow = {
            enabled   = false,
            lines     = 8,
            speed     = 0.25,
            thickness = 2,
            length    = nil,
        },
        tankPower = false,
        fader = {
            steadyFlight = false,
        },
        cooldownManager = {
            enabled = false,
            hideSwipe = false,
            selectedViewer = 'essential',
            viewers = {
                essential = {
                    visibleSetting = 'ALWAYS', showTooltips = false, showKeybind = false,
                    keepSizeRatio = true, iconWidth = 30, iconHeight = 30, iconZoom = 0, spacing = 2, iconsPerRow = 12, growthDirection = 'DOWN',
                    cooldownText = { font = 'Expressway', fontSize = 16, fontOutline = 'OUTLINE', classColor = false, color = { r = 1, g = 1, b = 1 }, position = 'CENTER', xOffset = 0, yOffset = 0 },
                    countText    = { font = 'Expressway', fontSize = 11, fontOutline = 'OUTLINE', classColor = false, color = { r = 1, g = 1, b = 1 }, position = 'BOTTOMRIGHT', xOffset = 0, yOffset = 0 },
                    keybindText  = { font = 'Expressway', fontSize = 11, fontOutline = 'OUTLINE', classColor = false, color = { r = 1, g = 1, b = 1 }, position = 'TOPRIGHT', xOffset = 0, yOffset = 0 },
                    glow = { enabled = false, type = 'pixel', color = { r = 0.95, g = 0.95, b = 0.32, a = 1 }, lines = 8, speed = 0.25, thickness = 2, length = nil, particles = 4, scale = 1, startAnim = true },
                },
                utility = {
                    visibleSetting = 'ALWAYS', showTooltips = false, showKeybind = false,
                    keepSizeRatio = true, iconWidth = 30, iconHeight = 30, iconZoom = 0, spacing = 2, iconsPerRow = 12, growthDirection = 'DOWN',
                    cooldownText = { font = 'Expressway', fontSize = 16, fontOutline = 'OUTLINE', classColor = false, color = { r = 1, g = 1, b = 1 }, position = 'CENTER', xOffset = 0, yOffset = 0 },
                    countText    = { font = 'Expressway', fontSize = 11, fontOutline = 'OUTLINE', classColor = false, color = { r = 1, g = 1, b = 1 }, position = 'BOTTOMRIGHT', xOffset = 0, yOffset = 0 },
                    keybindText  = { font = 'Expressway', fontSize = 11, fontOutline = 'OUTLINE', classColor = false, color = { r = 1, g = 1, b = 1 }, position = 'TOPRIGHT', xOffset = 0, yOffset = 0 },
                    glow = { enabled = false, type = 'pixel', color = { r = 0.95, g = 0.95, b = 0.32, a = 1 }, lines = 8, speed = 0.25, thickness = 2, length = nil, particles = 4, scale = 1, startAnim = true },
                },
                buffIcon = {
                    visibleSetting = 'ALWAYS', hideWhenInactive = false, showTooltips = false,
                    keepSizeRatio = true, iconWidth = 30, iconHeight = 30, iconZoom = 0, spacing = 2, iconsPerRow = 12, growthDirection = 'DOWN',
                    cooldownText = { font = 'Expressway', fontSize = 16, fontOutline = 'OUTLINE', classColor = false, color = { r = 1, g = 1, b = 1 }, position = 'CENTER', xOffset = 0, yOffset = 0 },
                    countText    = { font = 'Expressway', fontSize = 11, fontOutline = 'OUTLINE', classColor = false, color = { r = 1, g = 1, b = 1 }, position = 'BOTTOMRIGHT', xOffset = 0, yOffset = 0 },
                    glow = { enabled = false, type = 'pixel', color = { r = 0.95, g = 0.95, b = 0.32, a = 1 }, lines = 8, speed = 0.25, thickness = 2, length = nil, particles = 4, scale = 1, startAnim = true },
                },
                buffBar = {
                    visibleSetting = 'ALWAYS', hideWhenInactive = true, showTooltips = false, barWidth = 200, barHeight = 20, spacing = 2, growthDirection = 'DOWN',
                    showIcon = true, showName = true, showTimer = true, showStacks = true, showSpark = false, iconGap = 2, mirroredColumns = false, columnGap = 4,
                    foregroundTexture = 'ElvUI Norm', backgroundTexture = 'ElvUI Norm',
                    nameText     = { font = 'Expressway', fontSize = 12, fontOutline = 'OUTLINE', classColor = false, color = { r = 1, g = 1, b = 1 }, position = 'LEFT', xOffset = 2, yOffset = 0 },
                    durationText = { font = 'Expressway', fontSize = 12, fontOutline = 'OUTLINE', classColor = false, color = { r = 1, g = 1, b = 1 }, position = 'RIGHT', xOffset = -2, yOffset = 0 },
                    stacksText   = { font = 'Expressway', fontSize = 11, fontOutline = 'OUTLINE', classColor = false, color = { r = 1, g = 1, b = 1 }, position = 'BOTTOMRIGHT', xOffset = 0, yOffset = 0 },
                },
                custom = {
                    enabled = false,
                    visibleSetting = 'ALWAYS',
                    showTooltips = true,
                    showRacials = true,
                    showHealthstone = true,
                    showPotions = true,
                    showCombatPotions = true,
                    trinketMode = 'both',
                    keepSizeRatio = true,
                    iconWidth = 36, iconHeight = 36,
                    iconZoom = 0,
                    spacing = 4,
                    iconsPerRow = 6,
                    growthDirection = 'CENTER',
                    cooldownText = { font = 'Expressway', fontSize = 14, fontOutline = 'OUTLINE', classColor = false, color = { r = 1, g = 1, b = 1 }, position = 'CENTER', xOffset = 0, yOffset = 0 },
                    countText    = { font = 'Expressway', fontSize = 11, fontOutline = 'OUTLINE', classColor = false, color = { r = 1, g = 1, b = 1 }, position = 'BOTTOMRIGHT', xOffset = 0, yOffset = 0 },
                },
            },
            spellGlow = {},
            spellBarColor = {},
        },
        damageMeter = {
            enabled       = false,
            barHeight     = 18,
            barSpacing    = 1,
            showClassIcon = false,
            showTimer     = false,
            modeIndex     = 1,
            autoResetOnComplete = false,
            embedded         = true,
            standaloneWidth  = 220,
            standaloneHeight = 180,
            windowEnabled    = { true, false, false, false },
            extraWindows     = {},
            showBackdrop        = true,
            backdropColor       = { r = 0.06, g = 0.06, b = 0.06, a = 0.80 },
            showHeaderBackdrop  = true,
            showHeaderBorder    = true,
            headerMouseover     = false,
            headerFont        = 'Expressway',
            headerFontSize    = 11,
            headerFontOutline = 'OUTLINE',
            headerBGColor   = { r = 0.06, g = 0.06, b = 0.06, a = 0.85 },
            headerFontColor = { r = 1.00, g = 1.00, b = 1.00 },
            barTexture    = '',
            barClassColor = true,
            barColor      = { r = 0.60, g = 0.60, b = 0.60 },
            barBGTexture  = '',
            barBGClassColor = true,
            barBGColor    = { r = 0.20, g = 0.20, b = 0.20, a = 0.35 },
            barFont        = 'Expressway',
            barFontSize    = 11,
            barFontOutline = 'OUTLINE',
            hideInPetBattle    = false,
            hideInFlight       = false,
            barBorderEnabled   = false,
            textClassColor = false,
            textColor      = { r = 1.00, g = 1.00, b = 1.00 },
            valueClassColor = false,
            valueColor      = { r = 1.00, g = 1.00, b = 1.00 },
            clickInCombat  = false,
            showRank       = true,
            rankClassColor = false,
            rankColor      = { r = 0.60, g = 0.60, b = 0.60 },
        },
        minimapButtonBar = {
            enabled        = false,
            orientation    = 'HORIZONTAL',
            growthDirection = 'RIGHTDOWN',
            buttonSize     = 28,
            buttonSpacing  = 2,
            buttonsPerRow  = 12,
            buttonBackdrop      = true,
            buttonBackdropColor = { r = 0.00, g = 0.00, b = 0.00, a = 0.50 },
            buttonBorder        = true,
            buttonBorderColor   = { r = 0.00, g = 0.00, b = 0.00, a = 1.00 },
            buttonBorderSize    = 1,
            backdrop       = true,
            backdropColor  = { r = 0.06, g = 0.06, b = 0.06, a = 0.85 },
            border         = true,
            borderColor    = { r = 0.00, g = 0.00, b = 0.00, a = 1.00 },
            borderSize     = 1,
            mouseover      = false,
            mouseoverAlpha = 1.0,
            hideInCombat   = false,
        },
    },
}

local P = E.DF and E.DF.profile
if P then
    P.TrenchyUI = E:CopyTable({}, TUI.defaults.profile)
end

function TUI:BuildConfig()
    local tuiVersion = C_AddOns.GetAddOnMetadata("ElvUI_TrenchyUI", "Version") or "?"
    local tuiName = E:TextGradient('TrenchyUI', 1.00,0.18,0.24, 0.80,0.10,0.20)
    E.Options.name = format("%s + |TInterface\\AddOns\\ElvUI_TrenchyUI\\media\\TrenchyUI_Tiny:16:16|t %s |cff99ff33%s|r", E.Options.name, tuiName, tuiVersion)

    E.Options.args.TrenchyUI = ACH:Group(tuiName, nil, 6, "tab")
    local root = E.Options.args.TrenchyUI.args

    self:BuildQoLConfig(root, tuiName)
    self:BuildDamageMeterConfig(root, tuiName)
    self:BuildCooldownManagerConfig(root, tuiName)
    self:BuildUnitFramesConfig(root, tuiName)
    self:BuildNameplatesConfig(root, tuiName)
    self:BuildSkinsConfig(root, tuiName)
    self:BuildProfilesConfig(root, tuiName)
    self:BuildInformationConfig(root, tuiName)
end
