--!strict

-- Deterministic shared rules for the Resource Guide so the HUD can present rarity chart data from the shared resource catalog.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Geodes = require(Shared.Config.Geodes)
local Pickaxes = require(Shared.Config.Pickaxes)
local Resources = require(Shared.Config.Resources)
local ResourceVisuals = require(Shared.Domain.ResourceVisuals)
local Traits = require(Shared.Config.Traits)

local ResourceGuide = {}

local RARITY_ORDER = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
}

local RARITY_ACCENTS = {
	Common = Color3.fromRGB(255, 226, 122),
	Uncommon = Color3.fromRGB(196, 155, 255),
	Rare = Color3.fromRGB(101, 236, 199),
	Epic = Color3.fromRGB(119, 214, 255),
	Legendary = Color3.fromRGB(255, 189, 101),
}

local DEFAULT_PICKAXE_ID = "stone_pickaxe"

local TRAIT_SORT_INDEX = {}

for index, traitDefinition in ipairs(Traits.order or {}) do
	if traitDefinition ~= nil and type(traitDefinition.id) == "string" then
		TRAIT_SORT_INDEX[traitDefinition.id] = index
	end
end

local function compareCatalogEntries(leftEntry, rightEntry)
	if leftEntry.rank ~= rightEntry.rank then
		return leftEntry.rank < rightEntry.rank
	end

	if leftEntry.displayName ~= rightEntry.displayName then
		return leftEntry.displayName < rightEntry.displayName
	end

	return leftEntry.resourceId < rightEntry.resourceId
end

local function buildCatalogEntries()
	local entries = {}

	for resourceId, resourceDefinition in pairs(Resources) do
		if type(resourceDefinition) ~= "table" then
			continue
		end

		table.insert(entries, {
			resourceId = resourceId,
			displayName = tostring(resourceDefinition.displayName or resourceId),
			rarity = tostring(resourceDefinition.rarity or "Common"),
			rank = ResourceVisuals.getRarityRank(resourceDefinition.rarity),
			color = resourceDefinition.color,
			variantId = ResourceVisuals.getResourceVariantShape(resourceId, resourceDefinition),
		})
	end

	table.sort(entries, compareCatalogEntries)
	return entries
end

local CATALOG_ENTRIES = buildCatalogEntries()

local function roundToPlaces(value: number, places: number): number
	local scalar = 10 ^ places
	return math.floor((value * scalar) + 0.5) / scalar
end

local function formatPercent(percentValue: number): string
	if percentValue <= 0 then
		return "0.0%"
	end

	local places = 1
	if percentValue < 10 then
		places = 2
	end
	if percentValue < 1 then
		places = 3
	end

	return string.format("%." .. tostring(places) .. "f%%", roundToPlaces(percentValue, places))
end

local function getResolvedPickaxe(pickaxeId: string?)
	if type(pickaxeId) == "string" and Pickaxes.catalog[pickaxeId] ~= nil then
		return Pickaxes.catalog[pickaxeId]
	end

	return Pickaxes.catalog[DEFAULT_PICKAXE_ID]
end

local function getTotalWeight(entries: { any }?): number
	if type(entries) ~= "table" then
		return 0
	end

	local totalWeight = 0

	for _, entry in ipairs(entries) do
		local weight = if type(entry.weight) == "number" then entry.weight else 0
		if weight > 0 then
			totalWeight += weight
		end
	end

	return totalWeight
end

local function buildRarityChances(pickaxeDefinition: any)
	local rarityChances = {}

	for _, rarity in ipairs(RARITY_ORDER) do
		rarityChances[rarity] = 0
	end

	if type(pickaxeDefinition) ~= "table" then
		return rarityChances, 0
	end

	local geodeChance = math.max(0, tonumber(pickaxeDefinition.geodeChance) or 0) / 100
	local geodeWeights = pickaxeDefinition.geodeWeights
	local totalGeodeWeight = getTotalWeight(geodeWeights)

	if geodeChance <= 0 or totalGeodeWeight <= 0 then
		return rarityChances, 0
	end

	for _, geodeEntry in ipairs(geodeWeights) do
		local geodeId = geodeEntry.geodeId
		local geodeWeight = if type(geodeEntry.weight) == "number" then geodeEntry.weight else 0
		local geodeDefinition = if type(geodeId) == "string" then Geodes[geodeId] else nil
		if geodeWeight <= 0 or geodeDefinition == nil then
			continue
		end

		local totalResourceWeight = getTotalWeight(geodeDefinition.rolls)
		if totalResourceWeight <= 0 then
			continue
		end

		local geodeShare = geodeChance * (geodeWeight / totalGeodeWeight)

		for _, roll in ipairs(geodeDefinition.rolls) do
			local resourceId = roll.resourceId
			local resourceWeight = if type(roll.weight) == "number" then roll.weight else 0
			local resourceDefinition = if type(resourceId) == "string" then Resources[resourceId] else nil
			if resourceWeight <= 0 or resourceDefinition == nil then
				continue
			end

			local rarity = if type(resourceDefinition.rarity) == "string" then resourceDefinition.rarity else "Common"
			rarityChances[rarity] = (rarityChances[rarity] or 0) + (geodeShare * (resourceWeight / totalResourceWeight))
		end
	end

	local totalChance = 0
	for _, rarity in ipairs(RARITY_ORDER) do
		totalChance += rarityChances[rarity] or 0
	end

	return rarityChances, totalChance
end

function ResourceGuide.getRarityOrder(): { string }
	local order = table.clone(RARITY_ORDER)
	return order
end

function ResourceGuide.getDefaultPickaxeId(): string
	return DEFAULT_PICKAXE_ID
end

function ResourceGuide.ensureCollectionState(resourceGuideState: any): { discoveredResources: { [string]: any } }
	if type(resourceGuideState) ~= "table" then
		return {
			discoveredResources = {},
		}
	end

	if type(resourceGuideState.discoveredResources) ~= "table" then
		resourceGuideState.discoveredResources = {}
	end

	return resourceGuideState
end

function ResourceGuide.recordDiscovery(profile: any, resourceTypeId: string?, traitId: string?): boolean
	if type(profile) ~= "table" or type(resourceTypeId) ~= "string" or Resources[resourceTypeId] == nil then
		return false
	end

	-- Keep collection progress attached to the authoritative profile so all grant paths write the same persisted state.
	local collectionState = ResourceGuide.ensureCollectionState(profile.resourceGuide)
	profile.resourceGuide = collectionState

	local discoveredResources = collectionState.discoveredResources
	local resourceEntry = discoveredResources[resourceTypeId]
	if type(resourceEntry) ~= "table" then
		resourceEntry = {
			found = true,
			discoveredTraits = {},
		}
		discoveredResources[resourceTypeId] = resourceEntry
	else
		resourceEntry.found = true
		if type(resourceEntry.discoveredTraits) ~= "table" then
			resourceEntry.discoveredTraits = {}
		end
	end

	local resolvedTraitId = if type(traitId) == "string" and Traits[traitId] ~= nil then traitId else "none"
	resourceEntry.discoveredTraits[resolvedTraitId] = true
	return true
end

local function sortDiscoveredTraitNames(leftName: string, rightName: string): boolean
	local leftDefinition = nil
	local rightDefinition = nil

	for _, traitDefinition in ipairs(Traits.order or {}) do
		if traitDefinition.displayName == leftName then
			leftDefinition = traitDefinition
		end
		if traitDefinition.displayName == rightName then
			rightDefinition = traitDefinition
		end
	end

	local leftIndex = if leftDefinition ~= nil then TRAIT_SORT_INDEX[leftDefinition.id] or 999 else 999
	local rightIndex = if rightDefinition ~= nil then TRAIT_SORT_INDEX[rightDefinition.id] or 999 else 999
	if leftIndex ~= rightIndex then
		return leftIndex < rightIndex
	end

	return leftName < rightName
end

function ResourceGuide.getCollectionSlots(resourceGuideState: any): { any }
	local collectionState = ResourceGuide.ensureCollectionState(resourceGuideState)
	local slots = table.create(#CATALOG_ENTRIES)

	for layoutOrder, catalogEntry in ipairs(CATALOG_ENTRIES) do
		local discoveredEntry = collectionState.discoveredResources[catalogEntry.resourceId]
		local isFound = type(discoveredEntry) == "table" and discoveredEntry.found == true
		local discoveredTraitNames = {}

		if isFound and type(discoveredEntry.discoveredTraits) == "table" then
			for traitId in pairs(discoveredEntry.discoveredTraits) do
				if traitId ~= "none" then
					local traitDefinition = Traits[traitId]
					if traitDefinition ~= nil then
						table.insert(discoveredTraitNames, traitDefinition.displayName or traitId)
					end
				end
			end
		end

		table.sort(discoveredTraitNames, sortDiscoveredTraitNames)

		table.insert(slots, {
			layoutOrder = layoutOrder,
			resourceId = catalogEntry.resourceId,
			displayName = if isFound then catalogEntry.displayName else "???",
			realDisplayName = catalogEntry.displayName,
			rarity = catalogEntry.rarity,
			rank = catalogEntry.rank,
			color = catalogEntry.color,
			variantId = catalogEntry.variantId,
			isFound = isFound,
			discoveredTraitNames = discoveredTraitNames,
			hoverTitle = if isFound then catalogEntry.displayName else "???",
			hoverAttributesText = if isFound
				then if #discoveredTraitNames > 0 then table.concat(discoveredTraitNames, ", ") else "No attributes found yet"
				else "???",
		})
	end

	return slots
end

function ResourceGuide.getGuideSummary(pickaxeId: string?): any
	local pickaxeDefinition = getResolvedPickaxe(pickaxeId)
	local _, totalChance = buildRarityChances(pickaxeDefinition)

	return {
		pickaxeId = pickaxeDefinition.id,
		pickaxeDisplayName = pickaxeDefinition.displayName,
		totalResourceChance = totalChance,
		totalResourceChanceText = formatPercent(totalChance * 100),
		subtitleText = string.format("Per mine swing with %s equipped.", pickaxeDefinition.displayName),
		hintText = string.format(
			"Resource drops total %s per swing. Better pickaxes raise geode chance and shift weight toward rarer geodes.",
			formatPercent(totalChance * 100)
		),
	}
end

function ResourceGuide.getGuideRows(pickaxeId: string?): { any }
	local pickaxeDefinition = getResolvedPickaxe(pickaxeId)
	local rarityChances, totalChance = buildRarityChances(pickaxeDefinition)
	local rows = {}
	local maxChance = 0

	for _, rarity in ipairs(RARITY_ORDER) do
		maxChance = math.max(maxChance, rarityChances[rarity] or 0)
	end

	for index, rarity in ipairs(RARITY_ORDER) do
		local chance = rarityChances[rarity] or 0
		local share = if totalChance > 0 then chance / totalChance else 0
		local percent = chance * 100
		local accentColor = RARITY_ACCENTS[rarity] or Color3.fromRGB(255, 226, 122)
		local backgroundColor = accentColor:Lerp(Color3.fromRGB(255, 255, 255), 0.68)
		local highlightColor = accentColor:Lerp(Color3.fromRGB(255, 255, 255), 0.36)
		local rank = ResourceVisuals.getRarityRank(rarity)

		table.insert(rows, {
			layoutOrder = index,
			rarity = rarity,
			rank = rank,
			pickaxeId = pickaxeDefinition.id,
			pickaxeDisplayName = pickaxeDefinition.displayName,
			chance = chance,
			share = share,
			barFillShare = if maxChance > 0 then chance / maxChance else 0,
			percentage = percent,
			percentageText = formatPercent(percent),
			countText = string.format("Drop share %s", formatPercent(share * 100)),
			accentColor = accentColor,
			backgroundColor = backgroundColor,
			highlightColor = highlightColor,
		})
	end

	return rows
end

return ResourceGuide
