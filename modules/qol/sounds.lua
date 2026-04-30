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
