local E = unpack(ElvUI)
local QOL = E:GetModule('TUI_QoL')

local MuteSoundFile = MuteSoundFile
local UnmuteSoundFile = UnmuteSoundFile

-- Each entry: db key under qol.muteSounds, label, FileDataIDs to mute
QOL.MUTE_SOUND_ENTRIES = {
	{
		key = 'gazeOfAlnseer',
		label = 'Gaze of the Alnseer',
		fdids = { 2144789, 2144790, 2144791, 2026452, 2026453 },
	},
	{
		key = 'banLu',
		label = "Ban-Lu (Monk Mount)",
		fdids = {
			1593212, 1593213, 1593214, 1593215, 1593216, 1593217, 1593218, 1593219,
			1593220, 1593221, 1593222, 1593223, 1593224, 1593225, 1593226, 1593227,
			1593228, 1593229, 1593230, 1593231, 1593232, 1593233, 1593234, 1593235,
			1593236,
			1604691, 1604692, 1604693, 1604694, 1604695, 1604696, 1604697, 1604698, 1604699, 1604700,
			1604683, 1604684, 1604685, 1604717, 1604718, 1604719, 1604720, 1604721, 1604722, 1604723,
			1604686, 1604687, 1604688, 1604689, 1604690,
		},
	},
}

local function GetMuteDB()
	local TUI = E:GetModule('TrenchyUI')
	return TUI.db and TUI.db.profile and TUI.db.profile.qol and TUI.db.profile.qol.muteSounds
end

function QOL:RefreshMutedSounds()
	local db = GetMuteDB()
	if not db then return end
	for _, entry in ipairs(QOL.MUTE_SOUND_ENTRIES) do
		local enabled = db[entry.key]
		for _, fdid in ipairs(entry.fdids) do
			if enabled then
				MuteSoundFile(fdid)
			elseif UnmuteSoundFile then
				UnmuteSoundFile(fdid)
			end
		end
	end
end

function QOL:InitMutedSounds()
	QOL:RefreshMutedSounds()
end
