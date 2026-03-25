--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local DailyRewardsConfig = require(Shared.Config.DailyRewards)
local Time = require(Shared.Util.Time)

local DailyRewardsController = {}
DailyRewardsController.__index = DailyRewardsController

local function formatDuration(seconds: number): string
	local safeSeconds = math.max(0, math.floor(seconds))
	local hours = math.floor(safeSeconds / 3600)
	local minutes = math.floor((safeSeconds % 3600) / 60)
	local remaining = safeSeconds % 60
	return string.format("%02d:%02d:%02d", hours, minutes, remaining)
end

local function formatReward(reward)
	if reward.rewardType == "coins" then
		return string.format("%d coins", reward.amount)
	end

	if reward.rewardType == "gems" then
		return string.format("%d gems", reward.amount)
	end

	if reward.rewardId ~= nil then
		return string.format("%s x%d", tostring(reward.rewardId), reward.amount)
	end

	return string.format("%s x%d", tostring(reward.rewardType), reward.amount)
end

local function getClaimState(profile, nowUnix)
	local rewards = DailyRewardsConfig.days
	local currentDay = math.clamp(profile.dailyRewards.currentDay, 1, #rewards)
	local reward = rewards[currentDay]
	local lastClaimUnix = profile.dailyRewards.lastClaimUnix
	local cooldownSeconds = 24 * 60 * 60
	local canClaim = lastClaimUnix == nil or (nowUnix - lastClaimUnix) >= cooldownSeconds
	local nextClaimUnix = if canClaim then nowUnix else lastClaimUnix + cooldownSeconds

	return {
		currentDay = currentDay,
		reward = reward,
		canClaim = canClaim,
		nextClaimUnix = nextClaimUnix,
	}
end

function DailyRewardsController.new(context)
	return setmetatable({
		context = context or {},
	}, DailyRewardsController)
end

function DailyRewardsController:start()
	local screen = self.context.screen
	local app = self.context.app

	local function refresh(state, nowUnix)
		local profile = state.profile
		local claimState = getClaimState(profile, nowUnix)
		screen:setDailyText(string.format(
			"Day %d reward: %s\nStreak: %d\nNext claim: %s",
			claimState.currentDay,
			formatReward(claimState.reward),
			profile.dailyRewards.streakCount or 0,
			if claimState.canClaim then "Ready now" else formatDuration(claimState.nextClaimUnix - nowUnix)
		))

		screen:setDailyButtonState(
			claimState.canClaim,
			if claimState.canClaim then "Claim Daily Reward" else string.format("Claim in %s", formatDuration(claimState.nextClaimUnix - nowUnix))
		)
	end

	screen.buttons.claimDaily.Activated:Connect(function()
		app:requestClaimDailyReward()
	end)

	self.context.stateChanged:Connect(refresh)
	refresh(app:getState(), Time.nowUnix())
end

return DailyRewardsController
