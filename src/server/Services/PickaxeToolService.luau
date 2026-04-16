--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Server = ServerScriptService:WaitForChild("Server")

local Pickaxes = require(Shared.Config.Pickaxes)
local PickaxeModelBuilder = require(Server.Util.PickaxeModelBuilder)

local PickaxeToolService = {}
PickaxeToolService.__index = PickaxeToolService

local function getPickaxeId(tool: Instance): string?
	if not tool:IsA("Tool") then
		return nil
	end

	local pickaxeId = tool:GetAttribute("PickaxeId") or tool:GetAttribute("PickaxeTypeId")
	if typeof(pickaxeId) ~= "string" or pickaxeId == "" then
		return nil
	end

	return pickaxeId
end

local function getContainer(player, containerName: string)
	local container = player[containerName]
	if container ~= nil then
		return container
	end

	local waitForChild = player.WaitForChild
	if type(waitForChild) == "function" then
		return player:WaitForChild(containerName)
	end

	return nil
end

local function collectOwnedPickaxes(profile)
	local owned = {}
	local ownedMap = {}
	local inventory = profile.inventory or {}
	local pickaxes = inventory.pickaxes or {}

	for _, pickaxeId in ipairs(Pickaxes.order) do
		if pickaxes[pickaxeId] == true then
			table.insert(owned, pickaxeId)
			ownedMap[pickaxeId] = true
		end
	end

	return owned, ownedMap
end

function PickaxeToolService.new(dependencies)
	return setmetatable({
		dependencies = dependencies or {},
		playerConnections = {},
		syncInProgress = {},
		syncQueued = {},
	}, PickaxeToolService)
end

function PickaxeToolService:createPickaxeTool(pickaxeId: string)
	local definition = Pickaxes.catalog[pickaxeId]
	local tool = Instance.new("Tool")
	tool.Name = if definition ~= nil then definition.displayName else pickaxeId
	tool.CanBeDropped = false
	tool.ToolTip = tool.Name
	tool:SetAttribute("GemFactoryPickaxeTool", true)
	tool:SetAttribute("PickaxeId", pickaxeId)
	tool:SetAttribute("PickaxeTypeId", pickaxeId)
	if definition ~= nil then
		tool:SetAttribute("PickaxeRarity", definition.rarity)
	end
	PickaxeModelBuilder.addHeldPickaxe(tool, definition)
	return tool
end

function PickaxeToolService:ensurePickaxeToolModel(tool: Tool, pickaxeId: string)
	local definition = Pickaxes.catalog[pickaxeId]
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	if
		tool:FindFirstChild("Handle") == nil
		or tool:GetAttribute("PickaxeModelVersion") ~= PickaxeModelBuilder.getModelVersion()
	then
		PickaxeModelBuilder.addHeldPickaxe(tool, definition)
	end
end

function PickaxeToolService:syncPlayerTools(player)
	local playerData = self.dependencies.playerData
	if playerData == nil then
		return
	end

	local profile = playerData:getProfile(player.UserId)
	if profile == nil then
		return
	end

	local backpack = getContainer(player, "Backpack")
	local starterGear = getContainer(player, "StarterGear")
	local character = player.Character
	if backpack == nil or starterGear == nil then
		return
	end

	local ownedPickaxes, ownedMap = collectOwnedPickaxes(profile)
	local equippedById = {}

	if character ~= nil then
		for _, child in ipairs(character:GetChildren()) do
			local pickaxeId = getPickaxeId(child)
			if pickaxeId ~= nil then
				if ownedMap[pickaxeId] ~= true or equippedById[pickaxeId] == true then
					child:Destroy()
				else
					self:ensurePickaxeToolModel(child :: Tool, pickaxeId)
					equippedById[pickaxeId] = true
				end
			end
		end
	end

	for _, container in ipairs({ starterGear, backpack }) do
		for _, child in ipairs(container:GetChildren()) do
			if getPickaxeId(child) ~= nil then
				child:Destroy()
			end
		end
	end

	for _, pickaxeId in ipairs(ownedPickaxes) do
		self:createPickaxeTool(pickaxeId).Parent = starterGear
		if equippedById[pickaxeId] ~= true then
			self:createPickaxeTool(pickaxeId).Parent = backpack
		end
	end
end

function PickaxeToolService:queuePlayerSync(player)
	local userId = player.UserId
	if self.syncInProgress[userId] then
		self.syncQueued[userId] = true
		return
	end

	self.syncInProgress[userId] = true
	task.spawn(function()
		local ok, errorMessage = pcall(function()
			self:syncPlayerTools(player)
		end)

		if not ok then
			warn("[GemFactory] PickaxeToolService sync failed:", errorMessage)
		end

		self.syncInProgress[userId] = nil
		if self.syncQueued[userId] then
			self.syncQueued[userId] = nil
			local refreshedPlayer = Players:GetPlayerByUserId(userId)
			if refreshedPlayer ~= nil then
				self:queuePlayerSync(refreshedPlayer)
			end
		end
	end)
end

function PickaxeToolService:syncPlayerByUserId(userId)
	local player = Players:GetPlayerByUserId(userId)
	if player ~= nil then
		self:queuePlayerSync(player)
	end
end

function PickaxeToolService:onPlayerAdded(player)
	local userId = player.UserId
	local existingConnection = self.playerConnections[userId]
	if existingConnection ~= nil then
		existingConnection:Disconnect()
	end

	self.playerConnections[userId] = player.CharacterAdded:Connect(function()
		self:queuePlayerSync(player)
	end)

	self:queuePlayerSync(player)
end

function PickaxeToolService:onPlayerRemoving(player)
	local userId = player.UserId
	local connection = self.playerConnections[userId]
	if connection ~= nil then
		connection:Disconnect()
		self.playerConnections[userId] = nil
	end

	self.syncInProgress[userId] = nil
	self.syncQueued[userId] = nil
end

function PickaxeToolService:start()
	Players.PlayerAdded:Connect(function(player)
		self:onPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:onPlayerRemoving(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:onPlayerAdded(player)
	end

	print("[GemFactory] PickaxeToolService ready")
end

return PickaxeToolService
