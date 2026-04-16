--!strict

local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Geodes = require(Shared.Config.Geodes)
local Resources = require(Shared.Config.Resources)
local Traits = require(Shared.Config.Traits)
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
	local hash = 0
	local text = tostring(value or "")

	for index = 1, #text do
		hash = (hash * 33 + string.byte(text, index)) % 2147483647
	end

	return hash
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

local function resolveResourceVisualProfile(resourceTypeId, resourceDefinition)
	local rarity = if resourceDefinition ~= nil and resourceDefinition.rarity ~= nil then resourceDefinition.rarity else "Common"
	local variantId = getResourceVariantShape(resourceTypeId, resourceDefinition)
	local rarityRank = getRarityRank(rarity)

	local baseColor = if resourceDefinition ~= nil and resourceDefinition.color ~= nil
		then resourceDefinition.color
		else RESOURCE_RARITY_ACCENTS[rarity] or Color3.fromRGB(240, 240, 255)
	local accentColor = getResourceRarityAccent(rarity, baseColor)
	local glowColor = blendColor(accentColor, Color3.fromRGB(255, 255, 255), 0.25)

	return {
		baseColor = baseColor,
		accentColor = accentColor,
		glowColor = glowColor,
		displayName = if resourceDefinition ~= nil and resourceDefinition.displayName ~= nil then resourceDefinition.displayName else "Resource",
		rarity = rarity,
		rarityRank = rarityRank,
		scale = getResourceRarityScale(rarity),
		variantId = variantId,
	}
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
	part.Parent = parent
	return part
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

local function createResourceBillboard(parentPart, titleText, subtitleText, accentColor, rarityRank)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = parentPart.Name .. "_Marker"
	billboard.Size = UDim2.fromOffset(188 + (rarityRank * 4), 54 + (rarityRank > 3 and 6 or 0))
	billboard.StudsOffset = Vector3.new(0, 2.8 + (rarityRank * 0.08), 0)
	billboard.AlwaysOnTop = true
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
		3 + (profile.rarityRank * 2),
		0.7,
		1.1,
		0.25,
		0.9 + (profile.rarityRank * 0.14),
		0.18,
		0
	)

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

getResourceVariantShape = function(resourceTypeId, resourceDefinition)
	local resourceKey = normalizeVisualKey(resourceTypeId)
	local rarity = if resourceDefinition ~= nil and resourceDefinition.rarity ~= nil then resourceDefinition.rarity else "Common"
	local rarityRank = getRarityRank(rarity)
	local variantId = RESOURCE_TYPE_VARIANTS[resourceKey] or "gemstone"

	if variantId == "gemstone" then
		if resourceKey:find("cluster", 1, true) ~= nil or rarityRank == 3 then
			variantId = "cluster"
		end

		if resourceKey:find("core", 1, true) ~= nil
			or resourceKey:find("shard", 1, true) ~= nil
			or rarityRank >= 4
		then
			variantId = "artifact"
		end
	end

	return variantId
end

local function buildPolishedGemstone(resourcePart, profile, rootYaw)
	local scale = profile.scale
	local baseColor = profile.baseColor
	local accentColor = profile.accentColor
	local glowColor = profile.glowColor
	local centerSize = Vector3.new(1.65, 2.2, 1.65) * scale

	resourcePart.Size = centerSize
	resourcePart.Color = blendColor(baseColor, Color3.fromRGB(255, 255, 255), 0.1)
	resourcePart.Material = Enum.Material.Glass
	resourcePart.Transparency = 0.12
	resourcePart.Reflectance = 0.16
	orientPart(resourcePart, rootYaw, math.rad(0), math.rad(34))

	local topTip = createVisualBasePart(
		resourcePart,
		"Part",
		"GemTopTip",
		Vector3.new(centerSize.X * 0.72, centerSize.Y * 0.34, centerSize.Z * 0.72),
		resourcePart.Position + Vector3.new(0, centerSize.Y * 0.48, 0),
		accentColor,
		Enum.Material.Neon
	)
	orientPart(topTip, rootYaw, math.rad(-8), math.rad(45))
	topTip.Transparency = 0.08

	local bottomTip = createVisualBasePart(
		resourcePart,
		"Part",
		"GemBottomTip",
		Vector3.new(centerSize.X * 0.72, centerSize.Y * 0.34, centerSize.Z * 0.72),
		resourcePart.Position + Vector3.new(0, -centerSize.Y * 0.48, 0),
		blendColor(baseColor, Color3.fromRGB(10, 10, 16), 0.2),
		Enum.Material.SmoothPlastic
	)
	orientPart(bottomTip, rootYaw, math.rad(8), math.rad(225))
	bottomTip.Transparency = 0.18

	local sideBand = createVisualBasePart(
		resourcePart,
		"Part",
		"GemBand",
		Vector3.new(centerSize.X * 1.08, centerSize.Y * 0.16, centerSize.Z * 1.08),
		resourcePart.Position + Vector3.new(0, 0, 0),
		blendColor(baseColor, Color3.fromRGB(18, 15, 26), 0.22),
		Enum.Material.SmoothPlastic
	)
	orientPart(sideBand, rootYaw, 0, math.rad(45))
	sideBand.Transparency = 0.08

	for index, yOffset in ipairs({ 0.2, -0.12, 0.05, -0.26 }) do
		local accentShard = createVisualBasePart(
			resourcePart,
			"Part",
			string.format("GemFacet_%d", index),
			Vector3.new(centerSize.X * 0.2, centerSize.Y * 0.7, centerSize.Z * 0.12),
			resourcePart.Position
				+ Vector3.new(
					math.cos(rootYaw + (math.rad(90) * (index - 1))) * centerSize.X * 0.42,
					yOffset,
					math.sin(rootYaw + (math.rad(90) * (index - 1))) * centerSize.Z * 0.42
				),
			glowColor,
			Enum.Material.Neon
		)
		orientPart(accentShard, rootYaw + math.rad((index - 1) * 45), math.rad(10), math.rad(12))
		accentShard.Transparency = 0.2
	end
end

local function buildCrystalCluster(resourcePart, profile, rootYaw)
	local scale = profile.scale
	local baseColor = profile.baseColor
	local accentColor = profile.accentColor
	local glowColor = profile.glowColor
	local coreSize = Vector3.new(1.25, 2.45, 1.25) * scale

	resourcePart.Size = coreSize
	resourcePart.Color = blendColor(baseColor, Color3.fromRGB(255, 255, 255), 0.08)
	resourcePart.Material = Enum.Material.Crystal
	resourcePart.Transparency = 0.08
	resourcePart.Reflectance = 0.12
	orientPart(resourcePart, rootYaw, math.rad(-5), math.rad(22))

	local baseRock = createVisualBasePart(
		resourcePart,
		"Part",
		"ClusterBase",
		Vector3.new(coreSize.X * 1.55, coreSize.Y * 0.28, coreSize.Z * 1.55),
		resourcePart.Position + Vector3.new(0, -coreSize.Y * 0.5, 0),
		blendColor(baseColor, Color3.fromRGB(20, 18, 28), 0.42),
		Enum.Material.Slate
	)
	orientPart(baseRock, rootYaw, 0, math.rad(4))
	baseRock.Transparency = 0.1

	local shardOffsets = {
		{ x = -0.46, y = 0.22, z = -0.08, yaw = 12, roll = 10 },
		{ x = 0.34, y = 0.38, z = 0.12, yaw = -16, roll = -8 },
		{ x = 0.08, y = -0.02, z = -0.42, yaw = 24, roll = 14 },
		{ x = -0.1, y = 0.58, z = 0.34, yaw = 38, roll = 18 },
	}

	for index, shard in ipairs(shardOffsets) do
		local shardPart = createVisualBasePart(
			resourcePart,
			"Part",
			string.format("ClusterShard_%d", index),
			Vector3.new(coreSize.X * (0.35 + (index * 0.05)), coreSize.Y * (0.55 + (index * 0.08)), coreSize.Z * 0.22),
			resourcePart.Position
				+ Vector3.new(
					shard.x * coreSize.X,
					shard.y * coreSize.Y,
					shard.z * coreSize.Z
				),
			if index % 2 == 0 then accentColor else glowColor,
			Enum.Material.Neon
		)
		orientPart(shardPart, rootYaw + math.rad(shard.yaw), math.rad(4 + (index * 3)), math.rad(shard.roll))
		shardPart.Transparency = 0.12 + (index * 0.03)
	end
end

local function buildArtifactCore(resourcePart, profile, rootYaw)
	local scale = profile.scale
	local baseColor = profile.baseColor
	local accentColor = profile.accentColor
	local glowColor = profile.glowColor
	local coreSize = Vector3.new(1.55, 2.0, 1.55) * scale

	resourcePart.Size = coreSize
	resourcePart.Color = blendColor(baseColor, Color3.fromRGB(255, 255, 255), 0.18)
	resourcePart.Material = Enum.Material.Neon
	resourcePart.Transparency = 0.09
	resourcePart.Reflectance = 0.05
	orientPart(resourcePart, rootYaw, math.rad(0), math.rad(45))

	local crown = createVisualBasePart(
		resourcePart,
		"Part",
		"ArtifactCrown",
		Vector3.new(coreSize.X * 0.72, coreSize.Y * 0.42, coreSize.Z * 0.72),
		resourcePart.Position + Vector3.new(0, coreSize.Y * 0.42, 0),
		accentColor,
		Enum.Material.ForceField
	)
	orientPart(crown, rootYaw + math.rad(22), math.rad(-10), math.rad(34))
	crown.Transparency = 0.16

	local coreCap = createVisualBasePart(
		resourcePart,
		"Part",
		"ArtifactCoreCap",
		Vector3.new(coreSize.X * 0.88, coreSize.Y * 0.18, coreSize.Z * 0.88),
		resourcePart.Position,
		blendColor(baseColor, Color3.fromRGB(22, 18, 34), 0.15),
		Enum.Material.SmoothPlastic
	)
	orientPart(coreCap, rootYaw, 0, math.rad(45))
	coreCap.Transparency = 0.12

	local haloBars = {
		{ name = "ArtifactHaloEast", size = Vector3.new(coreSize.X * 1.35, 0.14, 0.14), offset = Vector3.new(coreSize.X * 0.1, 0, 0), yaw = 0 },
		{ name = "ArtifactHaloNorth", size = Vector3.new(0.14, 0.14, coreSize.Z * 1.35), offset = Vector3.new(0, 0, coreSize.Z * 0.1), yaw = 0 },
		{ name = "ArtifactHaloSlashOne", size = Vector3.new(coreSize.X * 1.28, 0.12, 0.12), offset = Vector3.new(0, 0, 0), yaw = 45 },
		{ name = "ArtifactHaloSlashTwo", size = Vector3.new(coreSize.X * 1.28, 0.12, 0.12), offset = Vector3.new(0, 0, 0), yaw = -45 },
	}

	for index, halo in ipairs(haloBars) do
		local haloBar = createVisualBasePart(
			resourcePart,
			"Part",
			halo.name,
			halo.size,
			resourcePart.Position + halo.offset,
			if index % 2 == 0 then glowColor else accentColor,
			Enum.Material.Neon
		)
		orientPart(haloBar, rootYaw + math.rad(halo.yaw), 0, 0)
		haloBar.Transparency = 0.2
	end

	local shardOffsets = {
		{ x = 0.34, y = 0.44, z = -0.1, yaw = 0, roll = 18 },
		{ x = -0.3, y = -0.34, z = 0.14, yaw = 140, roll = -16 },
		{ x = 0.02, y = 0.1, z = 0.42, yaw = 70, roll = 4 },
	}

	for index, shard in ipairs(shardOffsets) do
		local shardPart = createVisualBasePart(
			resourcePart,
			"Part",
			string.format("ArtifactShard_%d", index),
			Vector3.new(coreSize.X * 0.25, coreSize.Y * (0.62 + (index * 0.06)), coreSize.Z * 0.14),
			resourcePart.Position
				+ Vector3.new(
					shard.x * coreSize.X,
					shard.y * coreSize.Y,
					shard.z * coreSize.Z
				),
			if index == 1 then glowColor else accentColor,
			Enum.Material.Neon
		)
		orientPart(shardPart, rootYaw + math.rad(shard.yaw), math.rad(8), math.rad(shard.roll))
		shardPart.Transparency = 0.16
	end
end

local function buildResourceVisual(resourcePart, resourceTypeId, traitId)
	local resourceDefinition = if resourceTypeId ~= nil then Resources[resourceTypeId] else nil
	local profile = resolveResourceVisualProfile(resourceTypeId, resourceDefinition)
	local rootYaw = math.rad((getStringHash(resourcePart.Name) % 360) - 180)

	resourcePart:SetAttribute("ResourceVisualVariant", profile.variantId)
	resourcePart:SetAttribute("ResourceRarity", profile.rarity)
	resourcePart:SetAttribute("ResourceRarityRank", profile.rarityRank)
	resourcePart:SetAttribute("TraitDisplayName", resolveTraitDisplayName(traitId) or "None")

	if profile.variantId == "artifact" then
		buildArtifactCore(resourcePart, profile, rootYaw)
	elseif profile.variantId == "cluster" then
		buildCrystalCluster(resourcePart, profile, rootYaw)
	else
		buildPolishedGemstone(resourcePart, profile, rootYaw)
	end

	createRarityEffects(resourcePart, profile, profile.variantId)
	local traitDisplayName = applyTraitEffects(resourcePart, profile, traitId)
	if traitDisplayName == nil then
		traitDisplayName = "None"
	end

	createResourceBillboard(
		resourcePart,
		if traitDisplayName ~= "None" then string.format("%s %s", traitDisplayName, profile.displayName) else profile.displayName,
		if traitDisplayName ~= "None" then string.format("%s - %s", profile.rarity, traitDisplayName) else profile.rarity,
		profile.accentColor,
		profile.rarityRank
	)
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

local function createGeodePart(parent, geodeName, geodeTypeId, stateLabel, position)
	local geodeDefinition = if geodeTypeId ~= nil then Geodes[geodeTypeId] else nil
	local shellColor = if stateLabel == "ready" then Color3.fromRGB(208, 236, 255) else Color3.fromRGB(58, 52, 68)
	local geodePart = createDecorPart(
		parent,
		geodeName,
		Vector3.new(4.5, 4.5, 4.5),
		position,
		geodeDefinition and geodeDefinition.displayColor or getGeodeTint(geodeTypeId, stateLabel),
		if stateLabel == "ready" then Enum.Material.SmoothPlastic else Enum.Material.Slate
	)
	geodePart.Shape = Enum.PartType.Ball
	geodePart:SetAttribute("GeodeId", geodeName)
	geodePart:SetAttribute("GeodeTypeId", geodeTypeId)
	geodePart:SetAttribute("ReadyState", stateLabel)
	geodePart:SetAttribute("GeodeState", stateLabel)

	local shell = createDecorPart(
		parent,
		geodeName .. "_Shell",
		Vector3.new(3.2, 3.2, 3.2),
		position + Vector3.new(0, 0.2, 0),
		shellColor,
		if stateLabel == "ready" then Enum.Material.Neon else Enum.Material.Slate
	)
	shell.Shape = Enum.PartType.Ball
	shell:SetAttribute("GeodeId", geodeName)
	shell:SetAttribute("GeodeTypeId", geodeTypeId)
	shell:SetAttribute("ReadyState", stateLabel)
	shell:SetAttribute("GeodeState", stateLabel)

	local marker = Instance.new("BillboardGui")
	marker.Name = geodeName .. "_Marker"
	marker.Size = UDim2.fromOffset(120, 26)
	marker.StudsOffset = Vector3.new(0, 3.4, 0)
	marker.AlwaysOnTop = true
	marker.Parent = geodePart

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.Text = stateLabel == "ready" and "Ready" or "Cracking"
	label.TextColor3 = stateLabel == "ready" and Color3.fromRGB(233, 244, 255) or Color3.fromRGB(184, 196, 214)
	label.TextScaled = true
	label.Parent = marker
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
		local geodePosition = Vector3.new(
			gridOriginX + ((placement.x - 1) * cellSize) + (((footprintWidth - 1) * cellSize) / 2),
			plot.position.y + 3.25,
			gridOriginZ + ((placement.y - 1) * cellSize) + (((footprintHeight - 1) * cellSize) / 2)
		)
		createGeodePart(geodeFolder, tostring(geode.id), geode.geodeTypeId, geode.readyState, geodePosition)
	end
end

local function createResourcePart(parent, resourceName, resourceTypeId, traitId, position)
	local resourcePart = createDecorPart(
		parent,
		resourceName,
		Vector3.new(3, 3, 3),
		position,
		Color3.fromRGB(240, 240, 255),
		Enum.Material.Neon
	)
	resourcePart:SetAttribute("ResourceId", resourceName)
	resourcePart:SetAttribute("ResourceTypeId", resourceTypeId)
	resourcePart:SetAttribute("TraitId", traitId or "none")
	buildResourceVisual(resourcePart, resourceTypeId, traitId)
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
		local resourcePosition = Vector3.new(
			gridOriginX + ((placement.x - 1) * cellSize) + (((footprintWidth - 1) * cellSize) / 2),
			plot.position.y + 3,
			gridOriginZ + ((placement.y - 1) * cellSize) + (((footprintHeight - 1) * cellSize) / 2)
		)
		createResourcePart(resourceFolder, tostring(resource.id), resource.resourceTypeId, resource.traitId, resourcePosition)
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
