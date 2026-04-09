local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local UFC = E:GetModule('TUI_UnitFrames')
local UF = E:GetModule('UnitFrames')

-- Absorb texture override
function UFC:InitAbsorbTextures()
	local db = TUI.db.profile.absorbTexture
	if not db then return end

	local LSM = E.Libs.LSM
	local hasDamage = db.damageAbsorb and db.damageAbsorb ~= ''
	local hasHeal = db.healAbsorb and db.healAbsorb ~= ''
	if not hasDamage and not hasHeal then return end

	hooksecurefunc(UF, 'Configure_HealComm', function(_, frame)
		local pred = frame and frame.HealthPrediction
		if not pred then return end

		if hasDamage then
			local tex = LSM:Fetch('statusbar', db.damageAbsorb)
			pred.damageAbsorb:SetStatusBarTexture(tex)
		end
		if hasHeal then
			local tex = LSM:Fetch('statusbar', db.healAbsorb)
			pred.healAbsorb:SetStatusBarTexture(tex)
		end
	end)
end
