--!strict
-- FlightController: how flying feels (the client half of FlightService).
--
-- Drifty steering: WASD / the thumbstick push you around with momentum, you keep sliding
-- when you let go, and a lazy wind nudges you around, so staying over an island is a
-- small skill. Rising is automatic: the server sends a HeightTarget and you float up to
-- it (and sink when you let out air). The body leans into the drift and the balloon
-- trails behind on its string.
--
-- Controls (section 16): Jump = take off, hold Space / LET OUT AIR = drop, hold E / LAND.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local FlightController = {}

local LocalPlayer = Players.LocalPlayer

local FlightConfig: any
local Net: RemoteEvent
local Spots: { any } = {}

local character: Model? = nil
local humanoid: Humanoid? = nil
local hrp: BasePart? = nil
local defaults = { walk = 16, jumpPower = 50, jumpHeight = 7.2 }

local movers: { align: AlignPosition, orient: AlignOrientation, att: Attachment }? = nil
local vel = Vector3.zero -- horizontal drift velocity
local target = Vector3.zero -- horizontal target
local yCur = 0
local heading = 0
local roll = 0
local wind = Vector3.zero
local windGoal = Vector3.zero
local windAt = 0
local letOutHeld = false
local landHeld = false
local keysBound = false
local lastLaunch = 0
local zoom = 0
local defaultMinZoom = 0.5

FlightController.Changed = Instance.new("BindableEvent") -- fires when the landable spot changes
FlightController.LandDenied = Instance.new("BindableEvent") -- (status, spot, studs) when E is pressed out of range
FlightController.Spot = nil :: any? -- the spot you can land on right now
FlightController.Nearest = nil :: any? -- nearest island (for the arrow)
FlightController.LettingOut = false -- holding Space / LET OUT AIR right now

local function state(): string
	return (LocalPlayer:GetAttribute("FlightState") :: string?) or "Ground"
end

local function flying(): boolean
	local s = state()
	return s == "Flying" or s == "Landing"
end

function FlightController.IsFlying(): boolean
	return flying()
end

function FlightController.GetSpots(): { any }
	return Spots
end

--------------------------------------------------------------------------------
-- intents

function FlightController.SetLetOut(on: boolean)
	if on == letOutHeld then
		return
	end
	letOutHeld = on
	FlightController.LettingOut = on and flying()
	Net:FireServer("LetOut", on and flying())
end

-- Why can't I land? Returns ("high" | "low" | "far", island, studs) for the island you're
-- closest to landing on.
function FlightController.LandHint(): (string, any?, number)
	local root = hrp
	if not root then
		return "far", nil, 0
	end
	local first = LocalPlayer:GetAttribute("FirstLanding") == true
	local best, bestSpot, bestOff = "far", nil, math.huge
	for _, spot in Spots do
		local status, off = FlightConfig.LandStatus(spot, root.Position, first)
		if status ~= "far" and off < bestOff then
			best, bestSpot, bestOff = status, spot, off
		end
	end
	if not bestSpot then
		return "far", FlightController.Nearest, 0
	end
	return best, bestSpot, bestOff
end

function FlightController.SetLanding(on: boolean)
	if on and not FlightController.Spot then
		if flying() then
			FlightController.LandDenied:Fire(FlightController.LandHint())
		end
		return
	end
	if on == landHeld then
		return
	end
	landHeld = on
	Net:FireServer("Land", on)
end

function FlightController.Launch()
	if state() ~= "Ground" or not character or not character:FindFirstChild("Balloon") then
		return
	end
	if not LocalPlayer:GetAttribute("DataLoaded") then
		return
	end
	if os.clock() - lastLaunch < 1 then
		return
	end
	lastLaunch = os.clock()
	Net:FireServer("Launch")
end

--------------------------------------------------------------------------------
-- movers

local function setJump(h: Humanoid, on: boolean)
	h.JumpPower = if on then defaults.jumpPower else 0
	h.JumpHeight = if on then defaults.jumpHeight else 0
end

local function removeMovers()
	if movers then
		movers.align:Destroy()
		movers.orient:Destroy()
		movers.att:Destroy()
		movers = nil
	end
end

local function addMovers()
	if movers or not hrp or not humanoid then
		return
	end
	local root = hrp :: BasePart
	local att = Instance.new("Attachment")
	att.Name = "FlightAttachment"
	att.Parent = root
	local align = Instance.new("AlignPosition")
	align.Name = "FlightAlign"
	align.Mode = Enum.PositionAlignmentMode.OneAttachment
	align.Attachment0 = att
	align.MaxForce = 1e6
	align.MaxVelocity = math.huge
	align.Responsiveness = 22
	align.Position = root.Position
	align.Parent = root
	local orient = Instance.new("AlignOrientation")
	orient.Name = "FlightOrient"
	orient.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orient.Attachment0 = att
	orient.MaxTorque = 1e7
	orient.Responsiveness = 14
	orient.CFrame = root.CFrame.Rotation
	orient.Parent = root
	movers = { align = align, orient = orient, att = att }

	local v = root.AssemblyLinearVelocity
	vel = Vector3.new(v.X, 0, v.Z)
	target = Vector3.new(root.Position.X, 0, root.Position.Z)
	yCur = root.Position.Y
	local look = root.CFrame.LookVector
	heading = math.atan2(-look.X, -look.Z)
	roll = 0
end

local function applyState()
	local h = humanoid
	if not h then
		return
	end
	local s = state()
	if s == "Flying" or s == "Landing" then
		addMovers()
		h.WalkSpeed = 0
		setJump(h, false)
		h.AutoRotate = false
		-- Bind the keys ONCE per flight. Re-binding while E is held (e.g. when the state
		-- flips Flying -> Landing) makes Roblox send a Cancel, which used to let go of
		-- LAND the moment landing started.
		if not keysBound then
			keysBound = true
			ContextActionService:BindActionAtPriority("BalloonLetOut", function(_, inputState)
				FlightController.SetLetOut(inputState == Enum.UserInputState.Begin)
				return Enum.ContextActionResult.Sink
			end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
			ContextActionService:BindActionAtPriority("BalloonLand", function(_, inputState)
				if inputState == Enum.UserInputState.Begin then
					FlightController.SetLanding(true)
				elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
					FlightController.SetLanding(false)
				end
				return Enum.ContextActionResult.Sink
			end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.E, Enum.KeyCode.ButtonX)
		end
	else
		removeMovers()
		if keysBound then
			keysBound = false
			ContextActionService:UnbindAction("BalloonLetOut")
			ContextActionService:UnbindAction("BalloonLand")
		end
		letOutHeld = false
		FlightController.LettingOut = false
		landHeld = false
		if s == "Falling" then
			-- no parachute: straight down, arms flailing
			h.WalkSpeed = 0
			setJump(h, false)
			if hrp then
				local v = (hrp :: BasePart).AssemblyLinearVelocity
				;(hrp :: BasePart).AssemblyLinearVelocity = Vector3.new(0, math.min(v.Y, 0), 0)
			end
			h:ChangeState(Enum.HumanoidStateType.Freefall)
		else
			h.WalkSpeed = defaults.walk
			setJump(h, true)
			h.AutoRotate = true
		end
	end
end

--------------------------------------------------------------------------------
-- per frame

local function moveInput(): Vector3
	local h = humanoid
	if not h then
		return Vector3.zero
	end
	local dir = h.MoveDirection
	return Vector3.new(dir.X, 0, dir.Z)
end

local function angleLerp(a: number, b: number, t: number): number
	local d = (b - a + math.pi) % (2 * math.pi) - math.pi
	return a + d * t
end

local function stepWind(now: number, dt: number)
	local cfg = FlightConfig.Drift
	if now >= windAt then
		local range = cfg.WindChange
		windAt = now + range[1] + math.random() * (range[2] - range[1])
		local a = math.random() * math.pi * 2
		windGoal = Vector3.new(math.cos(a), 0, math.sin(a)) * cfg.Wind * (0.35 + 0.65 * math.random())
	end
	wind = wind:Lerp(windGoal, 1 - math.exp(-0.6 * dt))
end

local function stepFlight(dt: number)
	local root = hrp
	local m = movers
	if not root or not m then
		return
	end
	local cfg = FlightConfig.Drift
	local now = os.clock()
	stepWind(now, dt)

	-- momentum: input accelerates, drag bleeds it off slowly (the drift)
	local input = moveInput()
	vel += input * cfg.Accel * dt
	local drag = cfg.Drag + (if state() == "Landing" then 2.5 else 0)
	vel *= math.exp(-drag * dt)
	if vel.Magnitude > cfg.MaxSpeed then
		vel = vel.Unit * cfg.MaxSpeed
	end
	target += (vel + wind) * dt

	-- stay inside the map's walls
	local b = cfg.Bounds
	local cx, cz = math.clamp(target.X, -b, b), math.clamp(target.Z, -b, b)
	if cx ~= target.X then
		vel = Vector3.new(0, 0, vel.Z)
	end
	if cz ~= target.Z then
		vel = Vector3.new(vel.X, 0, 0)
	end
	target = Vector3.new(cx, 0, cz)

	-- leash: if something blocks you (an island's side), don't let the target run away
	local pos = root.Position
	local flat = Vector3.new(pos.X, 0, pos.Z)
	local off = target - flat
	if off.Magnitude > 5 then
		target = flat + off.Unit * 5
		vel *= math.exp(-4 * dt)
	end

	-- rise to the server's height target, sink when it drops
	local goal = (LocalPlayer:GetAttribute("HeightTarget") :: number?) or pos.Y
	local rise = (LocalPlayer:GetAttribute("RiseSpeed") :: number?) or FlightConfig.Rise.Speed
	local d = goal - yCur
	local maxStep = (if d > 0 then rise else FlightConfig.Rise.FallSpeed) * dt
	local eased = d * (1 - math.exp(-2.2 * dt))
	local stepY = math.clamp(eased, -maxStep, maxStep)
	if math.abs(d) > 1 and math.abs(stepY) < 2 * dt then
		stepY = math.sign(d) * math.min(math.abs(d), 2 * dt)
	end
	yCur = math.clamp(yCur + stepY, pos.Y - 8, pos.Y + 8)

	-- never shove the body into an island: pressing into its underside (or into the ground
	-- when you sink onto it) makes friction pin you in place. Stop at the surface instead,
	-- so you can still drift out sideways.
	local c = character
	if c then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { c }
		params.IgnoreWater = true
		local head = workspace:Raycast(pos, Vector3.new(0, 4.5, 0), params)
		if head and head.Instance.CanCollide and yCur > pos.Y then
			yCur = pos.Y
		end
		local feet = workspace:Raycast(pos, Vector3.new(0, -3.4, 0), params)
		if feet and feet.Instance.CanCollide and yCur < pos.Y then
			yCur = pos.Y
		end
	end
	local bob = math.sin(now * 1.4) * 0.45
	m.align.Position = Vector3.new(target.X, yCur + bob, target.Z)

	-- lean into the drift, turn to face where you're going
	local speed = vel.Magnitude
	if speed > 2.5 then
		heading = angleLerp(heading, math.atan2(-vel.X, -vel.Z), 1 - math.exp(-3 * dt))
	end
	local forward = Vector3.new(-math.sin(heading), 0, -math.cos(heading))
	local right = Vector3.new(math.cos(heading), 0, -math.sin(heading))
	local side = input:Dot(right)
	roll = roll + (side * 0.18 - roll) * (1 - math.exp(-4 * dt))
	local lean = cfg.Lean * math.clamp(speed / cfg.MaxSpeed, 0, 1) * math.clamp(input:Dot(forward) + 0.4, 0, 1)
	local sway = math.sin(now * 0.9) * 0.04
	m.orient.CFrame = CFrame.Angles(0, heading, 0) * CFrame.Angles(-lean, 0, -roll + sway)
end

-- keep the balloon's follow point above your hand, trailing behind your motion
local function stepBalloon()
	local root = hrp
	local c = character
	if not root or not c then
		return
	end
	local att = root:FindFirstChild("BalloonTarget") :: Attachment?
	if not att then
		return
	end
	local hand = (c:FindFirstChild("RightHand") or c:FindFirstChild("Right Arm")) :: BasePart?
	local grip = hand and hand:FindFirstChild("RightGripAttachment") :: Attachment?
	if not grip then
		return
	end
	local v = root.AssemblyLinearVelocity
	local trail = Vector3.new(v.X, 0, v.Z) * 0.06
	att.WorldPosition = grip.WorldPosition + Vector3.new(0, FlightConfig.StringLength, 0) - trail
end

local function stepCamera(dt: number)
	local size = (LocalPlayer:GetAttribute("Size") :: number?) or 1
	local cfg = FlightConfig.Camera
	local goal = if flying() then math.min(cfg.MaxZoom, cfg.MinZoom + cfg.PerRootSize * math.sqrt(size)) else defaultMinZoom
	zoom += (goal - zoom) * (1 - math.exp(-2 * dt))
	if math.abs(goal - zoom) < 0.05 then
		zoom = goal
	end
	if math.abs(LocalPlayer.CameraMinZoomDistance - zoom) > 0.01 then
		LocalPlayer.CameraMinZoomDistance = math.max(defaultMinZoom, zoom)
	end
end

local function stepSpots()
	local root = hrp
	if not root then
		return
	end
	local pos = root.Position
	local first = LocalPlayer:GetAttribute("FirstLanding") == true
	local spot = if flying() then FlightConfig.LandSpotAt(Spots, pos, first) else nil
	local nearest, best = nil, math.huge
	for _, s in Spots do
		if s.Name ~= FlightConfig.Home.Name then
			local dist = (s.Top - pos).Magnitude
			if dist < best then
				nearest, best = s, dist
			end
		end
	end
	FlightController.Nearest = nearest
	if spot ~= FlightController.Spot then
		FlightController.Spot = spot
		if not spot and landHeld then
			FlightController.SetLanding(false)
		end
		FlightController.Changed:Fire(spot)
	end
end

--------------------------------------------------------------------------------
-- character

local function onCharacter(c: Model)
	removeMovers()
	character = c
	humanoid = c:WaitForChild("Humanoid", 10) :: Humanoid?
	hrp = c:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if humanoid then
		defaults.walk = humanoid.WalkSpeed
		defaults.jumpPower = humanoid.JumpPower
		defaults.jumpHeight = humanoid.JumpHeight
	end
	applyState()
end

--------------------------------------------------------------------------------
-- start

export type StartOptions = {
	Shared: Instance,
	RemoteParent: Instance,
}

function FlightController.Start(opts: StartOptions)
	local config = opts.Shared:WaitForChild("Config")
	FlightConfig = require(config:WaitForChild("FlightConfig") :: ModuleScript) :: any
	local IslandConfig = require(config:WaitForChild("IslandConfig") :: ModuleScript) :: any
	for _, island in IslandConfig.Islands do
		table.insert(Spots, island)
	end
	table.insert(Spots, FlightConfig.Home)
	Net = opts.RemoteParent:WaitForChild("FlightNet") :: RemoteEvent
	defaultMinZoom = LocalPlayer.CameraMinZoomDistance
	zoom = defaultMinZoom

	LocalPlayer:GetAttributeChangedSignal("FlightState"):Connect(applyState)
	LocalPlayer.CharacterAdded:Connect(onCharacter)
	if LocalPlayer.Character then
		task.spawn(onCharacter, LocalPlayer.Character)
	end
	Net.OnClientEvent:Connect(function(kind: string)
		if kind == "Banked" or kind == "Popped" then
			removeMovers()
		end
	end)

	UserInputService.JumpRequest:Connect(function()
		if state() == "Ground" and humanoid and humanoid.FloorMaterial ~= Enum.Material.Air then
			FlightController.Launch()
		end
	end)

	RunService.PreSimulation:Connect(function(dt)
		if flying() then
			stepFlight(dt)
		elseif state() == "Falling" and hrp then
			local root = hrp :: BasePart
			local v = root.AssemblyLinearVelocity
			local terminal = FlightConfig.Rise.Terminal
			local vx, vz = v.X * math.exp(-3 * dt), v.Z * math.exp(-3 * dt)
			if v.Y < -terminal or math.abs(v.X) > 0.5 or math.abs(v.Z) > 0.5 then
				root.AssemblyLinearVelocity = Vector3.new(vx, math.max(v.Y, -terminal), vz)
			end
		end
		stepBalloon()
	end)
	RunService.RenderStepped:Connect(function(dt)
		stepCamera(dt)
		stepSpots()
	end)
end

return FlightController
