--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local GeodeRoller = require(Shared.Domain.GeodeRoller)
local Geodes = require(Shared.Config.Geodes)
local TraitRoller = require(Shared.Domain.TraitRoller)
local Traits = require(Shared.Config.Traits)

return function()
	local geode = Geodes.starter_geode
	assert(GeodeRoller.getTotalWeight(geode.rolls) == 100, "starter geode should have a full weight table")

	local traitPool = {
		Traits.none,
		Traits.flawless,
		Traits.prismatic,
		Traits.celestial,
	}

	local rng = Random.new(7)
	local geodeResult = GeodeRoller.rollGeode(geode, rng)
	local traitResult = TraitRoller.rollTrait(traitPool, rng)

	assert(geodeResult ~= nil and geodeResult.resourceId ~= nil, "geode roller should return a resource result")
	assert(traitResult ~= nil and traitResult.id ~= nil, "trait roller should return a trait result")
end

