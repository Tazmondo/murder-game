local Config = {
	-- Maximum allowed latency variation - this is subtracted from server-sided cooldowns
	LatencyVariation = 0.1,

	-- MURDERER --
	ThrowCooldown = 1,

	-- Time before knives in the air disappear
	KnifeTimeout = 30,

	KnifeSpeed = 80,
	KnifeRotationSpeed = math.rad(360) * 5,
}

return Config
