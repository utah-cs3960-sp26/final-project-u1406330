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
			makeRoll("quartz", 30),
			makeRoll("rose_quartz", 24),
			makeRoll("smoky_quartz", 18),
			makeRoll("jade_fragment", 16),
			makeRoll("copper_nugget", 8),
			makeRoll("amethyst", 4),
		}
	),
	crystal_cavern_geode = makeGeode(
		"crystal_cavern_geode",
		"Crystal Cavern Geode",
		18,
		Color3.fromRGB(92, 112, 150),
		{
			makeRoll("quartz", 16),
			makeRoll("rose_quartz", 14),
			makeRoll("smoky_quartz", 10),
			makeRoll("jade_fragment", 12),
			makeRoll("copper_nugget", 8),
			makeRoll("amethyst", 18),
			makeRoll("moonstone", 10),
			makeRoll("garnet_node", 8),
			makeRoll("topaz_vein", 4),
		}
	),
	moonlit_geode = makeGeode(
		"moonlit_geode",
		"Moonlit Geode",
		24,
		Color3.fromRGB(168, 176, 204),
		{
			makeRoll("quartz", 8),
			makeRoll("rose_quartz", 8),
			makeRoll("smoky_quartz", 8),
			makeRoll("amethyst", 18),
			makeRoll("moonstone", 16),
			makeRoll("garnet_node", 12),
			makeRoll("topaz_vein", 10),
			makeRoll("silver_ingot", 6),
			makeRoll("emerald_cluster", 8),
			makeRoll("ruby_cluster", 6),
		}
	),
	ember_glass_geode = makeGeode(
		"ember_glass_geode",
		"Ember Glass Geode",
		30,
		Color3.fromRGB(214, 116, 72),
		{
			makeRoll("smoky_quartz", 8),
			makeRoll("copper_nugget", 8),
			makeRoll("amethyst", 12),
			makeRoll("moonstone", 2),
			makeRoll("garnet_node", 12),
			makeRoll("topaz_vein", 12),
			makeRoll("silver_ingot", 8),
			makeRoll("emerald_cluster", 12),
			makeRoll("ruby_cluster", 10),
			makeRoll("sapphire_spire", 8),
			makeRoll("gold_ingot", 8),
		}
	),
	verdant_rift_geode = makeGeode(
		"verdant_rift_geode",
		"Verdant Rift Geode",
		36,
		Color3.fromRGB(88, 170, 112),
		{
			makeRoll("jade_fragment", 10),
			makeRoll("amethyst", 8),
			makeRoll("moonstone", 8),
			makeRoll("topaz_vein", 8),
			makeRoll("emerald_cluster", 22),
			makeRoll("peridot_bloom", 20),
			makeRoll("ruby_cluster", 8),
			makeRoll("gold_ingot", 8),
			makeRoll("sapphire_spire", 8),
		}
	),
	aurora_shard_geode = makeGeode(
		"aurora_shard_geode",
		"Aurora Shard Geode",
		42,
		Color3.fromRGB(90, 199, 214),
		{
			makeRoll("moonstone", 10),
			makeRoll("silver_ingot", 6),
			makeRoll("emerald_cluster", 14),
			makeRoll("ruby_cluster", 10),
			makeRoll("sapphire_spire", 14),
			makeRoll("peridot_bloom", 12),
			makeRoll("gold_ingot", 8),
			makeRoll("diamond_core", 10),
			makeRoll("black_opal", 8),
			makeRoll("aetherite_relic", 4),
			makeRoll("mythril_ingot", 4),
		}
	),
	thunder_core_geode = makeGeode(
		"thunder_core_geode",
		"Thunder Core Geode",
		50,
		Color3.fromRGB(80, 96, 128),
		{
			makeRoll("garnet_node", 8),
			makeRoll("topaz_vein", 8),
			makeRoll("silver_ingot", 8),
			makeRoll("sapphire_spire", 10),
			makeRoll("gold_ingot", 10),
			makeRoll("diamond_core", 16),
			makeRoll("black_opal", 10),
			makeRoll("aetherite_relic", 8),
			makeRoll("mythril_ingot", 10),
			makeRoll("voidglass_core", 8),
			makeRoll("phoenix_amber", 4),
		}
	),
	fossil_vault_geode = makeGeode(
		"fossil_vault_geode",
		"Fossil Vault Geode",
		60,
		Color3.fromRGB(168, 149, 120),
		{
			makeRoll("smoky_quartz", 12),
			makeRoll("copper_nugget", 12),
			makeRoll("moonstone", 8),
			makeRoll("silver_ingot", 8),
			makeRoll("emerald_cluster", 10),
			makeRoll("gold_ingot", 10),
			makeRoll("diamond_core", 12),
			makeRoll("black_opal", 10),
			makeRoll("mythril_ingot", 8),
			makeRoll("phoenix_amber", 5),
			makeRoll("star_shard", 5),
		}
	),
	prism_sun_geode = makeGeode(
		"prism_sun_geode",
		"Prism Sun Geode",
		72,
		Color3.fromRGB(244, 204, 96),
		{
			makeRoll("sapphire_spire", 8),
			makeRoll("peridot_bloom", 8),
			makeRoll("gold_ingot", 8),
			makeRoll("diamond_core", 14),
			makeRoll("black_opal", 10),
			makeRoll("aetherite_relic", 10),
			makeRoll("mythril_ingot", 8),
			makeRoll("voidglass_core", 8),
			makeRoll("phoenix_amber", 8),
			makeRoll("star_shard", 10),
			makeRoll("astral_reliquary", 4),
			makeRoll("worldseed", 4),
		}
	),
	sovereign_nova_geode = makeGeode(
		"sovereign_nova_geode",
		"Sovereign Nova Geode",
		90,
		Color3.fromRGB(235, 230, 214),
		{
			makeRoll("sapphire_spire", 6),
			makeRoll("gold_ingot", 6),
			makeRoll("diamond_core", 14),
			makeRoll("black_opal", 12),
			makeRoll("aetherite_relic", 12),
			makeRoll("mythril_ingot", 10),
			makeRoll("voidglass_core", 10),
			makeRoll("star_shard", 12),
			makeRoll("phoenix_amber", 8),
			makeRoll("astral_reliquary", 5),
			makeRoll("worldseed", 3),
			makeRoll("celestium_ingot", 2),
		}
	),
}

return Geodes
