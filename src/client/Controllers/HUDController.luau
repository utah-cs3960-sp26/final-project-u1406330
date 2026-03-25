--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Resources = require(Shared.Config.Resources)
local Stations = require(Shared.Config.Stations)
local Traits = require(Shared.Config.Traits)
local EconomyMath = require(Shared.Domain.EconomyMath)
local EconomyConfig = require(Shared.Config.Economy)
local Time = require(Shared.Util.Time)

local HUDController = {}
HUDController.__index = HUDController

local function countEntries(input)
	local count = 0
	for _ in pairs(input) do
		count += 1
	end
	return count
end

local function formatNumber(value: number): string
	local text = tostring(math.floor(value + 0.5))
	while true do
		local nextText = text:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		if nextText == text then
			break
		end
		text = nextText
	end
	return text
end

local function computePassiveRate(profile)
	local total = 0

	for _, resource in pairs(profile.resourcesById) do
		local resourceDefinition = Resources[resource.resourceTypeId]
		if resourceDefinition ~= nil and resource.stationId ~= nil then
			local traitDefinition = Traits[resource.traitId or "none"] or Traits.none
			local stationInstance = profile.stationsById[resource.stationId]
			local stationDefinition = stationInstance and Stations[stationInstance.stationTypeId] or nil
			local stationMultiplier = stationDefinition and stationDefinition.incomeMultiplier or 1
			local traitMultiplier = traitDefinition.multiplier or 1
			local prestigeMultiplier = EconomyMath.getPrestigeMultiplier(
				profile.progression.prestigeCount,
				EconomyConfig.prestigeStep,
				EconomyConfig.basePrestigeMultiplier
			)

			total += EconomyMath.getResourceIncome(
				resourceDefinition.baseCoinRate,
				traitMultiplier,
				stationMultiplier,
				prestigeMultiplier,
				1
			)
		end
	end

	return total
end

function HUDController.new(context)
	return setmetatable({
		context = context or {},
	}, HUDController)
end

function HUDController:start()
	local screen = self.context.screen
	local app = self.context.app

	local function refresh(state)
		local profile = state.profile
		local resourceCount = countEntries(profile.resourcesById)
		local stationCount = countEntries(profile.stationsById)
		local queueCount = #profile.geodeQueue
		local passiveRate = computePassiveRate(profile)
		local cavernValue = profile.currencies.coins + (resourceCount * 25) + (stationCount * 50) + (queueCount * 5)
		local plotId = profile.plotState.plotId or "Unassigned"

		screen:setStatusText(state.connectionMessage or "Ready")
		screen:setOverviewText(string.format(
			"Coins: %s\nPassive: %s / sec\nCavern Value: %s\nResources: %d\nStations: %d\nQueue: %d\nPlot: %s",
			formatNumber(profile.currencies.coins),
			formatNumber(passiveRate),
			formatNumber(cavernValue),
			resourceCount,
			stationCount,
			queueCount,
			plotId
		))
	end

	self.context.stateChanged:Connect(refresh)
	refresh(app:getState(), Time.nowUnix())
end

return HUDController


