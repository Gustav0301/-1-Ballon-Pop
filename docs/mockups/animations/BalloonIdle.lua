-- BalloonIdle · 1+ Ballon Pop (made with Claude, same format as Rig Director)
-- Paste into the Studio command bar. Creates a KeyframeSequence in ServerStorage,
-- ready to open in the Animation Editor or publish to Roblox.

local seq = Instance.new("KeyframeSequence")
seq.Name = "BalloonIdle"
seq.Loop = true
seq.Priority = Enum.AnimationPriority.Idle

local function kf(t)
	local k = Instance.new("Keyframe")
	k.Time = t
	k.Parent = seq
	return k
end

local function pose(parent, name, cf, style, dir)
	local p = Instance.new("Pose")
	p.Name = name
	p.CFrame = cf
	p.EasingStyle = Enum.PoseEasingStyle[style]
	p.EasingDirection = Enum.PoseEasingDirection[dir]
	p.Parent = parent
	return p
end

local function marker(k, name, value)
	local m = Instance.new("KeyframeMarker")
	m.Name = name
	m.Value = value
	k:AddMarker(m)
end

local r = math.rad

do -- t = 0s
	local k = kf(0)
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(-2), r(0), r(0)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(4), r(0), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(4), r(0), r(9)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.new(), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(4), r(0), r(-9)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.new(), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(0), r(0), r(3)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.new(), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(0), r(0), r(-3)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(0), r(0), r(-3)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.new(), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(0), r(0), r(3)), "Cubic", "InOut")
end

do -- t = 0.55s
	local k = kf(0.55)
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(0, -0.03, 0), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(4), r(0), r(0)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(-4), r(0), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(14), r(0), r(10)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(24), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.new(), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(14), r(0), r(-10)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(24), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.new(), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(10), r(0), r(3)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.Angles(r(-20), r(0), r(0)), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(10), r(0), r(-3)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(10), r(0), r(-3)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.Angles(r(-20), r(0), r(0)), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(10), r(0), r(3)), "Cubic", "InOut")
end

do -- t = 0.95s
	local k = kf(0.95)
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(0, 0.12, 0), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(-5), r(0), r(0)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(12), r(0), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(-10), r(0), r(16)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(14), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.new(), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(-10), r(0), r(-16)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(14), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.new(), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(0), r(0), r(3)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.new(), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(-16), r(0), r(-3)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(0), r(0), r(-3)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.new(), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(-16), r(0), r(3)), "Cubic", "InOut")
end

do -- t = 1.35s
	local k = kf(1.35)
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(0, -0.03, 0), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(4), r(0), r(0)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(-4), r(0), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(14), r(0), r(10)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(24), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.new(), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(14), r(0), r(-10)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(24), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.new(), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(10), r(0), r(3)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.Angles(r(-20), r(0), r(0)), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(10), r(0), r(-3)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(10), r(0), r(-3)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.Angles(r(-20), r(0), r(0)), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(10), r(0), r(3)), "Cubic", "InOut")
end

do -- t = 1.75s
	local k = kf(1.75)
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(-2), r(0), r(0)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(4), r(0), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(4), r(0), r(9)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.new(), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(4), r(0), r(-9)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.new(), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(0), r(0), r(3)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.new(), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(0), r(0), r(-3)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(0), r(0), r(-3)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.new(), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(0), r(0), r(3)), "Cubic", "InOut")
end

do -- t = 2.45s
	local k = kf(2.45)
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(0, 0.02, 0) * CFrame.Angles(r(0), r(3.6), r(0)), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(-3), r(10.5), r(0)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(26), r(30), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(4), r(0), r(12)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(18), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.new(), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(4), r(0), r(-12)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(18), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.new(), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(0), r(3), r(3)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.new(), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(0), r(0), r(-3)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(0), r(3), r(-3)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.new(), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(0), r(0), r(3)), "Cubic", "InOut")
end

do -- t = 2.95s
	local k = kf(2.95)
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(0, 0.02, 0) * CFrame.Angles(r(0), r(3.6), r(0)), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(-3), r(10.5), r(0)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(26), r(30), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(4), r(0), r(12)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(18), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.new(), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(4), r(0), r(-12)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(18), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.new(), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(0), r(3), r(3)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.new(), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(0), r(0), r(-3)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(0), r(3), r(-3)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.new(), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(0), r(0), r(3)), "Cubic", "InOut")
end

do -- t = 3.45s
	local k = kf(3.45)
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(0, 0.02, 0) * CFrame.Angles(r(0), r(-2.88), r(0)), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(-3), r(-8.4), r(0)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(14), r(-24), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(4), r(0), r(12)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(18), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.new(), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(4), r(0), r(-12)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(18), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.new(), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(0), r(-2.4), r(3)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.new(), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(0), r(0), r(-3)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(0), r(-2.4), r(-3)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.new(), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(0), r(0), r(3)), "Cubic", "InOut")
end

do -- t = 4s
	local k = kf(4)
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(-2), r(0), r(0)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(4), r(0), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(4), r(0), r(9)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.new(), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(4), r(0), r(-9)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.new(), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(0), r(0), r(3)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.new(), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(0), r(0), r(-3)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(0), r(0), r(-3)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.new(), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(0), r(0), r(3)), "Cubic", "InOut")
end

seq.Parent = game:GetService("ServerStorage")
game:GetService("Selection"):Set({ seq })
print("Created KeyframeSequence '" .. seq.Name .. "' in ServerStorage")
