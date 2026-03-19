local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local S = TUI._cdm

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

-- Re-anchor container to its mover based on growth direction
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

function S.LayoutContainer(viewerKey, isCapture)
	if viewerKey == 'custom' then return S.LayoutCustomViewer() end
	if viewerKey == 'buffBar' then return S.LayoutBuffBar(viewerKey, isCapture) end

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
	local vGlow = vdb.glow
	local useGlow = vGlow and vGlow.enabled

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

		if viewerKey == 'buffIcon' then
			local sid = icon.GetBaseSpellID and icon:GetBaseSpellID()
			local sgdb = sid and S.GetSpellGlowDB(sid)
			if sgdb and sgdb.enabled then
				S.ApplyGlow(icon, sgdb, true)
			else
				S.StopGlow(icon)
			end
		elseif useGlow then
			S.ApplyGlow(icon, vGlow)
		else
			S.StopGlow(icon)
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

-- Buff Bar styling
function S.ApplyBarStyle(frame, vdb)
	local bar = frame.Bar
	if not bar then return end

	local barH = vdb.barHeight or 20
	local showIcon = vdb.showIcon ~= false
	local iconGap = vdb.iconGap or 2
	local iconSide = frame.tuiBarIconSide or 'LEFT'

	-- Icon sizing and anchoring
	local icon = frame.Icon
	if icon then
		if showIcon then
			icon:Show()
			icon:ClearAllPoints()
			icon:SetSize(barH, barH)
			if iconSide == 'RIGHT' then
				icon:SetPoint('RIGHT', frame, 'RIGHT', 0, 0)
			else
				icon:SetPoint('LEFT', frame, 'LEFT', 0, 0)
			end
			if icon.Icon then icon.Icon:SetAllPoints(icon) end
		else
			icon:Hide()
		end
	end

	-- Bar anchoring: fill remaining space
	bar:ClearAllPoints()
	bar:SetReverseFill(iconSide == 'RIGHT')
	if showIcon and icon then
		if iconSide == 'RIGHT' then
			bar:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
			bar:SetPoint('BOTTOMRIGHT', icon, 'BOTTOMLEFT', -iconGap, 0)
		else
			bar:SetPoint('TOPLEFT', icon, 'TOPRIGHT', iconGap, 0)
			bar:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, 0)
		end
	else
		bar:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
		bar:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, 0)
	end

	-- Foreground texture
	local fgTex = LSM:Fetch('statusbar', vdb.foregroundTexture or 'ElvUI Norm')
	local statusBarTex = bar:GetStatusBarTexture()
	if statusBarTex then
		statusBarTex:SetTexture(fgTex)
		statusBarTex:ClearTextureSlice()
		statusBarTex:SetTextureSliceMode(0)
	end

	-- Background texture
	local bgTex = LSM:Fetch('statusbar', vdb.backgroundTexture or 'ElvUI Norm')
	if bar.BarBG then
		bar.BarBG:SetTexture(bgTex)
		bar.BarBG:ClearAllPoints()
		bar.BarBG:SetAllPoints(bar)
	end

	-- Per-spell bar color override
	local spellID = frame.GetBaseSpellID and frame:GetBaseSpellID()
	local sbc = spellID and S.GetSpellBarColorDB(spellID)
	local hasCustomColor = sbc and sbc.enabled

	if hasCustomColor then
		bar:SetStatusBarColor(sbc.fgColor.r, sbc.fgColor.g, sbc.fgColor.b)
		if bar.BarBG then
			local bg = sbc.bgColor
			bar.BarBG:SetVertexColor(bg.r, bg.g, bg.b, bg.a or 0.5)
		end
		-- Hook to persist custom color over Blizzard updates
		if not frame.tuiBarColorHooked then
			frame.tuiBarColorHooked = true
			local origSetColor = bar.SetStatusBarColor
			hooksecurefunc(bar, 'SetStatusBarColor', function(self)
				local sid = frame.GetBaseSpellID and frame:GetBaseSpellID()
				local sc = sid and S.GetSpellBarColorDB(sid)
				if sc and sc.enabled and not frame.tuiSettingColor then
					frame.tuiSettingColor = true
					origSetColor(self, sc.fgColor.r, sc.fgColor.g, sc.fgColor.b)
					frame.tuiSettingColor = false
				end
			end)
		end
	elseif frame.tuiBarColorHooked then
		frame.tuiSettingColor = false
	end

	-- Spark (Pip) toggle
	if bar.Pip then
		if vdb.showSpark then
			bar.Pip:SetAlpha(1)
			bar.Pip:Show()
		else
			bar.Pip:SetAlpha(0)
			bar.Pip:Hide()
			if not bar.Pip.tuiKilled then
				bar.Pip.tuiKilled = true
				hooksecurefunc(bar.Pip, 'Show', function(self) self:SetAlpha(0) end)
			end
		end
	end
	if frame.CooldownFlash then frame.CooldownFlash:Hide() end

	-- Hide icon overlay texture (atlas UI-HUD-CoolDownManager-IconOverlay)
	if icon and not frame.tuiIconOverlayKilled then
		for _, region in next, { icon:GetRegions() } do
			if region:IsObjectType('Texture') then
				local atlas = region:GetAtlas()
				if atlas == 'UI-HUD-CoolDownManager-IconOverlay' then
					region:SetAlpha(0)
				end
			end
		end
		frame.tuiIconOverlayKilled = true
	end

	-- Name text
	if bar.Name then
		if vdb.showName ~= false and vdb.nameText then
			bar.Name:Show()
			S.StyleFontString(bar.Name, vdb.nameText)
		else
			bar.Name:Hide()
		end
	end

	-- Duration text
	if bar.Duration then
		if vdb.showTimer ~= false and vdb.durationText then
			bar.Duration:Show()
			S.StyleFontString(bar.Duration, vdb.durationText)
		else
			bar.Duration:Hide()
		end
	end

	-- Stacks text on icon
	if icon and showIcon then S.ApplyCountText(icon, vdb.stacksText) end

	-- DebuffBorder suppression
	if frame.DebuffBorder and not frame.tuiDebuffBorderKilled then
		frame.DebuffBorder:Hide()
		frame.DebuffBorder:SetAlpha(0)
		hooksecurefunc(frame.DebuffBorder, 'Show', function(self) self:Hide() end)
		frame.tuiDebuffBorderKilled = true
	end
end

function S.LayoutBuffBar(viewerKey, isCapture)
	local container = S.containers[viewerKey]
	if not container then return end

	local db = S.GetDB()
	if not db or not db.enabled then return end

	local vdb = S.GetViewerDB(viewerKey)
	if not vdb then return end

	local viewer = S.GetViewer(viewerKey)
	if not viewer then return end

	local barW = vdb.barWidth or 200
	local barH = vdb.barHeight or 20
	local spacing = vdb.spacing or 2
	local growUp = (vdb.growthDirection == 'UP')

	local bars = S.iconCache[viewerKey]
	if not bars then bars = {}; S.iconCache[viewerKey] = bars end
	wipe(bars)

	if not viewer.itemFramePool then return end
	for frame in viewer.itemFramePool:EnumerateActive() do
		if frame and frame:IsShown() then
			bars[#bars + 1] = frame
		end
	end

	table.sort(bars, S.sortFunc)

	local count = #bars

	-- Visibility: hideWhenInactive toggles within the current visibility state
	local vis = vdb.visibleSetting or 'ALWAYS'
	if vdb.hideWhenInactive and count == 0 then
		container:Hide()
		if viewer then viewer:Hide() end
	elseif vis ~= 'HIDDEN' and not container:IsShown() then
		if S.ShouldShowContainer(viewerKey) then
			container:Show()
			if viewer then viewer:Show() end
		end
	end

	if count == 0 then
		container:SetSize(barW, barH)
		S.AnchorToMover(viewerKey, growUp)
		return
	end

	local mirroredColumns = vdb.mirroredColumns and count >= 2
	local columnGap = vdb.columnGap or 4
	local anchor = growUp and 'BOTTOMLEFT' or 'TOPLEFT'
	local yDir = growUp and 1 or -1

	if mirroredColumns then
		local colW = (barW - columnGap) / 2
		local rows = math_ceil(count / 2)
		container:SetSize(barW, rows * barH + (rows - 1) * spacing)

		-- Iterate by row, processing left/right pairs together
		for row = 0, rows - 1 do
			local li = row * 2 + 1
			local left = bars[li]
			local right = bars[li + 1]
			local yOff = yDir * row * (barH + spacing)

			-- Left bar: full width if unpaired (odd last), otherwise half
			left:SetScale(1)
			left:SetSize(right and colW or barW, barH)
			left.tuiBarIconSide = right and 'RIGHT' or 'LEFT'
			if isCapture or not S.styledFrames[left] then
				S.ApplyBarStyle(left, vdb)
				S.styledFrames[left] = viewerKey
				left.tuiViewerKey = viewerKey
			end
			left:ClearAllPoints()
			left:SetPoint(anchor, container, anchor, 0, yOff)

			-- Right bar (absent on odd-count last row)
			if right then
				right:SetScale(1)
				right:SetSize(colW, barH)
				right.tuiBarIconSide = 'LEFT'
				if isCapture or not S.styledFrames[right] then
					S.ApplyBarStyle(right, vdb)
					S.styledFrames[right] = viewerKey
					right.tuiViewerKey = viewerKey
				end
				right:ClearAllPoints()
				right:SetPoint(anchor, container, anchor, colW + columnGap, yOff)
			end
		end
	else
		container:SetSize(barW, count * barH + (count - 1) * spacing)

		for i, frame in ipairs(bars) do
			frame:SetScale(1)
			frame:SetSize(barW, barH)
			frame.tuiBarIconSide = 'LEFT'

			if isCapture or not S.styledFrames[frame] then
				S.ApplyBarStyle(frame, vdb)
				S.styledFrames[frame] = viewerKey
				frame.tuiViewerKey = viewerKey
			end

			frame:ClearAllPoints()
			frame:SetPoint(anchor, container, anchor, 0, yDir * (i - 1) * (barH + spacing))
		end
	end

	S.AnchorToMover(viewerKey, growUp)
end
