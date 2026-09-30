--!strict
-- SoundConfig: every sound in the game. Paste an asset id into Id ("rbxassetid://123", or
-- just the number) and it plays; empty ids are silent, so nothing breaks before sounds are uploaded.
-- The matching generated files are in sounds/ (see docs/SOUNDS.md for uploading).

export type Sound = { Id: string, Volume: number, Pitch: number?, Vary: number?, Loop: boolean? }

local SoundConfig = {}

-- stylua: ignore
SoundConfig.Sounds = {
	-- flying
	Launch    = { Id = "rbxassetid://136103370782858", Volume = 0.6, Vary = 0.05 },  -- whoosh + stretchy inflate when you take off
	Tick      = { Id = "rbxassetid://119382422981870", Volume = 0.18, Vary = 0.0 },  -- soft coin tick while unbanked coins grow (pitch rises with size)
	LetOut    = { Id = "rbxassetid://134446458417184", Volume = 0.35, Loop = true }, -- air hissing out while you hold Space
	LandStart = { Id = "rbxassetid://119094332530085", Volume = 0.5 },               -- landing started
	Bank      = { Id = "rbxassetid://90569499809182", Volume = 0.7 },               -- coins cascading into the counter
	CoinIn    = { Id = "rbxassetid://75035169858942", Volume = 0.25, Vary = 0.12 }, -- each coin of the fountain arriving
	Max       = { Id = "rbxassetid://89311425663950", Volume = 0.55 },              -- hit max size
	Hit       = { Id = "rbxassetid://116799188637243", Volume = 0.7, Vary = 0.08 },  -- your balloon got hit
	Pop       = { Id = "rbxassetid://123423924337507", Volume = 0.9, Vary = 0.1 },   -- a balloon pops (3D, bigger = lower)
	Fall      = { Id = "rbxassetid://96098387921473", Volume = 0.45 },              -- falling whistle after a pop
	-- menus
	Click     = { Id = "rbxassetid://114026742115835", Volume = 0.45, Vary = 0.05 },
	Open      = { Id = "rbxassetid://99023710891961", Volume = 0.45 },
	Close     = { Id = "rbxassetid://106227854099124", Volume = 0.4 },
	Buy       = { Id = "rbxassetid://77206626670912", Volume = 0.6 },
	Upgrade   = { Id = "rbxassetid://117546447030019", Volume = 0.6 },
	Equip     = { Id = "rbxassetid://140464443530220", Volume = 0.5 },
	Error     = { Id = "rbxassetid://76233791592532", Volume = 0.45 },
	Teleport  = { Id = "rbxassetid://100498652817291", Volume = 0.5 },
	Restock   = { Id = "rbxassetid://97548889984274", Volume = 0.45 },
	Fanfare   = { Id = "rbxassetid://113238965811791", Volume = 0.6 },               -- a Legendary / Mythic is in stock
	-- music (crossfades between the two)
	MusicGround = { Id = "rbxassetid://81177147149735", Volume = 0.3, Loop = true },
	MusicSky    = { Id = "rbxassetid://81177147149735", Volume = 0.3, Loop = true },
} :: { [string]: Sound }

SoundConfig.MusicFade = 2.5 -- seconds to crossfade between ground and sky music
SoundConfig.SkyMusicAbove = 60 -- studs above the grass where the sky music takes over

return SoundConfig
