--!strict

-- Deterministic shared rules for Shop Rotation so gameplay behavior can be reused by the server, client presentation, and specs.

local ShopRotation = {}

function ShopRotation.getHourlyIndex(nowUnix: number, offerCount: number)
	if offerCount <= 0 then
		return 0
	end

	return (math.floor(nowUnix / 3600) % offerCount) + 1
end

function ShopRotation.getSecondsUntilNextRotation(nowUnix: number): number
	local currentHourStart = math.floor(nowUnix / 3600) * 3600
	local nextHourStart = currentHourStart + 3600
	return math.max(0, nextHourStart - nowUnix)
end

function ShopRotation.getHourlyState(nowUnix: number, offerCount: number)
	return {
		index = ShopRotation.getHourlyIndex(nowUnix, offerCount),
		secondsRemaining = ShopRotation.getSecondsUntilNextRotation(nowUnix),
	}
end

return ShopRotation
