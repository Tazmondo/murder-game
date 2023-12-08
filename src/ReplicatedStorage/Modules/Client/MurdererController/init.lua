local MurdererController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientMurderer = require(script.ClientMurderer)
local CharacterUtil = require(ReplicatedStorage.Modules.Shared.CharacterUtil)
local Config = require(ReplicatedStorage.Modules.Shared.Config)

type Knife = Model & {
	Handle: BasePart & {
		Grip: Attachment,
	},
}

local knifeModel = assert(ReplicatedStorage.Assets.Knife, "No knife model found!") :: Knife
assert(knifeModel.Handle, "Knife had no handle!")
assert(knifeModel.Handle.Grip, "Knife handle had no grip!")

function MakeMurderer(player: Player)
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
	motor.Archivable = false -- Prevents the motor6d from existing when it is cloned later on to throw the knife

	motor.Parent = knife.Handle

	knife.Parent = character.model

	if player == Players.LocalPlayer then
		ClientMurderer:InitializeMurderer(character, knife)
	end
end

function HandleMurdererAttributeChanged(player: Player)
	local isMurderer = player:GetAttribute(Config.MurdererAttribute)
	if isMurderer then
		MakeMurderer(player)
	end
end

function PlayerAdded(player: Player)
	HandleMurdererAttributeChanged(player)
	player:GetAttributeChangedSignal(Config.MurdererAttribute):Connect(function()
		HandleMurdererAttributeChanged(player)
	end)
end

function MurdererController:Initialize()
	Players.PlayerAdded:Connect(PlayerAdded)
	for _, player in Players:GetPlayers() do
		PlayerAdded(player)
	end
end

MurdererController:Initialize()

return MurdererController
