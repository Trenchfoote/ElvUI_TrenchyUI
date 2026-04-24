local E = unpack(ElvUI)

local UnitPower, UnitPowerType, UnitPowerPercent, format = UnitPower, UnitPowerType, UnitPowerPercent, format
local UnitStagger, UnitHealthMax = UnitStagger, UnitHealthMax
local CurveConstants = _G['CurveConstants']
local ScaleTo100 = CurveConstants and CurveConstants.ScaleTo100

local tuiGradient = E:TextGradient('TrenchyUI', 1.00,0.18,0.24, 0.80,0.10,0.20)

-- Smart Power tag: shows percentage for mana users, current value otherwise
E:AddTag('tui-smartpower', 'UNIT_DISPLAYPOWER UNIT_POWER_FREQUENT UNIT_MAXPOWER', function(unit)
	local powerType = UnitPowerType(unit)
	if powerType == Enum.PowerType.Mana then
		return format('%d', UnitPowerPercent(unit, nil, true, ScaleTo100))
	else
		return UnitPower(unit)
	end
end)
E:AddTagInfo('tui-smartpower', tuiGradient, 'Shows power percentage for mana specs, current power for others')

-- Stagger percentage tag: current staggered damage as % of max health (no % sign)
E:AddTag('tui-staggerpct', 0.1, function(unit)
	local cur = UnitStagger(unit)
	if not cur then return end
	local max = UnitHealthMax(unit)
	if not max or max <= 0 then return end
	return format('%d', (cur / max) * 100)
end)
E:AddTagInfo('tui-staggerpct', tuiGradient, 'Stagger amount as a percentage of max health (Brewmaster Monk)')
