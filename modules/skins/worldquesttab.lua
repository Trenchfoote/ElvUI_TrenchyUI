local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local S = E:GetModule('Skins')

local hooksecurefunc = hooksecurefunc
local pairs = pairs

local skinned = false

local function SkinQuestButton(button)
	if button.TUI_Skinned then return end
	button.TUI_Skinned = true

	if button.Separator then button.Separator:SetAlpha(0) end

	local highlight = button.Highlight
	if highlight then
		for _, region in pairs({ highlight:GetRegions() }) do
			if region:IsObjectType('Texture') then
				region:SetTexture(E.media.normTex)
				region:SetVertexColor(1, 1, 1, 0.15)
			end
		end
	end

	local tracked = button.TrackedBorder
	if tracked then
		for _, region in pairs({ tracked:GetRegions() }) do
			if region:IsObjectType('Texture') then
				region:SetTexture(E.media.normTex)
				region:SetVertexColor(1, 0.82, 0, 0.3)
			end
		end
	end
end

local function SkinSideTab(tab)
	if not tab then return end
	if tab.Background then tab.Background:SetAlpha(0) end
	if tab.SelectedTexture then
		tab.SelectedTexture:SetDrawLayer('ARTWORK')
		tab.SelectedTexture:SetColorTexture(1, 0.82, 0, 0.3)
		tab.SelectedTexture:SetAllPoints()
	end
	for _, region in pairs({ tab:GetRegions() }) do
		if region:IsObjectType('Texture') and region ~= tab.Icon
			and region ~= tab.SelectedTexture then
			local atlas = region.GetAtlas and region:GetAtlas()
			if atlas and atlas:find('Glow%-hover') then
				region:SetColorTexture(1, 1, 1, 0.3)
				region:SetAllPoints()
			elseif region ~= tab.SelectedTexture then
				region:SetAlpha(0)
			end
		end
	end
	tab:CreateBackdrop()
	tab:Size(30, 40)
	if tab.Icon then
		tab.Icon:ClearAllPoints()
		tab.Icon:SetPoint('CENTER')
		hooksecurefunc(tab.Icon, 'SetPoint', function(icon, _, anchor)
			if anchor then icon:SetPoint('CENTER') end
		end)
	end
end

local function SkinWorldQuestTab()
	if skinned then return end
	local frame = _G.WQT_WorldQuestFrame
	if not frame then return end
	skinned = true

	-- Side tab
	SkinSideTab(_G.WQT_QuestMapTab)

	-- Main list container
	local list = frame.ScrollFrame
	if list then
		if list.BorderFrame then list.BorderFrame:StripTextures() end
		if list.Background then list.Background:Hide() end
		list:StripTextures()
		list:SetTemplate('Transparent')

		-- Filter bar: strip the blue highlight texture, keep text + clear button
		local filterBar = list.BorderContainer and list.BorderContainer.FilterBar
		if filterBar then filterBar:StripTextures() end

		-- Scroll bar
		if list.ScrollBar then S:HandleTrimScrollBar(list.ScrollBar) end

		-- Top bar elements
		local topBar = list.TopBar
		if topBar then
			if topBar.SortDropdown then S:HandleDropDownBox(topBar.SortDropdown) end
			if topBar.FilterDropdown then S:HandleDropDownBox(topBar.FilterDropdown) end
			if topBar.SearchBox then S:HandleEditBox(topBar.SearchBox) end
		end

		-- Hook quest button creation
		local scrollBox = list.BorderContainer and list.BorderContainer.QuestScrollBox
		if scrollBox then
			hooksecurefunc(scrollBox, 'Update', function(self)
				for _, child in self:EnumerateFrames() do
					SkinQuestButton(child)
				end
			end)
			for _, child in scrollBox:EnumerateFrames() do
				SkinQuestButton(child)
			end
		end
	end

	-- Settings frame
	local settings = frame.SettingsFrame
	if settings then
		if settings.BorderFrame then settings.BorderFrame:StripTextures() end
		settings:StripTextures()
		settings:SetTemplate('Transparent')
		if settings.ScrollBar then S:HandleTrimScrollBar(settings.ScrollBar) end

		local function SkinSettingsElement(child)
			if child.TUI_Skinned then return end
			child.TUI_Skinned = true
			if child.CheckBox then S:HandleCheckBox(child.CheckBox) end
			if child.SliderWithSteppers then
				local slider = child.SliderWithSteppers.Slider
				if slider then S:HandleSliderFrame(slider) end
			end
			if child.TextBox then S:HandleEditBox(child.TextBox) end
			if child.Dropdown then S:HandleDropDownBox(child.Dropdown) end
			-- Strip category/subcategory chrome
			if child.BGLeft then child.BGLeft:SetAlpha(0) end
			if child.BGRight then child.BGRight:SetAlpha(0) end
			if child.BGMiddle then child.BGMiddle:SetAlpha(0) end
			if child.Background then child.Background:SetAlpha(0) end
			-- Add ElvUI backdrop + highlight to expandable headers
			local isHeader = child.BGLeft or (child.Background and child.ExpandIcon)
			if isHeader and not child.backdrop then
				child:CreateBackdrop('Transparent')
				local r, g, b = unpack(E.media.rgbvaluecolor)
				-- Replace all highlight textures with flat color
				if child.Highlight then child.Highlight:SetAlpha(0) end
				if child.Mask then child.Mask:Hide() end
				for _, region in pairs({ child:GetRegions() }) do
					if region:IsObjectType('Texture') and region:GetDrawLayer() == 'HIGHLIGHT' then
						region:SetAlpha(0)
					end
				end
				local hl = child:CreateTexture(nil, 'HIGHLIGHT')
				hl:SetColorTexture(r, g, b, 0.25)
				hl:SetAllPoints(child.backdrop)
			end
		end

		local scrollBox = settings.ScrollBox
		if scrollBox then
			hooksecurefunc(scrollBox, 'Update', function(self)
				for _, child in self:EnumerateFrames() do
					SkinSettingsElement(child)
				end
			end)
			for _, child in scrollBox:EnumerateFrames() do
				SkinSettingsElement(child)
			end
		end
	end
end

function TUI:InitSkinWorldQuestTab()
	if not E:IsAddOnEnabled('WorldQuestTab') then return end
	if not self.db or not self.db.profile.addons or not self.db.profile.addons.skinWorldQuestTab then return end

	if _G.WQT_WorldQuestFrame then
		SkinWorldQuestTab()
	else
		hooksecurefunc('LoadAddOn', function(name)
			if name == 'WorldQuestTab' then SkinWorldQuestTab() end
		end)
	end
end
