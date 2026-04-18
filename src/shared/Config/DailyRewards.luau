--!strict

-- Static shared configuration for Daily Rewards used by deterministic gameplay logic on both client and server.

local DailyRewards = {
	streakResetHours = 48,
	days = {
		{ day = 1, rewardType = "coins", amount = 100 },
		{ day = 2, rewardType = "geode", amount = 1, rewardId = "starter_geode" },
		{ day = 3, rewardType = "boost", amount = 1, rewardId = "geode_speed_boost" },
		{ day = 4, rewardType = "geode", amount = 1, rewardId = "crystal_cavern_geode" },
		{ day = 5, rewardType = "token", amount = 1, rewardId = "trait_token" },
		{ day = 6, rewardType = "gems", amount = 25 },
		{ day = 7, rewardType = "resource", amount = 1, rewardId = "diamond_core" },
	},
}

return DailyRewards
