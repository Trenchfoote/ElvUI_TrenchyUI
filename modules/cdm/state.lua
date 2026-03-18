local E = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local LCG = LibStub('LibCustomGlow-1.0', true)
local LSM = E.Libs.LSM

TUI._cdm = {}
local S = TUI._cdm

S.LCG = LCG
S.LSM = LSM

S.VIEWER_KEYS = {
	essential = { global = 'EssentialCooldownViewer', label = 'Essential CDs',  mover = 'TUI_CDM_Essential' },
	utility   = { global = 'UtilityCooldownViewer',  label = 'Utility CDs',    mover = 'TUI_CDM_Utility' },
	buffIcon  = { global = 'BuffIconCooldownViewer', label = 'Buff Icon CDs',  mover = 'TUI_CDM_BuffIcon' },
	buffBar   = { global = 'BuffBarCooldownViewer',  label = 'Buff Bar CDs',   mover = 'TUI_CDM_BuffBar' },
	custom    = { global = nil,                      label = 'Custom Tracker',  mover = 'TUI_CDM_Custom' },
}

-- Shared mutable state
S.containers = {}
S.styledFrames = {}
S.glowActive = {}
S.previewActive = false
S.inCombat = false
S.configOpen = false
S.hookedAlerts = {}
S.hookedSwipes = {}
S.hookedViewers = {}
S.iconCache = {}
S.containerDirty = {}
S.moverToViewer = {}

S.sortFunc = function(a, b) return (a.layoutIndex or 0) < (b.layoutIndex or 0) end

-- DB helpers
function S.GetDB()
	return TUI.db and TUI.db.profile and TUI.db.profile.cooldownManager
end

function S.GetViewerDB(viewerKey)
	local db = S.GetDB()
	return db and db.viewers and db.viewers[viewerKey]
end

function S.GetViewer(viewerKey)
	local info = S.VIEWER_KEYS[viewerKey]
	return info and _G[info.global]
end

-- Per-spell glow DB helpers
S.SPELL_GLOW_DEFAULTS = { enabled = false, type = 'pixel', color = { r = 0.95, g = 0.95, b = 0.32, a = 1 }, lines = 8, speed = 0.25, thickness = 2, particles = 4, scale = 1 }

function S.GetSpellGlowDB(spellID)
	local db = S.GetDB()
	return db and db.spellGlow and db.spellGlow[spellID]
end

function S.GetOrCreateSpellGlowDB(spellID)
	local db = S.GetDB()
	if not db then return nil end
	if not db.spellGlow then db.spellGlow = {} end
	if not db.spellGlow[spellID] then
		local d = S.SPELL_GLOW_DEFAULTS
		db.spellGlow[spellID] = { enabled = d.enabled, type = d.type, color = { r = d.color.r, g = d.color.g, b = d.color.b, a = d.color.a }, lines = d.lines, speed = d.speed, thickness = d.thickness, particles = d.particles, scale = d.scale }
	end
	return db.spellGlow[spellID]
end

-- Per-spell bar color helpers
S.SPELL_BAR_COLOR_DEFAULTS = { enabled = false, fgColor = { r = 0.2, g = 0.6, b = 1 }, bgColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.5 } }

function S.GetSpellBarColorDB(spellID)
	local db = S.GetDB()
	return db and db.spellBarColor and db.spellBarColor[spellID]
end

function S.GetOrCreateSpellBarColorDB(spellID)
	local db = S.GetDB()
	if not db then return nil end
	if not db.spellBarColor then db.spellBarColor = {} end
	if not db.spellBarColor[spellID] then
		local d = S.SPELL_BAR_COLOR_DEFAULTS
		db.spellBarColor[spellID] = { enabled = d.enabled, fgColor = { r = d.fgColor.r, g = d.fgColor.g, b = d.fgColor.b }, bgColor = { r = d.bgColor.r, g = d.bgColor.g, b = d.bgColor.b, a = d.bgColor.a } }
	end
	return db.spellBarColor[spellID]
end
