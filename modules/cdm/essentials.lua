-- CDM Essential Cooldowns viewer
local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local S = TUI._cdm

function S.LayoutEssential(isCapture)
	local vdb = S.GetViewerDB('essential')
	local useGlow = vdb and vdb.glow and vdb.glow.enabled
	local useSpellCD = vdb and vdb.showSpellCooldown

	S.LayoutIconViewer('essential', isCapture, function(icon)
		if useGlow then
			S.ApplyGlow(icon, vdb.glow)
		else
			S.StopGlow(icon)
		end
		if useSpellCD then
			S.HookSpellCooldownOverride(icon)
			S.ApplySpellCooldownDesaturation(icon)
		end
	end)
end
