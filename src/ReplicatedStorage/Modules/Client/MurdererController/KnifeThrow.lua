local KnifeThrow = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CharacterUtil = require(ReplicatedStorage.Modules.Shared.CharacterUtil)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Types = require(ReplicatedStorage.Modules.Shared.Types)

local KnifeHitEvent = require(ReplicatedStorage.Events.Murderer.KnifeHitEvent):Client()

local knifeId = 0

type Knife = {
	model: Types.KnifeModel,
	origin: CFrame,
	id: number,
	murdererLocalId: number,
	raycastParams: RaycastParams,
	localKnife: boolean,
}

local flyingKnives: { [number]: Knife } = {}
local staticKnives: { [number]: Knife } = {}

function KnifeThrow:Throw(
	origin: CFrame,
	knifeTemplate: Types.KnifeModel,
	character: CharacterUtil.Character,
	id: number
)
	knifeId += 1

	local newKnife = knifeTemplate:Clone()

	local handle = newKnife.PrimaryPart :: BasePart
	handle.Anchored = true

	newKnife:PivotTo(origin)
	newKnife.Parent = workspace

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { character.model }
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	flyingKnives[knifeId] = {
		model = newKnife,
		origin = origin,
		id = knifeId,
		raycastParams = raycastParams,
		localKnife = character.model == Players.LocalPlayer.Character,
		murdererLocalId = id,
	}

	local currentId = knifeId
	task.delay(Config.KnifeTimeout, function()
		if flyingKnives[currentId] then
			flyingKnives[currentId].model:Destroy()
			flyingKnives[currentId] = nil
		end
	end)

	return knifeId
end

function KnifeThrow:DeleteKnife(knifeId: number)
	local knife = flyingKnives[knifeId] or staticKnives[knifeId]
	if knife then
		flyingKnives[knifeId] = nil
		staticKnives[knifeId] = nil
		knife.model:Destroy()
	end
end

function KnifeThrow:ClearAllKnives()
	for i, knife in flyingKnives do
		knife.model:Destroy()
	end

	for i, knife in staticKnives do
		knife.model:Destroy()
	end

	flyingKnives = {}
	staticKnives = {}
end

function PreSimulation(dt: number)
	for i, knife in flyingKnives do
		local currentCFrame = knife.model:GetPivot()
		local newPosition = currentCFrame.Position + knife.origin.LookVector * dt * Config.KnifeSpeed
		local newRotation = currentCFrame.Rotation * CFrame.Angles(dt * -Config.KnifeRotationSpeed, 0, 0)
		local newCFrame = CFrame.new(newPosition) * newRotation

		local raycast =
			workspace:Raycast(currentCFrame.Position, newCFrame.Position - currentCFrame.Position, knife.raycastParams)

		if raycast then
			local instance = raycast.Instance :: BasePart
			local staticKnifeCFrame = CFrame.new(raycast.Position - knife.origin.LookVector * 0.1)
				* knife.origin.Rotation
				* CFrame.Angles(math.rad(-90), 0, 0)

			knife.model:PivotTo(staticKnifeCFrame)
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = knife.model.Handle
			weld.Part1 = instance
			weld.Parent = knife.model

			knife.model.Handle.Anchored = false

			flyingKnives[i] = nil
			staticKnives[i] = knife

			if knife.localKnife then
				KnifeHitEvent:Fire(knife.murdererLocalId, instance, raycast.Position, instance.CFrame)
			end
		else
			knife.model:PivotTo(newCFrame)
		end
	end
end

function KnifeThrow:Initialize()
	RunService.PreSimulation:Connect(PreSimulation)
end

KnifeThrow:Initialize()

return KnifeThrow
