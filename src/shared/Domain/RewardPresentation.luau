--!strict

local RewardPresentation = {}

local RarityRanks = {
	Common = 0,
	Uncommon = 1,
	Rare = 2,
	Epic = 3,
	Legendary = 4,
	Mythic = 5,
}

local function getRarityRank(rarity: any): number
	if type(rarity) ~= "string" then
		return 0
	end

	return RarityRanks[rarity] or 0
end

local function getCelebrationTierFromRank(rank: number): number
	return math.max(0, rank)
end

local function getScaleFromTier(tier: number, growthStep: number): number
	if tier <= 0 then
		return 0
	end

	return 1 + (tier * growthStep)
end

function RewardPresentation.getResourceRarityRank(resourceDefinition: any): number
	if resourceDefinition == nil then
		return 0
	end

	return getRarityRank(resourceDefinition.rarity)
end

function RewardPresentation.getResourceCelebrationTier(resourceDefinition: any): number
	return getCelebrationTierFromRank(RewardPresentation.getResourceRarityRank(resourceDefinition))
end

function RewardPresentation.getResourceSlotMachineScale(resourceDefinition: any): number
	local tier = RewardPresentation.getResourceCelebrationTier(resourceDefinition)
	return getScaleFromTier(tier, 0.35)
end

function RewardPresentation.getTraitRarityRank(traitDefinition: any): number
	if traitDefinition == nil then
		return 0
	end

	if type(traitDefinition.rarityRank) == "number" then
		return traitDefinition.rarityRank
	end

	return getRarityRank(traitDefinition.rarity)
end

function RewardPresentation.getTraitCelebrationTier(traitDefinition: any): number
	return getCelebrationTierFromRank(RewardPresentation.getTraitRarityRank(traitDefinition))
end

function RewardPresentation.getTraitSlotMachineScale(traitDefinition: any): number
	local tier = RewardPresentation.getTraitCelebrationTier(traitDefinition)
	return getScaleFromTier(tier, 0.4)
end

function RewardPresentation.getRewardBurstScale(resourceDefinition: any, traitDefinition: any): number
	local resourceScale = RewardPresentation.getResourceSlotMachineScale(resourceDefinition)
	local traitScale = RewardPresentation.getTraitSlotMachineScale(traitDefinition)

	if resourceScale <= 0 and traitScale <= 0 then
		return 0
	end

	return 1 + (resourceScale * 0.6) + (traitScale * 0.4)
end

function RewardPresentation.shouldUseSlotMachineReveal(resourceDefinition: any, traitDefinition: any): boolean
	return RewardPresentation.getResourceCelebrationTier(resourceDefinition) > 0
		or RewardPresentation.getTraitCelebrationTier(traitDefinition) > 0
end

return RewardPresentation
