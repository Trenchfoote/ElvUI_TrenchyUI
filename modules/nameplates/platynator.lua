-- Platynator nameplate tweaks
local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')

local UnitHealthPercent = UnitHealthPercent
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local ScaleTo100 = CurveConstants and CurveConstants.ScaleTo100
local C_Timer_After = C_Timer.After

local hookedWidgets = {}

local function HookWidget(widget, hookName, callback)
	local key = widget[hookName]
	if not key then return end
	if hookedWidgets[widget] and hookedWidgets[widget][hookName] then return end
	if not hookedWidgets[widget] then hookedWidgets[widget] = {} end
	hookedWidgets[widget][hookName] = true
	hooksecurefunc(widget, hookName, callback)
end

local function ProcessDisplay(display)
	local db = TUI.db.profile.platynator
	if not db or not display.widgets then return end

	for _, w in ipairs(display.widgets) do
		if db.hidePercentSign and w.UpdateText and w.text and w.details and w.details.kind == 'health' then
			HookWidget(w, 'UpdateText', function(self)
				if not self.unit or not self.text then return end
				if UnitIsDeadOrGhost(self.unit) then return end
				local pct = UnitHealthPercent(self.unit, true, ScaleTo100)
				if pct then self.text:SetFormattedText('%d', pct) end
			end)
			if w.unit then w:UpdateText() end
		end
		if db.classColorTarget and w.ApplyTarget and w.highlight and w.details and w.details.kind == 'target' then
			HookWidget(w, 'ApplyTarget', function(self)
				if not self:IsShown() or not self.highlight then return end
				local cc = E:ClassColor(E.myclass)
				if cc then self.highlight:SetVertexColor(cc.r, cc.g, cc.b, self.highlight:GetAlpha()) end
			end)
		end
		if db.classColorMouseover and w.ApplyMouseover and w.highlight and w.details and w.details.kind == 'mouseover' then
			HookWidget(w, 'ApplyMouseover', function(self)
				if not self:IsShown() or not self.highlight then return end
				local cc = E:ClassColor(E.myclass)
				if cc then self.highlight:SetVertexColor(cc.r, cc.g, cc.b, self.highlight:GetAlpha()) end
			end)
		end
	end
end

local eventFrame = CreateFrame('Frame')

function TUI:InitPlatynatorTweaks()
	if self._hookedPlatynator then return end
	self._hookedPlatynator = true

	local db = self.db.profile.platynator
	if not db then return end

	-- Find Platynator display anchored to a nameplate
	local function FindAndProcess(nameplate)
		-- Check nameplate children first (fast path)
		for _, child in pairs({ nameplate:GetChildren() }) do
			if child.widgets then
				ProcessDisplay(child)
				return
			end
		end
		-- Fallback: scan UIParent children anchored to this nameplate
		for _, child in pairs({ UIParent:GetChildren() }) do
			if child.widgets and child:IsShown() then
				local _, anchor = child:GetPoint(1)
				if anchor == nameplate then
					ProcessDisplay(child)
					return
				end
			end
		end
	end

	eventFrame:RegisterEvent('NAME_PLATE_UNIT_ADDED')
	eventFrame:SetScript('OnEvent', function(_, _, unit)
		C_Timer_After(0.1, function()
			local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
			if not nameplate then return end
			FindAndProcess(nameplate)
		end)
	end)

	-- Hook any displays already visible
	C_Timer_After(0.1, function()
		for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
			FindAndProcess(nameplate)
		end
	end)
end
