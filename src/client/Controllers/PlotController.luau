--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local World = require(Shared.Config.World)

local PlotController = {}
PlotController.__index = PlotController

function PlotController.new(context)
	return setmetatable({
		context = context or {},
	}, PlotController)
end

function PlotController:start()
	local screen = self.context.screen
	local app = self.context.app

	local function refresh(state)
		local profile = state.profile
		local plotId = profile.plotState.plotId or "Unassigned"
		local occupiedCells = 0
		local onPlotGeodes = 0
		local storedGeodes = 0
		local inventoryGeodes = profile.inventory and profile.inventory.geodes or nil

		for _, geode in pairs(profile.geodesById) do
			if geode.placement ~= nil then
				onPlotGeodes += 1
			end
		end

		if type(inventoryGeodes) == "table" then
			for _, amount in pairs(inventoryGeodes) do
				if type(amount) == "number" and amount > 0 then
					storedGeodes += amount
				end
			end
		end

		if storedGeodes == 0 then
			for _, geode in pairs(profile.geodesById) do
				if geode.placement == nil then
					storedGeodes += 1
				end
			end
		end

		for _ in pairs(profile.plotState.gridOccupancy) do
			occupiedCells += 1
		end

		screen:setPlotText(string.format(
			"Cavern Lot: %s\nGrid: %d x %d\nOccupied Cells: %d\nGeodes on plot: %d\nGeodes in inventory: %d\nClick a ready geode on the plot to crack it open.\nUnlocked Zones: %d",
			plotId,
			World.plotGridWidth,
			World.plotGridHeight,
			occupiedCells,
			onPlotGeodes,
			storedGeodes,
			#profile.progression.unlockedZones
		))
	end

	self.context.stateChanged:Connect(refresh)
	refresh(app:getState())
end

return PlotController
