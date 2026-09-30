-- Starts the server: world look, saves, flying and hazards.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

require(ServerScriptService.Services.ServerMain).Start({
	Shared = ReplicatedStorage.Shared,
	RemoteParent = ReplicatedStorage,
})
