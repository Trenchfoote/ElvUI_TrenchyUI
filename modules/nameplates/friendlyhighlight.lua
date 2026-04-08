local E = unpack(ElvUI)
local NPS = E:GetModule('TUI_Nameplates')
local NP = E:GetModule('NamePlates')

function NPS:HookDisableFriendlyHighlight()
	if self._hookedFriendlyHighlight then return end
	self._hookedFriendlyHighlight = true

	hooksecurefunc(NP, 'Update_Highlight', function(_, nameplate)
		if not nameplate or not nameplate.frameType then return end
		local ft = nameplate.frameType
		if (ft == 'FRIENDLY_PLAYER' or ft == 'FRIENDLY_NPC') and nameplate:IsElementEnabled('Highlight') then
			nameplate:DisableElement('Highlight')
		end
	end)
end
