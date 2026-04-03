local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')

local CreateFrame = CreateFrame
local ipairs, pairs, sort = ipairs, pairs, sort
local tostring, floor, ceil, min = tostring, math.floor, math.ceil, math.min

local mbbBar
local mbbButtons = {}
local mbbInCombat = false
local mbbSkinned = {}

local UpdateVisibility
local MBB_PADDING = 4
local backdropInsets = { left = 0, right = 0, top = 0, bottom = 0 }
local backdropTable = { insets = backdropInsets }

local function GetMBBDB()
	return TUI.db.profile.minimapButtonBar
end

local function StripButton(btn)
	if mbbSkinned[btn] then return end
	mbbSkinned[btn] = true

	for _, region in pairs({ btn:GetRegions() }) do
		if region.IsObjectType and region:IsObjectType('Texture') then
			local tex = region:GetTexture()
			local texStr = tex and tostring(tex):lower() or ''

			if texStr:find('border') or texStr:find('overlay') or texStr:find('background')
			or texStr == '136430' or texStr == '136467' then
				region:SetTexture(nil)
				region:SetAlpha(0)
				region:Hide()
			end
		end
	end

	for _, key in ipairs({ 'overlay', 'Border', 'border', 'highlight' }) do
		local child = btn[key]
		if child and child.SetTexture then
			child:SetTexture(nil)
			child:SetAlpha(0)
		end
	end

	local hl = btn.GetHighlightTexture and btn:GetHighlightTexture()
	if hl then
		hl:SetTexture(nil)
		hl:SetAlpha(0)
	end

	local icon = btn.icon
	if not icon then
		for _, region in pairs({ btn:GetRegions() }) do
			if region.IsObjectType and region:IsObjectType('Texture') and region:GetTexture() and region:IsShown() then
				icon = region
				break
			end
		end
	end
	btn.tuiIcon = icon
end

local function SkinButton(btn, size)
	StripButton(btn)

	local db = GetMBBDB()
	btn:SetSize(size, size)

	if not btn.tuiBackdrop then
		local bd = CreateFrame('Frame', nil, btn, 'BackdropTemplate')
		bd:SetFrameLevel(btn:GetFrameLevel())
		btn.tuiBackdrop = bd
	end

	local bd = btn.tuiBackdrop
	local bSize = db.buttonBorderSize or 1
	bd:ClearAllPoints()
	bd:SetPoint('TOPLEFT', btn, 'TOPLEFT', -bSize, bSize)
	bd:SetPoint('BOTTOMRIGHT', btn, 'BOTTOMRIGHT', bSize, -bSize)

	if db.buttonBackdrop or db.buttonBorder then
		backdropTable.bgFile = db.buttonBackdrop and E.media.blankTex or nil
		backdropTable.edgeFile = db.buttonBorder and E.media.blankTex or nil
		backdropTable.edgeSize = db.buttonBorder and bSize or 0
		bd:SetBackdrop(backdropTable)
		if db.buttonBackdrop then
			local c = db.buttonBackdropColor
			bd:SetBackdropColor(c.r, c.g, c.b, c.a)
		else
			bd:SetBackdropColor(0, 0, 0, 0)
		end
		if db.buttonBorder then
			local c = db.buttonBorderColor
			bd:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
		end
		bd:Show()
	else
		bd:SetBackdrop(nil)
		bd:Hide()
	end

	local icon = btn.tuiIcon
	if icon then
		icon:ClearAllPoints()
		icon:SetPoint('TOPLEFT', btn, 'TOPLEFT', 0, 0)
		icon:SetPoint('BOTTOMRIGHT', btn, 'BOTTOMRIGHT', 0, 0)
		icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	end
end

local function LayoutBar()
	if not mbbBar then return end
	local db = GetMBBDB()
	local size = db.buttonSize
	local spacing = db.buttonSpacing
	local perRow = db.buttonsPerRow
	local bdInset = (db.buttonBorder and db.buttonBorderSize or 0)
	local effectiveSpacing = spacing + bdInset * 2
	local growth = db.growthDirection or 'RIGHTDOWN'

	local count = #mbbButtons
	if count == 0 then
		mbbBar:SetSize(size + MBB_PADDING * 2, size + MBB_PADDING * 2)
		return
	end

	local primary = min(count, perRow)
	local secondary = ceil(count / perRow)

	local isHorizontal = (db.orientation or 'HORIZONTAL') == 'HORIZONTAL'
	local barW, barH
	if isHorizontal then
		barW = MBB_PADDING * 2 + primary * size + (primary - 1) * effectiveSpacing
		barH = MBB_PADDING * 2 + secondary * size + (secondary - 1) * effectiveSpacing
	else
		barW = MBB_PADDING * 2 + secondary * size + (secondary - 1) * effectiveSpacing
		barH = MBB_PADDING * 2 + primary * size + (primary - 1) * effectiveSpacing
	end

	local anchorPoint, xDir, yDir
	if growth == 'RIGHTDOWN' then     anchorPoint = 'TOPLEFT';     xDir =  1; yDir = -1
	elseif growth == 'RIGHTUP' then   anchorPoint = 'BOTTOMLEFT';  xDir =  1; yDir =  1
	elseif growth == 'LEFTDOWN' then  anchorPoint = 'TOPRIGHT';    xDir = -1; yDir = -1
	elseif growth == 'LEFTUP' then    anchorPoint = 'BOTTOMRIGHT'; xDir = -1; yDir =  1
	elseif growth == 'DOWNRIGHT' then anchorPoint = 'TOPLEFT';     xDir =  1; yDir = -1
	elseif growth == 'DOWNLEFT' then  anchorPoint = 'TOPRIGHT';    xDir = -1; yDir = -1
	elseif growth == 'UPRIGHT' then   anchorPoint = 'BOTTOMLEFT';  xDir =  1; yDir =  1
	elseif growth == 'UPLEFT' then    anchorPoint = 'BOTTOMRIGHT'; xDir = -1; yDir =  1
	else                              anchorPoint = 'TOPLEFT';     xDir =  1; yDir = -1
	end

	mbbBar:SetSize(barW, barH)
	local mover = mbbBar.mover
	if mover then
		local curPoint = mover:GetPoint()
		if curPoint ~= anchorPoint then
			local ax, ay
			if anchorPoint == 'TOPLEFT' then        ax, ay = mover:GetLeft(),  mover:GetTop()
			elseif anchorPoint == 'TOPRIGHT' then   ax, ay = mover:GetRight(), mover:GetTop()
			elseif anchorPoint == 'BOTTOMLEFT' then ax, ay = mover:GetLeft(),  mover:GetBottom()
			else                                    ax, ay = mover:GetRight(), mover:GetBottom()
			end
			if ax and ay then
				mover:ClearAllPoints()
				mover:SetPoint(anchorPoint, UIParent, 'BOTTOMLEFT', ax, ay)
				E:SaveMoverPosition('TrenchyUIMinimapButtonBarMover')
			end
		end
		mbbBar:ClearAllPoints()
		mbbBar:SetPoint(anchorPoint, mover, anchorPoint, 0, 0)
	end

	for i, btn in ipairs(mbbButtons) do
		btn:ClearAllPoints()
		SkinButton(btn, size)

		local idx = i - 1
		local primaryIdx = idx % perRow
		local secondaryIdx = floor(idx / perRow)

		local x, y
		if isHorizontal then
			x = xDir * (MBB_PADDING + primaryIdx * (size + effectiveSpacing))
			y = yDir * (MBB_PADDING + secondaryIdx * (size + effectiveSpacing))
		else
			x = xDir * (MBB_PADDING + secondaryIdx * (size + effectiveSpacing))
			y = yDir * (MBB_PADDING + primaryIdx * (size + effectiveSpacing))
		end

		btn:SetPoint(anchorPoint, mbbBar, anchorPoint, x, y)
		btn:SetParent(mbbBar)
		if not btn.tuiMouseHooked then
			btn:HookScript('OnEnter', function() UpdateVisibility() end)
			btn:HookScript('OnLeave', function() UpdateVisibility() end)
			btn.tuiMouseHooked = true
		end
		btn:Show()
	end
end

local function UpdateBarStyle()
	if not mbbBar then return end
	local db = GetMBBDB()

	if db.backdrop or db.border then
		local bSize = db.borderSize or 1
		backdropTable.bgFile = db.backdrop and E.media.blankTex or nil
		backdropTable.edgeFile = db.border and E.media.blankTex or nil
		backdropTable.edgeSize = db.border and bSize or 0
		mbbBar:SetBackdrop(backdropTable)
		if db.backdrop then
			local bc = db.backdropColor
			mbbBar:SetBackdropColor(bc.r, bc.g, bc.b, bc.a)
		else
			mbbBar:SetBackdropColor(0, 0, 0, 0)
		end
		if db.border then
			local ec = db.borderColor
			mbbBar:SetBackdropBorderColor(ec.r, ec.g, ec.b, ec.a)
		end
	else
		mbbBar:SetBackdrop(nil)
	end
end

UpdateVisibility = function()
	if not mbbBar then return end
	local db = GetMBBDB()

	if C_PetBattles and C_PetBattles.IsInBattle() then mbbBar:Hide(); return end

	if db.hideInCombat and mbbInCombat then mbbBar:Hide(); return end

	if not mbbBar:IsShown() then mbbBar:Show() end

	if db.mouseover then
		mbbBar:SetAlpha(mbbBar:IsMouseOver() and db.mouseoverAlpha or 0)
	else
		mbbBar:SetAlpha(1)
	end
end

local function CollectButtons()
	mbbButtons = {}
	local LDB = LibStub and LibStub('LibDBIcon-1.0', true)
	if not LDB then return end

	local objects = LDB:GetButtonList()
	if objects then
		for _, obj in ipairs(objects) do
			local btn = type(obj) == 'string' and LDB:GetMinimapButton(obj) or obj
			if btn and btn:IsObjectType('Frame') then
				-- Respect addon's own hide setting from LibDBIcon
				if not (btn.db and btn.db.hide) then
					mbbButtons[#mbbButtons + 1] = btn
				end
			end
		end
	end

	local zygorBtn = _G['ZygorGuidesViewerMapIcon']
	if zygorBtn and zygorBtn:IsObjectType('Frame') then
		mbbButtons[#mbbButtons + 1] = zygorBtn
	end

	sort(mbbButtons, function(a, b)
		return (a:GetName() or '') < (b:GetName() or '')
	end)
end

function TUI:UpdateMinimapButtonBar()
	if not mbbBar then return end
	CollectButtons()
	LayoutBar()
	UpdateBarStyle()
	UpdateVisibility()
end

function TUI:InitMinimapButtonBar()
	local db = GetMBBDB()
	if not db.enabled then return end

	C_Timer.After(2, function()
		mbbBar = CreateFrame('Frame', 'TrenchyUIMinimapButtonBar', E.UIParent, 'BackdropTemplate')
		mbbBar:SetSize(200, 40)
		mbbBar:SetPoint('TOPRIGHT', E.UIParent, 'TOPRIGHT', -200, -4)
		mbbBar:SetClampedToScreen(true)
		mbbBar:SetFrameStrata('LOW')

		mbbBar:SetScript('OnEnter', UpdateVisibility)
		mbbBar:SetScript('OnLeave', UpdateVisibility)
		mbbBar:HookScript('OnShow', UpdateVisibility)

		TUI:RegisterEvent('PLAYER_REGEN_DISABLED', function()
			mbbInCombat = true
			UpdateVisibility()
		end)
		TUI:RegisterEvent('PLAYER_REGEN_ENABLED', function()
			mbbInCombat = false
			UpdateVisibility()
		end)
		TUI:RegisterEvent('PET_BATTLE_OPENING_START', UpdateVisibility)
		TUI:RegisterEvent('PET_BATTLE_CLOSE', UpdateVisibility)

		E:CreateMover(mbbBar, 'TrenchyUIMinimapButtonBarMover', 'TUI Minimap Buttons', nil, nil, LayoutBar, 'ALL,TRENCHYUI', nil, 'TrenchyUI,qol')
		TUI:UpdateMinimapButtonBar()
		C_Timer.After(5, function() TUI:UpdateMinimapButtonBar() end)
	end)
end
