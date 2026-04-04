local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')

local ipairs = ipairs

local function ApplyBarColors()
	local warpDeplete = _G['WarpDeplete']
	if not warpDeplete then return end

	local mode = TUI.db and TUI.db.profile.colorMode or 'dark'
	local cr, cg, cb = TUI:GetClassColor()
	if not cr then return end

	local fgR, fgG, fgB, bgR, bgG, bgB
	if mode == 'dark' then
		bgR, bgG, bgB = cr, cg, cb
	else
		fgR, fgG, fgB = cr, cg, cb
		bgR, bgG, bgB = 0.173, 0.173, 0.173
	end

	if warpDeplete.bars then
		for _, bar in ipairs(warpDeplete.bars) do
			if bar.frame and bar.frame.SetBackdropColor then
				bar.frame:SetBackdropColor(bgR, bgG, bgB, 1)
			end
			if fgR and bar.bar then
				bar.bar:SetStatusBarColor(fgR, fgG, fgB, 1)
			end
		end
	end

	if warpDeplete.forces then
		if warpDeplete.forces.frame and warpDeplete.forces.frame.SetBackdropColor then
			warpDeplete.forces.frame:SetBackdropColor(bgR, bgG, bgB, 1)
		end
		if fgR and warpDeplete.forces.bar then
			warpDeplete.forces.bar:SetStatusBarColor(fgR, fgG, fgB, 1)
		end
	end
end

function TUI:InitSkinWarpDeplete()
	local warpDeplete = _G['WarpDeplete']
	if not warpDeplete or not warpDeplete.RenderLayout then return end
	if not self.db or not self.db.profile.addons or not self.db.profile.addons.skinWarpDeplete then return end

	hooksecurefunc(warpDeplete, 'RenderLayout', ApplyBarColors)
end
