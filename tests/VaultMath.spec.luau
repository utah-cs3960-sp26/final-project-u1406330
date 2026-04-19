--!strict

-- Spec coverage for Vault Math to keep deterministic gameplay behavior and regressions easy to verify.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Geodes = require(Shared.Config.Geodes)
local Resources = require(Shared.Config.Resources)
local Sizes = require(Shared.Config.Sizes)
local Traits = require(Shared.Config.Traits)
local RewardPresentation = require(Shared.Domain.RewardPresentation)
local VaultMath = require(Shared.Domain.VaultMath)

return function()
	assert(VaultMath.getResourceSellValue(Resources.quartz, Traits.none) == 25, "common resources should sell from base coin rate")
	assert(VaultMath.getResourceSellValue(Resources.amethyst, Traits.fiery) == 118, "trait multipliers should scale sell value deterministically")
	assert(VaultMath.getResourceSellValue(Resources.star_shard, Traits.singularity) == 30000, "ultra rare traits should carry a much bigger sell premium")
	assert(VaultMath.getResourceSellValue(Resources.quartz, Traits.none, Sizes.huge) == 43, "size categories should increase sell value deterministically")
	assert(VaultMath.getResourceSellValue(nil, Traits.none) == 0, "unknown resources should have no sell value")

	assert(VaultMath.getGeodeSellValue(Geodes.starter_geode) == 45, "geode sell value should derive from crack timer")
	assert(VaultMath.getGeodeSellValue(nil) == 0, "unknown geodes should have no sell value")

	assert(VaultMath.getResourceRarityTier(Resources.quartz) == 0, "common resources should not start the slot machine reveal")
	assert(VaultMath.getResourceRarityTier(Resources.star_shard) == 4, "legendary resources should escalate the reveal tier")
	assert(VaultMath.getTraitRarityTier(Traits.none) == 0, "common attributes should not trigger the attribute reveal scale")
	assert(VaultMath.getTraitRarityTier(Traits.singularity) == 5, "ultra rare attributes should have the highest tier")
	assert(VaultMath.getRewardPresentationScale(Resources.star_shard, Traits.singularity) > VaultMath.getRewardPresentationScale(Resources.quartz, Traits.none), "rarer combinations should produce a bigger reveal scale")

	assert(RewardPresentation.shouldUseSlotMachineReveal(Resources.quartz, Traits.none) == false, "common/common rewards should stay quiet")
	assert(RewardPresentation.shouldUseSlotMachineReveal(Resources.star_shard, Traits.none) == true, "legendary resources should use the slot-machine style reveal")
	assert(RewardPresentation.shouldUseSlotMachineReveal(Resources.quartz, Traits.singularity) == true, "ultra rare attributes should also trigger the slot-machine reveal")
end
