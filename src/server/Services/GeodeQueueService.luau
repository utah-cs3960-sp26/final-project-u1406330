--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

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

function GeodeQueueService:getClaimableEntries(profile, nowUnix, geodeId)
	local claimable = {}

	for _, entry in ipairs(profile.geodeQueue) do
		local isFinished = entry.status == "finished" or (entry.status == "queued" and entry.endsAt <= nowUnix)
		if isFinished then
			entry.status = "finished"
			if geodeId == nil or entry.id == geodeId then
				table.insert(claimable, entry)
			end
		end
	end

	return claimable
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
	local queuedCount = 0
	local finishedCount = 0
	local nextReadyUnix = nil
	local entries = {}

	for _, entry in ipairs(profile.geodeQueue) do
		local remaining = self:timeRemaining(entry, nowUnix)
		local entryState = {
			id = entry.id,
			geodeId = entry.geodeId,
			status = entry.status,
			remainingSeconds = remaining,
			endsAt = entry.endsAt,
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
	local rareAnnouncementService = self.dependencies.rareAnnouncementService
	local createdResources = {}
	local createdResourceIds = {}
	local claimableIds = {}

	for _, entry in ipairs(claimableEntries) do
		claimableIds[entry.id] = true
	end

	local remainingEntries = {}
	for _, entry in ipairs(profile.geodeQueue) do
		if claimableIds[entry.id] then
			local resource, errorCode = geodeService:createResourceInstance(entry.geodeId, nowUnix, rng)
			if resource ~= nil then
				profile.resourcesById[resource.id] = resource
				table.insert(profile.resourceOrder, resource.id)
				table.insert(createdResources, resource)
				table.insert(createdResourceIds, resource.id)
				if rareAnnouncementService ~= nil and shouldAnnounceResource(resource) then
					local resourceDefinition = Resources[resource.resourceTypeId]
					rareAnnouncementService:announce(
						playerName or "Miner",
						resourceDefinition and resourceDefinition.displayName or resource.resourceTypeId,
						getTraitLabel(resource.traitId)
					)
				end
			else
				warn("[GemFactory] Failed to resolve geode", entry.geodeId, errorCode)
				table.insert(remainingEntries, entry)
			end
		else
			table.insert(remainingEntries, entry)
		end
	end

	local stationService = self.dependencies.stationService
	local autoAssignment = nil
	if stationService ~= nil and #createdResourceIds > 0 then
		autoAssignment = stationService:autoAssignResources(profile, createdResourceIds)
	end

	profile.geodeQueue = remainingEntries

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


