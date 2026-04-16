--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Geodes = require(Shared.Config.Geodes)
local World = require(Shared.Config.World)

local GeodePlacementGhost = {}
GeodePlacementGhost.__index = GeodePlacementGhost

local function getPlotBase(plotModel: Model): BasePart?
	local plotBase = plotModel:FindFirstChild("PlotBase")
	if plotBase ~= nil and plotBase:IsA("BasePart") then
		return plotBase
	end

	return nil
end

local function getGeodeDefinition(geodeTypeId: string?)
	if geodeTypeId == nil then
		return nil
	end

	return Geodes[geodeTypeId]
end

function GeodePlacementGhost.new()
	local model = Instance.new("Model")
	model.Name = "GeodePlacementGhost"

	local shell = Instance.new("Part")
	shell.Name = "Shell"
	shell.Anchored = true
	shell.CanCollide = false
	shell.CanQuery = false
	shell.CanTouch = false
	shell.CastShadow = false
	shell.Material = Enum.Material.SmoothPlastic
	shell.Shape = Enum.PartType.Ball
	shell.Size = Vector3.new(4.5, 4.5, 4.5)
	shell.Transparency = 0.7
	shell.Parent = model

	local core = Instance.new("Part")
	core.Name = "Core"
	core.Anchored = true
	core.CanCollide = false
	core.CanQuery = false
	core.CanTouch = false
	core.CastShadow = false
	core.Material = Enum.Material.Glass
	core.Shape = Enum.PartType.Ball
	core.Size = Vector3.new(3.2, 3.2, 3.2)
	core.Transparency = 0.55
	core.Parent = model

	local prompt = Instance.new("BillboardGui")
	prompt.Name = "Label"
	prompt.AlwaysOnTop = true
	prompt.Size = UDim2.fromOffset(140, 24)
	prompt.StudsOffset = Vector3.new(0, 3.5, 0)
	prompt.Parent = core

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = "Geode"
	label.TextColor3 = Color3.fromRGB(245, 247, 255)
	label.TextSize = 14
	label.TextWrapped = true
	label.Parent = prompt

	model.PrimaryPart = core

	return setmetatable({
		model = model,
		core = core,
		label = label,
		shell = shell,
		geodeTypeId = nil,
		footprintWidth = 2,
		footprintHeight = 2,
		visible = false,
	}, GeodePlacementGhost)
end

function GeodePlacementGhost:setGeodeTypeId(geodeTypeId: string?)
	if self.geodeTypeId == geodeTypeId then
		return
	end

	self.geodeTypeId = geodeTypeId

	local definition = getGeodeDefinition(geodeTypeId)
	if definition ~= nil then
		self.footprintWidth = definition.gridSize and definition.gridSize.width or 2
		self.footprintHeight = definition.gridSize and definition.gridSize.height or 2
		self.core.Color = definition.displayColor or Color3.fromRGB(240, 240, 255)
		self.shell.Color = definition.displayColor or Color3.fromRGB(205, 210, 224)
		self.label.Text = definition.displayName or "Geode"
	else
		self.footprintWidth = 2
		self.footprintHeight = 2
		self.core.Color = Color3.fromRGB(240, 240, 255)
		self.shell.Color = Color3.fromRGB(205, 210, 224)
		self.label.Text = "Geode"
	end
end

function GeodePlacementGhost:getSnappedCell(plotModel: Model, hitPosition: Vector3): (number?, number?, Vector3?)
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
		plotBase.Position.Y + 3.25,
		gridOriginZ + ((cellY - 1) * World.cellSize) + (((self.footprintHeight - 1) * World.cellSize) / 2)
	)

	return cellX, cellY, worldPosition
end

function GeodePlacementGhost:showAt(plotModel: Model, hitPosition: Vector3): (number?, number?, Vector3?)
	local cellX, cellY, worldPosition = self:getSnappedCell(plotModel, hitPosition)
	if cellX == nil or cellY == nil or worldPosition == nil then
		self:hide()
		return nil, nil, nil
	end

	self.model.Parent = Workspace
	self.model:PivotTo(CFrame.new(worldPosition))
	self.visible = true
	return cellX, cellY, worldPosition
end

function GeodePlacementGhost:hide()
	if not self.visible then
		return
	end

	self.visible = false
	self.model.Parent = nil
end

function GeodePlacementGhost:destroy()
	self.model:Destroy()
end

return GeodePlacementGhost

