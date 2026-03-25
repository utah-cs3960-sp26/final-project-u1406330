--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local World = require(Shared.Config.World)

local PlotService = {}
PlotService.__index = PlotService

local function getPlotPosition(index)
	local plotOffset = World.plotOffsets[index]
	if plotOffset ~= nil then
		return {
			x = World.plotOrigin.x + plotOffset.x,
			y = World.plotOrigin.y,
			z = World.plotOrigin.z + plotOffset.z,
		}
	end

	local row = math.floor((index - 1) / World.plotColumns)
	local column = (index - 1) % World.plotColumns
	local horizontalStart = -(((World.plotColumns - 1) * World.plotSpacing) / 2)
	local verticalStart = -(((math.max(World.plotRows, 1) - 1) * World.plotSpacing) / 2)

	return {
		x = World.plotOrigin.x + horizontalStart + (column * World.plotSpacing),
		y = World.plotOrigin.y,
		z = World.plotOrigin.z + verticalStart + (row * World.plotSpacing),
	}
end

function PlotService.new(dependencies)
	local plots = {}
	local assignedByUserId = {}
	local assignedByPlotId = {}
	local plotsById = {}
	local totalPlots = math.min(World.plotCount, World.maxPlots)

	for index = 1, totalPlots do
		local plotId = "plot_" .. tostring(index)
		local position = getPlotPosition(index)

		plots[index] = {
			id = plotId,
			index = index,
			userId = nil,
			position = position,
		}
		plotsById[plotId] = plots[index]
	end

	return setmetatable({
		dependencies = dependencies or {},
		plots = plots,
		plotsById = plotsById,
		assignedByUserId = assignedByUserId,
		assignedByPlotId = assignedByPlotId,
	}, PlotService)
end

function PlotService:assignPlot(userId)
	local userKey = tostring(userId)
	local existingPlotId = self.assignedByUserId[userKey]
	if existingPlotId ~= nil then
		return existingPlotId
	end

	for _, plot in ipairs(self.plots) do
		if plot.userId == nil then
			plot.userId = userId
			self.assignedByUserId[userKey] = plot.id
			self.assignedByPlotId[plot.id] = plot
			return plot.id
		end
	end

	return nil, "plot_limit_reached"
end

function PlotService:releasePlot(userId)
	local userKey = tostring(userId)
	local plotId = self.assignedByUserId[userKey]
	if plotId == nil then
		return false, "plot_not_assigned"
	end

	local plot = self.assignedByPlotId[plotId]
	if plot ~= nil then
		plot.userId = nil
	end

	self.assignedByUserId[userKey] = nil
	self.assignedByPlotId[plotId] = nil
	return true
end

function PlotService:getPlotLimit()
	return #self.plots
end

function PlotService:getPlotById(plotId)
	return self.plotsById[plotId]
end

function PlotService:getPlotForUserId(userId)
	local plotId = self.assignedByUserId[tostring(userId)]
	if plotId == nil then
		return nil
	end

	return self.plotsById[plotId]
end

function PlotService:getAllPlots()
	return self.plots
end

function PlotService:getPlotWorldPosition(plotId)
	local plot = self:getPlotById(plotId)
	if plot == nil then
		return nil
	end

	return plot.position
end

function PlotService:start()
	print("[GemFactory] PlotService ready")
end

return PlotService

