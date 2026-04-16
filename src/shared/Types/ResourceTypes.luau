--!strict

export type ResourceInstance = {
	id: string,
	resourceTypeId: string,
	traitId: string?,
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
