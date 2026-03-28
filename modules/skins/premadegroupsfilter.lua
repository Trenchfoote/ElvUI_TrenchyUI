local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local S = E:GetModule('Skins')

local hooksecurefunc = hooksecurefunc
local pairs = pairs

local skinned = false

-- Recursively walk a frame tree and skin all known widget types
local function SkinDescendants(frame, depth)
	if not frame or depth > 10 then return end
	for _, child in pairs({ frame:GetChildren() }) do
		if child.IsObjectType and not child.TUI_Skinned then
			-- CheckButtons (UICheckButtonTemplate)
			if child:IsObjectType('CheckButton') then
				child.TUI_Skinned = true
				S:HandleCheckBox(child)
				child:SetSize(22, 22)
				-- Reposition Act checkboxes to vertically center with their row
				local parent = child:GetParent()
				if parent and parent.Title then
					child:ClearAllPoints()
					child:SetPoint('LEFT', parent, 'LEFT', 2, 0)
				end
			-- EditBoxes (InputBoxTemplate for min/max fields)
			elseif child:IsObjectType('EditBox') then
				child.TUI_Skinned = true
				S:HandleEditBox(child)
			-- ScrollFrames (InputScrollFrameTemplate for expression fields)
			elseif child:IsObjectType('ScrollFrame') then
				child.TUI_Skinned = true
				child:StripTextures()
				if child.NineSlice then child.NineSlice:SetAlpha(0) end
				child:CreateBackdrop('Transparent')
				if child.EditBox then child.EditBox:SetTextColor(1, 1, 1) end
			end
			-- Recurse into children
			SkinDescendants(child, depth + 1)
		end
	end
end

-- Skin the custom dropdown template (strips CharacterCreate-LabelFrame textures)
local function SkinDropdowns(frame)
	if not frame then return end
	for _, child in pairs({ frame:GetChildren() }) do
		local dd = child.DropDown
		if dd and not dd.TUI_Skinned then
			dd.TUI_Skinned = true
			if dd.Left then dd.Left:SetAlpha(0) end
			if dd.Middle then dd.Middle:SetAlpha(0) end
			if dd.Right then dd.Right:SetAlpha(0) end
			dd:CreateBackdrop()
			dd.backdrop:Point('TOPLEFT', 18, -5)
			dd.backdrop:Point('BOTTOMRIGHT', -14, 7)
			if dd.Text then
				dd.Text:ClearAllPoints()
				dd.Text:SetPoint('LEFT', dd.backdrop, 'LEFT', 4, 0)
				dd.Text:SetPoint('RIGHT', dd.backdrop, 'RIGHT', -18, 0)
			end
			-- Clip parent Title so dots don't overlap the dropdown
			if child.Title then
				child.Title:SetPoint('RIGHT', dd.backdrop, 'LEFT', -2, 0)
				child.Title:SetWordWrap(false)
			end
			if dd.Button then
				dd.Button:ClearAllPoints()
				dd.Button:SetPoint('RIGHT', dd.backdrop, 'RIGHT', -2, 0)
				dd.Button:SetSize(16, 16)
				S:HandleNextPrevButton(dd.Button, 'down')
			end
		end
		-- Recurse for nested panels
		SkinDropdowns(child)
	end
end

-- Skin PGF's SelectAll/None/Invert/Bountiful text buttons
local function SkinTextButtons(frame)
	if not frame then return end
	local r, g, b = unpack(E.media.rgbvaluecolor)
	for _, child in pairs({ frame:GetChildren() }) do
		if child.Bg and child.Label and not child.TUI_Skinned then
			child.TUI_Skinned = true
			child.Bg:SetAlpha(0)
			child:CreateBackdrop()
			child.backdrop:SetInside(child, 1, 1)
			local ht = child:GetHighlightTexture()
			if ht then
				ht:SetColorTexture(r, g, b, 0.25)
				ht:SetAllPoints(child.backdrop)
			end
		end
	end
end

-- Recursively find and skin popup menu frames (have .Buttons table)
local function SkinPopupMenus(parent)
	if not parent then return end
	local r, g, b = unpack(E.media.rgbvaluecolor)
	for _, f in pairs({ parent:GetChildren() }) do
		if f.Buttons and f:IsShown() then
			if not f.TUI_Hooked then
				f.TUI_Hooked = true
				local function ApplyPopupSkin(self)
					for _, region in pairs({ self:GetRegions() }) do
						if region:IsObjectType('Texture') then region:SetAlpha(0) end
					end
					if self.NineSlice then self.NineSlice:Hide() end
					if not self.backdrop then
						Mixin(self, BackdropTemplateMixin)
						self:SetTemplate('Transparent')
					end
				end
				ApplyPopupSkin(f)
				f:HookScript('OnShow', ApplyPopupSkin)
			end
			for _, btn in pairs(f.Buttons) do
				if type(btn) == 'table' and btn.IsObjectType and not btn.TUI_Skinned then
					btn.TUI_Skinned = true
					if btn.NormalTexture then btn.NormalTexture:SetAlpha(0) end
					if btn.HighlightTexture then
						btn.HighlightTexture:SetColorTexture(r, g, b, 0.25)
					end
				end
			end
		end
		-- Recurse into children to find deeply nested popups
		SkinPopupMenus(f)
	end
end

local function SkinPGF()
	if skinned then return end
	local dialog = _G.PremadeGroupsFilterDialog
	if not dialog then return end
	skinned = true

	-- Main dialog frame
	S:HandlePortraitFrame(dialog)

	-- Maximize/Minimize
	if dialog.MaximizeMinimizeFrame then S:HandleMaxMinFrame(dialog.MaximizeMinimizeFrame) end

	-- Buttons
	if dialog.ResetButton then S:HandleButton(dialog.ResetButton) end
	if dialog.SettingsButton then S:HandleButton(dialog.SettingsButton) end
	if dialog.RefreshButton then S:HandleButton(dialog.RefreshButton) end

	-- UsePGF checkbox on the LFG search panel
	local usePGF = _G.UsePGFButton
	if usePGF and not usePGF.TUI_Skinned then
		usePGF.TUI_Skinned = true
		S:HandleCheckBox(usePGF)
		usePGF:SetSize(22, 22)
	end

	-- Skin all panel contents recursively
	local panels = {
		_G.PremadeGroupsFilterDungeonPanel,
		_G.PremadeGroupsFilterRaidPanel,
		_G.PremadeGroupsFilterDelvePanel,
		_G.PremadeGroupsFilterArenaPanel,
		_G.PremadeGroupsFilterRBGPanel,
		_G.PremadeGroupsFilterRolePanel,
		_G.PremadeGroupsFilterMiniPanel,
	}
	for _, panel in pairs(panels) do
		if panel then
			SkinDescendants(panel, 0)
			SkinDropdowns(panel)
			-- Text buttons in dungeon/delve selection lists
			if panel.Dungeons then SkinTextButtons(panel.Dungeons) end
			if panel.Delves then SkinTextButtons(panel.Delves) end
		end
	end

	-- Hook dropdown buttons to skin popup menus when they appear
	for _, panel in pairs(panels) do
		if panel then
			for _, child in pairs({ panel:GetChildren() }) do
				for _, grandchild in pairs({ child:GetChildren() }) do
					if grandchild.DropDown and grandchild.DropDown.Button then
						grandchild.DropDown.Button:HookScript('OnClick', function()
							C_Timer.After(0, function()
								SkinPopupMenus(_G.PremadeGroupsFilterDialog)
							end)
						end)
					end
				end
			end
		end
	end

	-- Settings panel
	local settings = dialog.SettingsFrame
	if settings then
		if settings.ScrollBar then S:HandleTrimScrollBar(settings.ScrollBar) end
		local scrollBox = settings.ScrollBox
		if scrollBox then
			hooksecurefunc(scrollBox, 'Update', function(self)
				for _, child in self:EnumerateFrames() do
					if not child.TUI_Skinned then
						child.TUI_Skinned = true
						if child.CheckBox then
							S:HandleCheckBox(child.CheckBox)
							child.CheckBox:SetSize(22, 22)
						end
					end
				end
			end)
		end
	end
end

function TUI:InitSkinPremadeGroupsFilter()
	if not E:IsAddOnEnabled('PremadeGroupsFilter') then return end
	if not self.db or not self.db.profile.addons or not self.db.profile.addons.skinPremadeGroupsFilter then return end

	local dialog = _G.PremadeGroupsFilterDialog
	if dialog then
		dialog:HookScript('OnShow', SkinPGF)
		if dialog:IsShown() then SkinPGF() end
	else
		hooksecurefunc('LFGListFrame_SetActivePanel', function()
			if not skinned and _G.PremadeGroupsFilterDialog then
				_G.PremadeGroupsFilterDialog:HookScript('OnShow', SkinPGF)
				if _G.PremadeGroupsFilterDialog:IsShown() then SkinPGF() end
			end
		end)
	end
end
