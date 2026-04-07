local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')

function TUI:InitModules()
	-- Force value color to current class
	local cc = E:ClassColor(E.myclass)
	if cc and E.db.general.valuecolor then
		E.db.general.valuecolor.r = cc.r
		E.db.general.valuecolor.g = cc.g
		E.db.general.valuecolor.b = cc.b
	end

	-- Borders
	if self.db.profile.borderMode and self.InitBorderMode then self:InitBorderMode() end

	-- Skins
	if self.InitSkinWarpDeplete then self:InitSkinWarpDeplete() end
	if self.InitSkinBigWigs then self:InitSkinBigWigs() end
	if self.InitSkinAuctionator then self:InitSkinAuctionator() end
	if self.InitSkinBugSack then self:InitSkinBugSack() end
	if self.InitSkinOPie then self:InitSkinOPie() end
	if self.InitSkinPlatynator then self:InitSkinPlatynator() end
	if self.InitSkinPremadeGroupsFilter then self:InitSkinPremadeGroupsFilter() end

	-- QoL
	local db = self.db.profile.qol
	if db.hideTalkingHead then self:InitHideTalkingHead() end
	if db.autoFillDelete then self:InitAutoFillDelete() end
	if db.difficultyText then self:InitDifficultyText() end
	if db.fastLoot then self:InitFastLoot() end
	if db.moveableFrames and not self:IsCompatBlocked('moveableFrames') then self:InitMoveableFrames() end
	if db.hideObjectiveInCombat then self:InitHideObjectiveInCombat() end
	if self.InitMinimapButtonBar then self:InitMinimapButtonBar() end
	if db.cursorCircle then self:InitCursorCircle() end
	if db.shortenEnchantStrings and self.InitEnchantStrings then self:InitEnchantStrings() end

	-- Nameplates (skip entirely if ElvUI nameplates are disabled)
	local np = self.db.profile.nameplates
	if np and E.private.nameplates.enable then
		if np.hideFriendlyRealm then self:InitHideFriendlyRealm() end
		-- Override target indicator color with player's class color
		self:HookClassColorTargetIndicator()
		if np.interruptCastbarColors then self:HookCastbarInterrupt() end
		-- Pending removal based on ElvUI updates
		if np.focusGlow and np.focusGlow.enabled then self:InitFocusGlow() end
		if np.importantCast and np.importantCast.enabled then self:HookImportantCast() end
		if np.hoverHighlight and np.hoverHighlight.enabled then self:HookHoverHighlight() end
		if np.disableFriendlyHighlight then self:HookDisableFriendlyHighlight() end
		if np.questColor and np.questColor.enabled then self:HookQuestColor() end
	end

	-- Platynator tweaks (independent of ElvUI nameplates)
	if E:IsAddOnEnabled('Platynator') then self:InitPlatynatorTweaks() end

	-- Unit Frames
	if self.db.profile.tankPower and self.InitTankPower then self:InitTankPower() end
	if not self:IsCompatBlocked('auraHighlight') and self.InitPixelGlow then self:InitPixelGlow() end
	if self.InitEvokerEssenceCharge then self:InitEvokerEssenceCharge() end
	if self.InitSteadyFlight then self:InitSteadyFlight() end
	if self.InitRaidRoleFilter then self:InitRaidRoleFilter() end

	-- Cooldown Manager
	if not self:IsCompatBlocked('cooldownManager') and self.InitCooldownManager then self:InitCooldownManager() end

	-- Damage Meter
	if not self:IsCompatBlocked('damageMeter') and self.InitDamageMeter then self:InitDamageMeter() end
end
