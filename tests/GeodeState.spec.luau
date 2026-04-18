--!strict

-- Spec coverage for Geode State to keep deterministic gameplay behavior and regressions easy to verify.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local GeodeState = require(Shared.Domain.GeodeState)

return function()
	local instance = GeodeState.createInstance("geode_1", "starter_geode", 100, 10)
	assert(instance.id == "geode_1", "created geode should keep the provided id")
	assert(instance.geodeTypeId == "starter_geode", "created geode should keep the type id")
	assert(instance.endsAt == 110, "created geode should derive its end time from the timer")

	local profile = {
		geodesById = {
			geode_1 = {
				id = "geode_1",
				geodeTypeId = "starter_geode",
				status = "queued",
				startedAt = 100,
				endsAt = 110,
				obtainedAt = 100,
				placement = {
					plotId = "plot_1",
					x = 1,
					y = 1,
					width = 2,
					height = 2,
				},
			},
			geode_2 = {
				id = "geode_2",
				geodeTypeId = "moonlit_geode",
				status = "queued",
				startedAt = 100,
				endsAt = 130,
				obtainedAt = 100,
				placement = nil,
			},
		},
		geodeOrder = { "geode_1", "geode_2" },
		geodeQueue = {},
	}

	local queueEntries = GeodeState.buildQueueEntries(profile.geodesById, profile.geodeOrder, 115)
	assert(#queueEntries == 2, "queue entries should be derived from owned geodes")
	assert(queueEntries[1].status == "finished", "derived queue entries should reflect ready geodes")

	local claimableIds = GeodeState.getClaimableIds(profile, 115, nil)
	assert(#claimableIds == 1 and claimableIds[1] == "geode_1", "only placed finished geodes should be claimable")

	GeodeState.removeGeode(profile.geodesById, profile.geodeOrder, "geode_1")
	assert(profile.geodesById.geode_1 == nil, "removing a geode should clear it from ownership state")
	assert(#profile.geodeOrder == 1 and profile.geodeOrder[1] == "geode_2", "removing a geode should update order")

	local migrated = {
		geodesById = {},
		geodeOrder = {},
		geodeQueue = {
			{
				id = "legacy_geode",
				geodeId = "starter_geode",
				startedAt = 50,
				endsAt = 65,
				status = "queued",
			},
		},
	}

	assert(GeodeState.migrateLegacyQueue(migrated) == true, "legacy queue entries should migrate into owned geodes")
	assert(migrated.geodesById.legacy_geode ~= nil, "migrated geodes should be addressable by id")
	assert(migrated.geodesById.legacy_geode.geodeTypeId == "starter_geode", "migration should preserve the geode type")
	assert(#migrated.geodeOrder == 1 and migrated.geodeOrder[1] == "legacy_geode", "migration should preserve order")
end
