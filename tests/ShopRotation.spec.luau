--!strict

-- Spec coverage for Shop Rotation to keep deterministic gameplay behavior and regressions easy to verify.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local ShopRotation = require(Shared.Domain.ShopRotation)

return function()
	assert(ShopRotation.getHourlyIndex(0, 3) == 1, "rotation should start at index 1")
	assert(ShopRotation.getHourlyIndex(3600, 3) == 2, "rotation should advance every hour")
	assert(ShopRotation.getSecondsUntilNextRotation(3599) == 1, "rotation timer should count down to the next hour")

	local state = ShopRotation.getHourlyState(7201, 4)
	assert(state.index == 3, "hourly state should expose the active index")
	assert(state.secondsRemaining == 3599, "hourly state should expose remaining seconds")
end
