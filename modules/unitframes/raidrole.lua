local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local UFC = E:GetModule('TUI_UnitFrames')

function UFC:Initialize()
	if TUI.db.profile.tankPower and self.InitTankPower then self:InitTankPower() end
	if not TUI:IsCompatBlocked('auraHighlight') and self.InitPixelGlow then self:InitPixelGlow() end
	if self.InitEvokerEssenceCharge then self:InitEvokerEssenceCharge() end
	if self.InitSteadyFlight then self:InitSteadyFlight() end
	if self.InitPrivateAuraPreview then self:InitPrivateAuraPreview() end
	self:InitAbsorbTextures()
end

E:RegisterModule(UFC:GetName())
