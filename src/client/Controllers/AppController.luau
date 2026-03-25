--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local TableUtil = require(Shared.Util.TableUtil)
local Time = require(Shared.Util.Time)
local Signal = require(Shared.Util.Signal)
local PlayerProfile = require(Shared.Types.PlayerProfile)
local Shops = require(Shared.Config.Shops)
local ShopRotation = require(Shared.Domain.ShopRotation)
local RemoteNames = require(Shared.Net.RemoteNames)

local RootScreen = require(script.Parent.Parent.UI.Screens.RootScreen)

local HUDController = require(script.Parent.HUDController)
local ShopController = require(script.Parent.ShopController)
local GeodeController = require(script.Parent.GeodeController)
local PlotController = require(script.Parent.PlotController)
local PlacementController = require(script.Parent.PlacementController)
local DailyRewardsController = require(script.Parent.DailyRewardsController)
local NotificationsController = require(script.Parent.NotificationsController)
local Palette = require(script.Parent.Parent.UI.Theme.Palette)

local AppController = {}
AppController.__index = AppController

local function buildHourlyShopState(nowUnix: number)
	local offers = Shops.hourlyRotation
	local starterOffer = Shops.starterOffers[1]
	local offerIndex = 1
	local currentOffer = nil
	local secondsRemaining = 0

	if #offers > 0 then
		offerIndex = ShopRotation.getHourlyIndex(nowUnix, #offers)
		currentOffer = TableUtil.deepCopy(offers[offerIndex])
		secondsRemaining = ShopRotation.getSecondsUntilNextRotation(nowUnix)
	end

	return {
		currentOffer = currentOffer,
		offerIndex = offerIndex,
		secondsRemaining = secondsRemaining,
		starterOffer = TableUtil.deepCopy(starterOffer),
	}
end

local function buildDefaultState(nowUnix: number)
	return {
		profile = PlayerProfile.new(nowUnix),
		shop = buildHourlyShopState(nowUnix),
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

	return shop
end

local function normalizeProfileState(currentProfile, payload, nowUnix)
	local profile = TableUtil.deepCopy(currentProfile)

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

	if payload.stationsById ~= nil then
		profile.stationsById = TableUtil.reconcile(profile.stationsById, payload.stationsById)
	end

	if payload.placedObjects ~= nil then
		profile.placedObjects = TableUtil.reconcile(profile.placedObjects, payload.placedObjects)
	end

	if payload.geodeQueue ~= nil then
		profile.geodeQueue = TableUtil.deepCopy(payload.geodeQueue)
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
		_running = false,
	}, AppController)

	context.app = self
	self.controllers = {
		HUDController.new(context),
		ShopController.new(context),
		GeodeController.new(context),
		PlotController.new(context),
		PlacementController.new(context),
		DailyRewardsController.new(context),
		NotificationsController.new(context),
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

function AppController:requestBuyStarterGeode()
	local ok, result = self:invokeRemote(RemoteNames.RequestBuyGeode, "starter_geode")
	if ok and type(result) == "table" and result.ok == true then
		self:setStatus("Starter geode purchase requested.")
	else
		local errorText = type(result) == "table" and result.errorCode or result
		self:setStatus("Starter geode purchase failed: " .. tostring(errorText))
	end
	return ok, result
end

function AppController:requestClaimFinishedGeodes()
	local ok, result = self:invokeRemote(RemoteNames.RequestClaimFinishedGeode)
	if ok and type(result) == "table" and result.ok == true then
		self:setStatus("Ready geodes claimed.")
	else
		local errorText = type(result) == "table" and result.errorCode or result
		self:setStatus("Ready geode claim failed: " .. tostring(errorText))
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


