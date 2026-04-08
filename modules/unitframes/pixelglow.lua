local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local UFC = E:GetModule('TUI_UnitFrames')
local UF = E:GetModule('UnitFrames')

local LCG = E.Libs.CustomGlow
local GLOW_KEY = 'TUI_PixelGlow'
local GLOW_FRAME_KEY = '_PixelGlow' .. GLOW_KEY
local glowColor = { 1, 1, 1, 1 }

local function GetPixelGlowDB()
	local db = TUI.db and TUI.db.profile and TUI.db.profile.pixelGlow
	if not db then return false, 8, 0.25, 2 end
	return db.enabled, db.lines, db.speed, db.thickness
end

function UFC:InitPixelGlow()
	local enabled = GetPixelGlowDB()
	if not enabled then return end
	if not LCG or not LCG.PixelGlow_Start then return end

	hooksecurefunc(UF, 'PostUpdate_AuraHighlight', function(_, frame, _, aura, _, _, wasFiltered)
		if wasFiltered or not frame then return end
		local element = frame.AuraHighlight
		if not element then return end

		local r, g, b, a = element:GetVertexColor()
		element:SetVertexColor(0, 0, 0, 0)
		if frame.AuraHightlightGlow then frame.AuraHightlightGlow:Hide() end

		local target = frame.Health or frame
		if not aura then
			LCG.PixelGlow_Stop(target, GLOW_KEY)
			return
		end

		local _, lines, speed, thickness = GetPixelGlowDB()
		glowColor[1], glowColor[2], glowColor[3] = r, g, b
		LCG.PixelGlow_Start(target, glowColor, lines, speed, nil, thickness, 0, 0, false, GLOW_KEY)
		local gf = target[GLOW_FRAME_KEY]
		if gf then gf:SetAlpha(a) end
	end)
end
