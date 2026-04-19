--!strict

-- Client controller for Geode Placement Ghost that coordinates UI, local input, and app-state updates for this slice.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Geodes = require(Shared.Config.Geodes)
local SizeRules = require(Shared.Domain.SizeRules)
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

local function createGhostPart(parent: Instance, name: string, size: Vector3, color: Color3, material: Enum.Material, transparency: number): BasePart
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Shape = Enum.PartType.Ball
	part.Size = size
	part.Color = color
	part.Material = material
	part.Transparency = transparency
	part.Parent = parent
	return part
end

function GeodePlacementGhost.new()
	local model = Instance.new("Model")
	model.Name = "GeodePlacementGhost"

	local shell = createGhostPart(model, "Shell", Vector3.new(4.5, 4.5, 4.5), Color3.fromRGB(205, 210, 224), Enum.Material.Slate, 0.62)
	local core = createGhostPart(model, "Core", Vector3.new(3.45, 3.45, 3.45), Color3.fromRGB(240, 240, 255), Enum.Material.Glass, 0.5)

	local gloss = createGhostPart(model, "Gloss", Vector3.new(4.66, 4.66, 4.66), Color3.fromRGB(228, 235, 255), Enum.Material.Glass, 0.78)
	local highlight = createGhostPart(model, "Highlight", Vector3.new(0.92, 0.92, 0.92), Color3.fromRGB(255, 255, 255), Enum.Material.Neon, 0.42)
	local crackGlow = createGhostPart(model, "CrackGlow", Vector3.new(0.34, 3.15, 0.42), Color3.fromRGB(255, 255, 255), Enum.Material.Neon, 0.7)

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

	model.PrimaryPart = shell

	return setmetatable({
		model = model,
		core = core,
		gloss = gloss,
		highlight = highlight,
		crackGlow = crackGlow,
		label = label,
		prompt = prompt,
		shell = shell,
		geodeTypeId = nil,
		sizeId = nil,
		sizeValue = nil,
		footprintWidth = 2,
		footprintHeight = 2,
		visible = false,
	}, GeodePlacementGhost)
end

function GeodePlacementGhost:setGeodeTypeId(geodeTypeId: string?, sizeId: string?, sizeValue: number?)
	if self.geodeTypeId == geodeTypeId and self.sizeId == sizeId and self.sizeValue == sizeValue then
		return
	end

	self.geodeTypeId = geodeTypeId
	self.sizeId = sizeId
	self.sizeValue = sizeValue

	local definition = getGeodeDefinition(geodeTypeId)
	local scaleValue = SizeRules.getScaleValue(sizeId, sizeValue)
	if definition ~= nil then
		self.footprintWidth = definition.gridSize and definition.gridSize.width or 2
		self.footprintHeight = definition.gridSize and definition.gridSize.height or 2
		self.core.Color = definition.displayColor or Color3.fromRGB(240, 240, 255)
		self.shell.Color = definition.displayColor or Color3.fromRGB(205, 210, 224)
		self.label.Text = string.format("%s %s", SizeRules.getDisplayName(sizeId, sizeValue), definition.displayName or "Geode")
	else
		self.footprintWidth = 2
		self.footprintHeight = 2
		self.core.Color = Color3.fromRGB(240, 240, 255)
		self.shell.Color = Color3.fromRGB(205, 210, 224)
		self.label.Text = "Geode"
	end

	self.shell.Size = Vector3.new(4.5, 4.5, 4.5) * scaleValue
	self.core.Size = Vector3.new(3.45, 3.45, 3.45) * scaleValue
	self.gloss.Size = Vector3.new(4.66, 4.66, 4.66) * scaleValue
	self.highlight.Size = Vector3.new(0.92, 0.92, 0.92) * scaleValue
	self.crackGlow.Size = Vector3.new(0.34, 3.15, 0.42) * scaleValue
	self.gloss.Color = Color3.fromRGB(228, 235, 255)
	self.highlight.Color = Color3.fromRGB(255, 255, 255)
	self.crackGlow.Color = self.core.Color:Lerp(Color3.fromRGB(255, 255, 255), 0.28)
	self.shell.Material = Enum.Material.Slate
	self.core.Material = Enum.Material.Glass
	self.gloss.Material = Enum.Material.Glass
	self.highlight.Material = Enum.Material.Neon
	self.crackGlow.Material = Enum.Material.Neon
	self.core.Position = self.shell.Position + Vector3.new(0, 0.12 * scaleValue, 0)
	self.gloss.Position = self.shell.Position
	self.highlight.Position = self.shell.Position + (Vector3.new(1.0, 1.0, -0.8) * scaleValue)
	self.crackGlow.CFrame = CFrame.new(self.shell.Position + (Vector3.new(0.08, 0.08, -0.18) * scaleValue)) * CFrame.Angles(math.rad(-10), math.rad(14), math.rad(4))
	self.prompt.StudsOffset = Vector3.new(0, 2.55 + scaleValue, 0)
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
		plotBase.Position.Y + (plotBase.Size.Y / 2) + (self.shell.Size.Y / 2),
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
