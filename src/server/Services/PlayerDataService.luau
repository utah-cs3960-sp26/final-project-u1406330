--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local PlayerProfile = require(Shared.Types.PlayerProfile)
local TableUtil = require(Shared.Util.TableUtil)
local Time = require(Shared.Util.Time)

local PlayerDataService = {}
PlayerDataService.__index = PlayerDataService

function PlayerDataService.new(persistenceService)
	return setmetatable({
		persistenceService = persistenceService,
		activeProfiles = {},
		services = nil,
		onProfileChanged = nil,
	}, PlayerDataService)
end

function PlayerDataService:createDefaultProfile()
	return PlayerProfile.new(Time.nowUnix())
end

function PlayerDataService:loadProfile(userId)
	local userKey = tostring(userId)
	local activeProfile = self.activeProfiles[userKey]
	if activeProfile ~= nil then
		return activeProfile
	end

	local savedProfile = self.persistenceService:load(userId)
	local nowUnix = Time.nowUnix()
	local profile = if savedProfile then PlayerProfile.reconcile(savedProfile, nowUnix) else PlayerProfile.new(nowUnix)
	self.activeProfiles[userKey] = profile
	return profile
end

function PlayerDataService:getProfile(userId)
	return self.activeProfiles[tostring(userId)]
end

function PlayerDataService:getOrLoadProfile(userId)
	return self:getProfile(userId) or self:loadProfile(userId)
end

function PlayerDataService:getActiveProfiles()
	return self.activeProfiles
end

function PlayerDataService:notifyProfileChanged(userId)
	if self.onProfileChanged ~= nil then
		self.onProfileChanged(userId)
	end
end

function PlayerDataService:mutateProfile(userId, mutator)
	local profile = self:getProfile(userId)
	if profile == nil then
		return nil, "profile_not_loaded"
	end

	local result = table.pack(mutator(profile))
	return table.unpack(result, 1, result.n)
end

function PlayerDataService:saveProfile(userId)
	local profile = self:getProfile(userId)
	if profile ~= nil then
		profile.meta.lastSavedAt = Time.nowUnix()
		self.persistenceService:save(userId, profile)
	end
end

function PlayerDataService:onPlayerAdded(player)
	local profile = self:loadProfile(player.UserId)
	local services = self.services

	if services ~= nil and services.plot ~= nil then
		local plotId = services.plot:assignPlot(player.UserId)
		if plotId ~= nil then
			for _, placement in pairs(profile.placedObjects) do
				placement.plotId = plotId
			end

			for _, station in pairs(profile.stationsById) do
				if station.placement ~= nil then
					station.placement.plotId = plotId
				end
			end

			profile.plotState.plotId = plotId
		end
	end

	if services ~= nil and services.offlineProgress ~= nil then
		local summary = services.offlineProgress:buildSummary(profile, Time.nowUnix())
		if summary ~= nil then
			profile.unclaimedOfflineRewards = summary
			profile.session.lastLogoutUnix = nil
		end
	end

	profile.session.lastPassiveTickUnix = Time.nowUnix()
	profile.session.passiveCoinRemainder = 0

	self:notifyProfileChanged(player.UserId)
end

function PlayerDataService:onPlayerRemoving(player)
	local profile = self:getProfile(player.UserId)
	if profile ~= nil then
		local nowUnix = Time.nowUnix()
		if self.services ~= nil and self.services.economy ~= nil then
			self.services.economy:flushPlayer(player.UserId, profile, nowUnix)
		end

		profile.session.lastLogoutUnix = nowUnix
		profile.session.lastPassiveTickUnix = nil
		profile.session.passiveCoinRemainder = 0
	end

	if self.services ~= nil and self.services.plot ~= nil then
		self.services.plot:releasePlot(player.UserId)
	end

	self:releaseProfile(player.UserId)
end

function PlayerDataService:releaseProfile(userId)
	self:saveProfile(userId)
	self.activeProfiles[tostring(userId)] = nil
end

function PlayerDataService:getPublicState(userId, nowUnix)
	local services = self.services
	local profile = self:getOrLoadProfile(userId)
	local currentUnix = nowUnix or Time.nowUnix()

	local publicProfile = TableUtil.deepCopy(profile)
	local shopState = nil
	local dailyState = nil
	local economyState = nil
	local geodeQueueState = nil

	if services ~= nil then
		if services.shop ~= nil then
			shopState = services.shop:getShopState(currentUnix)
		end

		if services.dailyRewards ~= nil then
			dailyState = services.dailyRewards:getClaimState(profile, currentUnix)
		end

		if services.economy ~= nil then
			economyState = services.economy:getEconomyState(profile)
		end

		if services.geodeQueue ~= nil then
			geodeQueueState = services.geodeQueue:getQueueState(profile, currentUnix)
		end
	end

	return {
		userId = userId,
		serverUnix = currentUnix,
		profile = publicProfile,
		economy = economyState,
		shop = shopState,
		dailyRewards = dailyState,
		geodeQueue = geodeQueueState,
		offlineRewards = TableUtil.deepCopy(profile.unclaimedOfflineRewards),
	}
end

function PlayerDataService:start(services)
	self.services = services
	Players.PlayerAdded:Connect(function(player)
		self:onPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:onPlayerRemoving(player)
	end)

	game:BindToClose(function()
		for _, player in ipairs(Players:GetPlayers()) do
			self:onPlayerRemoving(player)
		end
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:onPlayerAdded(player)
	end

	print("[GemFactory] PlayerDataService ready")
end

return PlayerDataService

