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
	require(script.Parent.HUDController).Start({
		Shared = opts.Shared,
		RemoteParent = opts.RemoteParent,
		Flight = Flight,
	})
end

return ClientMain
