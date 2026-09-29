--!strict
-- HazardConfig: every tunable number for the first-island hazards
-- (Meadow Sky + Cloud Shelf). Starting values, tune freely.
--
-- Timing fields are seconds from the start of an attack:
--   LockTime  when the server locks the aim point (dodge window starts)
--   HitTime   when the server checks for a hit and fires HazardService.Hit
--   Recover   how long the hazard keeps moving after the hit before it resumes

local HazardConfig = {}

HazardConfig.GroundY = 0 -- world Y of the grass start map; zone heights are measured from here

HazardConfig.Global = {
	TickRate = 1 / 20, -- server AI tick
	SpawnInterval = 3, -- seconds between spawn checks per player
	MaxPerPlayer = 3, -- hazards hunting one balloon at once
	SpawnRadius = 90, -- studs from the balloon where hazards appear
	DespawnDistance = 260, -- hazards give up past this distance
	SwatRange = 12, -- riders' swatter range for HazardService.Swat
	VisibleDistance = 450, -- clients skip animating rigs further than this
	ShakeDistance = 70, -- camera shake falls off to zero at this distance
}

HazardConfig.Zones = {
	MeadowSky = { Min = 0, Max = 500 },
	CloudShelf = { Min = 500, Max = 1500 },
}

-- Demo mode: gives every player a stud balloon over their head (HP = its Toughness), builds
-- the balloon gallery by the spawn, and spawns one of each hazard in turn at any height,
-- so every attack and balloon can be seen in an empty place.
HazardConfig.Demo = {
	Enabled = false, -- the bootstrap scripts can switch this on
	Kinds = { "Sparrow", "Plane", "Pinwheel", "Nimbo" },
	BalloonHP = 3, -- fallback when a balloon type has no Toughness
	RespawnDelay = 3,
	StringLength = 4.5, -- studs of string between the hand and the balloon's knot
}

export type HazardType = {
	Zone: string,
	MinHeight: number,
	MaxHeight: number,
	Weight: number,
	Damage: number,
	Cooldown: number,
	LockTime: number,
	HitTime: number,
	Recover: number,
	HitRadius: number,
	HitShape: string, -- "Point" | "Line" | "Column"
	AttackRange: number,
	MoveSpeed: number,
	OrbitRadius: number,
	OrbitHeight: number,
	OrbitSpeed: number,
	ExitDistance: number,
	Color: Color3,
	Hot: Color3,
	Deep: Color3,
	[string]: any,
}

HazardConfig.Types = {
	Sparrow = {
		Zone = "MeadowSky",
		MinHeight = 20,
		MaxHeight = 500,
		Weight = 5,
		Damage = 1,
		Cooldown = 4,
		LockTime = 0.70,
		DiveStart = 0.85,
		HitTime = 1.00,
		Recover = 0.30,
		HitRadius = 4,
		HitShape = "Point",
		AttackRange = 55,
		MoveSpeed = 24,
		OrbitRadius = 22,
		OrbitHeight = 10,
		OrbitSpeed = 0.8,
		ExitDistance = 16,
		Color = Color3.fromHex("FFD21F"),
		Hot = Color3.fromHex("FFF6B0"),
		Deep = Color3.fromHex("B36B00"),
	},

	Plane = {
		Zone = "MeadowSky",
		MinHeight = 150,
		MaxHeight = 500,
		Weight = 3,
		Damage = 1,
		Cooldown = 5,
		UnfoldAt = 0.40,
		LockTime = 0.90,
		LaunchAt = 1.10,
		HitTime = 1.20,
		Recover = 0.30,
		HitRadius = 3.5,
		HitShape = "Line",
		AttackRange = 70,
		MoveSpeed = 18,
		OrbitRadius = 34,
		OrbitHeight = 4,
		OrbitSpeed = 0.5,
		ExitDistance = 22,
		Color = Color3.fromHex("7CFF3A"),
		Hot = Color3.fromHex("E6FFD0"),
		Deep = Color3.fromHex("2C7A0E"),
	},

	Pinwheel = {
		Zone = "CloudShelf",
		MinHeight = 500,
		MaxHeight = 1500,
		Weight = 4,
		Damage = 1,
		Cooldown = 6,
		BloomAt = 0.60,
		LockTime = 1.10,
		SnapAt = 1.40,
		HitTime = 1.45,
		ReturnAt = 1.60,
		Recover = 0.70,
		HitRadius = 5,
		ClampRadius = 11,
		HitShape = "Point",
		AttackRange = 45,
		MoveSpeed = 16,
		OrbitRadius = 24,
		OrbitHeight = 3,
		OrbitSpeed = 0.6,
		ExitDistance = 0,
		Color = Color3.fromHex("FF3FD0"),
		Hot = Color3.fromHex("FFD0F5"),
		Deep = Color3.fromHex("7A0B63"),
	},

	Nimbo = {
		Zone = "CloudShelf",
		MinHeight = 800,
		MaxHeight = 1500,
		Weight = 2,
		Damage = 2,
		Cooldown = 7,
		SoakAt = 0.30,
		LockTime = 0.80,
		DrizzleAt = 1.50,
		HitTime = 1.60,
		WringAt = 1.90,
		Recover = 0.80,
		HitRadius = 8,
		HitShape = "Column",
		ColumnDepth = 45,
		AttackRange = 30,
		MoveSpeed = 12,
		OrbitRadius = 3,
		OrbitHeight = 18, -- hovers this high above the balloon
		OrbitSpeed = 0.4,
		ExitDistance = 0,
		PinCount = 26,
		Color = Color3.fromHex("38C8FF"),
		Hot = Color3.fromHex("DDF6FF"),
		Deep = Color3.fromHex("0B4F8A"),
	},
} :: { [string]: HazardType }

return HazardConfig
