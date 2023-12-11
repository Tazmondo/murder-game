local MurdererController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientMurderer = require(script.ClientMurderer)
local KnifeThrow = require(script.KnifeThrow)
local CharacterUtil = require(ReplicatedStorage.Modules.Shared.CharacterUtil)
local Types = require(ReplicatedStorage.Modules.Shared.Types)

local CreateMurdererEvent = require(ReplicatedStorage.Events.Murderer.CreateMurdererEvent):Client()
local ReplicateKnifeHitEvent = require(ReplicatedStorage.Events.Murderer.ReplicateKnifeHitEvent):Client()
local ReplicateKnifeThrowEvent = require(ReplicatedStorage.Events.Murderer.ReplicateKnifeThrowEvent):Client()

local otherMurderers: { [Player]: Types.LocalMurderer? } = {}

local knifeModel = assert(ReplicatedStorage.Assets.Knife, "No knife model found!") :: Types.KnifeModel
assert(knifeModel.Handle, "Knife had no handle!")
assert(knifeModel.Handle.Grip, "Knife handle had no grip!")

function MakeMurderer(player: Player)
	print("Making", player, "a murderer")

	local character = CharacterUtil:GetCharacterFromPlayer(player)
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

	local data: Types.LocalMurderer = {
		lastThrown = 0,
		knife = knife,
		character = character,
		knifeMap = {},
		knifeId = 0,
	}

	if player == Players.LocalPlayer then
		ClientMurderer:InitializeMurderer(character, knife, data)
	else
		otherMurderers[player] = data
		player.CharacterRemoving:Once(function()
			ClearMurderer(player)
		end)
		character.humanoid.Died:Once(function()
			ClearMurderer(player)
		end)
	end
end

function ClearMurderer(player: Player)
	local state = otherMurderers[player]
	if state then
		state.knife:Destroy()
		otherMurderers[player] = nil
	end
end

function HandleReplicateKnifeThrow(murderer: Player, origin: CFrame, id: number)
	local state = otherMurderers[murderer]
	if not state then
		return
	end

	local globalId = KnifeThrow:Throw(origin, state.knife, state.character, id)
	state.knifeMap[id] = globalId
end

function HandlereplicateKnifeHit(murderer: Player, id: number, didHitPlayer: boolean)
	local state = otherMurderers[murderer]
	if not state then
		return
	end

	local globalKnife = state.knifeMap[id]
	if not globalKnife then
		return
	end

	-- Only delete knife if it hit a player, as server will handle player ragdolls
	if didHitPlayer then
		KnifeThrow:DeleteKnife(id)
	end
end

function HandleCreateMurdererEvent(murderer: Player)
	MakeMurderer(murderer)
end

function MurdererController:Initialize()
	ReplicateKnifeThrowEvent:On(HandleReplicateKnifeThrow)
	ReplicateKnifeHitEvent:On(HandlereplicateKnifeHit)
	CreateMurdererEvent:On(HandleCreateMurdererEvent)
end

MurdererController:Initialize()

return MurdererController
