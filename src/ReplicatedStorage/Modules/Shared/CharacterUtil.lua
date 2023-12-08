local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Future = require(ReplicatedStorage.Packages.Future)
local CharacterUtil = {}

export type Character = {
	model: Model,
	humanoid: Humanoid,
	HRP: BasePart,
	animator: Animator,
}

function CharacterUtil:GetCharacter(player: Player): Character?
	local character = player.Character
	local HRP
	local humanoid
	local animator: Animator?

	if character then
		humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
		if humanoid then
			HRP = humanoid.RootPart
			if RunService:IsServer() then
				animator = humanoid:FindFirstChild("Animator") :: Animator? or Instance.new("Animator", humanoid)
			else
				animator = humanoid:FindFirstChild("Animator") :: Animator?
			end
		end
	end

	if character and HRP and humanoid and animator then
		return {
			model = character,
			humanoid = humanoid,
			HRP = HRP,
			animator = animator,
		}
	else
		return nil
	end
end

function CharacterUtil:GetFutureCharacter(player: Player): Future.Future<Character?>
	return Future.new(function()
		local character = CharacterUtil:GetCharacter(player)
		while character == nil do
			task.wait()
			if player.Parent == nil then
				return nil :: Character?
			end
			character = CharacterUtil:GetCharacter(player)
		end

		return character
	end)
end

return CharacterUtil
