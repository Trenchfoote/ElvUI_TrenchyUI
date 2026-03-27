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
		if settings.BorderFrame then
			settings.BorderFrame:StripTextures()
			settings.BorderFrame:SetTemplate('Transparent')
		end
		for _, region in pairs({ settings:GetRegions() }) do
			if region:IsObjectType('Texture') then region:SetAlpha(0) end
		end
		if settings.ScrollBar then S:HandleTrimScrollBar(settings.ScrollBar) end
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
