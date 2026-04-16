--!strict

local Players = game:GetService("Players")
local GeodeToolService = {}
GeodeToolService.__index = GeodeToolService

local function getGeodeInstanceId(tool: Instance): string?
	if not tool:IsA("Tool") then
		return nil
	end

	local geodeInstanceId = tool:GetAttribute("GeodeInstanceId")
	if typeof(geodeInstanceId) ~= "string" or geodeInstanceId == "" then
		return nil
	end

	return geodeInstanceId
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

function GeodeToolService.new(dependencies)
	return setmetatable({
		dependencies = dependencies or {},
		playerConnections = {},
		syncInProgress = {},
		syncQueued = {},
	}, GeodeToolService)
end

function GeodeToolService:syncPlayerTools(player)
	local backpack = getContainer(player, "Backpack")
	local starterGear = getContainer(player, "StarterGear")
	local character = player.Character
	if backpack == nil or starterGear == nil then
		return
	end

	if character ~= nil then
		for _, child in ipairs(character:GetChildren()) do
			local geodeInstanceId = getGeodeInstanceId(child)
			if geodeInstanceId ~= nil then
				child:Destroy()
			end
		end
	end

	for _, child in ipairs(starterGear:GetChildren()) do
		local geodeInstanceId = getGeodeInstanceId(child)
		if geodeInstanceId ~= nil then
			child:Destroy()
		end
	end

	for _, child in ipairs(backpack:GetChildren()) do
		local geodeInstanceId = getGeodeInstanceId(child)
		if geodeInstanceId ~= nil then
			child:Destroy()
		end
	end
end

function GeodeToolService:queuePlayerSync(player)
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
			warn("[GemFactory] GeodeToolService sync failed:", errorMessage)
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

function GeodeToolService:syncPlayerByUserId(userId)
	local player = Players:GetPlayerByUserId(userId)
	if player ~= nil then
		self:queuePlayerSync(player)
	end
end

function GeodeToolService:onPlayerAdded(player)
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

function GeodeToolService:onPlayerRemoving(player)
	local userId = player.UserId
	local connection = self.playerConnections[userId]
	if connection ~= nil then
		connection:Disconnect()
		self.playerConnections[userId] = nil
	end

	self.syncInProgress[userId] = nil
	self.syncQueued[userId] = nil
end

function GeodeToolService:start()
	Players.PlayerAdded:Connect(function(player)
		self:onPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:onPlayerRemoving(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:onPlayerAdded(player)
	end

	print("[GemFactory] GeodeToolService ready; geodes are stored in Vault")
end

return GeodeToolService
