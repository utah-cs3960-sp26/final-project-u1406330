--!strict

-- Spec coverage for Geode Tool Service to keep deterministic gameplay behavior and regressions easy to verify.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local PlayerProfile = require(Shared.Types.PlayerProfile)
local GeodeToolService = require(game:GetService("ServerScriptService").Server.Services.GeodeToolService)

local function createTool(name: string, geodeInstanceId: string?, geodeTypeId: string?)
	local tool = Instance.new("Tool")
	tool.Name = name
	tool.RequiresHandle = false
	if geodeInstanceId ~= nil then
		tool:SetAttribute("GeodeInstanceId", geodeInstanceId)
	end
	if geodeTypeId ~= nil then
		tool:SetAttribute("GeodeTypeId", geodeTypeId)
	end
	return tool
end

local function countGeodeTools(container)
	local count = 0
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Tool") and typeof(child:GetAttribute("GeodeInstanceId")) == "string" then
			count += 1
		end
	end
	return count
end

local function hasGeodeTool(container, geodeInstanceId: string)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Tool") and child:GetAttribute("GeodeInstanceId") == geodeInstanceId then
			return true
		end
	end

	return false
end

return function()
	local profile = PlayerProfile.new(100)
	profile.geodeOrder = { "geode_1", "geode_2", "geode_3" }
	profile.geodesById.geode_1 = {
		id = "geode_1",
		geodeTypeId = "starter_geode",
		status = "queued",
		startedAt = 100,
		endsAt = 110,
		obtainedAt = 100,
		placement = nil,
	}
	profile.geodesById.geode_2 = {
		id = "geode_2",
		geodeTypeId = "moonlit_geode",
		status = "queued",
		startedAt = 100,
		endsAt = 130,
		obtainedAt = 100,
		placement = {
			plotId = "plot_1",
			x = 1,
			y = 1,
			width = 2,
			height = 2,
		},
	}
	profile.geodesById.geode_3 = {
		id = "geode_3",
		geodeTypeId = "crystal_cavern_geode",
		status = "queued",
		startedAt = 100,
		endsAt = 120,
		obtainedAt = 100,
		placement = nil,
	}

	local backpack = Instance.new("Folder")
	backpack.Name = "Backpack"
	createTool("Starter Geode", "geode_1", "starter_geode").Parent = backpack
	createTool("Placed Geode", "geode_2", "moonlit_geode").Parent = backpack
	createTool("Duplicate Starter Geode", "geode_1", "starter_geode").Parent = backpack

	local starterGear = Instance.new("Folder")
	starterGear.Name = "StarterGear"
	createTool("Old Geode", "geode_2", "moonlit_geode").Parent = starterGear

	local character = Instance.new("Model")
	character.Name = "Character"
	createTool("Equipped Crystal Cavern Geode", "geode_3", "crystal_cavern_geode").Parent = character
	createTool("Opened Geode", "geode_2", "moonlit_geode").Parent = character

	local player = {
		UserId = 1,
		Backpack = backpack,
		StarterGear = starterGear,
		Character = character,
	}

	local service = GeodeToolService.new({
		playerData = {
			getProfile = function()
				return profile
			end,
		},
	})

	service:syncPlayerTools(player)

	assert(countGeodeTools(backpack) == 0, "vault geodes should not appear in the backpack")
	assert(hasGeodeTool(backpack, "geode_1") == false, "stored geodes should stay in the vault")
	assert(countGeodeTools(starterGear) == 0, "vault geodes should not mirror into starter gear")
	assert(#character:GetChildren() == 0, "equipped geode tools should be cleaned up")
	assert(hasGeodeTool(character, "geode_3") == false, "vault geodes should not stay equipped")

	profile.geodesById.geode_1.placement = {
		plotId = "plot_1",
		x = 2,
		y = 2,
		width = 2,
		height = 2,
	}
	service:syncPlayerTools(player)

	assert(countGeodeTools(backpack) == 0, "placing one geode should not create tools for another")
	assert(hasGeodeTool(backpack, "geode_3") == false, "remaining geodes should stay in the vault")
	assert(countGeodeTools(starterGear) == 0, "starter gear should remain clear of geodes")

	profile.geodesById.geode_3.placement = {
		plotId = "plot_1",
		x = 3,
		y = 3,
		width = 2,
		height = 2,
	}
	service:syncPlayerTools(player)

	assert(countGeodeTools(backpack) == 0, "placed geodes should be removed from the backpack")
	assert(countGeodeTools(starterGear) == 0, "placed geodes should be removed from starter gear")

	profile.geodeOrder = { "geode_1", "geode_3", "geode_4" }
	profile.geodesById.geode_4 = {
		id = "geode_4",
		geodeTypeId = "starter_geode",
		status = "queued",
		startedAt = 100,
		endsAt = 140,
		obtainedAt = 100,
		placement = nil,
	}
	service:syncPlayerTools(player)

	assert(hasGeodeTool(backpack, "geode_4") == false, "newly owned geodes should stay in the vault")
	assert(hasGeodeTool(starterGear, "geode_4") == false, "newly owned geodes should not mirror into starter gear")
end
