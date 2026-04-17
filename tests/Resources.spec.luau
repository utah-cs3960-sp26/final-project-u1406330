--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Resources = require(Shared.Config.Resources)

local function countByRarity()
	local counts = {
		Common = 0,
		Uncommon = 0,
		Rare = 0,
		Epic = 0,
		Legendary = 0,
	}

	for _, definition in pairs(Resources) do
		if counts[definition.rarity] ~= nil then
			counts[definition.rarity] += 1
		end
	end

	return counts
end

return function()
	local resourceCount = 0
	for _ in pairs(Resources) do
		resourceCount += 1
	end

	assert(resourceCount == 25, "resource catalog should expand to twenty-five collectible resources")

	local rarityCounts = countByRarity()
	assert(rarityCounts.Common == 5, "common rarity should have a full five-resource spread")
	assert(rarityCounts.Uncommon == 5, "uncommon rarity should have a full five-resource spread")
	assert(rarityCounts.Rare == 5, "rare rarity should have a full five-resource spread")
	assert(rarityCounts.Epic == 5, "epic rarity should have a full five-resource spread")
	assert(rarityCounts.Legendary == 5, "legendary rarity should have a full five-resource spread")

	assert(Resources.gold_ingot ~= nil and Resources.gold_ingot.rarity == "Rare", "gold ingot should anchor the grounded raw-material family in the midgame")
	assert(Resources.mythril_ingot ~= nil and Resources.mythril_ingot.rarity == "Epic", "mythril ingot should provide a premium ingot chase")
	assert(Resources.aetherite_relic ~= nil and Resources.aetherite_relic.rarity == "Epic", "aetherite relic should exist as a high-tier otherworldly reward")
	assert(Resources.worldseed ~= nil and Resources.worldseed.rarity == "Legendary", "worldseed should exist as a top-end legendary reward")

	assert(Resources.copper_nugget.baseCoinRate > Resources.quartz.baseCoinRate, "later common resources should still step up in sell value")
	assert(Resources.gold_ingot.baseCoinRate > Resources.emerald_cluster.baseCoinRate, "rare additions should scale above the starter rare baseline")
	assert(Resources.mythril_ingot.baseCoinRate > Resources.diamond_core.baseCoinRate, "epic additions should beat the original epic baseline")
	assert(Resources.worldseed.baseCoinRate > Resources.star_shard.baseCoinRate, "at least one legendary addition should outrank the original legendary sell value")
end
