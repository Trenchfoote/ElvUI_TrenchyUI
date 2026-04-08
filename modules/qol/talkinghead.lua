local E = unpack(ElvUI)
local QOL = E:NewModule('TUI_QoL', 'AceEvent-3.0', 'AceHook-3.0')

local tremove = tremove

local function KillTalkingHead()
	local thf = TalkingHeadFrame
	if not thf then return end

	thf:UnregisterEvent('TALKINGHEAD_REQUESTED')
	thf:UnregisterEvent('TALKINGHEAD_CLOSE')
	thf:UnregisterEvent('SOUNDKIT_FINISHED')
	thf:UnregisterEvent('LOADING_SCREEN_ENABLED')
	thf:Hide()

	if AlertFrame and AlertFrame.alertFrameSubSystems then
		for i = #AlertFrame.alertFrameSubSystems, 1, -1 do
			local sub = AlertFrame.alertFrameSubSystems[i]
			if sub.anchorFrame and sub.anchorFrame == thf then
				tremove(AlertFrame.alertFrameSubSystems, i)
			end
		end
	end

	if not QOL:IsHooked(thf, 'Show') then
		QOL:SecureHook(thf, 'Show', function(self) self:Hide() end)
	end
end

function QOL:InitHideTalkingHead()
	KillTalkingHead()
end
