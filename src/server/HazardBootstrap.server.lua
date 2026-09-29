-- Starts the hazard system. Demo = true gives every player a test Gumball balloon and
-- cycles all four hazards around them, so the attacks can be seen before FlightService
-- exists. Set Demo = false once FlightService provides real balloons (see docs/HAZARDS.md).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local HazardService = require(ServerScriptService.Services.HazardService)

HazardService.Start({
	Shared = ReplicatedStorage.Shared,
	RemoteParent = ReplicatedStorage,
	Demo = true,
})
