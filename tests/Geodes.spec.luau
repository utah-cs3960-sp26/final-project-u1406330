--!strict

-- Spec coverage for Geode config to keep crack timer progression deterministic and easy to inspect.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Geodes = require(Shared.Config.Geodes)

local expectedTimers = {
	starter_geode = 30,
	crystal_cavern_geode = 45,
	moonlit_geode = 60,
	ember_glass_geode = 75,
	verdant_rift_geode = 90,
	aurora_shard_geode = 110,
	thunder_core_geode = 130,
	fossil_vault_geode = 150,
	prism_sun_geode = 175,
	sovereign_nova_geode = 200,
}

local progressionOrder = {
	"starter_geode",
	"crystal_cavern_geode",
	"moonlit_geode",
	"ember_glass_geode",
	"verdant_rift_geode",
	"aurora_shard_geode",
	"thunder_core_geode",
	"fossil_vault_geode",
	"prism_sun_geode",
	"sovereign_nova_geode",
}

return function()
	assert(Geodes.starter_geode.geodeSeconds == 30, "starter geodes should use the new 30-second common baseline")
	assert(Geodes.starter_geode.geodeSeconds >= 30, "the lowest-rarity geode should never crack faster than 30 seconds")

	for geodeId, expectedSeconds in pairs(expectedTimers) do
		local definition = Geodes[geodeId]
		assert(definition ~= nil, string.format("%s should exist in the shared geode catalog", geodeId))
		assert(definition.geodeSeconds == expectedSeconds, string.format("%s should keep its intended crack timer", geodeId))
		assert(definition.geodeSeconds % 5 == 0, string.format("%s timer should stay easy to inspect in 5-second steps", geodeId))
	end

	local previousSeconds = 0
	local previousStep = 0
	for _, geodeId in ipairs(progressionOrder) do
		local currentSeconds = Geodes[geodeId].geodeSeconds
		assert(currentSeconds > previousSeconds, string.format("%s should take longer than the previous geode tier", geodeId))
		if previousSeconds > 0 then
			local currentStep = currentSeconds - previousSeconds
			assert(currentStep >= 15, string.format("%s should increase by at least 15 seconds over the previous tier", geodeId))
			assert(currentStep >= previousStep, string.format("%s should not flatten the timer ramp compared with the previous tier jump", geodeId))
			previousStep = currentStep
		end
		previousSeconds = currentSeconds
	end

	assert(Geodes.verdant_rift_geode.geodeSeconds == Geodes.starter_geode.geodeSeconds * 3, "mid-tier geodes should land on a clean 90-second checkpoint")
	assert(Geodes.prism_sun_geode.geodeSeconds - Geodes.fossil_vault_geode.geodeSeconds == 25, "late-game geodes should widen the wait between top tiers")
	assert(Geodes.sovereign_nova_geode.geodeSeconds - Geodes.prism_sun_geode.geodeSeconds == 25, "the final geode tier should preserve the widened late-game jump")
	assert(Geodes.sovereign_nova_geode.geodeSeconds == 200, "the rarest geode should remain a clear multi-minute capstone timer")
end
