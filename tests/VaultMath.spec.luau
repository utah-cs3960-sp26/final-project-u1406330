--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Resources = require(Shared.Config.Resources)
local Geodes = require(Shared.Config.Geodes)
local Traits = require(Shared.Config.Traits)
local VaultMath = require(Shared.Domain.VaultMath)

return function()
	assert(VaultMath.getResourceSellValue(Resources.quartz, Traits.none) == 25, "common resources should sell from base coin rate")
	assert(VaultMath.getResourceSellValue(Resources.amethyst, Traits.flawless) == 150, "traits should increase resource sell value")
	assert(VaultMath.getResourceSellValue(nil, Traits.none) == 0, "unknown resources should have no sell value")
	assert(VaultMath.getGeodeSellValue(Geodes.starter_geode) == 30, "geode sell value should derive from crack timer")
	assert(VaultMath.getGeodeSellValue(nil) == 0, "unknown geodes should have no sell value")
end
