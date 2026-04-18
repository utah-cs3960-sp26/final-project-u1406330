--!strict

-- Server-authoritative service for Mock Persistence Service that validates requests and mutates gameplay state for this system.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local TableUtil = require(Shared.Util.TableUtil)

local MockPersistenceService = {}
MockPersistenceService.__index = MockPersistenceService

function MockPersistenceService.new()
	return setmetatable({
		store = {},
		seeds = {},
	}, MockPersistenceService)
end

function MockPersistenceService:load(userId)
	local userKey = tostring(userId)
	local stored = self.store[userKey]
	if stored ~= nil then
		return TableUtil.deepCopy(stored)
	end

	local seed = self.seeds[userKey]
	if seed ~= nil then
		return TableUtil.deepCopy(seed)
	end

	return nil
end

function MockPersistenceService:save(userId, profile)
	self.store[tostring(userId)] = TableUtil.deepCopy(profile)
end

function MockPersistenceService:seed(userId, profile)
	self.seeds[tostring(userId)] = TableUtil.deepCopy(profile)
end

function MockPersistenceService:reset()
	table.clear(self.store)
	table.clear(self.seeds)
end

function MockPersistenceService:start()
	print("[GemFactory] MockPersistenceService ready")
end

return MockPersistenceService

