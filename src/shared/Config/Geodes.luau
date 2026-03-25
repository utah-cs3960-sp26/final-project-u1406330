--!strict

local Geodes = {
	starter_geode = {
		id = "starter_geode",
		displayName = "Starter Geode",
		geodeSeconds = 10,
		gridSize = {
			width = 2,
			height = 2,
		},
		displayColor = Color3.fromRGB(124, 129, 150),
		rolls = {
			{ resourceId = "quartz", weight = 70 },
			{ resourceId = "amethyst", weight = 25 },
			{ resourceId = "emerald_cluster", weight = 5 },
		},
	},
	crystal_cavern_geode = {
		id = "crystal_cavern_geode",
		displayName = "Crystal Cavern Geode",
		geodeSeconds = 20,
		gridSize = {
			width = 2,
			height = 2,
		},
		displayColor = Color3.fromRGB(92, 112, 150),
		rolls = {
			{ resourceId = "quartz", weight = 45 },
			{ resourceId = "amethyst", weight = 32 },
			{ resourceId = "emerald_cluster", weight = 17 },
			{ resourceId = "diamond_core", weight = 6 },
		},
	},
	moonlit_geode = {
		id = "moonlit_geode",
		displayName = "Moonlit Geode",
		geodeSeconds = 30,
		gridSize = {
			width = 2,
			height = 2,
		},
		displayColor = Color3.fromRGB(128, 116, 162),
		rolls = {
			{ resourceId = "amethyst", weight = 35 },
			{ resourceId = "emerald_cluster", weight = 40 },
			{ resourceId = "diamond_core", weight = 22 },
			{ resourceId = "star_shard", weight = 3 },
		},
	},
}

return Geodes
