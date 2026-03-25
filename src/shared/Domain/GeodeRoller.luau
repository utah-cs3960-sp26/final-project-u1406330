--!strict

local GeodeRoller = {}

function GeodeRoller.getTotalWeight(entries: { any }): number
	local totalWeight = 0

	for _, entry in ipairs(entries) do
		if type(entry.weight) == "number" and entry.weight > 0 then
			totalWeight += entry.weight
		end
	end

	return totalWeight
end

local function pickWeighted(entries: { any }, roll: number)
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

	return entries[#entries]
end

function GeodeRoller.rollGeode(geodeDefinition: any, rng: Random?)
	local rolls = geodeDefinition.rolls
	if type(rolls) ~= "table" or #rolls == 0 then
		return nil
	end

	local totalWeight = GeodeRoller.getTotalWeight(rolls)
	if totalWeight <= 0 then
		return nil
	end

	local roll = if rng then rng:NextNumber() else math.random()
	local scaledRoll = math.max(0.000001, roll * totalWeight)
	return pickWeighted(rolls, scaledRoll)
end

return GeodeRoller

