local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local LSM = E.Libs.LSM

local UF = E:GetModule('UnitFrames')
local NP = E:GetModule('NamePlates')
local AB = E:GetModule('ActionBars')
local CH = E:GetModule('Chat')
local DT = E:GetModule('DataTexts')
local DB = E:GetModule('DataBars')
local A = E:GetModule('Auras')
local B = E:GetModule('Bags')

local BORDER_NAME = 'LS Thin #1 (Blizz Compat)'
local EDGE_SIZE = 22
local OFFSET = 5
local BORDER_R, BORDER_G, BORDER_B = 0.6, 0.6, 0.6

local NUM_ACTIONBAR_BUTTONS = NUM_ACTIONBAR_BUTTONS or 12
local NUM_PET_ACTION_SLOTS = NUM_PET_ACTION_SLOTS or 10
local NUM_STANCE_SLOTS = NUM_STANCE_SLOTS or 10

local borderTex
local borderBackdrop = { edgeSize = EDGE_SIZE }
local borderRegistry = {}

-- Core ----------------------------------------------------------------

local function CreateBorder(frame, frameLevel, anchor1, anchor2)
	if not frame then return end
	if frame:GetObjectType() == 'Texture' then frame = frame:GetParent() end
	if not frame then return end
	if frame.tuiBorder then return frame.tuiBorder end

	local parent = frame
	local border = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
	border:SetFrameLevel(parent:GetFrameLevel() + (frameLevel or 2))
	borderBackdrop.edgeFile = borderTex
	border:SetBackdrop(borderBackdrop)
	E:ReplaceSetupTextureCoordinates(border)
	border:SetBackdropBorderColor(BORDER_R, BORDER_G, BORDER_B, 1)
	border:SetPoint('TOPLEFT', anchor1 or parent, 'TOPLEFT', -OFFSET, OFFSET)
	border:SetPoint('BOTTOMRIGHT', anchor2 or anchor1 or parent, 'BOTTOMRIGHT', OFFSET, -OFFSET)

	frame.tuiBorder = border
	borderRegistry[#borderRegistry + 1] = border
	return border
end

local function HideElvUIBorder(frame)
	if not frame then return end
	if frame.SetBackdropBorderColor then
		frame:SetBackdropBorderColor(0, 0, 0, 0)
	end
	if frame.iborder then frame.iborder:Hide() end
	if frame.oborder then frame.oborder:Hide() end
end

-- Unit Frames ---------------------------------------------------------

local function BorderUnitFrame(frame)
	if not frame then return end

	local main = frame.backdrop or frame
	CreateBorder(main, 15)
	HideElvUIBorder(main)

	if frame.Health and frame.Health.backdrop then
		HideElvUIBorder(frame.Health.backdrop)
	end

	if frame.Power and frame.Power.backdrop then
		HideElvUIBorder(frame.Power.backdrop)
	end
end

local function OnCreateAndUpdateUF(_, unit)
	BorderUnitFrame(UF[unit])
end

local function OnCreateAndUpdateUFGroup(_, group, numGroup)
	for i = 1, numGroup do
		BorderUnitFrame(_G['ElvUF_' .. E:StringTitle(group) .. i])
	end
end

local function OnCreateAndUpdateHeaderGroup(_, group)
	local name = E:StringTitle(group)
	if name == 'Tank' then
		for i = 1, 2 do BorderUnitFrame(_G['ElvUF_TankUnitButton' .. i]) end
	elseif name == 'Assist' then
		for i = 1, 2 do BorderUnitFrame(_G['ElvUF_AssistUnitButton' .. i]) end
	end
end

-- UF Castbars ---------------------------------------------------------

local function OnConfigureCastbar(_, frame)
	if not frame then return end
	local castbar = frame.Castbar
	if not castbar then return end

	local cb = castbar.backdrop or castbar
	CreateBorder(cb)
	HideElvUIBorder(cb)

	if castbar.ButtonIcon and castbar.ButtonIcon.bg then
		CreateBorder(castbar.ButtonIcon.bg)
		HideElvUIBorder(castbar.ButtonIcon.bg)
	end
end

-- UF Aura Icons -------------------------------------------------------

local function OnPostUpdateAura(_, _, button)
	if not button or button.tuiBorder then return end
	CreateBorder(button)
	HideElvUIBorder(button)
end

-- Nameplates ----------------------------------------------------------

local function OnStylePlate(_, nameplate)
	local health = nameplate.Health
	if health and not health.tuiBorder then
		CreateBorder(health, 3)
		HideElvUIBorder(health.backdrop)
	end

	local castbar = nameplate.Castbar
	if castbar then
		if not castbar.tuiBorder then
			CreateBorder(castbar, 3)
			HideElvUIBorder(castbar.backdrop)
		end
		if castbar.Icon and not castbar.Icon.tuiBorder then
			CreateBorder(castbar.Icon)
			HideElvUIBorder(castbar.Icon.backdrop)
		end
	end

	local power = nameplate.Power
	if power and not power.tuiBorder then
		CreateBorder(power, 3)
		HideElvUIBorder(power.backdrop)
	end
end

local function OnConstructNPAuraIcon(_, button)
	if not button or button.tuiBorder then return end
	CreateBorder(button, 2)
	HideElvUIBorder(button)
end

-- Action Bars ---------------------------------------------------------

local function SkinABButton(button)
	if not button then return end
	CreateBorder(button, 3)
end

local function SkinABBar(bar, barType)
	if not bar then return end

	if bar.backdrop then
		CreateBorder(bar.backdrop)
	end

	if barType == 'PLAYER' then
		for i = 1, NUM_ACTIONBAR_BUTTONS do
			SkinABButton(bar.buttons and bar.buttons[i])
		end
	elseif barType == 'PET' then
		for i = 1, NUM_PET_ACTION_SLOTS do
			SkinABButton(_G['PetActionButton' .. i])
		end
	elseif barType == 'STANCE' then
		for i = 1, NUM_STANCE_SLOTS do
			SkinABButton(_G['ElvUI_StanceBarButton' .. i])
		end
	end
end

local function OnPositionAndSizeBar(_, barName)
	local bar = AB.handledBars and AB.handledBars[barName]
	SkinABBar(bar, 'PLAYER')
end

local function OnPositionAndSizeBarPet()
	SkinABBar(_G.ElvUI_BarPet, 'PET')
end

local function OnPositionAndSizeBarShapeShift()
	SkinABBar(_G.ElvUI_StanceBar, 'STANCE')
end

-- Buff/Debuff Auras (header) -----------------------------------------

local function OnCreateAuraIcon(_, button)
	if not button or button.tuiBorder then return end
	CreateBorder(button)
	HideElvUIBorder(button)
end

-- Chat ----------------------------------------------------------------

local function OnPositionChats()
	for _, name in ipairs(CH.panels) do
		local panel = _G[name]
		if panel then
			CreateBorder(panel)
			HideElvUIBorder(panel)
		end
	end
end

-- Minimap -------------------------------------------------------------

local function BorderMinimap()
	local mm = _G.Minimap
	if mm and mm.backdrop then
		CreateBorder(mm.backdrop)
		HideElvUIBorder(mm.backdrop)
	end
end

-- Tooltip -------------------------------------------------------------

local function BorderTooltip()
	local tt = _G.GameTooltip
	if tt then
		CreateBorder(tt)
		HideElvUIBorder(tt)
	end
	local ttBar = _G.GameTooltipStatusBar
	if ttBar and ttBar.backdrop then
		CreateBorder(ttBar.backdrop)
		HideElvUIBorder(ttBar.backdrop)
	end
end

-- DataTexts -----------------------------------------------------------

local function OnRegisterPanel(_, panel)
	if not panel then return end
	CreateBorder(panel)
	HideElvUIBorder(panel)
end

local function BorderDataTexts()
	if not DT.RegisteredPanels then return end
	for _, panel in pairs(DT.RegisteredPanels) do
		CreateBorder(panel)
		HideElvUIBorder(panel)
	end
end

-- DataBars ------------------------------------------------------------

local function BorderDataBars()
	if not DB.StatusBars then return end
	for _, bar in pairs(DB.StatusBars) do
		if bar.holder then
			CreateBorder(bar.holder)
			HideElvUIBorder(bar.holder)
		end
	end
end

-- Bags ----------------------------------------------------------------

local function OnConstructContainerButton(_, _, slot)
	if not slot or slot.tuiBorder then return end
	CreateBorder(slot)
	HideElvUIBorder(slot)
end

local function BorderBagFrames()
	local bagFrame = B.BagFrame
	if bagFrame then
		CreateBorder(bagFrame)
		HideElvUIBorder(bagFrame)
	end
	local bankFrame = B.BankFrame
	if bankFrame then
		CreateBorder(bankFrame)
		HideElvUIBorder(bankFrame)
	end
end

-- Loot ----------------------------------------------------------------

local function BorderLoot()
	local lootFrame = _G.ElvLootFrame
	if lootFrame then
		CreateBorder(lootFrame)
		HideElvUIBorder(lootFrame)
	end
end

-- Totem Tracker -------------------------------------------------------

local function BorderTotemTracker()
	local TM = E:GetModule('TotemTracker', true)
	if not TM or not TM.bar then return end
	CreateBorder(TM.bar)
	HideElvUIBorder(TM.bar)
	for i = 1, 4 do
		local button = TM.bar[i]
		if button then
			CreateBorder(button)
			HideElvUIBorder(button)
		end
	end
end

-- AltPowerBar ---------------------------------------------------------

local function BorderAltPowerBar()
	local bar = _G.PlayerPowerBarAlt
	if bar then
		CreateBorder(bar)
	end
end

-- Init ----------------------------------------------------------------

function TUI:InitBorderMode()
	if not E:IsAddOnEnabled('ls_Borders') then return end

	borderTex = LSM:Fetch('border', BORDER_NAME)
	if not borderTex then return end

	-- Unit Frames
	if E.private.unitframe.enable then
		hooksecurefunc(UF, 'CreateAndUpdateUF', OnCreateAndUpdateUF)
		hooksecurefunc(UF, 'CreateAndUpdateUFGroup', OnCreateAndUpdateUFGroup)
		hooksecurefunc(UF, 'CreateAndUpdateHeaderGroup', OnCreateAndUpdateHeaderGroup)
		hooksecurefunc(UF, 'Configure_Castbar', OnConfigureCastbar)
		hooksecurefunc(UF, 'PostUpdateAura', OnPostUpdateAura)
	end

	-- Nameplates
	if E.private.nameplates.enable then
		hooksecurefunc(NP, 'StylePlate', OnStylePlate)
		if NP.Construct_AuraIcon then
			hooksecurefunc(NP, 'Construct_AuraIcon', OnConstructNPAuraIcon)
		end
	end

	-- Action Bars
	if E.private.actionbar.enable then
		hooksecurefunc(AB, 'PositionAndSizeBar', OnPositionAndSizeBar)
		hooksecurefunc(AB, 'PositionAndSizeBarPet', OnPositionAndSizeBarPet)
		hooksecurefunc(AB, 'PositionAndSizeBarShapeShift', OnPositionAndSizeBarShapeShift)

		for id = 1, 15 do
			local bar = _G['ElvUI_Bar' .. id]
			if bar then SkinABBar(bar, 'PLAYER') end
		end
		SkinABBar(_G.ElvUI_BarPet, 'PET')
		SkinABBar(_G.ElvUI_StanceBar, 'STANCE')
	end

	-- Buff/Debuff Auras
	if A and A.CreateIcon then
		hooksecurefunc(A, 'CreateIcon', OnCreateAuraIcon)
	end

	-- Chat
	if CH.panels then
		hooksecurefunc(CH, 'PositionChats', OnPositionChats)
		OnPositionChats()
	end

	-- Tooltip
	BorderTooltip()

	-- Minimap
	BorderMinimap()

	-- DataTexts
	hooksecurefunc(DT, 'RegisterPanel', OnRegisterPanel)
	BorderDataTexts()

	-- DataBars
	BorderDataBars()

	-- Bags
	if B.ConstructContainerButton then
		hooksecurefunc(B, 'ConstructContainerButton', OnConstructContainerButton)
	end
	BorderBagFrames()

	-- Loot
	BorderLoot()

	-- Totem Tracker
	BorderTotemTracker()

	-- AltPowerBar
	BorderAltPowerBar()
end
