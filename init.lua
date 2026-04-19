local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')

function TUI:InitModules()
	-- Borders
	if self.db.profile.borderMode and self.InitBorderMode then self:InitBorderMode() end

	-- Skins, QoL, Nameplates, Unit Frames, Cooldown Manager, Damage Meter
	-- all registered via E:RegisterModule and initialize automatically
end
