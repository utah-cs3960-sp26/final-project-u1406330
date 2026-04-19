--!strict

-- Static shared configuration for Pickaxes used by deterministic gameplay logic on both client and server.

local geodeOrder = {
	"starter_geode",
	"crystal_cavern_geode",
	"moonlit_geode",
	"ember_glass_geode",
	"verdant_rift_geode",
	"aurora_shard_geode",
	"thunder_core_geode",
	"fossil_vault_geode",
	"prism_sun_geode",
	"sovereign_nova_geode",
}

local GEODE_FIND_CHANCE_SCALE = 0.75

local function makeGeodeWeights(weights: { number })
	local entries = {}

	for index, geodeId in ipairs(geodeOrder) do
		table.insert(entries, {
			geodeId = geodeId,
			weight = weights[index] or 0,
		})
	end

	return entries
end

local function scaleGeodeChance(baseChance: number): number
	-- Keep one shared balance knob for "how often do geodes appear at all" so tier tables can stay intact.
	return math.max(0, math.floor(baseChance * GEODE_FIND_CHANCE_SCALE + 0.5))
end

local function makePickaxe(
	id: string,
	displayName: string,
	rarity: string,
	price: number,
	currency: string,
	cooldownSeconds: number,
	coinRewardMin: number,
	coinRewardMax: number,
	geodeChance: number,
	geodeWeights: { number },
	displayColor: Color3
)
	return {
		id = id,
		displayName = displayName,
		rarity = rarity,
		price = price,
		currency = currency,
		cooldownSeconds = cooldownSeconds,
		coinRewardMin = coinRewardMin,
		coinRewardMax = coinRewardMax,
		geodeChance = scaleGeodeChance(geodeChance),
		geodeWeights = makeGeodeWeights(geodeWeights),
		displayColor = displayColor,
	}
end

local Pickaxes = {
	order = {
		"stone_pickaxe",
		"copper_pickaxe",
		"iron_pickaxe",
		"steel_pickaxe",
		"gold_pickaxe",
		"platinum_pickaxe",
		"emerald_pickaxe",
		"obsidian_pickaxe",
		"lunar_pickaxe",
		"crown_pickaxe",
	},
	catalog = {
		stone_pickaxe = makePickaxe(
			"stone_pickaxe",
			"Stone Pickaxe",
			"Common",
			75,
			"coins",
			0.6,
			4,
			8,
			25,
			{ 50, 25, 15, 5, 3, 1, 1, 0, 0, 0 },
			Color3.fromRGB(126, 126, 129)
		),
		copper_pickaxe = makePickaxe(
			"copper_pickaxe",
			"Copper Pickaxe",
			"Uncommon",
			150,
			"coins",
			0.55,
			6,
			11,
			28,
			{ 40, 24, 16, 9, 5, 3, 2, 1, 0, 0 },
			Color3.fromRGB(184, 121, 74)
		),
		iron_pickaxe = makePickaxe(
			"iron_pickaxe",
			"Iron Pickaxe",
			"Rare",
			260,
			"coins",
			0.5,
			9,
			16,
			30,
			{ 30, 24, 16, 10, 7, 5, 4, 2, 1, 1 },
			Color3.fromRGB(155, 164, 176)
		),
		steel_pickaxe = makePickaxe(
			"steel_pickaxe",
			"Steel Pickaxe",
			"Epic",
			420,
			"coins",
			0.48,
			12,
			22,
			32,
			{ 22, 20, 16, 12, 9, 7, 5, 4, 3, 2 },
			Color3.fromRGB(108, 120, 136)
		),
		gold_pickaxe = makePickaxe(
			"gold_pickaxe",
			"Gold Pickaxe",
			"Legendary",
			650,
			"coins",
			0.45,
			16,
			30,
			34,
			{ 15, 16, 15, 13, 11, 10, 7, 5, 4, 4 },
			Color3.fromRGB(224, 183, 74)
		),
		platinum_pickaxe = makePickaxe(
			"platinum_pickaxe",
			"Platinum Pickaxe",
			"Mythic",
			950,
			"coins",
			0.42,
			22,
			40,
			36,
			{ 10, 12, 13, 14, 13, 12, 9, 7, 5, 5 },
			Color3.fromRGB(209, 221, 226)
		),
		emerald_pickaxe = makePickaxe(
			"emerald_pickaxe",
			"Emerald Pickaxe",
			"Ancient",
			1400,
			"coins",
			0.4,
			30,
			52,
			38,
			{ 7, 9, 10, 12, 13, 13, 12, 10, 7, 7 },
			Color3.fromRGB(90, 195, 130)
		),
		obsidian_pickaxe = makePickaxe(
			"obsidian_pickaxe",
			"Obsidian Pickaxe",
			"Prismatic",
			2000,
			"coins",
			0.38,
			40,
			68,
			40,
			{ 5, 6, 8, 10, 12, 14, 14, 11, 10, 10 },
			Color3.fromRGB(74, 74, 91)
		),
		lunar_pickaxe = makePickaxe(
			"lunar_pickaxe",
			"Lunar Pickaxe",
			"Sovereign",
			2900,
			"coins",
			0.35,
			52,
			88,
			42,
			{ 3, 4, 5, 7, 10, 12, 15, 15, 13, 16 },
			Color3.fromRGB(171, 182, 214)
		),
		crown_pickaxe = makePickaxe(
			"crown_pickaxe",
			"Crown Pickaxe",
			"Apex",
			4000,
			"coins",
			0.3,
			68,
			110,
			45,
			{ 2, 2, 3, 4, 7, 9, 13, 16, 18, 26 },
			Color3.fromRGB(245, 231, 167)
		),
	},
}

return Pickaxes
