local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local QOL = E:GetModule('TUI_QoL')
local AB = E:GetModule('ActionBars')

local pairs = pairs

local function LinkEnabled()
	local db = TUI.db.profile.qol
	return db and db.linkActionBarMouseover
end

-- Pet and Stance bars share ElvUI's Bar_OnEnter/Button_OnEnter handlers and set
-- bar.db/bar.mouseover like the numbered bars, but live outside AB.handledBars.
-- Resolved at init (not file load) so the frames are guaranteed to exist.
local extraBars = {}

-- A bar participates in the linked group if it is enabled and set to mouse over.
local function IsLinkedBar(bar)
	return bar and bar.mouseover and bar.db and bar.db.enabled
end

-- Rebuilt each fade pass into a reused module-level buffer (no per-event allocation):
-- all currently linked bars across the numbered set plus pet/stance.
local linkedBuffer = {}
local function CollectLinkedBars()
	local n = 0
	for _, bar in pairs(AB.handledBars) do
		if IsLinkedBar(bar) then n = n + 1; linkedBuffer[n] = bar end
	end
	for i = 1, #extraBars do
		local bar = extraBars[i]
		if IsLinkedBar(bar) then n = n + 1; linkedBuffer[n] = bar end
	end
	for i = n + 1, #linkedBuffer do linkedBuffer[i] = nil end
	return n
end

-- True while the cursor still sits on any linked bar, so a leave on one bar does
-- not fade the whole group out while the mouse is over a sibling. Scans directly
-- (not via linkedBuffer) so it can be called from FadeSiblingsOut without clobbering
-- that buffer mid-pass.
local function AnyLinkedBarHovered()
	for _, bar in pairs(AB.handledBars) do
		if IsLinkedBar(bar) and bar:IsMouseOver() then return true end
	end
	for i = 1, #extraBars do
		local bar = extraBars[i]
		if IsLinkedBar(bar) and bar:IsMouseOver() then return true end
	end
	return false
end

-- Fade the SIBLINGS of the entered bar in. The entered bar is intentionally
-- skipped: ElvUI's own handler is already fading it this same event, and stacking
-- a second fade on it competes for the shared FadeObject (the source of glitches).
local function FadeSiblingsIn(entered)
	local n = CollectLinkedBars()
	for i = 1, n do
		local bar = linkedBuffer[i]
		if bar ~= entered then
			E:UIFrameFadeIn(bar, 0.2, bar:GetAlpha(), bar.db.alpha or 1)
			AB:FadeBarBlings(bar, bar.db.alpha)
		end
	end
end

local function FadeGroupOut(left)
	-- Still over the group (moved to a sibling, or onto this bar's backdrop):
	-- ElvUI's native leave handler already faded `left` out, so fade it back in
	-- to keep the whole group visible. Without this, leaving one bar for another
	-- leaves the departed bar stuck hidden until it is re-hovered.
	if AnyLinkedBarHovered() then
		E:UIFrameFadeIn(left, 0.2, left:GetAlpha(), left.db.alpha or 1)
		AB:FadeBarBlings(left, left.db.alpha)
		return
	end
	-- Mouse left the group entirely: fade the siblings out. `left` is already
	-- faded out by ElvUI's native handler.
	local n = CollectLinkedBars()
	for i = 1, n do
		local bar = linkedBuffer[i]
		if bar ~= left then
			E:UIFrameFadeOut(bar, 0.2, bar:GetAlpha(), 0)
			AB:FadeBarBlings(bar, 0)
		end
	end
end

-- ElvUI defines these as methods (AB:Handler), so the post-hook receives AB as the
-- first arg and the frame as the second; discard self and read the frame.
local function OnBarEnter(_, bar)
	if LinkEnabled() and IsLinkedBar(bar) then FadeSiblingsIn(bar) end
end

local function OnBarLeave(_, bar)
	if LinkEnabled() and IsLinkedBar(bar) then FadeGroupOut(bar) end
end

local function OnButtonEnter(_, button)
	if LinkEnabled() and button then
		local bar = button:GetParent()
		if IsLinkedBar(bar) then FadeSiblingsIn(bar) end
	end
end

local function OnButtonLeave(_, button)
	if LinkEnabled() and button then
		local bar = button:GetParent()
		if IsLinkedBar(bar) then FadeGroupOut(bar) end
	end
end

function QOL:InitActionBarLink()
	if self._actionBarLinkHooked then return end
	if not (AB and AB.handledBars) then return end
	self._actionBarLinkHooked = true

	if _G.ElvUI_BarPet then extraBars[#extraBars + 1] = _G.ElvUI_BarPet end
	if _G.ElvUI_StanceBar then extraBars[#extraBars + 1] = _G.ElvUI_StanceBar end

	-- Post-hook ElvUI's per-bar fade handlers so the linked group fades together
	hooksecurefunc(AB, 'Bar_OnEnter', OnBarEnter)
	hooksecurefunc(AB, 'Bar_OnLeave', OnBarLeave)
	hooksecurefunc(AB, 'Button_OnEnter', OnButtonEnter)
	hooksecurefunc(AB, 'Button_OnLeave', OnButtonLeave)
end
