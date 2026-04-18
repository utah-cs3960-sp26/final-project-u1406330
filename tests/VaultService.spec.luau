--!strict

-- Spec coverage for Vault Service to keep deterministic gameplay behavior and regressions easy to verify.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Server = ServerScriptService:WaitForChild("Server")

local PlayerProfile = require(Shared.Types.PlayerProfile)
local GeodeState = require(Shared.Domain.GeodeState)
local SizeRules = require(Shared.Domain.SizeRules)
local PlacementService = require(Server.Services.PlacementService)
local VaultService = require(Server.Services.VaultService)

return function()
	local profile = PlayerProfile.new(100)
	profile.plotState.plotId = "plot_1"

	local geode = GeodeState.createInstance("geode_a", "starter_geode", 100, 10, "huge", 1.52)
	profile.geodesById[geode.id] = geode
	table.insert(profile.geodeOrder, geode.id)
	profile.inventory.geodes.starter_geode = 1

	profile.resourcesById.resource_a = {
		id = "resource_a",
		resourceTypeId = "quartz",
		traitId = "none",
		sizeId = "huge",
		sizeValue = 1.52,
		level = 1,
		stationId = nil,
		obtainedAt = 100,
		placement = nil,
	}
	table.insert(profile.resourceOrder, "resource_a")

	local playerData = {
		mutateProfile = function(_, _, mutator)
			return mutator(profile)
		end,
		notifyProfileChanged = function() end,
	}
	local service = VaultService.new({
		playerData = playerData,
		placementService = PlacementService.new({}),
	})

	local placedResource = service:placeResource(1, "resource_a", 1, 1)
	assert(placedResource ~= nil, "unplaced resources should be placeable from the vault")
	assert(profile.resourcesById.resource_a.placement ~= nil, "resource placement should be recorded on the resource")
	assert(next(profile.placedObjects) ~= nil, "resource placement should occupy the plot grid")

	local duplicatePlace, duplicateError = service:placeResource(1, "resource_a", 2, 2)
	assert(duplicatePlace == nil and duplicateError == "resource_already_placed", "placed resources should not place twice")

	local stationedResource = {
		id = "resource_b",
		resourceTypeId = "amethyst",
		traitId = "none",
		sizeId = "tiny",
		sizeValue = SizeRules.getScaleValue("tiny", nil),
		level = 1,
		stationId = "station_a",
		obtainedAt = 100,
		placement = nil,
	}
	profile.resourcesById.resource_b = stationedResource
	table.insert(profile.resourceOrder, "resource_b")
	local stationedPlace, stationedError = service:placeResource(1, "resource_b", 2, 2)
	assert(stationedPlace == nil and stationedError == "resource_assigned_to_station", "stationed resources should stay station-owned")

	local soldGeode = service:sellGeode(1, "geode_a")
	assert(soldGeode ~= nil, "stored geodes should be sellable")
	assert(profile.geodesById.geode_a == nil, "selling a geode should remove it from owned geodes")
	assert(profile.inventory.geodes.starter_geode == 0, "selling a geode should update vault counts")
	assert(profile.currencies.coins == 280, "selling a starter geode should award configured coins")

	assert(service:getResourceSellValue(profile.resourcesById.resource_a) == 43, "resource sell previews should include resolved size categories")
	local soldResource = service:sellResource(1, "resource_a")
	assert(soldResource ~= nil, "placed resources should be sellable")
	assert(profile.resourcesById.resource_a == nil, "selling a resource should remove it from owned resources")
	assert(profile.currencies.coins == 323, "selling quartz should award configured coins including size")
end
