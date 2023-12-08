local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Future = require(ReplicatedStorage.Packages.Future)

local LoadedEvent = require(ReplicatedStorage.Events.LoadedEvent):Server()

-- Checks if a player is loaded

local LoadedService = {}

LoadedEvent:On(function(player: Player)
	print(player, "Loaded.")
	player:SetAttribute("LoadedService_Loaded", true)
end)

function IsClientLoaded(player: Player)
	return player:GetAttribute("LoadedService_Loaded") == true
end

function LoadedService:ClientLoaded(player: Player)
	local loaded = Future.Try(function(player: Player)
		while not IsClientLoaded(player) do
			if player.Parent == nil then
				return false
			end
			task.wait()
		end
		return true
	end, player)

	return loaded
end

return LoadedService
