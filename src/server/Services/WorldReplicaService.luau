--!strict

local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Resources = require(Shared.Config.Resources)
local Stations = require(Shared.Config.Stations)
local World = require(Shared.Config.World)

local WorldReplicaService = {}
WorldReplicaService.__index = WorldReplicaService

local SHARED_FLOOR_NAME = "SharedFloor"
local PLOT_MARKER_FOLDER_NAME = "PlotMarkers"

local ROCK_VARIANTS = {
	{
		{ x = -28, z = -26, height = 10, radius = 3.5, yaw = 8 },
		{ x = 30, z = -18, height = 6, radius = 2.25, yaw = 28 },
		{ x = -18, z = 30, height = 8, radius = 2.75, yaw = -18 },
	},
	{
		{ x = 27, z = -28, height = 11, radius = 3.25, yaw = -12 },
		{ x = -31, z = 14, height = 7, radius = 2.5, yaw = 34 },
		{ x = 18, z = 29, height = 5, radius = 2.25, yaw = -24 },
	},
	{
		{ x = -30, z = -6, height = 9, radius = 3, yaw = 22 },
		{ x = 26, z = 24, height = 7, radius = 2.5, yaw = -30 },
		{ x = -8, z = 31, height = 5, radius = 2.25, yaw = 14 },
	},
	{
		{ x = 31, z = 8, height = 10, radius = 3.25, yaw = 16 },
		{ x = -25, z = -29, height = 6, radius = 2.5, yaw = -26 },
		{ x = 12, z = -31, height = 8, radius = 2.75, yaw = 10 },
	},
}

function WorldReplicaService.new(dependencies)
	return setmetatable({
		dependencies = dependencies or {},
		records = {},
		models = {},
		signatures = {},
		running = false,
	}, WorldReplicaService)
end

local function ensureWorldFolder()
	local worldFolder = Workspace:FindFirstChild(World.worldFolderName)
	if worldFolder == nil then
		worldFolder = Instance.new("Folder")
		worldFolder.Name = World.worldFolderName
		worldFolder.Parent = Workspace
	end

	local plotFolder = worldFolder:FindFirstChild(World.plotFolderName)
	if plotFolder == nil then
		plotFolder = Instance.new("Folder")
		plotFolder.Name = World.plotFolderName
		plotFolder.Parent = worldFolder
	end

	return worldFolder, plotFolder
end

local function clearChildren(container)
	for _, child in ipairs(container:GetChildren()) do
		child:Destroy()
	end
end

local function getPlotHalfSize()
	return World.plotBaseSize.width / 2, World.plotBaseSize.depth / 2
end

local function getSharedFloorSize()
	local sharedBaseplateSize = World.sharedBaseplateSize
	if sharedBaseplateSize ~= nil then
		return sharedBaseplateSize.width, sharedBaseplateSize.height, sharedBaseplateSize.depth
	end

	local padding = World.sharedFloorPadding or 32
	return
		(World.plotColumns * World.plotSpacing) + World.plotBaseSize.width + padding,
		2,
		(math.max(World.plotRows or 1, 1) * World.plotSpacing) + World.plotBaseSize.depth + padding
end

local function getResourceColor(resourceId, resourcesById)
	local resource = resourcesById[resourceId]
	local resourceDefinition = resource and Resources[resource.resourceTypeId] or nil
	if resourceDefinition ~= nil and resourceDefinition.color ~= nil then
		return resourceDefinition.color
	end

	local rarity = resourceDefinition and resourceDefinition.rarity or "Common"

	if rarity == "Legendary" then
		return Color3.fromRGB(255, 231, 135)
	elseif rarity == "Epic" then
		return Color3.fromRGB(164, 120, 255)
	elseif rarity == "Rare" then
		return Color3.fromRGB(93, 255, 195)
	elseif rarity == "Uncommon" then
		return Color3.fromRGB(185, 120, 255)
	end

	return Color3.fromRGB(240, 240, 255)
end

local function buildPlotSignature(plot, profile)
	local signatureParts = {
		tostring(plot.userId or "none"),
		tostring(plot.index or 0),
		tostring(profile and #profile.resourceOrder or 0),
	}

	if profile ~= nil then
		local stationParts = {}
		for stationId, station in pairs(profile.stationsById) do
			if station.placement ~= nil and station.placement.plotId == plot.id then
				local occupantParts = {}
				for _, resourceId in ipairs(station.occupantIds) do
					local resource = profile.resourcesById[resourceId]
					if resource ~= nil then
						table.insert(occupantParts, table.concat({
							resourceId,
							resource.resourceTypeId,
							tostring(resource.traitId or "none"),
						}, ":"))
					else
						table.insert(occupantParts, resourceId .. ":missing")
					end
				end

				table.insert(stationParts, table.concat({
					stationId,
					station.stationTypeId,
					tostring(station.placement.x),
					tostring(station.placement.y),
					tostring(station.level),
					table.concat(occupantParts, ","),
				}, ":"))
			end
		end

		table.sort(stationParts)
		table.insert(signatureParts, table.concat(stationParts, "|"))
	end

	return table.concat(signatureParts, "||")
end

local function createPart(parent, name, size, position, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = true
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material
	part.Parent = parent
	return part
end

local function createDecorPart(parent, name, size, position, color, material)
	local part = createPart(parent, name, size, position, color, material)
	part.CanCollide = false
	return part
end

local function buildSharedFloor(worldFolder)
	local width, height, depth = getSharedFloorSize()
	local floor = worldFolder:FindFirstChild(SHARED_FLOOR_NAME)
	if floor == nil then
		floor = createPart(
			worldFolder,
			SHARED_FLOOR_NAME,
			Vector3.new(width, height, depth),
			Vector3.new(World.plotOrigin.x, World.plotOrigin.y - 1.5, World.plotOrigin.z),
			Color3.fromRGB(26, 24, 34),
			Enum.Material.Slate
		)
	else
		floor.Size = Vector3.new(width, height, depth)
		floor.Position = Vector3.new(World.plotOrigin.x, World.plotOrigin.y - 1.5, World.plotOrigin.z)
		floor.Color = Color3.fromRGB(26, 24, 34)
		floor.Material = Enum.Material.Slate
	end

	local markers = worldFolder:FindFirstChild(PLOT_MARKER_FOLDER_NAME)
	if markers ~= nil then
		markers:Destroy()
	end

	markers = Instance.new("Folder")
	markers.Name = PLOT_MARKER_FOLDER_NAME
	markers.Parent = worldFolder

	return floor, markers
end

local function addPlotMarker(markerFolder, plot)
	local halfWidth, halfDepth = getPlotHalfSize()
	local markerHeight = World.plotMarkerHeight or 1
	local markerInset = 5
	local markerColor = Color3.fromRGB(56, 51, 73)
	local markerSizeX = Vector3.new(World.plotBaseSize.width - (markerInset * 2), markerHeight, 2)
	local markerSizeZ = Vector3.new(2, markerHeight, World.plotBaseSize.depth - (markerInset * 2))

	createDecorPart(
		markerFolder,
		plot.id .. "_NorthMarker",
		markerSizeX,
		Vector3.new(plot.position.x, plot.position.y + 0.65, plot.position.z - halfDepth + markerInset),
		markerColor,
		Enum.Material.Slate
	)
	createDecorPart(
		markerFolder,
		plot.id .. "_SouthMarker",
		markerSizeX,
		Vector3.new(plot.position.x, plot.position.y + 0.65, plot.position.z + halfDepth - markerInset),
		markerColor,
		Enum.Material.Slate
	)
	createDecorPart(
		markerFolder,
		plot.id .. "_WestMarker",
		markerSizeZ,
		Vector3.new(plot.position.x - halfWidth + markerInset, plot.position.y + 0.65, plot.position.z),
		markerColor,
		Enum.Material.Slate
	)
	createDecorPart(
		markerFolder,
		plot.id .. "_EastMarker",
		markerSizeZ,
		Vector3.new(plot.position.x + halfWidth - markerInset, plot.position.y + 0.65, plot.position.z),
		markerColor,
		Enum.Material.Slate
	)
end

local function ensureStaticWorld(worldFolder, plots)
	local floor = worldFolder:FindFirstChild(SHARED_FLOOR_NAME)
	local markers = worldFolder:FindFirstChild(PLOT_MARKER_FOLDER_NAME)
	if floor ~= nil and markers ~= nil then
		return
	end

	local _, markerFolder = buildSharedFloor(worldFolder)
	for _, plot in ipairs(plots) do
		addPlotMarker(markerFolder, plot)
	end
end

local function addPlotCornerCrystal(parent, name, position, color, height)
	local crystal = createDecorPart(
		parent,
		name,
		Vector3.new(2.5, height, 2.5),
		position,
		color,
		Enum.Material.Neon
	)
	crystal.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(15), math.rad(6))
	return crystal
end

local function addRockSpikes(parent, plot)
	local rockFolder = Instance.new("Folder")
	rockFolder.Name = "RockSpikes"
	rockFolder.Parent = parent

	local variant = ROCK_VARIANTS[((plot.index or 1) - 1) % #ROCK_VARIANTS + 1]
	local rockColor = Color3.fromRGB(37, 34, 46)
	local accentColors = {
		Color3.fromRGB(123, 242, 255),
		Color3.fromRGB(180, 146, 255),
		Color3.fromRGB(143, 255, 210),
	}

	for spikeIndex, spike in ipairs(variant) do
		local rockPosition = Vector3.new(
			plot.position.x + spike.x,
			plot.position.y + (spike.height / 2),
			plot.position.z + spike.z
		)
		local rock = createDecorPart(
			rockFolder,
			string.format("RockSpike_%d", spikeIndex),
			Vector3.new(spike.radius * 2, spike.height, spike.radius * 2),
			rockPosition,
			rockColor,
			Enum.Material.Slate
		)
		rock.CFrame = CFrame.new(rockPosition)
			* CFrame.Angles(math.rad(4), math.rad(spike.yaw), math.rad(8))

		local crystalPosition = rockPosition + Vector3.new(0.75, (spike.height / 2) + 1.5, -0.5)
		addPlotCornerCrystal(
			rockFolder,
			string.format("CrystalShard_%d", spikeIndex),
			crystalPosition,
			accentColors[((plot.index or 1) + spikeIndex - 1) % #accentColors + 1],
			math.max(3, spike.height * 0.45)
		)
	end
end

local function addAmbientCrystals(parent, plot)
	local halfWidth, halfDepth = getPlotHalfSize()
	addPlotCornerCrystal(
		parent,
		"RearCrystal",
		Vector3.new(plot.position.x - halfWidth + 8, plot.position.y + 3.5, plot.position.z - halfDepth + 10),
		Color3.fromRGB(110, 236, 255),
		7
	)
	addPlotCornerCrystal(
		parent,
		"SideCrystal",
		Vector3.new(plot.position.x + halfWidth - 10, plot.position.y + 4.5, plot.position.z + halfDepth - 12),
		Color3.fromRGB(186, 156, 255),
		9
	)
end

function WorldReplicaService:_getPlotModel(plotId)
	local _, plotFolder = ensureWorldFolder()
	local plotModel = plotFolder:FindFirstChild(plotId)
	if plotModel == nil then
		plotModel = Instance.new("Model")
		plotModel.Name = plotId
		plotModel.Parent = plotFolder
	end

	return plotModel
end

function WorldReplicaService:_buildPlot(plot, profile, signature)
	local plotModel = self:_getPlotModel(plot.id)
	clearChildren(plotModel)
	plotModel:SetAttribute("PlotId", plot.id)
	plotModel:SetAttribute("OwnerUserId", plot.userId)
	plotModel:SetAttribute("ResourceCount", profile and #profile.resourceOrder or 0)
	plotModel:SetAttribute("StationCount", profile and (function()
		local count = 0
		for _, station in pairs(profile.stationsById) do
			if station.placement ~= nil and station.placement.plotId == plot.id then
				count += 1
			end
		end
		return count
	end)() or 0)

	local base = createPart(
		plotModel,
		"PlotBase",
		Vector3.new(World.plotBaseSize.width, World.plotBaseSize.height, World.plotBaseSize.depth),
		Vector3.new(plot.position.x, plot.position.y, plot.position.z),
		Color3.fromRGB(45, 42, 59),
		Enum.Material.Slate
	)
	base.TopSurface = Enum.SurfaceType.Smooth

	local trim = createDecorPart(
		plotModel,
		"PlotTrim",
		Vector3.new(World.plotBaseSize.width - 6, 0.4, World.plotBaseSize.depth - 6),
		Vector3.new(plot.position.x, plot.position.y + 1.2, plot.position.z),
		Color3.fromRGB(58, 54, 78),
		Enum.Material.Rock
	)
	trim.Transparency = 0.1

	addAmbientCrystals(plotModel, plot)
	addRockSpikes(plotModel, plot)

	local stationFolder = Instance.new("Folder")
	stationFolder.Name = World.stationFolderName
	stationFolder.Parent = plotModel

	local cellSize = World.cellSize
	local gridOriginX = plot.position.x - ((World.plotGridWidth * cellSize) / 2) + (cellSize / 2)
	local gridOriginZ = plot.position.z - ((World.plotGridHeight * cellSize) / 2) + (cellSize / 2)
	for _, station in pairs(profile and profile.stationsById or {}) do
		if station.placement ~= nil and station.placement.plotId == plot.id then
			local stationDefinition = Stations[station.stationTypeId]
			if stationDefinition ~= nil then
				local stationPart = createPart(
					stationFolder,
					stationDefinition.displayName,
					Vector3.new(
						stationDefinition.gridSize.width * cellSize,
						4,
						stationDefinition.gridSize.height * cellSize
					),
					Vector3.new(
						gridOriginX + ((station.placement.x - 1) * cellSize) + (((stationDefinition.gridSize.width - 1) * cellSize) / 2),
						plot.position.y + 3,
						gridOriginZ + ((station.placement.y - 1) * cellSize) + (((stationDefinition.gridSize.height - 1) * cellSize) / 2)
					),
					stationDefinition.color or Color3.fromRGB(120, 180, 120),
					Enum.Material.Crystal
				)

				local occupantsFolder = Instance.new("Folder")
				occupantsFolder.Name = "DisplayedResources"
				occupantsFolder.Parent = stationPart

				for occupantIndex, resourceId in ipairs(station.occupantIds) do
					local displayPart = createDecorPart(
						occupantsFolder,
						resourceId,
						Vector3.new(1.5, 1.5, 1.5),
						stationPart.Position
							+ Vector3.new(
								(-stationPart.Size.X / 2) + 1.25 + (((occupantIndex - 1) % 3) * 1.75),
								3,
								(-stationPart.Size.Z / 2) + 1.25 + (math.floor((occupantIndex - 1) / 3) * 1.75)
							),
						getResourceColor(resourceId, profile and profile.resourcesById or {}),
						Enum.Material.Neon
					)
					displayPart.Shape = Enum.PartType.Ball
				end
			end
		end
	end

	self.models[plot.id] = plotModel
	self.signatures[plot.id] = signature
	self.records[plot.id] = {
		plotId = plot.id,
		userId = plot.userId,
		resourceCount = profile and #profile.resourceOrder or 0,
		stationCount = profile and (function()
			local count = 0
			for _, station in pairs(profile.stationsById) do
				if station.placement ~= nil and station.placement.plotId == plot.id then
					count += 1
				end
			end
			return count
		end)() or 0,
	}
end

function WorldReplicaService:syncAll()
	local plotService = self.dependencies.plotService
	local playerDataService = self.dependencies.playerDataService
	if plotService == nil or playerDataService == nil then
		return
	end

	local worldFolder = ensureWorldFolder()
	local plots = plotService:getAllPlots()
	ensureStaticWorld(worldFolder, plots)

	for _, plot in ipairs(plots) do
		if plot.userId ~= nil then
			local profile = playerDataService:getProfile(plot.userId)
			local signature = buildPlotSignature(plot, profile)
			if self.signatures[plot.id] ~= signature or self.models[plot.id] == nil then
				self:_buildPlot(plot, profile, signature)
			end
		elseif self.models[plot.id] ~= nil then
			self.models[plot.id]:Destroy()
			self.models[plot.id] = nil
			self.records[plot.id] = nil
			self.signatures[plot.id] = nil
		end
	end
end

function WorldReplicaService:syncPlot(plotId, profile)
	local plotService = self.dependencies.plotService
	if plotService == nil then
		return
	end

	local plot = plotService:getPlotById(plotId)
	if plot == nil then
		return
	end

	self:_buildPlot(plot, profile, buildPlotSignature(plot, profile))
end

function WorldReplicaService:clearPlot(plotId)
	self.records[plotId] = nil
	self.signatures[plotId] = nil
	local model = self.models[plotId]
	if model ~= nil then
		model:Destroy()
		self.models[plotId] = nil
	end
end

function WorldReplicaService:start()
	self.running = true
	self:syncAll()

	task.spawn(function()
		while self.running do
			self:syncAll()
			task.wait(1)
		end
	end)

	print("[GemFactory] WorldReplicaService ready")
end

return WorldReplicaService
