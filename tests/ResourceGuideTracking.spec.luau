--!strict

-- Spec coverage for server-authoritative Resource Guide tracking so collection progress persists from reward grant paths.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Server = ServerScriptService:WaitForChild("Server")

local DailyRewardsConfig = require(Shared.Config.DailyRewards)
local PlayerProfile = require(Shared.Types.PlayerProfile)
local PlacementService = require(Server.Services.PlacementService)
local GeodeService = require(Server.Services.GeodeService)
local GeodeQueueService = require(Server.Services.GeodeQueueService)
local DailyRewardsService = require(Server.Services.DailyRewardsService)

return function()
	local profile = PlayerProfile.new(100)
	profile.plotState.plotId = "plot_1"
	profile.dailyRewards.currentDay = 1

	local notifiedCount = 0
	local playerData = {
		getOrLoadProfile = function()
			return profile
		end,
		mutateProfile = function(_, _, mutator)
			return mutator(profile)
		end,
		notifyProfileChanged = function()
			notifiedCount += 1
		end,
	}

	local geodeService = GeodeService.new({
		playerData = playerData,
		placementService = PlacementService.new({}),
	})
	local geodeQueueService = GeodeQueueService.new({
		geodeService = geodeService,
		placementService = geodeService.dependencies.placementService,
	})

	local geodeInstance = geodeService:createGeodeInstance(profile, "starter_geode", 100, Random.new(5))
	assert(geodeInstance ~= nil, "test setup should create a starter geode instance")
	geodeInstance.startsAt = 100
	geodeInstance.endsAt = 100
	geodeInstance.placement = {
		x = 1,
		y = 1,
		width = 1,
		height = 1,
		rotation = 0,
	}

	local openResult = geodeQueueService:openGeode(profile, 100, Random.new(7), geodeInstance.id, "Tester")
	assert(openResult ~= nil and #openResult.createdResources == 1, "opening a ready geode should still create one resource")

	local crackedResource = openResult.createdResources[1]
	local discoveredFromGeode = profile.resourceGuide.discoveredResources[crackedResource.resourceTypeId]
	assert(discoveredFromGeode ~= nil and discoveredFromGeode.found == true, "geode openings should mark the rolled resource as collected")
	assert(
		discoveredFromGeode.discoveredTraits[crackedResource.traitId or "none"] == true,
		"geode openings should record the rolled trait for that resource"
	)

	local dailyRewardsService = DailyRewardsService.new({
		playerData = playerData,
	})

	local resourceDay = nil
	for dayIndex, day in ipairs(DailyRewardsConfig.days) do
		if day.rewardType == "resource" then
			resourceDay = dayIndex
			break
		end
	end

	assert(resourceDay ~= nil, "daily rewards config should include at least one resource reward day for collection tracking")

	profile.dailyRewards.currentDay = resourceDay
	profile.dailyRewards.lastClaimUnix = nil

	local rewardResult = dailyRewardsService:claimReward(1, 400)
	assert(rewardResult ~= nil, "claiming a resource daily reward should succeed when the reward is ready")

	local rewardedResourceId = DailyRewardsConfig.days[resourceDay].rewardId
	local discoveredFromDaily = profile.resourceGuide.discoveredResources[rewardedResourceId]
	assert(discoveredFromDaily ~= nil and discoveredFromDaily.found == true, "daily resource rewards should also update collection progress")
	assert(
		discoveredFromDaily.discoveredTraits.none == true,
		"daily resource rewards should record the plain no-trait discovery state for hover details"
	)
	assert(notifiedCount == 1, "daily reward claims should still notify listeners after mutating collection progress")
end
