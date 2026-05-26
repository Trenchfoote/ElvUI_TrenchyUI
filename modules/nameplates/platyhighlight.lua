-- Platynator highlight class-color override: recolor Target/Mouseover highlights to the player's class color.
local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local NPS = E:GetModule('TUI_Nameplates')

local C_NamePlate = C_NamePlate
local C_Timer = C_Timer
local hooksecurefunc = hooksecurefunc
local ipairs, pairs = ipairs, pairs

local KIND_OPTION = {
	target    = 'classColorTarget',
	mouseover = 'classColorMouseover',
}

local SWEEP_INTERVAL = 0.25

local hookedTextures = {}
local hookedWidgets  = {}
local plateDisplays  = {}
local sweepTicker

local function ShouldClassColor(widget)
	local d = widget.details
	if not d then return false end
	local key = KIND_OPTION[d.kind]
	if not key then return false end
	local db = TUI.db.profile.nameplates.platyHighlight
	return db and db.enabled and db[key]
end

local function HookTexture(texture, widget)
	if hookedTextures[texture] then return end
	hookedTextures[texture] = widget
	hooksecurefunc(texture, 'SetVertexColor', function(self, r, g, b, a)
		if self.__tuiGuard or not ShouldClassColor(widget) then return end
		local c = E:ClassColor(E.myclass)
		self.__tuiGuard = true
		self:SetVertexColor(c.r, c.g, c.b, a)
		self.__tuiGuard = false
	end)
end

local function PaintWidget(widget)
	local tex, d = widget.highlight, widget.details
	if not tex or not d or not d.color then return end
	if ShouldClassColor(widget) then
		local c = E:ClassColor(E.myclass)
		tex:SetVertexColor(c.r, c.g, c.b, d.color.a)
	else
		tex:SetVertexColor(d.color.r, d.color.g, d.color.b, d.color.a)
	end
end

local function HookWidget(widget)
	if hookedWidgets[widget] then return end
	local d = widget.details
	if not d or not KIND_OPTION[d.kind] or not widget.highlight then return end
	hookedWidgets[widget] = true
	HookTexture(widget.highlight, widget)
	PaintWidget(widget)
end

-- Platy parents its display (the child holding .widgets) directly to the nameplate;
-- cache it per plate so steady-state ticks skip the GetChildren scan.
local function GetDisplay(plate)
	local cached = plateDisplays[plate]
	if cached and cached:GetParent() == plate and cached.widgets then
		return cached
	end
	for _, child in ipairs({ plate:GetChildren() }) do
		if child.widgets then
			plateDisplays[plate] = child
			return child
		end
	end
	plateDisplays[plate] = nil
end

local function SweepPlate(plate)
	local display = GetDisplay(plate)
	if not display then return end
	for _, w in ipairs(display.widgets) do
		HookWidget(w)
	end
end

local function SweepAllPlates()
	for _, plate in ipairs(C_NamePlate.GetNamePlates() or {}) do
		SweepPlate(plate)
	end
end

local function OnNamePlateAdded(_, unit)
	local plate = C_NamePlate.GetNamePlateForUnit(unit)
	if not plate then return end
	SweepPlate(plate)
	-- Platy's display may attach after our handler on the first add; retry briefly.
	for i = 1, 4 do
		C_Timer.After(0.1 * i, function()
			local p = C_NamePlate.GetNamePlateForUnit(unit)
			if p then SweepPlate(p) end
		end)
	end
end

local function OnTargetChanged()
	local plate = C_NamePlate.GetNamePlateForUnit('target')
	if plate then SweepPlate(plate) end
end

local function OnMouseoverChanged()
	local plate = C_NamePlate.GetNamePlateForUnit('mouseover')
	if plate then SweepPlate(plate) end
end

-- Repaint hooked widgets when a toggle flips
function NPS:RefreshPlatyHighlight()
	for widget in pairs(hookedWidgets) do
		PaintWidget(widget)
	end
end

function NPS:InitPlatyHighlight()
	if self._platyHighlightInit then
		SweepAllPlates()
		return
	end
	self._platyHighlightInit = true

	self:RegisterEvent('NAME_PLATE_UNIT_ADDED', OnNamePlateAdded)
	self:RegisterEvent('PLAYER_TARGET_CHANGED', OnTargetChanged)
	self:RegisterEvent('UPDATE_MOUSEOVER_UNIT', OnMouseoverChanged)
	self:RegisterEvent('PLAYER_ENTERING_WORLD', SweepAllPlates)

	-- Safety net for Platy-internal widget rebuilds (style changes, pool refills) we can't hook directly
	sweepTicker = C_Timer.NewTicker(SWEEP_INTERVAL, SweepAllPlates)

	SweepAllPlates()
end
