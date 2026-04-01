local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local UF = E:GetModule('UnitFrames')
local LSM = E.Libs.LSM

local UnitClass = UnitClass
local UnitPowerType = UnitPowerType
local UnitStagger = UnitStagger
local UnitHealthMax = UnitHealthMax
local InCombatLockdown = InCombatLockdown
local CreateFrame = CreateFrame

local powerTypesFull = { MANA = true, FOCUS = true, ENERGY = true }

local function UpdateStaggerBar(bar, unit)
	local cur = UnitStagger(unit) or 0
	local max = UnitHealthMax(unit) or 1
	bar:SetMinMaxValues(0, max)
	bar:SetValue(cur)
end

local function GetOrCreateStaggerBar(parent)
	if parent.TUI_StaggerBar then return parent.TUI_StaggerBar end

	local power = parent.Power
	if not power then return nil end

	local texture = LSM:Fetch('statusbar', E.db.unitframe and E.db.unitframe.statusbar or 'ElvUI Norm')

	local bar = CreateFrame('StatusBar', nil, parent)
	bar:SetAllPoints(power)
	bar:SetFrameLevel(power:GetFrameLevel() + 5)
	bar:SetStatusBarTexture(texture)
	bar:GetStatusBarTexture():SetHorizTile(false)

	local c = E:ClassColor('MONK')
	bar:SetStatusBarColor(c.r, c.g, c.b)

	bar:CreateBackdrop(nil, nil, nil, nil, true)

	bar:Hide()
	parent.TUI_StaggerBar = bar
	return bar
end

-- Frames with active stagger bars
local activeBars = {}

-- Allocate power bar layout space without showing the power bar
local function AllocatePowerSpace(parent)
	if parent.POWERBAR_SHOWN then return end
	parent.POWERBAR_SHOWN = true
	UF:Configure_Power(parent, true)
	UF:Configure_InfoPanel(parent)
end

-- Release power bar layout space
local function ReleasePowerSpace(parent)
	if not parent.POWERBAR_SHOWN then return end
	if parent.Power and parent.Power:IsShown() then return end
	parent.POWERBAR_SHOWN = false
	UF:Configure_Power(parent, true)
	UF:Configure_InfoPanel(parent)
end

local function HideStaggerBar(parent)
	local bar = parent.TUI_StaggerBar
	if not bar or not bar:IsShown() then return end
	bar:Hide()
	activeBars[parent] = nil
	ReleasePowerSpace(parent)
end

function TUI:InitTankPower()
	if self._hookedTankPower then return end
	self._hookedTankPower = true

	local staggerFrame = CreateFrame('Frame')
	staggerFrame:RegisterEvent('UNIT_AURA')
	staggerFrame:RegisterEvent('UNIT_MAXHEALTH')
	staggerFrame:SetScript('OnEvent', function(_, _, unit)
		for parent in pairs(activeBars) do
			if parent.unit == unit then
				UpdateStaggerBar(parent.TUI_StaggerBar, unit)
			end
		end
	end)

	hooksecurefunc(UF, 'PostUpdatePower', function(power, unit)
		if not unit then return end

		local parent = power.origParent or power:GetParent()
		local db = parent.db and parent.db.power
		if not db or not db.onlyHealer then
			HideStaggerBar(parent)
			return
		end

		local role = (parent.db.roleIcon and parent.db.roleIcon.enable and parent.role) or UF:GetRoleIcon(parent)
		if role ~= 'TANK' then
			HideStaggerBar(parent)
			return
		end

		local _, classFile = UnitClass(unit)

		-- Blood DK: show the power bar (runic power)
		if classFile == 'DEATHKNIGHT' then
			HideStaggerBar(parent)

			if power:IsShown() then return end

			local cur, max, min = power.cur, power.max, power.min
			if not cur or not max then return end

			local _, powerType = UnitPowerType(unit)
			local fullType = powerTypesFull[powerType]
			local autoHide = (E:IsSecretValue(cur) or E:IsSecretValue(max)) or not db.autoHide or ((fullType and cur ~= max) or (not fullType and cur ~= min))
			local notInCombat = not db.notInCombat or InCombatLockdown()

			if autoHide and notInCombat then
				power:Show()
				UF:PowerBar_PostVisibility(power, parent)
			end
			return
		end

		-- Brewmaster Monk: show stagger bar, no power bar
		if classFile == 'MONK' then
			AllocatePowerSpace(parent)

			local bar = GetOrCreateStaggerBar(parent)
			if bar then
				bar:Show()
				activeBars[parent] = true
				UpdateStaggerBar(bar, unit)
			end
			return
		end

		-- Other tank: hide stagger bar
		HideStaggerBar(parent)
	end)
end
