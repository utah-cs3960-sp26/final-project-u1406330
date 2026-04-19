--!strict

-- Static shared configuration for Sizes used by deterministic gameplay logic on both client and server.

local Sizes = {
	-- Resource visuals intentionally render larger than the raw rolled size values so the default
	-- placed models read clearly on plots without changing size bucket odds, labels, or sell math.
	resourceVisualScaleMultiplier = 3,
	tiny = {
		id = "tiny",
		displayName = "Tiny",
		rarity = "Common",
		weight = 3000,
		minScale = 0.65,
		maxScale = 0.79,
		scaleFactor = 0.72,
		sellMultiplier = 0.7,
	},
	small = {
		id = "small",
		displayName = "Small",
		rarity = "Common",
		weight = 4000,
		minScale = 0.80,
		maxScale = 0.94,
		scaleFactor = 0.88,
		sellMultiplier = 0.85,
	},
	medium = {
		id = "medium",
		displayName = "Medium",
		rarity = "Uncommon",
		weight = 2000,
		minScale = 0.95,
		maxScale = 1.09,
		scaleFactor = 1.0,
		sellMultiplier = 1.0,
	},
	large = {
		id = "large",
		displayName = "Large",
		rarity = "Rare",
		weight = 700,
		minScale = 1.10,
		maxScale = 1.34,
		scaleFactor = 1.22,
		sellMultiplier = 1.3,
	},
	huge = {
		id = "huge",
		displayName = "Huge",
		rarity = "Epic",
		weight = 250,
		minScale = 1.35,
		maxScale = 1.69,
		scaleFactor = 1.52,
		sellMultiplier = 1.7,
	},
	colossal = {
		id = "colossal",
		displayName = "Colossal",
		rarity = "Legendary",
		weight = 50,
		minScale = 1.70,
		maxScale = 2.0,
		scaleFactor = 1.85,
		sellMultiplier = 2.5,
	},
}

Sizes.order = {
	Sizes.tiny,
	Sizes.small,
	Sizes.medium,
	Sizes.large,
	Sizes.huge,
	Sizes.colossal,
}

return Sizes
