--!strict

local Pickaxes = require(script.Parent.Pickaxes)

local function makeOffer(pickaxeId: string, spotlightText: string)
	local pickaxe = Pickaxes.catalog[pickaxeId]

	return {
		offerId = pickaxeId,
		pickaxeId = pickaxeId,
		displayName = pickaxe.displayName,
		rarity = pickaxe.rarity,
		price = pickaxe.price,
		currency = pickaxe.currency,
		cooldownSeconds = pickaxe.cooldownSeconds,
		coinRewardMin = pickaxe.coinRewardMin,
		coinRewardMax = pickaxe.coinRewardMax,
		geodeChance = pickaxe.geodeChance,
		geodeWeights = pickaxe.geodeWeights,
		displayColor = pickaxe.displayColor,
		spotlightText = spotlightText,
	}
end

local catalog = {
	stone_pickaxe = makeOffer("stone_pickaxe", "Entry line"),
	copper_pickaxe = makeOffer("copper_pickaxe", "Early upgrade"),
	iron_pickaxe = makeOffer("iron_pickaxe", "Miner's step"),
	steel_pickaxe = makeOffer("steel_pickaxe", "Workbench favorite"),
	gold_pickaxe = makeOffer("gold_pickaxe", "Shiny middle"),
	platinum_pickaxe = makeOffer("platinum_pickaxe", "Deep haul"),
	emerald_pickaxe = makeOffer("emerald_pickaxe", "Green edge"),
	obsidian_pickaxe = makeOffer("obsidian_pickaxe", "Hard reach"),
	lunar_pickaxe = makeOffer("lunar_pickaxe", "Night shift"),
	crown_pickaxe = makeOffer("crown_pickaxe", "Top shelf"),
}

local starterOffers = {
	catalog.stone_pickaxe,
	catalog.copper_pickaxe,
	catalog.iron_pickaxe,
	catalog.steel_pickaxe,
	catalog.gold_pickaxe,
	catalog.platinum_pickaxe,
	catalog.emerald_pickaxe,
	catalog.obsidian_pickaxe,
	catalog.lunar_pickaxe,
	catalog.crown_pickaxe,
}

local Shops = {
	catalog = catalog,
	starterOffers = starterOffers,
	hourlyRotation = {
		catalog.stone_pickaxe,
		catalog.copper_pickaxe,
		catalog.iron_pickaxe,
		catalog.steel_pickaxe,
		catalog.gold_pickaxe,
		catalog.platinum_pickaxe,
		catalog.emerald_pickaxe,
		catalog.obsidian_pickaxe,
		catalog.lunar_pickaxe,
		catalog.crown_pickaxe,
	},
}

return Shops
