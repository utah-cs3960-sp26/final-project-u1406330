--!strict

-- Spec coverage for Shop Catalog to keep deterministic gameplay behavior and regressions easy to verify.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Geodes = require(Shared.Config.Geodes)
local Pickaxes = require(Shared.Config.Pickaxes)
local Shops = require(Shared.Config.Shops)
local VaultMath = require(Shared.Domain.VaultMath)
local ShopService = require(game:GetService("ServerScriptService"):WaitForChild("Server").Services.ShopService)

local upgradeTargetsByPickaxe = {
	copper_pickaxe = {
		previousPickaxeId = "stone_pickaxe",
		targetMinutes = 1.75,
	},
	iron_pickaxe = {
		previousPickaxeId = "copper_pickaxe",
		targetMinutes = 5,
	},
	steel_pickaxe = {
		previousPickaxeId = "iron_pickaxe",
		targetMinutes = 10,
	},
	gold_pickaxe = {
		previousPickaxeId = "steel_pickaxe",
		targetMinutes = 15,
	},
	platinum_pickaxe = {
		previousPickaxeId = "gold_pickaxe",
		targetMinutes = 20,
	},
	emerald_pickaxe = {
		previousPickaxeId = "platinum_pickaxe",
		targetMinutes = 25,
	},
	obsidian_pickaxe = {
		previousPickaxeId = "emerald_pickaxe",
		targetMinutes = 30,
	},
	lunar_pickaxe = {
		previousPickaxeId = "obsidian_pickaxe",
		targetMinutes = 35,
	},
	crown_pickaxe = {
		previousPickaxeId = "lunar_pickaxe",
		targetMinutes = 40,
	},
}

local function sumWeights(rolls)
	local total = 0
	for _, roll in ipairs(rolls) do
		total += roll.weight
	end
	return total
end

local function getAverageGeodeSellValue(pickaxe)
	local totalWeight = sumWeights(pickaxe.geodeWeights)
	local totalSellValue = 0

	for _, entry in ipairs(pickaxe.geodeWeights) do
		local geodeDefinition = Geodes[entry.geodeId]
		totalSellValue += VaultMath.getGeodeSellValue(geodeDefinition) * entry.weight
	end

	return totalSellValue / math.max(1, totalWeight)
end

local function getMiningCoinsPerMinute(pickaxe)
	local averageCoinReward = (pickaxe.coinRewardMin + pickaxe.coinRewardMax) / 2
	local geodeChanceShare = pickaxe.geodeChance / 100
	local averageSwingValue = (averageCoinReward * (1 - geodeChanceShare)) + (getAverageGeodeSellValue(pickaxe) * geodeChanceShare)
	return averageSwingValue * (60 / pickaxe.cooldownSeconds)
end

return function()
	local shopService = ShopService.new({})

	assert(#Shops.starterOffers == 10, "the shop should expose ten starter-side offers")
	assert(#Shops.hourlyRotation == 10, "the shop should expose ten hourly offers")

	for _, pickaxeId in ipairs(Pickaxes.order) do
		local pickaxe = Pickaxes.catalog[pickaxeId]
		assert(pickaxe ~= nil, string.format("pickaxe config should include %s", pickaxeId))
		assert(sumWeights(pickaxe.geodeWeights) == 100, string.format("%s should have a full weight table", pickaxeId))

		local offer = shopService:getOffer(pickaxeId, 0)
		assert(offer ~= nil, string.format("shop service should resolve %s", pickaxeId))
		assert(offer.offerId == pickaxeId, string.format("%s should preserve its id", pickaxeId))
		assert(offer.displayName == pickaxe.displayName, string.format("%s should mirror the pickaxe display name", pickaxeId))
		assert(offer.price == pickaxe.price, string.format("%s should mirror the pickaxe price", pickaxeId))
		assert(offer.currency == pickaxe.currency, string.format("%s should mirror the pickaxe currency", pickaxeId))
		assert(offer.cooldownSeconds == pickaxe.cooldownSeconds, string.format("%s should mirror the pickaxe cooldown", pickaxeId))
		assert(offer.coinRewardMin == pickaxe.coinRewardMin, string.format("%s should mirror the coin reward minimum", pickaxeId))
		assert(offer.coinRewardMax == pickaxe.coinRewardMax, string.format("%s should mirror the coin reward maximum", pickaxeId))
		assert(offer.geodeChance == pickaxe.geodeChance, string.format("%s should mirror the geode chance", pickaxeId))
		assert(offer.displayColor ~= nil, string.format("%s should carry a display color", pickaxeId))
		assert(offer.rarity ~= nil and offer.rarity ~= "", string.format("%s should carry a rarity label", pickaxeId))
	end

	local unknownOffer = shopService:getOffer("missing_pickaxe", 0)
	assert(unknownOffer == nil, "unknown offers should be rejected")

	local starterOffer = shopService:getOffer("stone_pickaxe", 0)
	assert(starterOffer ~= nil, "stone pickaxe should remain available")
	assert(starterOffer.source == "starter", "stone pickaxe should resolve from starter offers")
	assert(starterOffer.price == 500, "stone pickaxe price should stay anchored to the new economy ramp")
	assert(starterOffer.currency == "coins", "stone pickaxe should stay coin priced")

	local previousPrice = 0
	for _, pickaxeId in ipairs(Pickaxes.order) do
		local pickaxe = Pickaxes.catalog[pickaxeId]
		assert(pickaxe.price > previousPrice, string.format("%s should cost more than the previous pickaxe tier", pickaxeId))
		previousPrice = pickaxe.price
	end

	local starterCoins = 250
	for pickaxeId, target in pairs(upgradeTargetsByPickaxe) do
		local pickaxe = Pickaxes.catalog[pickaxeId]
		local previousPickaxe = Pickaxes.catalog[target.previousPickaxeId]
		assert(pickaxe ~= nil and previousPickaxe ~= nil, string.format("%s should have a valid previous tier", pickaxeId))

		local priceDelta = pickaxe.price - previousPickaxe.price
		local effectiveDelta = if target.previousPickaxeId == "stone_pickaxe" then pickaxe.price - starterCoins else priceDelta
		local miningMinutes = effectiveDelta / getMiningCoinsPerMinute(previousPickaxe)
		local minMinutes = target.targetMinutes * 0.85
		local maxMinutes = target.targetMinutes * 1.2
		assert(
			miningMinutes >= minMinutes and miningMinutes <= maxMinutes,
			string.format(
				"%s should land near its intended affordability window; expected about %.2f minutes, got %.2f",
				pickaxeId,
				target.targetMinutes,
				miningMinutes
			)
		)
	end

	local hourlyOffer, hourlyIndex, secondsRemaining = shopService:getHourlyOffer(0)
	assert(hourlyOffer ~= nil, "hourly rotation should return the first offer at hour zero")
	assert(hourlyOffer.offerId == "stone_pickaxe", "hourly rotation should begin with the stone pickaxe")
	assert(hourlyIndex == 1, "hourly rotation should start at index one")
	assert(secondsRemaining == 3600, "hourly rotation should count down to the next hour")

	local lateHourlyOffer, lateHourlyIndex = shopService:getHourlyOffer(9 * 3600)
	assert(lateHourlyOffer ~= nil, "hourly rotation should keep cycling through the catalog")
	assert(lateHourlyOffer.offerId == "crown_pickaxe", "the rotation should reach the last configured offer")
	assert(lateHourlyIndex == 10, "the last configured offer should occupy the tenth rotation slot")

	local shopState = shopService:getShopState(2 * 3600 + 123)
	assert(shopState.starterOffer.offerId == "stone_pickaxe", "shop state should always surface the starter offer")
	assert(shopState.currentOffer.offerId == "iron_pickaxe", "shop state should surface the current hourly offer")
	assert(shopState.offerIndex == 3, "shop state should expose the active hourly index")
	assert(shopState.secondsRemaining == 3477, "shop state should report the remaining time in the hour")
	assert(shopState.currentOffer.source == "hourly", "current hourly offer should be tagged as hourly")
end
