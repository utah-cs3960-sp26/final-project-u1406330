--!strict

-- Shared type definitions for Resource Types so profile, item, and world data stay consistent across modules.

export type ResourceInstance = {
	id: string,
	resourceTypeId: string,
	traitId: string?,
	sizeId: string?,
	sizeValue: number?,
	level: number,
	stationId: string?,
	obtainedAt: number,
	placement: {
		plotId: string,
		x: number,
		y: number,
		width: number,
		height: number,
	}?,
}

return {}
