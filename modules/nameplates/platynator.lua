-- Platynator nameplate tweaks
local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')

local UnitHealthPercent = UnitHealthPercent
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local ScaleTo100 = CurveConstants and CurveConstants.ScaleTo100

local hookedHealthWidgets = {}
local hookedTargetWidgets = {}
local hookedMouseoverWidgets = {}

-- Find Platynator's display frame on a nameplate
local function GetPlatyDisplay(nameplate)
	for _, child in pairs({ nameplate:GetChildren() }) do
		if child.widgets then return child end
	end
end

-- Hook UpdateText to replace health text without % using format (resolves secrets C-side)
local function HookHealthWidget(widget)
	if hookedHealthWidgets[widget] then return end
	hookedHealthWidgets[widget] = true

	hooksecurefunc(widget, 'UpdateText', function(self)
		if not self.unit or not self.text then return end
		if UnitIsDeadOrGhost(self.unit) then return end
		local pct = UnitHealthPercent(self.unit, true, ScaleTo100)
		if pct then
			self.text:SetFormattedText('%d', pct)
		end
	end)
end

-- Hook a target highlight widget to use class color
local function HookTargetWidget(widget)
	if hookedTargetWidgets[widget] then return end
	hookedTargetWidgets[widget] = true

	hooksecurefunc(widget, 'ApplyTarget', function(self)
		if not self:IsShown() or not self.highlight then return end
		local cc = E:ClassColor(E.myclass)
		if cc then self.highlight:SetVertexColor(cc.r, cc.g, cc.b, self.highlight:GetAlpha()) end
	end)
end

-- Hook a mouseover highlight widget to use class color
local function HookMouseoverWidget(widget)
	if hookedMouseoverWidgets[widget] then return end
	hookedMouseoverWidgets[widget] = true

	hooksecurefunc(widget, 'ApplyMouseover', function(self)
		if not self:IsShown() or not self.highlight then return end
		local cc = E:ClassColor(E.myclass)
		if cc then self.highlight:SetVertexColor(cc.r, cc.g, cc.b, self.highlight:GetAlpha()) end
	end)
end

local eventFrame = CreateFrame('Frame')

function TUI:InitPlatynatorTweaks()
	if self._hookedPlatynator then return end
	self._hookedPlatynator = true

	local db = self.db.profile.platynator
	if not db then return end

	local function ProcessNameplate(unit)
		local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
		if not nameplate then return end

		local display = GetPlatyDisplay(nameplate)
		if not display or not display.widgets then return end

		for _, w in ipairs(display.widgets) do
			if db.hidePercentSign and w.UpdateText and w.text and w.details and w.details.kind == 'health' then
				HookHealthWidget(w)
				if w.unit then w:UpdateText() end
			end
			if db.classColorTarget and w.ApplyTarget and w.highlight and w.details and w.details.kind == 'target' then
				HookTargetWidget(w)
				if w.unit then w:ApplyTarget() end
			end
			if db.classColorMouseover and w.ApplyMouseover and w.highlight and w.details and w.details.kind == 'mouseover' then
				HookMouseoverWidget(w)
			end
		end
	end

	eventFrame:RegisterEvent('NAME_PLATE_UNIT_ADDED')
	eventFrame:SetScript('OnEvent', function(_, event, unit)
		if event == 'NAME_PLATE_UNIT_ADDED' then
			ProcessNameplate(unit)
		end
	end)

	-- Hook any nameplates already visible
	for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
		local unit = nameplate.namePlateUnitToken
		if unit then ProcessNameplate(unit) end
	end
end
