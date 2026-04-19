--!strict

-- Server-authoritative service for World Replica Service that validates requests and mutates gameplay state for this system.

local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Geodes = require(Shared.Config.Geodes)
local Resources = require(Shared.Config.Resources)
local Traits = require(Shared.Config.Traits)
local GeodePresentation = require(Shared.Domain.GeodePresentation)
local ResourceVisuals = require(Shared.Domain.ResourceVisuals)
local SizeRules = require(Shared.Domain.SizeRules)
local WorldLabelPresentation = require(Shared.Domain.WorldLabelPresentation)
local Stations = require(Shared.Config.Stations)
local World = require(Shared.Config.World)

local WorldReplicaService = {}
WorldReplicaService.__index = WorldReplicaService

local SHARED_FLOOR_NAME = "SharedFloor"
local PLOT_MARKER_FOLDER_NAME = "PlotMarkers"
local SHOP_FRONT_NAME = "PickaxeShop"
local MINE_NAME = "GeodeMine"
local SHOP_PROMPT_ATTRIBUTE = "GemFactoryShopPrompt"
local MINE_TARGET_ATTRIBUTE = "GemFactoryMineTarget"
local MINE_ZONE_ATTRIBUTE = "GemFactoryMineZone"
local STATIC_WORLD_LAYOUT_VERSION = 3
local PLOT_SURFACE_COLLIDER_NAME = "PlotSurfaceCollider"
local REPLICA_TRANSPARENCY_ATTRIBUTE = "ReplicaTransparency"

local ROCK_VARIANTS = {
	{
		{ x = -28, z = -26, height = 10, radius = 3.5, yaw = 8 },
		{ x = 30, z = -18, height = 6, radius = 2.25, yaw = 28 },
		{ x = -18, z = 30, height = 8, radius = 2.75, yaw = -18 },
		{ x = 26, z = 28, height = 4, radius = 4.5, yaw = 14, kind = "boulder" },
		{ x = -32, z = 8, height = 3, radius = 5, yaw = -10, kind = "boulder" },
	},
	{
		{ x = 27, z = -28, height = 11, radius = 3.25, yaw = -12 },
		{ x = -31, z = 14, height = 7, radius = 2.5, yaw = 34 },
		{ x = 18, z = 29, height = 5, radius = 2.25, yaw = -24 },
		{ x = -24, z = -31, height = 4, radius = 4.75, yaw = 19, kind = "boulder" },
		{ x = 32, z = 10, height = 3, radius = 4.5, yaw = -24, kind = "boulder" },
	},
	{
		{ x = -30, z = -6, height = 9, radius = 3, yaw = 22 },
		{ x = 26, z = 24, height = 7, radius = 2.5, yaw = -30 },
		{ x = -8, z = 31, height = 5, radius = 2.25, yaw = 14 },
		{ x = -29, z = -29, height = 4, radius = 4.25, yaw = -18, kind = "boulder" },
		{ x = 30, z = -12, height = 3, radius = 4.75, yaw = 26, kind = "boulder" },
	},
	{
		{ x = 31, z = 8, height = 10, radius = 3.25, yaw = 16 },
		{ x = -25, z = -29, height = 6, radius = 2.5, yaw = -26 },
		{ x = 12, z = -31, height = 8, radius = 2.75, yaw = 10 },
		{ x = 28, z = 29, height = 4, radius = 4.5, yaw = -12, kind = "boulder" },
		{ x = -30, z = -4, height = 3, radius = 4.75, yaw = 20, kind = "boulder" },
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

local function getGeodeTint(geodeTypeId: string?, readyState: string)
	if geodeTypeId == "moonlit_geode" then
		return readyState == "ready" and Color3.fromRGB(148, 171, 255) or Color3.fromRGB(83, 95, 136)
	elseif geodeTypeId == "crystal_cavern_geode" then
		return readyState == "ready" and Color3.fromRGB(126, 208, 255) or Color3.fromRGB(74, 100, 122)
	end

	return readyState == "ready" and Color3.fromRGB(174, 191, 212) or Color3.fromRGB(92, 96, 104)
end

local function normalizeVisualKey(value)
	if value == nil then
		return ""
	end

	local text = string.lower(tostring(value))
	text = text:gsub("[%s%-]+", "_")
	text = text:gsub("[^%w_]", "")
	return text
end

local function titleCaseLabel(value)
	local source = tostring(value or "")
	source = source:gsub("_", " ")
	source = source:gsub("%-", " ")

	local words = {}
	for word in source:gmatch("%S+") do
		local firstLetter = word:sub(1, 1)
		local rest = word:sub(2)
		table.insert(words, string.upper(firstLetter) .. string.lower(rest))
	end

	return table.concat(words, " ")
end

local function getStringHash(value)
	return ResourceVisuals.getStringHash(value)
end

local function blendColor(baseColor, targetColor, alpha)
	return baseColor:Lerp(targetColor, alpha)
end

local RESOURCE_RARITY_ORDER = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
}

local RESOURCE_RARITY_ACCENTS = {
	Common = Color3.fromRGB(244, 249, 255),
	Uncommon = Color3.fromRGB(188, 145, 255),
	Rare = Color3.fromRGB(108, 228, 193),
	Epic = Color3.fromRGB(118, 213, 255),
	Legendary = Color3.fromRGB(255, 224, 117),
}

local RESOURCE_TYPE_VARIANTS = {
	quartz = "gemstone",
	amethyst = "gemstone",
	emerald_cluster = "cluster",
	diamond_core = "artifact",
	star_shard = "artifact",
}

local TRAIT_EFFECT_PRESETS = {
	{
		keywords = { "fiery", "fire", "ember", "blaze", "burn" },
		accent = Color3.fromRGB(255, 123, 56),
		accent2 = Color3.fromRGB(255, 214, 92),
		particleTexture = "rbxasset://textures/particles/fire_main.dds",
		beam = false,
		lightBoost = 1.1,
	},
	{
		keywords = { "icy", "frost", "freeze", "glacial", "snow" },
		accent = Color3.fromRGB(138, 226, 255),
		accent2 = Color3.fromRGB(236, 250, 255),
		particleTexture = "rbxasset://textures/particles/sparkles_main.dds",
		beam = false,
		lightBoost = 0.95,
	},
	{
		keywords = { "prismatic", "prism", "rainbow" },
		accent = Color3.fromRGB(255, 126, 180),
		accent2 = Color3.fromRGB(120, 220, 255),
		particleTexture = "rbxasset://textures/particles/sparkles_main.dds",
		beam = true,
		lightBoost = 1.15,
	},
	{
		keywords = { "celestial", "star", "lunar", "astral" },
		accent = Color3.fromRGB(255, 236, 160),
		accent2 = Color3.fromRGB(174, 220, 255),
		particleTexture = "rbxasset://textures/particles/sparkles_main.dds",
		beam = true,
		lightBoost = 1.2,
	},
	{
		keywords = { "radiant", "glow", "sun", "luminous" },
		accent = Color3.fromRGB(255, 221, 118),
		accent2 = Color3.fromRGB(255, 248, 216),
		particleTexture = "rbxasset://textures/particles/sparkles_main.dds",
		beam = true,
		lightBoost = 1.15,
	},
	{
		keywords = { "void", "abyss", "shadow", "night" },
		accent = Color3.fromRGB(104, 92, 188),
		accent2 = Color3.fromRGB(58, 54, 88),
		particleTexture = "rbxasset://textures/particles/smoke_main.dds",
		beam = true,
		lightBoost = 0.75,
	},
	{
		keywords = { "verdant", "nature", "leaf", "growth" },
		accent = Color3.fromRGB(128, 231, 146),
		accent2 = Color3.fromRGB(218, 255, 188),
		particleTexture = "rbxasset://textures/particles/sparkles_main.dds",
		beam = false,
		lightBoost = 1.0,
	},
	{
		keywords = { "storm", "thunder", "electric", "arcane" },
		accent = Color3.fromRGB(108, 194, 255),
		accent2 = Color3.fromRGB(255, 255, 255),
		particleTexture = "rbxasset://textures/particles/sparkles_main.dds",
		beam = true,
		lightBoost = 1.05,
	},
}

local function getRarityRank(rarity)
	return RESOURCE_RARITY_ORDER[rarity or "Common"] or 1
end

local function getResourceRarityScale(rarity)
	local rarityRank = getRarityRank(rarity)
	return 0.92 + ((rarityRank - 1) * 0.14)
end

local function getResourceRarityAccent(rarity, baseColor)
	local rarityAccent = RESOURCE_RARITY_ACCENTS[rarity or "Common"] or baseColor
	return baseColor:Lerp(rarityAccent, math.clamp(0.15 + (getRarityRank(rarity) * 0.12), 0, 0.65))
end

local function resolveTraitDisplayName(traitId)
	if traitId == nil or traitId == "none" then
		return nil
	end

	local traitDefinition = Traits[traitId]
	if traitDefinition ~= nil and traitDefinition.displayName ~= nil then
		return traitDefinition.displayName
	end

	return titleCaseLabel(traitId)
end

local function resolveTraitPreset(traitId)
	local normalizedTraitId = normalizeVisualKey(traitId)
	if normalizedTraitId == "" or normalizedTraitId == "none" then
		return nil
	end

	for _, preset in ipairs(TRAIT_EFFECT_PRESETS) do
		for _, keyword in ipairs(preset.keywords) do
			if string.find(normalizedTraitId, keyword, 1, true) ~= nil then
				return preset
			end
		end
	end

	return nil
end

local getResourceVariantShape

local function resolveResourceVisualProfile(resourceTypeId, resourceDefinition, sizeId, sizeValue)
	local profile = ResourceVisuals.resolveRevealProfile(resourceTypeId, nil, sizeId, sizeValue)
	profile.sizeDisplayName = SizeRules.getDisplayName(sizeId, sizeValue)
	return profile
end

local function createVisualBasePart(parent, className, name, size, position, color, material)
	local part = Instance.new(className)
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material
	part:SetAttribute(REPLICA_TRANSPARENCY_ATTRIBUTE, 0)
	part.Parent = parent
	return part
end

local function setReplicaTransparency(part: BasePart, transparency: number)
	part.Transparency = transparency
	part:SetAttribute(REPLICA_TRANSPARENCY_ATTRIBUTE, transparency)
end

local function reapplyReplicaTransparency(resourcePart: BasePart)
	for _, descendant in ipairs(resourcePart:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local transparencyValue = descendant:GetAttribute(REPLICA_TRANSPARENCY_ATTRIBUTE)
			if type(transparencyValue) == "number" then
				descendant.Transparency = transparencyValue
			end
		end
	end

	local rootTransparencyValue = resourcePart:GetAttribute(REPLICA_TRANSPARENCY_ATTRIBUTE)
	if type(rootTransparencyValue) == "number" then
		resourcePart.Transparency = rootTransparencyValue
	end
end

local function orientPart(part, yawRadians, pitchRadians, rollRadians)
	part.CFrame = CFrame.new(part.Position) * CFrame.Angles(pitchRadians or 0, yawRadians or 0, rollRadians or 0)
end

local function createColoredLight(parent, color, brightness, range)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Shadows = false
	light.Parent = parent
	return light
end

local function createSparkEmitter(parent, texture, colorA, colorB, rate, lifetimeMin, lifetimeMax, speedMin, speedMax, sizeStart, sizeEnd)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = texture
	emitter.Color = ColorSequence.new(colorA, colorB)
	emitter.LightEmission = 1
	emitter.Rate = rate
	emitter.Lifetime = NumberRange.new(lifetimeMin, lifetimeMax)
	emitter.Speed = NumberRange.new(speedMin, speedMax)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, sizeStart),
		NumberSequenceKeypoint.new(1, sizeEnd),
	})
	emitter.Transparency = NumberSequence.new(0.05, 1)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Drag = 1
	emitter.Parent = parent
	return emitter
end

local function createHoverQueryablePart(part: BasePart)
	part.CanQuery = true
	part.CanTouch = false
	part.CanCollide = false
end

local function createResourceBillboard(parentPart, titleText, subtitleText, accentColor, rarityRank)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = parentPart.Name .. "_Marker"
	billboard.Size = UDim2.fromOffset(188 + (rarityRank * 4), 54 + (rarityRank > 3 and 6 or 0))
	billboard.StudsOffset = Vector3.new(0, 2.8 + (rarityRank * 0.08), 0)
	billboard.AlwaysOnTop = true
	billboard.Enabled = false
	billboard.Parent = parentPart

	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Color3.fromRGB(30, 26, 40)
	frame.BackgroundTransparency = 0.12
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = billboard

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 8)
	frameCorner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = accentColor
	stroke.Thickness = 2
	stroke.Transparency = 0.05
	stroke.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 0)
	layout.Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.LayoutOrder = 1
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.new(1, 0, 0, 26)
	titleLabel.Font = Enum.Font.FredokaOne
	titleLabel.Text = titleText
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextStrokeColor3 = Color3.fromRGB(22, 18, 30)
	titleLabel.TextStrokeTransparency = 0.55
	titleLabel.TextScaled = true
	titleLabel.TextWrapped = true
	titleLabel.Parent = frame

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.LayoutOrder = 2
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Size = UDim2.new(1, 0, 0, 16)
	subtitleLabel.Font = Enum.Font.FredokaOne
	subtitleLabel.Text = subtitleText
	subtitleLabel.TextColor3 = accentColor
	subtitleLabel.TextStrokeColor3 = Color3.fromRGB(22, 18, 30)
	subtitleLabel.TextStrokeTransparency = 0.7
	subtitleLabel.TextScaled = true
	subtitleLabel.TextWrapped = true
	subtitleLabel.Parent = frame

	return billboard
end

local function createRarityEffects(parentPart, profile, visualVariantId)
	if profile.rarityRank <= 1 then
		return
	end

	local glowAttachment = Instance.new("Attachment")
	glowAttachment.Name = "RarityGlowAttachment"
	glowAttachment.Position = Vector3.new(0, parentPart.Size.Y * 0.35, 0)
	glowAttachment.Parent = parentPart

	createColoredLight(
		parentPart,
		profile.glowColor,
		0.55 + (profile.rarityRank * 0.18),
		5.5 + (profile.rarityRank * 1.4)
	)

	local sparkleRate = 2 + (profile.rarityRank * 3)
	if visualVariantId == "artifact" then
		sparkleRate += 2
	end

	createSparkEmitter(
		glowAttachment,
		"rbxasset://textures/particles/sparkles_main.dds",
		profile.accentColor,
		profile.glowColor,
		sparkleRate,
		0.75,
		1.35,
		0.4,
		1.0 + (profile.rarityRank * 0.18),
		0.22,
		0
	)

	if profile.rarityRank >= 3 then
		local leftAttachment = Instance.new("Attachment")
		leftAttachment.Name = "RarityBeamLeft"
		leftAttachment.Position = Vector3.new(parentPart.Size.X * 0.45, 0, 0)
		leftAttachment.Parent = parentPart

		local rightAttachment = Instance.new("Attachment")
		rightAttachment.Name = "RarityBeamRight"
		rightAttachment.Position = Vector3.new(-parentPart.Size.X * 0.45, 0, 0)
		rightAttachment.Parent = parentPart

		local beam = Instance.new("Beam")
		beam.Attachment0 = leftAttachment
		beam.Attachment1 = rightAttachment
		beam.Color = ColorSequence.new(profile.accentColor, profile.glowColor)
		beam.FaceCamera = true
		beam.LightEmission = 1
		beam.Width0 = 0.08 + (profile.rarityRank * 0.02)
		beam.Width1 = 0.12 + (profile.rarityRank * 0.02)
		beam.Transparency = NumberSequence.new(0.15, 0.9)
		beam.Parent = parentPart
	end
end

local function applyTraitEffects(parentPart, profile, traitId)
	local preset = resolveTraitPreset(traitId)
	if preset == nil then
		return resolveTraitDisplayName(traitId)
	end

	local traitDisplayName = resolveTraitDisplayName(traitId)
	local aura = Instance.new("Highlight")
	aura.Name = "TraitAura"
	aura.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	aura.FillColor = blendColor(profile.baseColor, preset.accent, 0.52)
	aura.FillTransparency = 0.78
	aura.OutlineColor = blendColor(preset.accent2, Color3.fromRGB(255, 255, 255), 0.18)
	aura.OutlineTransparency = 0.16
	aura.Parent = parentPart

	local effectAttachment = Instance.new("Attachment")
	effectAttachment.Name = "TraitEffectAttachment"
	effectAttachment.Position = Vector3.new(0, parentPart.Size.Y * 0.18, 0)
	effectAttachment.Parent = parentPart

	local lightBoost = preset.lightBoost or 1
	createColoredLight(
		parentPart,
		preset.accent2,
		0.45 + (profile.rarityRank * 0.12 * lightBoost),
		4.5 + (profile.rarityRank * 1.1)
	)

	createSparkEmitter(
		effectAttachment,
		preset.particleTexture,
		preset.accent,
		preset.accent2,
		5 + (profile.rarityRank * 3),
		0.82,
		1.24,
		0.3,
		1.05 + (profile.rarityRank * 0.18),
		0.26,
		0
	)

	local traitBand = createVisualBasePart(
		parentPart,
		"Part",
		"TraitBand",
		Vector3.new(parentPart.Size.X * 1.08, math.max(0.18, parentPart.Size.Y * 0.18), parentPart.Size.Z * 1.08),
		parentPart.Position,
		blendColor(preset.accent, preset.accent2, 0.38),
		Enum.Material.Neon
	)
	traitBand.Shape = Enum.PartType.Cylinder
	traitBand.CFrame = CFrame.new(parentPart.Position + Vector3.new(0, parentPart.Size.Y * 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	traitBand.Transparency = 0.52

	local crest = createVisualBasePart(
		parentPart,
		"Part",
		"TraitCrest",
		Vector3.new(parentPart.Size.X * 0.18, parentPart.Size.Y * 0.92, parentPart.Size.Z * 0.18),
		parentPart.Position,
		blendColor(preset.accent2, Color3.fromRGB(255, 255, 255), 0.2),
		Enum.Material.Neon
	)
	crest.CFrame = CFrame.new(parentPart.Position + Vector3.new(0, parentPart.Size.Y * 0.42, -parentPart.Size.Z * 0.18))
		* CFrame.Angles(math.rad(-12), 0, math.rad(8))
	crest.Transparency = 0.36

	if normalizeVisualKey(traitId):find("fiery", 1, true) ~= nil or normalizeVisualKey(traitId):find("fire", 1, true) ~= nil then
		createSparkEmitter(
			effectAttachment,
			"rbxasset://textures/particles/fire_main.dds",
			Color3.fromRGB(255, 160, 72),
			Color3.fromRGB(255, 230, 120),
			5 + profile.rarityRank,
			0.45,
			0.9,
			0.35,
			1.15,
			0.2,
			0
		)
	end

	if preset.beam then
		local forwardAttachment = Instance.new("Attachment")
		forwardAttachment.Name = "TraitBeamForward"
		forwardAttachment.Position = Vector3.new(0, 0, parentPart.Size.Z * 0.42)
		forwardAttachment.Parent = parentPart

		local backwardAttachment = Instance.new("Attachment")
		backwardAttachment.Name = "TraitBeamBackward"
		backwardAttachment.Position = Vector3.new(0, 0, -parentPart.Size.Z * 0.42)
		backwardAttachment.Parent = parentPart

		local beam = Instance.new("Beam")
		beam.Attachment0 = forwardAttachment
		beam.Attachment1 = backwardAttachment
		beam.Color = ColorSequence.new(preset.accent, preset.accent2)
		beam.FaceCamera = true
		beam.LightEmission = 1
		beam.Width0 = 0.08 + (profile.rarityRank * 0.01)
		beam.Width1 = 0.02 + (profile.rarityRank * 0.01)
		beam.Transparency = NumberSequence.new(0.2, 1)
		beam.Parent = parentPart
	end

	return traitDisplayName
end

local function configureResourceHoverTargets(resourcePart: BasePart)
	createHoverQueryablePart(resourcePart)

	for _, descendant in ipairs(resourcePart:GetDescendants()) do
		if descendant:IsA("BasePart") then
			createHoverQueryablePart(descendant)
			descendant:SetAttribute("ResourceId", resourcePart:GetAttribute("ResourceId"))
			descendant:SetAttribute("ResourceTypeId", resourcePart:GetAttribute("ResourceTypeId"))
		end
	end
end

getResourceVariantShape = function(resourceTypeId, resourceDefinition)
	return ResourceVisuals.getResourceVariantShape(resourceTypeId, resourceDefinition)
end

local function getOreCrystalDefinitions(variantId)
	return ResourceVisuals.getOreCrystalDefinitions(variantId)
end

local function buildOreShard(parentPart, profile, rootCFrame, baseTopY, shard, index)
	local scale = profile.scale
	local height = shard.height * scale
	local width = shard.width * scale
	local depth = shard.depth * scale
	local shardColor = blendColor(profile.baseColor, profile.glowColor, shard.tint or 0.18)
	local shardCFrame = rootCFrame
		* CFrame.new((shard.x or 0) * scale, baseTopY + (height * 0.5) - (0.04 * scale), (shard.z or 0) * scale)
		* CFrame.Angles(math.rad(shard.pitch or 0), math.rad(shard.yaw or 0), math.rad(shard.roll or 0))

	local body = createVisualBasePart(
		parentPart,
		"Part",
		string.format("OreShard_%d", index),
		Vector3.new(width, height, depth),
		parentPart.Position,
		shardColor,
		Enum.Material.Glass
	)
	body.CFrame = shardCFrame
	setReplicaTransparency(body, 0.08)
	body.Reflectance = 0.12

	local capHeight = math.max(0.22, height * 0.22)
	local cap = createVisualBasePart(
		parentPart,
		"WedgePart",
		string.format("OreShardTip_%d", index),
		Vector3.new(width * 1.05, capHeight, depth * 1.06),
		parentPart.Position,
		blendColor(shardColor, profile.glowColor, 0.28),
		Enum.Material.Glass
	)
	cap.CFrame = shardCFrame * CFrame.new(0, (height * 0.5) + (capHeight * 0.28), 0)
	setReplicaTransparency(cap, 0.02)
	cap.Reflectance = 0.16

	local frontFacet = createVisualBasePart(
		parentPart,
		"Part",
		string.format("OreFacetFront_%d", index),
		Vector3.new(width * 0.18, height * 0.70, 0.035 * scale),
		parentPart.Position,
		blendColor(profile.accentColor, profile.glowColor, 0.34),
		Enum.Material.Neon
	)
	frontFacet.CFrame = shardCFrame * CFrame.new(width * -0.24, height * 0.02, -(depth * 0.51))
	setReplicaTransparency(frontFacet, 0.38)

	local sideFacet = createVisualBasePart(
		parentPart,
		"Part",
		string.format("OreFacetSide_%d", index),
		Vector3.new(0.035 * scale, height * 0.58, depth * 0.42),
		parentPart.Position,
		blendColor(profile.baseColor, Color3.fromRGB(255, 255, 255), 0.20),
		Enum.Material.Neon
	)
	sideFacet.CFrame = shardCFrame * CFrame.new(width * 0.51, height * -0.02, depth * 0.08)
	setReplicaTransparency(sideFacet, 0.48)
end

local function buildCrystalOreCluster(resourcePart, profile, rootYaw)
	local scale = profile.scale
	local baseSize = Vector3.new(2.35, 0.36, 1.85) * scale
	local rootCFrame = CFrame.new(resourcePart.Position) * CFrame.Angles(0, rootYaw, 0)

	resourcePart.Size = baseSize
	resourcePart.Color = blendColor(profile.baseColor, Color3.fromRGB(26, 24, 32), 0.70)
	resourcePart.Material = Enum.Material.Slate
	setReplicaTransparency(resourcePart, 0)
	resourcePart.Reflectance = 0.02
	resourcePart.CFrame = rootCFrame

	local baseTopY = baseSize.Y * 0.5
	local lip = createVisualBasePart(
		resourcePart,
		"Part",
		"OreBaseHighlight",
		Vector3.new(1.65, 0.08, 1.12) * scale,
		resourcePart.Position,
		blendColor(profile.baseColor, profile.accentColor, 0.18),
		Enum.Material.Slate
	)
	lip.CFrame = rootCFrame * CFrame.new(0, baseTopY + (0.035 * scale), 0)
	setReplicaTransparency(lip, 0.18)

	for index, shard in ipairs(getOreCrystalDefinitions(profile.variantId)) do
		buildOreShard(resourcePart, profile, rootCFrame, baseTopY, shard, index)
	end
end

local function buildIngotResource(resourcePart, profile, rootYaw)
	local scale = profile.scale
	local rootCFrame = CFrame.new(resourcePart.Position) * CFrame.Angles(0, rootYaw, 0)
	local baseSize = Vector3.new(2.5, 0.62, 1.65) * scale

	resourcePart.Size = baseSize
	resourcePart.Color = blendColor(profile.baseColor, Color3.fromRGB(52, 46, 40), 0.20)
	resourcePart.Material = Enum.Material.Metal
	setReplicaTransparency(resourcePart, 0)
	resourcePart.Reflectance = 0.10 + (profile.rarityRank * 0.012)
	resourcePart.CFrame = rootCFrame

	local roughBase = createVisualBasePart(
		resourcePart,
		"Part",
		"IngotBase",
		Vector3.new(2.9, 0.22, 1.95) * scale,
		resourcePart.Position,
		blendColor(profile.baseColor, Color3.fromRGB(46, 40, 38), 0.58),
		Enum.Material.Slate
	)
	roughBase.CFrame = rootCFrame * CFrame.new(0, -(baseSize.Y * 0.42), 0)
	setReplicaTransparency(roughBase, 0.04)

	local crown = createVisualBasePart(
		resourcePart,
		"Part",
		"IngotCrown",
		Vector3.new(1.82, 0.16, 1.02) * scale,
		resourcePart.Position,
		blendColor(profile.baseColor, profile.glowColor, 0.14),
		Enum.Material.Metal
	)
	crown.CFrame = rootCFrame * CFrame.new(0, (baseSize.Y * 0.34), 0)
	crown.Reflectance = 0.18

	local leftBevel = createVisualBasePart(
		resourcePart,
		"WedgePart",
		"IngotLeftBevel",
		Vector3.new(0.62, 0.18, 1.08) * scale,
		resourcePart.Position,
		blendColor(profile.baseColor, Color3.fromRGB(255, 255, 255), 0.10),
		Enum.Material.Metal
	)
	leftBevel.CFrame = rootCFrame
		* CFrame.new(-(crown.Size.X * 0.5), (baseSize.Y * 0.30), 0)
		* CFrame.Angles(0, math.rad(180), math.rad(90))

	local rightBevel = createVisualBasePart(
		resourcePart,
		"WedgePart",
		"IngotRightBevel",
		Vector3.new(0.62, 0.18, 1.08) * scale,
		resourcePart.Position,
		blendColor(profile.baseColor, profile.glowColor, 0.16),
		Enum.Material.Metal
	)
	rightBevel.CFrame = rootCFrame
		* CFrame.new(crown.Size.X * 0.5, (baseSize.Y * 0.30), 0)
		* CFrame.Angles(0, 0, -math.rad(90))

	local accentStrip = createVisualBasePart(
		resourcePart,
		"Part",
		"IngotAccent",
		Vector3.new(1.28, 0.05, 0.14) * scale,
		resourcePart.Position,
		blendColor(profile.accentColor, profile.glowColor, 0.24),
		if profile.rarityRank >= 4 then Enum.Material.Neon else Enum.Material.Metal
	)
	accentStrip.CFrame = rootCFrame * CFrame.new(0, (baseSize.Y * 0.42), 0)
	setReplicaTransparency(accentStrip, if profile.rarityRank >= 4 then 0.18 else 0.42)

	local edgeGlint = createVisualBasePart(
		resourcePart,
		"Part",
		"IngotEdgeGlint",
		Vector3.new(0.08, 0.30, 1.18) * scale,
		resourcePart.Position,
		Color3.fromRGB(255, 248, 220),
		Enum.Material.Neon
	)
	edgeGlint.CFrame = rootCFrame * CFrame.new(baseSize.X * 0.34, 0.04 * scale, 0)
	setReplicaTransparency(edgeGlint, 0.62)
end

local function buildEldritchResource(resourcePart, profile, rootYaw)
	local scale = profile.scale
	local rootCFrame = CFrame.new(resourcePart.Position) * CFrame.Angles(0, rootYaw, 0)
	local pedestalSize = Vector3.new(1.82, 0.28, 1.82) * scale

	resourcePart.Size = pedestalSize
	resourcePart.Color = blendColor(profile.baseColor, Color3.fromRGB(18, 18, 28), 0.62)
	resourcePart.Material = Enum.Material.Slate
	setReplicaTransparency(resourcePart, 0)
	resourcePart.Reflectance = 0.03
	resourcePart.CFrame = rootCFrame

	local innerCore = createVisualBasePart(
		resourcePart,
		"Part",
		"EldritchCore",
		Vector3.new(0.64, 2.4, 0.64) * scale,
		resourcePart.Position,
		blendColor(profile.baseColor, profile.glowColor, 0.18),
		Enum.Material.Glass
	)
	innerCore.CFrame = rootCFrame * CFrame.new(0, 1.26 * scale, 0) * CFrame.Angles(math.rad(-4), math.rad(18), math.rad(3))
	setReplicaTransparency(innerCore, 0.10)
	innerCore.Reflectance = 0.18

	local heart = createVisualBasePart(
		resourcePart,
		"Part",
		"EldritchHeart",
		Vector3.new(0.42, 0.42, 0.42) * scale,
		resourcePart.Position,
		blendColor(profile.accentColor, profile.glowColor, 0.44),
		Enum.Material.Neon
	)
	heart.Shape = Enum.PartType.Ball
	heart.CFrame = rootCFrame * CFrame.new(0, 1.18 * scale, 0)
	setReplicaTransparency(heart, 0.10)

	local orbitDefs = getOreCrystalDefinitions("eldritch")
	for index, shard in ipairs(orbitDefs) do
		if index > 1 then
			buildOreShard(resourcePart, profile, rootCFrame, 0.90 * scale, shard, index)
		end
	end

	local seam = createVisualBasePart(
		resourcePart,
		"Part",
		"EldritchSeam",
		Vector3.new(0.10, 1.96, 0.12) * scale,
		resourcePart.Position,
		blendColor(profile.accentColor, Color3.fromRGB(255, 255, 255), 0.24),
		Enum.Material.Neon
	)
	seam.CFrame = rootCFrame * CFrame.new(0.08 * scale, 1.24 * scale, -0.22 * scale) * CFrame.Angles(math.rad(-8), math.rad(14), math.rad(6))
	setReplicaTransparency(seam, 0.26)

	if profile.rarityRank >= 5 then
		local halo = createVisualBasePart(
			resourcePart,
			"Part",
			"EldritchHalo",
			Vector3.new(0.14, 1.75, 1.75) * scale,
			resourcePart.Position,
			blendColor(profile.glowColor, Color3.fromRGB(255, 255, 255), 0.20),
			Enum.Material.Neon
		)
		halo.Shape = Enum.PartType.Cylinder
		halo.CFrame = rootCFrame * CFrame.new(0, 1.78 * scale, 0) * CFrame.Angles(0, 0, math.rad(90))
		setReplicaTransparency(halo, 0.42)
	end
end

local function buildResourceVisual(resourcePart, resourceTypeId, traitId, sizeId, sizeValue)
	local resourceDefinition = if resourceTypeId ~= nil then Resources[resourceTypeId] else nil
	local profile = resolveResourceVisualProfile(resourceTypeId, resourceDefinition, sizeId, sizeValue)
	local rootYaw = math.rad((getStringHash(resourcePart.Name) % 360) - 180)
	local labelAccentColor = WorldLabelPresentation.getPlacedResourceLabelAccentColor(profile.rarity)

	resourcePart:SetAttribute("ResourceVisualVariant", profile.variantId)
	resourcePart:SetAttribute("ResourceRarity", profile.rarity)
	resourcePart:SetAttribute("ResourceRarityRank", profile.rarityRank)
	resourcePart:SetAttribute("TraitDisplayName", resolveTraitDisplayName(traitId) or "None")
	resourcePart:SetAttribute("ResourceLabelAccentColor", labelAccentColor)

	if profile.variantId == "ingot" then
		buildIngotResource(resourcePart, profile, rootYaw)
	elseif profile.variantId == "eldritch" then
		buildEldritchResource(resourcePart, profile, rootYaw)
	else
		buildCrystalOreCluster(resourcePart, profile, rootYaw)
	end

	createRarityEffects(resourcePart, profile, profile.variantId)
	local traitDisplayName = applyTraitEffects(resourcePart, profile, traitId)
	if traitDisplayName == nil then
		traitDisplayName = "None"
	end

	local displayTitle, displaySubtitle = WorldLabelPresentation.getPlacedResourceLabelText(
		profile.displayName,
		traitDisplayName,
		profile.sizeDisplayName,
		profile.rarity
	)
	resourcePart:SetAttribute("ResourceDisplayName", profile.displayName)
	resourcePart:SetAttribute("ResourceLabelTitle", displayTitle)
	resourcePart:SetAttribute("ResourceLabelSubtitle", displaySubtitle)

	createResourceBillboard(
		resourcePart,
		displayTitle,
		displaySubtitle,
		labelAccentColor,
		profile.rarityRank
	)

	configureResourceHoverTargets(resourcePart)
	reapplyReplicaTransparency(resourcePart)
end

local function collectPlacedGeodes(profile, plotId, nowUnix)
	local profileAny = profile :: any
	local geodesById = profileAny and profileAny.geodesById or nil
	local geodeOrder = profileAny and profileAny.geodeOrder or nil
	local placedGeodes = {}

	if type(geodesById) == "table" and type(geodeOrder) == "table" then
		for _, geodeId in ipairs(geodeOrder) do
			local geode = geodesById[geodeId]
			if type(geode) == "table" then
				local placement = geode.placement or geode.plotPlacement
				if type(placement) == "table" and placement.plotId == plotId then
					local endsAt = geode.endsAt or nowUnix
					local readyState = if geode.status == "ready" or geode.status == "finished" or endsAt <= nowUnix then "ready" else "cracking"
					table.insert(placedGeodes, {
						id = geode.id or geodeId,
						geodeTypeId = geode.geodeTypeId or geode.geodeId,
						sizeId = geode.sizeId,
						sizeValue = geode.sizeValue,
						placement = placement,
						readyState = readyState,
						endsAt = endsAt,
					})
				end
			end
		end
	end

	return placedGeodes
end

local function collectPlacedResources(profile, plotId)
	local placedResources = {}
	if profile == nil then
		return placedResources
	end

	for _, resourceId in ipairs(profile.resourceOrder or {}) do
		local resource = profile.resourcesById[resourceId]
		local placement = resource and resource.placement or nil
		if type(placement) == "table" and placement.plotId == plotId then
			table.insert(placedResources, {
				id = resource.id or resourceId,
				resourceTypeId = resource.resourceTypeId,
				traitId = resource.traitId,
				sizeId = resource.sizeId,
				sizeValue = resource.sizeValue,
				placement = placement,
			})
		end
	end

	return placedResources
end

local function buildPlotSignature(plot, profile, nowUnix)
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

		local geodeParts = {}
		for _, geode in ipairs(collectPlacedGeodes(profile, plot.id, nowUnix)) do
			table.insert(geodeParts, table.concat({
				geode.id,
				tostring(geode.geodeTypeId or "unknown"),
				tostring(geode.placement.x or "nil"),
				tostring(geode.placement.y or "nil"),
				geode.readyState,
			}, ":"))
		end

		table.sort(geodeParts)
		table.insert(signatureParts, table.concat(geodeParts, "|"))

		local resourceParts = {}
		for _, resource in ipairs(collectPlacedResources(profile, plot.id)) do
			table.insert(resourceParts, table.concat({
				resource.id,
				tostring(resource.resourceTypeId or "unknown"),
				tostring(resource.traitId or "none"),
				tostring(resource.sizeId or "medium"),
				tostring(resource.sizeValue or "nil"),
				tostring(resource.placement.x or "nil"),
				tostring(resource.placement.y or "nil"),
			}, ":"))
		end

		table.sort(resourceParts)
		table.insert(signatureParts, table.concat(resourceParts, "|"))
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

local function pivotStaticModel(model, sourceBaseCFrame, targetBaseCFrame)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CFrame = targetBaseCFrame * sourceBaseCFrame:ToObjectSpace(descendant.CFrame)
		end
	end
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

local function buildPickaxeShop(worldFolder)
	local shopFolder = worldFolder:FindFirstChild(SHOP_FRONT_NAME)
	if shopFolder ~= nil then
		if shopFolder:GetAttribute("StaticLayoutVersion") == STATIC_WORLD_LAYOUT_VERSION then
			return shopFolder
		end
		shopFolder:Destroy()
	end

	shopFolder = Instance.new("Model")
	shopFolder.Name = SHOP_FRONT_NAME
	shopFolder:SetAttribute("StaticLayoutVersion", STATIC_WORLD_LAYOUT_VERSION)
	shopFolder.Parent = worldFolder

	local width = getSharedFloorSize()
	local edgeX = World.plotOrigin.x + (width / 2) - 18
	local basePosition = Vector3.new(edgeX, World.plotOrigin.y + 1, World.plotOrigin.z)

	local stallBase = createPart(
		shopFolder,
		"StallBase",
		Vector3.new(20, 2, 36),
		basePosition,
		Color3.fromRGB(38, 34, 48),
		Enum.Material.Slate
	)
	stallBase.TopSurface = Enum.SurfaceType.Smooth

	local backWall = createPart(
		shopFolder,
		"ShopBackWall",
		Vector3.new(1.2, 8, 28),
		basePosition + Vector3.new(7.4, 5, 0),
		Color3.fromRGB(68, 53, 96),
		Enum.Material.WoodPlanks
	)
	backWall.CanCollide = false

	local sign = createDecorPart(
		shopFolder,
		"ShopSign",
		Vector3.new(0.8, 4, 18),
		basePosition + Vector3.new(6.7, 7.2, 0),
		Color3.fromRGB(103, 83, 127),
		Enum.Material.Wood
	)

	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Left
	signGui.AlwaysOnTop = true
	signGui.Parent = sign

	local signLabel = Instance.new("TextLabel")
	signLabel.BackgroundTransparency = 1
	signLabel.Size = UDim2.fromScale(1, 1)
	signLabel.Font = Enum.Font.GothamBold
	signLabel.Text = "Pickaxe Shop"
	signLabel.TextColor3 = Color3.fromRGB(248, 248, 255)
	signLabel.TextScaled = true
	signLabel.Parent = signGui

	local shopCallout = Instance.new("BillboardGui")
	shopCallout.Name = "ShopCallout"
	shopCallout.AlwaysOnTop = true
	shopCallout.Size = UDim2.fromOffset(180, 44)
	shopCallout.StudsOffset = Vector3.new(0, 4, 0)
	shopCallout.Parent = sign

	local calloutLabel = Instance.new("TextLabel")
	calloutLabel.BackgroundTransparency = 1
	calloutLabel.Size = UDim2.fromScale(1, 1)
	calloutLabel.Font = Enum.Font.GothamBold
	calloutLabel.Text = "Pickaxes tuned here."
	calloutLabel.TextColor3 = Color3.fromRGB(248, 248, 255)
	calloutLabel.TextScaled = true
	calloutLabel.Parent = shopCallout

	local shelf = createDecorPart(
		shopFolder,
		"PickaxeShelf",
		Vector3.new(1, 1, 24),
		basePosition + Vector3.new(6.1, 4.8, 0),
		Color3.fromRGB(45, 38, 63),
		Enum.Material.Wood
	)

	for index, tint in ipairs({
		Color3.fromRGB(126, 126, 129),
		Color3.fromRGB(184, 121, 74),
		Color3.fromRGB(155, 164, 176),
		Color3.fromRGB(224, 183, 74),
		Color3.fromRGB(90, 195, 130),
	}) do
		local zOffset = -10 + ((index - 1) * 5)
		local handle = createDecorPart(
			shopFolder,
			string.format("DisplayPickaxeHandle_%d", index),
			Vector3.new(0.35, 3.4, 0.35),
			basePosition + Vector3.new(5.5, 5.5, zOffset),
			Color3.fromRGB(60, 45, 38),
			Enum.Material.Wood
		)
		handle.CFrame = CFrame.new(handle.Position) * CFrame.Angles(0, 0, math.rad(22))

		local head = createDecorPart(
			shopFolder,
			string.format("DisplayPickaxeHead_%d", index),
			Vector3.new(0.45, 0.45, 2.6),
			basePosition + Vector3.new(5.1, 6.85, zOffset),
			tint,
			Enum.Material.Metal
		)
		head.CFrame = CFrame.new(head.Position) * CFrame.Angles(0, math.rad(90), math.rad(22))
	end
	shelf.Transparency = 0.05

	local promptAnchor = createDecorPart(
		shopFolder,
		"ShopPromptAnchor",
		Vector3.new(2, 5, 24),
		basePosition + Vector3.new(-5.5, 4, 0),
		Color3.fromRGB(92, 180, 170),
		Enum.Material.ForceField
	)
	promptAnchor.Transparency = 1
	promptAnchor.CanQuery = false
	promptAnchor.CanTouch = false

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShopPrompt"
	prompt.ActionText = "Browse Pickaxes"
	prompt.ObjectText = "Pickaxe Smith"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute(SHOP_PROMPT_ATTRIBUTE, true)
	prompt.Parent = promptAnchor

	return shopFolder
end

local function buildMine(worldFolder)
	local mine = worldFolder:FindFirstChild(MINE_NAME)
	if mine ~= nil then
		if mine:GetAttribute("StaticLayoutVersion") == STATIC_WORLD_LAYOUT_VERSION then
			return mine
		end
		mine:Destroy()
	end

	mine = Instance.new("Model")
	mine.Name = MINE_NAME
	mine:SetAttribute("GemFactoryMine", true)
	mine:SetAttribute("StaticLayoutVersion", STATIC_WORLD_LAYOUT_VERSION)
	mine.Parent = worldFolder

	local width = getSharedFloorSize()
	local sourceBaseCFrame = CFrame.new(World.plotOrigin.x, World.plotOrigin.y + 1, World.plotOrigin.z)
	local basePosition = sourceBaseCFrame.Position

	local platform = createPart(
		mine,
		"MinePlatform",
		Vector3.new(44, 2, 26),
		basePosition,
		Color3.fromRGB(35, 33, 43),
		Enum.Material.Slate
	)
	platform.TopSurface = Enum.SurfaceType.Smooth

	local zone = createDecorPart(
		mine,
		"MineStandingZone",
		Vector3.new(40, 16, 24),
		basePosition + Vector3.new(0, 8, 0),
		Color3.fromRGB(92, 180, 170),
		Enum.Material.ForceField
	)
	zone.Transparency = 1
	zone.CanQuery = true
	zone:SetAttribute(MINE_ZONE_ATTRIBUTE, true)

	local mouth = createPart(
		mine,
		"MineFace",
		Vector3.new(34, 22, 4),
		basePosition + Vector3.new(0, 12, -9),
		Color3.fromRGB(30, 28, 36),
		Enum.Material.Rock
	)
	mouth:SetAttribute(MINE_TARGET_ATTRIBUTE, true)
	mouth:SetAttribute("GemFactoryMine", true)

	local target = createPart(
		mine,
		"MineTarget",
		Vector3.new(24, 14, 1),
		basePosition + Vector3.new(0, 10, -6.6),
		Color3.fromRGB(58, 53, 72),
		Enum.Material.Slate
	)
	target:SetAttribute(MINE_TARGET_ATTRIBUTE, true)
	target:SetAttribute("GemFactoryMine", true)

	for index = 1, 7 do
		local xOffset = -15 + ((index - 1) * 5)
		local crystal = createDecorPart(
			mine,
			string.format("MineCrystal_%d", index),
			Vector3.new(1.5, 4 + (index % 3), 1.5),
			basePosition + Vector3.new(xOffset, 4 + (index % 3), -6),
			Color3.fromRGB(92 + (index * 12), 160, 190 + (index * 4)),
			Enum.Material.Neon
		)
		crystal.CFrame = CFrame.new(crystal.Position) * CFrame.Angles(math.rad(8), math.rad(index * 17), math.rad(12))
	end

	local sign = createDecorPart(
		mine,
		"MineSign",
		Vector3.new(18, 4, 0.6),
		basePosition + Vector3.new(0, 17.5, -6.65),
		Color3.fromRGB(76, 64, 91),
		Enum.Material.Wood
	)

	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Back
	signGui.AlwaysOnTop = true
	signGui.Parent = sign

	local signLabel = Instance.new("TextLabel")
	signLabel.BackgroundTransparency = 1
	signLabel.Size = UDim2.fromScale(1, 1)
	signLabel.Font = Enum.Font.GothamBold
	signLabel.Text = "Geode Mine"
	signLabel.TextColor3 = Color3.fromRGB(248, 248, 255)
	signLabel.TextScaled = true
	signLabel.Parent = signGui

	local edgeX = World.plotOrigin.x - (width / 2) + 24
	local targetBaseCFrame = CFrame.new(edgeX, basePosition.Y, World.plotOrigin.z) * CFrame.Angles(0, math.rad(90), 0)
	pivotStaticModel(mine, sourceBaseCFrame, targetBaseCFrame)

	return mine
end

local function addRockSpikes(parent, plot)
	local rockFolder = Instance.new("Folder")
	rockFolder.Name = "RockSpikes"
	rockFolder.Parent = parent

	local variant = ROCK_VARIANTS[((plot.index or 1) - 1) % #ROCK_VARIANTS + 1]
	local rockColor = Color3.fromRGB(37, 34, 46)

	for spikeIndex, spike in ipairs(variant) do
		local rockPosition = Vector3.new(
			plot.position.x + spike.x,
			plot.position.y + (spike.height / 2),
			plot.position.z + spike.z
		)
		local rockSize = Vector3.new(spike.radius * 2, spike.height, spike.radius * 2)
		local rockMaterial = Enum.Material.Slate
		if spike.kind == "boulder" then
			rockSize = Vector3.new(spike.radius * 2.5, spike.height, spike.radius * 2.1)
			rockMaterial = Enum.Material.Rock
		end

		local rock = createDecorPart(
			rockFolder,
			string.format("RockSpike_%d", spikeIndex),
			rockSize,
			rockPosition,
			rockColor,
			rockMaterial
		)
		rock.CFrame = CFrame.new(rockPosition)
			* CFrame.Angles(math.rad(4), math.rad(spike.yaw), math.rad(8))
	end
end

local function createGeodePart(parent, geodeName, geodeTypeId, stateLabel, position, sizeId, sizeValue, endsAt)
	local labelText = GeodePresentation.getWorldLabelText(stateLabel, endsAt, os.time())
	local resolvedStateLabel = if labelText == "Ready!" then "ready" else "cracking"
	local geodeDefinition = if geodeTypeId ~= nil then Geodes[geodeTypeId] else nil
	local geodeColor = geodeDefinition and geodeDefinition.displayColor or getGeodeTint(geodeTypeId, resolvedStateLabel)
	local isReady = resolvedStateLabel == "ready"
	local geodeScale = SizeRules.getScaleValue(sizeId, sizeValue)
	local shellSize = Vector3.new(4.5, 4.5, 4.5) * geodeScale
	local coreSize = (if isReady then Vector3.new(3.35, 3.35, 3.35) else Vector3.new(3.95, 3.95, 3.95)) * geodeScale
	local glossSize = (if isReady then Vector3.new(4.68, 4.68, 4.68) else Vector3.new(4.64, 4.64, 4.64)) * geodeScale
	local highlightSize = (if isReady then Vector3.new(0.92, 0.92, 0.92) else Vector3.new(0.78, 0.78, 0.78)) * geodeScale
	local highlightOffset = Vector3.new(1.0, 1.0, -0.8) * geodeScale

	local geodePart = createDecorPart(
		parent,
		geodeName,
		shellSize,
		position,
		if isReady then blendColor(geodeColor, Color3.fromRGB(255, 255, 255), 0.12) else blendColor(geodeColor, Color3.fromRGB(32, 30, 38), 0.35),
		if isReady then Enum.Material.SmoothPlastic else Enum.Material.Slate
	)
	geodePart.Shape = Enum.PartType.Ball
	geodePart.Reflectance = if isReady then 0.08 else 0.02
	geodePart:SetAttribute("GeodeId", geodeName)
	geodePart:SetAttribute("GeodeTypeId", geodeTypeId)
	geodePart:SetAttribute("SizeId", sizeId or "medium")
	geodePart:SetAttribute("SizeValue", geodeScale)
	geodePart:SetAttribute("ReadyState", resolvedStateLabel)
	geodePart:SetAttribute("GeodeState", resolvedStateLabel)
	geodePart:SetAttribute("EndsAt", if isReady then nil else endsAt)

	local coreColor = if isReady
		then geodeColor
		else blendColor(geodeColor, Color3.fromRGB(10, 10, 14), 0.28)
	local core = createDecorPart(
		geodePart,
		"GeodeCore",
		coreSize,
		position + Vector3.new(0, 0.12 * geodeScale, 0),
		coreColor,
		if isReady then Enum.Material.Neon else Enum.Material.SmoothPlastic
	)
	core.Shape = Enum.PartType.Ball
	core.Transparency = if isReady then 0.08 else 0.04

	local gloss = createDecorPart(
		geodePart,
		"GeodeGloss",
		glossSize,
		position,
		if isReady then Color3.fromRGB(225, 235, 255) else Color3.fromRGB(175, 183, 196),
		Enum.Material.Glass
	)
	gloss.Shape = Enum.PartType.Ball
	gloss.Transparency = if isReady then 0.76 else 0.90

	local highlight = createDecorPart(
		geodePart,
		"GeodeHighlight",
		highlightSize,
		position + highlightOffset,
		if isReady then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(235, 240, 248),
		if isReady then Enum.Material.Neon else Enum.Material.SmoothPlastic
	)
	highlight.Shape = Enum.PartType.Ball
	highlight.Transparency = if isReady then 0.42 else 0.78

	if isReady then
		local light = Instance.new("PointLight")
		light.Color = geodeColor
		light.Brightness = 1.2
		light.Range = 6 + (geodeScale * 2)
		light.Shadows = false
		light.Parent = geodePart

		local glowAttachment = Instance.new("Attachment")
		glowAttachment.Name = "GeodeGlowAttachment"
		glowAttachment.Position = Vector3.new(0, 1.2 * geodeScale, 0)
		glowAttachment.Parent = geodePart

		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkle.Color = ColorSequence.new(geodeColor, Color3.fromRGB(255, 255, 255))
		sparkle.LightEmission = 1
		sparkle.Rate = 4
		sparkle.Lifetime = NumberRange.new(0.6, 1.0)
		sparkle.Speed = NumberRange.new(0.25, 0.6)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Size = NumberSequence.new(0.18, 0)
		sparkle.Transparency = NumberSequence.new(0.05, 1)
		sparkle.EmissionDirection = Enum.NormalId.Top
		sparkle.Drag = 1
		sparkle.Parent = glowAttachment
	end

	local marker = Instance.new("BillboardGui")
	marker.Name = geodeName .. "_Marker"
	marker.Size = UDim2.fromOffset(140, 32)
	marker.StudsOffset = Vector3.new(0, (shellSize.Y / 2) + 1.35, 0)
	marker.AlwaysOnTop = true
	marker.Parent = geodePart

	local markerFrame = Instance.new("Frame")
	markerFrame.BackgroundColor3 = Color3.fromRGB(30, 26, 40)
	markerFrame.BackgroundTransparency = 0.15
	markerFrame.Size = UDim2.fromScale(1, 1)
	markerFrame.Parent = marker

	local markerCorner = Instance.new("UICorner")
	markerCorner.CornerRadius = UDim.new(0, 6)
	markerCorner.Parent = markerFrame

	local markerStroke = Instance.new("UIStroke")
	markerStroke.Color = if isReady then geodeColor else Color3.fromRGB(120, 128, 140)
	markerStroke.Thickness = 1.5
	markerStroke.Transparency = 0.1
	markerStroke.Parent = markerFrame

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.Text = labelText
	label.TextColor3 = if isReady then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(184, 196, 214)
	label.TextStrokeColor3 = Color3.fromRGB(22, 18, 30)
	label.TextStrokeTransparency = 0.6
	label.TextScaled = true
	label.Parent = markerFrame

	return geodePart
end

local function addGeodes(parent, plot, profile, nowUnix)
	local geodeFolder = Instance.new("Folder")
	geodeFolder.Name = "Geodes"
	geodeFolder.Parent = parent

	local placedGeodes = collectPlacedGeodes(profile, plot.id, nowUnix)
	local cellSize = World.cellSize
	local gridOriginX = plot.position.x - ((World.plotGridWidth * cellSize) / 2) + (cellSize / 2)
	local gridOriginZ = plot.position.z - ((World.plotGridHeight * cellSize) / 2) + (cellSize / 2)

	for _, geode in ipairs(placedGeodes) do
		local placement = geode.placement
		local footprintWidth = (placement.width or 1)
		local footprintHeight = (placement.height or 1)
		local geodeScale = SizeRules.getScaleValue(geode.sizeId, geode.sizeValue)
		local geodeShellHeight = 4.5 * geodeScale
		local geodePosition = Vector3.new(
			gridOriginX + ((placement.x - 1) * cellSize) + (((footprintWidth - 1) * cellSize) / 2),
			plot.position.y + (World.plotBaseSize.height / 2) + (geodeShellHeight / 2),
			gridOriginZ + ((placement.y - 1) * cellSize) + (((footprintHeight - 1) * cellSize) / 2)
		)
		createGeodePart(
			geodeFolder,
			tostring(geode.id),
			geode.geodeTypeId,
			geode.readyState,
			geodePosition,
			geode.sizeId,
			geode.sizeValue,
			geode.endsAt
		)
	end
end

local function createResourcePart(parent, resourceName, resourceTypeId, traitId, sizeId, sizeValue, position)
	local rootSize = ResourceVisuals.getPlacedRootSize(sizeId, sizeValue)
	local resourcePart = createDecorPart(
		parent,
		resourceName,
		rootSize,
		position,
		Color3.fromRGB(240, 240, 255),
		Enum.Material.Neon
	)
	resourcePart:SetAttribute("ResourceId", resourceName)
	resourcePart:SetAttribute("ResourceTypeId", resourceTypeId)
	resourcePart:SetAttribute("TraitId", traitId or "none")
	resourcePart:SetAttribute("SizeId", sizeId or "medium")
	resourcePart:SetAttribute("SizeValue", SizeRules.getScaleValue(sizeId, sizeValue))
	buildResourceVisual(resourcePart, resourceTypeId, traitId, sizeId, sizeValue)
end

local function addResources(parent, plot, profile)
	local resourceFolder = Instance.new("Folder")
	resourceFolder.Name = "PlacedResources"
	resourceFolder.Parent = parent

	local placedResources = collectPlacedResources(profile, plot.id)
	local cellSize = World.cellSize
	local gridOriginX = plot.position.x - ((World.plotGridWidth * cellSize) / 2) + (cellSize / 2)
	local gridOriginZ = plot.position.z - ((World.plotGridHeight * cellSize) / 2) + (cellSize / 2)

	for _, resource in ipairs(placedResources) do
		local placement = resource.placement
		local footprintWidth = placement.width or 1
		local footprintHeight = placement.height or 1
		local baseHeight = ResourceVisuals.getPlacedBaseHeight(resource.sizeId, resource.sizeValue)
		local resourcePosition = Vector3.new(
			gridOriginX + ((placement.x - 1) * cellSize) + (((footprintWidth - 1) * cellSize) / 2),
			plot.position.y + (World.plotBaseSize.height / 2) + (baseHeight / 2),
			gridOriginZ + ((placement.y - 1) * cellSize) + (((footprintHeight - 1) * cellSize) / 2)
		)
		createResourcePart(resourceFolder, tostring(resource.id), resource.resourceTypeId, resource.traitId, resource.sizeId, resource.sizeValue, resourcePosition)
	end
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

function WorldReplicaService:_buildPlot(plot, profile, signature, nowUnix)
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

	-- Keep the visible trim non-blocking for presentation, but mirror it with an invisible
	-- collider so the server-authored plot surface matches what players see in the world.
	local surfaceCollider = createPart(
		plotModel,
		PLOT_SURFACE_COLLIDER_NAME,
		Vector3.new(World.plotBaseSize.width - 6, 0.4, World.plotBaseSize.depth - 6),
		Vector3.new(plot.position.x, plot.position.y + 1.2, plot.position.z),
		Color3.fromRGB(58, 54, 78),
		Enum.Material.SmoothPlastic
	)
	surfaceCollider.Transparency = 1
	surfaceCollider.CanQuery = false
	surfaceCollider.CanTouch = false

	addRockSpikes(plotModel, plot)
	addGeodes(plotModel, plot, profile, nowUnix)
	addResources(plotModel, plot, profile)

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
	buildMine(worldFolder)
	buildPickaxeShop(worldFolder)

	for _, plot in ipairs(plots) do
		if plot.userId ~= nil then
			local profile = playerDataService:getProfile(plot.userId)
			local nowUnix = os.time()
			local signature = buildPlotSignature(plot, profile, nowUnix)
			if self.signatures[plot.id] ~= signature or self.models[plot.id] == nil then
				self:_buildPlot(plot, profile, signature, nowUnix)
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

	local nowUnix = os.time()
	self:_buildPlot(plot, profile, buildPlotSignature(plot, profile, nowUnix), nowUnix)
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
