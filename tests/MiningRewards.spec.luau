--!strict

-- Spec coverage for Mining Rewards to keep deterministic gameplay behavior and regressions easy to verify.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Geodes = require(Shared.Config.Geodes)
local MiningRewards = require(Shared.Domain.MiningRewards)
local Pickaxes = require(Shared.Config.Pickaxes)

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

local expectedGeodeChanceByPickaxe = {
	stone_pickaxe = 9,
	copper_pickaxe = 11,
	iron_pickaxe = 11,
	steel_pickaxe = 12,
	gold_pickaxe = 13,
	platinum_pickaxe = 14,
	emerald_pickaxe = 14,
	obsidian_pickaxe = 15,
	lunar_pickaxe = 16,
	crown_pickaxe = 17,
}

local function makeRng(numberRoll: number, integerRoll: number)
	local rng = {}

	function rng:NextNumber()
		return numberRoll
	end

	function rng:NextInteger(_minValue: number, maxValue: number)
		return math.clamp(integerRoll, 1, maxValue)
	end

	return rng
end

local function findIndex(entries, value)
	for index, entry in ipairs(entries) do
		if entry == value then
			return index
		end
	end

	return nil
end

return function()
	local stonePickaxe = Pickaxes.catalog.stone_pickaxe
	local crownPickaxe = Pickaxes.catalog.crown_pickaxe

	local coinReward = MiningRewards.rollReward(stonePickaxe, makeRng(0.99, 7))
	assert(coinReward ~= nil, "coin roll should return a reward")
	assert(coinReward.rewardType == "coins", "coin path should return coins")
	assert(coinReward.pickaxeId == "stone_pickaxe", "coin reward should preserve the pickaxe id")
	assert(coinReward.coins ~= nil and coinReward.coins >= stonePickaxe.coinRewardMin and coinReward.coins <= stonePickaxe.coinRewardMax, "coin reward should stay inside the configured range")
	assert(coinReward.geodeId == nil, "coin path should not include a geode id")

	local geodeReward = MiningRewards.rollReward(stonePickaxe, makeRng(0.10, 1))
	assert(geodeReward ~= nil, "geode roll should return a reward")
	assert(geodeReward.rewardType == "geode", "geode path should return a geode")
	assert(geodeReward.pickaxeId == "stone_pickaxe", "geode reward should preserve the pickaxe id")
	assert(geodeReward.coins == nil, "geode path should not include coins")
	assert(geodeReward.geodeId == "starter_geode", "the stone pickaxe should favor the common geode on a low weighted roll")

	local stoneRareReward = MiningRewards.rollReward(stonePickaxe, makeRng(0.10, 45))
	local crownRareReward = MiningRewards.rollReward(crownPickaxe, makeRng(0.10, 45))

	assert(stoneRareReward ~= nil and stoneRareReward.rewardType == "geode", "stone pickaxe should still roll a geode on the shared test roll")
	assert(crownRareReward ~= nil and crownRareReward.rewardType == "geode", "crown pickaxe should still roll a geode on the shared test roll")
	assert(stoneRareReward.geodeId ~= nil and crownRareReward.geodeId ~= nil, "both rare-roll checks should resolve geodes")

	local stoneIndex = findIndex(geodeOrder, stoneRareReward.geodeId)
	local crownIndex = findIndex(geodeOrder, crownRareReward.geodeId)
	assert(stoneIndex ~= nil and crownIndex ~= nil, "rolled geodes should exist in the geode ladder")
	assert(crownIndex > stoneIndex, "later pickaxes should bias the same roll toward rarer geodes")

	local unknownReward, unknownReason = MiningRewards.rollReward(nil, makeRng(0.99, 1))
	assert(unknownReward == nil, "unknown pickaxes should be rejected")
	assert(unknownReason == "unknown_pickaxe", "unknown pickaxe rejection should be explicit")

	for _, pickaxeId in ipairs(Pickaxes.order) do
		local pickaxe = Pickaxes.catalog[pickaxeId]
		local expectedGeodeChance = expectedGeodeChanceByPickaxe[pickaxeId]
		assert(expectedGeodeChance ~= nil, string.format("%s should have an expected scaled geode chance", pickaxeId))
		assert(pickaxe.geodeChance == expectedGeodeChance, string.format("%s should use the scaled geode find chance", pickaxeId))

		local geodeThreshold = pickaxe.geodeChance / 100
		local belowThresholdReward = MiningRewards.rollReward(pickaxe, makeRng(math.max(0, geodeThreshold - 0.001), 1))
		assert(belowThresholdReward ~= nil and belowThresholdReward.rewardType == "geode", string.format("%s should still award a geode just inside its scaled chance", pickaxeId))

		local aboveThresholdReward = MiningRewards.rollReward(pickaxe, makeRng(math.min(0.999, geodeThreshold + 0.001), pickaxe.coinRewardMax))
		assert(aboveThresholdReward ~= nil and aboveThresholdReward.rewardType == "coins", string.format("%s should award coins once the scaled geode chance is missed", pickaxeId))

		local reward = MiningRewards.rollReward(pickaxe, makeRng(0.99, pickaxe.coinRewardMax))
		assert(reward ~= nil and reward.rewardType == "coins", string.format("%s should be able to produce a coin reward", pickaxeId))
		assert(reward.coins ~= nil, string.format("%s should return a coin amount on the coin path", pickaxeId))
		assert(reward.coins >= pickaxe.coinRewardMin and reward.coins <= pickaxe.coinRewardMax, string.format("%s coin reward should remain within bounds", pickaxeId))
	end

	assert(Geodes[geodeReward.geodeId] ~= nil, "rolled geodes should exist in the shared geode catalog")
	assert(MiningRewards.getTotalGeodeWeight(stonePickaxe) == 100, "the stone pickaxe should have a full geode weight table")
	assert(MiningRewards.getTotalGeodeWeight(crownPickaxe) == 100, "the crown pickaxe should keep its geode tier weighting after the chance rebalance")
end
