local MurdererService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterUtil = require(ReplicatedStorage.Modules.Shared.CharacterUtil)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local LoadedService = require(script.Parent.LoadedService)

local CreateMurdererEvent = require(ReplicatedStorage.Events.Murderer.CreateMurdererEvent):Server()
local ReplicateKnifeHitEvent = require(ReplicatedStorage.Events.Murderer.ReplicateKnifeHitEvent):Server()
local ReplicateKnifeThrowEvent = require(ReplicatedStorage.Events.Murderer.ReplicateKnifeThrowEvent):Server()
local ThrowKnifeEvent = require(ReplicatedStorage.Events.Murderer.ThrowKnifeEvent):Server()
local KnifeHitEvent = require(ReplicatedStorage.Events.Murderer.KnifeHitEvent):Server()

type Knife = {
	id: number,
	origin: CFrame,
}

type Murderer = {
	lastThrown: number,
	knives: { [number]: Knife },
	knifeId: number,
}

local murderers: { [Player]: Murderer? } = {}

function MurdererService:MakeMurderer(player: Player)
	print("Making", player, "a murderer")

	murderers[player] = {
		lastThrown = 0,
		knives = {},
		knifeId = 0,
	}

	CreateMurdererEvent:FireAll(player)
end

function HandleKnifeThrowEvent(player: Player, origin: CFrame)
	local murdererState = murderers[player]
	if not murdererState then
		return
	end
	local character = player.Character
	if not character then
		return
	end

	murdererState.knifeId += 1

	local cooldown = Config.ThrowCooldown - Config.LatencyVariation
	if tick() - murdererState.lastThrown < cooldown then
		warn(player, "Tried to throw knives too fast")
		return
	end

	if (origin.Position - character:GetPivot().Position).Magnitude > 20 then
		warn(player, "Tried to throw a knife from an invalid position")
		return
	end

	local newKnife: Knife = {
		id = murdererState.knifeId,
		origin = origin,
	}
	murdererState.knives[murdererState.knifeId] = newKnife

	ReplicateKnifeThrowEvent:FireAllExcept(player, player, origin, murdererState.knifeId)
end

function HandleKnifeHitEvent(
	player: Player,
	knifeId: number,
	targetPart: BasePart,
	localHitPosition: Vector3,
	localTargetCFrame: CFrame
)
	local murdererState = murderers[player]
	if not murdererState then
		return
	end

	local knife = murdererState.knives[knifeId]
	if not knife then
		warn("Tried to register hit for nonexistent knife")
		return
	end

	local actualLookVector = (localHitPosition - knife.origin.Position).Unit
	local dot = knife.origin.LookVector.Unit:Dot(actualLookVector)
	if dot < 0.95 then
		warn(player, "Likely exploiting, mismatched knife trajectories", dot)
		return
	end

	if (localTargetCFrame.Position - targetPart.Position).Magnitude > 10 then
		warn("Local position too far away", (localHitPosition - targetPart.Position).Magnitude)
		return
	end

	local offset = localTargetCFrame:PointToObjectSpace(localHitPosition)
	local realSize = targetPart.Size
	if math.abs(offset.X) > realSize.X or math.abs(offset.Y) > realSize.Y or math.abs(offset.Z) > realSize.Z then
		warn(player, "Invalid position offset - likely exploiting")
		return
	end

	local character = CharacterUtil:GetCharacterFromPart(targetPart)
	local hitPlayer = character ~= nil

	if character then
		character.humanoid:TakeDamage(math.huge)
	end

	ReplicateKnifeHitEvent:FireAllExcept(player, player, knifeId, hitPlayer)
	murdererState.knives[knifeId] = nil
end

function PlayerRemoving(player: Player)
	murderers[player] = nil
end

function PlayerAdded(player: Player)
	local function charAdded(char)
		LoadedService:ClientLoaded(player):Await()
		MurdererService:MakeMurderer(player)
	end

	for murderer, state in murderers do
		CreateMurdererEvent:Fire(player, murderer)
	end

	player.CharacterAdded:Connect(charAdded)
	if player.Character then
		charAdded(player.Character)
	end
end

function MurdererService:Initialize()
	Players.PlayerAdded:Connect(PlayerAdded)
	Players.PlayerRemoving:Connect(PlayerRemoving)
	ThrowKnifeEvent:On(HandleKnifeThrowEvent)
	KnifeHitEvent:On(HandleKnifeHitEvent)

	for i, player in Players:GetPlayers() do
		PlayerAdded(player)
	end
end

MurdererService:Initialize()

return MurdererService
