local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local UF = E:GetModule('UnitFrames')

local DARK_GREY = { r = 0.17254902422428, g = 0.17254902422428, b = 0.17254902422428 }
local CASTBAR_DARK = { r = 0.14117647707462, g = 0.14117647707462, b = 0.14117647707462 }

local OVERRIDE_UNITS = {
	'arena', 'assist', 'boss', 'focus', 'party', 'pet', 'player',
	'raid1', 'raid2', 'raid3', 'tank', 'target', 'targettarget',
}

-- Custom text entries that use [classcolor] in dark mode
local CLASS_COLOR_TEXTS = {
	{ 'focus',  'T-FocusName' },
	{ 'party',  'T-PartyHealth' },
	{ 'party',  'T-PartyName' },
	{ 'pet',    'T-PetName' },
	{ 'player', 'T-Health' },
	{ 'raid1',  'T-RaidHealth' },
	{ 'raid1',  'T-RaidName' },
	{ 'tank',   'T-TankName' },
	{ 'target', 'T-THealth' },
	{ 'target', 'T-TName' },
}

function TUI:ApplyColorMode(mode)
	local isDark = mode == 'dark'
	local colors = E.db.unitframe.colors
	local tdb = TUI.db.profile
	tdb.colorMode = mode

	-- UF health color override
	for _, unit in ipairs(OVERRIDE_UNITS) do
		local unitDB = E.db.unitframe.units[unit]
		if unitDB then
			unitDB.colorOverride = isDark and 'FORCE_OFF' or 'FORCE_ON'
		end
	end

	-- Backdrop: dark = class color, color = custom dark grey
	colors.classbackdrop = isDark
	colors.customhealthbackdrop = not isDark
	if not isDark then
		colors.health_backdrop.r = DARK_GREY.r
		colors.health_backdrop.g = DARK_GREY.g
		colors.health_backdrop.b = DARK_GREY.b
	end

	-- Custom text [classcolor] tags
	for _, entry in ipairs(CLASS_COLOR_TEXTS) do
		local unit, name = entry[1], entry[2]
		local ct = E.db.unitframe.units[unit] and E.db.unitframe.units[unit].customTexts
		if ct and ct[name] then
			local text = ct[name].text_format
			if text then
				if isDark then
					if not text:find('%[classcolor%]') then
						ct[name].text_format = '[classcolor]' .. text
					end
				else
					ct[name].text_format = text:gsub('%[classcolor%]', '')
				end
			end
		end
	end

	-- Player castbar colors
	local cb = E.db.unitframe.units.player and E.db.unitframe.units.player.castbar
	if cb and cb.customColor then
		local cc = E:ClassColor(E.myclass)
		if cc then
			local cust = cb.customColor
			if isDark then
				cust.color.r, cust.color.g, cust.color.b = CASTBAR_DARK.r, CASTBAR_DARK.g, CASTBAR_DARK.b
				cust.colorBackdrop.r, cust.colorBackdrop.g, cust.colorBackdrop.b = cc.r, cc.g, cc.b
				cb.textColor.r, cb.textColor.g, cb.textColor.b = cc.r, cc.g, cc.b
			else
				cust.color.r, cust.color.g, cust.color.b = cc.r, cc.g, cc.b
				cust.colorBackdrop.r, cust.colorBackdrop.g, cust.colorBackdrop.b = CASTBAR_DARK.r, CASTBAR_DARK.g, CASTBAR_DARK.b
				cb.textColor.r, cb.textColor.g, cb.textColor.b = 1, 1, 1
			end
		end
	end

	-- TDM bar colors
	if tdb.damageMeter then
		tdb.damageMeter.barClassColor = not isDark
		tdb.damageMeter.barBGClassColor = isDark
		tdb.damageMeter.textClassColor = isDark
	end

	-- TDM class icon backgrounds
	local tdm = TUI._tdm
	if tdm and tdm.windows and tdb.damageMeter and tdb.damageMeter.showClassIcon then
		local showBG = not isDark
		for _, win in pairs(tdm.windows) do
			if win.bars then
				for _, bar in pairs(win.bars) do
					if bar.classIconBG then
						if showBG then bar.classIconBG:Show() else bar.classIconBG:Hide() end
					end
				end
			end
		end
	end

	-- Refresh UFs and TDM
	UF:Update_AllFrames()
	if TUI.RefreshMeter then TUI:RefreshMeter() end

	-- Refresh WarpDeplete bars
	local wd = _G['WarpDeplete']
	if wd and wd.RenderLayout then wd:RenderLayout() end

	local modeText = isDark and 'dark' or 'color'
	E:Print('|cffff2f3dTrenchyUI|r: Switched to ' .. modeText .. ' mode.')
end

SLASH_TRENCHYAFTERDARK1 = '/trenchyafterdark'
SlashCmdList['TRENCHYAFTERDARK'] = function()
	TUI:ApplyColorMode('dark')
end

SLASH_TRENCHYINCOLOR1 = '/trenchyincolor'
SlashCmdList['TRENCHYINCOLOR'] = function()
	TUI:ApplyColorMode('color')
end
