-- CDM Utility Cooldowns viewer
local E = unpack(ElvUI)
local CDM = E:GetModule('TUI_CDM')

function CDM.LayoutUtility(isCapture)
	local vdb = CDM.GetViewerDB('utility')
	local useGlow = vdb and vdb.glow and vdb.glow.enabled

	CDM.LayoutIconViewer('utility', isCapture, function(icon)
		if useGlow then
			CDM.ApplyGlow(icon, vdb.glow)
		else
			CDM.StopGlow(icon)
		end
		CDM.ApplyKeybindText(icon, vdb)
	end)
end
