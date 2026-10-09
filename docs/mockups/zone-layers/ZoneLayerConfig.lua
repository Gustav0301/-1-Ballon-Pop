--!strict
-- ZoneLayerConfig: how every sky zone looks. One entry per zone; a new zone just adds an entry.
-- Made from tools/zones/zones.py (the preview uses the same numbers). Colours are hex like in the plan.
-- Sky: Lighting + Atmosphere + ColorCorrection + Terrain clouds. Clouds: stud clouds around you.
-- Near: small bits that fly past you (0 = off, 1 = normal). Weather plays on top of this.

local ZoneLayerConfig = {}

ZoneLayerConfig.Zones = { {
	Id = "MeadowSky",
	Name = "MEADOW SKY",
	From = 0,
	To = 500,
	Sky = {
		Brightness = 3.0,
		ClockTime = 13.6,
		Exposure = 0.0,
		Ambient = Color3.fromHex("7680A0"),
		OutdoorAmbient = Color3.fromHex("98A6C0"),
		SkyTop = Color3.fromHex("3FA9F5"),
		Horizon = Color3.fromHex("D4F0FF"),
		Sun = Color3.fromHex("FFF6C9"),
		AtmosColor = Color3.fromHex("D4F0FF"),
		AtmosDecay = Color3.fromHex("6EAEE8"),
		AtmosDensity = 0.2,
		AtmosHaze = 0.5,
		AtmosGlare = 0.3,
		AtmosOffset = 0.2,
		Tint = Color3.fromHex("FFFBF4"),
		Saturation = 0.18,
		Contrast = 0.06,
		CCBrightness = 0.02,
		SunSize = 14,
		CloudCover = 0.52,
		CloudDensity = 0.45,
		CloudColor = Color3.fromHex("FFFFFF"),
	},
	Clouds = {
		Kind = "Puffy",
		Count = 24,
		MinY = 90,
		MaxY = 430,
		Ring = { 120, 520 },
		Drift = Vector3.new(3.0, 0, 0.6),
		Top = Color3.fromHex("FFFFFF"),
		Side = Color3.fromHex("F2F7FF"),
		Bottom = Color3.fromHex("BCD0EA"),
	},
	Near = {
		Petals = 1.0,
		Pollen = 1.0,
		Mist = 0.0,
		Dust = 0.0,
		PetalColors = { Color3.fromHex("FF8FB8"), Color3.fromHex("FFE066"), Color3.fromHex("FFFFFF"), Color3.fromHex("FFB0D0") },
	},
}, {
	Id = "CloudShelf",
	Name = "CLOUD SHELF",
	From = 500,
	To = 1500,
	Sky = {
		Brightness = 3.5,
		ClockTime = 14.2,
		Exposure = 0.05,
		Ambient = Color3.fromHex("8C7E70"),
		OutdoorAmbient = Color3.fromHex("C0A68C"),
		SkyTop = Color3.fromHex("1F6FD1"),
		Horizon = Color3.fromHex("FFD9A0"),
		Sun = Color3.fromHex("FFE08A"),
		AtmosColor = Color3.fromHex("FFD9A0"),
		AtmosDecay = Color3.fromHex("3F7FD6"),
		AtmosDensity = 0.24,
		AtmosHaze = 1.0,
		AtmosGlare = 0.75,
		AtmosOffset = 0.12,
		Tint = Color3.fromHex("FFF0DA"),
		Saturation = 0.24,
		Contrast = 0.08,
		CCBrightness = 0.03,
		SunSize = 19,
		CloudCover = 0.25,
		CloudDensity = 0.3,
		CloudColor = Color3.fromHex("FFF2DC"),
	},
	Clouds = {
		Kind = "Cloudlets",
		Count = 30,
		MinY = 560,
		MaxY = 1450,
		Ring = { 90, 420 },
		Drift = Vector3.new(1.6, 0, 0.4),
		Top = Color3.fromHex("FFF4DE"),
		Side = Color3.fromHex("FFFFFF"),
		Bottom = Color3.fromHex("E9D7C0"),
	},
	Near = {
		Petals = 0.0,
		Pollen = 0.0,
		Mist = 1.0,
		Dust = 1.0,
		PetalColors = {  },
	},
} }

-- The cloud deck between Meadow Sky and Cloud Shelf (Y is its middle). No collision: you fly through it.
ZoneLayerConfig.Deck = {
	Y = 500,
	Thickness = 40,
	Tile = 64,
	Radius = 448,
	ActiveRange = 800,
	BuildPerFrame = 10,
	Coverage = 0.88,
	IslandHole = 26,
	IslandBand = 60,
	Top = Color3.fromHex("FFFFFF"),
	TopGold = Color3.fromHex("FFF0D2"),
	Side = Color3.fromHex("F6F9FF"),
	Bottom = Color3.fromHex("CFDCF0"),
	Seed = 7,
	SeaY = 512,
	SeaOuter = 2048,
	Sea = Color3.fromHex("FFF8EE"),
}

ZoneLayerConfig.Towers = {
	Count = 7,
	Distance = { 1100, 1700 },
	Height = { 180, 420 },
	Width = { 90, 160 },
}

ZoneLayerConfig.Blend = {
	Below = 100,
	Above = 30,
}

ZoneLayerConfig.Punch = {
	MistDensity = 0.62,
	FlashBrightness = 0.18,
	FlashTime = 0.5,
	Whoosh = "Launch",
	WhooshPitch = 0.75,
}

ZoneLayerConfig.Studs = {
	On = true,
	Texture = "rbxassetid://6927295847",
	Tile = 4,
	Transparency = 0.55,
}

ZoneLayerConfig.Near = {
	Max = 40,
}

ZoneLayerConfig.Islands = {
	Folders = { "SkyIslands" },
	Margin = 6,
}

return ZoneLayerConfig
