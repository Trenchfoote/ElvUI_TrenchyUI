-- CDM Essential Cooldowns viewer
local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local S = TUI._cdm

function S.LayoutEssential(isCapture)
	local vGlow = S.GetViewerDB('essential')
	local useGlow = vGlow and vGlow.glow and vGlow.glow.enabled

	S.LayoutIconViewer('essential', isCapture, function(icon, vdb)
		if useGlow then
			S.ApplyGlow(icon, vdb.glow)
		else
			S.StopGlow(icon)
		end
	end)
end
