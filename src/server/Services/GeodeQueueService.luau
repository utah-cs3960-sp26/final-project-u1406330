--!strict

-- Server-authoritative service for Geode Queue Service that validates requests and mutates gameplay state for this system.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local GeodeState = require(Shared.Domain.GeodeState)
local Resources = require(Shared.Config.Resources)
local Traits = require(Shared.Config.Traits)

local GeodeQueueService = {}
GeodeQueueService.__index = GeodeQueueService

function GeodeQueueService.new(dependencies)
	return setmetatable({
		dependencies = dependencies or {},
	}, GeodeQueueService)
end

function GeodeQueueService:timeRemaining(entry, nowUnix)
	return math.max(0, entry.endsAt - nowUnix)
end

function GeodeQueueService:syncQueueCache(profile, nowUnix)
	GeodeState.refreshStatuses(profile.geodesById, profile.geodeOrder, nowUnix)
	profile.geodeQueue = GeodeState.buildQueueEntries(profile.geodesById, profile.geodeOrder, nowUnix)
	return profile.geodeQueue
end

function GeodeQueueService:getClaimableEntries(profile, nowUnix, geodeId)
	self:syncQueueCache(profile, nowUnix)

	local claimable = {}
	for _, geodeInstanceId in ipairs(GeodeState.getClaimableIds(profile, nowUnix, geodeId)) do
		local geodeInstance = profile.geodesById[geodeInstanceId]
		if geodeInstance ~= nil then
			table.insert(claimable, GeodeState.toQueueEntry(geodeInstance, nowUnix))
		end
	end

	return claimable
end

function GeodeQueueService:openGeode(profile, nowUnix, rng, geodeId, playerName)
	return self:claimEntries(profile, nowUnix, rng, geodeId, playerName)
end

local function shouldAnnounceResource(resource)
	local resourceDefinition = Resources[resource.resourceTypeId]
	if resourceDefinition == nil then
		return false
	end

	if resource.traitId ~= nil and resource.traitId ~= "none" then
		return true
	end

	local rarity = resourceDefinition.rarity
	return rarity == "Rare" or rarity == "Epic" or rarity == "Legendary"
end

local function getTraitLabel(traitId)
	if traitId == nil then
		return "none"
	end

	local traitDefinition = Traits[traitId]
	if traitDefinition ~= nil then
		return traitDefinition.displayName
	end

	return traitId
end

function GeodeQueueService:getQueueState(profile, nowUnix)
	local queueEntries = self:syncQueueCache(profile, nowUnix)
	local queuedCount = 0
	local finishedCount = 0
	local nextReadyUnix = nil
	local entries = {}

	for _, entry in ipairs(queueEntries) do
		local remaining = self:timeRemaining(entry, nowUnix)
		local entryState = {
			id = entry.id,
			geodeId = entry.geodeId,
			status = entry.status,
			remainingSeconds = remaining,
			endsAt = entry.endsAt,
			isPlaced = profile.geodesById[entry.id] ~= nil and profile.geodesById[entry.id].placement ~= nil,
		}

		table.insert(entries, entryState)

		if entry.status == "finished" then
			finishedCount += 1
		elseif remaining > 0 then
			queuedCount += 1
			if nextReadyUnix == nil or entry.endsAt < nextReadyUnix then
				nextReadyUnix = entry.endsAt
			end
		else
			finishedCount += 1
		end
	end

	return {
		queuedCount = queuedCount,
		finishedCount = finishedCount,
		nextReadyUnix = nextReadyUnix,
		entries = entries,
	}
end

function GeodeQueueService:claimEntries(profile, nowUnix, rng, geodeId, playerName)
	local claimableEntries = self:getClaimableEntries(profile, nowUnix, geodeId)
	if #claimableEntries == 0 then
		return nil, "no_ready_geodes"
	end

	local geodeService = self.dependencies.geodeService
	local placementService = self.dependencies.placementService
	local rareAnnouncementService = self.dependencies.rareAnnouncementService
	if geodeService == nil then
		return nil, "open_unavailable"
	end
	local createdResources = {}
	local createdResourceIds = {}
	for _, entry in ipairs(claimableEntries) do
		local geodeInstance = profile.geodesById[entry.id]
		if geodeInstance ~= nil then
			local resource, errorCode = geodeService:createResourceInstance(
				geodeInstance.geodeTypeId,
				nowUnix,
				rng,
				geodeInstance.sizeId,
				geodeInstance.sizeValue
			)
			if resource ~= nil then
				profile.resourcesById[resource.id] = resource
				table.insert(profile.resourceOrder, resource.id)
				table.insert(createdResources, resource)
				table.insert(createdResourceIds, resource.id)
				if placementService ~= nil then
					placementService:removeObjectByObjectId(profile, "geode", geodeInstance.id)
				end
				GeodeState.removeGeode(profile.geodesById, profile.geodeOrder, geodeInstance.id)
				if rareAnnouncementService ~= nil and shouldAnnounceResource(resource) then
					local resourceDefinition = Resources[resource.resourceTypeId]
					rareAnnouncementService:announce(
						playerName or "Miner",
						resourceDefinition and resourceDefinition.displayName or resource.resourceTypeId,
						getTraitLabel(resource.traitId)
					)
				end
			else
				warn("[GemFactory] Failed to resolve geode", geodeInstance.geodeTypeId, errorCode)
			end
		end
	end

	local stationService = self.dependencies.stationService
	local autoAssignment = nil
	if stationService ~= nil and #createdResourceIds > 0 then
		autoAssignment = {
			assignedResourceIds = {},
			unassignedResourceIds = createdResourceIds,
		}
	end

	self:syncQueueCache(profile, nowUnix)

	return {
		claimedEntries = claimableEntries,
		createdResources = createdResources,
		createdResourceIds = createdResourceIds,
		autoAssignment = autoAssignment,
	}
end

function GeodeQueueService:start()
	print("[GemFactory] GeodeQueueService ready")
end

return GeodeQueueService

