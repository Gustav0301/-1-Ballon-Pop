-- Applies the festival sky and lighting when the server starts.

local ServerScriptService = game:GetService("ServerScriptService")

require(ServerScriptService.Services.WorldLook).Apply()
