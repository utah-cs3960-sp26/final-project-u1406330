--!strict

-- Server bootstrap module that constructs services, registers remotes, and starts authoritative gameplay systems.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Geodes = require(Shared.Config.Geodes)
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

local function isValidMineTarget(instance)
	if instance == nil or not instance:IsA("BasePart") then
		return false
	end

	if instance:GetAttribute("GemFactoryMineTarget") == true then
		return true
	end

	local current = instance.Parent
	while current ~= nil do
		if current:IsA("Model") and current:GetAttribute("GemFactoryMine") == true then
			return true
		end
		current = current.Parent
	end

	return false
end

local function findMineModel(instance)
	local current = instance
	while current ~= nil do
		if current:IsA("Model") and current:GetAttribute("GemFactoryMine") == true then
			return current
		end
		current = current.Parent
	end

	return nil
end

local function isPositionInsidePart(position, part)
	local localPosition = part.CFrame:PointToObjectSpace(position)
	local halfSize = part.Size / 2
	return math.abs(localPosition.X) <= halfSize.X
		and math.abs(localPosition.Y) <= halfSize.Y
		and math.abs(localPosition.Z) <= halfSize.Z
end

local function isPlayerInsideMine(player, mineTarget)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return false
	end

	local mineModel = findMineModel(mineTarget)
	if mineModel == nil then
		return false
	end

	for _, descendant in ipairs(mineModel:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("GemFactoryMineZone") == true then
			return isPositionInsidePart(root.Position, descendant)
		end
	end

	return false
end

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
	local GeodeToolService = require(servicesFolder.GeodeToolService)
	local VaultService = require(servicesFolder.VaultService)
	local MiningService = require(servicesFolder.MiningService)
	local PickaxeToolService = require(servicesFolder.PickaxeToolService)
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
		placementService = placement,
	})
	local geodeTools = GeodeToolService.new({
		playerData = playerData,
	})
	local vault = VaultService.new({
		playerData = playerData,
		placementService = placement,
	})
	local pickaxeTools = PickaxeToolService.new({
		playerData = playerData,
	})
	local mining = MiningService.new({
		playerData = playerData,
		geodeService = geode,
	})
	local geodeQueue = GeodeQueueService.new({
		playerData = playerData,
		geodeService = geode,
		stationService = stations,
		placementService = placement,
		rareAnnouncementService = rareAnnouncements,
	})
	geode.dependencies.geodeQueueService = geodeQueue
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
		geodeTools = geodeTools,
		vault = vault,
		mining = mining,
		pickaxeTools = pickaxeTools,
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

	services.playerData.onProfileChanged = function(userId)
		publishState(userId)
		services.geodeTools:syncPlayerByUserId(userId)
		services.pickaxeTools:syncPlayerByUserId(userId)
	end

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
		return {
			ok = false,
			errorCode = "geode_shop_removed",
		}
	end

	remotes.RequestBuyPickaxe.OnServerInvoke = function(player, pickaxeId)
		return callAction("RequestBuyPickaxe", function()
			local result, errorCode = services.mining:buyPickaxe(player.UserId, pickaxeId)
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

	remotes.RequestEquipPickaxe.OnServerInvoke = function(player, pickaxeId)
		return callAction("RequestEquipPickaxe", function()
			local result, errorCode = services.mining:equipPickaxe(player.UserId, pickaxeId)
			if result == nil then
				return {
					ok = false,
					errorCode = errorCode or "equip_failed",
				}
			end

			return {
				ok = true,
				equip = result,
			}
		end)
	end

	remotes.RequestMine.OnServerInvoke = function(player, pickaxeId, mineTarget)
		return callAction("RequestMine", function()
			if not isValidMineTarget(mineTarget) or not isPlayerInsideMine(player, mineTarget) then
				return {
					ok = false,
					errorCode = "not_inside_mine",
				}
			end

			local mineResult, errorCode = services.mining:mine(player.UserId, pickaxeId, Time.nowUnix())
			if mineResult == nil then
				return {
					ok = false,
					errorCode = errorCode or "mine_failed",
				}
			end

			local reward = mineResult.reward
			return {
				ok = true,
				reward = reward,
				rewardType = reward.rewardType,
				coins = reward.coins,
				geodeId = reward.geodeId,
				geodeTypeId = reward.geodeId,
				geodeDisplayName = reward.geodeId ~= nil and Geodes[reward.geodeId] ~= nil and Geodes[reward.geodeId].displayName or nil,
				geodeInstance = reward.geodeInstance,
				pickaxeId = mineResult.pickaxeId,
			}
		end)
	end

	local function handleOpenGeode(player, geodeId)
		return callAction("RequestCrackGeode", function()
			local openResult, errorCode = services.geode:openGeode(player.UserId, geodeId, Time.nowUnix(), nil, player.Name)
			if openResult == nil then
				return {
					ok = false,
					errorCode = errorCode or "open_failed",
				}
			end

			return {
				ok = true,
				open = openResult,
			}
		end)
	end

	remotes.RequestCrackGeode.OnServerInvoke = handleOpenGeode
	remotes.RequestClaimFinishedGeode.OnServerInvoke = handleOpenGeode

	remotes.RequestPlaceGeode.OnServerInvoke = function(player, geodeInstanceId, x, y)
		return callAction("RequestPlaceGeode", function()
			local placeResult, errorCode = services.geode:placeGeode(player.UserId, geodeInstanceId, x, y)
			if placeResult == nil then
				return {
					ok = false,
					errorCode = errorCode or "placement_failed",
				}
			end

			return {
				ok = true,
				placement = placeResult.placement,
				geode = placeResult.geodeInstance,
			}
		end)
	end

	remotes.RequestPlaceResource.OnServerInvoke = function(player, resourceId, x, y)
		return callAction("RequestPlaceResource", function()
			local placeResult, errorCode = services.vault:placeResource(player.UserId, resourceId, x, y)
			if placeResult == nil then
				return {
					ok = false,
					errorCode = errorCode or "placement_failed",
				}
			end

			return {
				ok = true,
				placement = placeResult.placement,
				resource = placeResult.resource,
			}
		end)
	end

	remotes.RequestPickupResource.OnServerInvoke = function(player, resourceId)
		return callAction("RequestPickupResource", function()
			local pickupResult, errorCode = services.vault:pickupResource(player.UserId, resourceId)
			if pickupResult == nil then
				return {
					ok = false,
					errorCode = errorCode or "pickup_failed",
				}
			end

			return {
				ok = true,
				resource = pickupResult.resource,
			}
		end)
	end

	remotes.RequestSellVaultItem.OnServerInvoke = function(player, itemKind, itemId)
		return callAction("RequestSellVaultItem", function()
			local sellResult, errorCode
			if itemKind == "geode" then
				sellResult, errorCode = services.vault:sellGeode(player.UserId, itemId)
			elseif itemKind == "resource" then
				sellResult, errorCode = services.vault:sellResource(player.UserId, itemId)
			else
				return {
					ok = false,
					errorCode = "unsupported_vault_item",
				}
			end

			if sellResult == nil then
				return {
					ok = false,
					errorCode = errorCode or "sell_failed",
				}
			end

			return {
				ok = true,
				sale = sellResult,
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
				if resource ~= nil and resource.stationId == nil and resource.placement == nil then
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
		services.geodeTools,
		services.vault,
		services.mining,
		services.pickaxeTools,
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


