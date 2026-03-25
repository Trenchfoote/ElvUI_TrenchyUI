-- CDM shared helpers: containers, movers, styling, glow, preview
local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local S = TUI._cdm

local LCG = S.LCG
local LSM = S.LSM

local hooksecurefunc = hooksecurefunc
local ipairs = ipairs
local pairs = pairs
local wipe = wipe
local math_ceil = math.ceil
local math_min = math.min
local math_floor = math.floor

local CDM_CONFIG_STRING = 'TrenchyUI,cooldownManager'

-- Container creation
function S.CreateContainer(viewerKey)
	local info = S.VIEWER_KEYS[viewerKey]
	local vdb = S.GetViewerDB(viewerKey)

	local w, h
	if viewerKey == 'buffBar' then
		w = vdb and vdb.barWidth or 200
		h = (vdb and vdb.barHeight or 20) * 4
	elseif viewerKey == 'custom' then
		local iconW = vdb and vdb.iconWidth or 36
		w = iconW
		h = (vdb and vdb.keepSizeRatio and iconW) or (vdb and vdb.iconHeight or 36)
	else
		local iconW = vdb and vdb.iconWidth or 30
		local iconH = (vdb and vdb.keepSizeRatio and iconW) or (vdb and vdb.iconHeight or 30)
		w = iconW * 8
		h = iconH * 2
	end

	local configStr = CDM_CONFIG_STRING .. ',' .. viewerKey

	local frame = CreateFrame('Frame', info.mover .. 'Holder', E.UIParent)
	frame:SetSize(w, h)
	frame:SetPoint('TOPLEFT', E.UIParent, 'CENTER', 0, 0)
	frame:SetFrameStrata('MEDIUM')
	frame:SetFrameLevel(5)

	E:CreateMover(frame, info.mover .. 'Mover', 'TUI ' .. info.label, nil, nil, nil, 'ALL,TRENCHYUI', nil, configStr, true)
	S.moverToViewer[configStr] = viewerKey

	S.containers[viewerKey] = frame
	return frame
end

function S.AnchorToMover(viewerKey, growUp)
	local container = S.containers[viewerKey]
	if not container then return end
	local info = S.VIEWER_KEYS[viewerKey]
	local mover = _G[info.mover .. 'Mover']
	if not mover then return end

	if not InCombatLockdown() then
		mover:SetSize(container:GetSize())
	end

	container:ClearAllPoints()
	if growUp then
		container:SetPoint('BOTTOM', mover, 'BOTTOM')
	else
		container:SetPoint('TOP', mover, 'TOP')
	end
end

-- Icon grid layout shared by essential, utility, buffIcon
function S.LayoutIconViewer(viewerKey, isCapture, perIconCallback)
	local container = S.containers[viewerKey]
	if not container then return end

	local db = S.GetDB()
	if not db or not db.enabled then return end

	local vdb = S.GetViewerDB(viewerKey)
	if not vdb then return end

	local viewer = S.GetViewer(viewerKey)
	if not viewer or not viewer.itemFramePool then return end

	local iconW = E:Scale(vdb.iconWidth or 30)
	local iconH = (vdb.keepSizeRatio and iconW) or E:Scale(vdb.iconHeight or 30)
	local perRow = vdb.iconsPerRow or 12

	local spacing = E:Scale(vdb.spacing or 2)
	local growUp = (vdb.growthDirection == 'UP')

	local icons = S.iconCache[viewerKey]
	if not icons then icons = {}; S.iconCache[viewerKey] = icons end
	wipe(icons)

	for frame in viewer.itemFramePool:EnumerateActive() do
		if frame and frame:IsShown() and frame.layoutIndex then
			icons[#icons + 1] = frame
		end
	end

	table.sort(icons, S.sortFunc)

	local count = #icons
	if count == 0 then
		local minW = perRow * iconW + (perRow - 1) * spacing
		container:SetSize(minW, iconH)
		S.AnchorToMover(viewerKey, growUp)
		return
	end

	local applyStyle = isCapture
	local iconZoom = vdb.iconZoom

	for _, icon in ipairs(icons) do
		icon:SetScale(1)
		icon:SetSize(iconW, iconH)

		S.ApplyIconZoom(icon, iconZoom)

		if applyStyle or not S.styledFrames[icon] then
			S.ApplyTextOverrides(icon, vdb, db)
			S.styledFrames[icon] = viewerKey
			icon.tuiViewerKey = viewerKey
		end

		if perIconCallback then
			perIconCallback(icon, vdb, db)
		end

		if icon.DebuffBorder and not icon.tuiDebuffBorderKilled then
			icon.DebuffBorder:Hide()
			icon.DebuffBorder:SetAlpha(0)
			hooksecurefunc(icon.DebuffBorder, 'Show', function(self) self:Hide() end)
			icon.tuiDebuffBorderKilled = true
		end
	end

	local cols = math_min(count, perRow)
	local rows = math_ceil(count / perRow)
	local totalW = cols * iconW + (cols - 1) * spacing
	local totalH = rows * iconH + (rows - 1) * spacing
	container:SetSize(totalW, totalH)

	for i, icon in ipairs(icons) do
		local row = math_floor((i - 1) / perRow)
		local col = (i - 1) % perRow

		local rowStart = row * perRow + 1
		local rowEnd = math_min(rowStart + perRow - 1, count)
		local rowCount = rowEnd - rowStart + 1
		local rowW = rowCount * iconW + (rowCount - 1) * spacing
		local offsetX = (totalW - rowW) / 2

		local x = offsetX + col * (iconW + spacing)
		local y

		if growUp then
			y = row * (iconH + spacing)
		else
			y = -row * (iconH + spacing)
		end

		icon:ClearAllPoints()
		if growUp then
			icon:SetPoint('BOTTOMLEFT', container, 'BOTTOMLEFT', x, y)
		else
			icon:SetPoint('TOPLEFT', container, 'TOPLEFT', x, y)
		end
	end

	S.AnchorToMover(viewerKey, growUp)
end

-- Glow
local glowColor = {}
local GLOW_PREFIXES = { '_PixelGlow', '_AutoCastGlow', '_ButtonGlow', '_ProcGlow' }

function S.StopGlow(itemFrame)
	if not LCG or not S.glowActive[itemFrame] then return end
	S.glowActive[itemFrame] = nil

	LCG.PixelGlow_Stop(itemFrame, 'TUI_CDM')
	LCG.AutoCastGlow_Stop(itemFrame, 'TUI_CDM')
	LCG.ButtonGlow_Stop(itemFrame)
	LCG.ProcGlow_Stop(itemFrame, 'TUI_CDM')

	if itemFrame.tuiAlertHidden then
		itemFrame.tuiAlertHidden = nil
		local alert = itemFrame.SpellActivationAlert
		if alert then alert:SetAlpha(1) end
	end
end

function S.ApplyGlow(itemFrame, glowDB, perSpell)
	if not LCG then return end

	local alert = itemFrame.SpellActivationAlert
	if not perSpell then
		if not alert or not alert:IsShown() then
			S.StopGlow(itemFrame)
			return
		end
	end

	if alert and alert:IsShown() then
		alert:SetAlpha(0)
		itemFrame.tuiAlertHidden = true
	end

	if alert and not S.hookedAlerts[itemFrame] then
		S.hookedAlerts[itemFrame] = true
		hooksecurefunc(alert, 'Show', function(self)
			local vKey = S.styledFrames[itemFrame]
			if vKey == 'buffIcon' then
				local sid = itemFrame.GetBaseSpellID and itemFrame:GetBaseSpellID()
				local sgdb = sid and S.GetSpellGlowDB(sid)
				if sgdb and sgdb.enabled then
					self:SetAlpha(0)
					itemFrame.tuiAlertHidden = true
				end
			else
				local vdb = vKey and S.GetViewerDB(vKey)
				if vdb and vdb.glow and vdb.glow.enabled then
					self:SetAlpha(0)
					itemFrame.tuiAlertHidden = true
				end
			end
		end)
	end

	S.glowActive[itemFrame] = true

	local glowType = glowDB.type or 'pixel'
	local color = glowDB.color
	if color then
		glowColor[1], glowColor[2], glowColor[3], glowColor[4] = color.r, color.g, color.b, color.a or 1
	else
		glowColor[1], glowColor[2], glowColor[3], glowColor[4] = 0.95, 0.95, 0.32, 1
	end

	local fl = 0
	if glowType == 'pixel' then
		LCG.PixelGlow_Start(itemFrame, glowColor, glowDB.lines or 8, glowDB.speed or 0.25, glowDB.length, glowDB.thickness or 2, 0, 0, nil, 'TUI_CDM', fl)
	elseif glowType == 'autocast' then
		LCG.AutoCastGlow_Start(itemFrame, glowColor, glowDB.particles or 4, glowDB.speed or 0.25, glowDB.scale or 1, 0, 0, 'TUI_CDM', fl)
	elseif glowType == 'button' then
		LCG.ButtonGlow_Start(itemFrame, glowColor, glowDB.speed or 0.25, fl)
	elseif glowType == 'proc' then
		LCG.ProcGlow_Start(itemFrame, {
			color = glowColor,
			startAnim = glowDB.startAnim ~= false,
			key = 'TUI_CDM',
			frameLevel = fl,
		})
	end

	for _, prefix in ipairs(GLOW_PREFIXES) do
		local gf = itemFrame[prefix .. 'TUI_CDM']
		if gf then
			gf:ClearAllPoints()
			gf:SetPoint('TOPLEFT', itemFrame, 'TOPLEFT', 0, 0)
			gf:SetPoint('BOTTOMRIGHT', itemFrame, 'BOTTOMRIGHT', 0, 0)
			break
		end
	end
end

-- Icon zoom
function S.ApplyIconZoom(itemFrame, zoom)
	if not zoom or zoom <= 0 then return end
	local icon = itemFrame.Icon
	if icon then
		if icon.SetTexCoord then
			icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
		elseif icon.Icon and icon.Icon.SetTexCoord then
			icon.Icon:SetTexCoord(zoom, 1 - zoom, zoom, 1 - zoom)
		end
	end
end

-- Text styling
local function GetTextColor(tdb)
	if tdb.classColor then
		local cc = E:ClassColor(E.myclass)
		if cc then return cc.r, cc.g, cc.b end
	end
	local c = tdb.color
	return c.r, c.g, c.b
end

function S.StyleFontString(fs, tdb)
	if not fs then return end
	fs:SetIgnoreParentScale(true)
	fs:ClearAllPoints()
	fs:SetPoint(tdb.position, tdb.xOffset, tdb.yOffset)
	fs:FontTemplate(LSM:Fetch('font', tdb.font), tdb.fontSize, tdb.fontOutline)
	fs:SetTextColor(GetTextColor(tdb))
end

function S.ApplyCountText(itemFrame, tdb)
	if not tdb then return end
	local fs
	fs = itemFrame.Applications and itemFrame.Applications.Applications
	if fs then S.StyleFontString(fs, tdb) end
	fs = itemFrame.Count
	if fs then S.StyleFontString(fs, tdb) end
	fs = itemFrame.ChargeCount and itemFrame.ChargeCount.Current
	if fs then S.StyleFontString(fs, tdb) end
end

function S.ApplyCooldownText(cooldown, tdb)
	if not cooldown or not tdb then return end
	cooldown:SetHideCountdownNumbers(false)
	local text = cooldown.tuiText or cooldown.Text or cooldown:GetRegions()
	if text and text.SetTextColor then
		cooldown.tuiText = text
		cooldown.Text = nil
		S.StyleFontString(text, tdb)
	end
end

function S.ApplySwipeOverride(cooldown, db)
	if not cooldown then return end
	if db.hideSwipe then
		cooldown:SetDrawSwipe(false)
		if not S.hookedSwipes[cooldown] then
			S.hookedSwipes[cooldown] = true
			hooksecurefunc(cooldown, 'SetDrawSwipe', function(self, draw)
				if draw then
					local cdb = S.GetDB()
					if cdb and cdb.enabled and cdb.hideSwipe then
						self:SetDrawSwipe(false)
					end
				end
			end)
		end
	end
end

function S.ApplyTextOverrides(itemFrame, vdb, db)
	S.ApplyCountText(itemFrame, vdb.countText)
	S.ApplyCooldownText(itemFrame.Cooldown, vdb.cooldownText)
	S.ApplySwipeOverride(itemFrame.Cooldown, db)
end

-- Preview text
function S.SetPreviewText(itemFrame, show, vdb)
	local bar = itemFrame.Bar
	if bar then
		local nameText = bar.Name and bar.Name:IsShown() and bar.Name:GetText()
		local hasRealName = nameText and (issecretvalue(nameText) or nameText ~= '')
		if show and vdb then
			if vdb.nameText and not hasRealName then
				if not bar.tuiPreviewName then
					bar.tuiPreviewName = bar:CreateFontString(nil, 'OVERLAY')
				end
				local pfs = bar.tuiPreviewName
				S.StyleFontString(pfs, vdb.nameText)
				pfs:SetText('Buff Name')
				pfs:Show()
			elseif bar.tuiPreviewName then
				bar.tuiPreviewName:Hide()
			end
			if vdb.durationText then
				if not bar.tuiPreviewDuration then
					bar.tuiPreviewDuration = bar:CreateFontString(nil, 'OVERLAY')
				end
				local pfs = bar.tuiPreviewDuration
				S.StyleFontString(pfs, vdb.durationText)
				pfs:SetText('12.5s')
				pfs:Show()
			end
		else
			if bar.tuiPreviewName then bar.tuiPreviewName:Hide() end
			if bar.tuiPreviewDuration then bar.tuiPreviewDuration:Hide() end
		end
		return
	end

	if show then
		local tdb = vdb and vdb.cooldownText
		if tdb then
			if not itemFrame.tuiCDPreview then
				itemFrame.tuiCDPreview = itemFrame:CreateFontString(nil, 'OVERLAY')
			end
			local pfs = itemFrame.tuiCDPreview
			S.StyleFontString(pfs, tdb)
			pfs:SetText('12')
			pfs:Show()
		end
	elseif itemFrame.tuiCDPreview then
		itemFrame.tuiCDPreview:Hide()
	end
end

function S.ShowPreview()
	if S.previewActive then return end
	S.previewActive = true

	for viewerKey in pairs(S.VIEWER_KEYS) do
		local vdb = S.GetViewerDB(viewerKey)
		local viewer = S.GetViewer(viewerKey)
		if viewer and vdb and viewer.itemFramePool then
			for frame in viewer.itemFramePool:EnumerateActive() do
				if frame and frame:IsShown() then
					S.SetPreviewText(frame, true, vdb)
				end
			end
		end
	end

	if S.RefreshCustomViewer then S.RefreshCustomViewer() end
end

function S.HidePreview()
	if not S.previewActive then return end
	S.previewActive = false

	for viewerKey in pairs(S.VIEWER_KEYS) do
		local viewer = S.GetViewer(viewerKey)
		if viewer and viewer.itemFramePool then
			for frame in viewer.itemFramePool:EnumerateActive() do
				if frame then
					S.SetPreviewText(frame, false)
				end
			end
		end
	end

	if S.RefreshCustomViewer then S.RefreshCustomViewer() end
	S.ScheduleRelayout()
end

-- Dispatcher: routes to per-viewer layout functions (loaded after per-viewer files)
local LAYOUT_MAP = {
	essential = function(c) return S.LayoutEssential(c) end,
	utility   = function(c) return S.LayoutUtility(c) end,
	buffIcon  = function(c) return S.LayoutBuffIcon(c) end,
	buffBar   = function(c) return S.LayoutBuffBar('buffBar', c) end,
	custom    = function(c) return S.LayoutCustomViewer and S.LayoutCustomViewer() end,
}

function S.LayoutContainer(viewerKey, isCapture)
	local fn = LAYOUT_MAP[viewerKey]
	if fn then fn(isCapture) end
end
