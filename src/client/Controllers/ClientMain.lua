--!strict
-- ClientMain: starts every client controller. Called by GameBootstrap (Rojo) or by the
-- GamePack's Run script (drag-in build).

local ClientMain = {}

export type StartOptions = {
	Shared: Instance,
	RemoteParent: Instance,
}

function ClientMain.Start(opts: StartOptions)
	require(script.Parent.HazardFXController).Start(opts)
	local Flight = require(script.Parent.FlightController)
	Flight.Start(opts)
	local Sound = require(script.Parent.SoundController)
	Sound.Start({ Shared = opts.Shared, RemoteParent = opts.RemoteParent, Flight = Flight })
	local HUD = require(script.Parent.HUDController)
	HUD.Start({ Shared = opts.Shared, RemoteParent = opts.RemoteParent, Flight = Flight, Sound = Sound })
	require(script.Parent.MenuController).Start({
		Shared = opts.Shared,
		RemoteParent = opts.RemoteParent,
		HUD = HUD,
		Sound = Sound,
	})
end

return ClientMain
