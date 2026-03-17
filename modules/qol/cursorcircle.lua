local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')

local CreateFrame = CreateFrame
local GetCursorPosition = GetCursorPosition

local TEXTURE_PATH = 'Interface\\AddOns\\ElvUI_TrenchyUI\\media\\cursorcircle_'
local circleFrame, circleTexture

local function ApplyCircleColor()
	local db = TUI.db.profile.qol
	if db.cursorCircleClassColor then
		local cc = E:ClassColor(E.myclass)
		circleTexture:SetVertexColor(cc.r, cc.g, cc.b, 1)
	else
		local c = db.cursorCircleColor or { r = 1, g = 1, b = 1, a = 1 }
		circleTexture:SetVertexColor(c.r, c.g, c.b, c.a or 1)
	end
end

function TUI:InitCursorCircle()
	if circleFrame then return end
	local db = self.db.profile.qol

	circleFrame = CreateFrame('Frame', nil, UIParent)
	circleFrame:SetSize(db.cursorCircleSize or 64, db.cursorCircleSize or 64)
	circleFrame:SetFrameStrata('TOOLTIP')
	circleFrame:SetFrameLevel(128)

	circleTexture = circleFrame:CreateTexture(nil, 'OVERLAY')
	circleTexture:SetAllPoints()
	circleTexture:SetTexture(TEXTURE_PATH .. (db.cursorCircleThickness or 'medium'))
	ApplyCircleColor()

	local lastX, lastY = 0, 0
	circleFrame:SetScript('OnUpdate', function(frame)
		local cx, cy = GetCursorPosition()
		if cx == lastX and cy == lastY then return end
		lastX, lastY = cx, cy
		frame:ClearAllPoints()
		local scale = UIParent:GetEffectiveScale()
		frame:SetPoint('CENTER', UIParent, 'BOTTOMLEFT', cx / scale, cy / scale)
	end)

	circleFrame:Show()
end

function TUI:UpdateCursorCircle()
	if not circleFrame then return end
	local db = self.db.profile.qol
	local size = db.cursorCircleSize or 64
	circleFrame:SetSize(size, size)
	circleTexture:SetTexture(TEXTURE_PATH .. (db.cursorCircleThickness or 'medium'))
	ApplyCircleColor()
end

function TUI:ToggleCursorCircle(enable)
	if enable then
		if not circleFrame then
			self:InitCursorCircle()
		else
			circleFrame:Show()
		end
	elseif circleFrame then
		circleFrame:Hide()
	end
end
