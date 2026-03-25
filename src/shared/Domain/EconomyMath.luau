--!strict

local EconomyMath = {}

function EconomyMath.getPrestigeMultiplier(prestigeCount: number, step: number, baseMultiplier: number?): number
	return (baseMultiplier or 1) + (prestigeCount * step)
end

function EconomyMath.getResourceIncome(baseRate: number, traitMultiplier: number, stationMultiplier: number, prestigeMultiplier: number?, eventMultiplier: number?): number
	return baseRate * traitMultiplier * stationMultiplier * (prestigeMultiplier or 1) * (eventMultiplier or 1)
end

function EconomyMath.getPassiveIncomeForElapsedSeconds(passiveRate: number, elapsedSeconds: number): number
	return math.max(0, passiveRate) * math.max(0, elapsedSeconds)
end

function EconomyMath.resolvePassiveAccrual(passiveRate: number, elapsedSeconds: number, existingRemainder: number?): (number, number)
	local totalIncome = EconomyMath.getPassiveIncomeForElapsedSeconds(passiveRate, elapsedSeconds) + math.max(0, existingRemainder or 0)
	local awardedCoins = math.floor(totalIncome)
	return awardedCoins, totalIncome - awardedCoins
end

function EconomyMath.sumResourceIncome(entries: { { baseRate: number, traitMultiplier: number, stationMultiplier: number } }, prestigeMultiplier: number?): number
	local total = 0

	for _, entry in ipairs(entries) do
		total += EconomyMath.getResourceIncome(
			entry.baseRate,
			entry.traitMultiplier,
			entry.stationMultiplier,
			prestigeMultiplier,
			1
		)
	end

	return total
end

return EconomyMath

