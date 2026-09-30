--!strict
-- ServerMain: starts every server system in order. Called by GameBootstrap (Rojo) or by
-- the GamePack's Start script (drag-in build), with the Shared folder's location.

local ServerMain = {}

export type StartOptions = {
	Shared: Instance,
	RemoteParent: Instance,
}

function ServerMain.Start(opts: StartOptions)
	local services = script.Parent
	require(services.WorldLook).Apply()

	local DataService = require(services.DataService)
	DataService.Start()

	-- HazardService first: it makes the HazardFX remote that FlightService fires pops on
	local HazardService = require(services.HazardService)
	local FlightService = require(services.FlightService)
	HazardService.IsFlying = FlightService.IsHuntable
	HazardService.Hit.Event:Connect(function(player: Player, damage: number)
		FlightService.Damage(player, damage)
	end)
	HazardService.Start({ Shared = opts.Shared, RemoteParent = opts.RemoteParent, Demo = false })
	FlightService.Start({ Shared = opts.Shared, RemoteParent = opts.RemoteParent })
	require(services.BalloonService).Start({ Shared = opts.Shared, RemoteParent = opts.RemoteParent })
end

return ServerMain
