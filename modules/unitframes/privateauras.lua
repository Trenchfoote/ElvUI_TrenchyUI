-- Private Aura preview: overlay fake PAs on unit frames during ElvUI's Show/Hide Auras preview
-- Only activates for unit frames where ElvUI's per-unit Private Auras are enabled
local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local UFC = E:GetModule('TUI_UnitFrames')

local ipairs = ipairs
local pairs = pairs
local tremove = table.remove

local FAKE_SPELL_ID = 5782 -- Matches ElvUI's fake aura (Fear)
local BORDER_ATLAS = 'ui-debuff-border-default-noicon'

local pool = {}
local activeByFrame = {}

local function AcquireFake()
	local fake = tremove(pool)
	if not fake then
		fake = CreateFrame('Frame', nil, UIParent)
		fake.icon = fake:CreateTexture(nil, 'BACKGROUND')
		fake.icon:SetAllPoints()
		fake.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		fake.border = fake:CreateTexture(nil, 'OVERLAY')
		fake.border:SetPoint('CENTER')
	end
	return fake
end

local function ReleaseFake(fake)
	fake:Hide()
	fake:SetParent(UIParent)
	fake:ClearAllPoints()
	fake.border:Hide()
	pool[#pool + 1] = fake
end

local HideFakes -- forward declaration

local function ShowFakes(frame)
	if not frame or not frame.forceShowAuras then HideFakes(frame) return end

	local tdb = TUI.db and TUI.db.profile and TUI.db.profile.privateAuras
	if not tdb or not tdb.enabled then HideFakes(frame) return end

	-- Respect ElvUI's per-unit PA enabled state
	local db = frame.db and frame.db.privateAuras
	if not db or not db.enable or not db.icon then HideFakes(frame) return end

	-- ElvUI populates element.auraIcons with the real anchor frames Blizzard uses.
	-- Overlay on those directly for pixel-accurate placement.
	local element = frame.PrivateAuras
	if not element or not element.auraIcons or #element.auraIcons == 0 then HideFakes(frame) return end

	local size = db.icon.size or 32
	local iconPoint = db.icon.point or 'CENTER'
	local borderScale = db.borderScale or 1
	local borderSize = size + (5 * borderScale)

	local list = activeByFrame[frame] or {}
	activeByFrame[frame] = list

	for i, anchor in ipairs(element.auraIcons) do
		local fake = list[i] or AcquireFake()
		list[i] = fake

		fake:SetParent(anchor)
		fake:SetFrameStrata(anchor:GetFrameStrata())
		fake:SetFrameLevel((anchor:GetFrameLevel() or 0) + 5)
		fake:SetSize(size, size)
		fake:ClearAllPoints()
		-- Match Blizzard's iconAnchor: point = iconPoint on both icon and anchor
		fake:SetPoint(iconPoint, anchor, iconPoint, 0, 0)

		local tex = C_Spell.GetSpellTexture(FAKE_SPELL_ID)
		if tex then fake.icon:SetTexture(tex) end

		if C_Texture.GetAtlasExists(BORDER_ATLAS) then
			fake.border:SetAtlas(BORDER_ATLAS)
			fake.border:SetSize(borderSize, borderSize)
			fake.border:Show()
		else
			fake.border:Hide()
		end

		fake:Show()
	end
end

function HideFakes(frame) -- forward-declared above
	local list = activeByFrame[frame]
	if not list then return end
	for _, fake in ipairs(list) do
		ReleaseFake(fake)
	end
	activeByFrame[frame] = nil
end

function UFC:InitPrivateAuraPreview()
	local UF = E:GetModule('UnitFrames', true)
	if not UF then return end

	-- "Show Auras" button on individual frames: sets forceShowAuras directly + calls CreateAndUpdateUF
	hooksecurefunc(UF, 'CreateAndUpdateUF', function(_, unit)
		local frame = UF[unit]
		if not frame then return end
		if frame.forceShowAuras then
			ShowFakes(frame)
		else
			HideFakes(frame)
		end
	end)

	-- Group frame preview (HeaderConfig → ForceShow cascade)
	hooksecurefunc(UF, 'ForceShow', function(_, frame)
		ShowFakes(frame)
	end)
	hooksecurefunc(UF, 'UnforceShow', function(_, frame)
		HideFakes(frame)
	end)
end

function UFC:RefreshPrivateAuraPreview()
	for frame in pairs(activeByFrame) do
		HideFakes(frame)
		ShowFakes(frame)
	end
end
