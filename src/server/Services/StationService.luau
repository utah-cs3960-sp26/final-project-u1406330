--!strict

-- Server-authoritative service for Station Service that validates requests and mutates gameplay state for this system.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Stations = require(Shared.Config.Stations)
local StationAssignment = require(Shared.Domain.StationAssignment)
local World = require(Shared.Config.World)
local Id = require(Shared.Util.Id)

local StationService = {}
StationService.__index = StationService

function StationService.new(dependencies)
	return setmetatable({
		dependencies = dependencies or {},
	}, StationService)
end

function StationService:getDefinition(stationTypeId)
	return Stations[stationTypeId]
end

function StationService:getStarterStationTypeId()
	return World.starterStationTypeId
end

function StationService:getStarterStation(profile)
	for _, station in pairs(profile.stationsById) do
		if station.stationTypeId == self:getStarterStationTypeId() then
			return station
		end
	end

	return nil
end

function StationService:createStationInstance(stationTypeId)
	local stationDefinition = self:getDefinition(stationTypeId)
	if stationDefinition == nil then
		return nil, "unknown_station"
	end

	return {
		id = Id.new("station"),
		stationTypeId = stationTypeId,
		level = 1,
		occupantIds = {},
		placement = nil,
	}, nil
end

function StationService:grantStarterStation(profile)
	local existingStarter = self:getStarterStation(profile)
	if existingStarter ~= nil then
		return existingStarter
	end

	local starterTypeId = self:getStarterStationTypeId()
	local station = self:createStationInstance(starterTypeId)
	if station == nil then
		return nil, "starter_station_missing"
	end

	profile.stationsById[station.id] = station
	return station
end

function StationService:ensureStarterStation(profile)
	return self:grantStarterStation(profile)
end

function StationService:autoAssignResources(profile, resourceIds)
	return StationAssignment.autoAssignResources(profile, Stations, resourceIds)
end

function StationService:assignResource(profile, resourceId, stationId)
	return StationAssignment.assignResourceToStation(profile, Stations, resourceId, stationId)
end

function StationService:getTemplate(stationTypeId)
	return self:getDefinition(stationTypeId)
end

function StationService:start()
	print("[GemFactory] StationService ready")
end

return StationService

