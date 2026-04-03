local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')

local ipairs = ipairs

local function ApplyBarClassColors()
	local r, g, b = TUI:GetClassColor()
	if not r then return end
	local warpDeplete = _G['WarpDeplete']
	if not warpDeplete then return end

	if warpDeplete.bars then
		for _, bar in ipairs(warpDeplete.bars) do
			if bar.frame and bar.frame.SetBackdropColor then
				bar.frame:SetBackdropColor(r, g, b, 1)
			end
		end
	end

	if warpDeplete.forces and warpDeplete.forces.frame and warpDeplete.forces.frame.SetBackdropColor then
		warpDeplete.forces.frame:SetBackdropColor(r, g, b, 1)
	end
end

function TUI:InitSkinWarpDeplete()
	local warpDeplete = _G['WarpDeplete']
	if not warpDeplete or not warpDeplete.RenderLayout then return end
	if not self.db or not self.db.profile.addons or not self.db.profile.addons.skinWarpDeplete then return end

	hooksecurefunc(warpDeplete, 'RenderLayout', ApplyBarClassColors)
end
