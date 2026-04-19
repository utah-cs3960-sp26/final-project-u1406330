--!strict

-- Spec coverage for Geode config to keep crack timer progression deterministic and easy to inspect.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Geodes = require(Shared.Config.Geodes)

local expectedTimers = {
	starter_geode = 15,
	crystal_cavern_geode = 20,
	moonlit_geode = 25,
	ember_glass_geode = 30,
	verdant_rift_geode = 35,
	aurora_shard_geode = 40,
	thunder_core_geode = 50,
	fossil_vault_geode = 60,
	prism_sun_geode = 75,
	sovereign_nova_geode = 90,
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
	assert(Geodes.starter_geode.geodeSeconds == 15, "starter geodes should use the 15-second common baseline")

	for geodeId, expectedSeconds in pairs(expectedTimers) do
		local definition = Geodes[geodeId]
		assert(definition ~= nil, string.format("%s should exist in the shared geode catalog", geodeId))
		assert(definition.geodeSeconds == expectedSeconds, string.format("%s should keep its intended crack timer", geodeId))
		assert(definition.geodeSeconds % 5 == 0, string.format("%s timer should stay easy to inspect in 5-second steps", geodeId))
	end

	local previousSeconds = 0
	for _, geodeId in ipairs(progressionOrder) do
		local currentSeconds = Geodes[geodeId].geodeSeconds
		assert(currentSeconds > previousSeconds, string.format("%s should take longer than the previous geode tier", geodeId))
		previousSeconds = currentSeconds
	end

	assert(Geodes.prism_sun_geode.geodeSeconds - Geodes.fossil_vault_geode.geodeSeconds == 15, "late-game geodes should widen the wait between top tiers")
	assert(Geodes.sovereign_nova_geode.geodeSeconds == Geodes.starter_geode.geodeSeconds * 6, "the rarest geode should remain a clear long-form capstone timer")
end
