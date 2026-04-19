--!strict

-- Deterministic shared rules for World Label Presentation so gameplay behavior can be reused by the server, client presentation, and specs.

local WorldLabelPresentation = {}

local RESOURCE_RARITY_LABEL_COLORS = {
	Common = Color3.fromRGB(244, 249, 255),
	Uncommon = Color3.fromRGB(188, 145, 255),
	Rare = Color3.fromRGB(108, 228, 193),
	Epic = Color3.fromRGB(118, 213, 255),
	Legendary = Color3.fromRGB(255, 224, 117),
}

function WorldLabelPresentation.resolveHoveredResourceId(targetResourceId: string?, ancestorResourceId: string?): string?
	if type(targetResourceId) == "string" and targetResourceId ~= "" then
		return targetResourceId
	end

	if type(ancestorResourceId) == "string" and ancestorResourceId ~= "" then
		return ancestorResourceId
	end

	return nil
end

function WorldLabelPresentation.shouldShowPlacedResourceLabel(resourceId: string?, hoveredResourceId: string?): boolean
	if type(resourceId) ~= "string" or resourceId == "" then
		return false
	end

	return resourceId == hoveredResourceId
end

function WorldLabelPresentation.getPlacedResourceLabelAccentColor(rarityLabel: string?): Color3
	if type(rarityLabel) == "string" and RESOURCE_RARITY_LABEL_COLORS[rarityLabel] ~= nil then
		return RESOURCE_RARITY_LABEL_COLORS[rarityLabel]
	end

	return RESOURCE_RARITY_LABEL_COLORS.Common
end

function WorldLabelPresentation.getPlacedResourceLabelText(
	resourceDisplayName: string?,
	traitDisplayName: string?,
	sizeDisplayName: string?,
	rarityLabel: string?
): (string, string)
	local baseDisplayName = if type(resourceDisplayName) == "string" and resourceDisplayName ~= ""
		then resourceDisplayName
		else "Unknown Resource"
	local normalizedTraitDisplayName = if type(traitDisplayName) == "string" and traitDisplayName ~= "" and traitDisplayName ~= "None"
		then traitDisplayName
		else nil
	local normalizedSizeDisplayName = if type(sizeDisplayName) == "string" and sizeDisplayName ~= "" and sizeDisplayName ~= "Medium"
		then sizeDisplayName
		else nil
	local normalizedRarityLabel = if type(rarityLabel) == "string" and rarityLabel ~= ""
		then rarityLabel
		else "Common"

	local title = baseDisplayName
	if normalizedTraitDisplayName ~= nil then
		title = string.format("%s %s", normalizedTraitDisplayName, title)
	end
	if normalizedSizeDisplayName ~= nil then
		title = string.format("%s %s", normalizedSizeDisplayName, title)
	end

	local subtitle = normalizedRarityLabel
	if normalizedTraitDisplayName ~= nil then
		subtitle = string.format("%s - %s", subtitle, normalizedTraitDisplayName)
	end
	if normalizedSizeDisplayName ~= nil then
		subtitle = string.format("%s (%s)", subtitle, normalizedSizeDisplayName)
	end

	return title, subtitle
end

return WorldLabelPresentation
