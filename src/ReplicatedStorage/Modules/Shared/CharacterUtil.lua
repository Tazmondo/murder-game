local Players = game:GetService("Players")
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

function CharacterUtil:GetCharacterFromPlayer(player: Player): Character?
	local character = player.Character
	if character then
		return CharacterUtil:GetCharacterFromModel(character)
	end
	return nil
end

function CharacterUtil:GetCharacterFromModel(character: Model): Character?
	local HRP
	local humanoid
	local animator: Animator?

	humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
	if humanoid then
		HRP = humanoid.RootPart
		if RunService:IsServer() then
			animator = humanoid:FindFirstChild("Animator") :: Animator? or Instance.new("Animator", humanoid)
		else
			animator = humanoid:FindFirstChild("Animator") :: Animator?
		end
	end

	if HRP and humanoid and animator then
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
		local character = CharacterUtil:GetCharacterFromPlayer(player)
		while character == nil do
			task.wait()
			if player.Parent == nil then
				return nil :: Character?
			end
			character = CharacterUtil:GetCharacterFromPlayer(player)
		end

		return character
	end)
end

function CharacterUtil:GetCharacterFromPart(part: BasePart): Character?
	local parent = part.Parent
	while parent and not parent:IsA("Model") and parent.Parent ~= workspace do
		parent = parent.Parent
	end

	if parent and parent:IsA("Model") then
		return CharacterUtil:GetCharacterFromModel(parent)
	end

	return nil
end

return CharacterUtil
