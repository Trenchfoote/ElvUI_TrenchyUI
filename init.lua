local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')

function TUI:InitModules()
	-- Force value color to current class
	local cc = E:ClassColor(E.myclass)
	if cc and E.db.general.valuecolor then
		E.db.general.valuecolor.r = cc.r
		E.db.general.valuecolor.g = cc.g
		E.db.general.valuecolor.b = cc.b
	end

	-- Borders
	if self.db.profile.borderMode and self.InitBorderMode then self:InitBorderMode() end

	-- Skins, QoL, Nameplates, Unit Frames, Cooldown Manager, Damage Meter
	-- all registered via E:RegisterModule and initialize automatically
end
