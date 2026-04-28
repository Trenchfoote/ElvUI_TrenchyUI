-- Platynator nameplate tweaks
local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local NPS = E:GetModule('TUI_Nameplates')

local C_NamePlate = C_NamePlate
local C_Timer_After = C_Timer.After

local processedDisplays = {}

-- Overwrite the highlight texture with the player's class color. Hook SetVertexColor
-- as a safety net so a picker re-apply won't undo us.
local function ApplyClassColor(highlight)
	if highlight._tuiHooked then return end
	highlight._tuiHooked = true

	local cc = E.myClassColor
	if cc then
		local a = select(4, highlight:GetVertexColor())
		highlight:SetVertexColor(cc.r, cc.g, cc.b, a)
	end

	hooksecurefunc(highlight, 'SetVertexColor', function(self, r, g, b, a)
		if r == nil or E:IsSecretValue(r) then return end
		local color = E.myClassColor
		if not color or (r == color.r and g == color.g and b == color.b) then return end
		self:SetVertexColor(color.r, color.g, color.b, a)
	end)
end

local function ProcessDisplay(display)
	if processedDisplays[display] then return end
	processedDisplays[display] = true

	local db = TUI.db.profile.platynator
	for _, w in ipairs(display.widgets) do
		local kind = w.details and w.details.kind
		if w.highlight and ((kind == 'target' and db.classColorTarget) or (kind == 'mouseover' and db.classColorMouseover)) then
			ApplyClassColor(w.highlight)
		end
	end
end

local function FindDisplay(nameplate)
	for _, child in pairs({ nameplate:GetChildren() }) do
		if child.widgets then return child end
	end
end

-- Retry with backoff because Platynator may not have built the display yet
local function ProcessWithRetry(nameplate, attempt)
	local display = FindDisplay(nameplate)
	if display then ProcessDisplay(display) return end
	if attempt < 4 then
		C_Timer_After(0.1 * attempt, function()
			if nameplate:IsShown() then ProcessWithRetry(nameplate, attempt + 1) end
		end)
	end
end

local eventFrame = CreateFrame('Frame')

function NPS:InitPlatynatorTweaks()
	if self._hookedPlatynator then return end
	local db = TUI.db.profile.platynator
	if not db or not (db.classColorTarget or db.classColorMouseover) then return end
	self._hookedPlatynator = true

	eventFrame:RegisterEvent('NAME_PLATE_UNIT_ADDED')
	eventFrame:SetScript('OnEvent', function(_, _, unit)
		local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
		if nameplate then ProcessWithRetry(nameplate, 1) end
	end)

	for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
		ProcessWithRetry(nameplate, 1)
	end
end
