local E = unpack(ElvUI)
local CDM = E:GetModule('TUI_CDM')

local function AnchorOptionPanel(panel, spellID, hookKey)
	local spellInfo = C_Spell.GetSpellInfo(spellID)
	local name = spellInfo and spellInfo.name or ('Spell ' .. spellID)
	panel:SetTitle('|cffff2f3dTrenchyUI|r ' .. name)

	panel.frame:ClearAllPoints()
	local tsf = _G.CooldownViewerSettings
	if tsf and tsf:IsShown() then
		panel.frame:SetPoint('TOPLEFT', tsf, 'TOPRIGHT', 50, 0)
	else
		panel.frame:SetPoint('CENTER', E.UIParent, 'CENTER', 0, 100)
	end

	if tsf and not tsf[hookKey] then
		tsf:HookScript('OnHide', function() if panel then panel:Hide() end end)
		tsf[hookKey] = true
	end

	local editAlert = _G.CooldownViewerSettingsEditAlert
	if editAlert then
		if not editAlert[hookKey] then
			editAlert:HookScript('OnShow', function() if panel then panel:Hide() end end)
			editAlert[hookKey] = true
		end
		if editAlert:IsShown() then editAlert:Hide() end
	end
end

-- Glow Options Panel
do
	local AceGUI = LibStub('AceGUI-3.0')
	local glowPanel, currentSpellID
	local widgets = {}
	local GLOW_TYPES = { pixel = 'Pixel', autocast = 'Autocast', button = 'Button', proc = 'Proc' }
	local GLOW_TYPE_ORDER = { 'pixel', 'autocast', 'button', 'proc' }

	local function RefreshBuffIconGlow()
		local viewer = _G['BuffIconCooldownViewer']
		if not viewer or not viewer.itemFramePool then return end
		for frame in viewer.itemFramePool:EnumerateActive() do
			if frame and frame:IsShown() and frame.GetBaseSpellID then
				local sid = frame:GetBaseSpellID()
				local sgdb = sid and CDM.GetSpellGlowDB(sid)
				if sgdb and sgdb.enabled then
					CDM.ApplyGlow(frame, sgdb, true)
				else
					CDM.StopGlow(frame)
				end
			end
		end
	end

	local function UpdateVisibleSliders()
		if not glowPanel or not currentSpellID then return end
		local sgdb = CDM.GetOrCreateSpellGlowDB(currentSpellID)
		if not sgdb then return end
		local isPixel = sgdb.type == 'pixel'
		local isAutocast = sgdb.type == 'autocast'
		widgets.lines.frame:SetShown(isPixel)
		widgets.thickness.frame:SetShown(isPixel)
		widgets.particles.frame:SetShown(isAutocast)
		widgets.scale.frame:SetShown(isAutocast)
		glowPanel:DoLayout()
	end

	local function UpdatePanelWidgets()
		if not glowPanel or not currentSpellID then return end
		local sgdb = CDM.GetOrCreateSpellGlowDB(currentSpellID)
		if not sgdb then return end
		widgets.enable:SetValue(sgdb.enabled)
		widgets.glowType:SetValue(sgdb.type)
		widgets.color:SetColor(sgdb.color.r, sgdb.color.g, sgdb.color.b, sgdb.color.a or 1)
		widgets.speed:SetValue(sgdb.speed)
		widgets.lines:SetValue(sgdb.lines)
		widgets.thickness:SetValue(sgdb.thickness)
		widgets.particles:SetValue(sgdb.particles)
		widgets.scale:SetValue(sgdb.scale)
		UpdateVisibleSliders()
	end

	local function CreateGlowPanel()
		local window = AceGUI:Create('Window')
		window:SetTitle('|cffff2f3dTrenchyUI|r Glow Options')
		window:SetWidth(300)
		window:SetHeight(340)
		window:SetLayout('Flow')
		window:EnableResize(false)
		window.frame:SetFrameStrata('DIALOG')

		local enable = AceGUI:Create('CheckBox')
		enable:SetLabel('Enable Glow')
		enable:SetFullWidth(true)
		enable:SetCallback('OnValueChanged', function(_, _, val)
			local sgdb = CDM.GetOrCreateSpellGlowDB(currentSpellID)
			if sgdb then sgdb.enabled = val; RefreshBuffIconGlow() end
		end)
		window:AddChild(enable)
		widgets.enable = enable

		local glowType = AceGUI:Create('Dropdown')
		glowType:SetLabel('Type')
		glowType:SetList(GLOW_TYPES, GLOW_TYPE_ORDER)
		glowType:SetRelativeWidth(0.5)
		glowType:SetCallback('OnValueChanged', function(_, _, val)
			local sgdb = CDM.GetOrCreateSpellGlowDB(currentSpellID)
			if sgdb then sgdb.type = val; UpdateVisibleSliders(); RefreshBuffIconGlow() end
		end)
		window:AddChild(glowType)
		widgets.glowType = glowType

		local color = AceGUI:Create('ColorPicker')
		color:SetLabel('Color')
		color:SetRelativeWidth(0.5)
		color:SetHasAlpha(true)

		local function colorChanged(_, _, r, g, b, a)
			local sgdb = CDM.GetOrCreateSpellGlowDB(currentSpellID)
			if sgdb then sgdb.color.r, sgdb.color.g, sgdb.color.b, sgdb.color.a = r, g, b, a; RefreshBuffIconGlow() end
		end
		color:SetCallback('OnValueChanged', colorChanged)
		color:SetCallback('OnValueConfirmed', colorChanged)

		window:AddChild(color)
		widgets.color = color

		local speed = AceGUI:Create('Slider')
		speed:SetLabel('Speed')
		speed:SetSliderValues(0.05, 2, 0.05)
		speed:SetFullWidth(true)
		speed:SetCallback('OnValueChanged', function(_, _, val)
			local sgdb = CDM.GetOrCreateSpellGlowDB(currentSpellID)
			if sgdb then sgdb.speed = val; RefreshBuffIconGlow() end
		end)
		window:AddChild(speed)
		widgets.speed = speed

		local lines = AceGUI:Create('Slider')
		lines:SetLabel('Lines')
		lines:SetSliderValues(1, 20, 1)
		lines:SetFullWidth(true)
		lines:SetCallback('OnValueChanged', function(_, _, val)
			local sgdb = CDM.GetOrCreateSpellGlowDB(currentSpellID)
			if sgdb then sgdb.lines = val; RefreshBuffIconGlow() end
		end)
		window:AddChild(lines)
		widgets.lines = lines

		local thickness = AceGUI:Create('Slider')
		thickness:SetLabel('Thickness')
		thickness:SetSliderValues(1, 8, 1)
		thickness:SetFullWidth(true)
		thickness:SetCallback('OnValueChanged', function(_, _, val)
			local sgdb = CDM.GetOrCreateSpellGlowDB(currentSpellID)
			if sgdb then sgdb.thickness = val; RefreshBuffIconGlow() end
		end)
		window:AddChild(thickness)
		widgets.thickness = thickness

		local particles = AceGUI:Create('Slider')
		particles:SetLabel('Particles')
		particles:SetSliderValues(1, 16, 1)
		particles:SetFullWidth(true)
		particles:SetCallback('OnValueChanged', function(_, _, val)
			local sgdb = CDM.GetOrCreateSpellGlowDB(currentSpellID)
			if sgdb then sgdb.particles = val; RefreshBuffIconGlow() end
		end)
		window:AddChild(particles)
		widgets.particles = particles

		local scale = AceGUI:Create('Slider')
		scale:SetLabel('Scale')
		scale:SetSliderValues(0.5, 3, 0.1)
		scale:SetFullWidth(true)
		scale:SetCallback('OnValueChanged', function(_, _, val)
			local sgdb = CDM.GetOrCreateSpellGlowDB(currentSpellID)
			if sgdb then sgdb.scale = val; RefreshBuffIconGlow() end
		end)
		window:AddChild(scale)
		widgets.scale = scale

		window:Hide()
		glowPanel = window
	end

	function CDM:HideGlowPanel()
		if glowPanel then glowPanel:Hide() end
	end

	function CDM:ShowGlowPanel(spellID)
		if not glowPanel then CreateGlowPanel() end
		currentSpellID = spellID
		CDM:HideBarColorPanel()
		CDM:HideActiveStatePanel()
		AnchorOptionPanel(glowPanel, spellID, 'tuiGlowHooked')
		UpdatePanelWidgets()
		glowPanel:Show()
	end
end

-- Bar Color Options Panel
do
	local AceGUI = LibStub('AceGUI-3.0')
	local barColorPanel, barColorSpellID
	local bcWidgets = {}

	local function RefreshBuffBarColors()
		local viewer = _G['BuffBarCooldownViewer']
		if not viewer or not viewer.itemFramePool then return end
		local vdb = CDM.GetViewerDB('buffBar')
		if not vdb then return end
		for frame in viewer.itemFramePool:EnumerateActive() do
			if frame and frame:IsShown() then
				CDM.ApplyBarStyle(frame, vdb)
			end
		end
	end

	local function UpdateBarColorWidgets()
		if not barColorPanel or not barColorSpellID then return end
		local sbc = CDM.GetOrCreateSpellBarColorDB(barColorSpellID)
		if not sbc then return end
		bcWidgets.enable:SetValue(sbc.enabled)
		bcWidgets.fgColor:SetColor(sbc.fgColor.r, sbc.fgColor.g, sbc.fgColor.b, 1)
		bcWidgets.bgColor:SetColor(sbc.bgColor.r, sbc.bgColor.g, sbc.bgColor.b, sbc.bgColor.a or 0.5)
	end

	local function CreateBarColorPanel()
		local window = AceGUI:Create('Window')
		window:SetTitle('|cffff2f3dTrenchyUI|r Bar Colors')
		window:SetWidth(280)
		window:SetHeight(180)
		window:SetLayout('Flow')
		window:EnableResize(false)
		window.frame:SetFrameStrata('DIALOG')

		local enable = AceGUI:Create('CheckBox')
		enable:SetLabel('Enable Custom Colors')
		enable:SetFullWidth(true)
		enable:SetCallback('OnValueChanged', function(_, _, val)
			local sbc = CDM.GetOrCreateSpellBarColorDB(barColorSpellID)
			if sbc then sbc.enabled = val; RefreshBuffBarColors() end
		end)
		window:AddChild(enable)
		bcWidgets.enable = enable

		local fgColor = AceGUI:Create('ColorPicker')
		fgColor:SetLabel('Foreground')
		fgColor:SetRelativeWidth(0.5)
		fgColor:SetHasAlpha(false)
		local function fgChanged(_, _, r, g, b)
			local sbc = CDM.GetOrCreateSpellBarColorDB(barColorSpellID)
			if sbc then sbc.fgColor.r, sbc.fgColor.g, sbc.fgColor.b = r, g, b; RefreshBuffBarColors() end
		end
		fgColor:SetCallback('OnValueChanged', fgChanged)
		fgColor:SetCallback('OnValueConfirmed', fgChanged)
		window:AddChild(fgColor)
		bcWidgets.fgColor = fgColor

		local bgColor = AceGUI:Create('ColorPicker')
		bgColor:SetLabel('Background')
		bgColor:SetRelativeWidth(0.5)
		bgColor:SetHasAlpha(true)
		local function bgChanged(_, _, r, g, b, a)
			local sbc = CDM.GetOrCreateSpellBarColorDB(barColorSpellID)
			if sbc then sbc.bgColor.r, sbc.bgColor.g, sbc.bgColor.b, sbc.bgColor.a = r, g, b, a; RefreshBuffBarColors() end
		end
		bgColor:SetCallback('OnValueChanged', bgChanged)
		bgColor:SetCallback('OnValueConfirmed', bgChanged)
		window:AddChild(bgColor)
		bcWidgets.bgColor = bgColor

		window:Hide()
		barColorPanel = window
	end

	function CDM:HideBarColorPanel()
		if barColorPanel then barColorPanel:Hide() end
	end

	function CDM:ShowBarColorPanel(spellID)
		if not barColorPanel then CreateBarColorPanel() end
		barColorSpellID = spellID
		CDM:HideGlowPanel()
		CDM:HideActiveStatePanel()
		AnchorOptionPanel(barColorPanel, spellID, 'tuiBarColorHooked')
		UpdateBarColorWidgets()
		barColorPanel:Show()
	end
end

-- Active State Options Panel
do
	local AceGUI = LibStub('AceGUI-3.0')
	local activeStatePanel, activeStateSpellID
	local asWidgets = {}

	local function RefreshActiveState()
		for _, vKey in ipairs({ 'essential', 'utility' }) do
			local viewer = CDM.GetViewer(vKey)
			if viewer and viewer.itemFramePool then
				for frame in viewer.itemFramePool:EnumerateActive() do
					if frame and frame:IsShown() and frame.GetBaseSpellID then
						CDM.ApplyActiveState(frame, frame:GetBaseSpellID())
					end
				end
			end
		end
	end

	local MODE_LIST = { default = 'Default', hide = 'Hide', custom = 'Customize' }
	local MODE_ORDER = { 'default', 'hide', 'custom' }
	local SWIPE_LIST = { aura = 'Keep (Blizzard)', color = 'Solid Color', class = 'Class Color' }
	local SWIPE_ORDER = { 'aura', 'color', 'class' }

	local function UpdateControlStates()
		if not activeStatePanel or not activeStateSpellID then return end
		local sas = CDM.GetOrCreateSpellActiveStateDB(activeStateSpellID)
		if not sas then return end
		local custom = sas.mode == 'custom'
		asWidgets.swipe:SetDisabled(not custom)
		asWidgets.swipeColor:SetDisabled(not custom or sas.swipe ~= 'color')
		asWidgets.textColor:SetDisabled(not custom)
		asWidgets.textClass:SetDisabled(not custom)
		asWidgets.desaturate:SetDisabled(not custom)
	end

	local function UpdateActiveStateWidgets()
		if not activeStatePanel or not activeStateSpellID then return end
		local sas = CDM.GetOrCreateSpellActiveStateDB(activeStateSpellID)
		if not sas then return end
		asWidgets.mode:SetValue(sas.mode)
		asWidgets.swipe:SetValue(sas.swipe)
		asWidgets.swipeColor:SetColor(sas.swipeColor.r, sas.swipeColor.g, sas.swipeColor.b, sas.swipeColor.a or 1)
		asWidgets.textColor:SetColor(sas.textColor.r, sas.textColor.g, sas.textColor.b, 1)
		asWidgets.textClass:SetValue(sas.textClassColor)
		asWidgets.desaturate:SetValue(sas.desaturate)
		UpdateControlStates()
	end

	local function CreateActiveStatePanel()
		local window = AceGUI:Create('Window')
		window:SetTitle('|cffff2f3dTrenchyUI|r Active State')
		window:SetWidth(300)
		window:SetHeight(340)
		window:SetLayout('Flow')
		window:EnableResize(false)
		window.frame:SetFrameStrata('DIALOG')

		local mode = AceGUI:Create('Dropdown')
		mode:SetLabel('Mode')
		mode:SetList(MODE_LIST, MODE_ORDER)
		mode:SetFullWidth(true)
		mode:SetCallback('OnValueChanged', function(_, _, val)
			local sas = CDM.GetOrCreateSpellActiveStateDB(activeStateSpellID)
			if sas then sas.mode = val UpdateControlStates() RefreshActiveState() end
		end)
		window:AddChild(mode)
		asWidgets.mode = mode

		local swipe = AceGUI:Create('Dropdown')
		swipe:SetLabel('Swipe')
		swipe:SetList(SWIPE_LIST, SWIPE_ORDER)
		swipe:SetFullWidth(true)
		swipe:SetCallback('OnValueChanged', function(_, _, val)
			local sas = CDM.GetOrCreateSpellActiveStateDB(activeStateSpellID)
			if sas then sas.swipe = val UpdateControlStates() RefreshActiveState() end
		end)
		window:AddChild(swipe)
		asWidgets.swipe = swipe

		local swipeColor = AceGUI:Create('ColorPicker')
		swipeColor:SetLabel('Swipe Color')
		swipeColor:SetFullWidth(true)
		swipeColor:SetHasAlpha(true)
		local function scChanged(_, _, r, g, b, a)
			local sas = CDM.GetOrCreateSpellActiveStateDB(activeStateSpellID)
			if sas then sas.swipeColor.r, sas.swipeColor.g, sas.swipeColor.b, sas.swipeColor.a = r, g, b, a RefreshActiveState() end
		end
		swipeColor:SetCallback('OnValueChanged', scChanged)
		swipeColor:SetCallback('OnValueConfirmed', scChanged)
		window:AddChild(swipeColor)
		asWidgets.swipeColor = swipeColor

		local textColor = AceGUI:Create('ColorPicker')
		textColor:SetLabel('Active Text Color')
		textColor:SetRelativeWidth(0.6)
		textColor:SetHasAlpha(false)
		local function tcChanged(_, _, r, g, b)
			local sas = CDM.GetOrCreateSpellActiveStateDB(activeStateSpellID)
			if sas then sas.textColor.r, sas.textColor.g, sas.textColor.b = r, g, b RefreshActiveState() end
		end
		textColor:SetCallback('OnValueChanged', tcChanged)
		textColor:SetCallback('OnValueConfirmed', tcChanged)
		window:AddChild(textColor)
		asWidgets.textColor = textColor

		local textClass = AceGUI:Create('CheckBox')
		textClass:SetLabel('Class')
		textClass:SetRelativeWidth(0.4)
		textClass:SetCallback('OnValueChanged', function(_, _, val)
			local sas = CDM.GetOrCreateSpellActiveStateDB(activeStateSpellID)
			if sas then sas.textClassColor = val RefreshActiveState() end
		end)
		window:AddChild(textClass)
		asWidgets.textClass = textClass

		local desaturate = AceGUI:Create('CheckBox')
		desaturate:SetLabel('Desaturate icon while active')
		desaturate:SetFullWidth(true)
		desaturate:SetCallback('OnValueChanged', function(_, _, val)
			local sas = CDM.GetOrCreateSpellActiveStateDB(activeStateSpellID)
			if sas then sas.desaturate = val RefreshActiveState() end
		end)
		window:AddChild(desaturate)
		asWidgets.desaturate = desaturate

		local textNote = AceGUI:Create('Label')
		textNote:SetText('|cff808080Active Text Color applies only while the buff is active; your baseline cooldown text is restored afterward.|r')
		textNote:SetFullWidth(true)
		window:AddChild(textNote)
		asWidgets.textNote = textNote

		window:Hide()
		activeStatePanel = window
	end

	function CDM:HideActiveStatePanel()
		if activeStatePanel then activeStatePanel:Hide() end
	end

	function CDM:ShowActiveStatePanel(spellID)
		if not activeStatePanel then CreateActiveStatePanel() end
		activeStateSpellID = spellID
		CDM:HideGlowPanel()
		CDM:HideBarColorPanel()
		AnchorOptionPanel(activeStatePanel, spellID, 'tuiActiveStateHooked')
		UpdateActiveStateWidgets()
		activeStatePanel:Show()
	end
end

-- Blizzard CDM settings
function CDM.ShowBlizzardCDMSettings()
	if not C_AddOns.IsAddOnLoaded('Blizzard_CooldownViewer') then
		C_AddOns.LoadAddOn('Blizzard_CooldownViewer')
	end
	local settings = _G.CooldownViewerSettings
	if settings and not settings:IsShown() then
		settings:Show()
	end
	CDM.ScheduleRelayout()
end

function CDM.HideBlizzardCDMSettings()
	local settings = _G.CooldownViewerSettings
	if settings and settings:IsShown() then
		settings:Hide()
	end
	CDM.ScheduleRelayout()
end

function CDM.IsConfigOpen()
	local ACD = E.Libs.AceConfigDialog
	return ACD and ACD.OpenFrames and ACD.OpenFrames.ElvUI
end

function CDM.OpenCDMConfig()
	local ACD = E.Libs.AceConfigDialog
	if not ACD then return end

	if not (ACD.OpenFrames and ACD.OpenFrames.ElvUI) then
		E:ToggleOptions()
	end

	-- ElvUI_Options is load-on-demand; its config can register a moment after ToggleOptions (e.g. right after a fresh login). Poll until 'ElvUI' is registered before navigating, so SelectGroup never fires on an unregistered app.
	local ACR = E.Libs.AceConfigRegistry
	local tries = 0
	local function nav()
		tries = tries + 1
		if ACR and ACR:GetOptionsTable('ElvUI') then
			ACD:SelectGroup('ElvUI', 'TrenchyUI', 'cooldownManager')
		elseif tries < 25 then
			C_Timer.After(0.1, nav)
		end
	end
	nav()
end
