local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local NPS = E:NewModule('TUI_Nameplates', 'AceEvent-3.0', 'AceHook-3.0')
local NP = E:GetModule('NamePlates')

local function PostUpdate_ClassColorTarget(element, unit)
	if not TUI.db.profile.nameplates.classColorTargetIndicator then return end
	if not unit or not E:UnitIsUnit(unit, 'target') then return end

	local c = E:ClassColor(E.myclass)
	if not c then return end

	if element.TopIndicator and element.TopIndicator:IsShown() then
		element.TopIndicator:SetVertexColor(c.r, c.g, c.b)
	end
	if element.LeftIndicator and element.LeftIndicator:IsShown() then
		element.LeftIndicator:SetVertexColor(c.r, c.g, c.b)
	end
	if element.RightIndicator and element.RightIndicator:IsShown() then
		element.RightIndicator:SetVertexColor(c.r, c.g, c.b)
	end
	if element.Shadow and element.Shadow:IsShown() then
		element.Shadow:SetBackdropBorderColor(c.r, c.g, c.b)
	end
	if element.Spark and element.Spark:IsShown() then
		element.Spark:SetVertexColor(c.r, c.g, c.b)
	end
end

function NPS:HookClassColorTargetIndicator()
	if self._hookedClassColorTarget then return end
	self._hookedClassColorTarget = true

	hooksecurefunc(NP, 'Update_TargetIndicator', function(_, nameplate)
		if nameplate and nameplate.TargetIndicator then
			nameplate.TargetIndicator.PostUpdate = PostUpdate_ClassColorTarget
		end
	end)

	-- Catch plates configured before our hook
	C_Timer.After(0, function()
		for nameplate in pairs(NP.Plates) do
			if nameplate.TargetIndicator then
				nameplate.TargetIndicator.PostUpdate = PostUpdate_ClassColorTarget
			end
		end
	end)
end
