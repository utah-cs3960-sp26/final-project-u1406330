--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local EconomyConfig = require(Shared.Config.Economy)
local OfflineMath = require(Shared.Domain.OfflineMath)
local Time = require(Shared.Util.Time)

local OfflineProgressService = {}
OfflineProgressService.__index = OfflineProgressService

function OfflineProgressService.new(dependencies)
	return setmetatable({
		dependencies = dependencies or {},
	}, OfflineProgressService)
end

function OfflineProgressService:buildSummary(profile, nowUnix)
	local passiveRate = self.dependencies.economyService:getPassiveRate(profile)
	local summary = OfflineMath.buildSummary(
		profile.session.lastLogoutUnix,
		nowUnix,
		passiveRate,
		EconomyConfig.offlineCapSeconds
	)

	if summary == nil then
		return nil
	end

	summary.finishedGeodes = OfflineMath.collectFinishedGeodeIds(profile.geodeQueue, nowUnix)
	return summary
end

function OfflineProgressService:claimOfflineRewards(userId, nowUnix, rng, playerName)
	local playerData = self.dependencies.playerData
	local geodeQueueService = self.dependencies.geodeQueueService
	local profile = playerData:getOrLoadProfile(userId)
	if profile == nil then
		return nil, "profile_not_loaded"
	end

	local currentUnix = nowUnix or Time.nowUnix()
	local summary = profile.unclaimedOfflineRewards or self:buildSummary(profile, currentUnix)
	if summary == nil then
		return nil, "no_offline_rewards"
	end

	local result
	local _, mutateError = playerData:mutateProfile(userId, function(currentProfile)
		currentProfile.currencies.coins += summary.coins
		local geodeResult = geodeQueueService:claimEntries(currentProfile, currentUnix, rng, nil, playerName)

		currentProfile.unclaimedOfflineRewards = nil
		currentProfile.session.lastLogoutUnix = nil

		result = {
			summary = summary,
			reveals = geodeResult,
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

function OfflineProgressService:start()
	print("[GemFactory] OfflineProgressService ready")
end

return OfflineProgressService



