local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InstanceGuards = require(ReplicatedStorage.Modules.Shared.InstanceGuards)
local Guard = require(ReplicatedStorage.Packages.Guard)
local Red = require(ReplicatedStorage.Packages.Red)

return Red.Event("Murderer_KnifeHit", function(knifeId, targetPart, localHitPosition, localTargetCFrame)
	return Guard.Number(knifeId),
		InstanceGuards.BasePart(targetPart),
		Guard.Vector3(localHitPosition),
		Guard.CFrame(localTargetCFrame)
end)
