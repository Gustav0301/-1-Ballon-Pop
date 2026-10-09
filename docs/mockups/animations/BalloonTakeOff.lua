-- BalloonTakeOff · 1+ Ballon Pop (made with Claude, same format as Rig Director)
-- Paste into the Studio command bar. Creates a KeyframeSequence in ServerStorage,
-- ready to open in the Animation Editor or publish to Roblox.

local seq = Instance.new("KeyframeSequence")
seq.Name = "BalloonTakeOff"
seq.Loop = false
seq.Priority = Enum.AnimationPriority.Action

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

do -- t = 0.12s
	local k = kf(0.12)
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.Angles(r(0), r(-8), r(0)), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(6), r(-14), r(0)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(-20), r(-18), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(-18), r(0), r(14)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(34), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(10), r(0), r(-14)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(20), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.new(), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(4), r(-4), r(3)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.Angles(r(-8), r(0), r(0)), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(4), r(0), r(-3)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(4), r(-4), r(-3)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.Angles(r(-8), r(0), r(0)), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(4), r(0), r(3)), "Cubic", "InOut")
end

do -- t = 0.22s
	local k = kf(0.22)
	marker(k, "Grab", "")
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(0, -0.05, 0), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(6), r(0), r(0)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(16), r(0), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(70), r(0), r(-20)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(60), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(74), r(0), r(22)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(56), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(4), r(0), r(3)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.Angles(r(-8), r(0), r(0)), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(4), r(0), r(-3)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(4), r(0), r(-3)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.Angles(r(-8), r(0), r(0)), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(4), r(0), r(3)), "Cubic", "InOut")
end

do -- t = 0.36s
	local k = kf(0.36)
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(0, 0.02, 0), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(-8), r(0), r(0)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(62), r(0), r(-26)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(78), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(62), r(0), r(26)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(78), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(0), r(0), r(3)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.new(), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(0), r(0), r(-3)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(0), r(0), r(-3)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.new(), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(0), r(0), r(3)), "Cubic", "InOut")
end

do -- t = 0.48s
	local k = kf(0.48)
	marker(k, "Puff", "1")
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(0, -0.06, 0), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(9), r(0), r(0)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(-6), r(0), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(56), r(0), r(-24)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(84), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.Angles(r(14), r(0), r(0)), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(56), r(0), r(24)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(84), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.Angles(r(14), r(0), r(0)), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(4), r(0), r(3)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.Angles(r(-8), r(0), r(0)), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(4), r(0), r(-3)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(4), r(0), r(-3)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.Angles(r(-8), r(0), r(0)), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(4), r(0), r(3)), "Cubic", "InOut")
end

do -- t = 0.64s
	local k = kf(0.64)
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(0, 0.02, 0), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(-10), r(0), r(0)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(62), r(0), r(-26)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(78), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(62), r(0), r(26)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(78), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(0), r(0), r(3)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.new(), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(0), r(0), r(-3)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(0), r(0), r(-3)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.new(), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(0), r(0), r(3)), "Cubic", "InOut")
end

do -- t = 0.76s
	local k = kf(0.76)
	marker(k, "Puff", "2")
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(0, -0.06, 0), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(11.25), r(0), r(0)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(-6), r(0), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(56), r(0), r(-24)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(84), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.Angles(r(14), r(0), r(0)), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(56), r(0), r(24)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(84), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.Angles(r(14), r(0), r(0)), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(4), r(0), r(3)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.Angles(r(-8), r(0), r(0)), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(4), r(0), r(-3)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(4), r(0), r(-3)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.Angles(r(-8), r(0), r(0)), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(4), r(0), r(3)), "Cubic", "InOut")
end

do -- t = 0.92s
	local k = kf(0.92)
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(0, 0.02, 0), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(-12), r(0), r(0)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(62), r(0), r(-26)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(78), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(62), r(0), r(26)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(78), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(0), r(0), r(3)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.new(), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(0), r(0), r(-3)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(0), r(0), r(-3)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.new(), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(0), r(0), r(3)), "Cubic", "InOut")
end

do -- t = 1.06s
	local k = kf(1.06)
	marker(k, "Puff", "3")
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(0, -0.06, 0), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(13.5), r(0), r(0)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(-6), r(0), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(56), r(0), r(-24)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(84), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.Angles(r(14), r(0), r(0)), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(56), r(0), r(24)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(84), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.Angles(r(14), r(0), r(0)), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(4), r(0), r(3)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.Angles(r(-8), r(0), r(0)), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(4), r(0), r(-3)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(4), r(0), r(-3)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.Angles(r(-8), r(0), r(0)), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(4), r(0), r(3)), "Cubic", "InOut")
end

do -- t = 1.26s
	local k = kf(1.26)
	marker(k, "Release", "")
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(0, 0.04, 0), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(-8), r(4), r(0)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(24), r(4), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(150), r(0), r(14)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.Angles(r(-12), r(0), r(0)), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(24), r(0), r(-34)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(24), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.new(), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(0), r(0), r(3)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.new(), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(0), r(0), r(-3)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(0), r(0), r(-3)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.new(), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(0), r(0), r(3)), "Cubic", "InOut")
end

do -- t = 1.44s
	local k = kf(1.44)
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(0, -0.46, 0) * CFrame.Angles(r(12), r(0), r(0)), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(4), r(0), r(0)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(18), r(0), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(170), r(0), r(6)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(6), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.Angles(r(-6), r(0), r(0)), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(-30), r(0), r(-18)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(26), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.new(), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(40), r(0), r(4)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.Angles(r(-86), r(0), r(0)), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(34), r(0), r(-4)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(40), r(0), r(-4)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.Angles(r(-86), r(0), r(0)), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(34), r(0), r(4)), "Cubic", "InOut")
end

do -- t = 1.6s
	local k = kf(1.6)
	marker(k, "LiftOff", "")
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(0, 0.4, 0) * CFrame.Angles(r(-4), r(0), r(0)), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(-4), r(0), r(0)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(16), r(0), r(0)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(170), r(0), r(4)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(8), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.new(), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(10), r(0), r(-40)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(20), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.new(), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(-6), r(0), r(4)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.Angles(r(-26), r(0), r(0)), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.Angles(r(-26), r(0), r(-2)), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(22), r(0), r(-4)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.Angles(r(-58), r(0), r(0)), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.Angles(r(-20), r(0), r(2)), "Cubic", "InOut")
end

do -- t = 1.85s
	local k = kf(1.85)
	local root = pose(k, "HumanoidRootPart", CFrame.new(), "Cubic", "InOut")
	local LowerTorso = pose(root, "LowerTorso", CFrame.new(0, 0.74, 0) * CFrame.Angles(r(3), r(0), r(-3)), "Cubic", "InOut")
	local UpperTorso = pose(LowerTorso, "UpperTorso", CFrame.Angles(r(2), r(-2), r(2)), "Cubic", "InOut")
	local Head = pose(UpperTorso, "Head", CFrame.Angles(r(8), r(0), r(1)), "Cubic", "InOut")
	local RightUpperArm = pose(UpperTorso, "RightUpperArm", CFrame.Angles(r(168), r(2), r(5)), "Cubic", "InOut")
	local RightLowerArm = pose(RightUpperArm, "RightLowerArm", CFrame.Angles(r(10), r(0), r(0)), "Cubic", "InOut")
	local RightHand = pose(RightLowerArm, "RightHand", CFrame.new(), "Cubic", "InOut")
	local LeftUpperArm = pose(UpperTorso, "LeftUpperArm", CFrame.Angles(r(-10), r(-4), r(-20)), "Cubic", "InOut")
	local LeftLowerArm = pose(LeftUpperArm, "LeftLowerArm", CFrame.Angles(r(17), r(0), r(0)), "Cubic", "InOut")
	local LeftHand = pose(LeftLowerArm, "LeftHand", CFrame.new(), "Cubic", "InOut")
	local RightUpperLeg = pose(LowerTorso, "RightUpperLeg", CFrame.Angles(r(9), r(0), r(6)), "Cubic", "InOut")
	local RightLowerLeg = pose(RightUpperLeg, "RightLowerLeg", CFrame.Angles(r(-14), r(0), r(0)), "Cubic", "InOut")
	local RightFoot = pose(RightLowerLeg, "RightFoot", CFrame.new(), "Cubic", "InOut")
	local LeftUpperLeg = pose(LowerTorso, "LeftUpperLeg", CFrame.Angles(r(-18), r(0), r(-8)), "Cubic", "InOut")
	local LeftLowerLeg = pose(LeftUpperLeg, "LeftLowerLeg", CFrame.Angles(r(-30), r(0), r(0)), "Cubic", "InOut")
	local LeftFoot = pose(LeftLowerLeg, "LeftFoot", CFrame.new(), "Cubic", "InOut")
end

seq.Parent = game:GetService("ServerStorage")
game:GetService("Selection"):Set({ seq })
print("Created KeyframeSequence '" .. seq.Name .. "' in ServerStorage")

-- Markers the game listens for:
-- track:GetMarkerReachedSignal("Puff"):Connect(function(n) ... end)  -- n = "1", "2", "3"
-- track:GetMarkerReachedSignal("Grab") / ("Release") / ("LiftOff")  (take-off)
-- track:GetMarkerReachedSignal("Touchdown") / ("StandUp")  (landing)
