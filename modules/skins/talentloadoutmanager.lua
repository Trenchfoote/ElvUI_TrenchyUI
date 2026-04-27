-- Talent Loadout Manager skin
local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local SKN = E:GetModule('TUI_Skins')
local S = E:GetModule('Skins')

local hooksecurefunc = hooksecurefunc

local function SkinButton(btn)
	if not btn or btn.tuiSkinned then return end
	btn.tuiSkinned = true
	S:HandleButton(btn)
end

local function ApplyToggleArrow(btn, collapsed)
	local rot = (collapsed and S.ArrowRotation.right) or S.ArrowRotation.left
	local n = btn:GetNormalTexture()
	if n then n:SetTexCoord(0, 1, 0, 1); n:SetRotation(rot) end
	local p = btn:GetPushedTexture()
	if p then p:SetTexCoord(0, 1, 0, 1); p:SetRotation(rot) end
	local h = btn:GetHighlightTexture()
	if h then h:SetTexCoord(0, 1, 0, 1) end
end

local function SkinToggleButton(btn, Module)
	if not btn or btn.tuiSkinned then return end
	btn.tuiSkinned = true

	btn:Size(20, 20)
	local collapsed = Module.GetCollapsed and Module:GetCollapsed()
	S:HandleNextPrevButton(btn, collapsed and 'right' or 'left')
	ApplyToggleArrow(btn, collapsed)

	hooksecurefunc(Module, 'SetCollapsed', function(self, c)
		if self.SideBar and self.SideBar.ToggleSideBarButton == btn then
			ApplyToggleArrow(btn, c)
		end
	end)
end

local function SkinSideBar(sideBar, Module)
	if not sideBar or sideBar.tuiSkinned then return end
	sideBar.tuiSkinned = true

	if sideBar.Background then sideBar.Background:SetAlpha(0) end
	sideBar:SetTemplate('Transparent')

	SkinButton(sideBar.CreateButton)
	SkinButton(sideBar.ImportButton)
	SkinButton(sideBar.SaveButton)
	SkinButton(sideBar.ConfigButton)
	SkinToggleButton(sideBar.ToggleSideBarButton, Module)

	local sb = sideBar.ScrollBoxContainer
	if sb then
		if sb.ScrollBar and S.HandleTrimScrollBar then
			S:HandleTrimScrollBar(sb.ScrollBar)
		end
		if sb.ScrollBox and S.HandleScrollBar then
			S:HandleScrollBar(sb.ScrollBox)
		end
	end
end

local function SkinImportDialog(dialog)
	if not dialog or dialog.tuiSkinned then return end
	dialog.tuiSkinned = true

	dialog:StripTextures()
	dialog:SetTemplate('Transparent')

	SkinButton(dialog.AcceptButton)
	SkinButton(dialog.CancelButton)

	local imp = dialog.ImportControl
	if imp then
		if imp.InputContainer and S.HandleScrollFrame then
			S:HandleScrollFrame(imp.InputContainer)
		end
		for _, child in ipairs({ imp:GetChildren() }) do
			if child:IsObjectType('Button') then SkinButton(child) end
		end
	end

	local nameCtrl = dialog.NameControl
	if nameCtrl and nameCtrl.EditBox and S.HandleEditBox then
		S:HandleEditBox(nameCtrl.EditBox)
	end

	for _, child in ipairs({ dialog:GetChildren() }) do
		if child:IsObjectType('CheckButton') and S.HandleCheckBox then
			S:HandleCheckBox(child)
		end
	end
end

local function SkinModule(Module)
	if not Module or Module.tuiSkinHooked then return end
	Module.tuiSkinHooked = true

	if Module.SideBar then SkinSideBar(Module.SideBar, Module) end
	if Module.importDialog then SkinImportDialog(Module.importDialog) end

	hooksecurefunc(Module, 'SetupHook', function(self)
		if self.SideBar then SkinSideBar(self.SideBar, self) end
		if self.importDialog then SkinImportDialog(self.importDialog) end
	end)
end

local function ApplySkin()
	local LibAce = LibStub and LibStub('AceAddon-3.0', true)
	local addon = LibAce and LibAce:GetAddon('TalentLoadoutManager', true)
	if not addon then return end

	if addon.SideBarModule then SkinModule(addon.SideBarModule) end
	if addon.GetModule then
		local sb = addon:GetModule('SideBar', true)
		if sb then SkinModule(sb) end
	end
end

function SKN:InitSkinTalentLoadoutManager()
	if not E:IsAddOnEnabled('TalentLoadoutManager') then return end
	if not TUI.db or not TUI.db.profile.addons or not TUI.db.profile.addons.skinTalentLoadoutManager then return end

	ApplySkin()

	local f = CreateFrame('Frame')
	f:RegisterEvent('ADDON_LOADED')
	f:RegisterEvent('PLAYER_LOGIN')
	f:SetScript('OnEvent', function(_, event, name)
		if event == 'ADDON_LOADED' then
			if name == 'TalentLoadoutManager' or name == 'Blizzard_PlayerSpells' or name == 'Blizzard_ClassTalentUI' then
				C_Timer.After(0, ApplySkin)
			end
		else
			C_Timer.After(0, ApplySkin)
		end
	end)
end
