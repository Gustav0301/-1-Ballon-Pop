--!strict
-- HazardFXController: builds a stud model for every hazard root the server creates,
-- animates it every frame, and plays attacks in sync with the server's messages:
--   "Begin"(id, targetUserId, serverTime)   attack starts (all clients, synced by server time)
--   "Lock"(id, lockPos, launchPos)          aim point locked, dodge window starts
--   "Hit"(id, userId, damage)               a balloon got hit (damage number + extra shake for you)
--   "Cancel"(id)                            a rider swatted it mid-attack
--   "Pop"(userId, pos, color)               demo balloon popped into brick confetti

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local HazardFXController = {}

local LocalPlayer = Players.LocalPlayer

local Config: any
local Target: any
local VFX: any
local Visuals: { [string]: any } = {}
local rigs: { [number]: any } = {}
local folder: Folder

--------------------------------------------------------------------------------
-- Attack context: timing, target tracking and cleanup for one attack

local Ctx = {}
Ctx.__index = Ctx

function Ctx.new(rig: any, player: Player?, serverT0: number)
	local elapsed = math.max(0, workspace:GetServerTimeNow() - serverT0)
	local self = setmetatable({
		rig = rig,
		cfg = rig.cfg,
		player = player,
		start = os.clock() - elapsed,
		items = {},
		cancelled = false,
		finished = false,
		lockPos = nil :: Vector3?,
		launchPos = nil :: Vector3?,
		lastTarget = nil :: Vector3?,
		radius = 2.5,
	}, Ctx)
	return self
end

function Ctx.Time(self: any): number
	return os.clock() - self.start
end

-- Yields until `t` seconds into the attack. Returns false if the attack was cancelled.
function Ctx.WaitUntil(self: any, t: number): boolean
	while not self.cancelled and self:Time() < t do
		RunService.Heartbeat:Wait()
	end
	return not self.cancelled
end

-- The balloon position: live until the server locks it, then the locked point.
function Ctx.Target(self: any): (Vector3, number)
	if self.lockPos then
		return self.lockPos, self.radius
	end
	local pos, radius = Target.GetBalloon(self.player)
	if pos then
		self.lastTarget = pos
		self.radius = radius or self.radius
	end
	local fallback = self.rig.cf.Position + self.rig.cf.LookVector * 20
	return self.lastTarget or fallback, self.radius
end

-- Waits for the server's lock (with a small grace period), then returns the locked point.
function Ctx.WaitLock(self: any): Vector3?
	local deadline = self.cfg.LockTime + 0.35
	while not self.cancelled and not self.lockPos and self:Time() < deadline do
		RunService.Heartbeat:Wait()
	end
	if self.cancelled then
		return nil
	end
	if not self.lockPos then
		self.lockPos = (self:Target())
	end
	return self.lockPos
end

function Ctx.Add(self: any, item: any): any
	table.insert(self.items, item)
	return item
end

function Ctx.Cleanup(self: any)
	for _, item in self.items do
		if typeof(item) == "Instance" then
			item:Destroy()
		elseif type(item) == "function" then
			item()
		elseif type(item) == "table" then
			if item.Stop then
				item:Stop()
			elseif item.Destroy then
				item:Destroy()
			end
		end
	end
	table.clear(self.items)
end

function Ctx.Cancel(self: any)
	if self.cancelled then
		return
	end
	self.cancelled = true
	self:Cleanup()
end

--------------------------------------------------------------------------------

local function finish(rig: any, ctx: any)
	ctx:Cleanup()
	if rig.ctx == ctx then
		rig.ctx = nil
		rig.follow = true
		local visual = Visuals[rig.kind]
		if visual and visual.Reset then
			visual.Reset(rig)
		end
	end
end

local function addRig(root: Instance)
	if not root:IsA("BasePart") then
		return
	end
	local kind = root:GetAttribute("Kind")
	local id = root:GetAttribute("HazardId")
	if type(kind) ~= "string" then
		return
	end
	local visual = Visuals[kind]
	local cfg = Config.Types[kind]
	if not visual or not cfg or type(id) ~= "number" then
		return
	end
	local rig = visual.Build(cfg)
	rig.root = root
	rig.cf = root.CFrame
	rig.data.parent = folder
	rig.model.Parent = folder
	rigs[id] = rig
	visual.Animate(rig, 0)
	-- arrival poof
	VFX.Cubes({ Pos = root.Position, Count = 14, Colors = { cfg.Color, cfg.Hot }, Speed = { 6, 14 }, Size = { 0.3, 0.6 }, Life = { 0.3, 0.6 }, Drag = 3, Neon = true })
end

local function removeRig(id: number)
	local rig = rigs[id]
	if not rig then
		return
	end
	rigs[id] = nil
	if rig.ctx then
		rig.ctx:Cancel()
	end
	VFX.Cubes({ Pos = rig.cf.Position, Count = 12, Colors = { rig.cfg.Color, rig.cfg.Hot }, Speed = { 5, 12 }, Size = { 0.3, 0.6 }, Life = { 0.3, 0.6 }, Drag = 3, Neon = true })
	rig:Destroy()
end

local function onMessage(kind: string, ...: any)
	local args = { ... }
	if kind == "Begin" then
		local id, userId, serverT0 = args[1], args[2], args[3]
		local rig = rigs[id]
		if not rig then
			return
		end
		if rig.ctx then
			rig.ctx:Cancel()
		end
		local ctx = Ctx.new(rig, Players:GetPlayerByUserId(userId), serverT0)
		rig.ctx = ctx
		local visual = Visuals[rig.kind]
		task.spawn(function()
			local ok, err = pcall(visual.Attack, rig, ctx)
			if not ok then
				warn("[HazardFX] " .. rig.kind .. " attack error: " .. tostring(err))
			end
			finish(rig, ctx)
		end)
	elseif kind == "Lock" then
		local rig = rigs[args[1]]
		if rig and rig.ctx then
			rig.ctx.lockPos = args[2]
			rig.ctx.launchPos = args[3]
		end
	elseif kind == "Cancel" then
		local rig = rigs[args[1]]
		if rig and rig.ctx then
			local ctx = rig.ctx
			ctx:Cancel()
			finish(rig, ctx)
			-- knocked away: a dizzy cube puff and a spin
			VFX.Cubes({ Pos = rig.cf.Position, Count = 18, Colors = { rig.cfg.Color, Color3.new(1, 1, 1) }, Speed = { 8, 16 }, Size = { 0.3, 0.6 }, Life = { 0.3, 0.6 }, Drag = 3, Neon = true })
			VFX.Star(rig.cf.Position, rig.cfg.Hot, 5, 0.3)
		end
	elseif kind == "Hit" then
		local id, userId, damage = args[1], args[2], args[3]
		local rig = rigs[id]
		local player = Players:GetPlayerByUserId(userId)
		local pos = player and Target.GetBalloon(player)
		if pos then
			local color = if rig then rig.cfg.Hot else Color3.new(1, 1, 1)
			VFX.Popup(pos + Vector3.new(2.5, 2, 0), "-" .. tostring(damage), color)
		end
		if player == LocalPlayer then
			VFX.Shake(nil, 0.55)
			if rig then
				VFX.Tint(rig.cfg.Color, 0.45, 0.4)
			end
		end
	elseif kind == "Pop" then
		local pos: Vector3, color: Color3 = args[2], args[3]
		VFX.Flash(pos, Color3.new(1, 1, 1), 9, 0.35)
		VFX.Cubes({ -- brick confetti: studded plates that tumble down
			Pos = pos,
			Count = 60,
			Colors = { color, Color3.fromHex("D9232F"), Color3.fromHex("FF9A9A"), Color3.new(1, 1, 1) },
			Speed = { 14, 34 },
			Size = { 0.7, 1.3 },
			Life = { 1.2, 2 },
			Gravity = -45,
			Drag = 1.2,
			Neon = false,
			Plate = true,
			Shrink = false,
			Spin = 14,
		})
		VFX.SquareRing(CFrame.new(pos) * CFrame.Angles(math.pi / 2, 0, 0), color, 2, 22, 0.7, 0.5)
		VFX.Sparkles(pos, color, 40, 34)
		VFX.Light(pos, color, 12, 34, 0.5)
		VFX.Shake(pos, 0.9)
		if args[1] == LocalPlayer.UserId then
			VFX.Popup(pos + Vector3.new(0, 3, 0), "POP!", Color3.new(1, 1, 1))
		end
	end
end

--------------------------------------------------------------------------------

export type StartOptions = {
	Shared: Instance,
	RemoteParent: Instance,
}

function HazardFXController.Start(opts: StartOptions)
	local shared = opts.Shared
	local hazardsFolder = shared:WaitForChild("Hazards")
	Config = require(shared:WaitForChild("Config"):WaitForChild("HazardConfig") :: ModuleScript) :: any
	Target = require(hazardsFolder:WaitForChild("Target") :: ModuleScript) :: any
	VFX = require(hazardsFolder:WaitForChild("VFX") :: ModuleScript) :: any
	local visualsFolder = hazardsFolder:WaitForChild("Visuals")
	for kind in Config.Types do
		Visuals[kind] = require(visualsFolder:WaitForChild(kind) :: ModuleScript) :: any
	end

	local existing = workspace:FindFirstChild("HazardVisuals")
	if existing then
		existing:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "HazardVisuals"
	folder.Parent = workspace
	local fx = Instance.new("Folder")
	fx.Name = "FX"
	fx.Parent = folder
	VFX.Folder = fx
	VFX.ShakeDistance = Config.Global.ShakeDistance
	VFX.BindCamera()

	local remote = opts.RemoteParent:WaitForChild("HazardFX") :: RemoteEvent
	remote.OnClientEvent:Connect(onMessage)

	local hazards = workspace:WaitForChild("Hazards")
	for _, child in hazards:GetChildren() do
		addRig(child)
	end
	hazards.ChildAdded:Connect(addRig)
	hazards.ChildRemoved:Connect(function(child)
		local id = child:GetAttribute("HazardId")
		if type(id) == "number" then
			removeRig(id)
		end
	end)

	local visibleDist = Config.Global.VisibleDistance
	RunService.RenderStepped:Connect(function(dt)
		VFX.Step(dt)
		local cam = workspace.CurrentCamera
		local camPos = if cam then cam.CFrame.Position else Vector3.zero
		for _, rig in rigs do
			local root = rig.root
			if rig.follow and root then
				rig.cf = rig.cf:Lerp(root.CFrame, 1 - math.exp(-10 * dt))
			end
			rig.t += dt
			local near = (rig.cf.Position - camPos).Magnitude <= visibleDist
			rig:Show(near or rig.ctx ~= nil)
			if rig.visible then
				Visuals[rig.kind].Animate(rig, dt)
			end
		end
	end)
end

return HazardFXController
