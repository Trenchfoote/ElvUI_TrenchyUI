local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local UFC = E:GetModule('TUI_UnitFrames')
local UF = E:GetModule('UnitFrames')

local function HookRaidRole(frame)
	if not frame or not frame.RaidRoleIndicator then return end
	if frame.RaidRoleIndicator._tuiHooked then return end
	frame.RaidRoleIndicator._tuiHooked = true

	local indicator = frame.RaidRoleIndicator
	hooksecurefunc(indicator, 'Show', function(self)
		local db = TUI.db.profile.raidRole
		if not db then return end

		local tex = self:GetTexture()
		if not tex then return end
		local texLower = tostring(tex):lower()
		if db.hideMainTank and texLower:find('maintankicon') then
			self:Hide()
		elseif db.hideMainAssist and texLower:find('mainassisticon') then
			self:Hide()
		end
	end)
end

function UFC:InitRaidRoleFilter()
	local db = TUI.db.profile.raidRole
	if not db or (not db.hideMainTank and not db.hideMainAssist) then return end

	hooksecurefunc(UF, 'Configure_RaidRoleIcons', function(_, frame)
		HookRaidRole(frame)
	end)
end

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

function UFC:Initialize()
	if TUI.db.profile.tankPower and self.InitTankPower then self:InitTankPower() end
	if not TUI:IsCompatBlocked('auraHighlight') and self.InitPixelGlow then self:InitPixelGlow() end
	if self.InitEvokerEssenceCharge then self:InitEvokerEssenceCharge() end
	if self.InitSteadyFlight then self:InitSteadyFlight() end
	if self.InitRaidRoleFilter then self:InitRaidRoleFilter() end
	self:InitAbsorbTextures()
end

E:RegisterModule(UFC:GetName())
