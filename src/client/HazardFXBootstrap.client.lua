-- Starts the client side of the hazards: stud models, animation and VFX.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HazardFXController = require(script.Parent:WaitForChild("Controllers"):WaitForChild("HazardFXController"))

HazardFXController.Start({
	Shared = ReplicatedStorage:WaitForChild("Shared"),
	RemoteParent = ReplicatedStorage,
})
