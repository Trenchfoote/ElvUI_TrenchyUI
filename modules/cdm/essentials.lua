-- CDM Essential Cooldowns viewer
local E = unpack(ElvUI)
local CDM = E:GetModule('TUI_CDM')

function CDM.LayoutEssential(isCapture)
	local vdb = CDM.GetViewerDB('essential')
	local useGlow = vdb and vdb.glow and vdb.glow.enabled

	CDM.LayoutIconViewer('essential', isCapture, function(icon)
		if useGlow then
			CDM.ApplyGlow(icon, vdb.glow)
		else
			CDM.StopGlow(icon)
		end
		CDM.ApplyKeybindText(icon, vdb)
	end)
end
