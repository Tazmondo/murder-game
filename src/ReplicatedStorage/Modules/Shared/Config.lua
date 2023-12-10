local Config = {
	-- Maximum allowed latency variation - this is subtracted from server-sided cooldowns
	LatencyVariation = 0.1,

	-- MURDERER --
	MurdererAttribute = "Murderer_IsMurderer",
	ThrowCooldown = 1,
	ThrowTime = 0.5, -- Time taken to fully wind up knife
	ThrowAlpha = 0.95, -- Progress through throw time that releasing will result in a throw

	-- Time before knives in the air disappear
	KnifeTimeout = 30,

	KnifeSpeed = 80,
	KnifeRotationSpeed = math.rad(360) * 5,
}

return Config
