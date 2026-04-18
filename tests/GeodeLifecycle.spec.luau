--!strict

-- Spec coverage for Geode Lifecycle to keep deterministic gameplay behavior and regressions easy to verify.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Server = ServerScriptService:WaitForChild("Server")

local PlayerProfile = require(Shared.Types.PlayerProfile)

local PlacementService = require(Server.Services.PlacementService)
local GeodeService = require(Server.Services.GeodeService)
local GeodeQueueService = require(Server.Services.GeodeQueueService)

return function()
	local profile = PlayerProfile.new(100)
	profile.plotState.plotId = "plot_1"

	local placementService = PlacementService.new({})
	local playerData = {
		getOrLoadProfile = function()
			return profile
		end,
		mutateProfile = function(_, _, mutator)
			return mutator(profile)
		end,
		notifyProfileChanged = function() end,
	}
	local shopService = {
		getOffer = function(_, offerId)
			return {
				offerId = offerId,
				price = 50,
				currency = "coins",
			}
		end,
	}
	local geodeService = GeodeService.new({
		playerData = playerData,
		shopService = shopService,
		placementService = placementService,
	})
	local geodeQueueService = GeodeQueueService.new({
		geodeService = geodeService,
		placementService = placementService,
		stationService = {
			autoAssignResources = function(_, _, resourceIds)
				return {
					assignedResourceIds = {},
					unassignedResourceIds = resourceIds,
				}
			end,
		},
	})
	geodeService.dependencies.geodeQueueService = geodeQueueService

	local purchase = geodeService:buyGeode(1, "starter_geode", 100, Random.new(7))
	assert(purchase ~= nil, "buying a geode should succeed with a valid offer and balance")
	assert(#profile.geodeOrder == 1, "buying a geode should create owned geode state")
	assert(profile.inventory.geodes.starter_geode == 1, "buying a geode should put it into inventory")
	assert(purchase.inventoryCount == 1, "purchase response should reflect the updated inventory count")

	local geodeInstanceId = profile.geodeOrder[1]
	local geodeInstance = profile.geodesById[geodeInstanceId]
	assert(geodeInstance ~= nil, "owned geode state should be addressable by id")
	assert(geodeInstance.placement == nil, "bought geodes should stay stored until the player places them")

	local queueState = geodeQueueService:getQueueState(profile, 105)
	assert(queueState.queuedCount == 1, "stored geodes should still tick down in the queue")
	assert(queueState.entries[1].isPlaced == false, "unplaced geodes should stay in inventory instead of appearing on the plot")

	local placedResult = geodeService:placeGeode(1, geodeInstanceId, nil, nil)
	assert(placedResult ~= nil, "owned geodes should be placeable explicitly")
	assert(placedResult.placement ~= nil, "placing a geode should create a grid placement")
	assert(geodeInstance.placement ~= nil, "placing a geode should update the owned geode record")
	assert(profile.inventory.geodes.starter_geode == 0, "placing a geode should remove it from stored inventory counts")

	queueState = geodeQueueService:getQueueState(profile, 105)
	assert(queueState.entries[1].isPlaced == true, "queue state should expose explicitly placed geodes")

	local tooEarlyResult, tooEarlyError = geodeService:openGeode(1, geodeInstanceId, 105, Random.new(7), "Tester")
	assert(tooEarlyResult == nil and tooEarlyError == "no_ready_geodes", "unfinished geodes should not open before the timer ends")

	local openResult = geodeService:openGeode(1, geodeInstanceId, 111, Random.new(7), "Tester")
	assert(openResult ~= nil, "finished placed geodes should be openable")
	assert(#openResult.createdResourceIds == 1, "opening a geode should create exactly one resource in the MVP")
	assert(profile.geodesById[geodeInstanceId] == nil, "opened geodes should be removed from owned state")
	assert(#profile.geodeOrder == 0, "opened geodes should be removed from order")
	assert(profile.inventory.geodes.starter_geode == 0, "opening a geode should not re-add it to stored inventory counts")
	assert(#profile.resourceOrder == 1, "opening a geode should grant a resource")
	assert(next(profile.placedObjects) == nil, "opening a geode should clear its placement footprint")
end
