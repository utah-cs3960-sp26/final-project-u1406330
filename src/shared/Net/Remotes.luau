--!strict

local RemoteNames = require(script.Parent.RemoteNames)

local Remotes = {
	definitions = {
		[RemoteNames.RequestBuyGeode] = "RemoteFunction",
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

