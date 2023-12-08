local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Future = require(ReplicatedStorage.Packages.Future)
local CharacterUtil = {}

type Character = {
	model: Model,
	humanoid: Humanoid,
	HRP: BasePart,
}

function CharacterUtil:GetCharacter(player: Player): Character?
	local character = player.Character
	local HRP
	local humanoid
	if character then
		humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
		if humanoid then
			HRP = humanoid.RootPart
		end
	end

	if character and HRP and humanoid then
		return {
			model = character,
			humanoid = humanoid,
			HRP = HRP,
		}
	else
		return nil
	end
end

function CharacterUtil:GetFutureCharacter(player: Player): Future.Future<Character?>
	return Future.new(function()
		local character = nil
		while character == nil do
			if player.Parent == nil then
				return nil :: Character?
			end
			character = CharacterUtil:GetCharacter(player)
		end

		return character
	end)
end

return CharacterUtil
