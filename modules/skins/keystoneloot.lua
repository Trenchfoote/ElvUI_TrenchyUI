-- KeystoneLoot skin. Light touch: ElvUI window chrome, dropdowns, tabs and nav
-- arrows only — backgrounds/icon art left as Blizzard's (stripping looked worse).
local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local SKN = E:GetModule('TUI_Skins')
local S = E:GetModule('Skins')

local hooksecurefunc = hooksecurefunc
local pairs = pairs

local skinned = false

local function SkinEntryFrame(frame)
	if not frame or frame.TUI_Skinned then return end
	frame.TUI_Skinned = true
	if frame.BackButton then S:HandleNextPrevButton(frame.BackButton, 'left') end
	if frame.NextButton then S:HandleNextPrevButton(frame.NextButton, 'right') end
end

local function SkinTabs(tabSystem)
	if not tabSystem then return end
	for _, child in pairs({ tabSystem:GetChildren() }) do
		if child.IsObjectType and child:IsObjectType('Button') and not child.TUI_Skinned then
			child.TUI_Skinned = true
			S:HandleTab(child)
		end
	end
end

local function SkinKL()
	if skinned then return end
	local frame = _G.KeystoneLootFrame
	if not frame then return end
	skinned = true

	-- Window chrome only: border, close button, portrait (no background strip)
	S:HandlePortraitFrame(frame)

	for _, key in pairs({ 'SlotDropdown', 'ClassDropdown', 'ItemLevelDropdown' }) do
		local dd = frame[key]
		if dd then S:HandleDropDownBox(dd, dd:GetWidth()) end
	end
	if frame.SettingsDropdown then S:HandleButton(frame.SettingsDropdown) end

	SkinTabs(frame.TabSystem)

	local rf = frame.RaidsFrame
	if rf and rf.DropdownButton then S:HandleButton(rf.DropdownButton) end

	-- Only the carousel nav arrows on dungeon/raid rows
	if _G.KeystoneLootDungeonsFrameMixin then
		hooksecurefunc(_G.KeystoneLootDungeonsFrameMixin, 'Refresh', function(self)
			if not self.entryPool then return end
			for f in self.entryPool:EnumerateActive() do SkinEntryFrame(f) end
		end)
	end
	if _G.KeystoneLootRaidBlockMixin then
		hooksecurefunc(_G.KeystoneLootRaidBlockMixin, 'SetRaid', function(self)
			if not self.entryPool then return end
			for f in self.entryPool:EnumerateActive() do SkinEntryFrame(f) end
		end)
	end

	hooksecurefunc(frame.TabSystem or frame, 'Show', function() SkinTabs(frame.TabSystem) end)
end

function SKN:InitSkinKeystoneLoot()
	if not E:IsAddOnEnabled('KeystoneLoot') then return end
	if not (TUI.db and TUI.db.profile and TUI.db.profile.addons and TUI.db.profile.addons.skinKeystoneLoot) then return end

	local frame = _G.KeystoneLootFrame
	if frame then
		frame:HookScript('OnShow', SkinKL)
		if frame:IsShown() then SkinKL() end
	end
end
