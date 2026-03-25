--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local StationAssignment = require(Shared.Domain.StationAssignment)

return function()
	local stationDefinitions = {
		starter = {
			id = "starter",
			capacity = 2,
		},
		overflow = {
			id = "overflow",
			capacity = 1,
		},
	}

	local profile = {
		resourcesById = {
			resource_a = { id = "resource_a", stationId = nil },
			resource_b = { id = "resource_b", stationId = nil },
			resource_c = { id = "resource_c", stationId = nil },
		},
		stationsById = {
			station_b = {
				id = "station_b",
				stationTypeId = "overflow",
				occupantIds = {},
				placement = { x = 3, y = 1, width = 1, height = 1 },
			},
			station_a = {
				id = "station_a",
				stationTypeId = "starter",
				occupantIds = {},
				placement = { x = 1, y = 1, width = 1, height = 1 },
			},
		},
		placedObjects = {
			placement_b = {
				objectType = "station",
				objectId = "station_b",
				x = 3,
				y = 1,
			},
			placement_a = {
				objectType = "station",
				objectId = "station_a",
				x = 1,
				y = 1,
			},
		},
	}

	local order = StationAssignment.getPlacedStationOrder(profile)
	local firstStationId = StationAssignment.getAvailableStationId(profile, stationDefinitions)
	local assignment = StationAssignment.autoAssignResources(profile, stationDefinitions, { "resource_a", "resource_b", "resource_c" })
	local reassignSuccess = StationAssignment.assignResourceToStation(profile, stationDefinitions, "resource_c", "station_a")
	local noCapacityStationId, noCapacityReason = StationAssignment.getAvailableStationId(profile, stationDefinitions)

	assert(order[1].stationId == "station_a", "station order should follow placement coordinates")
	assert(firstStationId == "station_a", "first available station should respect placement order")
	assert(#assignment.assignedResourceIds == 3, "all resources should assign while capacity remains")
	assert(profile.resourcesById.resource_a.stationId == "station_a", "resources should slot into the first station first")
	assert(profile.resourcesById.resource_b.stationId == "station_a", "resources should fill station capacity before moving on")
	assert(reassignSuccess == false, "reassigning into a full station should fail cleanly")
	assert(profile.resourcesById.resource_c.stationId == "station_b", "resources should overflow into the next station")
	assert(#profile.stationsById.station_a.occupantIds == 2, "first station should contain the expected occupants")
	assert(#profile.stationsById.station_b.occupantIds == 1, "second station should contain the overflow occupant")
	assert(noCapacityStationId == nil and noCapacityReason == "no_station_capacity", "full stations should report no remaining capacity")
end
