--!strict

local StationAssignment = {}

local function getPlacementRecord(profile, stationId)
	for _, placement in pairs(profile.placedObjects) do
		if placement.objectType == "station" and placement.objectId == stationId then
			return placement
		end
	end

	return nil
end

local function compareStationOrder(left, right)
	if left.y ~= right.y then
		return left.y < right.y
	end

	if left.x ~= right.x then
		return left.x < right.x
	end

	return left.stationId < right.stationId
end

function StationAssignment.getPlacedStationOrder(profile)
	local ordered = {}

	for stationId, station in pairs(profile.stationsById) do
		if station.placement ~= nil then
			local placement = getPlacementRecord(profile, stationId) or station.placement
			table.insert(ordered, {
				stationId = stationId,
				x = placement.x,
				y = placement.y,
			})
		end
	end

	table.sort(ordered, compareStationOrder)
	return ordered
end

function StationAssignment.getAvailableStationId(profile, stationDefinitions)
	for _, entry in ipairs(StationAssignment.getPlacedStationOrder(profile)) do
		local station = profile.stationsById[entry.stationId]
		local stationDefinition = station and stationDefinitions[station.stationTypeId] or nil
		if station ~= nil and stationDefinition ~= nil and #station.occupantIds < stationDefinition.capacity then
			return station.id
		end
	end

	return nil, "no_station_capacity"
end

function StationAssignment.assignResourceToStation(profile, stationDefinitions, resourceId, stationId)
	local resource = profile.resourcesById[resourceId]
	if resource == nil then
		return false, "resource_not_found"
	end

	if resource.placement ~= nil then
		return false, "resource_already_placed"
	end

	local station = profile.stationsById[stationId]
	if station == nil then
		return false, "station_not_found"
	end

	if station.placement == nil then
		return false, "station_not_placed"
	end

	local stationDefinition = stationDefinitions[station.stationTypeId]
	if stationDefinition == nil then
		return false, "station_definition_missing"
	end

	if resource.stationId == stationId then
		return true
	end

	if #station.occupantIds >= stationDefinition.capacity then
		return false, "station_full"
	end

	if resource.stationId ~= nil then
		local previousStation = profile.stationsById[resource.stationId]
		if previousStation ~= nil then
			for index, occupantId in ipairs(previousStation.occupantIds) do
				if occupantId == resourceId then
					table.remove(previousStation.occupantIds, index)
					break
				end
			end
		end
	end

	resource.stationId = stationId
	table.insert(station.occupantIds, resourceId)
	return true
end

function StationAssignment.autoAssignResources(profile, stationDefinitions, resourceIds)
	local assignedResourceIds = {}
	local unassignedResourceIds = {}

	for _, resourceId in ipairs(resourceIds) do
		local stationId = StationAssignment.getAvailableStationId(profile, stationDefinitions)
		if stationId == nil then
			table.insert(unassignedResourceIds, resourceId)
		else
			local assigned = StationAssignment.assignResourceToStation(profile, stationDefinitions, resourceId, stationId)
			if assigned then
				table.insert(assignedResourceIds, resourceId)
			else
				table.insert(unassignedResourceIds, resourceId)
			end
		end
	end

	return {
		assignedResourceIds = assignedResourceIds,
		unassignedResourceIds = unassignedResourceIds,
	}
end

return StationAssignment
