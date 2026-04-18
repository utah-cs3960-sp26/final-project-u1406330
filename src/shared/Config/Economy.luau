--!strict

-- Static shared configuration for Economy used by deterministic gameplay logic on both client and server.

local Economy = {
	offlineCapSeconds = 60 * 60 * 12,
	basePrestigeMultiplier = 1,
	prestigeStep = 0.1,
}

return Economy
