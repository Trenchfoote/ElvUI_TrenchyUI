local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local UFC = E:GetModule('TUI_UnitFrames')
local UF = E:GetModule('UnitFrames')

local function HookIndicatorPostUpdate(frame)
	if not frame or not frame.RaidRoleIndicator then return end
	if frame.RaidRoleIndicator._tuiRoleHooked then return end
	frame.RaidRoleIndicator._tuiRoleHooked = true

	local origPostUpdate = frame.RaidRoleIndicator.PostUpdate
	frame.RaidRoleIndicator.PostUpdate = function(self, role)
		if origPostUpdate then origPostUpdate(self, role) end

		if not role then return end
		local db = TUI.db.profile.raidRole
		if not db then return end

		if db.hideMainTank and role == 'MAINTANK' then
			self:Hide()
		elseif db.hideMainAssist and role == 'MAINASSIST' then
			self:Hide()
		end
	end
end

function UFC:InitRaidRoleFilter()
	local db = TUI.db.profile.raidRole
	if not db or (not db.hideMainTank and not db.hideMainAssist) then return end

	hooksecurefunc(UF, 'Configure_RaidRoleIcons', function(_, frame)
		HookIndicatorPostUpdate(frame)
	end)
end

function UFC:Initialize()
	if TUI.db.profile.tankPower and self.InitTankPower then self:InitTankPower() end
	if not TUI:IsCompatBlocked('auraHighlight') and self.InitPixelGlow then self:InitPixelGlow() end
	if self.InitEvokerEssenceCharge then self:InitEvokerEssenceCharge() end
	if self.InitSteadyFlight then self:InitSteadyFlight() end
	if self.InitRaidRoleFilter then self:InitRaidRoleFilter() end
	self:InitAbsorbTextures()
	self:InitPrivateAuraPreview()
end

E:RegisterModule(UFC:GetName())
