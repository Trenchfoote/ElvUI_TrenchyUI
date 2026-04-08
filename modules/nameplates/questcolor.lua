local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local NPS = E:GetModule('TUI_Nameplates')
local NP = E:GetModule('NamePlates')

local IsInInstance = IsInInstance

local function ApplyQuestColor(nameplate)
	if IsInInstance() then return end
	if nameplate.TUI_QuestGUID ~= nameplate.unitGUID then return end
	local c = TUI.db.profile.nameplates.questColor.color
	NP:SetStatusBarColor(nameplate.Health, c.r, c.g, c.b)
end

function NPS:HookQuestColor()
	if self._hookedQuestColor then return end
	self._hookedQuestColor = true

	hooksecurefunc(NP, 'Health_UpdateColor', function(nameplate, _, unit)
		if not unit then return end
		ApplyQuestColor(nameplate)
	end)

	hooksecurefunc(NP, 'ThreatIndicator_PostUpdate', function(Indicator, _, status)
		if not status then return end
		ApplyQuestColor(Indicator.__owner)
	end)

	-- QuestIcons PostUpdate fires after tooltip scan; stamp GUID so stale data is never trusted
	local function QuestIconsPostUpdate(element)
		local nameplate = element.__owner
		if not nameplate or not nameplate.Health then return end
		nameplate.TUI_QuestGUID = element.lastQuests and nameplate.unitGUID or nil
		ApplyQuestColor(nameplate)
	end

	hooksecurefunc(NP, 'Update_QuestIcons', function(_, nameplate)
		local qi = nameplate and nameplate.QuestIcons
		if qi and qi.PostUpdate ~= QuestIconsPostUpdate then
			qi.PostUpdate = QuestIconsPostUpdate
		end
	end)
end
