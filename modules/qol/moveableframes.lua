local E = unpack(ElvUI)
local QOL = E:GetModule('TUI_QoL')

local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc
local InCombatLockdown = InCombatLockdown
local pairs = pairs

local hookedFrames = {}

local skipFrames = {
	HouseEditorFrame = true, HousingDashboardFrame = true, HouseFinderFrame = true,
	HouseListFrame = true, HousingHouseSettingsFrame = true, HousingModelPreviewFrame = true,
	HousingCornerstoneVisitorFrame = true, HousingCornerstoneHouseInfoFrame = true,
	HousingCornerstonePurchaseFrame = true, HousingBulletinBoardFrame = true,
}

local function MakeMoveable(frame)
	if hookedFrames[frame] then return end
	if not frame.IsObjectType or not frame:IsObjectType('Frame') then return end
	if frame:IsProtected() and InCombatLockdown() then return end
	if frame.mover then return end

	local name = frame.GetName and frame:GetName() or 'unknown'
	if skipFrames[name] then return end

	if name == 'MailFrame' or name == 'AchievementFrame' then
		hookedFrames[frame] = true
		frame:EnableMouse(true)
		frame:SetClampedToScreen(true)

		local function StartDrag(parent, button)
			if button ~= 'LeftButton' then return end
			parent.tuiDragging = true
			local cx, cy = GetCursorPosition()
			local scale = parent:GetEffectiveScale()
			parent.tuiDragCursorX = cx / scale
			parent.tuiDragCursorY = cy / scale
			parent.tuiDragLeft = parent:GetLeft()
			parent.tuiDragTop = parent:GetTop()
		end
		local function StopDrag(parent, button)
			if button == 'LeftButton' then parent.tuiDragging = false end
		end

		frame:HookScript('OnMouseDown', StartDrag)
		frame:HookScript('OnMouseUp', StopDrag)
		frame:HookScript('OnUpdate', function(self)
			if not self.tuiDragging then return end
			local cx, cy = GetCursorPosition()
			local scale = self:GetEffectiveScale()
			cx, cy = cx / scale, cy / scale
			local dx = cx - self.tuiDragCursorX
			local dy = cy - self.tuiDragCursorY
			self:ClearAllPoints()
			self:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', self.tuiDragLeft + dx, self.tuiDragTop + dy)
		end)

		if name == 'AchievementFrame' and frame.Header then
			frame.Header:HookScript('OnMouseDown', function(_, button) StartDrag(frame, button) end)
			frame.Header:HookScript('OnMouseUp', function(_, button) StopDrag(frame, button) end)
		end

		return
	end

	hookedFrames[frame] = true
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)

	if frame:IsProtected() then
		local handle = CreateFrame('Frame', nil, frame, 'PanelDragBarTemplate')
		handle:SetAllPoints(frame)
		handle:SetFrameLevel(frame:GetFrameLevel() + 1)
		handle:SetPropagateMouseMotion(true)
		handle:SetPropagateMouseClicks(true)
		handle:HookScript('OnMouseDown', function(_, button)
			if button == 'LeftButton' and not InCombatLockdown() then frame:StartMoving() end
		end)
		handle:HookScript('OnMouseUp', function(_, button)
			if button == 'LeftButton' then frame:StopMovingOrSizing() end
		end)
	else
		frame:EnableMouse(true)
		frame:HookScript('OnMouseDown', function(self, button)
			if button == 'LeftButton' then self:StartMoving() end
		end)
		frame:HookScript('OnMouseUp', function(self, button)
			if button == 'LeftButton' then self:StopMovingOrSizing() end
		end)
	end
end

local function HookUIPanels()
	if not UIPanelWindows then return end
	for name in pairs(UIPanelWindows) do
		local frame = _G[name]
		if frame and type(frame) == 'table' and frame.IsObjectType then
			MakeMoveable(frame)
		end
	end
end

local function HookElvUIBags()
	local B = E:GetModule('Bags')
	if not B then return end

	local function FreeDrag(self) self:StartMoving() end

	if B.BagFrame then B.BagFrame:SetScript('OnDragStart', FreeDrag); hookedFrames[B.BagFrame] = true end
	if B.BankFrame then B.BankFrame:SetScript('OnDragStart', FreeDrag); hookedFrames[B.BankFrame] = true end
end

function QOL:InitMoveableFrames()
	C_Timer.After(1, function()
		HookUIPanels()
		HookElvUIBags()
	end)

	hooksecurefunc('ShowUIPanel', function(frame)
		if frame and not hookedFrames[frame] then MakeMoveable(frame) end
	end)

	-- Keystone frame bypasses ShowUIPanel — hook it when the addon loads
	local function HookKeystoneFrame()
		local f = _G.ChallengesKeystoneFrame
		if f then MakeMoveable(f) end
	end
	if C_AddOns.IsAddOnLoaded('Blizzard_ChallengesUI') then
		HookKeystoneFrame()
	else
		EventUtil.ContinueOnAddOnLoaded('Blizzard_ChallengesUI', HookKeystoneFrame)
	end
end
