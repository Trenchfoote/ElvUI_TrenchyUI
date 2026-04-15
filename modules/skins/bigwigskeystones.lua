-- Skin for BigWigs Keystones (/key) frame
local E = unpack(ElvUI)
local S = E:GetModule('Skins')

if not E:IsAddOnEnabled('BigWigs') then return end

local skinned = false

local function SkinKeystoneFrame(frame)
	if skinned then return end
	skinned = true

	S:HandlePortraitFrame(frame)

	-- Hide the BigWigs portrait icon
	if frame.PortraitContainer then
		frame.PortraitContainer:SetAlpha(0)
	end

	-- Tabs and scroll bar
	for _, child in ipairs({ frame:GetChildren() }) do
		if child:IsObjectType('Button') and child.Left and child.Middle and child.Right and child.Text then
			S:HandleTab(child)
		elseif child:IsObjectType('ScrollFrame') and child.ScrollBar then
			S:HandleTrimScrollBar(child.ScrollBar)
		end
	end
end

-- Hook the /key slash command: BigWigs registers it as SlashCmdList["key"]
-- On first invocation the frame becomes visible and we skin it
C_Timer.After(0, function()
	if not SlashCmdList['key'] then return end

	hooksecurefunc(SlashCmdList, 'key', function()
		if skinned then return end

		-- The frame is now visible — find it among UIParent's shown children
		for _, child in ipairs({ UIParent:GetChildren() }) do
			local ok, match = pcall(function()
				return child:IsShown() and child.PortraitContainer and child.CloseButton and child.TitleContainer
			end)
			if ok and match then
				SkinKeystoneFrame(child)
				return
			end
		end
	end)
end)
