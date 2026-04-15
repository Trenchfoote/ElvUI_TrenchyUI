local E = unpack(ElvUI)
local S = E:GetModule('Skins')

local function SkinPlayerSpells()
	if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.talent) then return end

	local SpecFrame = _G.PlayerSpellsFrame and _G.PlayerSpellsFrame.SpecFrame
	if not SpecFrame then return end

	hooksecurefunc(SpecFrame, 'UpdateSpecFrame', function(frame)
		if not frame.SpecContentFramePool then return end

		for specContentFrame in frame.SpecContentFramePool:EnumerateActive() do
			if specContentFrame.SpellButtonPool then
				for button in specContentFrame.SpellButtonPool:EnumerateActive() do
					if button.CircleMask then
						button.CircleMask:Hide()
					end
				end
			end
		end
	end)
end

S:AddCallbackForAddon('Blizzard_PlayerSpells', 'TUI_SkinPlayerSpells', SkinPlayerSpells)
