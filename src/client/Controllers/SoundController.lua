--!strict
-- SoundController: plays SoundConfig sounds on game events, so the rest of the code only
-- has to call Sound.Play("Buy") for menu clicks. It listens itself to: your flight state,
-- FlightNet (banked), HazardFX (hits, pops), and plays the ground / sky music.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local SoundController = {}

local LocalPlayer = Players.LocalPlayer

local Config: any
local folder: Folder
local loops: { [string]: Sound } = {}
local music: { [string]: Sound } = {}
local Flight: any

local function def(name: string): any?
	local d = Config and Config.Sounds[name]
	if not d or d.Id == nil or d.Id == "" then
		return nil
	end
	return d
end

local function make(d: any, parent: Instance): Sound
	local s = Instance.new("Sound")
	s.SoundId = d.Id
	s.Volume = d.Volume
	s.PlaybackSpeed = d.Pitch or 1
	s.Looped = d.Loop == true
	s.Parent = parent
	return s
end

-- Play a sound once. opts.Pitch multiplies the pitch; opts.At plays it in 3D there.
function SoundController.Play(name: string, opts: { Pitch: number?, At: Vector3?, Volume: number? }?)
	local d = def(name)
	if not d then
		return
	end
	local o: any = opts or {}
	local parent: Instance = folder
	local holder: Part? = nil
	if o.At then
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Transparency = 1
		p.Size = Vector3.one
		p.Position = o.At
		p.Parent = workspace
		holder = p
		parent = p
	end
	local s = make(d, parent)
	local vary = d.Vary or 0
	s.PlaybackSpeed = (d.Pitch or 1) * (o.Pitch or 1) * (1 + (math.random() * 2 - 1) * vary)
	s.Volume = d.Volume * (o.Volume or 1)
	if holder then
		s.RollOffMaxDistance = 400
		s.RollOffMinDistance = 20
	end
	s:Play()
	s.Ended:Once(function()
		(holder or s):Destroy()
	end)
	task.delay(10, function()
		if (holder or s).Parent then
			(holder or s):Destroy()
		end
	end)
end

-- Start / stop a looping sound (e.g. LetOut).
function SoundController.Loop(name: string, on: boolean)
	local existing = loops[name]
	if on and not existing then
		local d = def(name)
		if not d then
			return
		end
		local created = make(d, folder)
		created.Looped = true
		loops[name] = created
		created:Play()
	elseif not on and existing then
		loops[name] = nil
		local fade = TweenService:Create(existing, TweenInfo.new(0.15), { Volume = 0 })
		fade:Play()
		fade.Completed:Once(function()
			existing:Destroy()
		end)
	end
end

local function setMusic(which: string)
	for name, s in music do
		local d = def(name)
		local target = if name == which and d then d.Volume else 0
		TweenService:Create(s, TweenInfo.new(Config.MusicFade), { Volume = target }):Play()
	end
end

export type StartOptions = { Shared: Instance, RemoteParent: Instance, Flight: any }

function SoundController.Start(opts: StartOptions)
	Config = require(opts.Shared:WaitForChild("Config"):WaitForChild("SoundConfig") :: ModuleScript) :: any
	Flight = opts.Flight
	local f = Instance.new("Folder")
	f.Name = "BalloonSounds"
	f.Parent = SoundService
	folder = f

	-- music: both tracks run, we crossfade the volume
	for _, name in { "MusicGround", "MusicSky" } do
		local d = def(name)
		if d then
			local s = make(d, folder)
			s.Volume = 0
			s.Looped = true
			s:Play()
			music[name] = s
		end
	end
	local current = ""

	-- flight state changes
	local last = LocalPlayer:GetAttribute("FlightState")
	LocalPlayer:GetAttributeChangedSignal("FlightState"):Connect(function()
		local s = LocalPlayer:GetAttribute("FlightState")
		if s == "Flying" and last == "Ground" then
			SoundController.Play("Launch")
		elseif s == "Landing" then
			SoundController.Play("LandStart")
		elseif s == "Falling" then
			SoundController.Play("Fall")
		end
		last = s
	end)
	LocalPlayer:GetAttributeChangedSignal("Maxed"):Connect(function()
		if LocalPlayer:GetAttribute("Maxed") == true then
			SoundController.Play("Max")
		end
	end)

	local flightNet = opts.RemoteParent:WaitForChild("FlightNet") :: RemoteEvent
	flightNet.OnClientEvent:Connect(function(kind: string)
		if kind == "Banked" then
			SoundController.Play("Bank")
		end
	end)
	task.spawn(function()
		local fx = opts.RemoteParent:WaitForChild("HazardFX", 30) :: RemoteEvent?
		if not fx then
			return
		end
		fx.OnClientEvent:Connect(function(kind: string, ...)
			local args = { ... }
			if kind == "Hit" and args[2] == LocalPlayer.UserId then
				SoundController.Play("Hit")
			elseif kind == "Pop" then
				local pos: Vector3 = args[2]
				local player = Players:GetPlayerByUserId(args[1])
				local size = if player then (player:GetAttribute("Size") :: number?) or 1 else 1
				-- bigger balloons pop deeper
				SoundController.Play("Pop", { At = pos, Pitch = math.clamp(1.25 - math.log10(math.max(size, 1)) * 0.2, 0.6, 1.25) })
			end
		end)
	end)

	-- per frame: coin ticks while you earn, the let-out hiss, and the music
	local lastTick, lastUnbanked = 0, 0
	RunService.Heartbeat:Connect(function()
		local s = LocalPlayer:GetAttribute("FlightState")
		local flying = s == "Flying" or s == "Landing"
		SoundController.Loop("LetOut", flying and Flight ~= nil and Flight.LettingOut == true)

		local unbanked = (LocalPlayer:GetAttribute("Unbanked") :: number?) or 0
		local now = os.clock()
		if flying and unbanked > lastUnbanked and now - lastTick > 0.9 then
			lastTick = now
			local size = (LocalPlayer:GetAttribute("Size") :: number?) or 1
			SoundController.Play("Tick", { Pitch = 0.9 + math.min(0.6, size / 400) })
		end
		lastUnbanked = unbanked

		local character = LocalPlayer.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local high = hrp ~= nil and hrp.Position.Y > Config.SkyMusicAbove
		local want = if flying or high then "MusicSky" else "MusicGround"
		if want ~= current then
			current = want
			setMusic(want)
		end
	end)
end

return SoundController
