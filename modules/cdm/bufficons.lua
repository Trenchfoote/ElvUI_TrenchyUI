-- CDM Buff Icon Cooldowns viewer
local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local S = TUI._cdm

function S.LayoutBuffIcon(isCapture)
	S.LayoutIconViewer('buffIcon', isCapture, function(icon)
		local sid = icon.GetBaseSpellID and icon:GetBaseSpellID()
		local sgdb = sid and S.GetSpellGlowDB(sid)
		if sgdb and sgdb.enabled then
			S.ApplyGlow(icon, sgdb, true)
		else
			S.StopGlow(icon)
		end
	end)
end
