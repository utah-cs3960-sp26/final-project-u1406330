--!strict

-- Deterministic shared rules for Resource Visuals so gameplay behavior can be reused by the server, client presentation, and specs.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Resources = require(Shared.Config.Resources)
local SizeRules = require(Shared.Domain.SizeRules)
local Traits = require(Shared.Config.Traits)

local ResourceVisuals = {}
local MAX_HASH_VALUE = 2147483647

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
	rose_quartz = "gemstone",
	smoky_quartz = "gemstone",
	jade_fragment = "gemstone",
	amethyst = "gemstone",
	moonstone = "moonstone",
	emerald_cluster = "cluster",
	garnet_node = "cluster",
	topaz_vein = "cluster",
	ruby_cluster = "cluster",
	peridot_bloom = "cluster",
	diamond_core = "artifact",
	sapphire_spire = "artifact",
	black_opal = "artifact",
	star_shard = "artifact",
	phoenix_amber = "artifact",
	copper_nugget = "ingot",
	silver_ingot = "ingot",
	gold_ingot = "ingot",
	mythril_ingot = "ingot",
	celestium_ingot = "ingot",
	aetherite_relic = "eldritch",
	voidglass_core = "eldritch",
	astral_reliquary = "eldritch",
	worldseed = "eldritch",
}

local PLACED_RESOURCE_BASE_SIZE = Vector3.new(3, 3, 3)
local PLACED_RESOURCE_BASE_HEIGHT = 0.36

local RESOURCE_PROFILE_OVERRIDES = {
	moonstone = {
		variantId = "moonstone",
		baseColor = Color3.fromRGB(214, 231, 255),
		accentColor = Color3.fromRGB(255, 228, 247),
		glowColor = Color3.fromRGB(195, 255, 247),
		scaleMultiplier = 0.74,
		minScale = 0.72,
		maxScale = 1.18,
		shineStrength = 0.34,
	},
}

local VARIANT_PROCEDURAL_RULES = {
	gemstone = {
		minCount = 4,
		maxCount = 6,
		positionJitter = 0.18,
		heightJitter = 0.22,
		widthJitter = 0.14,
		depthJitter = 0.16,
		rotationJitter = 18,
		tintJitter = 0.12,
	},
	cluster = {
		minCount = 5,
		maxCount = 7,
		positionJitter = 0.2,
		heightJitter = 0.24,
		widthJitter = 0.16,
		depthJitter = 0.18,
		rotationJitter = 20,
		tintJitter = 0.14,
	},
	artifact = {
		minCount = 5,
		maxCount = 6,
		positionJitter = 0.16,
		heightJitter = 0.18,
		widthJitter = 0.13,
		depthJitter = 0.15,
		rotationJitter = 16,
		tintJitter = 0.1,
	},
	ingot = {
		minCount = 4,
		maxCount = 5,
		positionJitter = 0.06,
		heightJitter = 0.1,
		widthJitter = 0.08,
		depthJitter = 0.08,
		rotationJitter = 6,
		tintJitter = 0.08,
	},
	eldritch = {
		minCount = 6,
		maxCount = 8,
		positionJitter = 0.22,
		heightJitter = 0.26,
		widthJitter = 0.18,
		depthJitter = 0.2,
		rotationJitter = 24,
		tintJitter = 0.16,
	},
	moonstone = {
		minCount = 5,
		maxCount = 6,
		positionJitter = 0.08,
		heightJitter = 0.1,
		widthJitter = 0.08,
		depthJitter = 0.08,
		rotationJitter = 10,
		tintJitter = 0.06,
	},
}

local STATIC_VARIANT_DEFINITIONS = {
	moonstone = {
		{ x = -0.18, z = 0.12, height = 1.22, width = 0.36, depth = 0.34, yaw = -28, pitch = -6, roll = 18, tint = 0.26 },
		{ x = 0.04, z = 0.16, height = 1.34, width = 0.38, depth = 0.34, yaw = -8, pitch = -7, roll = 8, tint = 0.38 },
		{ x = 0.26, z = 0.04, height = 1.18, width = 0.34, depth = 0.32, yaw = 18, pitch = -5, roll = -10, tint = 0.18 },
		{ x = 0.10, z = -0.18, height = 0.82, width = 0.26, depth = 0.22, yaw = 34, pitch = 2, roll = -18, tint = 0.52 },
		{ x = -0.08, z = -0.20, height = 0.66, width = 0.22, depth = 0.20, yaw = -30, pitch = 4, roll = 22, tint = 0.46 },
	},
	eldritch = {
		{ x = 0.00, z = 0.00, height = 2.48, width = 0.46, depth = 0.54, yaw = 8, pitch = -6, roll = 4, tint = 0.28 },
		{ x = 0.00, z = 0.00, height = 1.64, width = 0.22, depth = 0.24, yaw = -22, pitch = 0, roll = 0, tint = 0.42, orbit = true },
		{ x = 0.56, z = -0.06, height = 1.34, width = 0.24, depth = 0.62, yaw = 34, pitch = -12, roll = 22, tint = 0.22, orbit = true },
		{ x = -0.54, z = 0.10, height = 1.26, width = 0.24, depth = 0.58, yaw = -30, pitch = 11, roll = -18, tint = 0.14, orbit = true },
		{ x = 0.16, z = 0.52, height = 0.96, width = 0.18, depth = 0.42, yaw = 68, pitch = 8, roll = -12, tint = 0.34, orbit = true },
		{ x = -0.14, z = -0.48, height = 0.84, width = 0.16, depth = 0.40, yaw = -64, pitch = -6, roll = 12, tint = 0.18, orbit = true },
	},
	ingot = {
		{ kind = "body", x = 0.00, z = 0.00, height = 0.58, width = 1.78, depth = 1.12, yaw = 0, tint = 0.10 },
		{ kind = "top", x = 0.00, z = 0.00, height = 0.22, width = 1.38, depth = 0.74, yaw = 0, tint = 0.22 },
		{ kind = "edge", x = 0.00, z = -0.42, height = 0.16, width = 1.10, depth = 0.08, yaw = 0, tint = 0.34 },
		{ kind = "edge", x = 0.00, z = 0.42, height = 0.16, width = 1.10, depth = 0.08, yaw = 0, tint = 0.18 },
	},
	artifact = {
		{ x = -0.05, z = -0.04, height = 2.35, width = 0.58, depth = 0.68, yaw = 4, pitch = -5, roll = -4, tint = 0.24 },
		{ x = -0.56, z = 0.06, height = 1.74, width = 0.42, depth = 0.50, yaw = -24, pitch = 7, roll = 8, tint = 0.08 },
		{ x = 0.52, z = 0.10, height = 1.58, width = 0.38, depth = 0.48, yaw = 26, pitch = -8, roll = -8, tint = 0.34 },
		{ x = 0.18, z = 0.48, height = 1.12, width = 0.30, depth = 0.38, yaw = 42, pitch = 5, roll = -4, tint = 0.18 },
		{ x = -0.32, z = -0.44, height = 1.02, width = 0.30, depth = 0.36, yaw = -38, pitch = -5, roll = 5, tint = 0.12 },
	},
	cluster = {
		{ x = -0.14, z = -0.02, height = 2.02, width = 0.54, depth = 0.62, yaw = -8, pitch = -3, roll = 4, tint = 0.18 },
		{ x = -0.62, z = 0.04, height = 1.55, width = 0.42, depth = 0.52, yaw = -32, pitch = 8, roll = 9, tint = 0.06 },
		{ x = 0.48, z = -0.06, height = 1.45, width = 0.40, depth = 0.48, yaw = 24, pitch = -8, roll = -7, tint = 0.30 },
		{ x = 0.08, z = 0.44, height = 1.18, width = 0.34, depth = 0.42, yaw = 40, pitch = 6, roll = -2, tint = 0.20 },
		{ x = -0.34, z = -0.46, height = 0.96, width = 0.30, depth = 0.36, yaw = -46, pitch = -5, roll = 6, tint = 0.10 },
	},
	gemstone = {
		{ x = -0.02, z = 0.00, height = 1.90, width = 0.50, depth = 0.60, yaw = 0, pitch = -3, roll = 2, tint = 0.18 },
		{ x = -0.46, z = 0.06, height = 1.34, width = 0.36, depth = 0.44, yaw = -28, pitch = 8, roll = 8, tint = 0.04 },
		{ x = 0.43, z = -0.02, height = 1.24, width = 0.34, depth = 0.42, yaw = 24, pitch = -7, roll = -6, tint = 0.30 },
		{ x = 0.08, z = 0.40, height = 0.92, width = 0.28, depth = 0.34, yaw = 38, pitch = 4, roll = -3, tint = 0.16 },
	},
}

local function normalizeVisualKey(value: any): string
	if value == nil then
		return ""
	end

	local text = string.lower(tostring(value))
	text = text:gsub("[%s%-]+", "_")
	text = text:gsub("[^%w_]", "")
	return text
end

local function blendColor(baseColor: Color3, targetColor: Color3, alpha: number): Color3
	return baseColor:Lerp(targetColor, alpha)
end

local function cloneDefinition(definition: any): any
	local clone = {}

	for key, value in pairs(definition) do
		clone[key] = value
	end

	return clone
end

local function cloneDefinitions(definitions: { [number]: any }): { [number]: any }
	local cloned = table.create(#definitions)

	for index, definition in ipairs(definitions) do
		cloned[index] = cloneDefinition(definition)
	end

	return cloned
end

local function combineHashes(...): number
	local hash = 5381

	for index = 1, select("#", ...) do
		local valueHash = ResourceVisuals.getStringHash(select(index, ...))
		hash = ((hash * 33) + valueHash + index) % MAX_HASH_VALUE
	end

	return hash
end

local function hashToUnit(hash: number): number
	return (hash % 1000000) / 1000000
end

local function sampleUnit(seed: number, channel: string, index: number): number
	return hashToUnit(combineHashes(seed, channel, index))
end

local function sampleSigned(seed: number, channel: string, index: number, amplitude: number): number
	return ((sampleUnit(seed, channel, index) * 2) - 1) * amplitude
end

local function sampleRange(seed: number, channel: string, index: number, minValue: number, maxValue: number): number
	return minValue + ((maxValue - minValue) * sampleUnit(seed, channel, index))
end

local function resolveVariantDefinitions(variantId: string?): { [number]: any }
	local normalizedVariant = normalizeVisualKey(variantId)
	return STATIC_VARIANT_DEFINITIONS[normalizedVariant] or STATIC_VARIANT_DEFINITIONS.gemstone
end

local function getProceduralRules(variantId: string?): any
	local normalizedVariant = normalizeVisualKey(variantId)
	return VARIANT_PROCEDURAL_RULES[normalizedVariant] or VARIANT_PROCEDURAL_RULES.gemstone
end

local function getProfileOverride(resourceTypeId: string?): any?
	local resourceKey = normalizeVisualKey(resourceTypeId)
	return RESOURCE_PROFILE_OVERRIDES[resourceKey]
end

local function getSourceDefinitionForIndex(variantId: string, baseDefinitions: { [number]: any }, index: number): any
	if index <= #baseDefinitions then
		return baseDefinitions[index]
	end

	-- Extra ingot pieces should stay as trims so the silhouette remains a single grounded bar.
	if variantId == "ingot" then
		local edgeDefinitions = { baseDefinitions[3], baseDefinitions[4], baseDefinitions[2] }
		return edgeDefinitions[((index - #baseDefinitions - 1) % #edgeDefinitions) + 1]
	end

	-- Extra eldritch pieces should orbit around the center instead of duplicating the anchor shard.
	if variantId == "eldritch" then
		local orbitIndex = (((index - #baseDefinitions) - 1) % (#baseDefinitions - 1)) + 2
		return baseDefinitions[orbitIndex]
	end

	return baseDefinitions[((index - 1) % #baseDefinitions) + 1]
end

function ResourceVisuals.getStringHash(value: any): number
	local hash = 0
	local text = tostring(value or "")

	for index = 1, #text do
		hash = (hash * 33 + string.byte(text, index)) % MAX_HASH_VALUE
	end

	return hash
end

function ResourceVisuals.getRarityRank(rarity: string?): number
	return RESOURCE_RARITY_ORDER[rarity or "Common"] or 1
end

function ResourceVisuals.getResourceRarityScale(rarity: string?): number
	local rarityRank = ResourceVisuals.getRarityRank(rarity)
	return 0.92 + ((rarityRank - 1) * 0.14)
end

function ResourceVisuals.getResourceVariantShape(resourceTypeId: string?, resourceDefinition: any?): string
	local resourceKey = normalizeVisualKey(resourceTypeId)
	local rarity = if resourceDefinition ~= nil and resourceDefinition.rarity ~= nil then resourceDefinition.rarity else "Common"
	local rarityRank = ResourceVisuals.getRarityRank(rarity)
	local explicitVariant = if resourceDefinition ~= nil and type(resourceDefinition.visualVariant) == "string"
		then resourceDefinition.visualVariant
		else nil
	local variantId = explicitVariant or RESOURCE_TYPE_VARIANTS[resourceKey] or "gemstone"
	local override = getProfileOverride(resourceTypeId)
	if override ~= nil and type(override.variantId) == "string" then
		variantId = override.variantId
	end

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

function ResourceVisuals.getOreCrystalDefinitions(variantId: string?): { [number]: any }
	return cloneDefinitions(resolveVariantDefinitions(variantId))
end

function ResourceVisuals.getProceduralSeed(stableVisualId: any, resourceTypeId: string?, variantId: string?): number
	local visualKey = stableVisualId
	local normalizedVariant = normalizeVisualKey(variantId)
	if STATIC_VARIANT_DEFINITIONS[normalizedVariant] == nil then
		normalizedVariant = "gemstone"
	end

	if visualKey == nil or tostring(visualKey) == "" then
		visualKey = resourceTypeId or normalizedVariant or "resource"
	end

	return combineHashes(visualKey, resourceTypeId or "resource", normalizedVariant)
end

function ResourceVisuals.getProceduralCrystalDefinitions(
	variantId: string?,
	stableVisualId: any,
	resourceTypeId: string?
): { [number]: any }
	local normalizedVariant = normalizeVisualKey(variantId)
	if normalizedVariant == "" or STATIC_VARIANT_DEFINITIONS[normalizedVariant] == nil then
		normalizedVariant = "gemstone"
	end

	local baseDefinitions = resolveVariantDefinitions(normalizedVariant)
	local proceduralRules = getProceduralRules(normalizedVariant)
	local proceduralSeed = ResourceVisuals.getProceduralSeed(stableVisualId, resourceTypeId, normalizedVariant)
	local countRange = proceduralRules.maxCount - proceduralRules.minCount
	local targetCount = proceduralRules.minCount + math.floor(sampleUnit(proceduralSeed, "count", 1) * (countRange + 1))
	local definitions = table.create(targetCount)

	for index = 1, targetCount do
		local source = cloneDefinition(getSourceDefinitionForIndex(normalizedVariant, baseDefinitions, index))
		local isPrimaryIngotPiece = normalizedVariant == "ingot" and (source.kind == "body" or source.kind == "top")
		local positionAmplitude = if isPrimaryIngotPiece then proceduralRules.positionJitter * 0.35 else proceduralRules.positionJitter
		local rotationAmplitude = if normalizedVariant == "ingot" then proceduralRules.rotationJitter * 0.35 else proceduralRules.rotationJitter

		-- We vary around the static family definitions instead of replacing them so each family keeps its readable silhouette.
		source.x = source.x + sampleSigned(proceduralSeed, "x", index, positionAmplitude)
		source.z = source.z + sampleSigned(proceduralSeed, "z", index, positionAmplitude)
		source.height = math.max(0.08, source.height * sampleRange(proceduralSeed, "height", index, 1 - proceduralRules.heightJitter, 1 + proceduralRules.heightJitter))
		source.width = math.max(0.08, source.width * sampleRange(proceduralSeed, "width", index, 1 - proceduralRules.widthJitter, 1 + proceduralRules.widthJitter))
		source.depth = math.max(0.08, source.depth * sampleRange(proceduralSeed, "depth", index, 1 - proceduralRules.depthJitter, 1 + proceduralRules.depthJitter))
		source.yaw = source.yaw + sampleSigned(proceduralSeed, "yaw", index, rotationAmplitude)
		source.pitch = (source.pitch or 0) + sampleSigned(proceduralSeed, "pitch", index, rotationAmplitude * 0.75)
		source.roll = (source.roll or 0) + sampleSigned(proceduralSeed, "roll", index, rotationAmplitude * 0.75)
		source.tint = math.clamp((source.tint or 0) + sampleSigned(proceduralSeed, "tint", index, proceduralRules.tintJitter), 0, 0.75)
		definitions[index] = source
	end

	return definitions
end

function ResourceVisuals.getPlacedPhysicalScale(sizeId: string?, sizeValue: number?): number
	return SizeRules.getResourceVisualScale(sizeId, sizeValue)
end

function ResourceVisuals.getPlacedRootSize(sizeId: string?, sizeValue: number?): Vector3
	return PLACED_RESOURCE_BASE_SIZE * ResourceVisuals.getPlacedPhysicalScale(sizeId, sizeValue)
end

function ResourceVisuals.getPlacedBaseHeight(sizeId: string?, sizeValue: number?): number
	return PLACED_RESOURCE_BASE_HEIGHT * ResourceVisuals.getPlacedPhysicalScale(sizeId, sizeValue)
end

function ResourceVisuals.resolvePlacedVisualProfile(
	resourceTypeId: string?,
	traitId: string?,
	sizeId: string?,
	sizeValue: number?,
	stableVisualId: any
)
	return ResourceVisuals.resolveRevealProfile(resourceTypeId, traitId, sizeId, sizeValue, stableVisualId)
end

function ResourceVisuals.resolveRevealProfile(
	resourceTypeId: string?,
	traitId: string?,
	sizeId: string?,
	sizeValue: number?,
	stableVisualId: any
)
	local resourceDefinition = if resourceTypeId ~= nil then Resources[resourceTypeId] else nil
	local rarity = if resourceDefinition ~= nil and resourceDefinition.rarity ~= nil then resourceDefinition.rarity else "Common"
	local baseColor = if resourceDefinition ~= nil and resourceDefinition.color ~= nil
		then resourceDefinition.color
		else RESOURCE_RARITY_ACCENTS[rarity] or Color3.fromRGB(240, 240, 255)
	local rarityRank = ResourceVisuals.getRarityRank(rarity)
	local accentColor = blendColor(baseColor, RESOURCE_RARITY_ACCENTS[rarity] or baseColor, math.clamp(0.15 + (rarityRank * 0.12), 0, 0.65))
	local glowColor = blendColor(accentColor, Color3.fromRGB(255, 255, 255), 0.25)
	local traitDefinition = if traitId ~= nil then Traits[traitId] else nil
	local override = getProfileOverride(resourceTypeId)
	if override ~= nil then
		if type(override.baseColor) == "Color3" then
			baseColor = override.baseColor
		end
		if type(override.accentColor) == "Color3" then
			accentColor = override.accentColor
		end
		if type(override.glowColor) == "Color3" then
			glowColor = override.glowColor
		end
	end
	local traitAccent = if traitDefinition ~= nil and traitDefinition.accentColor ~= nil then traitDefinition.accentColor else accentColor
	local traitGlow = if traitDefinition ~= nil and traitDefinition.glowColor ~= nil then traitDefinition.glowColor else glowColor
	local sizeFactor = SizeRules.getScaleValue(sizeId, sizeValue)
	local visualSizeFactor = SizeRules.getResourceVisualScale(sizeId, sizeValue)
	local burstScale = if traitDefinition ~= nil and type(traitDefinition.burstScale) == "number" then traitDefinition.burstScale else 1
	local shineStrength = if traitDefinition ~= nil and type(traitDefinition.shineStrength) == "number" then traitDefinition.shineStrength else 0.2
	local variantId = ResourceVisuals.getResourceVariantShape(resourceTypeId, resourceDefinition)
	local proceduralId = stableVisualId or resourceTypeId or "resource"
	local proceduralSeed = ResourceVisuals.getProceduralSeed(proceduralId, resourceTypeId, variantId)

	if override ~= nil then
		if type(override.scaleMultiplier) == "number" then
			visualSizeFactor *= override.scaleMultiplier
		end
		if type(override.minScale) == "number" then
			visualSizeFactor = math.max(override.minScale, visualSizeFactor)
		end
		if type(override.maxScale) == "number" then
			visualSizeFactor = math.min(override.maxScale, visualSizeFactor)
		end
		if traitDefinition == nil and type(override.shineStrength) == "number" then
			shineStrength = override.shineStrength
		end
	end

	return {
		resourceTypeId = resourceTypeId,
		displayName = if resourceDefinition ~= nil and resourceDefinition.displayName ~= nil then resourceDefinition.displayName else "Resource",
		rarity = rarity,
		rarityRank = rarityRank,
		variantId = variantId,
		baseColor = baseColor,
		accentColor = accentColor,
		glowColor = glowColor,
		traitAccentColor = traitAccent,
		traitGlowColor = traitGlow,
		sizeId = sizeId or "medium",
		sizeValue = sizeFactor,
		scale = ResourceVisuals.getResourceRarityScale(rarity) * visualSizeFactor,
		burstScale = burstScale,
		shineStrength = shineStrength,
		hash = ResourceVisuals.getStringHash(resourceTypeId or "resource"),
		proceduralId = proceduralId,
		proceduralSeed = proceduralSeed,
		crystalDefinitions = ResourceVisuals.getProceduralCrystalDefinitions(variantId, proceduralId, resourceTypeId),
	}
end

return ResourceVisuals
