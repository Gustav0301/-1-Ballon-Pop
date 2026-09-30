--!strict
-- SoundConfig: every sound in the game. Paste an asset id into Id ("rbxassetid://123")
-- and it plays; empty ids are silent, so nothing breaks before sounds are uploaded.
-- The matching generated files are in sounds/ (see docs/SOUNDS.md for uploading).

export type Sound = { Id: string, Volume: number, Pitch: number?, Vary: number?, Loop: boolean? }

local SoundConfig = {}

-- stylua: ignore
SoundConfig.Sounds = {
	-- flying
	Launch    = { Id = "", Volume = 0.6, Vary = 0.05 },  -- whoosh + stretchy inflate when you take off
	Tick      = { Id = "", Volume = 0.18, Vary = 0.0 },  -- soft coin tick while unbanked coins grow (pitch rises with size)
	LetOut    = { Id = "", Volume = 0.35, Loop = true }, -- air hissing out while you hold Space
	LandStart = { Id = "", Volume = 0.5 },               -- landing started
	Bank      = { Id = "", Volume = 0.7 },               -- coins cascading into the counter
	CoinIn    = { Id = "", Volume = 0.25, Vary = 0.12 }, -- each coin of the fountain arriving
	Max       = { Id = "", Volume = 0.55 },              -- hit max size
	Hit       = { Id = "", Volume = 0.7, Vary = 0.08 },  -- your balloon got hit
	Pop       = { Id = "", Volume = 0.9, Vary = 0.1 },   -- a balloon pops (3D, bigger = lower)
	Fall      = { Id = "", Volume = 0.45 },              -- falling whistle after a pop
	-- menus
	Click     = { Id = "", Volume = 0.45, Vary = 0.05 },
	Open      = { Id = "", Volume = 0.45 },
	Close     = { Id = "", Volume = 0.4 },
	Buy       = { Id = "", Volume = 0.6 },
	Upgrade   = { Id = "", Volume = 0.6 },
	Equip     = { Id = "", Volume = 0.5 },
	Error     = { Id = "", Volume = 0.45 },
	Teleport  = { Id = "", Volume = 0.5 },
	Restock   = { Id = "", Volume = 0.45 },
	Fanfare   = { Id = "", Volume = 0.6 },               -- a Legendary / Mythic is in stock
	-- music (crossfades between the two)
	MusicGround = { Id = "", Volume = 0.3, Loop = true },
	MusicSky    = { Id = "", Volume = 0.3, Loop = true },
} :: { [string]: Sound }

SoundConfig.MusicFade = 2.5 -- seconds to crossfade between ground and sky music
SoundConfig.SkyMusicAbove = 60 -- studs above the grass where the sky music takes over

return SoundConfig
