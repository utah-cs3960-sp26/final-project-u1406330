--!strict

-- Static shared configuration for Stations used by deterministic gameplay logic on both client and server.

local Stations = {
	crystal_display_t1 = {
		id = "crystal_display_t1",
		displayName = "Crystal Display",
		capacity = 4,
		incomeMultiplier = 1,
		gridSize = { width = 2, height = 2 },
		color = Color3.fromRGB(102, 230, 255),
	},
	resonance_pedestal_t1 = {
		id = "resonance_pedestal_t1",
		displayName = "Resonance Pedestal",
		capacity = 6,
		incomeMultiplier = 1.15,
		gridSize = { width = 3, height = 3 },
		color = Color3.fromRGB(164, 120, 255),
	},
}

return Stations
