local MurdererService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local LoadedService = require(script.Parent.LoadedService)

type Murderer = {}

local murderers: { [Player]: Murderer? } = {}

function SetMurdererAttribute(player: Player, enabled: boolean)
	if enabled then
		player:SetAttribute(Config.MurdererAttribute, true)
	else
		player:SetAttribute(Config.MurdererAttribute, nil)
	end
end

function MurdererService:MakeMurderer(player: Player)
	print("Making", player, "a murderer")
	murderers[player] = {}
	SetMurdererAttribute(player, true)
end

function PlayerRemoving(player: Player)
	murderers[player] = nil
end

function MurdererService:Initialize()
	Players.PlayerRemoving:Connect(PlayerRemoving)

	task.spawn(function()
		local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
		player.CharacterAdded:Wait()
		LoadedService:ClientLoaded(player):Await()
		MurdererService:MakeMurderer(player)
	end)
end

MurdererService:Initialize()

return MurdererService
