local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local SKN = E:NewModule('TUI_Skins', 'AceEvent-3.0')

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

local function AddSlugToFont(fontString)
	if not fontString then return end
	local font, size, flags = fontString:GetFont()
	if not font or not flags then return end
	if flags:find('SLUG') then return end
	local newFlags = flags == '' and 'SLUG' or ('SLUG, ' .. flags)
	fontString:SetFont(font, size, newFlags)
end

local function ApplySlugToWD()
	local wd = _G['WarpDeplete']
	if not wd then return end

	if wd.timerText then AddSlugToFont(wd.timerText) end
	if wd.timerSplitText then AddSlugToFont(wd.timerSplitText) end
	if wd.deathsText then AddSlugToFont(wd.deathsText) end
	if wd.keyText then AddSlugToFont(wd.keyText) end
	if wd.keyDetailsText then AddSlugToFont(wd.keyDetailsText) end

	if wd.bars then
		for _, bar in ipairs(wd.bars) do
			if bar.text then AddSlugToFont(bar.text) end
		end
	end
	if wd.forces and wd.forces.text then AddSlugToFont(wd.forces.text) end

	if wd.objectiveTexts then
		for _, text in ipairs(wd.objectiveTexts) do
			AddSlugToFont(text)
		end
	end
end

function SKN:InitSkinWarpDeplete()
	local warpDeplete = _G['WarpDeplete']
	if not warpDeplete or not warpDeplete.RenderLayout then return end

	local addons = TUI.db and TUI.db.profile.addons
	if not addons then return end

	if addons.skinWarpDeplete then
		hooksecurefunc(warpDeplete, 'RenderLayout', ApplyBarColors)
	end

	if addons.slugWarpDeplete then
		hooksecurefunc(warpDeplete, 'RenderLayout', ApplySlugToWD)
	end
end
