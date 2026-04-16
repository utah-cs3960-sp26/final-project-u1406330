--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local GeodeRoller = require(Shared.Domain.GeodeRoller)
local TraitRoller = require(Shared.Domain.TraitRoller)
local Traits = require(Shared.Config.Traits)

local function makeRng(numberRoll: number)
	local rng = {}

	function rng:NextNumber()
		return numberRoll
	end

	return rng
end

return function()
	local geode = {
		rolls = {
			{ resourceId = "common", weight = 60 },
			{ resourceId = "rare", weight = 40 },
		},
	}

	assert(GeodeRoller.getTotalWeight(geode.rolls) == 100, "geode roller should still sum weighted tables")

	local weightedEntries = {
		{ id = "ignore_zero", weight = 0 },
		{ id = "ignore_negative", weight = -12 },
		{ id = "ignore_missing" },
		{ id = "count_me", weight = 17 },
	}
	assert(TraitRoller.getTotalWeight(weightedEntries) == 17, "trait weight totals should ignore invalid entries")

	local lowRoll = TraitRoller.rollTrait(Traits.order, makeRng(0.0001))
	assert(lowRoll ~= nil and lowRoll.id == "none", "low rolls should land on the common none trait")

	local fieryRoll = TraitRoller.rollTrait(Traits.order, makeRng(9000 / 12501))
	assert(fieryRoll ~= nil and fieryRoll.id == "fiery", "mid-table rolls should land on the fiery attribute")

	local ultraRareRoll = TraitRoller.rollTrait(Traits.order, makeRng(0.999999))
	assert(ultraRareRoll ~= nil and ultraRareRoll.id == "singularity", "top-end rolls should reach the ultra rare attribute")

	local emptyRoll = TraitRoller.rollTrait({}, makeRng(0.5))
	assert(emptyRoll == nil, "empty trait pools should be rejected")
end
