local ClientMurderer = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local KnifeThrow = require(script.Parent.KnifeThrow)
local CharacterUtil = require(ReplicatedStorage.Modules.Shared.CharacterUtil)

local animationFolder = ReplicatedStorage.Assets.Animations
local knifeThrowAnimation = assert(animationFolder.KnifeThrow, "No knife throw animation")
local knifeHoldAnimation = assert(animationFolder.KnifeHold, "No knife hold found")

local THROWTIME = 0.5
local THROWALPHA = 0.8 -- Progress through throw time that releasing will result in a throw
local THROWCOOLDOWN = 2

type MurdererData = {
	animations: {
		throw: AnimationTrack,
	},
	lastClicked: number,
	lastThrown: number,
	holding: boolean,
	knife: Model,
	character: CharacterUtil.Character,
}

local activeMurderer: MurdererData? = nil

function ClientMurderer:ClearMurderer()
	activeMurderer = nil
end

function ClientMurderer:InitializeMurderer(character: CharacterUtil.Character, knife: Model)
	local throw = character.animator:LoadAnimation(knifeThrowAnimation)
	local hold = character.animator:LoadAnimation(knifeHoldAnimation)
	hold:Play()
	throw:Play()
	throw:AdjustWeight(0.001)

	activeMurderer = {
		animations = {
			throw = throw,
		},
		lastClicked = 0,
		lastThrown = 0,
		holding = false,
		knife = knife,
		character = character,
	}

	Players.LocalPlayer.CharacterRemoving:Once(ClientMurderer.ClearMurderer)
	character.humanoid.Died:Once(ClientMurderer.ClearMurderer)
end

-- For getting length of time held down including down time during the throw cooldown
function GetCooldownHoldTime(activeMurderer: MurdererData)
	local cooldownEnd = activeMurderer.lastThrown + THROWCOOLDOWN
	local cooldownHeld = math.max(0, cooldownEnd - activeMurderer.lastClicked)
	local heldTime = os.clock() - activeMurderer.lastClicked - cooldownHeld

	return heldTime
end

function InputBegan(input: InputObject, processed: boolean)
	if processed or not activeMurderer then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		activeMurderer.holding = true
		activeMurderer.lastClicked = os.clock()
		activeMurderer.animations.throw:Play()
	end
end

function InputEnded(input: InputObject, processed: boolean)
	if processed or not activeMurderer then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		activeMurderer.holding = false

		-- User held down button for long enough to throw the knife
		if GetCooldownHoldTime(activeMurderer) >= (THROWTIME * THROWALPHA) then
			activeMurderer.lastThrown = os.clock()
			local ray = workspace.CurrentCamera:ScreenPointToRay(input.Position.X, input.Position.Y)

			local maxRayDirection = ray.Direction * 1000

			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			raycastParams.FilterDescendantsInstances = { activeMurderer.character.model }

			local raycast = workspace:Raycast(ray.Origin, maxRayDirection, raycastParams)
			local endPosition = if raycast then raycast.Position else ray.Origin + ray.Direction * 50

			local origin = CFrame.lookAt(activeMurderer.character.HRP.Position, endPosition)

			KnifeThrow:Throw(origin, activeMurderer.knife, activeMurderer.character)

			-- So that the animation snaps back
			activeMurderer.animations.throw:AdjustWeight(0.001, 0.05)
		else
			activeMurderer.animations.throw:AdjustWeight(0.001, 0.1)
		end
	end
end

function PreAnimation(dt: number)
	if not activeMurderer then
		return
	end

	if activeMurderer.holding then
		local throwProgress = math.clamp(GetCooldownHoldTime(activeMurderer) / THROWTIME, 0, 1)
		activeMurderer.animations.throw:AdjustWeight(throwProgress, 0.1)
	end
end

function ClientMurderer:Initialize()
	UserInputService.InputBegan:Connect(InputBegan)
	UserInputService.InputEnded:Connect(InputEnded)

	RunService.PreAnimation:Connect(PreAnimation)
end

ClientMurderer:Initialize()

return ClientMurderer
