--!strict

export type GridPlacement = {
	plotId: string?,
	x: number,
	y: number,
	width: number,
	height: number,
}

export type StationInstance = {
	id: string,
	stationTypeId: string,
	level: number,
	occupantIds: { string },
	placement: GridPlacement?,
}

export type PlacementRecord = {
	id: string,
	plotId: string?,
	objectType: string,
	objectId: string,
	x: number,
	y: number,
	width: number,
	height: number,
}

return {}

