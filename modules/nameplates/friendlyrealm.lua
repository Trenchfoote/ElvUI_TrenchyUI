local E = unpack(ElvUI)
local NPS = E:GetModule('TUI_Nameplates')

function NPS:InitHideFriendlyRealm()
	if not NamePlateFriendlyFrameOptions or not TextureLoadingGroupMixin then return end
	if not NamePlateFriendlyFrameOptions.updateNameUsesGetUnitName then return end

	local wrapper = { textures = NamePlateFriendlyFrameOptions }
	NamePlateFriendlyFrameOptions.updateNameUsesGetUnitName = 0
	TextureLoadingGroupMixin.RemoveTexture(wrapper, 'updateNameUsesGetUnitName')
end
