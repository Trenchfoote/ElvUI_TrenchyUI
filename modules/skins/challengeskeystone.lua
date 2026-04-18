local E = unpack(ElvUI)
local S = E:GetModule('Skins')
local ipairs = ipairs

local function HideAffixCircleMasks(list)
	if not list then return end
	for _, affix in ipairs(list) do
		if affix.CircleMask then
			affix.CircleMask:Hide()
		end
	end
end

local function SkinChallengesKeystone()
	if not (E.private.skins.blizzard.enable and E.private.skins.blizzard.lfg) then return end

	local KeyStoneFrame = _G.ChallengesKeystoneFrame
	if KeyStoneFrame then
		hooksecurefunc(KeyStoneFrame, 'OnKeystoneSlotted', function(frame)
			HideAffixCircleMasks(frame.Affixes)
		end)
	end

	if _G.ChallengesFrameWeeklyInfoMixin then
		hooksecurefunc(_G.ChallengesFrameWeeklyInfoMixin, 'SetUp', function(info)
			local child = info.Child
			if not child then return end
			HideAffixCircleMasks(child.AffixesContainer and child.AffixesContainer.Affixes or child.Affixes)
		end)
	end
end

S:AddCallbackForAddon('Blizzard_ChallengesUI', 'TUI_SkinChallengesKeystone', SkinChallengesKeystone)
