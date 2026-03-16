local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local NP = E:GetModule('NamePlates')

local function PostCastFailInterrupted(castbar)
	local c = NP.db.colors.castInterruptedColor
	if c then castbar:SetStatusBarColor(c.r, c.g, c.b) end
	castbar.TUI_IsInterruptedOrFailed = true
end

function TUI:HookCastbarFix()
	if self._hookedCastbarFix then return end
	self._hookedCastbarFix = true

	hooksecurefunc(NP, 'Castbar_PostCastFail', PostCastFailInterrupted)
	hooksecurefunc(NP, 'Castbar_PostCastInterrupted', PostCastFailInterrupted)
end
