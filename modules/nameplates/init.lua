-- TUI_Nameplates module aggregator — dispatches per-feature init based on user toggles
local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local NPS = E:GetModule('TUI_Nameplates')

function NPS:Initialize()
	local np = TUI.db.profile.nameplates
	if np and E.private.nameplates.enable then
		if np.hideFriendlyRealm then self:InitHideFriendlyRealm() end
		if np.interruptCastbarColors then self:HookCastbarInterrupt() end
		if np.focusGlow and np.focusGlow.enabled then self:InitFocusGlow() end
		if np.importantCast and np.importantCast.enabled then self:HookImportantCast() end
		if np.hoverHighlight and np.hoverHighlight.enabled then self:HookHoverHighlight() end
		if np.disableFriendlyHighlight then self:HookDisableFriendlyHighlight() end
		if np.questColor and np.questColor.enabled then self:HookQuestColor() end
	end
	if E:IsAddOnEnabled('Platynator') then self:InitPlatynatorTweaks() end
end

E:RegisterModule(NPS:GetName())
