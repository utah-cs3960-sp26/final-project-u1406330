--!strict

local World = {
	plotGridWidth = 16,
	plotGridHeight = 16,
	cellSize = 5,
	plotCount = 8,
	maxPlots = 8,
	plotRows = 2,
	plotColumns = 4,
	plotSpacing = 100,
	plotOrigin = {
		x = 0,
		y = 6,
		z = 0,
	},
	sharedBaseplateSize = {
		width = 460,
		height = 2,
		depth = 320,
	},
	plotBaseSize = {
		width = 92,
		height = 2,
		depth = 92,
	},
	plotOffsets = {
		{ x = -150, z = -105 },
		{ x = -50, z = -105 },
		{ x = 50, z = -105 },
		{ x = 150, z = -105 },
		{ x = -150, z = 105 },
		{ x = -50, z = 105 },
		{ x = 50, z = 105 },
		{ x = 150, z = 105 },
	},
	worldFolderName = "GemFactoryWorld",
	plotFolderName = "Plots",
	stationFolderName = "Stations",
	defaultPlotSpacing = 100,
	starterStationTypeId = "crystal_display_t1",
}

return World
