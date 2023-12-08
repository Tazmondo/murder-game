local RunService = game:GetService("RunService")
local KnifeThrow = {}

local KNIFESPEED = 40
local KNIFEROTATIONSPEED = math.rad(1080)
local MAXTRAVELTIME = 30
local knifeId = 0

type Knife = {
	model: Model,
	origin: CFrame,
	id: number,
}

local knives: { [number]: Knife } = {}

function KnifeThrow:Throw(origin: CFrame, knifeTemplate: Model)
	local newKnife = knifeTemplate:Clone()

	local handle = newKnife.PrimaryPart :: BasePart
	handle.Anchored = true

	newKnife:PivotTo(origin)
	newKnife.Parent = workspace

	knives[knifeId] = {
		model = newKnife,
		origin = origin,
		id = knifeId,
	}

	local currentId = knifeId
	task.delay(MAXTRAVELTIME, function()
		if knives[currentId] then
			knives[currentId].model:Destroy()
			knives[currentId] = nil
		end
	end)

	knifeId += 1
end

function PreSimulation(dt: number)
	for i, knife in knives do
		local currentCFrame = knife.model:GetPivot()
		local newPosition = currentCFrame.Position + knife.origin.LookVector * dt * KNIFESPEED
		local newRotation = currentCFrame.Rotation * CFrame.Angles(dt * -KNIFEROTATIONSPEED, 0, 0)
		local newCFrame = CFrame.new(newPosition) * newRotation

		knife.model:PivotTo(newCFrame)
	end
end

function KnifeThrow:Initialize()
	RunService.PreSimulation:Connect(PreSimulation)
end

KnifeThrow:Initialize()

return KnifeThrow
