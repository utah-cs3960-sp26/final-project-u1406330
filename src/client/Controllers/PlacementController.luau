--!strict

-- Client controller for Placement Controller that coordinates UI, local input, and app-state updates for this slice.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Stations = require(Shared.Config.Stations)
local World = require(Shared.Config.World)

local PlacementController = {}
PlacementController.__index = PlacementController

function PlacementController.new(context)
	return setmetatable({
		context = context or {},
	}, PlacementController)
end

function PlacementController:start()
	local screen = self.context.screen
	local app = self.context.app
	local starterStation = Stations[World.starterStationTypeId]

	local function refresh(state)
		local plotId = state.profile.plotState.plotId or "Unassigned"
		local starterPlaced = false
		local placedStationCount = 0
		for _, station in pairs(state.profile.stationsById) do
			if station.placement ~= nil then
				placedStationCount += 1
				if station.stationTypeId == World.starterStationTypeId then
					starterPlaced = true
				end
			end
		end

		screen:setPlacementText(string.format(
			"Placement snaps to a %d x %d cavern grid.\nCurrent lot: %s\nPlaced stations: %d\nStarter station footprint: %dx%d",
			World.plotGridWidth,
			World.plotGridHeight,
			plotId,
			placedStationCount,
			starterStation and starterStation.gridSize.width or 0,
			starterStation and starterStation.gridSize.height or 0
		))

		screen:setPlaceStarterStationButton(
			not starterPlaced and plotId ~= "Unassigned",
			if starterPlaced then "Starter Station Placed" else "Place Starter Station"
		)
	end

	screen.buttons.placeStarterStation.Activated:Connect(function()
		app:requestPlaceStarterStation()
	end)

	self.context.stateChanged:Connect(refresh)
	refresh(app:getState())
end

return PlacementController

