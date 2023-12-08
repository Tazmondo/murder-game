local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterUtil = require(ReplicatedStorage.Modules.Shared.CharacterUtil)
local LoadedService = require(script.Parent.LoadedService)
local MurdererService = {}

type Knife = Model & {
	Handle: BasePart & {
		Grip: Attachment,
	},
}

local knifeModel = assert(ReplicatedStorage.Assets.Knife, "No knife model found!") :: Knife
assert(knifeModel.Handle, "Knife had no handle!")
assert(knifeModel.Handle.Grip, "Knife handle had no grip!")

function MurdererService:MakeMurderer(player: Player)
	print("Making", player, "a murderer")
	local character = CharacterUtil:GetCharacter(player)
	if not character then
		warn("Tried to make a player without a character a murderer")
		return
	end

	local rightHand = character.model:FindFirstChild("RightHand") :: BasePart?
	assert(rightHand, "Character did not have a right hand!")
	local rightGripAttachment = rightHand:FindFirstChild("RightGripAttachment") :: Attachment?
	assert(rightGripAttachment, "Right hand did not have a grip attachment.")

	local knife = knifeModel:Clone()
	local motor = Instance.new("Motor6D")
	motor.Part0 = rightHand
	motor.Part1 = knife.Handle
	motor.C0 = rightGripAttachment.CFrame
	motor.C1 = knifeModel.Handle.Grip.CFrame

	motor.Parent = knife.Handle

	knife.Parent = character.model
end

function MurdererService:Initialize()
	task.spawn(function()
		local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
		LoadedService:ClientLoaded(player):Await()
		player.CharacterAdded:Wait()
		MurdererService:MakeMurderer(player)
	end)
end

MurdererService:Initialize()

return MurdererService
