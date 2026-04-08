-- CDM Buff Bar Cooldowns viewer
local E = unpack(ElvUI)
local CDM = E:GetModule('TUI_CDM')

local LSM = CDM.LSM
local hooksecurefunc = hooksecurefunc
local ipairs = ipairs
local math_ceil = math.ceil
local wipe = wipe

-- Bar styling
function CDM.ApplyBarStyle(frame, vdb)
	local bar = frame.Bar
	if not bar then return end

	local barH = vdb.barHeight or 20
	local showIcon = vdb.showIcon ~= false
	local iconGap = vdb.iconGap or 2
	local iconSide = frame.tuiBarIconSide or 'LEFT'

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

	local fgTex = LSM:Fetch('statusbar', vdb.foregroundTexture or 'ElvUI Norm')
	local statusBarTex = bar:GetStatusBarTexture()
	if statusBarTex then
		statusBarTex:SetTexture(fgTex)
		statusBarTex:ClearTextureSlice()
		statusBarTex:SetTextureSliceMode(0)
	end

	local bgTex = LSM:Fetch('statusbar', vdb.backgroundTexture or 'ElvUI Norm')
	if bar.BarBG then
		bar.BarBG:SetTexture(bgTex)
		bar.BarBG:ClearAllPoints()
		bar.BarBG:SetAllPoints(bar)
	end

	local spellID = frame.GetBaseSpellID and frame:GetBaseSpellID()
	local sbc = spellID and CDM.GetSpellBarColorDB(spellID)
	local hasCustomColor = sbc and sbc.enabled

	if hasCustomColor then
		bar:SetStatusBarColor(sbc.fgColor.r, sbc.fgColor.g, sbc.fgColor.b)
		if bar.BarBG then
			local bg = sbc.bgColor
			bar.BarBG:SetVertexColor(bg.r, bg.g, bg.b, bg.a or 0.5)
		end
		if not frame.tuiBarColorHooked then
			frame.tuiBarColorHooked = true
			local origSetColor = bar.SetStatusBarColor
			hooksecurefunc(bar, 'SetStatusBarColor', function(self)
				local sid = frame.GetBaseSpellID and frame:GetBaseSpellID()
				local sc = sid and CDM.GetSpellBarColorDB(sid)
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

	if bar.Name then
		if vdb.showName ~= false and vdb.nameText then
			bar.Name:Show()
			CDM.StyleFontString(bar.Name, vdb.nameText)
		else
			bar.Name:Hide()
		end
	end

	if bar.Duration then
		if vdb.showTimer ~= false and vdb.durationText then
			bar.Duration:Show()
			CDM.StyleFontString(bar.Duration, vdb.durationText)
		else
			bar.Duration:Hide()
		end
	end

	if icon and showIcon then CDM.ApplyCountText(icon, vdb.stacksText) end

	if frame.DebuffBorder and not frame.tuiDebuffBorderKilled then
		frame.DebuffBorder:Hide()
		frame.DebuffBorder:SetAlpha(0)
		hooksecurefunc(frame.DebuffBorder, 'Show', function(self) self:Hide() end)
		frame.tuiDebuffBorderKilled = true
	end
end

-- Buff bar layout
function CDM.LayoutBuffBar(viewerKey, isCapture)
	local container = CDM.containers[viewerKey]
	if not container then return end

	local db = CDM.GetDB()
	if not db or not db.enabled then return end

	local vdb = CDM.GetViewerDB(viewerKey)
	if not vdb then return end

	local viewer = CDM.GetViewer(viewerKey)
	if not viewer then return end

	local barW = vdb.barWidth or 200
	local barH = vdb.barHeight or 20
	local spacing = vdb.spacing or 2
	local growUp = (vdb.growthDirection == 'UP')

	local bars = CDM.iconCache[viewerKey]
	if not bars then bars = {}; CDM.iconCache[viewerKey] = bars end
	wipe(bars)

	if not viewer.itemFramePool then return end
	for frame in viewer.itemFramePool:EnumerateActive() do
		if frame and frame:IsShown() then
			bars[#bars + 1] = frame
		end
	end

	table.sort(bars, CDM.sortFunc)

	local count = #bars

	local vis = vdb.visibleSetting or 'ALWAYS'
	if vdb.hideWhenInactive and count == 0 then
		container:Hide()
	elseif vis ~= 'HIDDEN' and not container:IsShown() then
		if CDM.ShouldShowContainer(viewerKey) then
			container:Show()
		end
	end

	if count == 0 then
		container:SetSize(barW, barH)
		CDM.AnchorToMover(viewerKey, vdb.growthDirection)
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

		for row = 0, rows - 1 do
			local li = row * 2 + 1
			local left = bars[li]
			local right = bars[li + 1]
			local yOff = yDir * row * (barH + spacing)

			left:SetScale(1)
			left:SetSize(right and colW or barW, barH)
			left.tuiBarIconSide = right and 'RIGHT' or 'LEFT'
			if isCapture or not CDM.styledFrames[left] then
				CDM.ApplyBarStyle(left, vdb)
				CDM.styledFrames[left] = viewerKey
				left.tuiViewerKey = viewerKey
			end
			left:ClearAllPoints()
			left:SetPoint(anchor, container, anchor, 0, yOff)

			if right then
				right:SetScale(1)
				right:SetSize(colW, barH)
				right.tuiBarIconSide = 'LEFT'
				if isCapture or not CDM.styledFrames[right] then
					CDM.ApplyBarStyle(right, vdb)
					CDM.styledFrames[right] = viewerKey
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

			if isCapture or not CDM.styledFrames[frame] then
				CDM.ApplyBarStyle(frame, vdb)
				CDM.styledFrames[frame] = viewerKey
				frame.tuiViewerKey = viewerKey
			end

			frame:ClearAllPoints()
			frame:SetPoint(anchor, container, anchor, 0, yDir * (i - 1) * (barH + spacing))
		end
	end

	CDM.AnchorToMover(viewerKey, vdb.growthDirection)
end
