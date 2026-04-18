--!strict

-- Server-authoritative service for Mining Service that validates requests and mutates gameplay state for this system.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local MiningRewards = require(Shared.Domain.MiningRewards)
local PickaxeRules = require(Shared.Domain.PickaxeRules)
local Pickaxes = require(Shared.Config.Pickaxes)

local MiningService = {}
MiningService.__index = MiningService

local function getCurrencyAmount(profile, currency)
	if currency == "coins" then
		return profile.currencies.coins
	elseif currency == "gems" then
		return profile.currencies.gems
	elseif currency == "eventTokens" then
		return profile.currencies.eventTokens
	end

	return nil
end

local function spendCurrency(profile, currency, amount)
	if amount <= 0 then
		return true
	end

	if currency == "coins" then
		if profile.currencies.coins < amount then
			return false, "insufficient_coins"
		end
		profile.currencies.coins -= amount
		return true
	elseif currency == "gems" then
		if profile.currencies.gems < amount then
			return false, "insufficient_gems"
		end
		profile.currencies.gems -= amount
		return true
	elseif currency == "eventTokens" then
		if profile.currencies.eventTokens < amount then
			return false, "insufficient_tokens"
		end
		profile.currencies.eventTokens -= amount
		return true
	end

	return false, "unsupported_currency"
end

local function ensurePickaxeState(profile)
	profile.inventory.pickaxes = profile.inventory.pickaxes or {}
	profile.inventory.pickaxes, profile.progression.equippedPickaxeId = PickaxeRules.normalizeOwnedPickaxes(
		profile.inventory.pickaxes,
		profile.progression.equippedPickaxeId
	)
	return profile.progression.equippedPickaxeId
end

function MiningService.new(dependencies)
	return setmetatable({
		dependencies = dependencies or {},
		-- Cooldowns are tracked outside profiles so reconnecting or profile saves do not
		-- implicitly change the live input cadence enforced by the running server.
		lastMineAtByUserId = {},
	}, MiningService)
end

function MiningService:getPickaxeDefinition(pickaxeId: string?)
	if pickaxeId == nil then
		return nil
	end

	return Pickaxes.catalog[pickaxeId]
end

function MiningService:buyPickaxe(userId, pickaxeId)
	local playerData = self.dependencies.playerData
	local profile = playerData:getOrLoadProfile(userId)
	if profile == nil then
		return nil, "profile_not_loaded"
	end

	local pickaxeDefinition = self:getPickaxeDefinition(pickaxeId)
	if pickaxeDefinition == nil then
		return nil, "unknown_pickaxe"
	end

	local balance = getCurrencyAmount(profile, pickaxeDefinition.currency)
	if balance == nil then
		return nil, "unsupported_currency"
	end

	if balance < pickaxeDefinition.price then
		return nil, "insufficient_funds"
	end

	local result
	local _, mutateError = playerData:mutateProfile(userId, function(currentProfile)
		local currentPickaxeId = ensurePickaxeState(currentProfile)
		if currentProfile.inventory.pickaxes[pickaxeId] == true then
			return nil, "pickaxe_already_owned"
		end
		if not PickaxeRules.isStrictUpgrade(currentPickaxeId, pickaxeId) then
			return nil, "pickaxe_not_upgrade"
		end

		local spent, spendError = spendCurrency(currentProfile, pickaxeDefinition.currency, pickaxeDefinition.price)
		if not spent then
			return nil, spendError
		end

		currentProfile.inventory.pickaxes = {
			[pickaxeId] = true,
		}
		currentProfile.progression.equippedPickaxeId = pickaxeId

		result = {
			pickaxeId = pickaxeId,
			pickaxe = pickaxeDefinition,
			ownedPickaxes = currentProfile.inventory.pickaxes,
			equippedPickaxeId = pickaxeId,
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

function MiningService:equipPickaxe(userId, pickaxeId)
	local playerData = self.dependencies.playerData
	local result
	local _, mutateError = playerData:mutateProfile(userId, function(currentProfile)
		ensurePickaxeState(currentProfile)
		if Pickaxes.catalog[pickaxeId] == nil then
			return nil, "unknown_pickaxe"
		end
		if currentProfile.inventory.pickaxes[pickaxeId] ~= true then
			return nil, "pickaxe_not_owned"
		end

		currentProfile.progression.equippedPickaxeId = pickaxeId
		result = {
			pickaxeId = pickaxeId,
			pickaxe = Pickaxes.catalog[pickaxeId],
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

function MiningService:mine(userId, requestedPickaxeId, nowUnix, rng)
	local playerData = self.dependencies.playerData
	local geodeService = self.dependencies.geodeService
	local profile = playerData:getOrLoadProfile(userId)
	if profile == nil then
		return nil, "profile_not_loaded"
	end

	ensurePickaxeState(profile)

	local pickaxeId = requestedPickaxeId or profile.progression.equippedPickaxeId or "stone_pickaxe"
	local pickaxeDefinition = self:getPickaxeDefinition(pickaxeId)
	if pickaxeDefinition == nil then
		return nil, "unknown_pickaxe"
	end

	if profile.inventory.pickaxes[pickaxeId] ~= true then
		return nil, "pickaxe_not_owned"
	end

	local nowClock = os.clock()
	local lastMineAt = self.lastMineAtByUserId[userId]
	if lastMineAt ~= nil and nowClock - lastMineAt < pickaxeDefinition.cooldownSeconds then
		return nil, "mine_cooldown"
	end

	local result
	local _, mutateError = playerData:mutateProfile(userId, function(currentProfile)
		ensurePickaxeState(currentProfile)
		if currentProfile.inventory.pickaxes[pickaxeId] ~= true then
			return nil, "pickaxe_not_owned"
		end

		currentProfile.progression.equippedPickaxeId = pickaxeId
		-- The reward roll happens inside the profile mutation so the awarded state and the
		-- resulting inventory/currency changes are committed together or rejected together.
		local reward, rewardError = MiningRewards.rollReward(pickaxeDefinition, rng)
		if reward == nil then
			return nil, rewardError or "mine_roll_failed"
		end

		if reward.rewardType == "coins" then
			currentProfile.currencies.coins += reward.coins or 0
		elseif reward.rewardType == "geode" then
			if geodeService == nil then
				return nil, "geode_service_unavailable"
			end

			-- Geodes are created through GeodeService so size rolls, lifecycle timestamps, and
			-- instance bookkeeping stay centralized in one authoritative place.
			local geodeInstance, geodeError = geodeService:createGeodeInstance(currentProfile, reward.geodeId, nowUnix)
			if geodeInstance == nil then
				return nil, geodeError or "geode_create_failed"
			end
			reward.geodeInstance = geodeInstance
		else
			return nil, "unknown_reward"
		end

		result = {
			reward = reward,
			pickaxe = pickaxeDefinition,
			pickaxeId = pickaxeId,
		}
		return result
	end)

	if result ~= nil then
		self.lastMineAtByUserId[userId] = nowClock
		playerData:notifyProfileChanged(userId)
	end

	if result == nil and mutateError ~= nil then
		return nil, mutateError
	end

	return result
end

function MiningService:start()
	print("[GemFactory] MiningService ready")
end

return MiningService
