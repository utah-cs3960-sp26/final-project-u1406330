--!strict

-- Shared type definitions for Geode Types so profile, item, and world data stay consistent across modules.

export type GridPlacement = {
	plotId: string?,
	x: number,
	y: number,
	width: number,
	height: number,
}

export type GeodeInstance = {
	id: string,
	geodeTypeId: string,
	sizeId: string?,
	sizeValue: number?,
	status: string,
	startedAt: number,
	endsAt: number,
	obtainedAt: number,
	placement: GridPlacement?,
}

return {}
