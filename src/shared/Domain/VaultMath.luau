--!strict

local RewardPresentation = require(script.Parent.RewardPresentation)

local VaultMath = {}

function VaultMath.getResourceSellValue(resourceDefinition, traitDefinition, sizeDefinition): number
	if resourceDefinition == nil then
		return 0
	end

	local baseCoinRate = resourceDefinition.baseCoinRate or 0
	local traitMultiplier = if traitDefinition ~= nil then traitDefinition.sellMultiplier or traitDefinition.multiplier or 1 else 1
	local sizeMultiplier = if sizeDefinition ~= nil then sizeDefinition.sellMultiplier or 1 else 1
	return math.max(1, math.floor((baseCoinRate * 25 * traitMultiplier * sizeMultiplier) + 0.5))
end

function VaultMath.getGeodeSellValue(geodeDefinition): number
	if geodeDefinition == nil then
		return 0
	end

	local geodeSeconds = geodeDefinition.geodeSeconds or 0
	return math.max(1, math.floor((geodeSeconds * 3) + 0.5))
end

function VaultMath.getResourceRarityTier(resourceDefinition): number
	return RewardPresentation.getResourceCelebrationTier(resourceDefinition)
end

function VaultMath.getTraitRarityTier(traitDefinition): number
	return RewardPresentation.getTraitCelebrationTier(traitDefinition)
end

function VaultMath.getRewardPresentationScale(resourceDefinition, traitDefinition): number
	return RewardPresentation.getRewardBurstScale(resourceDefinition, traitDefinition)
end

return VaultMath
