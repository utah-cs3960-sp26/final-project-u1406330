--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local RemoteNames = require(Shared.Net.RemoteNames)
local Remotes = require(Shared.Net.Remotes)

return function()
	assert(RemoteNames.RequestPlaceGeode == "RequestPlaceGeode", "geode placement remote name should stay stable")
	assert(RemoteNames.RequestCrackGeode == "RequestCrackGeode", "geode crack remote name should stay stable")
	assert(RemoteNames.RequestOpenGeode == RemoteNames.RequestCrackGeode, "legacy geode open alias should point to the crack remote")
	assert(Remotes.definitions[RemoteNames.RequestPlaceGeode] == "RemoteFunction", "geode placement should be exposed as a remote function")
	assert(Remotes.definitions[RemoteNames.RequestCrackGeode] == "RemoteFunction", "geode cracking should be exposed as a remote function")
	assert(RemoteNames.RareRevealAnnounced == "RareRevealAnnounced", "canonical rare reveal remote should use the new name")
	assert(RemoteNames.RareGeodeAnnounced == RemoteNames.RareRevealAnnounced, "legacy rare geode alias should point to the new name")
	assert(Remotes.definitions[RemoteNames.RareRevealAnnounced] == "RemoteEvent", "rare reveal remote should be exposed as an event")
end
