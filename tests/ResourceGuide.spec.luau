--!strict

-- Spec coverage for Resource Guide data so the HUD chart stays deterministic as the resource catalog changes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local ResourceGuide = require(Shared.Domain.ResourceGuide)

return function()
	local order = ResourceGuide.getRarityOrder()
	assert(#order == 5, "resource guide should expose the five gameplay rarity tiers")
	assert(order[1] == "Common" and order[5] == "Legendary", "resource guide should keep the rarity ladder ordered from common to legendary")

	local stoneSummary = ResourceGuide.getGuideSummary("stone_pickaxe")
	assert(stoneSummary.pickaxeId == "stone_pickaxe", "guide summary should resolve the requested pickaxe")
	assert(stoneSummary.totalResourceChance > 0, "guide summary should expose a real resource drop chance")
	assert(
		string.find(stoneSummary.subtitleText, "Stone Pickaxe", 1, true) ~= nil,
		"guide summary should describe which pickaxe the chart is using"
	)
	assert(
		string.find(stoneSummary.hintText, stoneSummary.totalResourceChanceText, 1, true) ~= nil,
		"guide summary hint should surface the resolved total resource chance for the HUD"
	)

	local stoneRows = ResourceGuide.getGuideRows("stone_pickaxe")
	local crownRows = ResourceGuide.getGuideRows("crown_pickaxe")
	assert(#stoneRows == 5, "resource guide should build one row per rarity tier")
	assert(#crownRows == 5, "resource guide should stay stable across pickaxe tiers")

	local totalShare = 0
	local totalChance = 0
	for index, row in ipairs(stoneRows) do
		totalShare += row.share
		totalChance += row.chance
		assert(row.layoutOrder == index, "resource guide rows should stay stable for UI layouts")
		assert(row.pickaxeId == "stone_pickaxe", "rows should remember which pickaxe they were derived from")
		assert(row.chance >= 0, "rarity rows should never expose negative drop chances")
		assert(row.barFillShare >= 0 and row.barFillShare <= 1, "guide bars should stay normalized for the UI")
		assert(type(row.rarity) == "string" and row.rarity ~= "", "guide rows should expose a rarity label for the HUD chip")
		assert(type(row.percentageText) == "string" and row.percentageText ~= "", "guide rows should expose visible percent text")
		assert(type(row.countText) == "string" and row.countText ~= "", "guide rows should expose descriptive support text")
	end

	assert(math.abs(totalShare - 1) < 0.001, "resource guide rows should distribute the full resource-drop share")
	assert(math.abs(totalChance - stoneSummary.totalResourceChance) < 0.0001, "row chances should add up to the guide summary total")
	assert(stoneRows[3].rank == 3, "rare should preserve its shared rarity rank for styling")
	assert(stoneRows[1].percentage > stoneRows[5].percentage, "common resources should be more likely than legendary ones")
	assert(crownRows[5].percentage > stoneRows[5].percentage, "better pickaxes should improve legendary drop odds in the guide")
	assert(crownRows[1].percentage < stoneRows[1].percentage, "better pickaxes should reduce the common share of resource drops")
	assert(stoneRows[1].percentageText ~= "20.0%", "guide percentages should not be derived from catalog counts anymore")
end
