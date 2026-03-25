--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Resources = require(Shared.Config.Resources)
local Geodes = require(Shared.Config.Geodes)
local Traits = require(Shared.Config.Traits)
local GeodeRoller = require(Shared.Domain.GeodeRoller)
local TraitRoller = require(Shared.Domain.TraitRoller)
local Id = require(Shared.Util.Id)
local Time = require(Shared.Util.Time)

local GeodeService = {}
GeodeService.__index = GeodeService

local function getTraitPool()
	return {
		Traits.none,
		Traits.flawless,
		Traits.prismatic,
		Traits.celestial,
		Traits.radiant,
		Traits.void_touched,
	}
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

function GeodeService.new(dependencies)
	return setmetatable({
		dependencies = dependencies or {},
	}, GeodeService)
end

function GeodeService:createGeodeEntry(profile, geodeId, nowUnix)
	local geodeDefinition = Geodes[geodeId]
	if geodeDefinition == nil then
		return nil, "unknown_geode"
	end

	local entry = {
		id = Id.new("geode"),
		geodeId = geodeId,
		startedAt = nowUnix,
		endsAt = nowUnix + geodeDefinition.geodeSeconds,
		status = "queued",
	}

	table.insert(profile.geodeQueue, entry)
	return entry
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

		local geodeEntry, geodeError = self:createGeodeEntry(currentProfile, geodeId, nowUnix)
		if geodeEntry == nil then
			return nil, geodeError
		end

		result = {
			offer = offer,
			geodeEntry = geodeEntry,
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

function GeodeService:createResourceInstance(geodeId, nowUnix, rng)
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
		level = 1,
		stationId = nil,
		obtainedAt = nowUnix,
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
		level = 1,
		stationId = nil,
		obtainedAt = nowUnix,
	}
end

function GeodeService:resolveGeode(geodeId, rng)
	return self:createResourceInstance(geodeId, Time.nowUnix(), rng)
end

function GeodeService:start()
	print("[GemFactory] GeodeService ready")
end

return GeodeService



