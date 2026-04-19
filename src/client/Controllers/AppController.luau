--!strict

-- Client controller for App Controller that coordinates UI, local input, and app-state updates for this slice.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Resources = require(Shared.Config.Resources)
local Traits = require(Shared.Config.Traits)
local GeodePresentation = require(Shared.Domain.GeodePresentation)
local RewardPresentation = require(Shared.Domain.RewardPresentation)
local TableUtil = require(Shared.Util.TableUtil)
local Time = require(Shared.Util.Time)
local Signal = require(Shared.Util.Signal)
local PlayerProfile = require(Shared.Types.PlayerProfile)
local RemoteNames = require(Shared.Net.RemoteNames)

local RootScreen = require(script.Parent.Parent.UI.Screens.RootScreen)

local HUDController = require(script.Parent.HUDController)
local ShopController = require(script.Parent.ShopController)
local MiningController = require(script.Parent.MiningController)
local GeodeController = require(script.Parent.GeodeController)
local PlotController = require(script.Parent.PlotController)
local GeodeInteractionController = require(script.Parent.GeodeInteractionController)
local PlacementController = require(script.Parent.PlacementController)
local DailyRewardsController = require(script.Parent.DailyRewardsController)
local NotificationsController = require(script.Parent.NotificationsController)
local VaultController = require(script.Parent.VaultController)
local SprintController = require(script.Parent.SprintController)
local Palette = require(script.Parent.Parent.UI.Theme.Palette)

local AppController = {}
AppController.__index = AppController

local function buildDefaultState(nowUnix: number)
	return {
		profile = PlayerProfile.new(nowUnix),
		shop = {},
		announcements = {},
		connectionMessage = "Loading crystal cavern...",
	}
end

local function normalizeAnnouncements(payload, currentAnnouncements)
	local announcements = {}

	if type(payload) == "string" then
		table.insert(announcements, payload)
	elseif type(payload) == "table" then
		if #payload > 0 then
			for _, item in ipairs(payload) do
				if type(item) == "string" then
					table.insert(announcements, item)
				elseif type(item) == "table" then
					table.insert(announcements, tostring(item.message or item.text or item.title or "Crystal reveal spotted"))
				end
			end
		else
			table.insert(announcements, tostring(payload.message or payload.text or payload.title or "Crystal reveal spotted"))
		end
	end

	if #announcements == 0 then
		return TableUtil.deepCopy(currentAnnouncements)
	end

	while #announcements > 5 do
		table.remove(announcements)
	end

	return announcements
end

local function normalizeShopState(currentShop, payload)
	local shop = TableUtil.deepCopy(currentShop)
	local handledKeys = {
		currentOffer = true,
		offerIndex = true,
		secondsRemaining = true,
		starterOffer = true,
	}

	if type(payload) ~= "table" then
		return shop
	end

	if payload.currentOffer ~= nil then
		shop.currentOffer = TableUtil.deepCopy(payload.currentOffer)
	elseif payload.offerId ~= nil or payload.price ~= nil or payload.currency ~= nil then
		shop.currentOffer = TableUtil.deepCopy(payload)
	end

	if payload.offerIndex ~= nil then
		shop.offerIndex = payload.offerIndex
	end

	if payload.secondsRemaining ~= nil then
		shop.secondsRemaining = math.max(0, payload.secondsRemaining)
	end

	if payload.starterOffer ~= nil then
		shop.starterOffer = TableUtil.deepCopy(payload.starterOffer)
	end

	for key, value in pairs(payload) do
		if handledKeys[key] ~= true then
			shop[key] = TableUtil.deepCopy(value)
		end
	end

	return shop
end

local function normalizeProfileState(currentProfile, payload, nowUnix)
	local profile = TableUtil.deepCopy(currentProfile)
	local profileAny = profile :: any

	if type(payload) ~= "table" then
		return profile
	end

	local profilePayload = payload.profile
	if profilePayload == nil and payload.currencies ~= nil and payload.resourcesById ~= nil then
		profilePayload = payload
	end

	if profilePayload ~= nil then
		profile = PlayerProfile.reconcile(profilePayload, nowUnix)
	end

	if payload.currencies ~= nil then
		profile.currencies = TableUtil.reconcile(profile.currencies, payload.currencies)
	end

	if payload.resourcesById ~= nil then
		profile.resourcesById = TableUtil.reconcile(profile.resourcesById, payload.resourcesById)
	end

	if payload.resourceOrder ~= nil then
		profile.resourceOrder = TableUtil.deepCopy(payload.resourceOrder)
	end

	if payload.inventory ~= nil then
		profile.inventory = TableUtil.reconcile(profile.inventory, payload.inventory)
	end

	if payload.resourceGuide ~= nil then
		profile.resourceGuide = TableUtil.reconcile(profile.resourceGuide, payload.resourceGuide)
	end

	if payload.stationsById ~= nil then
		profile.stationsById = TableUtil.reconcile(profile.stationsById, payload.stationsById)
	end

	if payload.placedObjects ~= nil then
		profile.placedObjects = TableUtil.reconcile(profile.placedObjects, payload.placedObjects)
	end

	if payload.geodeQueue ~= nil then
		profile.geodeQueue = TableUtil.deepCopy(payload.geodeQueue)
	end

	if payload.geodesById ~= nil then
		profileAny.geodesById = TableUtil.reconcile(profileAny.geodesById or {}, payload.geodesById)
	end

	if payload.geodeOrder ~= nil then
		profileAny.geodeOrder = TableUtil.deepCopy(payload.geodeOrder)
	end

	if payload.unclaimedOfflineRewards ~= nil then
		profile.unclaimedOfflineRewards = TableUtil.deepCopy(payload.unclaimedOfflineRewards)
	end

	if payload.dailyRewards ~= nil then
		profile.dailyRewards = TableUtil.reconcile(profile.dailyRewards, payload.dailyRewards)
	end

	if payload.progression ~= nil then
		profile.progression = TableUtil.reconcile(profile.progression, payload.progression)
	end

	if payload.plotState ~= nil then
		profile.plotState = TableUtil.reconcile(profile.plotState, payload.plotState)
	end

	if payload.session ~= nil then
		profile.session = TableUtil.reconcile(profile.session, payload.session)
	end

	return profile
end

local function normalizePayload(state, payload, nowUnix)
	local nextState = TableUtil.deepCopy(state)

	if type(payload) ~= "table" then
		return nextState
	end

	if payload.state ~= nil then
		payload = payload.state
	end

	nextState.profile = normalizeProfileState(nextState.profile, payload, nowUnix)

	if payload.shop ~= nil then
		nextState.shop = normalizeShopState(nextState.shop, payload.shop)
	elseif payload.currentOffer ~= nil or payload.offerId ~= nil or payload.price ~= nil then
		nextState.shop = normalizeShopState(nextState.shop, payload)
	end

	if payload.announcements ~= nil then
		nextState.announcements = normalizeAnnouncements(payload.announcements, nextState.announcements)
	end

	if payload.connectionMessage ~= nil then
		nextState.connectionMessage = tostring(payload.connectionMessage)
	end

	return nextState
end

local function getResourceCelebrationSpec(resource, hasFollowupAttribute: boolean?)
	if type(resource) ~= "table" then
		return nil
	end

	local resourceTypeId = resource.resourceTypeId
	if type(resourceTypeId) ~= "string" then
		return nil
	end

	local resourceDefinition = Resources[resourceTypeId]
	local rarityName = if resourceDefinition ~= nil and type(resourceDefinition.rarity) == "string"
		then resourceDefinition.rarity
		else "Common"
	local rarityIndex = RewardPresentation.getResourceCelebrationTier(resourceDefinition)
	local traitId = if type(resource.traitId) == "string" then resource.traitId else "none"
	local displayName = if resourceDefinition ~= nil and resourceDefinition.displayName ~= nil then resourceDefinition.displayName else resourceTypeId

	return {
		kind = "resource",
		headline = "RESOURCE!",
		primary = displayName,
		detail = rarityName .. " treasure!",
		resourceTypeId = resourceTypeId,
		traitId = traitId,
		rarityLabel = rarityName,
		rarityIndex = rarityIndex + 1,
		accentColor = if resourceDefinition ~= nil then resourceDefinition.color else nil,
		reelWords = GeodePresentation.getResourceRevealWords(),
		reelFinal = displayName,
		showSlotMachine = GeodePresentation.shouldUseRevealSlotMachine("resource", rarityIndex + 1),
		duration = GeodePresentation.getRevealResolvedHoldSeconds("resource", hasFollowupAttribute),
	}
end

local function getAttributeCelebrationSpec(resource)
	if type(resource) ~= "table" then
		return nil
	end

	local traitId = if type(resource.traitId) == "string" then resource.traitId else "none"
	if traitId == "none" then
		return nil
	end

	local traitDefinition = Traits[traitId]
	if traitDefinition == nil then
		return nil
	end

	local traitRank = RewardPresentation.getTraitCelebrationTier(traitDefinition)
	local multiplier = traitDefinition.multiplier or traitDefinition.sellMultiplier or 1
	local displayName = traitDefinition.displayName or traitId

	return {
		kind = "attribute",
		headline = "ATTRIBUTE!",
		primary = displayName,
		detail = string.format("Sell value x%.2f", multiplier),
		traitId = traitId,
		rarityLabel = traitDefinition.rarity or displayName,
		rarityIndex = traitRank + 1,
		accentColor = traitDefinition.accentColor,
		highlightColor = traitDefinition.glowColor,
		reelWords = GeodePresentation.getAttributeRevealWords(),
		reelFinal = displayName,
		showSlotMachine = GeodePresentation.shouldUseRevealSlotMachine("attribute", traitRank + 1),
	}
end

function AppController.new()
	local nowUnix = Time.nowUnix()
	local context = {
		palette = Palette,
		stateChanged = Signal.new(),
		screen = nil,
		app = nil,
	}

	local self = setmetatable({
		context = context,
		state = buildDefaultState(nowUnix),
		remotes = {},
		controllers = {},
		pendingGeodePlacementId = nil,
		pendingResourcePlacementId = nil,
		_running = false,
	}, AppController)

	context.app = self
	self.controllers = {
		HUDController.new(context),
		ShopController.new(context),
		MiningController.new(context),
		GeodeController.new(context),
		PlotController.new(context),
		GeodeInteractionController.new(context),
		PlacementController.new(context),
		DailyRewardsController.new(context),
		NotificationsController.new(context),
		VaultController.new(context),
		SprintController.new(context),
	}

	return self
end

function AppController:getState()
	return self.state
end

function AppController:emitState(reason)
	self.context.stateChanged:Fire(self.state, Time.nowUnix(), reason)
end

function AppController:applyPayload(payload, reason)
	self.state = normalizePayload(self.state, payload, Time.nowUnix())
	self:emitState(reason or "state")
end

function AppController:setStatus(message)
	self.state.connectionMessage = message
	self:emitState("status")
end

function AppController:pushAnnouncement(message)
	if message == nil or message == "" then
		return
	end

	table.insert(self.state.announcements, 1, message)
	while #self.state.announcements > 5 do
		table.remove(self.state.announcements)
	end

	self:emitState("announcement")
end

function AppController:showOpenResultCelebrations(openResult)
	local screen = self.context.screen
	if screen == nil or screen.showMiningPopup == nil or type(openResult) ~= "table" then
		return
	end

	local createdResources = openResult.createdResources
	if type(createdResources) ~= "table" then
		return
	end

	for _, resource in ipairs(createdResources) do
		local attributeCelebration = getAttributeCelebrationSpec(resource)
		local resourceCelebration = getResourceCelebrationSpec(resource, attributeCelebration ~= nil)

		if resourceCelebration ~= nil then
			screen:showMiningPopup(resourceCelebration)
		end

		if attributeCelebration ~= nil then
			screen:showMiningPopup(attributeCelebration)
		end
	end
end

function AppController:getRemote(name)
	return self.remotes[name]
end

function AppController:invokeRemote(name, ...)
	local remote = self:getRemote(name)
	if remote == nil then
		return false, "remote_unavailable"
	end

	local ok, result = pcall(function(...)
		return remote:InvokeServer(...)
	end, ...)

	if not ok then
		return false, result
	end

	if type(result) == "table" then
		self:applyPayload(result, name)
	end

	return true, result
end

function AppController:getPendingGeodePlacementId()
	return self.pendingGeodePlacementId
end

function AppController:getPendingResourcePlacementId()
	return self.pendingResourcePlacementId
end

function AppController:beginGeodePlacement(geodeInstanceId)
	if geodeInstanceId == nil then
		return false
	end

	self.pendingGeodePlacementId = geodeInstanceId
	self.pendingResourcePlacementId = nil
	self:setStatus("Click a cell on your plot to place this geode.")
	return true
end

function AppController:beginResourcePlacement(resourceId)
	if resourceId == nil then
		return false
	end

	self.pendingResourcePlacementId = resourceId
	self.pendingGeodePlacementId = nil
	self:setStatus("Click a cell on your plot to place this treasure.")
	return true
end

function AppController:cancelGeodePlacement()
	if self.pendingGeodePlacementId == nil then
		return
	end

	self.pendingGeodePlacementId = nil
	self:setStatus("Geode placement canceled.")
end

function AppController:cancelResourcePlacement()
	if self.pendingResourcePlacementId == nil then
		return
	end

	self.pendingResourcePlacementId = nil
	self:setStatus("Resource placement canceled.")
end

function AppController:requestPlaceGeode(geodeInstanceId, x, y)
	if geodeInstanceId == nil then
		return false, "missing_geode_id"
	end

	local ok, result = self:invokeRemote(RemoteNames.RequestPlaceGeode, geodeInstanceId, x, y)
	if ok and type(result) == "table" and result.ok == true then
		self.pendingGeodePlacementId = nil
		self:setStatus("Geode placed on your plot.")
	else
		local errorText = type(result) == "table" and result.errorCode or result
		self:setStatus("Geode placement failed: " .. tostring(errorText))
	end
	return ok, result
end

function AppController:requestPlaceResource(resourceId, x, y)
	if resourceId == nil then
		return false, "missing_resource_id"
	end

	local ok, result = self:invokeRemote(RemoteNames.RequestPlaceResource, resourceId, x, y)
	if ok and type(result) == "table" and result.ok == true then
		self.pendingResourcePlacementId = nil
		self:setStatus("Treasure placed on your plot.")
	else
		local errorText = type(result) == "table" and result.errorCode or result
		self:setStatus("Treasure placement failed: " .. tostring(errorText))
	end
	return ok, result
end

function AppController:requestPickupResource(resourceId)
	if resourceId == nil then
		return false, "missing_resource_id"
	end

	local ok, result = self:invokeRemote(RemoteNames.RequestPickupResource, resourceId)
	if ok and type(result) == "table" and result.ok == true then
		if self.pendingResourcePlacementId == resourceId then
			self.pendingResourcePlacementId = nil
		end
		self:setStatus("Treasure returned to your Vault.")
	else
		local errorText = type(result) == "table" and result.errorCode or result
		self:setStatus("Treasure pickup failed: " .. tostring(errorText))
	end
	return ok, result
end

function AppController:requestSellVaultItem(itemKind, itemId)
	local ok, result = self:invokeRemote(RemoteNames.RequestSellVaultItem, itemKind, itemId)
	if ok and type(result) == "table" and result.ok == true then
		local sale = result.sale
		local coins = type(sale) == "table" and sale.coins or nil
		if type(coins) == "number" then
			self:setStatus(string.format("Sold from Vault for %d coins.", math.floor(coins + 0.5)))
		else
			self:setStatus("Sold from Vault.")
		end
	else
		local errorText = type(result) == "table" and result.errorCode or result
		self:setStatus("Vault sale failed: " .. tostring(errorText))
	end
	return ok, result
end

function AppController:requestOpenReadyGeode(geodeInstanceId)
	local remoteName = if self:getRemote(RemoteNames.RequestCrackGeode) ~= nil
		then RemoteNames.RequestCrackGeode
		else RemoteNames.RequestClaimFinishedGeode
	local ok, result = self:invokeRemote(remoteName, geodeInstanceId)
	if ok and type(result) == "table" and result.ok == true then
		local openResult = result.open or result.claim
		local claimCount = if type(openResult) == "table" and type(openResult.claimedEntries) == "table" then #openResult.claimedEntries else nil
		if claimCount ~= nil and claimCount > 0 then
			self:setStatus(string.format("Opened %d ready geode%s.", claimCount, if claimCount == 1 then "" else "s"))
		else
			self:setStatus("Ready geode opened.")
		end
		self:showOpenResultCelebrations(openResult)
	else
		local errorText = type(result) == "table" and result.errorCode or result
		self:setStatus("Ready geode crack failed: " .. tostring(errorText))
	end
	return ok, result
end

function AppController:requestClaimFinishedGeodes()
	local ok, result = self:invokeRemote(RemoteNames.RequestClaimFinishedGeode)
	if ok and type(result) == "table" and result.ok == true then
		local openResult = result.open or result.claim
		local claimCount = if type(openResult) == "table" and type(openResult.claimedEntries) == "table" then #openResult.claimedEntries else nil
		if claimCount ~= nil and claimCount > 0 then
			self:setStatus(string.format("Opened %d ready geode%s.", claimCount, if claimCount == 1 then "" else "s"))
		else
			self:setStatus("Ready geode opened.")
		end
		self:showOpenResultCelebrations(openResult)
	else
		local errorText = type(result) == "table" and result.errorCode or result
		self:setStatus("Ready geode crack failed: " .. tostring(errorText))
	end
	return ok, result
end

function AppController:requestPlaceStarterStation()
	local ok, result = self:invokeRemote(RemoteNames.RequestPlaceStation)
	if ok and type(result) == "table" and result.ok == true then
		self:setStatus("Starter station placed.")
	else
		local errorText = type(result) == "table" and result.errorCode or result
		self:setStatus("Starter station placement failed: " .. tostring(errorText))
	end
	return ok, result
end

function AppController:requestClaimDailyReward()
	local ok, result = self:invokeRemote(RemoteNames.RequestClaimDailyReward)
	if ok and type(result) == "table" and result.ok == true then
		self:setStatus("Daily reward claim requested.")
	else
		local errorText = type(result) == "table" and result.errorCode or result
		self:setStatus("Daily reward claim failed: " .. tostring(errorText))
	end
	return ok, result
end

function AppController:requestCollectOfflineRewards()
	local ok, result = self:invokeRemote(RemoteNames.RequestCollectOfflineRewards)
	if ok and type(result) == "table" and result.ok == true then
		self:setStatus("Offline rewards claim requested.")
	else
		local errorText = type(result) == "table" and result.errorCode or result
		self:setStatus("Offline rewards claim failed: " .. tostring(errorText))
	end
	return ok, result
end

function AppController:connectRemoteEvents()
	local stateUpdated = self:getRemote(RemoteNames.StateUpdated)
	if stateUpdated ~= nil then
		stateUpdated.OnClientEvent:Connect(function(payload)
			self:applyPayload(payload, "remote_state")
		end)
	end

	local shopUpdated = self:getRemote(RemoteNames.ShopRotationUpdated)
	if shopUpdated ~= nil then
		shopUpdated.OnClientEvent:Connect(function(payload)
			self:applyPayload({ shop = payload }, "remote_shop")
		end)
	end

	local rareRevealAnnounced = self:getRemote(RemoteNames.RareRevealAnnounced)
	if rareRevealAnnounced ~= nil then
		rareRevealAnnounced.OnClientEvent:Connect(function(payload)
			local text = nil
			if type(payload) == "string" then
				text = payload
			elseif type(payload) == "table" then
				text = tostring(payload.message or payload.text or payload.title or "Crystal reveal spotted")
			end

			if text ~= nil then
				self:pushAnnouncement(text)
			end
		end)
	end
end

function AppController:syncInitialState()
	local initialStateRemote = self:getRemote(RemoteNames.GetInitialState)
	if initialStateRemote == nil then
		self.state.connectionMessage = "Server state endpoint unavailable. Showing local preview state."
		return
	end

	local ok, result = pcall(function()
		return initialStateRemote:InvokeServer()
	end)

	if ok and result ~= nil then
		self:applyPayload(result, "initial_sync")
		self.state.connectionMessage = "Connected to server."
	else
		self.state.connectionMessage = "Using local preview state."
	end
end

function AppController:resolveRemotes()
	local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 10)
	if remotesFolder == nil then
		self.remotes = {}
		return
	end

	local remotes = {}
	for remoteName, className in pairs(require(Shared.Net.Remotes).definitions) do
		local remote = remotesFolder:FindFirstChild(remoteName)
		if remote ~= nil and remote.ClassName == className then
			remotes[remoteName] = remote
		end
	end

	self.remotes = remotes
end

function AppController:start()
	if self._running then
		return
	end

	self._running = true
	self.context.screen = RootScreen.new(self.context)
	self.context.screen:setStatusText(self.state.connectionMessage)

	self:resolveRemotes()
	self:connectRemoteEvents()
	self:syncInitialState()

	for _, controller in ipairs(self.controllers) do
		if controller.start ~= nil then
			controller:start()
		end
	end

	self:emitState("bootstrap")

	task.spawn(function()
		while self._running do
			task.wait(1)
			self:emitState("tick")
		end
	end)

	print("[GemFactory] Client app started")
end

return AppController
