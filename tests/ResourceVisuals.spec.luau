--!strict

-- Spec coverage for Resource Visuals to keep deterministic gameplay behavior and regressions easy to verify.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local ResourceVisuals = require(Shared.Domain.ResourceVisuals)
local Resources = require(Shared.Config.Resources)

local RESOURCE_VISUAL_BASE_SCALE = 3

local function roundNumber(value: number): number
	return math.floor((value * 1000) + 0.5) / 1000
end

local function buildLayoutSignature(definitions: { [number]: any }): string
	local chunks = table.create(#definitions)

	for index, definition in ipairs(definitions) do
		chunks[index] = table.concat({
			tostring(definition.kind or "crystal"),
			tostring(definition.orbit == true),
			tostring(roundNumber(definition.x or 0)),
			tostring(roundNumber(definition.z or 0)),
			tostring(roundNumber(definition.height or 0)),
			tostring(roundNumber(definition.width or 0)),
			tostring(roundNumber(definition.depth or 0)),
			tostring(roundNumber(definition.yaw or 0)),
			tostring(roundNumber(definition.pitch or 0)),
			tostring(roundNumber(definition.roll or 0)),
			tostring(roundNumber(definition.tint or 0)),
		}, "|")
	end

	return table.concat(chunks, "||")
end

return function()
	assert(ResourceVisuals.getRarityRank("Common") == 1, "common visuals should use the base rarity rank")
	assert(ResourceVisuals.getRarityRank("Legendary") == 5, "legendary visuals should map to the top rarity rank")

	assert(ResourceVisuals.getResourceVariantShape("quartz", Resources.quartz) == "gemstone", "quartz should keep the gemstone silhouette")
	assert(ResourceVisuals.getResourceVariantShape("emerald_cluster", Resources.emerald_cluster) == "cluster", "emerald cluster should use the cluster silhouette")
	assert(ResourceVisuals.getResourceVariantShape("diamond_core", Resources.diamond_core) == "artifact", "diamond core should use the artifact silhouette")
	assert(ResourceVisuals.getResourceVariantShape("gold_ingot", Resources.gold_ingot) == "ingot", "gold ingot should use the grounded ingot silhouette")
	assert(ResourceVisuals.getResourceVariantShape("worldseed", Resources.worldseed) == "eldritch", "worldseed should use the otherworldly eldritch silhouette")
	assert(ResourceVisuals.getResourceVariantShape("moonstone", Resources.moonstone) == "moonstone", "moonstone should use its dedicated moon silhouette")

	local clusterProfile = ResourceVisuals.resolveRevealProfile("emerald_cluster", "verdant", "huge", 1.52)
	assert(clusterProfile.variantId == "cluster", "resolved profiles should preserve the expected silhouette")
	assert(clusterProfile.scale > 1.52, "rarity scale should stack on top of the rolled size")
	assert(clusterProfile.traitAccentColor ~= clusterProfile.accentColor, "trait-tinted reveals should pick up trait accent colors")

	assert(ResourceVisuals.getPlacedPhysicalScale("tiny", nil) == 0.72 * RESOURCE_VISUAL_BASE_SCALE, "placed resource scale should apply the larger visual baseline on top of the size bucket")
	assert(ResourceVisuals.getPlacedPhysicalScale(nil, nil) == 1 * RESOURCE_VISUAL_BASE_SCALE, "placed resource scale should fall back to a larger medium baseline when size data is missing")
	assert(ResourceVisuals.getPlacedRootSize("medium", nil) == Vector3.new(3, 3, 3) * RESOURCE_VISUAL_BASE_SCALE, "medium placed resources should inherit the larger baseline size automatically")
	assert(ResourceVisuals.getPlacedRootSize("colossal", nil).X > ResourceVisuals.getPlacedRootSize("tiny", nil).X, "larger size buckets should create a larger physical root part")
	assert(ResourceVisuals.getPlacedBaseHeight("huge", nil) == 0.36 * 1.52 * RESOURCE_VISUAL_BASE_SCALE, "placed resource height offset should scale from both the size bucket and the larger visual baseline")
	assert(clusterProfile.scale > ResourceVisuals.getPlacedPhysicalScale("huge", 1.52), "rarity flair should stay larger than the authoritative physical size")

	local ingotProfile = ResourceVisuals.resolveRevealProfile("gold_ingot", "none", "medium", 1)
	assert(ingotProfile.variantId == "ingot", "ingot resources should resolve to the new grounded silhouette family")

	local moonstoneProfile = ResourceVisuals.resolvePlacedVisualProfile("moonstone", "none", "medium", 1, "moonstone-instance-a")
	assert(moonstoneProfile.variantId == "moonstone", "placed moonstone visuals should reuse the dedicated moon silhouette")
	assert(moonstoneProfile.scale < clusterProfile.scale, "moonstone should stay visually smaller than bulkier cluster resources")
	assert(moonstoneProfile.shineStrength > ingotProfile.shineStrength, "moonstone should keep a stronger iridescent shimmer than plain ingots")
	assert(moonstoneProfile.baseColor ~= Resources.moonstone.color, "moonstone should tint toward a pearly moon palette instead of the raw catalog swatch")

	local eldritchProfile = ResourceVisuals.resolveRevealProfile("worldseed", "celestial", "colossal", 1.85)
	assert(eldritchProfile.variantId == "eldritch", "super-rare rewards should resolve to the otherworldly silhouette family")
	assert(eldritchProfile.scale > ingotProfile.scale, "top-end eldritch rewards should read larger than baseline ingots when rarity and size climb")

	local artifactShards = ResourceVisuals.getOreCrystalDefinitions("artifact")
	assert(#artifactShards == 5, "artifact reveals should build the full five-shard layout")

	local moonstoneDefinitions = ResourceVisuals.getOreCrystalDefinitions("moonstone")
	assert(#moonstoneDefinitions == 5, "moonstone should use the dedicated five-piece crescent layout")

	local ingotDefinitions = ResourceVisuals.getOreCrystalDefinitions("ingot")
	assert(#ingotDefinitions >= 3, "ingot reveals should provide enough pieces to read as a layered bar silhouette")

	local eldritchDefinitions = ResourceVisuals.getOreCrystalDefinitions("eldritch")
	assert(#eldritchDefinitions >= 5, "eldritch reveals should provide a richer silhouette than the basic gemstone")

	local fallbackProfile = ResourceVisuals.resolveRevealProfile("unknown_resource", "none", nil, nil)
	assert(fallbackProfile.displayName == "Resource", "unknown resources should still resolve to a safe fallback label")
	assert(fallbackProfile.variantId == "gemstone", "unknown resources should fall back to the default gemstone silhouette")

	local repeatedLayoutA = ResourceVisuals.getProceduralCrystalDefinitions("cluster", "resource-instance-a", "emerald_cluster")
	local repeatedLayoutB = ResourceVisuals.getProceduralCrystalDefinitions("cluster", "resource-instance-a", "emerald_cluster")
	assert(
		buildLayoutSignature(repeatedLayoutA) == buildLayoutSignature(repeatedLayoutB),
		"the same stable resource id should always resolve to the same procedural layout"
	)

	local variedLayout = ResourceVisuals.getProceduralCrystalDefinitions("cluster", "resource-instance-b", "emerald_cluster")
	assert(
		buildLayoutSignature(repeatedLayoutA) ~= buildLayoutSignature(variedLayout),
		"different stable ids should produce different deterministic crystal layouts"
	)

	local proceduralFallback = ResourceVisuals.getProceduralCrystalDefinitions("unknown_family", "fallback-instance", "unknown_resource")
	local proceduralGemstone = ResourceVisuals.getProceduralCrystalDefinitions("gemstone", "fallback-instance", "unknown_resource")
	assert(#proceduralFallback >= 4, "unknown visual families should still generate a complete fallback layout")
	assert(
		buildLayoutSignature(proceduralFallback) == buildLayoutSignature(proceduralGemstone),
		"unknown visual families should fall back to the gemstone procedural family"
	)

	local seededProfileA = ResourceVisuals.resolveRevealProfile("worldseed", "celestial", "colossal", 1.85, "worldseed-instance-a")
	local seededProfileB = ResourceVisuals.resolveRevealProfile("worldseed", "celestial", "colossal", 1.85, "worldseed-instance-a")
	local seededProfileC = ResourceVisuals.resolveRevealProfile("worldseed", "celestial", "colossal", 1.85, "worldseed-instance-b")
	assert(seededProfileA.proceduralSeed == seededProfileB.proceduralSeed, "matching reveal ids should reuse the same procedural seed")
	assert(seededProfileA.sizeValue == 1.85, "reveal profiles should keep the authoritative rolled size value separate from the visual up-scaling")
	assert(
		buildLayoutSignature(seededProfileA.crystalDefinitions) == buildLayoutSignature(seededProfileB.crystalDefinitions),
		"seeded reveal profiles should embed the same deterministic crystal layout for the same id"
	)
	assert(
		buildLayoutSignature(seededProfileA.crystalDefinitions) ~= buildLayoutSignature(seededProfileC.crystalDefinitions),
		"different reveal ids should fan out into different embedded crystal layouts"
	)

	local ingotProcedural = ResourceVisuals.getProceduralCrystalDefinitions("ingot", "ingot-instance", "gold_ingot")
	assert(ingotProcedural[1].kind == "body", "ingot procedural layouts should preserve the grounded body piece")
	assert(#ingotProcedural >= 4, "ingot procedural layouts should stay compatible with the existing ingot family silhouette")

	local eldritchProcedural = ResourceVisuals.getProceduralCrystalDefinitions("eldritch", "eldritch-instance", "worldseed")
	assert(eldritchProcedural[2].orbit == true, "eldritch procedural layouts should preserve orbiting shards from the current family")

	local repeatedMoonstoneA = ResourceVisuals.getProceduralCrystalDefinitions("moonstone", "moonstone-instance-a", "moonstone")
	local repeatedMoonstoneB = ResourceVisuals.getProceduralCrystalDefinitions("moonstone", "moonstone-instance-a", "moonstone")
	local variedMoonstone = ResourceVisuals.getProceduralCrystalDefinitions("moonstone", "moonstone-instance-b", "moonstone")
	assert(
		buildLayoutSignature(repeatedMoonstoneA) == buildLayoutSignature(repeatedMoonstoneB),
		"moonstone should keep a deterministic crescent layout for the same stable id"
	)
	assert(
		buildLayoutSignature(repeatedMoonstoneA) ~= buildLayoutSignature(variedMoonstone),
		"different moonstone ids should still fan out into different deterministic moon layouts"
	)
end
