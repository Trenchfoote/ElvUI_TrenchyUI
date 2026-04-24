-- CDM shared helpers: containers, movers, styling, glow, preview
local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local CDM = E:GetModule('TUI_CDM')

local LCG = CDM.LCG
local LSM = CDM.LSM

local hooksecurefunc = hooksecurefunc
local ipairs = ipairs
local pairs = pairs
local wipe = wipe
local math_ceil = math.ceil
local math_min = math.min
local math_floor = math.floor
local CDM_CONFIG_STRING = 'TrenchyUI,cooldownManager'

local function CDMDisabled() local d = CDM.GetDB(); return not (d and d.enabled) end
local function IgnoreQuadrant() end

-- Container creation
function CDM.CreateContainer(viewerKey)
	local info = CDM.VIEWER_KEYS[viewerKey]
	local vdb = CDM.GetViewerDB(viewerKey)

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

	E:CreateMover(frame, info.mover .. 'Mover', 'TUI ' .. info.label, nil, nil, IgnoreQuadrant, 'ALL,TRENCHYUI', CDMDisabled, configStr)

	CDM.containers[viewerKey] = frame
	return frame
end

function CDM.AnchorToMover(viewerKey, growDirection)
	local container = CDM.containers[viewerKey]
	if not container then return end
	local info = CDM.VIEWER_KEYS[viewerKey]
	local mover = _G[info.mover .. 'Mover']
	if not mover then return end

	-- Re-anchor the mover so its fixed edge matches the growth direction
	if not InCombatLockdown() and mover:GetPoint() then
		local fixedAnchor
		if growDirection == 'UP' then
			fixedAnchor = 'BOTTOM'
		elseif growDirection == 'DOWN' then
			fixedAnchor = 'TOP'
		else
			fixedAnchor = 'CENTER'
		end

		local fixedX, fixedY
		if fixedAnchor == 'BOTTOM' then
			fixedX = (mover:GetLeft() + mover:GetRight()) / 2
			fixedY = mover:GetBottom()
		elseif fixedAnchor == 'TOP' then
			fixedX = (mover:GetLeft() + mover:GetRight()) / 2
			fixedY = mover:GetTop()
		else
			fixedX = (mover:GetLeft() + mover:GetRight()) / 2
			fixedY = (mover:GetBottom() + mover:GetTop()) / 2
		end

		if fixedX and fixedY then
			mover:ClearAllPoints()
			mover:SetPoint(fixedAnchor, UIParent, 'BOTTOMLEFT', fixedX, fixedY)
		end
	end

	container:ClearAllPoints()
	if growDirection == 'UP' then
		container:SetPoint('BOTTOM', mover, 'BOTTOM')
	elseif growDirection == 'DOWN' then
		container:SetPoint('TOP', mover, 'TOP')
	else
		container:SetPoint('CENTER', mover, 'CENTER')
	end
end

-- Icon grid layout shared by essential, utility, buffIcon
function CDM.LayoutIconViewer(viewerKey, isCapture, perIconCallback)
	local container = CDM.containers[viewerKey]
	if not container then return end

	local db = CDM.GetDB()
	if not db or not db.enabled then return end

	local vdb = CDM.GetViewerDB(viewerKey)
	if not vdb then return end

	local viewer = CDM.GetViewer(viewerKey)
	if not viewer or not viewer.itemFramePool then return end

	local iconW = E:Scale(vdb.iconWidth or 30)
	local iconH = (vdb.keepSizeRatio and iconW) or E:Scale(vdb.iconHeight or 30)
	local perRow = vdb.iconsPerRow or 12

	local spacing = E:Scale(vdb.spacing or 2)
	local growUp = (vdb.growthDirection == 'UP')

	local icons = CDM.iconCache[viewerKey]
	if not icons then icons = {}; CDM.iconCache[viewerKey] = icons end
	wipe(icons)

	for frame in viewer.itemFramePool:EnumerateActive() do
		if frame and frame:IsShown() and frame.layoutIndex then
			icons[#icons + 1] = frame
		end
	end

	table.sort(icons, CDM.sortFunc)

	local count = #icons
	if count == 0 then
		local minW = perRow * iconW + (perRow - 1) * spacing
		container:SetSize(minW, iconH)
		CDM.AnchorToMover(viewerKey, vdb.growthDirection)
		return
	end

	local applyStyle = isCapture
	local iconZoom = vdb.iconZoom

	for _, icon in ipairs(icons) do
		icon:SetScale(1)
		icon:SetSize(iconW, iconH)

		CDM.ApplyIconZoom(icon, iconZoom)

		if applyStyle or not CDM.styledFrames[icon] then
			CDM.ApplyTextOverrides(icon, vdb, db)
			CDM.styledFrames[icon] = viewerKey
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

	CDM.AnchorToMover(viewerKey, vdb.growthDirection)
end

-- Glow
local glowColor = {}
local GLOW_PREFIXES = { '_PixelGlow', '_AutoCastGlow', '_ButtonGlow', '_ProcGlow' }

function CDM.StopGlow(itemFrame)
	if not LCG or not CDM.glowActive[itemFrame] then return end
	CDM.glowActive[itemFrame] = nil

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

function CDM.ApplyGlow(itemFrame, glowDB, perSpell)
	if not LCG then return end

	local alert = itemFrame.SpellActivationAlert
	if not perSpell then
		if not alert or not alert:IsShown() then
			CDM.StopGlow(itemFrame)
			return
		end
	end

	if alert and alert:IsShown() then
		alert:SetAlpha(0)
		itemFrame.tuiAlertHidden = true
	end

	if alert and not CDM.hookedAlerts[itemFrame] then
		CDM.hookedAlerts[itemFrame] = true
		hooksecurefunc(alert, 'Show', function(self)
			local vKey = CDM.styledFrames[itemFrame]
			if vKey == 'buffIcon' then
				local sid = itemFrame.GetBaseSpellID and itemFrame:GetBaseSpellID()
				local sgdb = sid and CDM.GetSpellGlowDB(sid)
				if sgdb and sgdb.enabled then
					self:SetAlpha(0)
					itemFrame.tuiAlertHidden = true
				end
			else
				local vdb = vKey and CDM.GetViewerDB(vKey)
				if vdb and vdb.glow and vdb.glow.enabled then
					self:SetAlpha(0)
					itemFrame.tuiAlertHidden = true
				end
			end
		end)
	end

	CDM.glowActive[itemFrame] = true

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
function CDM.ApplyIconZoom(itemFrame, zoom)
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

function CDM.StyleFontString(fs, tdb)
	if not fs then return end
	fs:SetIgnoreParentScale(true)
	fs:ClearAllPoints()
	fs:SetPoint(tdb.position, tdb.xOffset, tdb.yOffset)
	fs:FontTemplate(LSM:Fetch('font', tdb.font), tdb.fontSize, tdb.fontOutline)
	fs:SetTextColor(GetTextColor(tdb))
end

function CDM.ApplyCountText(itemFrame, tdb)
	if not tdb then return end
	local fs
	fs = itemFrame.Applications and itemFrame.Applications.Applications
	if fs then CDM.StyleFontString(fs, tdb) end
	fs = itemFrame.Count
	if fs then CDM.StyleFontString(fs, tdb) end
	fs = itemFrame.ChargeCount and itemFrame.ChargeCount.Current
	if fs then CDM.StyleFontString(fs, tdb) end
end

function CDM.ApplyCooldownText(cooldown, tdb)
	if not cooldown or not tdb then return end
	cooldown:SetHideCountdownNumbers(false)
	local text = cooldown.tuiText or cooldown.Text or cooldown:GetRegions()
	if text and text.SetTextColor then
		cooldown.tuiText = text
		cooldown.Text = nil
		CDM.StyleFontString(text, tdb)
	end
end

function CDM.ApplySwipeOverride(cooldown, db)
	if not cooldown then return end
	if db.hideSwipe then
		cooldown:SetDrawSwipe(false)
		if not CDM.hookedSwipes[cooldown] then
			CDM.hookedSwipes[cooldown] = true
			hooksecurefunc(cooldown, 'SetDrawSwipe', function(self, draw)
				if draw then
					local cdb = CDM.GetDB()
					if cdb and cdb.enabled and cdb.hideSwipe then
						self:SetDrawSwipe(false)
					end
				end
			end)
		end
	end
end

function CDM.ApplyTextOverrides(itemFrame, vdb, db)
	CDM.ApplyCountText(itemFrame, vdb.countText)
	CDM.ApplyCooldownText(itemFrame.Cooldown, vdb.cooldownText)
	CDM.ApplySwipeOverride(itemFrame.Cooldown, db)
end

-- Keybind text: read directly from ElvUI action bar button HotKey FontStrings

function CDM.GetSpellKeybind(spellID)
	local slots = C_ActionBar.FindSpellActionButtons(spellID)
	if not slots then return nil end
	for _, slot in ipairs(slots) do
		for barNum = 1, 10 do
			for btnNum = 1, 12 do
				local btn = _G['ElvUI_Bar' .. barNum .. 'Button' .. btnNum]
				if btn and btn._state_action == slot and btn.HotKey then
					local text = btn.HotKey:GetText()
					if text and text ~= '' and text ~= _G.RANGE_INDICATOR then
						return text
					end
				end
			end
		end
	end
	return nil
end

function CDM.ApplyKeybindText(itemFrame, vdb)
	local tdb = vdb and vdb.keybindText
	if not vdb.showKeybind or not tdb then
		if itemFrame.tuiKeybind then itemFrame.tuiKeybind:SetText('') end
		return
	end

	local sid = itemFrame.GetBaseSpellID and itemFrame:GetBaseSpellID()
	if not sid then
		if itemFrame.tuiKeybind then itemFrame.tuiKeybind:SetText('') end
		return
	end

	if not itemFrame.tuiKeybind then
		itemFrame.tuiKeybind = itemFrame:CreateFontString(nil, 'OVERLAY')
		itemFrame.tuiKeybind:SetJustifyH('RIGHT')
		itemFrame.tuiKeybind:SetWordWrap(false)
	end

	CDM.StyleFontString(itemFrame.tuiKeybind, tdb)

	local key = CDM.GetSpellKeybind(sid)
	if key then
		itemFrame.tuiKeybind:SetText(key)
		itemFrame.tuiKeybind:Show()
	else
		itemFrame.tuiKeybind:SetText('')
	end
end

-- Preview text
function CDM.SetPreviewText(itemFrame, show, vdb)
	local bar = itemFrame.Bar
	if bar then
		local nameText = bar.Name and bar.Name:IsShown() and bar.Name:GetText()
		local hasRealName = nameText and (E:IsSecretValue(nameText) or nameText ~= '')
		if show and vdb then
			if vdb.nameText and not hasRealName then
				if not bar.tuiPreviewName then
					bar.tuiPreviewName = bar:CreateFontString(nil, 'OVERLAY')
				end
				local pfs = bar.tuiPreviewName
				CDM.StyleFontString(pfs, vdb.nameText)
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
				CDM.StyleFontString(pfs, vdb.durationText)
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
			CDM.StyleFontString(pfs, tdb)
			pfs:SetText('12')
			pfs:Show()
		end
	elseif itemFrame.tuiCDPreview then
		itemFrame.tuiCDPreview:Hide()
	end
end

function CDM.ShowPreview()
	if CDM.previewActive then return end
	CDM.previewActive = true

	for viewerKey in pairs(CDM.VIEWER_KEYS) do
		local vdb = CDM.GetViewerDB(viewerKey)
		local viewer = CDM.GetViewer(viewerKey)
		if viewer and vdb and viewer.itemFramePool then
			for frame in viewer.itemFramePool:EnumerateActive() do
				if frame and frame:IsShown() then
					CDM.SetPreviewText(frame, true, vdb)
				end
			end
		end
	end

	if CDM.RefreshCustomViewer then CDM.RefreshCustomViewer() end
end

function CDM.HidePreview()
	if not CDM.previewActive then return end
	CDM.previewActive = false

	for viewerKey in pairs(CDM.VIEWER_KEYS) do
		local viewer = CDM.GetViewer(viewerKey)
		if viewer and viewer.itemFramePool then
			for frame in viewer.itemFramePool:EnumerateActive() do
				if frame then
					CDM.SetPreviewText(frame, false)
				end
			end
		end
	end

	if CDM.RefreshCustomViewer then CDM.RefreshCustomViewer() end
	CDM.ScheduleRelayout()
end

-- Dispatcher: routes to per-viewer layout functions (loaded after per-viewer files)
local LAYOUT_MAP = {
	essential = function(c) return CDM.LayoutEssential(c) end,
	utility   = function(c) return CDM.LayoutUtility(c) end,
	buffIcon  = function(c) return CDM.LayoutBuffIcon(c) end,
	buffBar   = function(c) return CDM.LayoutBuffBar('buffBar', c) end,
	custom    = function() return CDM.LayoutCustomViewer and CDM.LayoutCustomViewer() end,
}

function CDM.LayoutContainer(viewerKey, isCapture)
	local fn = LAYOUT_MAP[viewerKey]
	if fn then fn(isCapture) end
end
