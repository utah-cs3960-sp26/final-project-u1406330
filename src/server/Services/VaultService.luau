--!strict

-- Server-authoritative service for Vault Service that validates requests and mutates gameplay state for this system.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Geodes = require(Shared.Config.Geodes)
local Resources = require(Shared.Config.Resources)
local Traits = require(Shared.Config.Traits)
local GeodeState = require(Shared.Domain.GeodeState)
local SizeRules = require(Shared.Domain.SizeRules)
local VaultMath = require(Shared.Domain.VaultMath)

local VaultService = {}
VaultService.__index = VaultService

local function removeFromOrder(order, id)
	-- Orders are stored as arrays for stable UI/world presentation, so removals have to
	-- preserve relative order instead of rebuilding the whole list from a dictionary.
	for index = #order, 1, -1 do
		if order[index] == id then
			table.remove(order, index)
			return
		end
	end
end

local function adjustGeodeInventory(profile, geodeTypeId, delta)
	local current = profile.inventory.geodes[geodeTypeId] or 0
	profile.inventory.geodes[geodeTypeId] = math.max(0, current + delta)
end

function VaultService.new(dependencies)
	return setmetatable({
		dependencies = dependencies or {},
	}, VaultService)
end

function VaultService:getResourceSellValue(resource)
	local resourceDefinition = resource ~= nil and Resources[resource.resourceTypeId] or nil
	local traitDefinition = resource ~= nil and Traits[resource.traitId or "none"] or Traits.none
	local sizeDefinition = if resource ~= nil then SizeRules.resolveDefinition(resource.sizeId, resource.sizeValue) else nil
	return VaultMath.getResourceSellValue(resourceDefinition, traitDefinition, sizeDefinition)
end

function VaultService:getGeodeSellValue(geode)
	local geodeDefinition = geode ~= nil and Geodes[geode.geodeTypeId] or nil
	return VaultMath.getGeodeSellValue(geodeDefinition)
end

function VaultService:placeResource(userId, resourceId, x, y)
	local playerData = self.dependencies.playerData
	local placementService = self.dependencies.placementService
	if placementService == nil then
		return nil, "placement_unavailable"
	end

	local result
	local _, mutateError = playerData:mutateProfile(userId, function(currentProfile)
		local resource = currentProfile.resourcesById[resourceId]
		if resource == nil then
			return nil, "unknown_resource_instance"
		end

		if resource.stationId ~= nil then
			return nil, "resource_assigned_to_station"
		end

		local placedResource, placementOrReason = placementService:placeResource(currentProfile, resource, x, y)
		if placedResource == nil or placementOrReason == nil then
			return nil, placementOrReason or "resource_placement_failed"
		end

		result = {
			resource = placedResource,
			placement = placementOrReason,
		}
		return result
	end)

	if result ~= nil then
		playerData:notifyProfileChanged(userId)
	end

	if result == nil and mutateError ~= nil then
		return nil, mutateError
	end

	return result
end

function VaultService:pickupResource(userId, resourceId)
	local playerData = self.dependencies.playerData
	local placementService = self.dependencies.placementService
	if placementService == nil then
		return nil, "placement_unavailable"
	end

	local result
	local _, mutateError = playerData:mutateProfile(userId, function(currentProfile)
		local resource = currentProfile.resourcesById[resourceId]
		if resource == nil then
			return nil, "unknown_resource_instance"
		end

		if resource.stationId ~= nil then
			return nil, "resource_assigned_to_station"
		end

		if resource.placement == nil then
			return nil, "resource_not_placed"
		end

		-- Vault pickup is authoritative on the server because the plot footprint has to be
		-- cleared in lockstep with the resource's placement field to avoid ghost occupancy.
		local removed, removeReason = placementService:removeObjectByObjectId(currentProfile, "resource", resource.id)
		if not removed then
			return nil, removeReason or "resource_pickup_failed"
		end

		result = {
			resource = resource,
		}
		return result
	end)

	if result ~= nil then
		playerData:notifyProfileChanged(userId)
	end

	if result == nil and mutateError ~= nil then
		return nil, mutateError
	end

	return result
end

function VaultService:sellResource(userId, resourceId)
	local playerData = self.dependencies.playerData
	local placementService = self.dependencies.placementService

	local result
	local _, mutateError = playerData:mutateProfile(userId, function(currentProfile)
		local resource = currentProfile.resourcesById[resourceId]
		if resource == nil then
			return nil, "unknown_resource_instance"
		end

		local sellValue = self:getResourceSellValue(resource)
		if sellValue <= 0 then
			return nil, "resource_not_sellable"
		end

		if resource.stationId ~= nil then
			local station = currentProfile.stationsById[resource.stationId]
			if station ~= nil and station.occupantIds ~= nil then
				-- Selling a station occupant must clear the station order as well as the vault copy,
				-- otherwise passive-income state would still point at a deleted resource id.
				removeFromOrder(station.occupantIds, resource.id)
			end
		end

		if placementService ~= nil then
			-- World placement is derived from profile state, so the placement footprint has to be
			-- cleared before the resource is removed from the authoritative profile tables.
			placementService:removeObjectByObjectId(currentProfile, "resource", resource.id)
		end

		currentProfile.resourcesById[resource.id] = nil
		removeFromOrder(currentProfile.resourceOrder, resource.id)
		currentProfile.currencies.coins += sellValue

		result = {
			resourceId = resource.id,
			coins = sellValue,
		}
		return result
	end)

	if result ~= nil then
		playerData:notifyProfileChanged(userId)
	end

	if result == nil and mutateError ~= nil then
		return nil, mutateError
	end

	return result
end

function VaultService:sellGeode(userId, geodeInstanceId)
	local playerData = self.dependencies.playerData
	local placementService = self.dependencies.placementService

	local result
	local _, mutateError = playerData:mutateProfile(userId, function(currentProfile)
		local geode = currentProfile.geodesById[geodeInstanceId]
		if geode == nil then
			return nil, "unknown_geode_instance"
		end

		local sellValue = self:getGeodeSellValue(geode)
		if sellValue <= 0 then
			return nil, "geode_not_sellable"
		end

		if placementService ~= nil then
			-- Selling a placed geode must clear its occupied cells before the geode leaves
			-- profile state, otherwise later placement checks would think the plot is blocked.
			placementService:removeObjectByObjectId(currentProfile, "geode", geode.id)
		end

		adjustGeodeInventory(currentProfile, geode.geodeTypeId, -1)
		GeodeState.removeGeode(currentProfile.geodesById, currentProfile.geodeOrder, geode.id)
		currentProfile.currencies.coins += sellValue

		result = {
			geodeInstanceId = geode.id,
			coins = sellValue,
		}
		return result
	end)

	if result ~= nil then
		playerData:notifyProfileChanged(userId)
	end

	if result == nil and mutateError ~= nil then
		return nil, mutateError
	end

	return result
end

function VaultService:start()
	print("[GemFactory] VaultService ready")
end

return VaultService
