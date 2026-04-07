local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
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

function TUI:InitRaidRoleFilter()
	local db = self.db.profile.raidRole
	if not db or (not db.hideMainTank and not db.hideMainAssist) then return end

	hooksecurefunc(UF, 'Configure_RaidRoleIcons', function(_, frame)
		HookRaidRole(frame)
	end)
end
