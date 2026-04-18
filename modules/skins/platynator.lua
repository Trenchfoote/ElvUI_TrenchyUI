-- Platynator config dialog skin
local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local SKN = E:GetModule('TUI_Skins')
local S = E:GetModule('Skins')

local pairs, ipairs = pairs, ipairs
local skinnedFrames = {}
local mainDialog

-- Designer preview skin: lighter background + pixel grid overlay
local GRID_SPACING = 12
local GRID_ALPHA = 0.08
local BG_COLOR = { 0.18, 0.18, 0.20, 0.95 }

local function LightenAndGridify(frame)
	if frame.tuiGridified then return end
	frame.tuiGridified = true

	if frame.Bg then
		frame.Bg:SetColorTexture(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3], BG_COLOR[4])
	end

	local w, h = frame:GetSize()
	if not w or w < 50 or h < 50 then
		C_Timer.After(0.1, function() frame.tuiGridified = nil; LightenAndGridify(frame) end)
		return
	end

	for x = GRID_SPACING, w - GRID_SPACING, GRID_SPACING do
		local line = frame:CreateTexture(nil, 'BORDER')
		line:SetColorTexture(1, 1, 1, GRID_ALPHA)
		line:SetSize(1, h - 4)
		line:SetPoint('TOP', frame, 'TOPLEFT', x, -2)
	end
	for y = GRID_SPACING, h - GRID_SPACING, GRID_SPACING do
		local line = frame:CreateTexture(nil, 'BORDER')
		line:SetColorTexture(1, 1, 1, GRID_ALPHA)
		line:SetSize(w - 4, 1)
		line:SetPoint('LEFT', frame, 'TOPLEFT', 2, -y)
	end
end

-- Find the largest InsetFrameTemplate child (the designer preview area)
local function FindPreviewInset(parent, depth)
	depth = (depth or 0) + 1
	if depth > 8 then return nil, 0 end

	local best, bestArea = nil, 0
	for _, child in ipairs({ parent:GetChildren() }) do
		if child.Bg and child.NineSlice and child ~= parent then
			local w, h = child:GetSize()
			local area = (w or 0) * (h or 0)
			if area > bestArea and (w or 0) >= 200 and (h or 0) >= 150 then
				bestArea = area
				best = child
			end
		end
		if child.GetChildren then
			local subBest, subArea = FindPreviewInset(child, depth)
			if subBest and subArea > bestArea then
				bestArea = subArea
				best = subBest
			end
		end
	end
	return best, bestArea
end

local function SkinDesignerPreview()
	if not mainDialog then return end
	-- Search only inside shown tab containers, skipping the dialog's own Inset
	for _, child in ipairs({ mainDialog:GetChildren() }) do
		if child ~= mainDialog.Inset and child:IsShown() and child.GetChildren then
			local previewInset = FindPreviewInset(child)
			if previewInset then
				LightenAndGridify(previewInset)
				return
			end
		end
	end
end

local function SkinChildren(parent, depth)
	depth = (depth or 0) + 1
	if depth > 10 then return end

	for _, child in pairs({ parent:GetChildren() }) do
		if not child.isSkinned then
			local objType = child:GetObjectType()

			if objType == 'Button' or objType == 'DropdownButton' then
				if child.SetupMenu then
					S:HandleDropDownBox(child)
				elseif child.Left and child.Middle and child.Right then
					S:HandleTab(child)
				elseif child.GetText and child:GetText() and child:GetText() ~= '' and child:GetWidth() > 40 then
					S:HandleButton(child)
				end
			elseif objType == 'CheckButton' then
				S:HandleCheckBox(child)
			elseif objType == 'Slider' then
				S:HandleSliderFrame(child)
			elseif objType == 'EditBox' then
				S:HandleEditBox(child)
			end
		end

		-- Recurse into containers
		if child.GetChildren then
			SkinChildren(child, depth)
		end
	end
end

local function ReskinDialog()
	if mainDialog and mainDialog:IsShown() then
		SkinChildren(mainDialog)
		SkinDesignerPreview()
	end
end

local function SkinDialog(frame)
	if not frame or skinnedFrames[frame] then return end
	skinnedFrames[frame] = true
	mainDialog = frame

	-- Main frame: ButtonFrameTemplate
	S:HandleFrame(frame)

	-- Tabs (stored in frame.Tabs array)
	if frame.Tabs then
		for _, tab in ipairs(frame.Tabs) do
			S:HandleTab(tab)
		end
	end

	-- Deep scan all children
	SkinChildren(frame)

	-- Re-skin when tabs are clicked (catches dynamically created widgets)
	hooksecurefunc('PanelTemplates_SelectTab', function()
		C_Timer.After(0, ReskinDialog)
	end)
end

local function SkinImportDialog()
	local dialog = _G.PlatynatorCustomiseDialogImportDialog
	if not dialog or skinnedFrames[dialog] then return end
	skinnedFrames[dialog] = true

	dialog:StripTextures()
	dialog:SetTemplate('Transparent')

	for _, child in pairs({ dialog:GetChildren() }) do
		local objType = child:GetObjectType()
		if objType == 'Button' then
			S:HandleButton(child)
		elseif objType == 'EditBox' then
			S:HandleEditBox(child)
		end
	end
end

function SKN:InitSkinPlatynator()
	if not E:IsAddOnEnabled('Platynator') then return end
	if not TUI.db or not TUI.db.profile.addons or not TUI.db.profile.addons.skinPlatynator then return end

	-- Hook frame creation to catch the dialog when it's first opened
	hooksecurefunc('CreateFrame', function(_, name)
		if type(name) ~= 'string' then return end
		if name:find('^PlatynatorCustomiseDialog') and name ~= 'PlatynatorCustomiseDialogImportDialog' then
			C_Timer.After(0, function()
				local frame = _G[name]
				if frame then SkinDialog(frame) end
			end)
		elseif name == 'PlatynatorCustomiseDialogImportDialog' then
			C_Timer.After(0, SkinImportDialog)
		end
	end)

	-- Skin if already created
	for name, frame in pairs(_G) do
		if type(name) == 'string' and name:find('^PlatynatorCustomiseDialog') and type(frame) == 'table' and frame.GetObjectType then
			if name == 'PlatynatorCustomiseDialogImportDialog' then
				SkinImportDialog()
			else
				SkinDialog(frame)
			end
		end
	end
end
