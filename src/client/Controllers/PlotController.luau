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
		for _ in pairs(profile.plotState.gridOccupancy) do
			occupiedCells += 1
		end

		screen:setPlotText(string.format(
			"Cavern Lot: %s\nGrid: %d x %d\nOccupied Cells: %d\nUnlocked Zones: %d",
			plotId,
			World.plotGridWidth,
			World.plotGridHeight,
			occupiedCells,
			#profile.progression.unlockedZones
		))
	end

	self.context.stateChanged:Connect(refresh)
	refresh(app:getState())
end

return PlotController
