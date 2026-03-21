local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')

local PROFILE_NAME = 'TrenchyUI'

function TUI:ApplyPlatynatorProfile()
	if not PLATYNATOR_CONFIG then return end

	PLATYNATOR_CONFIG.Profiles = PLATYNATOR_CONFIG.Profiles or {}

	local p = {}

	-- General settings
	p.stack_region_scale_y = 3.5
	p.obscured_alpha = 0.35
	p.not_target_behaviour = 'fade'
	p.simplified_nameplates = { minor = false, minion = false, instancesNormal = false }
	p.stacking_nameplates = { friend = false, enemy = true }
	p.show_friendly_in_instances = true
	p.blizzard_widget_scale = 2
	p.show_friendly_in_instances_1 = 'name_only'
	p.stack_applies_to = { normal = true, minion = false, minor = false }
	p.not_target_alpha = 1
	p.target_scale = 1.14
	p.click_region_scale_x = 1.3
	p.cast_alpha = 1
	p.stack_region_scale_x = 2
	p.click_region_scale = 1
	p.mouseover_alpha = 1
	p.closer_to_screen_edges = true
	p.cast_scale = 1
	p.closer_nameplates = false
	p.global_scale = 1.2
	p.target_behaviour = 'none'
	p.click_region_scale_y = 1.5
	p.show_nameplates_only_needed = false
	p.apply_cvars = true
	p.simplified_scale = 0.8

	-- Design assignments
	p.designs_assigned = {
		enemySimplifiedCombat = '_hare_simplified',
		enemyPvPPlayer = '_deer',
		enemyCombat = '_deer',
		friendCombat = '_name-only',
		friendPvPPlayer = '_name-only',
		enemySimplified = '_custom',
		friend = 'Name Only',
		enemy = 'ElvUI',
	}

	-- Design mode toggles
	p.designs_enabled = { pvpInstance = false, combat = false, pvpWorld = false }

	-- Clickable nameplates
	p.clickable_nameplates = { friend = false, enemy = true }

	-- Nameplate visibility
	p.show_nameplates = {
		friendlyMinion = false,
		enemyMinor = true,
		friendlyPlayer = true,
		friendlyNPC = false,
		enemyMinion = true,
		enemy = true,
	}

	p.designs = {
		["_custom"] = {
			version = 1,
			scale = 1,
			font = { outline = true, shadow = true, asset = "FritzQuadrata", slug = true },
			bars = {
				{
					kind = "health",
					animate = false,
					scale = 0.9,
					layer = 1,
					relativeTo = 0,
					anchor = {},
					foreground = { asset = "Platy: Fade Left" },
					background = { color = { a = 0.5650312304496765, r = 1, g = 1, b = 1 }, applyColor = false, asset = "Platy: Solid Grey" },
					absorb = { color = { a = 1, r = 1, g = 1, b = 1 }, asset = "Platy: Absorb Wide" },
					border = { color = { a = 1, r = 0.2588235437870026, g = 0.2588235437870026, b = 0.2588235437870026 }, height = 1.09, asset = "Platy: Blizzard Health", width = 1.12 },
					marker = { asset = "wide/glow" },
					autoColors = {
						{ combatOnly = true, kind = "threat", useSafeColor = false, instancesOnly = false, colors = { safe = { b = 0.2431372702121735, g = 0.9019608497619628, r = 0.3686274588108063 }, transition = { b = 0, g = 0.6274509803921569, r = 1 }, offtank = { b = 0.7843137254901961, g = 0.6666666666666666, r = 0.05882352941176471 }, warning = { b = 0, g = 0, r = 0.8 } } },
						{ kind = "eliteType", instancesOnly = true, colors = { boss = { b = 0.6392157077789307, g = 0, r = 1 }, melee = { r = 0.9882352941176472, g = 0.9882352941176472, b = 0.9882352941176472 }, caster = { r = 0, g = 0.4549019607843137, b = 0.7372549019607844 }, trivial = { r = 0.6980392156862745, g = 0.5568627450980392, b = 0.3333333333333333 }, miniboss = { r = 0.5647058823529412, g = 0, b = 0.7372549019607844 } } },
						{ kind = "classColors", colors = {} },
						{ kind = "tapped", colors = { tapped = { r = 0.4313725490196079, g = 0.4313725490196079, b = 0.4313725490196079 } } },
						{ kind = "reaction", colors = { unfriendly = { b = 0, g = 0.5058823529411765, r = 1 }, hostile = { b = 0, g = 0, r = 1 }, friendly = { b = 0, g = 1, r = 0 }, neutral = { b = 0, g = 1, r = 1 } } },
					},
				},
				{
					kind = "cast",
					scale = 1,
					layer = 1,
					anchor = { "TOP", 0, -8 },
					foreground = { asset = "Platy: Blizzard Cast Bar" },
					background = { color = { a = 1, r = 0.1764705926179886, g = 0.1764705926179886, b = 0.1764705926179886 }, applyColor = false, asset = "Platy: Solid White" },
					border = { color = { a = 0.5, b = 0.3215686274509804, g = 0.984313725490196, r = 1 }, height = 0.8, asset = "Platy: Blizzard Cast Bar", width = 1 },
					marker = { asset = "wide/glow" },
					interruptMarker = { color = { b = 1, g = 1, r = 1 }, asset = "none" },
					autoColors = {
						{ kind = "uninterruptableCast", colors = { uninterruptable = { b = 0.5294117647058824, g = 0.5294117647058824, r = 0.5294117647058824 } } },
						{ kind = "cast", colors = { cast = { b = 0, g = 0.7411764705882353, r = 1 }, interrupted = { b = 0.8784313725490196, g = 0.211764705882353, r = 0.9882352941176472 }, channel = { b = 0.2156862745098039, g = 0.7764705882352941, r = 0.2431372549019608 } } },
					},
				},
			},
			highlights = {
				{
					kind = "target",
					scale = 0.9,
					layer = 2,
					asset = "Platy: Blizzard Health Bold",
					width = 1.12,
					anchor = {},
					height = 1.21,
					color = { a = 1, r = 1, g = 1, b = 1 },
					sliced = true,
				},
				{
					kind = "mouseover",
					includeTarget = true,
					scale = 0.9,
					layer = 4,
					asset = "Platy: Blizzard Health Bold",
					width = 1.12,
					anchor = {},
					height = 1.21,
					color = { a = 0.5364580154418945, r = 0.6666666865348816, g = 0.6666666865348816, b = 0.6666666865348816 },
					sliced = true,
				},
				{
					kind = "automatic",
					scale = 1,
					layer = 2,
					asset = "Platy: Blizzard Cast Bar",
					width = 1,
					anchor = { "TOP", 0, -8 },
					height = 0.79,
					color = { a = 1, b = 1, g = 1, r = 1 },
					sliced = true,
					autoColors = {
						{ kind = "importantCast", colors = { cast = { a = 1, b = 0.1529411764705883, g = 0.09411764705882352, r = 1 }, channel = { a = 1, b = 0.1529411822557449, g = 0.0941176563501358, r = 1 } } },
						{ kind = "uninterruptableCast", colors = { uninterruptable = { a = 1, b = 0.7647058823529411, g = 0.7529411764705882, r = 0.5137254901960784 } } },
					},
				},
			},
			specialBars = {},
			auras = {
				{
					kind = "debuffs",
					direction = "LEFT",
					scale = 0.75,
					showCountdown = true,
					sorting = { kind = "duration", reversed = false },
					showPandemic = true,
					showDispel = {},
					anchor = { "BOTTOMRIGHT", 62, 9 },
					height = 1,
					textScale = 1,
					filters = { fromYou = true, important = true },
				},
				{
					kind = "buffs",
					direction = "RIGHT",
					scale = 0.75,
					showCountdown = true,
					sorting = { kind = "duration", reversed = false },
					height = 1,
					showDispel = { enrage = true },
					anchor = { "BOTTOMLEFT", -63, 9 },
					textScale = 1,
					filters = { dispelable = false, important = true, defensive = false },
				},
				{
					kind = "crowdControl",
					direction = "RIGHT",
					scale = 1.2,
					showCountdown = true,
					sorting = { kind = "duration", reversed = false },
					height = 1,
					showDispel = {},
					anchor = { "BOTTOM", 0, 9 },
					textScale = 1,
					filters = { fromYou = false },
				},
			},
			markers = {
				{ kind = "quest", asset = "normal/quest-blizzard", color = { b = 1, g = 1, r = 1 }, scale = 0.9, anchor = { "LEFT", -70, 0 }, layer = 3 },
				{ kind = "cannotInterrupt", asset = "normal/blizzard-shield", color = { b = 1, g = 1, r = 1 }, scale = 0.5, anchor = { "TOPLEFT", -63.5, -9.5 }, layer = 3 },
				{ kind = "raid", asset = "normal/blizzard-raid", color = { b = 1, g = 1, r = 1 }, scale = 1, anchor = {}, layer = 3 },
			},
			texts = {
				{ kind = "health", truncate = false, color = { b = 1, g = 1, r = 1 }, layer = 2, maxWidth = 0, significantFigures = 0, align = "CENTER", anchor = { "RIGHT", 60.5, 0 }, scale = 0.8, displayTypes = { "percentage" } },
				{ kind = "creatureName", showWhenWowDoes = false, truncate = true, align = "LEFT", layer = 2, maxWidth = 0.75, autoColors = {}, anchor = { "LEFT", -59, 0 }, color = { r = 1, g = 1, b = 1 }, scale = 0.8 },
				{ kind = "castSpellName", align = "LEFT", anchor = { "TOPLEFT", -55, -10.5 }, layer = 2, truncate = true, color = { b = 1, g = 1, r = 1 }, scale = 0.7, maxWidth = 0.44 },
				{ kind = "castTarget", truncate = true, color = { b = 1, g = 1, r = 1 }, layer = 2, maxWidth = 0.46, align = "RIGHT", anchor = { "TOPRIGHT", 61, -10.5 }, scale = 0.7, applyClassColors = true },
			},
		},
		["Name Only"] = {
			scale = 1.4,
			font = { outline = true, shadow = true, asset = "Expressway", slug = true },
			bars = {},
			highlights = {},
			specialBars = {},
			auras = {},
			markers = {},
			texts = {
				{ kind = "creatureName", showWhenWowDoes = false, truncate = true, align = "CENTER", layer = 0, maxWidth = 0.99, autoColors = { { kind = "classColors", colors = {} } }, anchor = {}, scale = 1.3, color = { b = 0.9686275124549866, g = 0.9686275124549866, r = 0.9686275124549866 } },
				{ kind = "guild", showWhenWowDoes = false, playerGuild = true, align = "CENTER", layer = 0, maxWidth = 0.99, npcRole = true, truncate = false, anchor = { "TOP", 0, -6 }, scale = 0.9, color = { r = 1, g = 1, b = 1 } },
			},
		},
		["ElvUI"] = {
			version = 1,
			scale = 1.5,
			font = { outline = true, shadow = true, asset = "Expressway", slug = true },
			bars = {
				{
					kind = "health",
					animate = false,
					scale = 1,
					layer = 1,
					relativeTo = 0,
					anchor = {},
					foreground = { asset = "ElvUI Blank" },
					background = { color = { a = 0.800000011920929, b = 0.1411764770746231, g = 0.1411764770746231, r = 0.1411764770746231 }, applyColor = false, asset = "ElvUI Blank" },
					absorb = { color = { a = 0.7812488675117493, r = 0.6705882549285889, g = 0.8431373238563538, b = 1 }, asset = "ElvUI Norm1" },
					border = { color = { a = 1, r = 0, g = 0, b = 0 }, height = 1, asset = "Platy: 1px", width = 1.15 },
					marker = { asset = "none" },
					autoColors = {
						{ combatOnly = true, kind = "threat", useSafeColor = false, instancesOnly = false, colors = { safe = { b = 0.2431372702121735, g = 0.9019608497619628, r = 0.3686274588108063 }, transition = { b = 0, g = 0.6274509803921569, r = 1 }, offtank = { b = 0.7843137254901961, g = 0.6666666666666666, r = 0.05882352941176471 }, warning = { b = 0, g = 0, r = 0.8 } } },
						{ kind = "quest", colors = { neutral = { b = 0, g = 0.5372549295425415, r = 1 }, friendly = { b = 0, g = 0.5372549295425415, r = 1 }, hostile = { b = 0, g = 0.5372549295425415, r = 1 } } },
						{ kind = "delveType", delves = true, outsideInstances = false, colors = { elite = { b = 0.7372549019607844, g = 0, r = 0.5647058823529412 }, boss = { b = 0, g = 0.1098039215686275, r = 0.7372549019607844 }, melee = { b = 0.9882352941176471, g = 0.9882352941176471, r = 0.9882352941176471 }, caster = { b = 0.7372549019607844, g = 0.4549019607843137, r = 0 }, trivial = { b = 0.3333333333333333, g = 0.5568627450980392, r = 0.6980392156862745 }, rare = { b = 0.5372549019607843, g = 0.3254901960784314, r = 0.7372549019607844 } } },
						{ kind = "eliteType", instancesOnly = true, colors = { boss = { b = 0.6392157077789307, g = 0, r = 1 }, melee = { b = 0.4862745404243469, g = 0.7647059559822083, r = 0.988235354423523 }, caster = { r = 0, g = 0.4549019607843137, b = 0.7372549019607844 }, trivial = { r = 0.6980392156862745, g = 0.5568627450980392, b = 0.3333333333333333 }, miniboss = { r = 0.5647058823529412, g = 0, b = 0.7372549019607844 } } },
						{ kind = "reaction", colors = { unfriendly = { b = 0, g = 0.5058823529411765, r = 1 }, hostile = { b = 0, g = 0, r = 1 }, friendly = { b = 0, g = 1, r = 0 }, neutral = { b = 0, g = 1, r = 1 } } },
					},
				},
				{
					kind = "cast",
					scale = 1,
					layer = 0,
					anchor = { "TOP", 0, -8.5 },
					foreground = { asset = "ElvUI Blank" },
					background = { color = { a = 1, r = 0.1764705926179886, g = 0.1764705926179886, b = 0.1764705926179886 }, applyColor = false, asset = "ElvUI Blank" },
					border = { color = { a = 0.5, r = 0, g = 0, b = 0 }, height = 0.8, asset = "Platy: 1px", width = 1.15},
					marker = { asset = "wide/glow" },
					interruptMarker = { color = { a = 1, r = 0.1803921610116959, g = 1, b = 0.03921568766236305 }, asset = "wide/glow" },
					autoColors = {
						{ kind = "interruptReady", colors = { ready = { b = 0, g = 1, r = 0 } } },
						{ kind = "interruptNotReady", colors = { notReady = { a = 1, r = 1, g = 0.5686274766921997, b = 0.19607844948768617 } } },
						{ kind = "uninterruptableCast", colors = { uninterruptable = { b = 0.5294117647058824, g = 0.5294117647058824, r = 0.5294117647058824 } } },
						{ kind = "cast", colors = { cast = { b = 0, g = 0.7411764705882353, r = 1 }, interrupted = { b = 0.8784313725490196, g = 0.211764705882353, r = 0.9882352941176472 }, channel = { b = 0.2156862745098039, g = 0.7764705882352941, r = 0.2431372549019608 } } },
					},
				},
			},
			highlights = {
				{
					kind = "mouseover",
					includeTarget = true,
					scale = 1,
					layer = 4,
					asset = "Platy: 4px",
					width = 1.15,
					anchor = {},
					height = 1,
					color = { a = 1, r = 1, g = 0.1843137294054031, b = 0.2392157018184662 },
					sliced = true,
				},
				{
					kind = "automatic",
					scale = 1,
					layer = 1,
					asset = "Platy: 2px",
					width = 1.15,
					anchor = { "TOP", 0, -8.5 },
					height = 0.79,
					color = { a = 1, b = 1, g = 1, r = 1 },
					sliced = true,
					autoColors = {
						{ kind = "importantCast", colors = { cast = { a = 1, b = 0.1529411764705883, g = 0.09411764705882352, r = 1 }, channel = { a = 1, b = 0.1529411822557449, g = 0.0941176563501358, r = 1 } } },
						{ kind = "uninterruptableCast", colors = { uninterruptable = { a = 1, b = 0.7647058823529411, g = 0.7529411764705882, r = 0.5137254901960784 } } },
					},
				},
				{
					kind = "target",
					scale = 1,
					layer = 4,
					asset = "Platy: Arrow Solid",
					width = 1.3,
					anchor = {},
					height = 1.3,
					color = { a = 1, r = 1, g = 0.1843137294054031, b = 0.2392157018184662 },
					sliced = true,
				},
				{
					kind = "focus",
					scale = 0.99,
					layer = 1,
					asset = "Platy: Striped Reverse",
					width = 1.15,
					anchor = {},
					height = 0.9,
					color = { a = 1, r = 0.4470588564872742, g = 0.4549019932746887, b = 0.4470588564872742 },
					sliced = false,
				},
			},
			specialBars = {},
			auras = {
				{
					kind = "debuffs",
					direction = "LEFT",
					scale = 0.98,
					showCountdown = true,
					sorting = { kind = "duration", reversed = false },
					showPandemic = true,
					showDispel = {},
					height = 1,
					anchor = { "BOTTOMRIGHT", 72, 9 },
					textScale = 0.75,
					filters = { fromYou = true, important = true },
				},
				{
					kind = "buffs",
					direction = "RIGHT",
					scale = 0.98,
					showCountdown = true,
					sorting = { kind = "duration", reversed = false },
					height = 1,
					showDispel = { enrage = true },
					anchor = { "BOTTOMLEFT", -72.5, 9 },
					textScale = 0.75,
					filters = { dispelable = false, important = true, defensive = false },
				},
				{
					kind = "crowdControl",
					direction = "RIGHT",
					scale = 1.5,
					showCountdown = true,
					sorting = { kind = "duration", reversed = false },
					height = 0.75,
					showDispel = {},
					anchor = { "BOTTOMLEFT", -16, 10 },
					textScale = 0.75,
					filters = { fromYou = false },
				},
			},
			markers = {
				{ kind = "quest", asset = "normal/quest-blizzard", scale = 0.9, anchor = { "LEFT", -81, 0 }, color = { b = 1, g = 1, r = 1 }, layer = 5 },
				{ kind = "cannotInterrupt", asset = "normal/shield-gradient", scale = 0.7, anchor = { "TOPLEFT", -77.5, -8.5 }, color = { b = 1, g = 1, r = 1 }, layer = 2 },
				{ kind = "raid", asset = "normal/blizzard-raid", scale = 1, anchor = {}, color = { b = 1, g = 1, r = 1 }, layer = 3 },
			},
			texts = {
				{ kind = "health", truncate = true, color = { b = 1, g = 1, r = 1 }, layer = 2, maxWidth = 0, significantFigures = 0, align = "CENTER", anchor = { "RIGHT", 69.5, 0 }, scale = 1, displayTypes = { "percentage" } },
				{ kind = "creatureName", showWhenWowDoes = false, truncate = true, align = "LEFT", layer = 2, maxWidth = 0.75, autoColors = {}, anchor = { "LEFT", -69, 0 }, color = { r = 1, g = 1, b = 1 }, scale = 1 },
				{ kind = "castSpellName", scale = 0.75, color = { b = 1, g = 1, r = 1 }, layer = 2, truncate = true, anchor = { "TOPLEFT", -69.5, -11 }, align = "LEFT", maxWidth = 0.44 },
				{ kind = "castTimeLeft", scale = 0.8, align = "CENTER", layer = 2, truncate = false, color = { b = 1, g = 1, r = 1 }, anchor = { "TOPRIGHT", 70.5, -11 }, maxWidth = 0 },
				{ kind = "castInterrupter", scale = 0.8, color = { b = 1, g = 1, r = 1 }, layer = 2, truncate = false, anchor = { "TOPRIGHT", 36.5, -10.5 }, align = "CENTER", maxWidth = 0, applyClassColors = true },
			},
		},
	}

	PLATYNATOR_CONFIG.Profiles[PROFILE_NAME] = p
	PLATYNATOR_CURRENT_PROFILE = PROFILE_NAME
end
