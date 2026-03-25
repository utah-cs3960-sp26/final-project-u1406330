--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local OfflineMath = require(Shared.Domain.OfflineMath)

return function()
	local summary = OfflineMath.buildSummary(100, 250, 5, 60)
	assert(summary ~= nil, "offline summary should exist when a logout timestamp is present")
	assert(summary.elapsedSeconds == 60, "elapsed time should clamp to the configured cap")
	assert(summary.coins == 300, "offline coins should be passive rate times clamped elapsed")

	local finished = OfflineMath.collectFinishedGeodeIds({
		{ id = "a", status = "queued", endsAt = 110 },
		{ id = "b", status = "finished", endsAt = 105 },
		{ id = "c", status = "queued", endsAt = 300 },
	}, 200)

	assert(#finished == 1 and finished[1] == "a", "only queued completed geodes should be returned")
end

