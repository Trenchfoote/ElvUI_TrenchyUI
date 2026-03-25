-- CDM Essential Cooldowns viewer
local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local S = TUI._cdm

function S.LayoutEssential(isCapture)
	local vdb = S.GetViewerDB('essential')
	local useGlow = vdb and vdb.glow and vdb.glow.enabled

	S.LayoutIconViewer('essential', isCapture, function(icon)
		if useGlow then
			S.ApplyGlow(icon, vdb.glow)
		else
			S.StopGlow(icon)
		end
		S.ApplyKeybindText(icon, vdb)
	end)
end
