--!strict
-- HazardService: server-authoritative hazards for Meadow Sky and Cloud Shelf.
--
-- The server owns each hazard as an invisible anchored root Part in workspace.Hazards
-- (attributes Kind, HazardId). It decides movement, when to attack, the locked aim point
-- and every hit. Clients only draw: they build the stud model and play the attack from
-- the "Begin" / "Lock" / "Hit" messages on the HazardFX RemoteEvent. No client->server
-- remote exists, so nothing here trusts the client.
--
-- Hook it to the balloon system:
--   HazardService.Hit.Event:Connect(function(player, damage, kind, hazardId)
--       FlightService.DamageBalloon(player, damage) -- apply fragility, pop, etc.
--   end)
--   Target.Resolver = function(player) return FlightService.GetBalloonPosition(player) end
--   HazardService.IsFlying = function(player) return FlightService.IsFlying(player) end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local HazardService = {}

HazardService.Hit = Instance.new("BindableEvent") -- (player, damage, kind, hazardId)

-- Who can be hunted. Default: anyone whose balloon the Target resolver can find.
HazardService.IsFlying = function(_player: Player): boolean
	return true
end

type Hazard = {
	id: number,
	kind: string,
	cfg: any,
	root: BasePart,
	target: Player,
	state: string, -- "Approach" | "Attack" | "Leave"
	cooldownUntil: number,
	orbit: number,
	lastTarget: Vector3,
	attackToken: number,
	attackStart: number,
	leaveAt: number?,
}

local Config: any
local Target: any
local Remote: RemoteEvent
local Folder: Folder
local hazards: { [number]: Hazard } = {}
local nextId = 0
local demoCycle: { [Player]: number } = {}
local started = false

--------------------------------------------------------------------------------
-- helpers

local function count(player: Player): number
	local n = 0
	for _, h in hazards do
		if h.target == player and h.state ~= "Leave" then
			n += 1
		end
	end
	return n
end

local function heightOf(pos: Vector3): number
	return pos.Y - Config.GroundY
end

local function pickKind(player: Player, pos: Vector3): string?
	if Config.Demo.Enabled then
		local kinds = Config.Demo.Kinds
		local i = (demoCycle[player] or 0) % #kinds + 1
		demoCycle[player] = i
		return kinds[i]
	end
	local h = heightOf(pos)
	local total = 0
	local pool = {}
	for kind, cfg in Config.Types do
		if h >= cfg.MinHeight and h <= cfg.MaxHeight then
			total += cfg.Weight
			table.insert(pool, { kind = kind, w = cfg.Weight })
		end
	end
	if total <= 0 then
		return nil
	end
	local roll = math.random() * total
	for _, e in pool do
		roll -= e.w
		if roll <= 0 then
			return e.kind
		end
	end
	return pool[#pool].kind
end

local function distToSegment(p: Vector3, a: Vector3, b: Vector3): number
	local ab = b - a
	local len2 = ab:Dot(ab)
	if len2 < 1e-6 then
		return (p - a).Magnitude
	end
	local t = math.clamp((p - a):Dot(ab) / len2, 0, 1)
	return (p - (a + ab * t)).Magnitude
end

local function faceTowards(pos: Vector3, look: Vector3, fallback: CFrame): CFrame
	local d = look - pos
	if d.Magnitude < 0.05 then
		return CFrame.new(pos) * fallback.Rotation
	end
	return CFrame.lookAt(pos, look)
end

local function flatLook(pos: Vector3, look: Vector3, fallback: CFrame): CFrame
	local flat = Vector3.new(look.X, pos.Y, look.Z)
	if (flat - pos).Magnitude < 0.5 then
		return CFrame.new(pos) * fallback.Rotation
	end
	return CFrame.lookAt(pos, flat)
end

--------------------------------------------------------------------------------
-- spawning / despawning

function HazardService.Spawn(kind: string, player: Player, position: Vector3): number?
	local cfg = Config.Types[kind]
	if not cfg then
		warn("[HazardService] unknown hazard kind", kind)
		return nil
	end
	nextId += 1
	local root = Instance.new("Part")
	root.Name = kind .. "_" .. nextId
	root.Size = Vector3.new(3, 3, 3)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.CastShadow = false
	root:SetAttribute("Kind", kind)
	root:SetAttribute("HazardId", nextId)
	root.CFrame = CFrame.new(position)
	root.Parent = Folder
	local pos = Target.GetBalloon(player) or position
	hazards[nextId] = {
		id = nextId,
		kind = kind,
		cfg = cfg,
		root = root,
		target = player,
		state = "Approach",
		cooldownUntil = os.clock() + 1.5,
		orbit = math.random() * math.pi * 2,
		lastTarget = pos,
		attackToken = 0,
		attackStart = 0,
	}
	return nextId
end

function HazardService.Despawn(id: number)
	local h = hazards[id]
	if h then
		hazards[id] = nil
		h.root:Destroy()
	end
end

local function leave(h: Hazard)
	if h.state == "Leave" then
		return
	end
	h.state = "Leave"
	h.attackToken += 1
	h.leaveAt = os.clock() + 2.5
end

local function spawnFor(player: Player)
	if count(player) >= Config.Global.MaxPerPlayer then
		return
	end
	local pos = Target.GetBalloon(player)
	if not pos then
		return
	end
	local kind = pickKind(player, pos)
	if not kind then
		return
	end
	local cfg = Config.Types[kind]
	local ang = math.random() * math.pi * 2
	local dist = if Config.Demo.Enabled then 45 else Config.Global.SpawnRadius
	local spawnPos = pos + Vector3.new(math.cos(ang) * dist, cfg.OrbitHeight + math.random(0, 10), math.sin(ang) * dist)
	HazardService.Spawn(kind, player, spawnPos)
end

--------------------------------------------------------------------------------
-- attacks

local function hitTest(h: Hazard, lockPos: Vector3, launchPos: Vector3, balloonPos: Vector3, balloonRadius: number): boolean
	local cfg = h.cfg
	local reach = cfg.HitRadius + balloonRadius * 0.6
	if cfg.HitShape == "Line" then
		local dir = lockPos - launchPos
		dir = if dir.Magnitude > 0.1 then dir.Unit else h.root.CFrame.LookVector
		return distToSegment(balloonPos, launchPos, lockPos + dir * cfg.ExitDistance) <= reach
	elseif cfg.HitShape == "Column" then
		local top = h.root.Position.Y
		local flat = Vector3.new(balloonPos.X - lockPos.X, 0, balloonPos.Z - lockPos.Z).Magnitude
		return flat <= reach and balloonPos.Y <= top and balloonPos.Y >= top - cfg.ColumnDepth
	end
	return (balloonPos - lockPos).Magnitude <= reach
end

local function beginAttack(h: Hazard)
	h.state = "Attack"
	h.attackToken += 1
	local token = h.attackToken
	local cfg = h.cfg
	h.attackStart = os.clock()
	Remote:FireAllClients("Begin", h.id, h.target.UserId, workspace:GetServerTimeNow())

	-- the Plane glides straight ahead before it unfolds; move the root with it so the
	-- server's cut line starts exactly where the client's dart launches
	if cfg.UnfoldAt then
		task.spawn(function()
			local look = h.root.CFrame
			local t = 0
			while t < cfg.UnfoldAt and h.attackToken == token and hazards[h.id] do
				t = math.min(t + RunService.Heartbeat:Wait(), cfg.UnfoldAt)
				h.root.CFrame = look * CFrame.new(0, 0, -cfg.MoveSpeed * t)
			end
		end)
	end

	task.spawn(function()
		task.wait(cfg.LockTime)
		if h.attackToken ~= token or not hazards[h.id] then
			return
		end
		local lockPos = Target.GetBalloon(h.target) or h.lastTarget
		local launchPos = h.root.Position
		Remote:FireAllClients("Lock", h.id, lockPos, launchPos)

		task.wait(cfg.HitTime - cfg.LockTime)
		if h.attackToken ~= token or not hazards[h.id] then
			return
		end
		-- any flying balloon caught in the attack takes the hit (bigger balloons are easier to hit)
		for _, player in Players:GetPlayers() do
			if HazardService.IsFlying(player) then
				local bpos, brad = Target.GetBalloon(player)
				if bpos and hitTest(h, lockPos, launchPos, bpos, brad or 2) then
					Remote:FireAllClients("Hit", h.id, player.UserId, cfg.Damage)
					HazardService.Hit:Fire(player, cfg.Damage, h.kind, h.id)
				end
			end
		end

		-- dives and cuts carry the hazard through the target; the client matches this path
		if cfg.ExitDistance > 0 then
			local dir = lockPos - launchPos
			dir = if dir.Magnitude > 0.1 then dir.Unit else h.root.CFrame.LookVector
			local exit = lockPos + dir * cfg.ExitDistance
			h.root.CFrame = CFrame.lookAt(exit, exit + dir)
		end

		task.wait(cfg.Recover)
		if h.attackToken ~= token or not hazards[h.id] then
			return
		end
		h.state = "Approach"
		h.cooldownUntil = os.clock() + cfg.Cooldown
	end)
end

-- Rider swatter: knocks a hazard away and cancels its attack if it hasn't hit yet.
-- Call from RiderService after validating the swing. Returns true if it connected.
function HazardService.Swat(player: Player, id: number): boolean
	local h = hazards[id]
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not h or not hrp or h.state == "Leave" then
		return false
	end
	if (hrp.Position - h.root.Position).Magnitude > Config.Global.SwatRange + 4 then
		return false
	end
	local cancelled = h.state == "Attack" and os.clock() - h.attackStart < h.cfg.HitTime - 0.1
	if h.state == "Attack" and not cancelled then
		return false
	end
	h.attackToken += 1
	h.state = "Approach"
	h.cooldownUntil = os.clock() + h.cfg.Cooldown
	local away = h.root.Position - hrp.Position
	away = if away.Magnitude > 0.1 then away.Unit else Vector3.yAxis
	h.root.CFrame = h.root.CFrame + away * 10
	Remote:FireAllClients("Cancel", h.id)
	return true
end

--------------------------------------------------------------------------------
-- AI tick

local function tick(dt: number)
	local now = os.clock()
	for id, h in hazards do
		local root = h.root
		if not root.Parent then
			hazards[id] = nil
			continue
		end
		if h.state == "Leave" then
			root.CFrame = root.CFrame + Vector3.new(0, 18 * dt, 0) + root.CFrame.LookVector * 20 * dt
			if h.leaveAt and now >= h.leaveAt then
				HazardService.Despawn(id)
			end
			continue
		end

		local target = h.target
		local tpos = if target.Parent == Players and HazardService.IsFlying(target) then Target.GetBalloon(target) else nil
		if not tpos then
			leave(h)
			continue
		end
		h.lastTarget = tpos
		local cfg = h.cfg

		if (tpos - root.Position).Magnitude > Config.Global.DespawnDistance then
			leave(h)
			continue
		end
		if not Config.Demo.Enabled then
			local height = heightOf(tpos)
			if height < cfg.MinHeight - 60 or height > cfg.MaxHeight + 120 then
				leave(h)
				continue
			end
		end

		if h.state == "Approach" then
			h.orbit += cfg.OrbitSpeed * dt
			local desired = tpos + Vector3.new(math.cos(h.orbit) * cfg.OrbitRadius, cfg.OrbitHeight, math.sin(h.orbit) * cfg.OrbitRadius)
			local pos = root.Position
			local delta = desired - pos
			local step = math.min(delta.Magnitude, cfg.MoveSpeed * dt)
			if delta.Magnitude > 0.01 then
				pos += delta.Unit * step
			end
			if h.kind == "Nimbo" then
				root.CFrame = flatLook(pos, tpos, root.CFrame)
			elseif h.kind == "Plane" then
				-- planes look where they're going until they're lined up
				local ahead = if delta.Magnitude > 2 then desired else tpos
				root.CFrame = faceTowards(pos, ahead, root.CFrame)
			else
				root.CFrame = faceTowards(pos, tpos, root.CFrame)
			end
			if now >= h.cooldownUntil and (desired - pos).Magnitude < 8 and (tpos - pos).Magnitude <= cfg.AttackRange then
				if h.kind == "Plane" then
					root.CFrame = faceTowards(pos, tpos, root.CFrame)
				end
				beginAttack(h)
			end
		end
	end
end

--------------------------------------------------------------------------------
-- start

export type StartOptions = {
	Shared: Instance, -- the folder holding Config/ and Hazards/
	RemoteParent: Instance, -- where the HazardFX RemoteEvent lives
	Demo: boolean?,
}

function HazardService.Start(opts: StartOptions)
	assert(RunService:IsServer(), "HazardService runs on the server")
	if started then
		return
	end
	started = true
	Config = require((opts.Shared :: any).Config.HazardConfig) :: any
	Target = require((opts.Shared :: any).Hazards.Target) :: any
	if opts.Demo ~= nil then
		Config.Demo.Enabled = opts.Demo
	end

	local remote = opts.RemoteParent:FindFirstChild("HazardFX") :: RemoteEvent?
	if not remote then
		local created = Instance.new("RemoteEvent")
		created.Name = "HazardFX"
		created.Parent = opts.RemoteParent
		remote = created
	end
	Remote = remote :: RemoteEvent

	local folder = workspace:FindFirstChild("Hazards") :: Folder?
	if not folder then
		local created = Instance.new("Folder")
		created.Name = "Hazards"
		created.Parent = workspace
		folder = created
	end
	Folder = folder :: Folder

	if Config.Demo.Enabled then
		local DemoBalloon = require(script.Parent.DemoBalloon)
		DemoBalloon.Start(Config, Target, HazardService, Remote)
	end

	Players.PlayerRemoving:Connect(function(player)
		demoCycle[player] = nil
		for _, h in hazards do
			if h.target == player then
				leave(h)
			end
		end
	end)

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		local rate = Config.Global.TickRate
		if acc >= rate then
			tick(acc)
			acc = 0
		end
	end)

	task.spawn(function()
		while true do
			task.wait(Config.Global.SpawnInterval)
			for _, player in Players:GetPlayers() do
				if HazardService.IsFlying(player) then
					spawnFor(player)
				end
			end
		end
	end)
end

return HazardService
