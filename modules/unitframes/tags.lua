local E = unpack(ElvUI)
local UF = E:GetModule('UnitFrames')

local UnitPower, UnitPowerType, UnitPowerPercent, format = UnitPower, UnitPowerType, UnitPowerPercent, format
local hooksecurefunc = hooksecurefunc
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
E:AddTagInfo('tui-stagger', tuiGradient, 'Stagger amount as a percentage of max health (Brewmaster Monk)')
