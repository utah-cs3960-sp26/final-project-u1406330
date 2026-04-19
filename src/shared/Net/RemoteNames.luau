--!strict

-- Shared networking module for Remote Names that defines or resolves the client-server remote contract.

local RemoteNames = {
	RequestBuyGeode = "RequestBuyGeode",
	RequestMine = "RequestMine",
	RequestBuyPickaxe = "RequestBuyPickaxe",
	RequestEquipPickaxe = "RequestEquipPickaxe",
	RequestPlaceGeode = "RequestPlaceGeode",
	RequestPlaceResource = "RequestPlaceResource",
	RequestPickupResource = "RequestPickupResource",
	RequestSellVaultItem = "RequestSellVaultItem",
	RequestCrackGeode = "RequestCrackGeode",
	RequestOpenGeode = "RequestCrackGeode",
	RequestClaimFinishedGeode = "RequestClaimFinishedGeode",
	RequestPlaceStation = "RequestPlaceStation",
	RequestMovePlacedObject = "RequestMovePlacedObject",
	RequestUpgradeStation = "RequestUpgradeStation",
	RequestClaimDailyReward = "RequestClaimDailyReward",
	RequestCollectOfflineRewards = "RequestCollectOfflineRewards",
	GetInitialState = "GetInitialState",
	StateUpdated = "StateUpdated",
	ShopRotationUpdated = "ShopRotationUpdated",
	RareRevealAnnounced = "RareRevealAnnounced",
	RareGeodeAnnounced = "RareRevealAnnounced",
}

return RemoteNames

