--!strict

-- Shared networking module for Remotes that defines or resolves the client-server remote contract.

local RemoteNames = require(script.Parent.RemoteNames)

local Remotes = {
	definitions = {
		[RemoteNames.RequestBuyGeode] = "RemoteFunction",
		[RemoteNames.RequestMine] = "RemoteFunction",
		[RemoteNames.RequestBuyPickaxe] = "RemoteFunction",
		[RemoteNames.RequestEquipPickaxe] = "RemoteFunction",
		[RemoteNames.RequestPlaceGeode] = "RemoteFunction",
		[RemoteNames.RequestPlaceResource] = "RemoteFunction",
		[RemoteNames.RequestSellVaultItem] = "RemoteFunction",
		[RemoteNames.RequestCrackGeode] = "RemoteFunction",
		[RemoteNames.RequestClaimFinishedGeode] = "RemoteFunction",
		[RemoteNames.RequestPlaceStation] = "RemoteFunction",
		[RemoteNames.RequestMovePlacedObject] = "RemoteFunction",
		[RemoteNames.RequestUpgradeStation] = "RemoteFunction",
		[RemoteNames.RequestClaimDailyReward] = "RemoteFunction",
		[RemoteNames.RequestCollectOfflineRewards] = "RemoteFunction",
		[RemoteNames.GetInitialState] = "RemoteFunction",
		[RemoteNames.StateUpdated] = "RemoteEvent",
		[RemoteNames.ShopRotationUpdated] = "RemoteEvent",
		[RemoteNames.RareRevealAnnounced] = "RemoteEvent",
	},
}

return Remotes

