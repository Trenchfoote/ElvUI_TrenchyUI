local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local QOL = E:GetModule('TUI_QoL')
local A = E:GetModule('Auras')

local function HookChildButton(button, header, hiddenAlpha)
	if button._tuiFaderHooked then return end
	button._tuiFaderHooked = true

	button:HookScript('OnEnter', function()
		E:UIFrameFadeIn(header, 0.15, header:GetAlpha(), 1)
	end)

	button:HookScript('OnLeave', function()
		if not header:IsMouseOver() then
			E:UIFrameFadeOut(header, 0.3, header:GetAlpha(), hiddenAlpha)
		end
	end)
end

local function HookChildren(header, hiddenAlpha)
	for i = 1, 40 do
		local child = header:GetAttribute('child' .. i)
		if not child then break end
		if child.IsObjectType and child:IsObjectType('Button') then
			HookChildButton(child, header, hiddenAlpha)
		end
	end
end

local function SetupFader(header, hiddenAlpha)
	if not header or header._tuiFaderHooked then return end
	header._tuiFaderHooked = true

	header:SetAlpha(hiddenAlpha)

	header:HookScript('OnEnter', function(self)
		E:UIFrameFadeIn(self, 0.15, self:GetAlpha(), 1)
	end)

	header:HookScript('OnLeave', function(self)
		if not self:IsMouseOver() then
			E:UIFrameFadeOut(self, 0.3, self:GetAlpha(), hiddenAlpha)
		end
	end)

	-- Hook existing children
	HookChildren(header, hiddenAlpha)

	-- Hook future children as they're created
	hooksecurefunc(A, 'UpdateHeader', function(_, hdr)
		if hdr == header then
			HookChildren(header, hiddenAlpha)
		end
	end)
end

function QOL:InitAuraFader()
	if not A.Initialized then return end

	local db = TUI.db.profile.qol

	if db.buffMouseover and A.BuffFrame then
		SetupFader(A.BuffFrame, db.buffMouseoverAlpha or 0)
	end

	if db.debuffMouseover and A.DebuffFrame then
		SetupFader(A.DebuffFrame, db.debuffMouseoverAlpha or 0)
	end
end
