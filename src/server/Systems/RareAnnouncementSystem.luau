--!strict

-- Server system for Rare Announcement System that reacts to gameplay events and coordinates cross-service presentation.

local RareAnnouncementSystem = {}
RareAnnouncementSystem.__index = RareAnnouncementSystem

function RareAnnouncementSystem.new(remoteEvent)
	return setmetatable({
		remoteEvent = remoteEvent,
	}, RareAnnouncementSystem)
end

function RareAnnouncementSystem:announce(playerName, resourceName, traitName)
	local payload = {
		message = string.format("%s revealed %s (%s)", playerName, resourceName, traitName or "none"),
		playerName = playerName,
		resourceName = resourceName,
		traitName = traitName or "none",
	}

	print(string.format("[GemFactory] Rare reveal: %s revealed %s (%s)", playerName, resourceName, traitName or "none"))

	if self.remoteEvent ~= nil then
		self.remoteEvent:FireAllClients(payload)
	end
end

function RareAnnouncementSystem:start()
	print("[GemFactory] RareAnnouncementSystem ready")
end

return RareAnnouncementSystem
