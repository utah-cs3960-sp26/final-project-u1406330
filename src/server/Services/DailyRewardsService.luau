--!strict

-- Server-authoritative service for Daily Rewards Service that validates requests and mutates gameplay state for this system.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Resources = require(Shared.Config.Resources)
local DailyRewardsConfig = require(Shared.Config.DailyRewards)
local Id = require(Shared.Util.Id)
local Time = require(Shared.Util.Time)

local DailyRewardsService = {}
DailyRewardsService.__index = DailyRewardsService

function DailyRewardsService.new(dependencies)
	return setmetatable({
		dependencies = dependencies or {},
	}, DailyRewardsService)
end

local function addInventoryCount(container, key, amount)
	container[key] = (container[key] or 0) + amount
end

local function applyReward(profile, reward, nowUnix)
	if reward.rewardType == "coins" then
		profile.currencies.coins += reward.amount
	elseif reward.rewardType == "gems" then
		profile.currencies.gems += reward.amount
	elseif reward.rewardType == "token" then
		profile.currencies.eventTokens += reward.amount
	elseif reward.rewardType == "geode" then
		addInventoryCount(profile.inventory.geodes, reward.rewardId or "unknown_geode", reward.amount)
	elseif reward.rewardType == "boost" then
		addInventoryCount(profile.inventory.items, reward.rewardId or "unknown_boost", reward.amount)
	elseif reward.rewardType == "resource" then
		local resourceDefinition = Resources[reward.rewardId]
		if resourceDefinition ~= nil then
			for _ = 1, reward.amount do
				local resourceId = Id.new("daily_resource")
				profile.resourcesById[resourceId] = {
					id = resourceId,
					resourceTypeId = resourceDefinition.id,
					traitId = "none",
					level = 1,
					stationId = nil,
					obtainedAt = nowUnix,
					placement = nil,
				}
				table.insert(profile.resourceOrder, resourceId)
			end
		end
	end
end

function DailyRewardsService:getClaimState(profile, nowUnix)
	local rewards = DailyRewardsConfig.days
	local currentDay = math.clamp(profile.dailyRewards.currentDay, 1, #rewards)
	local lastClaimUnix = profile.dailyRewards.lastClaimUnix
	local currentUnix = nowUnix or Time.nowUnix()
	local cooldownSeconds = 24 * 60 * 60
	local resetSeconds = DailyRewardsConfig.streakResetHours * 60 * 60
	local streakExpired = lastClaimUnix ~= nil and (currentUnix - lastClaimUnix) >= resetSeconds
	if streakExpired then
		currentDay = 1
	end

	local canClaim = lastClaimUnix == nil or (currentUnix - lastClaimUnix) >= cooldownSeconds
	local nextClaimUnix = currentUnix
	if not canClaim and lastClaimUnix ~= nil then
		nextClaimUnix = lastClaimUnix + cooldownSeconds
	end

	return {
		canClaim = canClaim,
		currentDay = currentDay,
		nextClaimUnix = nextClaimUnix,
		reward = rewards[currentDay],
		streakExpired = streakExpired,
	}
end

function DailyRewardsService:claimReward(userId, nowUnix)
	local playerData = self.dependencies.playerData
	local profile = playerData:getOrLoadProfile(userId)
	if profile == nil then
		return nil, "profile_not_loaded"
	end

	local state = self:getClaimState(profile, nowUnix)
	if not state.canClaim then
		return nil, "reward_on_cooldown"
	end

	local reward = state.reward
	local currentUnix = nowUnix or Time.nowUnix()
	local result

	local _, mutateError = playerData:mutateProfile(userId, function(currentProfile)
		applyReward(currentProfile, reward, currentUnix)

		currentProfile.dailyRewards.lastClaimUnix = currentUnix
		currentProfile.dailyRewards.currentDay = (state.currentDay % #DailyRewardsConfig.days) + 1
		if state.streakExpired or currentProfile.dailyRewards.streakCount == 0 then
			currentProfile.dailyRewards.streakCount = 1
		else
			currentProfile.dailyRewards.streakCount += 1
		end

		result = {
			reward = reward,
			state = self:getClaimState(currentProfile, currentUnix),
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

function DailyRewardsService:start()
	print("[GemFactory] DailyRewardsService ready")
end

return DailyRewardsService


