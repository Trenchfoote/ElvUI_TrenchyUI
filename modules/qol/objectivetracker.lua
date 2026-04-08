local E = unpack(ElvUI)
local QOL = E:GetModule('TUI_QoL')

function QOL:InitHideObjectiveInCombat()
	local tracker = ObjectiveTrackerFrame
	if not tracker then return end

	local BL = E:GetModule('Blizzard')
	local wasCollapsed = false

	QOL:RegisterEvent('PLAYER_REGEN_DISABLED', function()
		wasCollapsed = BL:ObjectiveTracker_IsCollapsed(tracker)
		if not wasCollapsed then
			BL:ObjectiveTracker_Collapse(tracker)
		end
	end)
	QOL:RegisterEvent('PLAYER_REGEN_ENABLED', function()
		if not wasCollapsed then
			BL:ObjectiveTracker_Expand(tracker)
		end
	end)
end
