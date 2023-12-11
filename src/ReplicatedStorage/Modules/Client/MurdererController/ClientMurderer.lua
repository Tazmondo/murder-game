local ClientMurderer = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local KnifeThrow = require(script.Parent.KnifeThrow)
local CharacterUtil = require(ReplicatedStorage.Modules.Shared.CharacterUtil)
local Config = require(ReplicatedStorage.Modules.Shared.Config)
local Types = require(ReplicatedStorage.Modules.Shared.Types)

local ThrowKnifeEvent = require(ReplicatedStorage.Events.Murderer.ThrowKnifeEvent):Client()
local UpdateAnimationEvent = require(ReplicatedStorage.Events.Murderer.UpdateAnimationEvent):Client()

local activeMurderer: Types.ClientMurderer? = nil

function ClientMurderer:ClearMurderer()
	activeMurderer = nil
end

function ClientMurderer:InitializeMurderer(
	character: CharacterUtil.Character,
	knife: Model,
	baseData: Types.LocalMurderer
)
	local newMurderer: Types.ClientMurderer = {
		knife = baseData.knife,
		character = baseData.character,
		knifeMap = baseData.knifeMap,
		throwTrack = baseData.throwTrack,
		lastHeld = baseData.lastHeld,
		holding = baseData.holding,
		lastThrown = 0,
		knifeId = 0,
	}

	activeMurderer = newMurderer

	Players.LocalPlayer.CharacterRemoving:Once(ClientMurderer.ClearMurderer)
	character.humanoid.Died:Once(ClientMurderer.ClearMurderer)
end

-- For getting length of time held down including down time during the throw cooldown
function GetCooldownHoldTime(activeMurderer: Types.ClientMurderer)
	local cooldownEnd = activeMurderer.lastThrown + Config.ThrowCooldown
	local cooldownHeld = math.max(0, cooldownEnd - activeMurderer.lastHeld)
	local heldTime = os.clock() - activeMurderer.lastHeld - cooldownHeld

	return heldTime
end

function InputBegan(input: InputObject, processed: boolean)
	if processed or not activeMurderer then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		UpdateAnimationEvent:Fire(true)
		activeMurderer.holding = true
		activeMurderer.lastHeld = os.clock()
	end
end

function InputEnded(input: InputObject, processed: boolean)
	if processed or not activeMurderer then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		activeMurderer.holding = false
		UpdateAnimationEvent:Fire(false)

		-- User held down button for long enough to throw the knife
		if GetCooldownHoldTime(activeMurderer) >= (Config.ThrowTime * Config.ThrowAlpha) then
			activeMurderer.lastThrown = os.clock()
			local ray = workspace.CurrentCamera:ScreenPointToRay(input.Position.X, input.Position.Y)

			local maxRayDirection = ray.Direction * 1000

			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			raycastParams.FilterDescendantsInstances = { activeMurderer.character.model }

			local raycast = workspace:Raycast(ray.Origin, maxRayDirection, raycastParams)
			local endPosition = if raycast then raycast.Position else ray.Origin + ray.Direction * 50

			local origin = CFrame.lookAt(activeMurderer.character.HRP.Position, endPosition)

			activeMurderer.knifeId += 1

			local globalKnifeId =
				KnifeThrow:Throw(origin, activeMurderer.knife, activeMurderer.character, activeMurderer.knifeId)
			activeMurderer.knifeMap[activeMurderer.knifeId] = globalKnifeId

			ThrowKnifeEvent:Fire(origin)

			-- So that the animation snaps back
			activeMurderer.throwTrack:AdjustWeight(0.01, 0.05)
		else
			activeMurderer.throwTrack:AdjustWeight(0.01, 0.1)
		end
	end
end

function PreAnimation(dt: number)
	if not activeMurderer then
		return
	end

	if activeMurderer.holding then
		local throwProgress = math.clamp(GetCooldownHoldTime(activeMurderer) / Config.ThrowTime, 0, 1)
		local animationProgress = math.clamp(throwProgress, 0.01, 1) -- Can't set weight to 0 or anim will break
		activeMurderer.throwTrack:AdjustWeight(animationProgress, 0.1)
	end
end

function ClientMurderer:Initialize()
	UserInputService.InputBegan:Connect(InputBegan)
	UserInputService.InputEnded:Connect(InputEnded)

	RunService.PreAnimation:Connect(PreAnimation)
end

ClientMurderer:Initialize()

return ClientMurderer
