--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local SizeRules = require(Shared.Domain.SizeRules)

return function()
	assert(SizeRules.getDisplayName("medium", nil) == "Medium", "legacy size ids should still resolve to their category")
	assert(SizeRules.getDisplayName(nil, 0.72) == "Tiny", "low numeric scales should resolve to Tiny")
	assert(SizeRules.getDisplayName(nil, 0.88) == "Small", "small-range scales should resolve to Small")
	assert(SizeRules.getDisplayName(nil, 1.22) == "Large", "large-range scales should resolve to Large")
	assert(SizeRules.getDisplayName(nil, 1.85) == "Colossal", "high numeric scales should resolve to Colossal")

	assert(SizeRules.getScaleValue(nil, 0.1) == 0.65, "scale should clamp to the configured minimum")
	assert(SizeRules.getScaleValue(nil, 5.0) == 2.0, "scale should clamp to the configured maximum")
	assert(SizeRules.getSellMultiplier(nil, 1.52) == 1.7, "sell multiplier should come from the resolved size category")
	assert(SizeRules.getDisplayText(nil, 1.22) == "Large (1.22x)", "display text should include both category and numeric scale")
end
