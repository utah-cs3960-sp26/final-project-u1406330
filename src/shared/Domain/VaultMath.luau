--!strict

local VaultMath = {}

function VaultMath.getResourceSellValue(resourceDefinition, traitDefinition): number
	if resourceDefinition == nil then
		return 0
	end

	local baseCoinRate = resourceDefinition.baseCoinRate or 0
	local traitMultiplier = if traitDefinition ~= nil then traitDefinition.multiplier or 1 else 1
	return math.max(1, math.floor((baseCoinRate * 25 * traitMultiplier) + 0.5))
end

function VaultMath.getGeodeSellValue(geodeDefinition): number
	if geodeDefinition == nil then
		return 0
	end

	local geodeSeconds = geodeDefinition.geodeSeconds or 0
	return math.max(1, math.floor((geodeSeconds * 3) + 0.5))
end

return VaultMath
