--!strict

-- Client controller for Resource Placement Ghost that coordinates UI, local input, and app-state updates for this slice.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Resources = require(Shared.Config.Resources)
local ResourceVisuals = require(Shared.Domain.ResourceVisuals)
local SizeRules = require(Shared.Domain.SizeRules)
local World = require(Shared.Config.World)

local ResourcePlacementGhost = {}
ResourcePlacementGhost.__index = ResourcePlacementGhost

local function getPreviewHeightOffset(rootPartHeight: number): number
	return (World.plotBaseSize.height / 2) + (rootPartHeight / 2)
end

local function getPlotBase(plotModel: Model): BasePart?
	local plotBase = plotModel:FindFirstChild("PlotBase")
	if plotBase ~= nil and plotBase:IsA("BasePart") then
		return plotBase
	end

	return nil
end

function ResourcePlacementGhost.new()
	local part = Instance.new("Part")
	part.Name = "ResourcePlacementGhost"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(3, 3, 3)
	part.Transparency = 0.55

	local prompt = Instance.new("BillboardGui")
	prompt.Name = "Label"
	prompt.AlwaysOnTop = true
	prompt.Size = UDim2.fromOffset(140, 24)
	prompt.StudsOffset = Vector3.new(0, 2.6, 0)
	prompt.Parent = part

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = "Treasure"
	label.TextColor3 = Color3.fromRGB(245, 247, 255)
	label.TextSize = 14
	label.TextWrapped = true
	label.Parent = prompt

	return setmetatable({
		part = part,
		label = label,
		resourceTypeId = nil,
		sizeId = nil,
		sizeValue = nil,
		footprintWidth = 1,
		footprintHeight = 1,
		visible = false,
	}, ResourcePlacementGhost)
end

function ResourcePlacementGhost:setResourceTypeId(resourceTypeId: string?, sizeId: string?, sizeValue: number?)
	if self.resourceTypeId == resourceTypeId and self.sizeId == sizeId and self.sizeValue == sizeValue then
		return
	end

	self.resourceTypeId = resourceTypeId
	self.sizeId = sizeId
	self.sizeValue = sizeValue
	local definition = if resourceTypeId ~= nil then Resources[resourceTypeId] else nil
	local rootSize = ResourceVisuals.getPlacedRootSize(sizeId, sizeValue)
	if definition ~= nil then
		self.footprintWidth = definition.gridSize and definition.gridSize.width or 1
		self.footprintHeight = definition.gridSize and definition.gridSize.height or 1
		self.part.Color = definition.color or Color3.fromRGB(240, 240, 255)
		self.label.Text = string.format("%s %s", SizeRules.getDisplayName(sizeId, sizeValue), definition.displayName or "Treasure")
	else
		self.footprintWidth = 1
		self.footprintHeight = 1
		self.part.Color = Color3.fromRGB(240, 240, 255)
		self.label.Text = "Treasure"
	end
	self.part.Size = rootSize
end

function ResourcePlacementGhost:getSnappedCell(plotModel: Model, hitPosition: Vector3): (number?, number?, Vector3?)
	local plotBase = getPlotBase(plotModel)
	if plotBase == nil then
		return nil, nil, nil
	end

	local maxX = World.plotGridWidth - self.footprintWidth + 1
	local maxY = World.plotGridHeight - self.footprintHeight + 1
	if maxX < 1 or maxY < 1 then
		return nil, nil, nil
	end

	local minX = plotBase.Position.X - ((World.plotGridWidth * World.cellSize) / 2)
	local minZ = plotBase.Position.Z - ((World.plotGridHeight * World.cellSize) / 2)
	local cellX = math.floor((hitPosition.X - minX) / World.cellSize) + 1
	local cellY = math.floor((hitPosition.Z - minZ) / World.cellSize) + 1

	if cellX < 1 or cellY < 1 or cellX > maxX or cellY > maxY then
		return nil, nil, nil
	end

	local gridOriginX = plotBase.Position.X - ((World.plotGridWidth * World.cellSize) / 2) + (World.cellSize / 2)
	local gridOriginZ = plotBase.Position.Z - ((World.plotGridHeight * World.cellSize) / 2) + (World.cellSize / 2)
	local worldPosition = Vector3.new(
		gridOriginX + ((cellX - 1) * World.cellSize) + (((self.footprintWidth - 1) * World.cellSize) / 2),
		plotBase.Position.Y + getPreviewHeightOffset(self.part.Size.Y),
		gridOriginZ + ((cellY - 1) * World.cellSize) + (((self.footprintHeight - 1) * World.cellSize) / 2)
	)

	return cellX, cellY, worldPosition
end

function ResourcePlacementGhost:showAt(plotModel: Model, hitPosition: Vector3): (number?, number?, Vector3?)
	local cellX, cellY, worldPosition = self:getSnappedCell(plotModel, hitPosition)
	if cellX == nil or cellY == nil or worldPosition == nil then
		self:hide()
		return nil, nil, nil
	end

	self.part.Parent = Workspace
	self.part.Position = worldPosition
	self.visible = true
	return cellX, cellY, worldPosition
end

function ResourcePlacementGhost:hide()
	if not self.visible then
		return
	end

	self.visible = false
	self.part.Parent = nil
end

function ResourcePlacementGhost:destroy()
	self.part:Destroy()
end

return ResourcePlacementGhost
