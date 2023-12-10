local InstanceGuards = {}

function InstanceGuards.BasePart(basePart: unknown): BasePart
	assert(typeof(basePart) == "Instance")
	assert(basePart:IsA("BasePart"))
	return basePart
end

function InstanceGuards.Player(player: unknown): Player
	assert(typeof(player) == "Instance")
	assert(player:IsA("Player"))
	return player
end

return InstanceGuards
