--!strict
-- FlightService: one flight, server authoritative (sections 2, 16 and 17 of the prompt).
--
--   Ground --jump--> Flying --hold E near an island--> Landing --2 s--> banked, Ground
--                      |                                 |
--                      +---------- HP hits 0 ------------+--> Falling --touch down--> Ground
--
-- The server owns size, unbanked coins, HP, the height target and every landing check.
-- The client only sends intents on the FlightNet remote:
--   "Launch"            jump while holding a balloon on the ground
--   "LetOut", on        hold Space / LET OUT AIR (lose 5% size per second)
--   "Land", on          hold E / LAND (the server finds the island itself)
-- and gets back:
--   "Banked", amount, spotName, firstBonus      "Popped", size, lostCoins
--   "Toast", text
-- Everything else goes through player attributes (FlightState, Size, Unbanked, HP, MaxHP,
-- HeightTarget, RiseSpeed, LandEnd, LandSpot, FirstLanding, Maxed, Balloon, MaxSize).
--
-- The client moves the character (smooth drifty steering); the server checks it stays
-- under its height target.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataService = require(script.Parent.DataService)

local FlightService = {}

type Flight = {
	state: string, -- "Ground" | "Flying" | "Landing" | "Falling"
	kind: string,
	stats: any,
	size: number,
	unbanked: number,
	hp: number,
	baseY: number,
	letOut: boolean,
	landSpot: any?,
	landEnd: number,
	launchedAt: number,
	fallStart: number,
	allowedY: number,
	scale: number,
	devKind: string?,
	msgs: { [string]: number },
	budget: number,
}

local Shared: any
local BalloonConfig: any
local BalloonBuilder: any
local FlightConfig: any
local LandSpots: { any } = {}
local Net: RemoteEvent
local FXRemote: RemoteEvent?
local flights: { [Player]: Flight } = {}

local STRING_COLOR = Color3.fromHex("F4F6FF")
local MAX_GLOW = Color3.fromHex("FFD95A")

--------------------------------------------------------------------------------
-- helpers

local function rootOf(player: Player): (Model?, BasePart?, Humanoid?)
	local character = player.Character
	if not character then
		return nil, nil, nil
	end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return character, hrp, humanoid
end

local function isFirst(player: Player): boolean
	local data = DataService.Get(player)
	return data ~= nil and not data.tutorial.landed
end

local function groundBelow(character: Model, from: Vector3, depth: number): RaycastResult?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.IgnoreWater = true
	return workspace:Raycast(from, Vector3.new(0, -depth, 0), params)
end

-- the equipped balloon: saved one, or the Studio gallery's "Try it" pick
local function loadout(player: Player, f: Flight)
	local kind, level = "Gumball", 1
	local _, entry = DataService.Equipped(player)
	if entry and BalloonConfig.Types[entry.type] then
		kind, level = entry.type, entry.level
	end
	if f.devKind then
		kind, level = f.devKind, 1
	end
	if not BalloonBuilder.Has(kind) then
		kind = "Gumball"
	end
	f.kind = kind
	f.stats = BalloonConfig.StatsFor(kind, level)
end

local function heightTarget(f: Flight): number
	local h = BalloonConfig.HeightFor(f.size, f.stats.Lift)
	return math.min(FlightConfig.Ceiling, f.baseY + 3 + h)
end

local function publish(player: Player, f: Flight)
	player:SetAttribute("FlightState", f.state)
	player:SetAttribute("Balloon", f.kind)
	player:SetAttribute("Size", math.floor(f.size * 10 + 0.5) / 10)
	player:SetAttribute("MaxSize", math.floor(f.stats.MaxSize))
	player:SetAttribute("Unbanked", math.floor(f.unbanked))
	player:SetAttribute("HP", math.floor(f.hp * 100 + 0.5) / 100)
	player:SetAttribute("MaxHP", f.stats.Toughness)
	player:SetAttribute("HeightTarget", heightTarget(f))
	player:SetAttribute("RiseSpeed", FlightConfig.RiseSpeed(f.stats.Lift))
	player:SetAttribute("Maxed", f.size >= f.stats.MaxSize - 1e-3)
	player:SetAttribute("LandEnd", f.landEnd)
	player:SetAttribute("LandSpot", if f.landSpot then f.landSpot.Name else "")
	player:SetAttribute("FirstLanding", isFirst(player))
end

--------------------------------------------------------------------------------
-- the held balloon

local function clearBalloon(character: Model)
	local old = character:FindFirstChild("Balloon")
	if old then
		old:Destroy()
	end
end

local function removeTarget(character: Model)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local att = hrp and hrp:FindFirstChild("BalloonTarget")
	if att then
		att:Destroy()
	end
end

-- the colour of the biggest visible part, for the pop confetti
local function mainColor(model: Model): Color3
	local best, bestVol = Color3.fromHex("FF3B3B"), 0
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 0.5 then
			local v = d.Size.X * d.Size.Y * d.Size.Z
			if v > bestVol then
				best, bestVol = d.Color, v
			end
		end
	end
	return best
end

-- (re)set the physics after building or ScaleTo (which also scales constraint lengths/forces)
local function setLift(model: Model)
	local root = model.PrimaryPart
	if not root then
		return
	end
	local force = root:FindFirstChild("Lift") :: VectorForce?
	if force then
		-- float its own weight plus a gentle pull that keeps the string taut
		force.Force = Vector3.new(0, root.AssemblyMass * (workspace.Gravity + 40) + 20, 0)
	end
	local rope = root:FindFirstChild("String") :: RopeConstraint?
	if rope then
		rope.Length = FlightConfig.StringLength + 0.4
		rope.Thickness = 0.09
	end
	local follow = root:FindFirstChild("Follow") :: AlignPosition?
	if follow then
		follow.MaxForce = 4000
		follow.Responsiveness = 14
	end
end

local function buildBalloon(player: Player, f: Flight)
	local character, hrp = rootOf(player)
	if not character or not hrp then
		return
	end
	clearBalloon(character)
	local hand = (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")) :: BasePart?
	local grip = hand and hand:FindFirstChild("RightGripAttachment") :: Attachment?
	if not hand or not grip then
		return
	end

	local scale = FlightConfig.VisualScale(f.size)
	local knot = BalloonBuilder.KnotOffset(f.kind) * scale
	local knotWorld = grip.WorldPosition + Vector3.new(0, FlightConfig.StringLength, 0)
	local model: Model = BalloonBuilder.Build(f.kind, {
		Anchored = false,
		Name = "Balloon",
		Scale = scale,
		CFrame = CFrame.new(knotWorld - knot),
	})
	model:SetAttribute("PopColor", mainColor(model))
	local root = model.PrimaryPart :: BasePart
	local knotAtt = root:FindFirstChild("StringAttachment") :: Attachment

	-- where the knot wants to be: above the hand (the owning client moves this point
	-- every frame so the balloon trails behind you as you drift)
	removeTarget(character)
	local targetAtt = Instance.new("Attachment")
	targetAtt.Name = "BalloonTarget"
	targetAtt.Parent = hrp
	targetAtt.WorldPosition = knotWorld

	local centre = Instance.new("Attachment")
	centre.Name = "Centre"
	centre.Parent = root

	local follow = Instance.new("AlignPosition")
	follow.Name = "Follow"
	follow.Attachment0 = knotAtt
	follow.Attachment1 = targetAtt
	follow.Responsiveness = 14
	follow.MaxForce = 4000
	follow.ApplyAtCenterOfMass = false
	follow.Parent = root

	local upright = Instance.new("AlignOrientation")
	upright.Name = "Upright"
	upright.Mode = Enum.OrientationAlignmentMode.OneAttachment
	upright.Attachment0 = centre
	upright.CFrame = CFrame.identity
	upright.Responsiveness = 9
	upright.MaxTorque = 1e6
	upright.Parent = root

	local lift = Instance.new("VectorForce")
	lift.Name = "Lift"
	lift.Attachment0 = centre
	lift.RelativeTo = Enum.ActuatorRelativeTo.World
	lift.ApplyAtCenterOfMass = true
	lift.Parent = root

	local rope = Instance.new("RopeConstraint")
	rope.Name = "String"
	rope.Attachment0 = grip
	rope.Attachment1 = knotAtt
	rope.Length = FlightConfig.StringLength + 0.4
	rope.Visible = true
	rope.Thickness = 0.09
	rope.Color = BrickColor.new(STRING_COLOR)
	rope.Parent = root

	model.Parent = character
	setLift(model)
	if root:CanSetNetworkOwnership() then
		root:SetNetworkOwner(player)
	end
	f.scale = scale
end

-- the balloon grows (the visual size caps; the camera zooms out for the rest)
local function rescale(player: Player, f: Flight)
	local character = player.Character
	local model = character and character:FindFirstChild("Balloon") :: Model?
	if not model then
		return
	end
	local scale = FlightConfig.VisualScale(f.size)
	if math.abs(scale - f.scale) >= 0.02 then
		f.scale = scale
		model:ScaleTo(scale)
		setLift(model)
	end
	local root = model.PrimaryPart
	if root then
		local glow = root:FindFirstChild("MaxGlow")
		local maxed = f.size >= f.stats.MaxSize - 1e-3
		if maxed and not glow then
			local light = Instance.new("PointLight")
			light.Name = "MaxGlow"
			light.Color = MAX_GLOW
			light.Brightness = 3
			light.Range = 18
			light.Shadows = false
			light.Parent = root
		elseif not maxed and glow then
			glow:Destroy()
		end
	end
end

--------------------------------------------------------------------------------
-- state changes

local function toGround(player: Player, f: Flight)
	f.state = "Ground"
	f.size = 1
	f.unbanked = 0
	f.letOut = false
	f.landSpot = nil
	f.landEnd = 0
	loadout(player, f)
	f.hp = f.stats.Toughness
	local character = player.Character
	if character then
		removeTarget(character)
		buildBalloon(player, f)
	end
	publish(player, f)
end

local function launch(player: Player, f: Flight)
	local character, hrp, humanoid = rootOf(player)
	if f.state ~= "Ground" or not character or not hrp or not humanoid or humanoid.Health <= 0 then
		return
	end
	if not character:FindFirstChild("Balloon") then
		return
	end
	if os.clock() - f.launchedAt < 1 then
		return
	end
	local hit = groundBelow(character, hrp.Position, 14)
	f.baseY = if hit then hit.Position.Y else hrp.Position.Y - 3
	f.state = "Flying"
	f.size = 1
	f.unbanked = 0
	f.hp = f.stats.Toughness
	f.launchedAt = os.clock()
	f.allowedY = hrp.Position.Y
	local data = DataService.Get(player)
	if data then
		data.stats.flights += 1
	end
	publish(player, f)
end

local function bank(player: Player, f: Flight)
	local spot = f.landSpot
	local character, hrp = rootOf(player)
	local first = isFirst(player)
	local bonus = if first then FlightConfig.Land.FirstBonus else 1
	local amount = math.floor(f.unbanked * bonus)
	local size = f.size
	DataService.AddCoins(player, amount)
	local data = DataService.Get(player)
	if data then
		data.tutorial.landed = true
		data.stats.biggestSize = math.max(data.stats.biggestSize, math.floor(size))
	end
	toGround(player, f)
	-- stand on the landing pad (or straight below you on the start map)
	if character and hrp and spot then
		local pad: Vector3? = spot.Pad
		if not pad then
			local hit = groundBelow(character, hrp.Position, 200)
			pad = if hit then hit.Position else nil
		end
		if pad then
			local look = hrp.CFrame.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)
			flat = if flat.Magnitude > 0.1 then flat.Unit else Vector3.new(0, 0, -1)
			local at = pad + Vector3.new(0, 3.5, 0)
			character:PivotTo(CFrame.lookAt(at, at + flat))
			hrp.AssemblyLinearVelocity = Vector3.zero
		end
	end
	Net:FireClient(player, "Banked", amount, if spot then spot.Label or spot.Name else "", bonus, size)
end

local function pop(player: Player, f: Flight)
	local character = player.Character
	local lost = math.floor(f.unbanked)
	local size = f.size
	local data = DataService.Get(player)
	if data then
		data.stats.totalPops += 1
		data.stats.biggestPop = math.max(data.stats.biggestPop, math.floor(size))
	end
	if character then
		local model = character:FindFirstChild("Balloon") :: Model?
		if model and model.PrimaryPart and FXRemote then
			local color = model:GetAttribute("PopColor")
			FXRemote:FireAllClients("Pop", player.UserId, model.PrimaryPart.Position, if typeof(color) == "Color3" then color else Color3.new(1, 0.25, 0.25))
		end
		clearBalloon(character)
		removeTarget(character)
	end
	f.state = "Falling"
	f.unbanked = 0
	f.letOut = false
	f.landSpot = nil
	f.landEnd = 0
	f.hp = 0
	f.fallStart = os.clock()
	publish(player, f)
	Net:FireClient(player, "Popped", size, lost)
end

--------------------------------------------------------------------------------
-- public API (HazardService, later BalloonService / RiderService)

function FlightService.IsFlying(player: Player): boolean
	local f = flights[player]
	return f ~= nil and (f.state == "Flying" or f.state == "Landing")
end

-- Can hazards hunt this player? Flying, after a short grace period so you can get off the
-- ground (a longer one before your first landing, so it's easy to reach the first island).
function FlightService.IsHuntable(player: Player): boolean
	local f = flights[player]
	if not f or not (f.state == "Flying" or f.state == "Landing") then
		return false
	end
	local grace = if isFirst(player) then FlightConfig.Grace.First else FlightConfig.Grace.Normal
	return os.clock() - f.launchedAt >= grace
end

function FlightService.GetState(player: Player): string
	local f = flights[player]
	return if f then f.state else "Ground"
end

-- A hazard hit: damage x fragility (1 + size / 200).
function FlightService.Damage(player: Player, damage: number)
	local f = flights[player]
	if not f or not (f.state == "Flying" or f.state == "Landing") then
		return
	end
	f.hp -= damage * (1 + f.size / FlightConfig.Fragility)
	if f.hp <= 1e-3 then
		pop(player, f)
	else
		publish(player, f)
	end
end

-- Re-read the equipped balloon (after an equip / upgrade). Only takes effect on the ground.
function FlightService.Refresh(player: Player)
	local f = flights[player]
	if f and f.state == "Ground" then
		toGround(player, f)
	end
end

--------------------------------------------------------------------------------
-- tick

local function step(player: Player, f: Flight, dt: number)
	local character, hrp, humanoid = rootOf(player)
	if f.state == "Ground" then
		return
	end
	if not character or not hrp or not humanoid then
		return
	end

	if f.state == "Falling" then
		local elapsed = os.clock() - f.fallStart
		local onFloor = humanoid.FloorMaterial ~= Enum.Material.Air
		local slow = math.abs(hrp.AssemblyLinearVelocity.Y) < 4
		if elapsed > 0.6 and slow and (onFloor or groundBelow(character, hrp.Position, 5)) or elapsed > 20 then
			toGround(player, f)
		end
		return
	end

	-- growing and earning
	if f.letOut then
		f.size = math.max(1, f.size * (1 - FlightConfig.LetOutAirRate * dt))
	elseif f.state == "Flying" then
		f.size = math.min(f.stats.MaxSize, f.size + f.stats.Growth * dt)
	end
	f.unbanked += f.size * f.stats.Earn * dt

	-- height check: the client rises to the target and sinks at FallSpeed, so allow for that
	local target = heightTarget(f)
	f.allowedY = math.max(target, f.allowedY - FlightConfig.Rise.FallSpeed * 1.2 * dt)
	local limit = f.allowedY + FlightConfig.AntiCheat.Above
	if hrp.Position.Y > limit then
		character:PivotTo(character:GetPivot() - Vector3.new(0, hrp.Position.Y - limit + 5, 0))
	end

	-- landing
	if f.state == "Landing" then
		local spot = f.landSpot
		if not spot or not FlightConfig.CanLand(spot, hrp.Position, isFirst(player)) then
			f.state = "Flying"
			f.landSpot = nil
			f.landEnd = 0
			Net:FireClient(player, "Toast", "Too far - landing cancelled")
		elseif workspace:GetServerTimeNow() >= f.landEnd then
			bank(player, f)
			return
		end
	end

	rescale(player, f)
	publish(player, f)
end

--------------------------------------------------------------------------------
-- remote

local LIMITS = { Launch = 0.4, LetOut = 0.05, Land = 0.15 }

local function onMessage(player: Player, kind: unknown, arg: unknown)
	local f = flights[player]
	if not f or type(kind) ~= "string" then
		return
	end
	local gap = LIMITS[kind]
	if not gap then
		return
	end
	-- per-message spacing plus a total budget (refills at 20 messages / second)
	local now = os.clock()
	if now - (f.msgs[kind] or 0) < gap then
		return
	end
	if f.budget <= 0 then
		return
	end
	f.msgs[kind] = now
	f.budget -= 1

	if kind == "Launch" then
		launch(player, f)
	elseif kind == "LetOut" then
		f.letOut = arg == true and f.state == "Flying"
	elseif kind == "Land" then
		local _, hrp = rootOf(player)
		if arg ~= true then
			if f.state == "Landing" then
				f.state = "Flying"
				f.landSpot = nil
				f.landEnd = 0
				publish(player, f)
			end
			return
		end
		if f.state ~= "Flying" or not hrp then
			return
		end
		if os.clock() - f.launchedAt < 1.5 then
			return
		end
		local first = isFirst(player)
		local spot = FlightConfig.LandSpotAt(LandSpots, hrp.Position, first)
		if not spot then
			Net:FireClient(player, "Toast", "Get closer to an island to land")
			return
		end
		f.state = "Landing"
		f.letOut = false
		f.landSpot = spot
		local time = if first then FlightConfig.Land.FirstTime else FlightConfig.Land.Time
		f.landEnd = workspace:GetServerTimeNow() + time
		publish(player, f)
	end
end

--------------------------------------------------------------------------------
-- players

local function newFlight(): Flight
	return {
		state = "Ground",
		kind = "Gumball",
		stats = BalloonConfig.StatsFor("Gumball", 1),
		size = 1,
		unbanked = 0,
		hp = 3,
		baseY = 0,
		letOut = false,
		landSpot = nil,
		landEnd = 0,
		launchedAt = 0,
		fallStart = 0,
		allowedY = 0,
		scale = 1,
		devKind = nil,
		msgs = {},
		budget = 20,
	}
end

local function onCharacter(player: Player, character: Model)
	local f = flights[player]
	if not f then
		return
	end
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	character:WaitForChild("HumanoidRootPart", 10)
	local hand = character:WaitForChild("RightHand", 5) or character:FindFirstChild("Right Arm")
	if hand then
		hand:WaitForChild("RightGripAttachment", 5)
	end
	if player.Character ~= character then
		return
	end
	toGround(player, f)
	if humanoid then
		humanoid.Died:Connect(function()
			local current = flights[player]
			if current and (current.state == "Flying" or current.state == "Landing") then
				pop(player, current)
			end
		end)
	end
end

local function onPlayer(player: Player)
	local f = newFlight()
	flights[player] = f
	DataService.Wait(player, 30)
	if player.Parent ~= Players then
		return
	end
	loadout(player, f)
	f.hp = f.stats.Toughness
	publish(player, f)
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end
end

--------------------------------------------------------------------------------
-- start

export type StartOptions = {
	Shared: Instance,
	RemoteParent: Instance,
}

function FlightService.Start(opts: StartOptions)
	assert(RunService:IsServer(), "FlightService runs on the server")
	Shared = opts.Shared
	BalloonConfig = require(Shared.Config.BalloonConfig) :: any
	BalloonBuilder = require(Shared.Balloons.BalloonBuilder) :: any
	FlightConfig = require(Shared.Config.FlightConfig) :: any
	local IslandConfig = require(Shared.Config.IslandConfig) :: any

	LandSpots = {}
	for _, island in IslandConfig.Islands do
		table.insert(LandSpots, island)
	end
	table.insert(LandSpots, FlightConfig.Home)

	local net = Instance.new("RemoteEvent")
	net.Name = "FlightNet"
	net.Parent = opts.RemoteParent
	Net = net
	net.OnServerEvent:Connect(onMessage)
	FXRemote = opts.RemoteParent:FindFirstChild("HazardFX") :: RemoteEvent?

	-- Studio only: the balloon gallery by the spawn with "Try it" prompts (swaps your
	-- balloon for this session, on the ground only; nothing is saved)
	if RunService:IsStudio() then
		Shared:SetAttribute("Gallery", true)
		local equip = Instance.new("RemoteEvent")
		equip.Name = "DemoEquip"
		equip.Parent = opts.RemoteParent
		local last: { [Player]: number } = {}
		equip.OnServerEvent:Connect(function(player: Player, kind: unknown)
			local f = flights[player]
			if not f or f.state ~= "Ground" then
				return
			end
			if type(kind) ~= "string" or not BalloonConfig.Types[kind] or not BalloonBuilder.Has(kind) then
				return
			end
			if os.clock() - (last[player] or 0) < 0.5 then
				return
			end
			last[player] = os.clock()
			f.devKind = kind
			toGround(player, f)
		end)
		Players.PlayerRemoving:Connect(function(player)
			last[player] = nil
		end)
	end

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end
	Players.PlayerAdded:Connect(onPlayer)
	Players.PlayerRemoving:Connect(function(player)
		-- leaving mid-flight counts as a pop: unbanked coins are simply never saved
		flights[player] = nil
	end)

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < FlightConfig.TickRate then
			return
		end
		local tickDt = math.min(acc, 0.5)
		acc = 0
		for player, f in flights do
			f.budget = math.min(20, f.budget + 20 * tickDt)
			step(player, f, tickDt)
		end
	end)
end

return FlightService
