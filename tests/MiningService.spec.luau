--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Server = ServerScriptService:WaitForChild("Server")

local PlayerProfile = require(Shared.Types.PlayerProfile)
local MiningService = require(Server.Services.MiningService)
local GeodeService = require(Server.Services.GeodeService)

local function makeRng(numberRoll: number, integerRoll: number)
	local rng = {}

	function rng:NextNumber()
		return numberRoll
	end

	function rng:NextInteger(_minValue: number, maxValue: number)
		return math.clamp(integerRoll, 1, maxValue)
	end

	return rng
end

return function()
	local profile = PlayerProfile.new(100)
	local notifyCount = 0
	local playerData = {
		getProfile = function()
			return profile
		end,
		getOrLoadProfile = function()
			return profile
		end,
		mutateProfile = function(_, _, mutator)
			return mutator(profile)
		end,
		notifyProfileChanged = function()
			notifyCount += 1
		end,
	}
	local geodeService = GeodeService.new({
		playerData = playerData,
	})
	local miningService = MiningService.new({
		playerData = playerData,
		geodeService = geodeService,
	})

	assert(profile.inventory.pickaxes.stone_pickaxe == true, "new profiles should start with a stone pickaxe")

	local coinResult = miningService:mine(1, "stone_pickaxe", 100, makeRng(0.99, 6))
	assert(coinResult ~= nil, "stone pickaxe should mine successfully")
	assert(coinResult.reward.rewardType == "coins", "high chance roll should grant coins")
	assert(profile.currencies.coins > 250, "coin mining should mutate profile coins")

	local cooldownResult, cooldownError = miningService:mine(1, "stone_pickaxe", 100, makeRng(0.99, 6))
	assert(cooldownResult == nil and cooldownError == "mine_cooldown", "rapid repeated mining should be cooldown rejected")

	miningService.lastMineAtByUserId[1] = nil
	local geodeResult = miningService:mine(1, "stone_pickaxe", 101, makeRng(0.01, 1))
	assert(geodeResult ~= nil, "geode reward path should mine successfully")
	assert(geodeResult.reward.rewardType == "geode", "low chance roll should grant a geode")
	assert(#profile.geodeOrder == 1, "geode mining should create an owned geode instance")
	assert(profile.inventory.geodes.starter_geode == 1, "geode mining should increment geode inventory")

	local buyResult = miningService:buyPickaxe(1, "copper_pickaxe")
	assert(buyResult ~= nil, "buying an affordable pickaxe should succeed")
	assert(profile.inventory.pickaxes.copper_pickaxe == true, "buying should mark the pickaxe owned")
	assert(profile.progression.equippedPickaxeId == "copper_pickaxe", "buying should equip the new pickaxe")

	local duplicateResult, duplicateError = miningService:buyPickaxe(1, "copper_pickaxe")
	assert(duplicateResult == nil and duplicateError == "pickaxe_already_owned", "duplicate pickaxe purchases should be rejected")

	local equipResult = miningService:equipPickaxe(1, "stone_pickaxe")
	assert(equipResult ~= nil, "owned pickaxes should be equippable")
	assert(profile.progression.equippedPickaxeId == "stone_pickaxe", "equip should update profile state")
	assert(notifyCount >= 4, "successful mining and pickaxe changes should notify profile listeners")
end
