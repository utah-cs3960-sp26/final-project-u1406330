--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local PlacementRules = require(Shared.Domain.PlacementRules)

return function()
	local occupancy = {
		["2:2"] = "existing",
	}

	local canPlaceOpen = select(1, PlacementRules.canPlace({ width = 4, height = 4 }, occupancy, 1, 1, 1, 1))
	local canPlaceOccupied, occupiedReason = PlacementRules.canPlace({ width = 4, height = 4 }, occupancy, 2, 2, 1, 1)
	local canPlaceOutOfBounds, boundsReason = PlacementRules.canPlace({ width = 4, height = 4 }, occupancy, 4, 4, 2, 1)
	local firstFit = PlacementRules.findFirstPlacement({ width = 3, height = 2 }, {
		["1:1"] = "filled",
		["2:1"] = "filled",
	}, 1, 1)
	local noFit, noFitReason = PlacementRules.findFirstPlacement({ width = 1, height = 1 }, {
		["1:1"] = "filled",
	}, 1, 1)

	assert(canPlaceOpen == true, "empty cell should be placeable")
	assert(canPlaceOccupied == false and occupiedReason == "occupied", "occupied cell should fail placement")
	assert(canPlaceOutOfBounds == false and boundsReason == "out_of_bounds", "placements outside the grid should fail")
	assert(#PlacementRules.getFootprintKeys(1, 1, 2, 2) == 4, "footprint should contain every occupied cell")
	assert(firstFit ~= nil and firstFit.x == 3 and firstFit.y == 1, "first fit should scan deterministically from top-left")
	assert(noFit == nil and noFitReason == "no_open_space", "missing space should report a clear reason")
end
