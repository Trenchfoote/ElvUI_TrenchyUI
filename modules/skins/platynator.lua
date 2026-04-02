-- Platynator config dialog skin
local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local S = E:GetModule('Skins')

local pairs, ipairs = pairs, ipairs
local skinnedFrames = {}

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

local mainDialog

local function ReskinDialog()
	if mainDialog and mainDialog:IsShown() then SkinChildren(mainDialog) end
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

function TUI:InitSkinPlatynator()
	if not E:IsAddOnEnabled('Platynator') then return end
	if not self.db or not self.db.profile.addons or not self.db.profile.addons.skinPlatynator then return end

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
