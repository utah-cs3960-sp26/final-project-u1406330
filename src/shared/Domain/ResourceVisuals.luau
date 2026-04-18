--!strict

-- Deterministic shared rules for Resource Visuals so gameplay behavior can be reused by the server, client presentation, and specs.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Resources = require(Shared.Config.Resources)
local SizeRules = require(Shared.Domain.SizeRules)
local Traits = require(Shared.Config.Traits)

local ResourceVisuals = {}

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
	moonstone = "gemstone",
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

function ResourceVisuals.getStringHash(value: any): number
	local hash = 0
	local text = tostring(value or "")

	for index = 1, #text do
		hash = (hash * 33 + string.byte(text, index)) % 2147483647
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
	if variantId == "eldritch" then
		return {
			{ x = 0.00, z = 0.00, height = 2.48, width = 0.46, depth = 0.54, yaw = 8, pitch = -6, roll = 4, tint = 0.28 },
			{ x = 0.00, z = 0.00, height = 1.64, width = 0.22, depth = 0.24, yaw = -22, pitch = 0, roll = 0, tint = 0.42, orbit = true },
			{ x = 0.56, z = -0.06, height = 1.34, width = 0.24, depth = 0.62, yaw = 34, pitch = -12, roll = 22, tint = 0.22, orbit = true },
			{ x = -0.54, z = 0.10, height = 1.26, width = 0.24, depth = 0.58, yaw = -30, pitch = 11, roll = -18, tint = 0.14, orbit = true },
			{ x = 0.16, z = 0.52, height = 0.96, width = 0.18, depth = 0.42, yaw = 68, pitch = 8, roll = -12, tint = 0.34, orbit = true },
			{ x = -0.14, z = -0.48, height = 0.84, width = 0.16, depth = 0.40, yaw = -64, pitch = -6, roll = 12, tint = 0.18, orbit = true },
		}
	elseif variantId == "ingot" then
		return {
			{ kind = "body", x = 0.00, z = 0.00, height = 0.58, width = 1.78, depth = 1.12, yaw = 0, tint = 0.10 },
			{ kind = "top", x = 0.00, z = 0.00, height = 0.22, width = 1.38, depth = 0.74, yaw = 0, tint = 0.22 },
			{ kind = "edge", x = 0.00, z = -0.42, height = 0.16, width = 1.10, depth = 0.08, yaw = 0, tint = 0.34 },
			{ kind = "edge", x = 0.00, z = 0.42, height = 0.16, width = 1.10, depth = 0.08, yaw = 0, tint = 0.18 },
		}
	elseif variantId == "artifact" then
		return {
			{ x = -0.05, z = -0.04, height = 2.35, width = 0.58, depth = 0.68, yaw = 4, pitch = -5, roll = -4, tint = 0.24 },
			{ x = -0.56, z = 0.06, height = 1.74, width = 0.42, depth = 0.50, yaw = -24, pitch = 7, roll = 8, tint = 0.08 },
			{ x = 0.52, z = 0.10, height = 1.58, width = 0.38, depth = 0.48, yaw = 26, pitch = -8, roll = -8, tint = 0.34 },
			{ x = 0.18, z = 0.48, height = 1.12, width = 0.30, depth = 0.38, yaw = 42, pitch = 5, roll = -4, tint = 0.18 },
			{ x = -0.32, z = -0.44, height = 1.02, width = 0.30, depth = 0.36, yaw = -38, pitch = -5, roll = 5, tint = 0.12 },
		}
	elseif variantId == "cluster" then
		return {
			{ x = -0.14, z = -0.02, height = 2.02, width = 0.54, depth = 0.62, yaw = -8, pitch = -3, roll = 4, tint = 0.18 },
			{ x = -0.62, z = 0.04, height = 1.55, width = 0.42, depth = 0.52, yaw = -32, pitch = 8, roll = 9, tint = 0.06 },
			{ x = 0.48, z = -0.06, height = 1.45, width = 0.40, depth = 0.48, yaw = 24, pitch = -8, roll = -7, tint = 0.30 },
			{ x = 0.08, z = 0.44, height = 1.18, width = 0.34, depth = 0.42, yaw = 40, pitch = 6, roll = -2, tint = 0.20 },
			{ x = -0.34, z = -0.46, height = 0.96, width = 0.30, depth = 0.36, yaw = -46, pitch = -5, roll = 6, tint = 0.10 },
		}
	end

	return {
		{ x = -0.02, z = 0.00, height = 1.90, width = 0.50, depth = 0.60, yaw = 0, pitch = -3, roll = 2, tint = 0.18 },
		{ x = -0.46, z = 0.06, height = 1.34, width = 0.36, depth = 0.44, yaw = -28, pitch = 8, roll = 8, tint = 0.04 },
		{ x = 0.43, z = -0.02, height = 1.24, width = 0.34, depth = 0.42, yaw = 24, pitch = -7, roll = -6, tint = 0.30 },
		{ x = 0.08, z = 0.40, height = 0.92, width = 0.28, depth = 0.34, yaw = 38, pitch = 4, roll = -3, tint = 0.16 },
	}
end

function ResourceVisuals.getPlacedPhysicalScale(sizeId: string?, sizeValue: number?): number
	return SizeRules.getScaleValue(sizeId, sizeValue)
end

function ResourceVisuals.getPlacedRootSize(sizeId: string?, sizeValue: number?): Vector3
	return PLACED_RESOURCE_BASE_SIZE * ResourceVisuals.getPlacedPhysicalScale(sizeId, sizeValue)
end

function ResourceVisuals.getPlacedBaseHeight(sizeId: string?, sizeValue: number?): number
	return PLACED_RESOURCE_BASE_HEIGHT * ResourceVisuals.getPlacedPhysicalScale(sizeId, sizeValue)
end

function ResourceVisuals.resolveRevealProfile(resourceTypeId: string?, traitId: string?, sizeId: string?, sizeValue: number?)
	local resourceDefinition = if resourceTypeId ~= nil then Resources[resourceTypeId] else nil
	local rarity = if resourceDefinition ~= nil and resourceDefinition.rarity ~= nil then resourceDefinition.rarity else "Common"
	local baseColor = if resourceDefinition ~= nil and resourceDefinition.color ~= nil
		then resourceDefinition.color
		else RESOURCE_RARITY_ACCENTS[rarity] or Color3.fromRGB(240, 240, 255)
	local rarityRank = ResourceVisuals.getRarityRank(rarity)
	local accentColor = blendColor(baseColor, RESOURCE_RARITY_ACCENTS[rarity] or baseColor, math.clamp(0.15 + (rarityRank * 0.12), 0, 0.65))
	local glowColor = blendColor(accentColor, Color3.fromRGB(255, 255, 255), 0.25)
	local traitDefinition = if traitId ~= nil then Traits[traitId] else nil
	local traitAccent = if traitDefinition ~= nil and traitDefinition.accentColor ~= nil then traitDefinition.accentColor else accentColor
	local traitGlow = if traitDefinition ~= nil and traitDefinition.glowColor ~= nil then traitDefinition.glowColor else glowColor
	local sizeFactor = SizeRules.getScaleValue(sizeId, sizeValue)
	local burstScale = if traitDefinition ~= nil and type(traitDefinition.burstScale) == "number" then traitDefinition.burstScale else 1
	local shineStrength = if traitDefinition ~= nil and type(traitDefinition.shineStrength) == "number" then traitDefinition.shineStrength else 0.2

	return {
		resourceTypeId = resourceTypeId,
		displayName = if resourceDefinition ~= nil and resourceDefinition.displayName ~= nil then resourceDefinition.displayName else "Resource",
		rarity = rarity,
		rarityRank = rarityRank,
		variantId = ResourceVisuals.getResourceVariantShape(resourceTypeId, resourceDefinition),
		baseColor = baseColor,
		accentColor = accentColor,
		glowColor = glowColor,
		traitAccentColor = traitAccent,
		traitGlowColor = traitGlow,
		sizeId = sizeId or "medium",
		sizeValue = sizeFactor,
		scale = ResourceVisuals.getResourceRarityScale(rarity) * sizeFactor,
		burstScale = burstScale,
		shineStrength = shineStrength,
		hash = ResourceVisuals.getStringHash(resourceTypeId or "resource"),
	}
end

return ResourceVisuals
