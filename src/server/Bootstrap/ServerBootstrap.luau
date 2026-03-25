--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemoteNames = require(Shared.Net.RemoteNames)
local Time = require(Shared.Util.Time)

local function ensureRemotes()
	local Remotes = require(Shared.Net.Remotes)
	local remotes = {}

	local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
	if remotesFolder == nil then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "Remotes"
		remotesFolder.Parent = ReplicatedStorage
	end

	for remoteName, className in pairs(Remotes.definitions) do
		local remote = remotesFolder:FindFirstChild(remoteName)
		if remote == nil then
			remote = Instance.new(className)
			remote.Name = remoteName
			remote.Parent = remotesFolder
		end
		remotes[remoteName] = remote
	end

	return remotes
end

local ServerBootstrap = {}

local function resolveServices(remotes)
	local servicesFolder = script.Parent.Parent.Services

	local MockPersistenceService = require(servicesFolder.MockPersistenceService)
	local PlayerDataService = require(servicesFolder.PlayerDataService)
	local PlotService = require(servicesFolder.PlotService)
	local ShopService = require(servicesFolder.ShopService)
	local StationService = require(servicesFolder.StationService)
	local PlacementService = require(servicesFolder.PlacementService)
	local EconomyService = require(servicesFolder.EconomyService)
	local GeodeService = require(servicesFolder.GeodeService)
	local GeodeQueueService = require(servicesFolder.GeodeQueueService)
	local DailyRewardsService = require(servicesFolder.DailyRewardsService)
	local OfflineProgressService = require(servicesFolder.OfflineProgressService)
	local WorldReplicaService = require(servicesFolder.WorldReplicaService)
	local RareAnnouncementSystem = require(script.Parent.Parent.Systems.RareAnnouncementSystem)

	local persistence = MockPersistenceService.new()
	local playerData = PlayerDataService.new(persistence)
	local shop = ShopService.new()
	local stations = StationService.new()
	local plot = PlotService.new()
	local placement = PlacementService.new({
		stationService = stations,
	})
	local economy = EconomyService.new({
		playerData = playerData,
		stationService = stations,
	})
	local rareAnnouncements = RareAnnouncementSystem.new(remotes[RemoteNames.RareRevealAnnounced])
	local geode = GeodeService.new({
		playerData = playerData,
		shopService = shop,
	})
	local geodeQueue = GeodeQueueService.new({
		playerData = playerData,
		geodeService = geode,
		stationService = stations,
		rareAnnouncementService = rareAnnouncements,
	})
	local dailyRewards = DailyRewardsService.new({
		playerData = playerData,
	})
	local offlineProgress = OfflineProgressService.new({
		playerData = playerData,
		economyService = economy,
		geodeQueueService = geodeQueue,
	})
	local worldReplica = WorldReplicaService.new({
		plotService = plot,
		placementService = placement,
		stationService = stations,
		playerDataService = playerData,
	})

	return {
		persistence = persistence,
		playerData = playerData,
		shop = shop,
		stations = stations,
		plot = plot,
		placement = placement,
		economy = economy,
		geode = geode,
		geodeQueue = geodeQueue,
		dailyRewards = dailyRewards,
		offlineProgress = offlineProgress,
		worldReplica = worldReplica,
		rareAnnouncements = rareAnnouncements,
	}
end

function ServerBootstrap.start()
	local remotes = ensureRemotes()
	local services = resolveServices(remotes)
	local running = true

	local function publishState(userId)
		local player = Players:GetPlayerByUserId(userId)
		if player == nil then
			return
		end

		local state = services.playerData:getPublicState(userId, Time.nowUnix())
		remotes.StateUpdated:FireClient(player, state)
	end

	local function publishShopState()
		local shopState = services.shop:getShopState(Time.nowUnix())
		remotes.ShopRotationUpdated:FireAllClients(shopState)
	end

	services.playerData.onProfileChanged = publishState

	local function callAction(actionName, action)
		local ok, result = pcall(action)
		if not ok then
			warn("[GemFactory] " .. actionName .. " failed:", result)
			return {
				ok = false,
				errorCode = "internal_error",
			}
		end

		return result
	end

	remotes.GetInitialState.OnServerInvoke = function(player)
		return {
			ok = true,
			state = services.playerData:getPublicState(player.UserId, Time.nowUnix()),
		}
	end

	remotes.RequestBuyGeode.OnServerInvoke = function(player, geodeId)
		return callAction("RequestBuyGeode", function()
			local result, errorCode = services.geode:buyGeode(player.UserId, geodeId, Time.nowUnix())
			if result == nil then
				return {
					ok = false,
					errorCode = errorCode or "purchase_failed",
				}
			end

			return {
				ok = true,
				purchase = result,
			}
		end)
	end

	remotes.RequestClaimFinishedGeode.OnServerInvoke = function(player, geodeId)
		return callAction("RequestClaimFinishedGeode", function()
			local profile = services.playerData:getOrLoadProfile(player.UserId)
			if profile == nil then
				return {
					ok = false,
					errorCode = "profile_not_loaded",
				}
			end

			local claimResult = services.geodeQueue:claimEntries(profile, Time.nowUnix(), nil, geodeId, player.Name)
			if claimResult == nil then
				return {
					ok = false,
					errorCode = "no_ready_geodes",
				}
			end

			services.playerData:notifyProfileChanged(player.UserId)
			return {
				ok = true,
				claim = claimResult,
			}
		end)
	end

	remotes.RequestClaimDailyReward.OnServerInvoke = function(player)
		return callAction("RequestClaimDailyReward", function()
			local result, errorCode = services.dailyRewards:claimReward(player.UserId, Time.nowUnix())
			if result == nil then
				return {
					ok = false,
					errorCode = errorCode or "reward_failed",
				}
			end

			return {
				ok = true,
				claim = result,
			}
		end)
	end

	remotes.RequestCollectOfflineRewards.OnServerInvoke = function(player)
		return callAction("RequestCollectOfflineRewards", function()
			local result, errorCode = services.offlineProgress:claimOfflineRewards(player.UserId, Time.nowUnix(), nil, player.Name)
			if result == nil then
				return {
					ok = false,
					errorCode = errorCode or "offline_reward_failed",
				}
			end

			return {
				ok = true,
				claim = result,
			}
		end)
	end

	remotes.RequestPlaceStation.OnServerInvoke = function(player, stationTypeId, x, y)
		return callAction("RequestPlaceStation", function()
			local profile = services.playerData:getOrLoadProfile(player.UserId)
			if profile == nil then
				return {
					ok = false,
					errorCode = "profile_not_loaded",
				}
			end

			local requestedStationTypeId = stationTypeId or services.stations:getStarterStationTypeId()
			local station, placementOrReason = services.placement:placeStation(profile, requestedStationTypeId, x, y)
			if station == nil or placementOrReason == nil then
				return {
					ok = false,
					errorCode = placementOrReason or "station_placement_failed",
				}
			end
			local placement = placementOrReason

			local resourceIds = {}
			for _, resourceId in ipairs(profile.resourceOrder) do
				local resource = profile.resourcesById[resourceId]
				if resource ~= nil and resource.stationId == nil then
					table.insert(resourceIds, resourceId)
				end
			end

			local autoAssignment = services.stations:autoAssignResources(profile, resourceIds)
			services.playerData:notifyProfileChanged(player.UserId)

			return {
				ok = true,
				station = station,
				placement = placement,
				autoAssignment = autoAssignment,
			}
		end)
	end

	remotes.RequestMovePlacedObject.OnServerInvoke = function()
		return {
			ok = false,
			errorCode = "not_implemented",
		}
	end

	remotes.RequestUpgradeStation.OnServerInvoke = function()
		return {
			ok = false,
			errorCode = "not_implemented",
		}
	end

	task.spawn(function()
		while running do
			publishShopState()
			task.wait(15)
		end
	end)

	local startOrder = {
		services.persistence,
		services.playerData,
		services.shop,
		services.stations,
		services.plot,
		services.placement,
		services.economy,
		services.geode,
		services.geodeQueue,
		services.dailyRewards,
		services.offlineProgress,
		services.worldReplica,
		services.rareAnnouncements,
	}

	for _, service in ipairs(startOrder) do
		if type(service) == "table" and service.start ~= nil then
			service:start(services)
		end
	end

	print("[GemFactory] Server bootstrap started")
	return services
end

return ServerBootstrap


