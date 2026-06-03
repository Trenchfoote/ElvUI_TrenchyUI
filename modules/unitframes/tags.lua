local E = unpack(ElvUI)
local UF = E:GetModule('UnitFrames')

local UnitPower, UnitPowerType, UnitPowerPercent, format = UnitPower, UnitPowerType, UnitPowerPercent, format
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local hooksecurefunc = hooksecurefunc
local CurveConstants = _G['CurveConstants']
local ScaleTo100 = CurveConstants and CurveConstants.ScaleTo100

local tuiCategory = E:TextGradient('TrenchyUI', 1.00,0.18,0.24, 0.80,0.10,0.20)

-- Single-letter role prefix: T for tanks, H for healers; nothing for DPS/no role.
-- Letter is class-of-role colored (tank orange, healer green); trailing space is baked
-- in so [tui-role][name] reads "T Trenchy" with no leading space for DPS. Place directly
-- before [name] with no literal space between them.
local ROLE_LETTER = { TANK = '|cffffa56eT|r ', HEALER = '|cff49ff45H|r ' }
E:AddTag('tui-role', 'GROUP_ROSTER_UPDATE PLAYER_ROLES_ASSIGNED', function(unit)
	return ROLE_LETTER[UnitGroupRolesAssigned(unit)]
end)
E:AddTagInfo('tui-role', tuiCategory, 'Role prefix for the name: "T " for tanks, "H " for healers (nothing for DPS). Use directly before [name], e.g. [tui-role][name].')

-- Smart Power tag: shows percentage for mana users, current value otherwise
E:AddTag('tui-smartpower', 'UNIT_DISPLAYPOWER UNIT_POWER_FREQUENT UNIT_MAXPOWER', function(unit)
	local powerType = UnitPowerType(unit)
	if powerType == Enum.PowerType.Mana then
		return format('%d', UnitPowerPercent(unit, nil, true, ScaleTo100))
	else
		return UnitPower(unit)
	end
end)
E:AddTagInfo('tui-smartpower', tuiCategory, 'Shows power percentage for mana specs, current power for others')

-- Stagger as % of max health; cached from oUF's non-tainted PostUpdateStagger call
local cachedStaggerPct
if UF and UF.PostUpdateStagger then
	hooksecurefunc(UF, 'PostUpdateStagger', function(element, cur)
		local max = element and element.max
		if cur and max and max > 0 then
			cachedStaggerPct = (cur / max) * 100
		else
			cachedStaggerPct = nil
		end
	end)
end

E:AddTag('tui-stagger', 0.1, function()
	if not cachedStaggerPct then return end
	return format('%d', cachedStaggerPct)
end)
E:AddTagInfo('tui-stagger', tuiCategory, 'Stagger amount as a percentage of max health (Brewmaster Monk)')

-- M+ forces % per mob (12.0.5+). Returns percentString so secret values pass through oUF's WrapString rather than dying in format().
local NP = E:GetModule('NamePlates', true)
local IsChallengeModeActive = C_PartyInfo and C_PartyInfo.IsChallengeModeActive
local GetUnitCriteriaProgressValues = C_ScenarioInfo and C_ScenarioInfo.GetUnitCriteriaProgressValues
local UnitIsPlayer, UnitCanAttack, UnitTreatAsPlayerForDisplay = UnitIsPlayer, UnitCanAttack, UnitTreatAsPlayerForDisplay

E:AddTag('tui-mplusforces', 'SCENARIO_CRITERIA_UPDATE SCENARIO_UPDATE UNIT_NAME_UPDATE', function(unit)
	-- Placement aid for ElvUI's NP test frame. _FRAME is injected by oUF into the tag's setfenv env.
	---@diagnostic disable-next-line: undefined-global
	if NP and _FRAME == NP.TestFrame then return '2.3' end
	if not (GetUnitCriteriaProgressValues and IsChallengeModeActive and IsChallengeModeActive()) then return end
	if not unit or UnitIsPlayer(unit) or not UnitCanAttack('player', unit) then return end
	if UnitTreatAsPlayerForDisplay and UnitTreatAsPlayerForDisplay(unit) then return end
	local actual, _, percentString = GetUnitCriteriaProgressValues(unit)
	if not actual then return end
	return percentString
end)
E:AddTagInfo('tui-mplusforces', tuiCategory, "Percent of M+ forces this enemy is worth (12.0.5+; only shows on attackable enemies during an active key)")
