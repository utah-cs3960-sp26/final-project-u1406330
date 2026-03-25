--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Resources = require(Shared.Config.Resources)
local EconomyConfig = require(Shared.Config.Economy)
local Stations = require(Shared.Config.Stations)
local Traits = require(Shared.Config.Traits)
local EconomyMath = require(Shared.Domain.EconomyMath)
local Time = require(Shared.Util.Time)

local EconomyService = {}
EconomyService.__index = EconomyService

function EconomyService.new(dependencies)
	return setmetatable({
		dependencies = dependencies or {},
	}, EconomyService)
end

function EconomyService:getPassiveRate(profile)
	local total = 0

	for _, resource in pairs(profile.resourcesById) do
		local resourceDefinition = Resources[resource.resourceTypeId]
		if resourceDefinition ~= nil and resource.stationId ~= nil then
			local traitDefinition = resource.traitId and Traits[resource.traitId] or Traits.none
			local stationInstance = resource.stationId and profile.stationsById[resource.stationId] or nil
			local stationDefinition = stationInstance and Stations[stationInstance.stationTypeId] or nil
			local stationMultiplier = stationDefinition and stationDefinition.incomeMultiplier or 1
			local traitMultiplier = traitDefinition and traitDefinition.multiplier or 1
			local prestigeMultiplier = EconomyMath.getPrestigeMultiplier(
				profile.progression.prestigeCount,
				EconomyConfig.prestigeStep,
				EconomyConfig.basePrestigeMultiplier
			)

			total += EconomyMath.getResourceIncome(resourceDefinition.baseCoinRate, traitMultiplier, stationMultiplier, prestigeMultiplier, 1)
		end
	end

	return total
end

function EconomyService:getCavernValue(profile)
	local resourceValue = 0
	local stationValue = 0

	for _, resource in pairs(profile.resourcesById) do
		local resourceDefinition = Resources[resource.resourceTypeId]
		if resourceDefinition ~= nil then
			resourceValue += resourceDefinition.baseCoinRate * 100
		end
	end

	for _, station in pairs(profile.stationsById) do
		local stationDefinition = Stations[station.stationTypeId]
		if stationDefinition ~= nil then
			stationValue += stationDefinition.capacity * 50
		end
	end

	return math.floor(profile.currencies.coins + (profile.currencies.gems * 100) + resourceValue + stationValue + (self:getPassiveRate(profile) * 120))
end

function EconomyService:getEconomyState(profile)
	return {
		passiveRate = self:getPassiveRate(profile),
		cavernValue = self:getCavernValue(profile),
		prestigeMultiplier = EconomyMath.getPrestigeMultiplier(
			profile.progression.prestigeCount,
			EconomyConfig.prestigeStep,
			EconomyConfig.basePrestigeMultiplier
		),
	}
end

function EconomyService:tickPlayer(userId, profile, nowUnix)
	local currentUnix = nowUnix or Time.nowUnix()
	local lastTickUnix = profile.session.lastPassiveTickUnix or currentUnix
	local elapsedSeconds = math.max(0, currentUnix - lastTickUnix)
	local passiveRate = self:getPassiveRate(profile)
	local awardedCoins, remainder = EconomyMath.resolvePassiveAccrual(
		passiveRate,
		elapsedSeconds,
		profile.session.passiveCoinRemainder
	)

	profile.session.lastPassiveTickUnix = currentUnix
	profile.session.passiveCoinRemainder = remainder

	if awardedCoins <= 0 then
		return 0
	end

	profile.currencies.coins += awardedCoins
	local playerData = self.dependencies.playerData
	if playerData ~= nil then
		playerData:notifyProfileChanged(userId)
	end

	return awardedCoins
end

function EconomyService:flushPlayer(userId, profile, nowUnix)
	return self:tickPlayer(userId, profile, nowUnix)
end

function EconomyService:start(services)
	self.dependencies.playerData = self.dependencies.playerData or services.playerData
	print("[GemFactory] EconomyService ready")

	task.spawn(function()
		while true do
			task.wait(1)

			local playerData = self.dependencies.playerData
			if playerData ~= nil then
				local nowUnix = Time.nowUnix()
				for userKey, profile in pairs(playerData:getActiveProfiles()) do
					local userId = tonumber(userKey)
					if userId ~= nil then
						self:tickPlayer(userId, profile, nowUnix)
					end
				end
			end
		end
	end)
end

return EconomyService


