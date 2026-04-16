-- Skin for BigWigs Keystones (/key) frame
local E = unpack(ElvUI)
local S = E:GetModule('Skins')

if not E:IsAddOnEnabled('BigWigs') then return end

local skinned = false

local function SkinKeystoneFrame(frame)
	if skinned then return end
	skinned = true

	S:HandlePortraitFrame(frame)

	if frame.PortraitContainer then
		frame.PortraitContainer:SetAlpha(0)
	end

	for _, child in ipairs({ frame:GetChildren() }) do
		if child:IsObjectType('Button') and child.Left and child.Middle and child.Right and child.Text then
			S:HandleTab(child)
		elseif child:IsObjectType('ScrollFrame') and child.ScrollBar then
			S:HandleTrimScrollBar(child.ScrollBar)
		end
	end
end

-- Find the BW keystones frame via EnumerateFrames (avoids UIParent:GetChildren taint)
-- Identified by unique properties: tip, teleportBar, CloseButton, TitleContainer
C_Timer.After(1, function()
	if skinned then return end
	local frame = EnumerateFrames()
	while frame do
		local ok, match = pcall(function()
			return frame.tip and frame.teleportBar and frame.CloseButton and frame.TitleContainer
		end)
		if ok and match then
			SkinKeystoneFrame(frame)
			return
		end
		frame = EnumerateFrames(frame)
	end
end)
