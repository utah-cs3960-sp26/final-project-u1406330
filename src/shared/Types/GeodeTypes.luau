--!strict

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
	status: string,
	startedAt: number,
	endsAt: number,
	obtainedAt: number,
	placement: GridPlacement?,
}

return {}
