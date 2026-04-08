local E = unpack(ElvUI)
local QOL = E:GetModule('TUI_QoL')

local hooksecurefunc = hooksecurefunc

local DELETE_DIALOGS = {
	['DELETE_GOOD_ITEM'] = true,
	['DELETE_GOOD_QUEST_ITEM'] = true,
}

function QOL:InitAutoFillDelete()
	hooksecurefunc('StaticPopup_Show', function(which)
		if not DELETE_DIALOGS[which] then return end

		for i = 1, STATICPOPUP_NUMDIALOGS or 4 do
			local frame = _G['StaticPopup' .. i]
			if frame and frame:IsShown() and frame.which == which then
				local editBox = frame.editBox or (frame.GetEditBox and frame:GetEditBox())
				if editBox then
					editBox:SetText(DELETE_ITEM_CONFIRM_STRING)
					if StaticPopup_StandardConfirmationTextHandler then
						StaticPopup_StandardConfirmationTextHandler(editBox, DELETE_ITEM_CONFIRM_STRING)
					end
				end
				break
			end
		end
	end)
end
