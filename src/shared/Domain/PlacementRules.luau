--!strict

local PlacementRules = {}

local function cellKey(x: number, y: number)
	return tostring(x) .. ":" .. tostring(y)
end

function PlacementRules.canPlace(plotSize: { width: number, height: number }, occupancy: { [string]: string }, x: number, y: number, width: number, height: number)
	if width <= 0 or height <= 0 then
		return false, "invalid_size"
	end

	if x < 1 or y < 1 then
		return false, "out_of_bounds"
	end

	if x + width - 1 > plotSize.width or y + height - 1 > plotSize.height then
		return false, "out_of_bounds"
	end

	for dx = 0, width - 1 do
		for dy = 0, height - 1 do
			if occupancy[cellKey(x + dx, y + dy)] ~= nil then
				return false, "occupied"
			end
		end
	end

	return true, nil
end

function PlacementRules.clearFootprint(occupancy: { [string]: string }, placement: { x: number, y: number, width: number, height: number })
	for dx = 0, placement.width - 1 do
		for dy = 0, placement.height - 1 do
			local key = cellKey(placement.x + dx, placement.y + dy)
			occupancy[key] = nil
		end
	end
end

function PlacementRules.getFootprintKeys(x: number, y: number, width: number, height: number): { string }
	local keys = {}

	for dx = 0, width - 1 do
		for dy = 0, height - 1 do
			table.insert(keys, cellKey(x + dx, y + dy))
		end
	end

	return keys
end

function PlacementRules.findFirstPlacement(plotSize: { width: number, height: number }, occupancy: { [string]: string }, width: number, height: number)
	for y = 1, plotSize.height do
		for x = 1, plotSize.width do
			local canPlace = PlacementRules.canPlace(plotSize, occupancy, x, y, width, height)
			if canPlace then
				return {
					x = x,
					y = y,
				}
			end
		end
	end

	return nil, "no_open_space"
end

function PlacementRules.buildOccupancyKey(x: number, y: number)
	return cellKey(x, y)
end

function PlacementRules.getCenterCell(x: number, y: number, width: number, height: number)
	return x + ((width - 1) / 2), y + ((height - 1) / 2)
end

return PlacementRules
