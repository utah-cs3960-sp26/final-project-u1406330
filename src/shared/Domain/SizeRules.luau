--!strict

-- Deterministic shared rules for Size Rules so gameplay behavior can be reused by the server, client presentation, and specs.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Sizes = require(Shared.Config.Sizes)

local SizeRules = {}

local function getGlobalScaleBounds()
	local minScale = math.huge
	local maxScale = -math.huge

	for _, definition in ipairs(Sizes.order) do
		if type(definition.minScale) == "number" then
			minScale = math.min(minScale, definition.minScale)
		end
		if type(definition.maxScale) == "number" then
			maxScale = math.max(maxScale, definition.maxScale)
		end
	end

	if minScale == math.huge then
		minScale = 1.0
	end
	if maxScale == -math.huge then
		maxScale = 1.0
	end

	return minScale, maxScale
end

local GLOBAL_MIN_SCALE, GLOBAL_MAX_SCALE = getGlobalScaleBounds()

local function roundToPlaces(value: number, places: number): number
	local magnitude = 10 ^ places
	return math.floor((value * magnitude) + 0.5) / magnitude
end

function SizeRules.clampScale(scaleValue: number?): number
	if type(scaleValue) ~= "number" then
		return Sizes.medium.scaleFactor or 1.0
	end

	return math.clamp(scaleValue, GLOBAL_MIN_SCALE, GLOBAL_MAX_SCALE)
end

function SizeRules.getDefinitionById(sizeId: string?)
	if type(sizeId) ~= "string" then
		return nil
	end

	return Sizes[sizeId]
end

function SizeRules.getDefinitionForScale(scaleValue: number?)
	local resolvedScale = SizeRules.clampScale(scaleValue)

	for _, definition in ipairs(Sizes.order) do
		local minScale = if type(definition.minScale) == "number" then definition.minScale else definition.scaleFactor or 1.0
		local maxScale = if type(definition.maxScale) == "number" then definition.maxScale else definition.scaleFactor or 1.0
		if resolvedScale >= minScale and resolvedScale <= maxScale then
			return definition
		end
	end

	if resolvedScale <= GLOBAL_MIN_SCALE then
		return Sizes.order[1]
	end

	return Sizes.order[#Sizes.order] or Sizes.medium
end

function SizeRules.resolveDefinition(sizeId: string?, sizeValue: number?)
	if type(sizeValue) == "number" then
		return SizeRules.getDefinitionForScale(sizeValue)
	end

	local definition = SizeRules.getDefinitionById(sizeId)
	if definition ~= nil then
		return definition
	end

	return Sizes.medium
end

function SizeRules.getScaleValue(sizeId: string?, sizeValue: number?): number
	if type(sizeValue) == "number" then
		return SizeRules.clampScale(sizeValue)
	end

	local definition = SizeRules.resolveDefinition(sizeId, nil)
	if definition ~= nil and type(definition.scaleFactor) == "number" then
		return definition.scaleFactor
	end

	return 1.0
end

function SizeRules.getResourceVisualScale(sizeId: string?, sizeValue: number?): number
	local baseScale = SizeRules.getScaleValue(sizeId, sizeValue)
	local visualMultiplier = if type(Sizes.resourceVisualScaleMultiplier) == "number" then Sizes.resourceVisualScaleMultiplier else 1.0
	return baseScale * visualMultiplier
end

function SizeRules.getSellMultiplier(sizeId: string?, sizeValue: number?): number
	local definition = SizeRules.resolveDefinition(sizeId, sizeValue)
	if definition ~= nil and type(definition.sellMultiplier) == "number" then
		return definition.sellMultiplier
	end

	return 1.0
end

function SizeRules.getDisplayName(sizeId: string?, sizeValue: number?): string
	local definition = SizeRules.resolveDefinition(sizeId, sizeValue)
	return if definition ~= nil and type(definition.displayName) == "string" then definition.displayName else "Medium"
end

function SizeRules.getDisplayText(sizeId: string?, sizeValue: number?): string
	return string.format("%s (%.2fx)", SizeRules.getDisplayName(sizeId, sizeValue), roundToPlaces(SizeRules.getScaleValue(sizeId, sizeValue), 2))
end

return SizeRules
