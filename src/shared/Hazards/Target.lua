--!strict
-- Target: where is a player's balloon? Server and client both use this, so hit
-- checks and visuals agree. When FlightService exists, point Target.Resolver at it.

local Players = game:GetService("Players")

local Target = {}

export type Resolver = (player: Player) -> (Vector3?, number?)

local function fromInstance(balloon: Instance): (Vector3?, number?)
	if balloon:IsA("Model") then
		local primary = balloon.PrimaryPart
		if primary then
			local extent = balloon:GetExtentsSize()
			return primary.Position, math.max(extent.X, extent.Y, extent.Z) / 2
		end
		local cf, size = balloon:GetBoundingBox()
		return cf.Position, math.max(size.X, size.Y, size.Z) / 2
	elseif balloon:IsA("BasePart") then
		local s = balloon.Size
		return balloon.Position, math.max(s.X, s.Y, s.Z) / 2
	end
	return nil, nil
end

-- Default lookup: a Model or Part named "Balloon" inside the character, or
-- workspace.Balloons[player.Name]. Returns (position, radius).
function Target.Default(player: Player): (Vector3?, number?)
	local character = player.Character
	local balloon = character and character:FindFirstChild("Balloon")
	if not balloon then
		local folder = workspace:FindFirstChild("Balloons")
		balloon = folder and folder:FindFirstChild(player.Name)
	end
	if balloon then
		return fromInstance(balloon)
	end
	return nil, nil
end

Target.Resolver = Target.Default :: Resolver

function Target.GetBalloon(player: Player?): (Vector3?, number?)
	if not player or player.Parent ~= Players then
		return nil, nil
	end
	return Target.Resolver(player)
end

return Target
