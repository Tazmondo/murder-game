local MurdererController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ClientMurderer = require(script.ClientMurderer)
local KnifeThrow = require(script.KnifeThrow)
local CharacterUtil = require(ReplicatedStorage.Modules.Shared.CharacterUtil)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Types = require(ReplicatedStorage.Modules.Shared.Types)

local ReplicateAnimationEvent = require(ReplicatedStorage.Events.Murderer.ReplicateAnimationEvent):Client()
local ReplicateKnifeHitEvent = require(ReplicatedStorage.Events.Murderer.ReplicateKnifeHitEvent):Client()
local ReplicateKnifeThrowEvent = require(ReplicatedStorage.Events.Murderer.ReplicateKnifeThrowEvent):Client()

local animationFolder = ReplicatedStorage.Assets.Animations
local knifeHoldAnimation = animationFolder.KnifeHold
local throwPose = animationFolder.KnifeThrowPose

local otherMurderers: { [Player]: Types.LocalMurderer? } = {}

local knifeModel = assert(ReplicatedStorage.Assets.Knife, "No knife model found!") :: Types.KnifeModel
assert(knifeModel.Handle, "Knife had no handle!")
assert(knifeModel.Handle.Grip, "Knife handle had no grip!")

function GetPoseData(character: Model, rootPose: Pose): Types.PoseData
	local motors = {}
	for i, descendant in character:GetDescendants() do
		if descendant:IsA("Motor6D") then
			local part1 = descendant.Part1
			if part1 then
				motors[part1.Name] = descendant
			end
		end
	end

	local poseData = {}
	for i, pose in rootPose:GetDescendants() do
		if pose:IsA("Pose") then
			local motor = motors[pose.Name]
			if not motor then
				warn("Missing motor:", pose.Name)
			end
			poseData[motor] = pose.CFrame
		end
	end

	return poseData
end

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

	local throw = character.animator:LoadAnimation(knifeThrowAnimation)

	local hold = character.animator:LoadAnimation(knifeHoldAnimation)

	hold:Play()
	throw:Play()
	throw:AdjustWeight(0.01)
	throw:AdjustSpeed(0)

	local data: Types.LocalMurderer = {
		lastHeld = 0,
		knife = knife,
		character = character,
		knifeMap = {},
		knifeId = 0,
		throwPose = GetPoseData(character.model, throwPose),
		holding = false,
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

function HandleMurdererAttributeChanged(player: Player)
	local isMurderer = player:GetAttribute(Config.MurdererAttribute)
	if isMurderer then
		MakeMurderer(player)
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

function HandleReplicateKnifeHit(murderer: Player, id: number, didHitPlayer: boolean)
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

function HandleAnimationEvent(murderer: Player, holding: boolean)
	local state = otherMurderers[murderer]
	if not state then
		return
	end

	state.holding = holding
	if holding then
		state.lastHeld = os.clock()
	else
		state.throwTrack:AdjustWeight(0.01)
	end
end

function PlayerAdded(player: Player)
	HandleMurdererAttributeChanged(player)

	player:GetAttributeChangedSignal(Config.MurdererAttribute):Connect(function()
		HandleMurdererAttributeChanged(player)
	end)
end

function PreAnimation()
	for i, murderer in otherMurderers do
		assert(murderer)
		if murderer.holding then
			local throwProgress = math.clamp((os.clock() - murderer.lastHeld) / Config.ThrowTime, 0.01, 1)
			murderer.throwTrack:AdjustWeight(throwProgress)
		end
	end
end

function MurdererController:Initialize()
	ReplicateKnifeThrowEvent:On(HandleReplicateKnifeThrow)
	ReplicateKnifeHitEvent:On(HandleReplicateKnifeHit)
	ReplicateAnimationEvent:On(HandleAnimationEvent)

	RunService.PreAnimation:Connect(PreAnimation)

	Players.PlayerAdded:Connect(PlayerAdded)
	for _, player in Players:GetPlayers() do
		PlayerAdded(player)
	end
end

MurdererController:Initialize()

return MurdererController
