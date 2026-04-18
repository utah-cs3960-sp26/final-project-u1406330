--!strict

-- Deterministic shared rules for Size Roller so gameplay behavior can be reused by the server, client presentation, and specs.

local SizeRoller = {}

function SizeRoller.getTotalWeight(entries: { any }): number
	local totalWeight = 0

	for _, entry in ipairs(entries) do
		if type(entry) == "table" and type(entry.weight) == "number" and entry.weight > 0 then
			totalWeight += entry.weight
		end
	end

	return totalWeight
end

local function pickWeighted(entries: { any }, roll: number)
	local cursor = 0

	for _, entry in ipairs(entries) do
		local weight = if type(entry) == "table" and type(entry.weight) == "number" then entry.weight else 0
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

local function nextRandom(rng: Random?): number
	return if rng then rng:NextNumber() else math.random()
end

function SizeRoller.rollScaleValue(entry, rng: Random?): number
	if type(entry) ~= "table" then
		return 1.0
	end

	local minScale = if type(entry.minScale) == "number" then entry.minScale else entry.scaleFactor or 1.0
	local maxScale = if type(entry.maxScale) == "number" then entry.maxScale else entry.scaleFactor or minScale
	if maxScale <= minScale then
		return minScale
	end

	return minScale + (nextRandom(rng) * (maxScale - minScale))
end

function SizeRoller.rollSize(sizeDefinitions: { any }, rng: Random?)
	if #sizeDefinitions == 0 then
		return nil
	end

	local totalWeight = SizeRoller.getTotalWeight(sizeDefinitions)
	if totalWeight <= 0 then
		return nil
	end

	local roll = nextRandom(rng)
	local scaledRoll = math.max(0.000001, roll * totalWeight)
	local result = pickWeighted(sizeDefinitions, scaledRoll)
	if type(result) ~= "table" then
		return result
	end

	local rolled = {}
	for key, value in pairs(result) do
		rolled[key] = value
	end
	rolled.scaleValue = SizeRoller.rollScaleValue(result, rng)
	return rolled
end

return SizeRoller
