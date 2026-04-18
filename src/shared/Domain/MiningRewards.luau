--!strict

-- Deterministic shared rules for Mining Rewards so gameplay behavior can be reused by the server, client presentation, and specs.

local MiningRewards = {}

local function rollNumber(rng: any): number
	if rng ~= nil then
		return rng:NextNumber()
	end

	return math.random()
end

local function rollInteger(rng: any, minValue: number, maxValue: number): number
	if rng ~= nil then
		return rng:NextInteger(minValue, maxValue)
	end

	return math.random(minValue, maxValue)
end

local function getGeodeWeights(pickaxeDefinition: any)
	if type(pickaxeDefinition) ~= "table" then
		return nil
	end

	local geodeWeights = pickaxeDefinition.geodeWeights
	if type(geodeWeights) ~= "table" then
		return nil
	end

	return geodeWeights
end

local function pickWeightedEntry(entries: { any }, roll: number)
	local cursor = 0

	for _, entry in ipairs(entries) do
		local weight = if type(entry.weight) == "number" then entry.weight else 0
		if weight <= 0 then
			continue
		end

		cursor += weight
		if roll <= cursor then
			return entry
		end
	end

	return nil
end

function MiningRewards.getTotalGeodeWeight(pickaxeDefinition: any): number
	local geodeWeights = getGeodeWeights(pickaxeDefinition)
	if geodeWeights == nil then
		return 0
	end

	local totalWeight = 0

	for _, entry in ipairs(geodeWeights) do
		if type(entry.weight) == "number" and entry.weight > 0 then
			totalWeight += entry.weight
		end
	end

	return totalWeight
end

function MiningRewards.rollCoins(pickaxeDefinition: any, rng: any)
	if type(pickaxeDefinition) ~= "table" or type(pickaxeDefinition.id) ~= "string" then
		return nil, "invalid_pickaxe"
	end

	local minCoins = pickaxeDefinition.coinRewardMin
	local maxCoins = pickaxeDefinition.coinRewardMax

	if type(minCoins) ~= "number" or type(maxCoins) ~= "number" or minCoins > maxCoins then
		return nil, "invalid_pickaxe"
	end

	local coins = rollInteger(rng, minCoins, maxCoins)
	return {
		rewardType = "coins",
		pickaxeId = pickaxeDefinition.id,
		displayName = pickaxeDefinition.displayName,
		rarity = pickaxeDefinition.rarity,
		coins = coins,
		geodeId = nil,
	}
end

function MiningRewards.rollGeode(pickaxeDefinition: any, rng: any)
	if type(pickaxeDefinition) ~= "table" or type(pickaxeDefinition.id) ~= "string" then
		return nil, "invalid_pickaxe"
	end

	local geodeWeights = getGeodeWeights(pickaxeDefinition)
	local totalWeight = MiningRewards.getTotalGeodeWeight(pickaxeDefinition)

	if geodeWeights == nil or totalWeight <= 0 then
		return nil, "invalid_pickaxe"
	end

	local roll = rollInteger(rng, 1, totalWeight)
	local entry = pickWeightedEntry(geodeWeights, roll)
	if entry == nil or type(entry.geodeId) ~= "string" then
		return nil, "invalid_pickaxe"
	end

	return {
		rewardType = "geode",
		pickaxeId = pickaxeDefinition.id,
		displayName = pickaxeDefinition.displayName,
		rarity = pickaxeDefinition.rarity,
		coins = nil,
		geodeId = entry.geodeId,
	}
end

function MiningRewards.rollReward(pickaxeDefinition: any, rng: any)
	if type(pickaxeDefinition) ~= "table" or type(pickaxeDefinition.id) ~= "string" then
		return nil, "unknown_pickaxe"
	end

	if type(pickaxeDefinition.geodeChance) ~= "number" then
		return nil, "invalid_pickaxe"
	end

	local chanceRoll = rollNumber(rng)
	if chanceRoll <= (pickaxeDefinition.geodeChance / 100) then
		return MiningRewards.rollGeode(pickaxeDefinition, rng)
	end

	return MiningRewards.rollCoins(pickaxeDefinition, rng)
end

return MiningRewards
