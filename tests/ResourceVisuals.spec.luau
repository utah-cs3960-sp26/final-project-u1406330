--!strict

-- Spec coverage for Resource Visuals to keep deterministic gameplay behavior and regressions easy to verify.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local ResourceVisuals = require(Shared.Domain.ResourceVisuals)
local Resources = require(Shared.Config.Resources)

return function()
	assert(ResourceVisuals.getRarityRank("Common") == 1, "common visuals should use the base rarity rank")
	assert(ResourceVisuals.getRarityRank("Legendary") == 5, "legendary visuals should map to the top rarity rank")

	assert(ResourceVisuals.getResourceVariantShape("quartz", Resources.quartz) == "gemstone", "quartz should keep the gemstone silhouette")
	assert(ResourceVisuals.getResourceVariantShape("emerald_cluster", Resources.emerald_cluster) == "cluster", "emerald cluster should use the cluster silhouette")
	assert(ResourceVisuals.getResourceVariantShape("diamond_core", Resources.diamond_core) == "artifact", "diamond core should use the artifact silhouette")
	assert(ResourceVisuals.getResourceVariantShape("gold_ingot", Resources.gold_ingot) == "ingot", "gold ingot should use the grounded ingot silhouette")
	assert(ResourceVisuals.getResourceVariantShape("worldseed", Resources.worldseed) == "eldritch", "worldseed should use the otherworldly eldritch silhouette")

	local clusterProfile = ResourceVisuals.resolveRevealProfile("emerald_cluster", "verdant", "huge", 1.52)
	assert(clusterProfile.variantId == "cluster", "resolved profiles should preserve the expected silhouette")
	assert(clusterProfile.scale > 1.52, "rarity scale should stack on top of the rolled size")
	assert(clusterProfile.traitAccentColor ~= clusterProfile.accentColor, "trait-tinted reveals should pick up trait accent colors")

	assert(ResourceVisuals.getPlacedPhysicalScale("tiny", nil) == 0.72, "placed resource scale should default from the size bucket")
	assert(ResourceVisuals.getPlacedPhysicalScale(nil, nil) == 1, "placed resource scale should fall back to medium when size data is missing")
	assert(ResourceVisuals.getPlacedRootSize("medium", nil) == Vector3.new(3, 3, 3), "medium placed resources should keep the baseline physical size")
	assert(ResourceVisuals.getPlacedRootSize("colossal", nil).X > ResourceVisuals.getPlacedRootSize("tiny", nil).X, "larger size buckets should create a larger physical root part")
	assert(ResourceVisuals.getPlacedBaseHeight("huge", nil) == 0.36 * 1.52, "placed resource height offset should scale from the size bucket")
	assert(clusterProfile.scale > ResourceVisuals.getPlacedPhysicalScale("huge", 1.52), "rarity flair should stay larger than the authoritative physical size")

	local ingotProfile = ResourceVisuals.resolveRevealProfile("gold_ingot", "none", "medium", 1)
	assert(ingotProfile.variantId == "ingot", "ingot resources should resolve to the new grounded silhouette family")

	local eldritchProfile = ResourceVisuals.resolveRevealProfile("worldseed", "celestial", "colossal", 1.85)
	assert(eldritchProfile.variantId == "eldritch", "super-rare rewards should resolve to the otherworldly silhouette family")
	assert(eldritchProfile.scale > ingotProfile.scale, "top-end eldritch rewards should read larger than baseline ingots when rarity and size climb")

	local artifactShards = ResourceVisuals.getOreCrystalDefinitions("artifact")
	assert(#artifactShards == 5, "artifact reveals should build the full five-shard layout")

	local ingotDefinitions = ResourceVisuals.getOreCrystalDefinitions("ingot")
	assert(#ingotDefinitions >= 3, "ingot reveals should provide enough pieces to read as a layered bar silhouette")

	local eldritchDefinitions = ResourceVisuals.getOreCrystalDefinitions("eldritch")
	assert(#eldritchDefinitions >= 5, "eldritch reveals should provide a richer silhouette than the basic gemstone")

	local fallbackProfile = ResourceVisuals.resolveRevealProfile("unknown_resource", "none", nil, nil)
	assert(fallbackProfile.displayName == "Resource", "unknown resources should still resolve to a safe fallback label")
	assert(fallbackProfile.variantId == "gemstone", "unknown resources should fall back to the default gemstone silhouette")
end
