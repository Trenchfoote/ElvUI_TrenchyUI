-- CDM Utility Cooldowns viewer
local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local S = TUI._cdm

function S.LayoutUtility(isCapture)
	local vGlow = S.GetViewerDB('utility')
	local useGlow = vGlow and vGlow.glow and vGlow.glow.enabled

	S.LayoutIconViewer('utility', isCapture, function(icon, vdb)
		if useGlow then
			S.ApplyGlow(icon, vdb.glow)
		else
			S.StopGlow(icon)
		end
	end)
end
