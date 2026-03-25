--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local EconomyMath = require(Shared.Domain.EconomyMath)

return function()
	assert(EconomyMath.getResourceIncome(10, 2, 1.5, 1.1, 1) == 33, "resource income should multiply all factors")
	assert(EconomyMath.getPassiveIncomeForElapsedSeconds(12, 30) == 360, "passive income should scale by elapsed time")
	assert(EconomyMath.getPrestigeMultiplier(3, 0.1, 1) == 1.3, "prestige multiplier should scale linearly")

	local awardedCoins, remainder = EconomyMath.resolvePassiveAccrual(1.25, 3, 0.5)
	assert(awardedCoins == 4, "passive accrual should award whole coins only")
	assert(math.abs(remainder - 0.25) < 0.0001, "passive accrual should preserve fractional carry")
end

