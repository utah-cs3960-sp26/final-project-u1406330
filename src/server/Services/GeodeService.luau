--!strict

-- Server-authoritative service for Geode Service that validates requests and mutates gameplay state for this system.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Resources = require(Shared.Config.Resources)
local Geodes = require(Shared.Config.Geodes)
local Traits = require(Shared.Config.Traits)
local GeodeState = require(Shared.Domain.GeodeState)
local GeodeRoller = require(Shared.Domain.GeodeRoller)
local TraitRoller = require(Shared.Domain.TraitRoller)
local Sizes = require(Shared.Config.Sizes)
local SizeRoller = require(Shared.Domain.SizeRoller)
local SizeRules = require(Shared.Domain.SizeRules)
local Id = require(Shared.Util.Id)
local Time = require(Shared.Util.Time)

local GeodeService = {}
GeodeService.__index = GeodeService

local function getTraitPool()
	return Traits.order or {
		Traits.none,
		Traits.fiery,
		Traits.frosted,
		Traits.verdant,
		Traits.radiant,
		Traits.prismatic,
		Traits.celestial,
		Traits.void_touched,
		Traits.starlit,
		Traits.cosmic,
		Traits.singularity,
	}
end

local function getSizePool()
	return Sizes.order
end

local function getCurrencyAmount(profile, currency)
	if currency == "coins" then
		return profile.currencies.coins
	elseif currency == "gems" then
		return profile.currencies.gems
	elseif currency == "eventTokens" then
		return profile.currencies.eventTokens
	end

	return nil
end

local function spendCurrency(profile, currency, amount)
	if amount <= 0 then
		return true
	end

	if currency == "coins" then
		if profile.currencies.coins < amount then
			return false, "insufficient_coins"
		end
		profile.currencies.coins -= amount
		return true
	elseif currency == "gems" then
		if profile.currencies.gems < amount then
			return false, "insufficient_gems"
		end
		profile.currencies.gems -= amount
		return true
	elseif currency == "eventTokens" then
		if profile.currencies.eventTokens < amount then
			return false, "insufficient_tokens"
		end
		profile.currencies.eventTokens -= amount
		return true
	end

	return false, "unsupported_currency"
end

local function adjustInventoryCount(profile, geodeId, delta)
	local inventory = profile.inventory
	local currentCount = inventory.geodes[geodeId] or 0
	local nextCount = math.max(0, currentCount + delta)
	inventory.geodes[geodeId] = nextCount
	return nextCount
end

function GeodeService.new(dependencies)
	return setmetatable({
		dependencies = dependencies or {},
	}, GeodeService)
end

function GeodeService:getDefinition(geodeId)
	return Geodes[geodeId]
end

function GeodeService:adjustInventoryCount(profile, geodeId, delta)
	return adjustInventoryCount(profile, geodeId, delta)
end

function GeodeService:createGeodeInstance(profile, geodeId, nowUnix, rng)
	local geodeDefinition = Geodes[geodeId]
	if geodeDefinition == nil then
		return nil, "unknown_geode"
	end

	local sizeRoll = SizeRoller.rollSize(getSizePool(), rng)
	local sizeId = sizeRoll and sizeRoll.id or "medium"
	local sizeValue = SizeRules.getScaleValue(sizeId, if sizeRoll ~= nil then sizeRoll.scaleValue else nil)
	local geodeInstance = GeodeState.createInstance(Id.new("geode"), geodeId, nowUnix, geodeDefinition.geodeSeconds, sizeId, sizeValue)
	profile.geodesById[geodeInstance.id] = geodeInstance
	table.insert(profile.geodeOrder, geodeInstance.id)
	adjustInventoryCount(profile, geodeId, 1)
	return geodeInstance
end

function GeodeService:buyGeode(userId, geodeId, nowUnix, rng)
	local playerData = self.dependencies.playerData
	local shopService = self.dependencies.shopService
	local profile = playerData:getOrLoadProfile(userId)
	if profile == nil then
		return nil, "profile_not_loaded"
	end

	local geodeDefinition = Geodes[geodeId]
	if geodeDefinition == nil then
		return nil, "unknown_geode"
	end

	local offer = shopService:getOffer(geodeId, nowUnix)
	if offer == nil then
		return nil, "offer_unavailable"
	end

	local balance = getCurrencyAmount(profile, offer.currency)
	if balance == nil then
		return nil, "unsupported_currency"
	end

	if balance < offer.price then
		return nil, "insufficient_funds"
	end

	local result
	local _, mutateError = playerData:mutateProfile(userId, function(currentProfile)
		local spent, spendError = spendCurrency(currentProfile, offer.currency, offer.price)
		if not spent then
			return nil, spendError
		end

		local geodeInstance, geodeError = self:createGeodeInstance(currentProfile, geodeId, nowUnix)
		if geodeInstance == nil then
			return nil, geodeError
		end

		result = {
			offer = offer,
			geodeEntry = GeodeState.toQueueEntry(geodeInstance, nowUnix),
			geodeInstance = geodeInstance,
			inventoryCount = currentProfile.inventory.geodes[geodeId] or 0,
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

function GeodeService:placeGeode(userId, geodeInstanceId, x, y)
	local playerData = self.dependencies.playerData
	local placementService = self.dependencies.placementService
	if placementService == nil then
		return nil, "placement_unavailable"
	end

	local result
	local _, mutateError = playerData:mutateProfile(userId, function(currentProfile)
		local geodeInstance = currentProfile.geodesById[geodeInstanceId]
		if geodeInstance == nil then
			return nil, "unknown_geode_instance"
		end

		local placedGeode, placementOrReason = placementService:placeGeode(currentProfile, geodeInstance, x, y)
		if placedGeode == nil or placementOrReason == nil then
			return nil, placementOrReason or "geode_placement_failed"
		end

		adjustInventoryCount(currentProfile, geodeInstance.geodeTypeId, -1)

		result = {
			geodeInstance = placedGeode,
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

function GeodeService:openGeode(userId, geodeInstanceId, nowUnix, rng, playerName)
	local playerData = self.dependencies.playerData
	local geodeQueueService = self.dependencies.geodeQueueService
	if geodeQueueService == nil then
		return nil, "open_unavailable"
	end

	local result
	local _, mutateError = playerData:mutateProfile(userId, function(currentProfile)
		result = geodeQueueService:openGeode(currentProfile, nowUnix, rng, geodeInstanceId, playerName)
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

function GeodeService:createResourceInstance(geodeId, nowUnix, rng, sizeId, sizeValue)
	local geodeDefinition = Geodes[geodeId]
	if geodeDefinition == nil then
		return nil, "unknown_geode"
	end

	local resourceRoll = GeodeRoller.rollGeode(geodeDefinition, rng)
	if resourceRoll == nil then
		return nil, "invalid_roll"
	end

	local traitRoll = TraitRoller.rollTrait(getTraitPool(), rng)
	local resourceDefinition = Resources[resourceRoll.resourceId]
	if resourceDefinition == nil then
		return nil, "unknown_resource"
	end

	return {
		id = Id.new("resource"),
		resourceTypeId = resourceDefinition.id,
		traitId = traitRoll and traitRoll.id or "none",
		sizeId = sizeId or "medium",
		sizeValue = SizeRules.getScaleValue(sizeId, sizeValue),
		level = 1,
		stationId = nil,
		obtainedAt = nowUnix,
		placement = nil,
	}
end

function GeodeService:createRewardResourceInstance(resourceId, nowUnix)
	local resourceDefinition = Resources[resourceId]
	if resourceDefinition == nil then
		return nil, "unknown_resource"
	end

	return {
		id = Id.new("resource"),
		resourceTypeId = resourceDefinition.id,
		traitId = "none",
		sizeId = "medium",
		sizeValue = SizeRules.getScaleValue("medium", nil),
		level = 1,
		stationId = nil,
		obtainedAt = nowUnix,
		placement = nil,
	}
end

function GeodeService:resolveGeode(geodeId, rng)
	return self:createResourceInstance(geodeId, Time.nowUnix(), rng)
end

function GeodeService:start()
	print("[GemFactory] GeodeService ready")
end

return GeodeService


