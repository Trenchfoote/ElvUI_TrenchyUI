local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local UF = E:GetModule('UnitFrames')

local hooksecurefunc = hooksecurefunc
local IsFlying = IsFlying

local sfOverridden = false

local function IsSteadyFlightEnabled()
	local db = TUI.db and TUI.db.profile and TUI.db.profile.fader
	return db and db.steadyFlight
end

local function GetPlayerFaderDB()
	return E.db and E.db.unitframe and E.db.unitframe.units
		and E.db.unitframe.units.player and E.db.unitframe.units.player.fader
end

function TUI:InitSteadyFlight()
	C_Timer.After(0, function()
		local playerFrame = _G.ElvUF_Player
		if not playerFrame then return end

		-- Fix fader count if Configure_Fader runs while we've suppressed DynamicFlight
		hooksecurefunc(UF, 'Configure_Fader', function(_, frame)
			if frame ~= playerFrame or not sfOverridden then return end
			local fader = frame.Fader
			if fader and fader.DynamicFlight and fader.count and fader.count > 0 then
				fader.count = fader.count - 1
			end
			sfOverridden = false
		end)

		-- Poll IsFlying() and suppress the DynamicFlight condition while airborne
		C_Timer.NewTicker(0.2, function()
			if not playerFrame.Fader then return end

			local faderDB = GetPlayerFaderDB()
			local dbEnabled = faderDB and faderDB.dynamicflight

			-- Restore if our feature or DynamicFlight was turned off
			if not IsSteadyFlightEnabled() or not dbEnabled then
				if sfOverridden then
					sfOverridden = false
					playerFrame.Fader.DynamicFlight = dbEnabled or nil
					playerFrame.Fader:ForceUpdate()
				end
				return
			end

			local flying = IsFlying()
			if flying and not sfOverridden then
				playerFrame.Fader.DynamicFlight = false
				sfOverridden = true
				playerFrame.Fader:ForceUpdate()
			elseif not flying and sfOverridden then
				playerFrame.Fader.DynamicFlight = true
				sfOverridden = false
				playerFrame.Fader:ForceUpdate()
			end
		end)
	end)
end
