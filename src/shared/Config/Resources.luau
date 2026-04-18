--!strict

-- Static shared configuration for Resources used by deterministic gameplay logic on both client and server.

local function makeResource(
	id: string,
	displayName: string,
	rarity: string,
	baseCoinRate: number,
	color: Color3,
	visualVariant: string?
)
	return {
		id = id,
		displayName = displayName,
		rarity = rarity,
		baseCoinRate = baseCoinRate,
		color = color,
		visualVariant = visualVariant,
	}
end

local Resources = {
	quartz = makeResource("quartz", "Quartz", "Common", 1, Color3.fromRGB(224, 233, 240), "gemstone"),
	rose_quartz = makeResource("rose_quartz", "Rose Quartz", "Common", 2, Color3.fromRGB(244, 182, 201), "gemstone"),
	smoky_quartz = makeResource("smoky_quartz", "Smoky Quartz", "Common", 3, Color3.fromRGB(114, 98, 94), "gemstone"),
	jade_fragment = makeResource("jade_fragment", "Jade Fragment", "Common", 4, Color3.fromRGB(92, 181, 134), "gemstone"),
	copper_nugget = makeResource("copper_nugget", "Copper Nugget", "Common", 5, Color3.fromRGB(186, 111, 74), "ingot"),

	amethyst = makeResource("amethyst", "Amethyst", "Uncommon", 4, Color3.fromRGB(179, 127, 255), "gemstone"),
	moonstone = makeResource("moonstone", "Moonstone", "Uncommon", 6, Color3.fromRGB(203, 226, 255), "gemstone"),
	garnet_node = makeResource("garnet_node", "Garnet Node", "Uncommon", 7, Color3.fromRGB(153, 48, 68), "cluster"),
	topaz_vein = makeResource("topaz_vein", "Topaz Vein", "Uncommon", 8, Color3.fromRGB(229, 174, 46), "cluster"),
	silver_ingot = makeResource("silver_ingot", "Silver Ingot", "Uncommon", 10, Color3.fromRGB(196, 205, 219), "ingot"),

	emerald_cluster = makeResource("emerald_cluster", "Emerald Cluster", "Rare", 12, Color3.fromRGB(72, 214, 158), "cluster"),
	ruby_cluster = makeResource("ruby_cluster", "Ruby Cluster", "Rare", 15, Color3.fromRGB(207, 52, 76), "cluster"),
	sapphire_spire = makeResource("sapphire_spire", "Sapphire Spire", "Rare", 17, Color3.fromRGB(63, 124, 226), "artifact"),
	peridot_bloom = makeResource("peridot_bloom", "Peridot Bloom", "Rare", 19, Color3.fromRGB(154, 220, 87), "cluster"),
	gold_ingot = makeResource("gold_ingot", "Gold Ingot", "Rare", 22, Color3.fromRGB(237, 190, 62), "ingot"),

	diamond_core = makeResource("diamond_core", "Diamond Core", "Epic", 40, Color3.fromRGB(150, 244, 255), "artifact"),
	black_opal = makeResource("black_opal", "Black Opal", "Epic", 44, Color3.fromRGB(79, 58, 125), "artifact"),
	aetherite_relic = makeResource("aetherite_relic", "Aetherite Relic", "Epic", 52, Color3.fromRGB(108, 245, 255), "eldritch"),
	mythril_ingot = makeResource("mythril_ingot", "Mythril Ingot", "Epic", 58, Color3.fromRGB(112, 212, 224), "ingot"),
	voidglass_core = makeResource("voidglass_core", "Voidglass Core", "Epic", 64, Color3.fromRGB(102, 82, 176), "eldritch"),

	star_shard = makeResource("star_shard", "Star Shard", "Legendary", 120, Color3.fromRGB(255, 221, 120), "artifact"),
	phoenix_amber = makeResource("phoenix_amber", "Phoenix Amber", "Legendary", 132, Color3.fromRGB(255, 130, 54), "artifact"),
	astral_reliquary = makeResource("astral_reliquary", "Astral Reliquary", "Legendary", 146, Color3.fromRGB(132, 226, 255), "eldritch"),
	worldseed = makeResource("worldseed", "Worldseed", "Legendary", 168, Color3.fromRGB(144, 255, 153), "eldritch"),
	celestium_ingot = makeResource("celestium_ingot", "Celestium Ingot", "Legendary", 184, Color3.fromRGB(255, 238, 162), "ingot"),
}

return Resources
