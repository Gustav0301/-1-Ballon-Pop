--!strict
-- WorldLook: the bright "Balloon Festival" sky from the reference art.
-- Warm early-afternoon sun, a soft blue haze that hides the horizon edge, gentle bloom so
-- Neon glows, a little extra colour, and dynamic stud-friendly clouds.
-- Runs on the server; Lighting changes replicate to every player.
-- (Lighting.Technology can't be set from a script: set it to Future in Studio for the best look.)

local Lighting = game:GetService("Lighting")

local WorldLook = {}

local function ensure<T>(parent: Instance, className: string, name: string): T
	local found = parent:FindFirstChildOfClass(className)
	if found then
		return found :: any
	end
	local created = Instance.new(className :: any)
	created.Name = name
	created.Parent = parent
	return created :: any
end

function WorldLook.Apply()
	Lighting.ClockTime = 13.6
	Lighting.GeographicLatitude = 28
	Lighting.Brightness = 2.6
	Lighting.ExposureCompensation = 0.1
	Lighting.Ambient = Color3.fromRGB(118, 128, 150)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 166, 192)
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.4
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.3

	local sky = ensure(Lighting, "Sky", "FestivalSky") :: Sky
	sky.CelestialBodiesShown = true
	sky.SunAngularSize = 14
	sky.MoonAngularSize = 9
	sky.StarCount = 1500

	local atmosphere = ensure(Lighting, "Atmosphere", "FestivalHaze") :: Atmosphere
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(199, 225, 255)
	atmosphere.Decay = Color3.fromRGB(110, 172, 232)
	atmosphere.Glare = 0.35
	atmosphere.Haze = 1.4

	local bloom = ensure(Lighting, "BloomEffect", "FestivalBloom") :: BloomEffect
	bloom.Intensity = 0.45
	bloom.Size = 22
	bloom.Threshold = 1.6

	local rays = ensure(Lighting, "SunRaysEffect", "FestivalSunRays") :: SunRaysEffect
	rays.Intensity = 0.05
	rays.Spread = 0.7

	-- a dedicated colour pass (HazardVFX uses its own "HazardTint" for hit flashes)
	local grade = Lighting:FindFirstChild("FestivalGrade") :: ColorCorrectionEffect?
	if not grade then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "FestivalGrade"
		cc.Parent = Lighting
		grade = cc
	end
	local g = grade :: ColorCorrectionEffect
	g.Saturation = 0.18
	g.Contrast = 0.06
	g.Brightness = 0.02

	local clouds = ensure(workspace.Terrain, "Clouds", "FestivalClouds") :: Clouds
	clouds.Cover = 0.52
	clouds.Density = 0.45
	clouds.Color = Color3.fromRGB(255, 255, 255)
end

return WorldLook
