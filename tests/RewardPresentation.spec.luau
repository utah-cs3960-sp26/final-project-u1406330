--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Resources = require(Shared.Config.Resources)
local Traits = require(Shared.Config.Traits)
local RewardPresentation = require(Shared.Domain.RewardPresentation)

return function()
	assert(RewardPresentation.getResourceRarityRank(Resources.quartz) == 0, "common resources should have the lowest rank")
	assert(RewardPresentation.getResourceCelebrationTier(Resources.amethyst) == 1, "uncommon resources should start the reveal scale above common")
	assert(RewardPresentation.getResourceSlotMachineScale(Resources.star_shard) > RewardPresentation.getResourceSlotMachineScale(Resources.quartz), "rarer resources should scale the reveal harder")

	assert(RewardPresentation.getTraitRarityRank(Traits.none) == 0, "the none attribute should stay common")
	assert(RewardPresentation.getTraitCelebrationTier(Traits.fiery) == 1, "fiery should count as a reveal-worthy attribute")
	assert(RewardPresentation.getTraitRarityRank(Traits.singularity) == 5, "the ultra rare attribute should sit at the top tier")

	assert(RewardPresentation.getRewardBurstScale(Resources.quartz, Traits.none) == 0, "common/common rewards should have no burst scale")
	assert(RewardPresentation.getRewardBurstScale(Resources.star_shard, Traits.singularity) > 2, "legendary plus ultra rare should produce a dramatic burst scale")
end
