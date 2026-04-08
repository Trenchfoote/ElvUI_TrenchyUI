local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local CDM = E:GetModule('TUI_CDM')

local hooksecurefunc = hooksecurefunc
local pairs = pairs
local ipairs = ipairs
local wipe = wipe

-- Hook setup
local layoutPending = false

local function DoRelayout()
	layoutPending = false
	local db = CDM.GetDB()
	if not db or not db.enabled then return end
	for viewerKey in pairs(CDM.VIEWER_KEYS) do
		CDM.LayoutContainer(viewerKey, false)
	end
	CDM:UpdateCDMVisibility()
end

function CDM.ScheduleRelayout()
	if layoutPending then return end
	layoutPending = true
	C_Timer.After(0, DoRelayout)
end

local cdmDisabledByCVar = false

local function OnCDMEvent(event, unit, ...)
	if event == 'CVAR_UPDATE' then
		local cvar = unit
		if cvar == 'cooldownViewerEnabled' then
			local val = ...
			if val == '0' then
				cdmDisabledByCVar = true
				for viewerKey, info in pairs(CDM.VIEWER_KEYS) do
					if info.global then
						local container = CDM.containers[viewerKey]
						if container then container:Hide() end
					end
				end
				E:Print('|cffff2f3dTrenchyUI|r: Cooldown Manager requires Blizzard\'s Cooldown Viewer. Re-enable it in Options > Gameplay Enhancements > Enable Cooldown Manager.')
			else
				cdmDisabledByCVar = false
				CDM:UpdateCDMVisibility()
				CDM.ScheduleRelayout()
			end
		end
		return
	end
	if cdmDisabledByCVar then return end
	-- Track combat state from any event since PLAYER_REGEN may not fire
	local inCombat = InCombatLockdown()
	if inCombat ~= CDM.inCombat then
		CDM.inCombat = inCombat
		CDM:UpdateCDMVisibility()
	end
	if event == 'UNIT_AURA' and unit ~= 'player' then return end
	CDM.ScheduleRelayout()
end

local function HookViewer(viewerKey)
	local viewer = CDM.GetViewer(viewerKey)
	if not viewer or CDM.hookedViewers[viewerKey] then return end
	CDM.hookedViewers[viewerKey] = true

	-- Clear stale Edit Mode anchors
	local container = CDM.containers[viewerKey]
	if container then
		viewer:ClearAllPoints()
		viewer:SetPoint('CENTER', container, 'CENTER', 0, 0)
		viewer:SetParent(container)
	end

	if viewer.itemFramePool then
		hooksecurefunc(viewer.itemFramePool, 'Acquire', function()
			CDM.ScheduleRelayout()
		end)
		hooksecurefunc(viewer.itemFramePool, 'Release', function()
			CDM.ScheduleRelayout()
		end)
	end

	if viewer.OnAcquireItemFrame then
		hooksecurefunc(viewer, 'OnAcquireItemFrame', function()
			CDM.ScheduleRelayout()
		end)
	end

	hooksecurefunc(viewer, 'RefreshLayout', function()
		local db = CDM.GetDB()
		if not db or not db.enabled then return end
		CDM.LayoutContainer(viewerKey, true)
	end)

	local selection = viewer.Selection
	if selection then
		selection:Hide()
		selection:SetAlpha(0)
		hooksecurefunc(selection, 'Show', function(self)
			self:Hide()
		end)
	end
end

-- Edit Mode HWI
local function FindViewerSettings(systemIndex)
	if not (C_EditMode and C_EditMode.GetLayouts and C_EditMode.SaveLayouts) then return end
	local enums = Enum and Enum.EditModeSystem
	if not (enums and enums.CooldownViewer and Enum.EditModeCooldownViewerSystemIndices and Enum.EditModeCooldownViewerSetting) then return end

	local layoutInfo = C_EditMode.GetLayouts()
	if type(layoutInfo) ~= 'table' or type(layoutInfo.layouts) ~= 'table' or type(layoutInfo.activeLayout) ~= 'number' then return end

	-- Preset layouts must be merged so activeLayout index resolves
	if EditModePresetLayoutManager and EditModePresetLayoutManager.GetCopyOfPresetLayouts then
		local presets = EditModePresetLayoutManager:GetCopyOfPresetLayouts()
		if type(presets) == 'table' then
			tAppendAll(presets, layoutInfo.layouts)
			layoutInfo.layouts = presets
		end
	end

	local active = layoutInfo.layouts[layoutInfo.activeLayout]
	if type(active) ~= 'table' or type(active.systems) ~= 'table' then return end

	for _, sys in ipairs(active.systems) do
		if sys.system == enums.CooldownViewer
			and sys.systemIndex == systemIndex
			and type(sys.settings) == 'table' then
			return sys.settings, layoutInfo
		end
	end
end

local VIEWER_SYSTEM_INDEX = {
	essential = Enum.EditModeCooldownViewerSystemIndices and Enum.EditModeCooldownViewerSystemIndices.Essential,
	utility   = Enum.EditModeCooldownViewerSystemIndices and Enum.EditModeCooldownViewerSystemIndices.Utility,
	buffIcon  = Enum.EditModeCooldownViewerSystemIndices and Enum.EditModeCooldownViewerSystemIndices.BuffIcon,
	buffBar   = Enum.EditModeCooldownViewerSystemIndices and Enum.EditModeCooldownViewerSystemIndices.BuffBar,
}

function CDM:GetEditModeSetting(viewerKey, settingEnum)
	local sysIdx = VIEWER_SYSTEM_INDEX and VIEWER_SYSTEM_INDEX[viewerKey]
	if not sysIdx then return nil end
	local settings = FindViewerSettings(sysIdx)
	if not settings then return nil end
	for _, s in ipairs(settings) do
		if s.setting == settingEnum then return s.value end
	end
	return nil
end

function CDM:SetEditModeSetting(viewerKey, settingEnum, value)
	local sysIdx = VIEWER_SYSTEM_INDEX and VIEWER_SYSTEM_INDEX[viewerKey]
	if not sysIdx then return end
	local settings, layoutInfo = FindViewerSettings(sysIdx)
	if not settings then return end
	for _, s in ipairs(settings) do
		if s.setting == settingEnum then
			if s.value == value then return end
			s.value = value
			C_EditMode.SaveLayouts(layoutInfo)
			return
		end
	end
	settings[#settings + 1] = { setting = settingEnum, value = value }
	C_EditMode.SaveLayouts(layoutInfo)
end

function CDM.ShouldShowContainer(viewerKey)
	local vdb = CDM.GetViewerDB(viewerKey)
	if not vdb then return true end

	local vis = vdb.visibleSetting or 'ALWAYS'
	if vis == 'HIDDEN' then return false end
	if vis == 'FADER' then return true end
	if vis == 'INCOMBAT' and not CDM.inCombat then return false end
	return true
end

function CDM:UpdateCDMVisibility()
	local db = CDM.GetDB()
	if not db or not db.enabled then return end

	local playerFrame = _G.ElvUF_Player

	for viewerKey in pairs(CDM.VIEWER_KEYS) do
		local vdb = CDM.GetViewerDB(viewerKey)
		local show = CDM.ShouldShowContainer(viewerKey)
		local container = CDM.containers[viewerKey]
		local viewer = CDM.GetViewer(viewerKey)

		if container then container:SetShown(show) end

		-- Sync alpha: FADER mirrors player frame, others reset to full
		if vdb and vdb.visibleSetting == 'FADER' then
			local alpha = playerFrame and playerFrame:GetAlpha() or 1
			if container then container:SetAlpha(alpha) end
			if viewer then viewer:SetAlpha(alpha) end
		else
			if container then container:SetAlpha(1) end
			if viewer then viewer:SetAlpha(1) end
		end
	end
end

-- Public API
function CDM:RefreshCDM()
	local db = CDM.GetDB()
	if not db or not db.enabled then return end

	wipe(CDM.styledFrames)
	wipe(CDM.glowActive)

	for viewerKey in pairs(CDM.VIEWER_KEYS) do
		CDM.LayoutContainer(viewerKey, true)
	end

	CDM.RefreshCustomViewer()
	self:UpdateCDMVisibility()

	if CDM.previewActive then
		CDM.previewActive = false
		CDM.ShowPreview()
	end
end

function CDM:Initialize()
	if TUI:IsCompatBlocked('cooldownManager') then return end
	local db = CDM.GetDB()
	if not db or not db.enabled then return end
	if self._cdmInitialized then return end
	self._cdmInitialized = true

	-- Force Blizzard CDM on; warn if viewers aren't loaded yet (requires reload)
	if GetCVarBool('cooldownViewerEnabled') ~= true then
		SetCVar('cooldownViewerEnabled', 1)
		if not _G['EssentialCooldownViewer'] then
			C_Timer.After(1, function()
				E:StaticPopup_Show('CONFIG_RL')
			end)
			E:Print('|cffff2f3dTrenchyUI|r: Enabled Blizzard Cooldown Manager. A reload is required.')
			return
		end
	end

	-- Sync our DB to reflect Blizzard's current Edit Mode HWI state
	local hwiSetting = Enum.EditModeCooldownViewerSetting and Enum.EditModeCooldownViewerSetting.HideWhenInactive
	if hwiSetting then
		for _, vk in ipairs({'buffIcon', 'buffBar'}) do
			local vdb = CDM.GetViewerDB(vk)
			local val = self:GetEditModeSetting(vk, hwiSetting)
			if vdb and val ~= nil then
				vdb.hideWhenInactive = (val == 1)
			end
		end
	end

	-- Force essential/utility viewers visible if Blizzard Edit Mode has them hidden
	local visSetting = Enum.EditModeCooldownViewerSetting and Enum.EditModeCooldownViewerSetting.VisibleSetting
	local visAlways = Enum.CooldownViewerVisibleSetting and Enum.CooldownViewerVisibleSetting.Always
	local visHidden = Enum.CooldownViewerVisibleSetting and Enum.CooldownViewerVisibleSetting.Hidden
	if visSetting and visAlways and visHidden then
		for _, vk in ipairs({'essential', 'utility'}) do
			local val = self:GetEditModeSetting(vk, visSetting)
			if val == visHidden then
				self:SetEditModeSetting(vk, visSetting, visAlways)
				local viewer = _G[CDM.VIEWER_KEYS[vk] and CDM.VIEWER_KEYS[vk].global]
				if viewer then
					viewer.visibleSetting = visAlways
					viewer:UpdateShownState()
				end
			end
		end
	end

	C_Timer.After(0, function()
		for viewerKey in pairs(CDM.VIEWER_KEYS) do
			if viewerKey ~= 'custom' then
				CDM.CreateContainer(viewerKey)
				HookViewer(viewerKey)
				CDM.LayoutContainer(viewerKey, true)
			end
		end

		CDM.InitCustomViewer()

		-- Resolve viewerKey from a frame or its parents via styledFrames/tuiViewerKey
		local function ResolveViewerKey(frame)
			if not frame then return nil end
			local key = CDM.styledFrames[frame] or frame.tuiViewerKey
			if key then return key end
			local parent = frame:GetParent()
			return parent and (CDM.styledFrames[parent] or parent.tuiViewerKey) or nil
		end

		-- Post-hook ElvUI Skins to re-apply our text styling after ElvUI overrides it
		local ElvSkins = E:GetModule('Skins', true)
		if ElvSkins then
			if ElvSkins.CooldownManager_UpdateTextContainer then
				hooksecurefunc(ElvSkins, 'CooldownManager_UpdateTextContainer', function(_, itemFrame)
					local viewerKey = ResolveViewerKey(itemFrame)
					if not viewerKey then return end
					local vdb = CDM.GetViewerDB(viewerKey)
					if vdb then
						CDM.ApplyCountText(itemFrame, vdb.countText)
					end
				end)
			end
			if ElvSkins.CooldownManager_SkinIcon then
				hooksecurefunc(ElvSkins, 'CooldownManager_SkinIcon', function(_, itemFrame)
					local viewerKey = ResolveViewerKey(itemFrame)
					if not viewerKey then return end
					local cdb = CDM.GetDB()
					local vdb = CDM.GetViewerDB(viewerKey)
					if vdb and cdb then
						CDM.ApplyTextOverrides(itemFrame, vdb, cdb)
					end
				end)
			end
			if ElvSkins.CooldownManager_SkinBar then
				hooksecurefunc(ElvSkins, 'CooldownManager_SkinBar', function(_, frame)
					local viewerKey = ResolveViewerKey(frame)
					if viewerKey == 'buffBar' then
						local vdb = CDM.GetViewerDB('buffBar')
						if vdb then CDM.ApplyBarStyle(frame, vdb) end
					end
				end)
			end
			if ElvSkins.CooldownManager_UpdateTextBar then
				hooksecurefunc(ElvSkins, 'CooldownManager_UpdateTextBar', function(_, bar)
					local frame = bar:GetParent()
					if frame and ResolveViewerKey(frame) == 'buffBar' then
						local vdb = CDM.GetViewerDB('buffBar')
						if vdb then
							if bar.Name and vdb.nameText then CDM.StyleFontString(bar.Name, vdb.nameText) end
							if bar.Duration and vdb.durationText then CDM.StyleFontString(bar.Duration, vdb.durationText) end
						end
					end
				end)
			end
		end

		-- Re-shield cooldown text after ElvUI's CooldownUpdate sets SetHideCountdownNumbers
		hooksecurefunc(E, 'CooldownUpdate', function(_, cooldown)
			if not cooldown or not cooldown.tuiText then return end
			cooldown:SetHideCountdownNumbers(false)
		end)

		CDM:RegisterEvent('UNIT_AURA', OnCDMEvent)
		CDM:RegisterEvent('SPELL_UPDATE_COOLDOWN', OnCDMEvent)
		CDM:RegisterEvent('SPELLS_CHANGED', OnCDMEvent)
		CDM:RegisterEvent('UPDATE_BINDINGS', OnCDMEvent)
		CDM:RegisterEvent('CVAR_UPDATE', OnCDMEvent)

		CDM:UpdateCDMVisibility()

		-- Mirror player frame fader alpha to FADER-mode CDM containers
		local playerFrame = _G.ElvUF_Player
		if playerFrame then
			hooksecurefunc(playerFrame, 'SetAlpha', function(pf)
				local alpha = pf:GetAlpha()
				for viewerKey in pairs(CDM.VIEWER_KEYS) do
					local vdb = CDM.GetViewerDB(viewerKey)
					if vdb and vdb.visibleSetting == 'FADER' then
						local container = CDM.containers[viewerKey]
						if container then container:SetAlpha(alpha) end
						local viewer = CDM.GetViewer(viewerKey)
						if viewer then viewer:SetAlpha(alpha) end
					end
				end
			end)
		end

		-- Right-click context menu for buff CDM items
		local CATEGORY_TRACKED_BUFF = 2
		local CATEGORY_TRACKED_BAR = 3
		local tuiMenuTitle = '|cffff2f3dTrenchyUI|r CDM'

		Menu.ModifyMenu('MENU_COOLDOWN_SETTINGS_ITEM', function(owner, rootDescription)
			if not owner or not owner.GetCooldownInfo then return end
			local cdInfo = owner:GetCooldownInfo()
			if not cdInfo then return end
			local cat = cdInfo.category

			if cat ~= CATEGORY_TRACKED_BUFF and cat ~= CATEGORY_TRACKED_BAR then return end

			rootDescription:CreateDivider()
			rootDescription:CreateTitle(tuiMenuTitle)

			if cat == CATEGORY_TRACKED_BAR then
				rootDescription:CreateButton('Bar Color Options', function()
					local spellID = owner.GetBaseSpellID and owner:GetBaseSpellID()
					if spellID then CDM:ShowBarColorPanel(spellID) end
				end)
			else
				rootDescription:CreateButton('Glow Options', function()
					local spellID = owner.GetBaseSpellID and owner:GetBaseSpellID()
					if spellID then CDM:ShowGlowPanel(spellID) end
				end)
			end
		end)

		SLASH_TUICDM1 = '/cdm'
		SlashCmdList['TUICDM'] = function()
			if cdmDisabledByCVar then
				E:Print('|cffff2f3dTrenchyUI|r: Cooldown Manager requires Blizzard\'s Cooldown Viewer. Re-enable it in Options > Gameplay Enhancements > Enable Cooldown Manager.')
				return
			end
			CDM.OpenCDMConfig()
		end
	end)
end

-- Config hooks
local cdmTabActive = false
local hookedConfigFrames = {}

local function TryHookConfigClose()
	local ACD = E.Libs.AceConfigDialog
	if not ACD or not ACD.OpenFrames then return end

	local configFrame = ACD.OpenFrames.ElvUI
	if not configFrame or not configFrame.frame then return end
	if hookedConfigFrames[configFrame.frame] then return end

	hookedConfigFrames[configFrame.frame] = true
	configFrame.frame:HookScript('OnHide', function()
		cdmTabActive = false
		CDM.HideBlizzardCDMSettings()
		if CDM.previewActive then CDM.HidePreview() end
	end)
end

C_Timer.After(0, function()
	local ACD = E.Libs.AceConfigDialog
	if ACD then
		-- Shared logic for detecting CDM tab navigation
		local function HandleGroupChange(appName, pathContainsCDM)
			if appName ~= 'ElvUI' then return end

			TryHookConfigClose()

			if pathContainsCDM and not cdmTabActive then
				cdmTabActive = true
				CDM.ShowBlizzardCDMSettings()
			elseif not pathContainsCDM and cdmTabActive then
				cdmTabActive = false
				CDM.HideBlizzardCDMSettings()
				if CDM.previewActive then CDM.HidePreview() end
			end
		end

		-- Hook SelectGroup for programmatic navigation (e.g. /cdm, mover right-click)
		hooksecurefunc(ACD, 'SelectGroup', function(_, appName, ...)
			local isCDM = false
			for i = 1, select('#', ...) do
				if select(i, ...) == 'cooldownManager' then
					isCDM = true
					break
				end
			end
			HandleGroupChange(appName, isCDM)
		end)

		-- Hook FeedGroup for user clicks
		hooksecurefunc(ACD, 'FeedGroup', function(_, appName, _, _, _, path)
			if appName ~= 'ElvUI' or type(path) ~= 'table' then return end
			if #path == 0 then return end

			local hasTrenchyUI = false
			local isCDM = false
			for i = 1, #path do
				if path[i] == 'TrenchyUI' then hasTrenchyUI = true end
				if path[i] == 'cooldownManager' then isCDM = true end
			end

			-- Skip parent TrenchyUI tree setup (path={'TrenchyUI'})
			if hasTrenchyUI and not isCDM and #path < 2 then return end

			-- Only react when navigating within TrenchyUI or away from CDM
			if not hasTrenchyUI and not cdmTabActive then return end

			HandleGroupChange(appName, isCDM)
		end)
	end

	-- Config close hook fallback from mover right-click
	hooksecurefunc(E, 'ToggleOptions', function()
		C_Timer.After(0.1, TryHookConfigClose)
	end)
end)

E:RegisterModule(CDM:GetName())
