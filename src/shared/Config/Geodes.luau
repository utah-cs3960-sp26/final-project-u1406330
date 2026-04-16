--!strict

local function makeRoll(resourceId: string, weight: number)
	return {
		resourceId = resourceId,
		weight = weight,
	}
end

local function makeGeode(
	id: string,
	displayName: string,
	geodeSeconds: number,
	displayColor: Color3,
	rolls: { { resourceId: string, weight: number } }
)
	return {
		id = id,
		displayName = displayName,
		geodeSeconds = geodeSeconds,
		gridSize = {
			width = 2,
			height = 2,
		},
		displayColor = displayColor,
		rolls = rolls,
	}
end

local Geodes = {
	starter_geode = makeGeode(
		"starter_geode",
		"Starter Geode",
		10,
		Color3.fromRGB(124, 129, 150),
		{
			makeRoll("quartz", 70),
			makeRoll("amethyst", 25),
			makeRoll("emerald_cluster", 5),
		}
	),
	crystal_cavern_geode = makeGeode(
		"crystal_cavern_geode",
		"Crystal Cavern Geode",
		18,
		Color3.fromRGB(92, 112, 150),
		{
			makeRoll("quartz", 45),
			makeRoll("amethyst", 30),
			makeRoll("emerald_cluster", 20),
			makeRoll("diamond_core", 5),
		}
	),
	moonlit_geode = makeGeode(
		"moonlit_geode",
		"Moonlit Geode",
		24,
		Color3.fromRGB(168, 176, 204),
		{
			makeRoll("quartz", 28),
			makeRoll("amethyst", 34),
			makeRoll("emerald_cluster", 26),
			makeRoll("diamond_core", 10),
			makeRoll("star_shard", 2),
		}
	),
	ember_glass_geode = makeGeode(
		"ember_glass_geode",
		"Ember Glass Geode",
		30,
		Color3.fromRGB(214, 116, 72),
		{
			makeRoll("quartz", 20),
			makeRoll("amethyst", 25),
			makeRoll("emerald_cluster", 30),
			makeRoll("diamond_core", 18),
			makeRoll("star_shard", 7),
		}
	),
	verdant_rift_geode = makeGeode(
		"verdant_rift_geode",
		"Verdant Rift Geode",
		36,
		Color3.fromRGB(88, 170, 112),
		{
			makeRoll("quartz", 18),
			makeRoll("amethyst", 22),
			makeRoll("emerald_cluster", 34),
			makeRoll("diamond_core", 16),
			makeRoll("star_shard", 10),
		}
	),
	aurora_shard_geode = makeGeode(
		"aurora_shard_geode",
		"Aurora Shard Geode",
		42,
		Color3.fromRGB(90, 199, 214),
		{
			makeRoll("quartz", 12),
			makeRoll("amethyst", 18),
			makeRoll("emerald_cluster", 28),
			makeRoll("diamond_core", 24),
			makeRoll("star_shard", 18),
		}
	),
	thunder_core_geode = makeGeode(
		"thunder_core_geode",
		"Thunder Core Geode",
		50,
		Color3.fromRGB(80, 96, 128),
		{
			makeRoll("quartz", 10),
			makeRoll("amethyst", 15),
			makeRoll("emerald_cluster", 25),
			makeRoll("diamond_core", 25),
			makeRoll("star_shard", 25),
		}
	),
	fossil_vault_geode = makeGeode(
		"fossil_vault_geode",
		"Fossil Vault Geode",
		60,
		Color3.fromRGB(168, 149, 120),
		{
			makeRoll("quartz", 40),
			makeRoll("amethyst", 25),
			makeRoll("emerald_cluster", 18),
			makeRoll("diamond_core", 10),
			makeRoll("star_shard", 7),
		}
	),
	prism_sun_geode = makeGeode(
		"prism_sun_geode",
		"Prism Sun Geode",
		72,
		Color3.fromRGB(244, 204, 96),
		{
			makeRoll("quartz", 8),
			makeRoll("amethyst", 14),
			makeRoll("emerald_cluster", 22),
			makeRoll("diamond_core", 26),
			makeRoll("star_shard", 30),
		}
	),
	sovereign_nova_geode = makeGeode(
		"sovereign_nova_geode",
		"Sovereign Nova Geode",
		90,
		Color3.fromRGB(235, 230, 214),
		{
			makeRoll("quartz", 5),
			makeRoll("amethyst", 10),
			makeRoll("emerald_cluster", 15),
			makeRoll("diamond_core", 25),
			makeRoll("star_shard", 45),
		}
	),
}

return Geodes
