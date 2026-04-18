--!strict

-- Server-authoritative service for Placement Service that validates requests and mutates gameplay state for this system.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Geodes = require(Shared.Config.Geodes)
local Resources = require(Shared.Config.Resources)
local World = require(Shared.Config.World)
local PlacementRules = require(Shared.Domain.PlacementRules)
local Id = require(Shared.Util.Id)

local PlacementService = {}
PlacementService.__index = PlacementService

function PlacementService.new(dependencies)
	return setmetatable({
		dependencies = dependencies or {},
	}, PlacementService)
end

function PlacementService:canPlace(profile, x, y, width, height)
	if profile.plotState.plotId == nil then
		return false, "plot_unassigned"
	end

	return PlacementRules.canPlace({
		width = World.plotGridWidth,
		height = World.plotGridHeight,
		}, profile.plotState.gridOccupancy, x, y, width, height)
end

function PlacementService:findFirstOpenCell(profile, width, height)
	if profile.plotState.plotId == nil then
		return nil, "plot_unassigned"
	end

	return PlacementRules.findFirstPlacement({
		width = World.plotGridWidth,
		height = World.plotGridHeight,
	}, profile.plotState.gridOccupancy, width, height)
end

function PlacementService:place(profile, objectType, objectId, x, y, width, height)
	local canPlace, reason = self:canPlace(profile, x, y, width, height)
	if not canPlace then
		return nil, reason
	end

	local placementId = Id.new("placement")
	local record = {
		id = placementId,
		plotId = profile.plotState.plotId,
		objectType = objectType,
		objectId = objectId,
		x = x,
		y = y,
		width = width,
		height = height,
	}

	profile.placedObjects[placementId] = record

	for dx = 0, width - 1 do
		for dy = 0, height - 1 do
			local cellKey = PlacementRules.buildOccupancyKey(x + dx, y + dy)
			profile.plotState.gridOccupancy[cellKey] = placementId
		end
	end

	return record
end

function PlacementService:placeStation(profile, stationTypeId, x, y)
	local stationService = self.dependencies.stationService
	local stationDefinition = stationService and stationService:getDefinition(stationTypeId) or nil

	if stationDefinition == nil then
		return nil, "unknown_station"
	end

	local station = nil
	for _, existingStation in pairs(profile.stationsById) do
		if existingStation.stationTypeId == stationTypeId and existingStation.placement == nil then
			station = existingStation
			break
		end
	end

	if station == nil then
		if stationTypeId == (stationService and stationService:getStarterStationTypeId() or nil) then
			station = stationService and stationService:ensureStarterStation(profile) or nil
		else
			station = stationService and stationService:createStationInstance(stationTypeId) or nil
		end
	end

	if station == nil then
		return nil, "station_unavailable"
	end

	if station.placement ~= nil then
		return nil, "station_already_placed"
	end

	local targetX = x
	local targetY = y
	if targetX == nil or targetY == nil then
		local placementTarget, placementReason = self:findFirstOpenCell(
			profile,
			stationDefinition.gridSize.width,
			stationDefinition.gridSize.height
		)
		if placementTarget == nil then
			return nil, placementReason
		end

		targetX = placementTarget.x
		targetY = placementTarget.y
	end

	profile.stationsById[station.id] = station

	local placement, reason = self:place(
		profile,
		"station",
		station.id,
		targetX,
		targetY,
		stationDefinition.gridSize.width,
		stationDefinition.gridSize.height
	)
	if placement == nil then
		if stationTypeId ~= (stationService and stationService:getStarterStationTypeId() or nil) then
			profile.stationsById[station.id] = nil
		end
		return nil, reason
	end

	station.placement = {
		plotId = placement.plotId,
		x = placement.x,
		y = placement.y,
		width = placement.width,
		height = placement.height,
	}

	return station, placement
end

function PlacementService:placeGeode(profile, geodeInstance, x, y)
	local geodeDefinition = Geodes[geodeInstance.geodeTypeId]
	if geodeDefinition == nil then
		return nil, "unknown_geode"
	end

	if geodeInstance.placement ~= nil then
		return nil, "geode_already_placed"
	end

	local gridSize = geodeDefinition.gridSize or { width = 1, height = 1 }
	local targetX = x
	local targetY = y
	if targetX == nil or targetY == nil then
		local placementTarget, placementReason = self:findFirstOpenCell(profile, gridSize.width, gridSize.height)
		if placementTarget == nil then
			return nil, placementReason
		end

		targetX = placementTarget.x
		targetY = placementTarget.y
	end

	local placement, reason = self:place(profile, "geode", geodeInstance.id, targetX, targetY, gridSize.width, gridSize.height)
	if placement == nil then
		return nil, reason
	end

	geodeInstance.placement = {
		plotId = placement.plotId,
		x = placement.x,
		y = placement.y,
		width = placement.width,
		height = placement.height,
	}

	return geodeInstance, placement
end

function PlacementService:placeResource(profile, resourceInstance, x, y)
	local resourceDefinition = Resources[resourceInstance.resourceTypeId]
	if resourceDefinition == nil then
		return nil, "unknown_resource"
	end

	if resourceInstance.placement ~= nil then
		return nil, "resource_already_placed"
	end

	local gridSize = resourceDefinition.gridSize or { width = 1, height = 1 }
	local targetX = x
	local targetY = y
	if targetX == nil or targetY == nil then
		local placementTarget, placementReason = self:findFirstOpenCell(profile, gridSize.width, gridSize.height)
		if placementTarget == nil then
			return nil, placementReason
		end

		targetX = placementTarget.x
		targetY = placementTarget.y
	end

	local placement, reason = self:place(profile, "resource", resourceInstance.id, targetX, targetY, gridSize.width, gridSize.height)
	if placement == nil then
		return nil, reason
	end

	resourceInstance.placement = {
		plotId = placement.plotId,
		x = placement.x,
		y = placement.y,
		width = placement.width,
		height = placement.height,
	}

	return resourceInstance, placement
end

function PlacementService:removeObjectByObjectId(profile, objectType, objectId)
	for placementId, record in pairs(profile.placedObjects) do
		if record.objectType == objectType and record.objectId == objectId then
			return self:remove(profile, placementId)
		end
	end

	return false, "placement_not_found"
end

function PlacementService:remove(profile, placementId)
	local record = profile.placedObjects[placementId]
	if record == nil then
		return false, "placement_not_found"
	end

	PlacementRules.clearFootprint(profile.plotState.gridOccupancy, record)

	local station = profile.stationsById[record.objectId]
	if station ~= nil and station.placement ~= nil then
		station.placement = nil
	end

	local geodeInstance = profile.geodesById[record.objectId]
	if geodeInstance ~= nil and geodeInstance.placement ~= nil then
		geodeInstance.placement = nil
	end

	local resource = profile.resourcesById[record.objectId]
	if resource ~= nil and resource.placement ~= nil then
		resource.placement = nil
	end

	profile.placedObjects[placementId] = nil
	return true
end

function PlacementService:move(profile, placementId, x, y)
	local record = profile.placedObjects[placementId]
	if record == nil then
		return nil, "placement_not_found"
	end

	PlacementRules.clearFootprint(profile.plotState.gridOccupancy, record)

	local canPlace, reason = self:canPlace(profile, x, y, record.width, record.height)
	if not canPlace then
		for dx = 0, record.width - 1 do
			for dy = 0, record.height - 1 do
				local cellKey = PlacementRules.buildOccupancyKey(record.x + dx, record.y + dy)
				profile.plotState.gridOccupancy[cellKey] = placementId
			end
		end
		return nil, reason
	end

	record.x = x
	record.y = y

	local station = profile.stationsById[record.objectId]
	if station ~= nil and station.placement ~= nil then
		station.placement.x = x
		station.placement.y = y
	end

	local geodeInstance = profile.geodesById[record.objectId]
	if geodeInstance ~= nil and geodeInstance.placement ~= nil then
		geodeInstance.placement.x = x
		geodeInstance.placement.y = y
	end

	local resource = profile.resourcesById[record.objectId]
	if resource ~= nil and resource.placement ~= nil then
		resource.placement.x = x
		resource.placement.y = y
	end

	for dx = 0, record.width - 1 do
		for dy = 0, record.height - 1 do
			local cellKey = PlacementRules.buildOccupancyKey(x + dx, y + dy)
			profile.plotState.gridOccupancy[cellKey] = placementId
		end
	end

	return record
end

function PlacementService:start()
	print("[GemFactory] PlacementService ready")
end

return PlacementService

