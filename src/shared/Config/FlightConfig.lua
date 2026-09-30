--!strict
-- FlightConfig: every tunable number for flying (section 2 of the game prompt).
-- Starting values, tune freely.

local FlightConfig = {}

FlightConfig.GroundY = 0 -- world Y of the grass start map
FlightConfig.TickRate = 0.1 -- server growth / earn tick
FlightConfig.Ceiling = 1500 -- top of Cloud Shelf (Phase 1); raise as zones unlock
FlightConfig.StringLength = 5 -- rope between hand and knot

-- held balloon visual size: grows with size up to a cap, then the camera zooms out instead
FlightConfig.Visual = {
	Min = 0.5, -- scale at size 1 (Gumball ~4.5 studs wide)
	Max = 1.25, -- scale cap
	FullAt = 160, -- size where the cap is reached
}

FlightConfig.LetOutAirRate = 0.05 -- size lost per second while holding Space (5%)
FlightConfig.Fragility = 200 -- damage x (1 + size / Fragility)

-- landing (hold E / LAND near an island)
FlightConfig.Land = {
	Time = 2.0,
	FirstTime = 0.6, -- the very first landing is quick and forgiving
	FirstBonus = 2, -- x2 coins on the first landing (tutorial via play)
	Range = 6, -- extra studs outside the island radius
	Below = 10, -- how far under the island top you can start landing
	Above = 45, -- how far above it (coming down onto an island is the natural way in)
	FirstRange = 16, -- first landing: a much bigger landing zone...
	FirstAbove = 70, -- ...and you can start it from higher up
}

-- The grass start map is a landing zone too, once you let out enough air to get low.
-- Without it, a player who misses every island could never bank.
FlightConfig.Home = {
	Name = "StartMap",
	Label = "Start Map",
	Top = Vector3.new(0, 0, 0),
	Radius = 150,
	Below = 10,
	Above = 60,
}

-- drifty steering: momentum, a little wind, slow to stop
FlightConfig.Drift = {
	Accel = 30, -- studs/s^2 from input
	Drag = 0.7, -- velocity lost per second (lower = driftier)
	MaxSpeed = 22,
	Wind = 5, -- max wind drift, studs/s
	WindChange = { 3, 7 }, -- seconds between wind shifts
	Lean = 0.3, -- body tilt from speed
	Bounds = 150, -- keep inside the map's walls
}

FlightConfig.Rise = {
	Speed = 14, -- studs/s climb at Lift 1
	PerLift = 3, -- extra climb speed per sqrt(Lift)
	FallSpeed = 30, -- sink speed when letting out air
	Recover = 6, -- studs/s you float back up after letting go of Space
	Floor = 6, -- letting out air stops this many studs above the grass
	Terminal = 160, -- max fall speed after a pop (also stops tunnelling through the ground)
}

FlightConfig.Camera = {
	MinZoom = 14, -- camera distance while flying at size 1
	PerRootSize = 2.2, -- + this x sqrt(size)
	MaxZoom = 60,
}

-- seconds after take-off before hazards start hunting you
FlightConfig.Grace = {
	Normal = 4,
	First = 12, -- until your first landing: enough to reach Meadow Rest in peace
}

FlightConfig.AntiCheat = {
	Above = 60, -- studs above the height target before the server pulls you back
}

export type LandSpot = { Name: string, Top: Vector3, Radius: number, Pad: Vector3?, Below: number?, Above: number? }

-- Where is `pos` compared to `spot`'s landing zone?
--   "ok"   inside it: you can land
--   "high" over the island but too high: let out air (hold Space)
--   "low"  beside it but too low: wait to float up
--   "far"  too far sideways
-- The second value is how many studs too high / too low.
function FlightConfig.LandStatus(spot: LandSpot, pos: Vector3, first: boolean?): (string, number)
	local land = FlightConfig.Land
	local range = spot.Radius + (if first then land.FirstRange else land.Range)
	local flat = Vector3.new(pos.X - spot.Top.X, 0, pos.Z - spot.Top.Z)
	if flat.Magnitude > range then
		return "far", 0
	end
	local dy = pos.Y - spot.Top.Y
	local above = spot.Above or (if first then land.FirstAbove else land.Above)
	local below = spot.Below or land.Below
	if dy > above then
		return "high", dy - above
	elseif dy < -below then
		return "low", -below - dy
	end
	return "ok", 0
end

-- Can a character whose root is at `pos` start (and keep) landing on `spot`?
function FlightConfig.CanLand(spot: LandSpot, pos: Vector3, first: boolean?): boolean
	return (FlightConfig.LandStatus(spot, pos, first)) == "ok"
end

-- The first spot you can land on from `pos` (nil if none).
function FlightConfig.LandSpotAt(spots: { LandSpot }, pos: Vector3, first: boolean?): LandSpot?
	for _, spot in spots do
		if FlightConfig.CanLand(spot, pos, first) then
			return spot
		end
	end
	return nil
end

function FlightConfig.RiseSpeed(lift: number): number
	return FlightConfig.Rise.Speed + FlightConfig.Rise.PerLift * math.sqrt(math.max(lift, 0))
end

function FlightConfig.VisualScale(size: number): number
	local v = FlightConfig.Visual
	local k = math.clamp(size / v.FullAt, 0, 1) ^ 0.5
	return v.Min + (v.Max - v.Min) * k
end

return FlightConfig
