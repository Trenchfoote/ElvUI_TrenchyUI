local E = unpack(ElvUI)
local UFC = E:GetModule('TUI_UnitFrames')
local UF = E:GetModule('UnitFrames')

local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitPartialPower = UnitPartialPower

local POWERTYPE_ESSENCE = Enum.PowerType.Essence or 19
local RESYNC_INTERVAL = 0.15

local function StopEssenceSmoothing(bars)
	bars._tuiEssenceActive = nil
	bars._tuiEssenceFillBar = nil
	bars._tuiEssenceElapsed = 0
end

-- Partial essence as 0-1; UnitPartialPower is non-secret so safe to scale while tainted (the regen rate is secret)
local function EssencePartialFill()
	local partial = UnitPartialPower('player', POWERTYPE_ESSENCE) or 0
	if partial < 0 then partial = 0
	elseif partial > 1000 then partial = 1000 end
	return partial * 0.001
end

local function RefreshEssenceChargeBar(bars)
	if not bars or not bars.IsShown or not bars:IsShown() then
		StopEssenceSmoothing(bars)
		return
	end

	local frame = bars.origParent or bars:GetParent()
	if not frame or frame.unit ~= 'player' or frame.ClassBar ~= 'ClassPower' then
		StopEssenceSmoothing(bars)
		return
	end

	local current = UnitPower('player', POWERTYPE_ESSENCE) or 0
	local maximum = UnitPowerMax('player', POWERTYPE_ESSENCE) or 0
	if maximum == 0 or current >= maximum then
		StopEssenceSmoothing(bars)
		return
	end

	local fillBar = bars[current + 1]
	if not fillBar or not fillBar:IsShown() then
		StopEssenceSmoothing(bars)
		return
	end

	fillBar:SetValue(EssencePartialFill())

	bars._tuiEssenceActive = true
	bars._tuiEssenceFillBar = fillBar
end

local function EssenceChargeOnUpdate(bars, elapsed)
	if not bars._tuiEssenceActive then return end

	local fillBar = bars._tuiEssenceFillBar
	if not fillBar or not fillBar:IsShown() then
		StopEssenceSmoothing(bars)
		return
	end

	-- Poll partial power each frame; the old regen-rate interpolation is gone (regen is secret in 12.x, tainted math errors)
	fillBar:SetValue(EssencePartialFill())

	bars._tuiEssenceElapsed = (bars._tuiEssenceElapsed or 0) + elapsed
	if bars._tuiEssenceElapsed >= RESYNC_INTERVAL then
		bars._tuiEssenceElapsed = 0
		RefreshEssenceChargeBar(bars)
	end
end

function UFC:InitEvokerEssenceCharge()
	if self._hookedEvokerEssenceCharge then return end
	self._hookedEvokerEssenceCharge = true

	if not E.Retail or E.myclass ~= 'EVOKER' then return end

	hooksecurefunc(UF, 'UpdateClassBar', function(bars, _, _, _, powerType)
		if not bars then return end

		if not bars._tuiEssenceHooked then
			bars._tuiEssenceHooked = true
			bars:HookScript('OnUpdate', EssenceChargeOnUpdate)
			bars:HookScript('OnHide', StopEssenceSmoothing)
		end

		if powerType and powerType ~= 'ESSENCE' then
			StopEssenceSmoothing(bars)
			return
		end

		RefreshEssenceChargeBar(bars)
	end)
end
