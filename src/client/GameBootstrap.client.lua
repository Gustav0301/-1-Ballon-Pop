-- Starts the client: hazard visuals, flying and the HUD.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(script.Parent:WaitForChild("Controllers"):WaitForChild("ClientMain")).Start({
	Shared = ReplicatedStorage:WaitForChild("Shared"),
	RemoteParent = ReplicatedStorage,
})
