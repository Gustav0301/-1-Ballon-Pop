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
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(138), r(0), r(24)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(18), r(0), r(0)), "Cubic", "InOut")
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

do -- t = 1s
	local k = kf(1)
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(0, 0.04, 0) * CFrame.Angles(r(0), r(0), r(1.5)), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(-4), r(0), r(-1)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(6), r(-6), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(140), r(0), r(25)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(18), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.new(), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(2), r(0), r(-10)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.new(), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(0), r(0), r(1.5)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.new(), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(0), r(0), r(-3)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(0), r(0), r(-4.5)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.new(), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(0), r(0), r(3)), "Cubic", "InOut")
end

do -- t = 1.8s
	local k = kf(1.8)
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(0, 0.02, 0) * CFrame.Angles(r(0), r(-4), r(1.5)), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(-6), r(-6), r(-1)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(28), r(-22), r(2)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(143), r(0), r(24)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(14), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.new(), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(3), r(0), r(-11)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.new(), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(0), r(4), r(1.5)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.new(), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(0), r(0), r(-3)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(0), r(4), r(-4.5)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.new(), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(0), r(0), r(3)), "Cubic", "InOut")
end

do -- t = 2.6s
	local k = kf(2.6)
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(0, 0.02, 0) * CFrame.Angles(r(0), r(-4), r(1.5)), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(-5), r(-6), r(-1)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(26), r(-18), r(2)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(143), r(0), r(24)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(14), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.new(), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(3), r(0), r(-11)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.new(), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(0), r(4), r(1.5)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.new(), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(0), r(0), r(-3)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(0), r(4), r(-4.5)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.new(), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(0), r(0), r(3)), "Cubic", "InOut")
end

do -- t = 2.95s
	local k = kf(2.95)
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(0, 0.12, 0) * CFrame.Angles(r(0), r(-2), r(0)), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(-3), r(-3), r(0)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(14), r(-4), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(158), r(0), r(18)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(4), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.Angles(r(-8), r(0), r(0)), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(-6), r(0), r(-16)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(16), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.new(), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(0), r(2), r(2)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.new(), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(-14), r(0), r(-3)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(0), r(2), r(-2)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.new(), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(-14), r(0), r(3)), "Cubic", "InOut")
end

do -- t = 3.35s
	local k = kf(3.35)
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(0, -0.03, 0), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(1), r(0), r(0)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(2), r(0), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(134), r(0), r(24)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(20), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.new(), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(6), r(0), r(-8)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.new(), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(3), r(0), r(3)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.Angles(r(-6), r(0), r(0)), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(3), r(0), r(-3)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(3), r(0), r(-3)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.Angles(r(-6), r(0), r(0)), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(3), r(0), r(3)), "Cubic", "InOut")
end

do -- t = 4s
	local k = kf(4)
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(-2), r(0), r(0)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(4), r(0), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(138), r(0), r(24)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(18), r(0), r(0)), "Cubic", "InOut")
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
