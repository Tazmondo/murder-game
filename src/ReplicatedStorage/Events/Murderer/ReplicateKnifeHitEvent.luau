local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InstanceGuards = require(ReplicatedStorage.Modules.Shared.InstanceGuards)
local Guard = require(ReplicatedStorage.Packages.Guard)
local Red = require(ReplicatedStorage.Packages.Red)
return Red.Event("Murderer_ReplicateKnifeHit", function(murderer, knifeId, didHitPlayer)
	return InstanceGuards.Player(murderer), Guard.Number(knifeId), Guard.Boolean(didHitPlayer)
end)
