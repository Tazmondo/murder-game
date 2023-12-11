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

local animationFolder = ReplicatedStorage.Assets.Animations
local knifeThrowAnimation = assert(animationFolder.KnifeThrow, "No knife throw animation")
local knifeHoldAnimation = assert(animationFolder.KnifeHold, "No knife hold found")

local THROWTIME = 0.5
local THROWALPHA = 0.8 -- Progress through throw time that releasing will result in a throw

local activeMurderer: Types.ClientMurderer? = nil

function ClientMurderer:ClearMurderer()
	activeMurderer = nil
end

function ClientMurderer:InitializeMurderer(
	character: CharacterUtil.Character,
	knife: Model,
	baseData: Types.LocalMurderer
)
	local throw = character.animator:LoadAnimation(knifeThrowAnimation)
	local hold = character.animator:LoadAnimation(knifeHoldAnimation)

	hold:Play()
	throw:Play()
	throw:AdjustWeight(0.01)
	throw:AdjustSpeed(0)

	activeMurderer = {
		animations = {
			throw = throw,
		},
		lastThrown = baseData.lastThrown,
		knife = baseData.knife,
		character = baseData.character,
		knifeMap = baseData.knifeMap,
		lastClicked = 0,
		holding = false,
		knifeId = 0,
	}

	Players.LocalPlayer.CharacterRemoving:Once(ClientMurderer.ClearMurderer)
	character.humanoid.Died:Once(ClientMurderer.ClearMurderer)
end

-- For getting length of time held down including down time during the throw cooldown
function GetCooldownHoldTime(activeMurderer: Types.ClientMurderer)
	local cooldownEnd = activeMurderer.lastThrown + Config.ThrowCooldown
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

			activeMurderer.knifeId += 1

			local globalKnifeId =
				KnifeThrow:Throw(origin, activeMurderer.knife, activeMurderer.character, activeMurderer.knifeId)
			activeMurderer.knifeMap[activeMurderer.knifeId] = globalKnifeId

			ThrowKnifeEvent:Fire(origin)

			-- So that the animation snaps back
			activeMurderer.animations.throw:AdjustWeight(0.01, 0.05)
		else
			activeMurderer.animations.throw:AdjustWeight(0.01, 0.1)
		end
	end
end

function PreAnimation(dt: number)
	if not activeMurderer then
		return
	end

	if activeMurderer.holding then
		local throwProgress = math.clamp(GetCooldownHoldTime(activeMurderer) / THROWTIME, 0, 1)
		local animationProgress = math.clamp(throwProgress, 0.01, 1) -- Can't set weight to 0 or anim will break
		activeMurderer.animations.throw:AdjustWeight(animationProgress)
	end
end

function ClientMurderer:Initialize()
	UserInputService.InputBegan:Connect(InputBegan)
	UserInputService.InputEnded:Connect(InputEnded)

	RunService.PreAnimation:Connect(PreAnimation)
end

ClientMurderer:Initialize()

return ClientMurderer
