--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local RemoteNames = require(Shared.Net.RemoteNames)
local Remotes = require(Shared.Net.Remotes)

return function()
	assert(RemoteNames.RareRevealAnnounced == "RareRevealAnnounced", "canonical rare reveal remote should use the new name")
	assert(RemoteNames.RareGeodeAnnounced == RemoteNames.RareRevealAnnounced, "legacy rare geode alias should point to the new name")
	assert(Remotes.definitions[RemoteNames.RareRevealAnnounced] == "RemoteEvent", "rare reveal remote should be exposed as an event")
end
