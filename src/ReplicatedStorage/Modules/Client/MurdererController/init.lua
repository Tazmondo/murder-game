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

local murderers: { [Player]: Types.LocalMurderer? } = {}

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
				continue
			end
			if pose.CFrame ~= CFrame.new() then
				poseData[motor] = pose.CFrame
			end
		end
	end

	return poseData
end

function ApplyPose(poseData: Types.PoseData, weight: number)
	weight = math.clamp(weight, 0, 1)
	for motor, transform in poseData do
		motor.Transform = motor.Transform:Lerp(transform, weight)
	end
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

	local hold = character.animator:LoadAnimation(knifeHoldAnimation)

	hold:Play()

	local data: Types.LocalMurderer = {
		lastHeld = 0,
		knife = knife,
		character = character,
		knifeMap = {},
		knifeId = 0,
		throwPose = GetPoseData(character.model, throwPose),
		throwWeight = 0,
		holding = false,
	}

	murderers[player] = data
	player.CharacterRemoving:Once(function()
		ClearMurderer(player)
	end)
	character.humanoid.Died:Once(function()
		ClearMurderer(player)
	end)
	if player == Players.LocalPlayer then
		ClientMurderer:InitializeMurderer(character, knife, data)
	end
end

function ClearMurderer(player: Player)
	local state = murderers[player]
	if state then
		state.knife:Destroy()
		murderers[player] = nil
	end
end

function HandleMurdererAttributeChanged(player: Player)
	local isMurderer = player:GetAttribute(Config.MurdererAttribute)
	if isMurderer then
		MakeMurderer(player)
	end
end

function HandleReplicateKnifeThrow(murderer: Player, origin: CFrame, id: number)
	local state = murderers[murderer]
	if not state then
		return
	end

	local globalId = KnifeThrow:Throw(origin, state.knife, state.character, id)
	state.knifeMap[id] = globalId
end

function HandleReplicateKnifeHit(murderer: Player, id: number, didHitPlayer: boolean)
	local state = murderers[murderer]
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
	local state = murderers[murderer]
	if not state then
		return
	end

	state.holding = holding
	if holding then
		state.lastHeld = os.clock()
	end
end

function PlayerAdded(player: Player)
	HandleMurdererAttributeChanged(player)

	player:GetAttributeChangedSignal(Config.MurdererAttribute):Connect(function()
		HandleMurdererAttributeChanged(player)
	end)
end

function Stepped()
	for i, murderer in murderers do
		assert(murderer)
		local throwProgress = if murderer.holding
			then math.clamp((os.clock() - murderer.lastHeld) / Config.ThrowTime, 0.01, 1)
			else 0
		ApplyPose(murderer.throwPose, throwProgress)
	end
end

function MurdererController:Initialize()
	ReplicateKnifeThrowEvent:On(HandleReplicateKnifeThrow)
	ReplicateKnifeHitEvent:On(HandleReplicateKnifeHit)
	ReplicateAnimationEvent:On(HandleAnimationEvent)

	RunService.Stepped:Connect(Stepped)

	Players.PlayerAdded:Connect(PlayerAdded)
	for _, player in Players:GetPlayers() do
		PlayerAdded(player)
	end
end

MurdererController:Initialize()

return MurdererController
