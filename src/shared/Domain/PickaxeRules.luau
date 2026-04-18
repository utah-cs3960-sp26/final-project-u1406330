--!strict

-- Deterministic shared rules for Pickaxe Rules so gameplay behavior can be reused by the server, client presentation, and specs.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Pickaxes = require(Shared.Config.Pickaxes)

local PickaxeRules = {}

local tierIndexById = {}

for index, pickaxeId in ipairs(Pickaxes.order) do
	tierIndexById[pickaxeId] = index
end

function PickaxeRules.getTierIndex(pickaxeId: string?): number?
	if type(pickaxeId) ~= "string" or pickaxeId == "" then
		return nil
	end

	return tierIndexById[pickaxeId]
end

function PickaxeRules.getHighestOwnedPickaxeId(ownedPickaxes: { [string]: boolean }?, equippedPickaxeId: string?): string
	local highestOwnedPickaxeId = nil

	for _, pickaxeId in ipairs(Pickaxes.order) do
		if ownedPickaxes ~= nil and ownedPickaxes[pickaxeId] == true then
			highestOwnedPickaxeId = pickaxeId
		end
	end

	if highestOwnedPickaxeId == nil then
		local equippedTierIndex = PickaxeRules.getTierIndex(equippedPickaxeId)
		if equippedTierIndex ~= nil then
			return equippedPickaxeId :: string
		end
	end

	return highestOwnedPickaxeId or "stone_pickaxe"
end

function PickaxeRules.normalizeOwnedPickaxes(ownedPickaxes: { [string]: boolean }?, equippedPickaxeId: string?): ({ [string]: boolean }, string)
	local resolvedPickaxeId = PickaxeRules.getHighestOwnedPickaxeId(ownedPickaxes, equippedPickaxeId)
	return {
		[resolvedPickaxeId] = true,
	}, resolvedPickaxeId
end

function PickaxeRules.isStrictUpgrade(currentPickaxeId: string?, candidatePickaxeId: string?): boolean
	local currentTierIndex = PickaxeRules.getTierIndex(currentPickaxeId)
	local candidateTierIndex = PickaxeRules.getTierIndex(candidatePickaxeId)
	if candidateTierIndex == nil then
		return false
	end

	if currentTierIndex == nil then
		return true
	end

	return candidateTierIndex > currentTierIndex
end

return PickaxeRules
