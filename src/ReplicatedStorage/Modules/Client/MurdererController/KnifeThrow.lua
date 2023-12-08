local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CharacterUtil = require(ReplicatedStorage.Modules.Shared.CharacterUtil)
local KnifeThrow = {}

local KNIFESPEED = 80
local KNIFEROTATIONSPEED = math.rad(360) * 5
local MAXTRAVELTIME = 30
local knifeId = 0

type Knife = {
	model: Model,
	origin: CFrame,
	id: number,
	raycastParams: RaycastParams,
}

local flyingKnives: { [number]: Knife } = {}

function KnifeThrow:Throw(origin: CFrame, knifeTemplate: Model, character: CharacterUtil.Character)
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
	}

	local currentId = knifeId
	task.delay(MAXTRAVELTIME, function()
		if flyingKnives[currentId] then
			flyingKnives[currentId].model:Destroy()
			flyingKnives[currentId] = nil
		end
	end)

	return knifeId
end

function PreSimulation(dt: number)
	for i, knife in flyingKnives do
		local currentCFrame = knife.model:GetPivot()
		local newPosition = currentCFrame.Position + knife.origin.LookVector * dt * KNIFESPEED
		local newRotation = currentCFrame.Rotation * CFrame.Angles(dt * -KNIFEROTATIONSPEED, 0, 0)
		local newCFrame = CFrame.new(newPosition) * newRotation

		local raycast =
			workspace:Raycast(currentCFrame.Position, newCFrame.Position - currentCFrame.Position, knife.raycastParams)

		if raycast then
			local staticKnifeCFrame = CFrame.new(raycast.Position - knife.origin.LookVector * 0.1)
				* knife.origin.Rotation
				* CFrame.Angles(math.rad(-90), 0, 0)

			knife.model:PivotTo(staticKnifeCFrame)
			flyingKnives[i] = nil
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
