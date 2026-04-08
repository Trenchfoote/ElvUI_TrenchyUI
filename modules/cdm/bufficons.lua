-- CDM Buff Icon Cooldowns viewer
local E = unpack(ElvUI)
local CDM = E:GetModule('TUI_CDM')

function CDM.LayoutBuffIcon(isCapture)
	CDM.LayoutIconViewer('buffIcon', isCapture, function(icon)
		local sid = icon.GetBaseSpellID and icon:GetBaseSpellID()
		local sgdb = sid and CDM.GetSpellGlowDB(sid)
		if sgdb and sgdb.enabled then
			CDM.ApplyGlow(icon, sgdb, true)
		else
			CDM.StopGlow(icon)
		end
	end)
end
