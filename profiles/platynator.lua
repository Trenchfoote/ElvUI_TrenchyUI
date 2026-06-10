local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')

local PROFILE_NAME = 'TrenchyUI'

function TUI:ApplyPlatynatorProfile()
	if not PLATYNATOR_CONFIG then return end

	PLATYNATOR_CONFIG.Profiles = PLATYNATOR_CONFIG.Profiles or {}

	local p = {
		addon = "Platynator",
		apply_cvars = true,
		blizzard_widget_scale = 2,
		cast_alpha = 1,
		cast_interrupted_timeout = 1,
		cast_scale = 1,
		click_region_scale = 1,
		click_region_scale_x = 1,
		click_region_scale_y = 1,
		clickable_nameplates = {
			enemy = true,
			friend = false,
		},
		closer_nameplates = false,
		closer_to_screen_edges = true,
		current_skin = "blizzard",
		design_all = {},
		design_assignments = {
			{
				criteria = {
					"cannot-attack",
				},
				scale = 1,
				simplified = false,
				style = "Name Only",
			},
			{
				criteria = {
					"can-attack",
				},
				scale = 1,
				simplified = false,
				style = "ElvUI",
			},
		},
		designs = {
			ElvUI = {
				auras = {
					{
						anchor = {
							"BOTTOMRIGHT",
							72,
							9,
						},
						direction = "LEFT",
						filters = {
							fromYou = true,
							important = true,
						},
						height = 0.6,
						kind = "debuffs",
						layer = 4,
						limit = 30,
						padding = 0.1,
						scale = 0.98,
						showCountdown = true,
						showPandemic = true,
						showSwipe = false,
						showTooltips = false,
						showType = true,
						sorting = {
							kind = "duration",
							reversed = false,
						},
						textScale = 1,
						texts = {
							countdown = {
								anchor = {},
								color = {
									b = 1,
									g = 1,
									r = 1,
								},
								scale = 0.88,
								showFractions = false,
								visible = true,
							},
							stacks = {
								anchor = {
									"BOTTOMRIGHT",
									11,
									3,
								},
								color = {
									b = 0.0392156876623631,
									g = 0.486274540424347,
									r = 1,
								},
								scale = 0.69,
								visible = true,
							},
						},
					},
					{
						anchor = {
							"BOTTOMLEFT",
							-71.5,
							9,
						},
						direction = "RIGHT",
						filters = {
							defensive = false,
							dispelable = true,
							important = false,
						},
						height = 0.6,
						kind = "buffs",
						layer = 4,
						limit = 30,
						padding = 0.1,
						scale = 0.98,
						showCountdown = true,
						showStealable = false,
						showSwipe = false,
						showTooltips = false,
						showType = true,
						sorting = {
							kind = "duration",
							reversed = false,
						},
						textScale = 1,
						texts = {
							countdown = {
								anchor = {},
								color = {
									b = 1,
									g = 1,
									r = 1,
								},
								scale = 0.88,
								showFractions = false,
								visible = true,
							},
							stacks = {
								anchor = {
									"BOTTOMRIGHT",
									11.5,
									1.5,
								},
								color = {
									b = 0.0392156876623631,
									g = 0.486274540424347,
									r = 1,
								},
								scale = 0.69,
								visible = true,
							},
						},
					},
					{
						anchor = {
							"RIGHT",
							98.5,
							0,
						},
						direction = "RIGHT",
						filters = {
							fromYou = false,
						},
						height = 0.6,
						kind = "crowdControl",
						layer = 3,
						limit = 30,
						padding = 0.1,
						scale = 1.25,
						showCountdown = true,
						showSwipe = false,
						showTooltips = false,
						showType = true,
						sorting = {
							kind = "duration",
							reversed = false,
						},
						textScale = 1,
						texts = {
							countdown = {
								anchor = {},
								color = {
									b = 1,
									g = 1,
									r = 1,
								},
								scale = 0.88,
								showFractions = false,
								visible = true,
							},
							stacks = {
								anchor = {
									"BOTTOMRIGHT",
									12.5,
									2,
								},
								color = {
									b = 0.0392156876623631,
									g = 0.486274540424347,
									r = 1,
								},
								scale = 0.69,
								visible = true,
							},
						},
					},
				},
				bars = {
					{
						absorb = {
							asset = "ElvUI Norm1",
							color = {
								a = 0.781248867511749,
								b = 1,
								g = 0.843137323856354,
								r = 0.670588254928589,
							},
						},
						anchor = {},
						animate = false,
						autoColors = {
							{
								colors = {
									offtank = {
										b = 0.784313725490196,
										g = 0.666666666666667,
										r = 0.0588235294117647,
									},
									safe = {
										b = 0.243137270212173,
										g = 0.901960849761963,
										r = 0.368627458810806,
									},
									transition = {
										b = 0,
										g = 0.627450980392157,
										r = 1,
									},
									warning = {
										b = 0,
										g = 0,
										r = 0.8,
									},
								},
								combatOnly = true,
								instancesOnly = false,
								kind = "threat",
								tanksOnly = false,
								useOffTankColor = true,
								useSafeColor = false,
							},
							{
								colors = {
									friendly = {
										b = 0,
										g = 0.537254929542542,
										r = 1,
									},
									hostile = {
										b = 0,
										g = 0.537254929542542,
										r = 1,
									},
									neutral = {
										b = 0,
										g = 0.537254929542542,
										r = 1,
									},
								},
								kind = "quest",
							},
							{
								colors = {
									boss = {
										b = 0,
										g = 0.109803921568628,
										r = 0.737254901960784,
									},
									caster = {
										b = 0.737254901960784,
										g = 0.454901960784314,
										r = 0,
									},
									elite = {
										b = 0.737254901960784,
										g = 0,
										r = 0.564705882352941,
									},
									melee = {
										b = 0.988235294117647,
										g = 0.988235294117647,
										r = 0.988235294117647,
									},
									rare = {
										b = 0.537254901960784,
										g = 0.325490196078431,
										r = 0.737254901960784,
									},
									trivial = {
										b = 0.333333333333333,
										g = 0.556862745098039,
										r = 0.698039215686274,
									},
								},
								delves = true,
								enabled = {
									boss = true,
									caster = true,
									elite = true,
									melee = true,
									rare = true,
									trivial = true,
								},
								kind = "delveType",
								outsideInstances = false,
							},
							{
								applyCasterAlways = true,
								colors = {
									boss = {
										b = 0.639215707778931,
										g = 0,
										r = 1,
									},
									caster = {
										b = 0.737254901960784,
										g = 0.454901960784314,
										r = 0,
									},
									melee = {
										b = 0.486274540424347,
										g = 0.764705955982208,
										r = 0.988235354423523,
									},
									miniboss = {
										b = 0.737254901960784,
										g = 0,
										r = 0.564705882352941,
									},
									trivial = {
										b = 0.333333333333333,
										g = 0.556862745098039,
										r = 0.698039215686274,
									},
								},
								enabled = {
									boss = true,
									caster = true,
									melee = true,
									miniboss = true,
									trivial = true,
								},
								instancesOnly = true,
								kind = "eliteType",
							},
							{
								colors = {
									friendly = {
										b = 0,
										g = 1,
										r = 0,
									},
									hostile = {
										b = 0,
										g = 0,
										r = 1,
									},
									neutral = {
										b = 0,
										g = 1,
										r = 1,
									},
									unfriendly = {
										b = 0,
										g = 0.505882352941176,
										r = 1,
									},
								},
								kind = "reaction",
							},
						},
						background = {
							applyColor = false,
							asset = "ElvUI Blank",
							color = {
								a = 0.800000011920929,
								b = 0.141176477074623,
								g = 0.141176477074623,
								r = 0.141176477074623,
							},
						},
						border = {
							asset = "Platy: 1px",
							color = {
								a = 1,
								b = 0,
								g = 0,
								r = 0,
							},
							height = 1,
							width = 1.15,
						},
						foreground = {
							asset = "ElvUI Blank",
						},
						kind = "health",
						layer = 1,
						marker = {
							asset = "none",
						},
						relativeTo = 0,
						scale = 1,
					},
					{
						anchor = {
							"TOP",
							0,
							-8.5,
						},
						autoColors = {
							{
								colors = {
									ready = {
										b = 0,
										g = 1,
										r = 0,
									},
								},
								kind = "interruptReady",
							},
							{
								colors = {
									notReady = {
										b = 0.196078449487686,
										g = 0.5686274766922,
										r = 1,
									},
								},
								kind = "interruptNotReady",
							},
							{
								colors = {
									uninterruptable = {
										b = 0.529411764705882,
										g = 0.529411764705882,
										r = 0.529411764705882,
									},
								},
								kind = "uninterruptableCast",
							},
							{
								colors = {
									cast = {
										b = 0,
										g = 0.741176470588235,
										r = 1,
									},
									channel = {
										b = 0.215686274509804,
										g = 0.776470588235294,
										r = 0.243137254901961,
									},
									empowered = {
										b = 0.4,
										g = 0.776470588235294,
										r = 0.0196078431372549,
									},
									interrupted = {
										b = 0,
										g = 0,
										r = 0,
									},
								},
								kind = "cast",
							},
						},
						background = {
							applyColor = true,
							asset = "ElvUI Blank",
							color = {
								a = 1,
								b = 0.176470592617989,
								g = 0.176470592617989,
								r = 0.176470592617989,
							},
						},
						border = {
							asset = "Platy: 1px",
							color = {
								a = 0.5,
								b = 0,
								g = 0,
								r = 0,
							},
							height = 0.8,
							width = 1.15,
						},
						foreground = {
							asset = "ElvUI Blank",
						},
						interruptMarker = {
							asset = "wide/glow",
							color = {
								a = 1,
								b = 0.0392156876623631,
								g = 1,
								r = 0.180392161011696,
							},
						},
						kind = "cast",
						layer = 0,
						marker = {
							asset = "wide/glow",
						},
						scale = 1,
					},
				},
				font = {
					asset = "Expressway",
					outline = true,
					shadow = false,
					slug = true,
				},
				highlights = {
					{
						anchor = {
							"TOP",
							0,
							-8.5,
						},
						asset = "Platy: 2px",
						autoColors = {
							{
								colors = {
									cast = {
										a = 1,
										b = 0.152941176470588,
										g = 0.0941176470588235,
										r = 1,
									},
									channel = {
										a = 1,
										b = 0.152941182255745,
										g = 0.0941176563501358,
										r = 1,
									},
								},
								kind = "importantCast",
							},
							{
								colors = {
									uninterruptable = {
										a = 1,
										b = 0.764705882352941,
										g = 0.752941176470588,
										r = 0.513725490196078,
									},
								},
								kind = "uninterruptableCast",
							},
						},
						color = {
							a = 1,
							b = 1,
							g = 1,
							r = 1,
						},
						height = 0.79,
						kind = "automatic",
						layer = 1,
						scale = 1,
						sliced = true,
						width = 1.15,
					},
					{
						anchor = {},
						asset = "Platy: Striped Reverse",
						color = {
							a = 1,
							b = 0.447058856487274,
							g = 0.454901993274689,
							r = 0.447058856487274,
						},
						height = 0.9,
						kind = "focus",
						layer = 1,
						scale = 0.99,
						sliced = false,
						width = 1.15,
					},
					{
						anchor = {
							"RIGHT",
							73,
							0,
						},
						asset = "Platy: 7px",
						autoColors = {
							{
								colors = {
									notMouseover = {
										a = 0,
										b = 0.921568691730499,
										g = 0.372549027204514,
										r = 0.694117665290833,
									},
								},
								includeTarget = true,
								kind = "notMouseover",
							},
							{
								colors = {},
								kind = "myClassColor",
							},
						},
						color = {
							a = 1,
							b = 1,
							g = 1,
							r = 1,
						},
						height = 1,
						kind = "automatic",
						layer = 3,
						scale = 1,
						sliced = true,
						width = 1.16,
					},
					{
						anchor = {
							"BOTTOM",
							0,
							-11.5,
						},
						asset = "Platy: Arrow Solid",
						autoColors = {
							{
								colors = {
									notTarget = {
										a = 0,
										b = 0.882353007793427,
										g = 1,
										r = 0.21960785984993,
									},
								},
								kind = "notTarget",
							},
							{
								colors = {},
								kind = "myClassColor",
							},
						},
						color = {
							a = 1,
							b = 1,
							g = 1,
							r = 1,
						},
						height = 1.54,
						kind = "automatic",
						layer = 3,
						scale = 1,
						sliced = true,
						width = 1.32,
					},
				},
				markers = {
					{
						anchor = {
							"LEFT",
							-90.5,
							0,
						},
						asset = "normal/quest-blizzard",
						color = {
							b = 1,
							g = 1,
							r = 1,
						},
						kind = "quest",
						layer = 4,
						scale = 0.9,
					},
					{
						anchor = {
							"TOPLEFT",
							-77.5,
							-8.5,
						},
						asset = "normal/shield-gradient",
						color = {
							b = 1,
							g = 1,
							r = 1,
						},
						kind = "cannotInterrupt",
						layer = 2,
						scale = 0.7,
					},
					{
						anchor = {
							"BOTTOMLEFT",
							-14,
							-2.5,
						},
						asset = "normal/blizzard-raid",
						color = {
							b = 1,
							g = 1,
							r = 1,
						},
						kind = "raid",
						layer = 4,
						scale = 1,
					},
				},
				regions = {
					click = {
						anchor = {
							"TOP",
							0,
							7.81,
						},
						autoSized = true,
						height = 1.84,
						kind = "click",
						width = 1.15,
					},
					stack = {
						anchor = {
							"TOP",
							0,
							10.69,
						},
						autoSized = true,
						height = 2.21,
						kind = "stack",
						width = 1.26,
					},
				},
				scale = 1.5,
				specialBars = {},
				texts = {
					{
						align = "CENTER",
						anchor = {
							"RIGHT",
							69.5,
							0,
						},
						color = {
							b = 1,
							g = 1,
							r = 1,
						},
						displayTypes = {
							"percentage",
						},
						formatMultiple = "%s (%s)",
						kind = "health",
						layer = 2,
						maxWidth = 0,
						scale = 1,
						showPercentSymbol = false,
						significantFigures = 0,
						truncate = true,
					},
					{
						align = "LEFT",
						anchor = {
							"LEFT",
							-69,
							0,
						},
						autoColors = {},
						color = {
							b = 1,
							g = 1,
							r = 1,
						},
						kind = "creatureName",
						layer = 2,
						maxWidth = 0.75,
						scale = 1,
						showWhenWowDoes = false,
						truncate = true,
					},
					{
						align = "LEFT",
						anchor = {
							"TOPLEFT",
							-69.5,
							-11,
						},
						color = {
							b = 1,
							g = 1,
							r = 1,
						},
						kind = "castSpellName",
						layer = 2,
						maxWidth = 0.45,
						scale = 0.75,
						truncate = true,
					},
					{
						align = "CENTER",
						anchor = {
							"TOPRIGHT",
							70.5,
							-11,
						},
						color = {
							b = 1,
							g = 1,
							r = 1,
						},
						kind = "castTimeLeft",
						layer = 2,
						maxWidth = 0,
						scale = 0.8,
						truncate = true,
					},
					{
						align = "LEFT",
						anchor = {
							"TOPLEFT",
							-69.5,
							-22,
						},
						applyClassColors = true,
						color = {
							b = 1,
							g = 1,
							r = 1,
						},
						kind = "castInterrupter",
						layer = 2,
						maxWidth = 0,
						scale = 0.75,
						truncate = false,
					},
					{
						align = "LEFT",
						anchor = {
							"TOPLEFT",
							-69.5,
							-22,
						},
						applyClassColors = true,
						color = {
							b = 1,
							g = 1,
							r = 1,
						},
						kind = "castTarget",
						layer = 2,
						maxWidth = 0,
						scale = 0.75,
						truncate = false,
					},
				},
				version = 11,
			},
			["Name Only"] = {
				auras = {},
				bars = {},
				font = {
					asset = "Expressway",
					outline = true,
					shadow = true,
					slug = true,
				},
				highlights = {},
				markers = {},
				regions = {
					click = {
						anchor = {},
						autoSized = true,
						height = 0.92,
						kind = "click",
						width = 0.99,
					},
					stack = {
						anchor = {},
						autoSized = true,
						height = 1.1,
						kind = "stack",
						width = 1.09,
					},
				},
				scale = 1.4,
				specialBars = {},
				texts = {
					{
						align = "CENTER",
						anchor = {},
						autoColors = {
							{
								colors = {},
								kind = "classColors",
							},
						},
						color = {
							b = 0.968627512454987,
							g = 0.968627512454987,
							r = 0.968627512454987,
						},
						kind = "creatureName",
						layer = 0,
						maxWidth = 0.99,
						scale = 1.3,
						showWhenWowDoes = false,
						truncate = true,
					},
					{
						align = "CENTER",
						anchor = {
							"TOP",
							0,
							-6,
						},
						color = {
							b = 1,
							g = 1,
							r = 1,
						},
						kind = "guild",
						layer = 0,
						maxWidth = 0.99,
						npcRole = true,
						playerGuild = true,
						scale = 0.9,
						showWhenWowDoes = false,
						truncate = false,
					},
				},
				version = 11,
			},
			_custom = {
				auras = {
					{
						anchor = {
							"BOTTOMLEFT",
							-63,
							25,
						},
						direction = "RIGHT",
						filters = {
							fromYou = true,
							important = true,
						},
						height = 1,
						kind = "debuffs",
						layer = 1,
						limit = 30,
						padding = 0.1,
						scale = 1,
						showCountdown = true,
						showPandemic = true,
						showSwipe = true,
						showTooltips = true,
						showType = false,
						sorting = {
							kind = "duration",
							reversed = false,
						},
						textScale = 1,
						texts = {
							countdown = {
								anchor = {},
								color = {
									b = 1,
									g = 1,
									r = 1,
								},
								scale = 1.17,
								showFractions = false,
								visible = true,
							},
							stacks = {
								anchor = {
									"TOPRIGHT",
									12,
									-1,
								},
								color = {
									b = 1,
									g = 1,
									r = 1,
								},
								scale = 0.92,
								visible = true,
							},
						},
					},
					{
						anchor = {
							"LEFT",
							-98,
							0,
						},
						direction = "LEFT",
						filters = {
							defensive = false,
							dispelable = false,
							important = true,
						},
						height = 1,
						kind = "buffs",
						layer = 1,
						limit = 30,
						padding = 0.1,
						scale = 1,
						showCountdown = true,
						showStealable = false,
						showSwipe = true,
						showTooltips = true,
						showType = true,
						sorting = {
							kind = "duration",
							reversed = false,
						},
						textScale = 1,
						texts = {
							countdown = {
								anchor = {},
								color = {
									b = 1,
									g = 1,
									r = 1,
								},
								scale = 1.17,
								showFractions = false,
								visible = true,
							},
							stacks = {
								anchor = {
									"TOPRIGHT",
									12,
									-1,
								},
								color = {
									b = 1,
									g = 1,
									r = 1,
								},
								scale = 0.92,
								visible = true,
							},
						},
					},
					{
						anchor = {
							"RIGHT",
							101,
							0,
						},
						direction = "RIGHT",
						filters = {
							fromYou = false,
						},
						height = 1,
						kind = "crowdControl",
						layer = 1,
						limit = 30,
						padding = 0.1,
						scale = 1,
						showCountdown = true,
						showSwipe = true,
						showTooltips = true,
						showType = false,
						sorting = {
							kind = "duration",
							reversed = false,
						},
						textScale = 1,
						texts = {
							countdown = {
								anchor = {},
								color = {
									b = 1,
									g = 1,
									r = 1,
								},
								scale = 1.17,
								showFractions = false,
								visible = true,
							},
							stacks = {
								anchor = {
									"TOPRIGHT",
									12,
									-1,
								},
								color = {
									b = 1,
									g = 1,
									r = 1,
								},
								scale = 0.92,
								visible = true,
							},
						},
					},
				},
				bars = {
					{
						absorb = {
							asset = "Platy: Absorb Wide",
							color = {
								a = 1,
								b = 1,
								g = 1,
								r = 1,
							},
						},
						anchor = {},
						animate = true,
						autoColors = {
							{
								colors = {
									tapped = {
										b = 0.431372549019608,
										g = 0.431372549019608,
										r = 0.431372549019608,
									},
								},
								kind = "tapped",
							},
							{
								colors = {
									offtank = {
										b = 0.784313725490196,
										g = 0.666666666666667,
										r = 0.0588235294117647,
									},
									safe = {
										b = 0.901960784313726,
										g = 0.588235294117647,
										r = 0.0588235294117647,
									},
									transition = {
										b = 0,
										g = 0.627450980392157,
										r = 1,
									},
									warning = {
										b = 0,
										g = 0,
										r = 0.8,
									},
								},
								combatOnly = true,
								instancesOnly = false,
								kind = "threat",
								tanksOnly = false,
								useOffTankColor = true,
								useSafeColor = false,
							},
							{
								colors = {
									friendly = {
										b = 0,
										g = 1,
										r = 0.87843137254902,
									},
									hostile = {
										b = 0.372549027204514,
										g = 0.48235297203064,
										r = 1,
									},
									neutral = {
										b = 0.290196078431373,
										g = 0.925490196078431,
										r = 1,
									},
								},
								kind = "quest",
							},
							{
								applyCasterAlways = false,
								colors = {
									boss = {
										b = 0.976470649242401,
										g = 1,
										r = 0,
									},
									caster = {
										b = 0.737254901960784,
										g = 0.454901960784314,
										r = 0,
									},
									melee = {
										b = 0.988235294117647,
										g = 0.988235294117647,
										r = 0.988235294117647,
									},
									miniboss = {
										b = 0.615686297416687,
										g = 0,
										r = 0.474509835243225,
									},
									trivial = {
										b = 0.333333333333333,
										g = 0.556862745098039,
										r = 0.698039215686274,
									},
								},
								enabled = {
									boss = true,
									caster = true,
									melee = true,
									miniboss = true,
									trivial = true,
								},
								instancesOnly = true,
								kind = "eliteType",
							},
							{
								colors = {},
								kind = "classColors",
							},
							{
								colors = {
									friendly = {
										b = 0,
										g = 1,
										r = 0,
									},
									hostile = {
										b = 0,
										g = 0,
										r = 1,
									},
									neutral = {
										b = 0,
										g = 1,
										r = 1,
									},
									unfriendly = {
										b = 0,
										g = 0.505882352941176,
										r = 1,
									},
								},
								kind = "reaction",
							},
						},
						background = {
							applyColor = true,
							asset = "Platy: Solid Grey",
							color = {
								a = 1,
								b = 1,
								g = 1,
								r = 1,
							},
						},
						border = {
							asset = "Platy: 4px",
							color = {
								a = 1,
								b = 0.227450996637344,
								g = 0.243137270212173,
								r = 0.16078431904316,
							},
							height = 1,
							width = 1,
						},
						foreground = {
							asset = "Platy: Fade Bottom",
						},
						kind = "health",
						layer = 1,
						marker = {
							asset = "wide/glow",
						},
						relativeTo = 0,
						scale = 1,
					},
					{
						anchor = {
							"TOP",
							0,
							-9,
						},
						autoColors = {
							{
								colors = {
									notReady = {
										b = 0,
										g = 0,
										r = 1,
									},
									ready = {
										b = 0,
										g = 1,
										r = 0,
									},
								},
								kind = "interruptReady",
							},
							{
								colors = {
									uninterruptable = {
										b = 0.764705882352941,
										g = 0.752941176470588,
										r = 0.513725490196078,
									},
								},
								kind = "uninterruptableCast",
							},
							{
								colors = {
									cast = {
										b = 0,
										g = 0.549019607843137,
										r = 0.988235294117647,
									},
									channel = {
										b = 0.360784322023392,
										g = 0.77647066116333,
										r = 0.5686274766922,
									},
									empowered = {
										b = 0.4,
										g = 0.776470588235294,
										r = 0.0196078431372549,
									},
									interrupted = {
										b = 0.87843137254902,
										g = 0.211764705882353,
										r = 0.988235294117647,
									},
								},
								kind = "cast",
							},
						},
						background = {
							applyColor = true,
							asset = "Platy: Solid Grey",
							color = {
								a = 1,
								b = 1,
								g = 1,
								r = 1,
							},
						},
						border = {
							asset = "Platy: 4px",
							color = {
								a = 1,
								b = 0.227450996637344,
								g = 0.243137270212173,
								r = 0.16078431904316,
							},
							height = 1,
							width = 1,
						},
						foreground = {
							asset = "Platy: Fade Bottom",
						},
						interruptMarker = {
							asset = "none",
							color = {
								b = 1,
								g = 1,
								r = 1,
							},
						},
						kind = "cast",
						layer = 2,
						marker = {
							asset = "wide/glow",
						},
						scale = 1,
					},
				},
				font = {
					asset = "Roboto Condensed Bold",
					outline = true,
					shadow = true,
					slug = true,
				},
				highlights = {
					{
						anchor = {},
						asset = "Platy: Arrow",
						color = {
							a = 1,
							b = 1,
							g = 1,
							r = 1,
						},
						height = 1.22,
						kind = "target",
						layer = 0,
						scale = 1,
						sliced = true,
						width = 1.23,
					},
					{
						anchor = {},
						asset = "Platy: 7px",
						color = {
							a = 1,
							b = 0.921568691730499,
							g = 0.372549027204514,
							r = 0.694117665290833,
						},
						height = 1.2,
						includeTarget = true,
						kind = "mouseover",
						layer = 0,
						scale = 1,
						sliced = true,
						width = 1.03,
					},
					{
						anchor = {
							"TOP",
							0,
							-8.5,
						},
						asset = "Platy: 7px",
						autoColors = {
							{
								colors = {
									cast = {
										a = 1,
										b = 0.152941176470588,
										g = 0.0941176470588235,
										r = 1,
									},
									channel = {
										a = 1,
										b = 1,
										g = 0.262745098039216,
										r = 0.0392156862745098,
									},
								},
								kind = "importantCast",
							},
						},
						color = {
							a = 1,
							b = 1,
							g = 1,
							r = 1,
						},
						height = 1.05,
						kind = "automatic",
						layer = 3,
						scale = 1,
						sliced = true,
						width = 1.01,
					},
				},
				markers = {
					{
						anchor = {
							"TOPLEFT",
							-60,
							-11.5,
						},
						asset = "normal/shield-soft",
						color = {
							b = 0.498039215686275,
							g = 0.482352941176471,
							r = 0.392156862745098,
						},
						kind = "cannotInterrupt",
						layer = 3,
						scale = 0.5,
					},
					{
						anchor = {
							"LEFT",
							-61,
							0,
						},
						asset = "special/blizzard-elite-midnight",
						color = {
							b = 1,
							g = 1,
							r = 1,
						},
						kind = "elite",
						layer = 3,
						openWorldOnly = true,
						scale = 0.8,
					},
					{
						anchor = {
							"BOTTOM",
							0,
							20,
						},
						asset = "normal/blizzard-raid",
						color = {
							b = 1,
							g = 1,
							r = 1,
						},
						kind = "raid",
						layer = 3,
						scale = 1,
					},
					{
						anchor = {
							"TOPLEFT",
							-78,
							-10,
						},
						asset = "normal/cast-icon",
						color = {
							b = 1,
							g = 1,
							r = 1,
						},
						kind = "castIcon",
						layer = 3,
						scale = 1,
						square = false,
					},
					{
						anchor = {
							"BOTTOMRIGHT",
							70.5,
							0,
						},
						asset = "normal/blizzard-rare-midnight",
						color = {
							b = 1,
							g = 1,
							r = 1,
						},
						includeElites = false,
						kind = "rare",
						layer = 3,
						scale = 0.84,
					},
				},
				regions = {
					click = {
						anchor = {
							"TOP",
							0,
							20.1,
						},
						autoSized = true,
						height = 2.86,
						width = 1,
					},
					stack = {
						anchor = {
							"TOP",
							0,
							24.57,
						},
						autoSized = true,
						height = 3.43,
						width = 1.1,
					},
				},
				scale = 1,
				specialBars = {},
				texts = {
					{
						align = "CENTER",
						anchor = {
							"BOTTOM",
							0,
							8,
						},
						autoColors = {},
						color = {
							b = 1,
							g = 1,
							r = 1,
						},
						kind = "creatureName",
						layer = 2,
						maxWidth = 0.99,
						scale = 1.1,
						showWhenWowDoes = false,
						truncate = false,
					},
					{
						align = "CENTER",
						anchor = {},
						color = {
							b = 1,
							g = 1,
							r = 1,
						},
						displayTypes = {
							"absolute",
						},
						formatMultiple = "%s (%s)",
						kind = "health",
						layer = 2,
						maxWidth = 0,
						scale = 1.15,
						showPercentSymbol = true,
						significantFigures = 0,
						truncate = false,
					},
					{
						align = "LEFT",
						anchor = {
							"TOPLEFT",
							-49,
							-12,
						},
						color = {
							b = 1,
							g = 1,
							r = 1,
						},
						colors = {
							npc = {
								friendly = {
									b = 0,
									g = 1,
									r = 0,
								},
								hostile = {
									b = 0,
									g = 0,
									r = 1,
								},
								neutral = {
									b = 0,
									g = 1,
									r = 1,
								},
								tapped = {
									b = 0.431372549019608,
									g = 0.431372549019608,
									r = 0.431372549019608,
								},
							},
						},
						kind = "castSpellName",
						layer = 2,
						maxWidth = 0.5,
						scale = 0.93,
						truncate = true,
					},
					{
						align = "RIGHT",
						anchor = {
							"TOPRIGHT",
							60,
							-13,
						},
						applyClassColors = true,
						color = {
							b = 1,
							g = 1,
							r = 1,
						},
						kind = "castInterrupter",
						layer = 2,
						maxWidth = 0.36,
						scale = 0.89,
						truncate = true,
					},
					{
						align = "RIGHT",
						anchor = {
							"TOPRIGHT",
							60,
							-13,
						},
						applyClassColors = true,
						color = {
							b = 1,
							g = 1,
							r = 1,
						},
						kind = "castTarget",
						layer = 2,
						maxWidth = 0.36,
						scale = 0.89,
						truncate = true,
					},
				},
				version = 11,
			},
		},
		designs_assigned = {
			enemy = "ElvUI",
			enemyCombat = "_deer",
			enemyPvPPlayer = "_deer",
			enemySimplified = "_custom",
			enemySimplifiedCombat = "_hare_simplified",
			friend = "Name Only",
			friendCombat = "_name-only",
			friendPvPPlayer = "_name-only",
		},
		designs_enabled = {
			combat = false,
			pvpInstance = false,
			pvpWorld = false,
		},
		global_scale = 1.2,
		kind = "profile",
		migration = 6,
		mouseover_alpha = 1,
		nameplate_position = "top",
		not_in_combat_alpha = 1,
		not_target_alpha = 1,
		not_target_behaviour = "fade",
		obscured_alpha = 0.35,
		obscured_combat_alpha = 0.45,
		out_of_range_alpha = 1,
		show_friendly_in_instances = true,
		show_friendly_in_instances_1 = "name_only",
		show_nameplates = {
			enemy = true,
			enemyMinion = true,
			enemyMinionGuardian = true,
			enemyMinionPet = true,
			enemyMinionTotem = true,
			enemyMinor = true,
			friendlyMinion = false,
			friendlyMinionGuardian = true,
			friendlyMinionPet = true,
			friendlyMinionTotem = true,
			friendlyNPC = false,
			friendlyPlayer = true,
		},
		show_nameplates_only_needed = false,
		simplified_assigned_fallback = "_custom",
		simplified_nameplates = {
			instancesNormal = false,
			minion = false,
			minor = false,
		},
		simplified_scale = 0.8,
		stack_applies_to = {
			minion = false,
			minor = false,
			normal = true,
		},
		stack_region_scale_x = 1.1,
		stack_region_scale_y = 1.2,
		stacking_nameplates = {
			enemy = true,
			friend = false,
		},
		style = "ElvUI",
		target_behaviour = "none",
		target_scale = 1.15,
		version = 1,
		vertical_offset = 0,
	}

	PLATYNATOR_CONFIG.Profiles[PROFILE_NAME] = p
	PLATYNATOR_CURRENT_PROFILE = PROFILE_NAME
end
