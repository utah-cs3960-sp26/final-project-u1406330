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

local function getPreviewHeightOffset(baseHeight: number): number
	return (World.plotBaseSize.height / 2) + (baseHeight / 2)
end

local function getPlotBase(plotModel: Model): BasePart?
	local plotBase = plotModel:FindFirstChild("PlotBase")
	if plotBase ~= nil and plotBase:IsA("BasePart") then
		return plotBase
	end

	return nil
end

local function createGhostPart(parent: Instance, className: "Part" | "WedgePart", name: string, size: Vector3, color: Color3, material: Enum.Material, transparency: number): BasePart
	local part: BasePart = Instance.new(className)
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Size = size
	part.Color = color
	part.Material = material
	part.Transparency = transparency
	part.Parent = parent
	return part
end

local function blendColor(baseColor: Color3, targetColor: Color3, alpha: number): Color3
	return baseColor:Lerp(targetColor, alpha)
end

local function clearGhostGeometry(model: Model, root: BasePart)
	for _, child in ipairs(model:GetChildren()) do
		if child ~= root then
			child:Destroy()
		end
	end
end

local function addCrystalShard(parent: Instance, rootCFrame: CFrame, definition, scale: number, baseHeight: number, baseColor: Color3, glowColor: Color3, index: number)
	local height = definition.height * scale
	local width = definition.width * scale
	local depth = definition.depth * scale
	local shardColor = blendColor(baseColor, glowColor, definition.tint or 0.18)
	local shardCFrame = rootCFrame
		* CFrame.new((definition.x or 0) * scale, baseHeight + (height * 0.5), (definition.z or 0) * scale)
		* CFrame.Angles(math.rad(definition.pitch or 0), math.rad(definition.yaw or 0), math.rad(definition.roll or 0))

	local body = createGhostPart(parent, "Part", string.format("Shard_%d", index), Vector3.new(width, height, depth), shardColor, Enum.Material.Glass, 0.65)
	body.CFrame = shardCFrame

	local capHeight = math.max(0.16, height * 0.2)
	local cap = createGhostPart(
		parent,
		"WedgePart",
		string.format("ShardCap_%d", index),
		Vector3.new(width * 1.04, capHeight, depth * 1.06),
		blendColor(shardColor, glowColor, 0.28),
		Enum.Material.Glass,
		0.52
	)
	cap.CFrame = shardCFrame * CFrame.new(0, (height * 0.5) + (capHeight * 0.28), 0)
end

local function buildCrystalGhost(model: Model, profile)
	local rootCFrame = CFrame.new() * CFrame.Angles(0, math.rad((profile.hash % 360) - 180), 0)
	local baseSize = Vector3.new(2.1, 0.32, 1.64) * profile.scale
	local base = createGhostPart(
		model,
		"Part",
		"OreBase",
		baseSize,
		blendColor(profile.baseColor, Color3.fromRGB(28, 26, 34), 0.72),
		Enum.Material.Slate,
		0.48
	)
	base.CFrame = rootCFrame * CFrame.new(0, -0.42 * profile.scale, 0)

	for index, shard in ipairs(ResourceVisuals.getOreCrystalDefinitions(profile.variantId)) do
		addCrystalShard(model, rootCFrame, shard, profile.scale, -0.24 * profile.scale, profile.baseColor, profile.glowColor, index)
	end
end

local function buildIngotGhost(model: Model, profile)
	local rootCFrame = CFrame.new() * CFrame.Angles(0, math.rad((profile.hash % 360) - 180), 0)
	for index, shard in ipairs(ResourceVisuals.getOreCrystalDefinitions("ingot")) do
		local part = createGhostPart(
			model,
			"Part",
			string.format("Ingot_%d", index),
			Vector3.new(shard.width, shard.height, shard.depth) * profile.scale,
			blendColor(profile.baseColor, profile.glowColor, shard.tint or 0.15),
			if index == 1 then Enum.Material.Metal else Enum.Material.SmoothPlastic,
			if index == 1 then 0.5 else 0.58
		)
		part.CFrame = rootCFrame * CFrame.new((shard.x or 0) * profile.scale, ((shard.height or 0.5) * profile.scale * 0.5) - (0.32 * profile.scale), (shard.z or 0) * profile.scale)
	end
end

local function buildEldritchGhost(model: Model, profile)
	local rootCFrame = CFrame.new() * CFrame.Angles(0, math.rad((profile.hash % 360) - 180), 0)
	local core = createGhostPart(
		model,
		"Part",
		"EldritchCore",
		Vector3.new(1.12, 1.6, 1.12) * profile.scale,
		blendColor(profile.baseColor, profile.glowColor, 0.2),
		Enum.Material.Glass,
		0.62
	)
	core.CFrame = rootCFrame * CFrame.new(0, 0.46 * profile.scale, 0)

	local halo = createGhostPart(
		model,
		"Part",
		"EldritchHalo",
		Vector3.new(0.12, 1.6, 1.6) * profile.scale,
		blendColor(profile.accentColor, profile.glowColor, 0.28),
		Enum.Material.Neon,
		0.7
	)
	halo.Shape = Enum.PartType.Cylinder
	halo.CFrame = rootCFrame * CFrame.new(0, 0.86 * profile.scale, 0) * CFrame.Angles(0, 0, math.rad(90))

	for index, shard in ipairs(ResourceVisuals.getOreCrystalDefinitions("eldritch")) do
		addCrystalShard(model, rootCFrame, shard, profile.scale * 0.92, 0.02 * profile.scale, profile.baseColor, profile.glowColor, index)
	end
end

function ResourcePlacementGhost.new()
	local model = Instance.new("Model")
	model.Name = "ResourcePlacementGhost"

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.CastShadow = false
	root.Transparency = 1
	root.Size = Vector3.new(0.25, 0.25, 0.25)
	root.Parent = model

	local prompt = Instance.new("BillboardGui")
	prompt.Name = "Label"
	prompt.AlwaysOnTop = true
	prompt.Size = UDim2.fromOffset(140, 24)
	prompt.StudsOffset = Vector3.new(0, 2.6, 0)
	prompt.Parent = root

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
		model = model,
		root = root,
		prompt = prompt,
		label = label,
		resourceTypeId = nil,
		sizeId = nil,
		sizeValue = nil,
		baseHeight = ResourceVisuals.getPlacedBaseHeight(nil, nil),
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
	self.baseHeight = ResourceVisuals.getPlacedBaseHeight(sizeId, sizeValue)
	local profile = ResourceVisuals.resolveRevealProfile(resourceTypeId, nil, sizeId, sizeValue)
	if definition ~= nil then
		self.footprintWidth = definition.gridSize and definition.gridSize.width or 1
		self.footprintHeight = definition.gridSize and definition.gridSize.height or 1
		self.label.Text = string.format("%s %s", SizeRules.getDisplayName(sizeId, sizeValue), definition.displayName or "Treasure")
	else
		self.footprintWidth = 1
		self.footprintHeight = 1
		self.label.Text = "Treasure"
	end

	clearGhostGeometry(self.model, self.root)
	if profile.variantId == "ingot" then
		buildIngotGhost(self.model, profile)
	elseif profile.variantId == "eldritch" then
		buildEldritchGhost(self.model, profile)
	else
		buildCrystalGhost(self.model, profile)
	end

	self.root.Size = rootSize
	self.prompt.StudsOffset = Vector3.new(0, math.max(2.6, rootSize.Y + 1.2), 0)
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
		plotBase.Position.Y + getPreviewHeightOffset(self.baseHeight),
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

	self.model.Parent = Workspace
	self.model:PivotTo(CFrame.new(worldPosition))
	self.visible = true
	return cellX, cellY, worldPosition
end

function ResourcePlacementGhost:hide()
	if not self.visible then
		return
	end

	self.visible = false
	self.model.Parent = nil
end

function ResourcePlacementGhost:destroy()
	self.model:Destroy()
end

return ResourcePlacementGhost
