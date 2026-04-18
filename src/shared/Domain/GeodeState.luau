--!strict

-- Deterministic shared rules for Geode State so gameplay behavior can be reused by the server, client presentation, and specs.

local GeodeState = {}

export type GeodeInstance = {
	id: string,
	geodeTypeId: string,
	sizeId: string?,
	sizeValue: number?,
	status: string,
	startedAt: number,
	endsAt: number,
	obtainedAt: number,
	placement: {
		plotId: string?,
		x: number,
		y: number,
		width: number,
		height: number,
	}?,
}

export type GeodeQueueEntry = {
	id: string,
	geodeId: string,
	startedAt: number,
	endsAt: number,
	status: string,
}

local function resolveStatus(instance: GeodeInstance, nowUnix: number?)
	local status = instance.status or "queued"
	if status == "claimed" then
		return status
	end

	if nowUnix ~= nil and (instance.endsAt or nowUnix) <= nowUnix then
		return "finished"
	end

	if status == "finished" and nowUnix ~= nil and instance.endsAt > nowUnix then
		return "queued"
	end

	return status
end

function GeodeState.createInstance(id: string, geodeTypeId: string, nowUnix: number, geodeSeconds: number, sizeId: string?, sizeValue: number?): GeodeInstance
	return {
		id = id,
		geodeTypeId = geodeTypeId,
		sizeId = sizeId or nil,
		sizeValue = sizeValue or nil,
		status = "queued",
		startedAt = nowUnix,
		endsAt = nowUnix + geodeSeconds,
		obtainedAt = nowUnix,
		placement = nil,
	}
end

function GeodeState.refreshStatuses(geodesById: { [string]: GeodeInstance }, geodeOrder: { string }, nowUnix: number)
	for _, geodeInstanceId in ipairs(geodeOrder) do
		local instance = geodesById[geodeInstanceId]
		if instance ~= nil then
			instance.status = resolveStatus(instance, nowUnix)
		end
	end
end

function GeodeState.toQueueEntry(instance: GeodeInstance, nowUnix: number?): GeodeQueueEntry
	return {
		id = instance.id,
		geodeId = instance.geodeTypeId,
		startedAt = instance.startedAt,
		endsAt = instance.endsAt,
		status = resolveStatus(instance, nowUnix),
	}
end

function GeodeState.buildQueueEntries(geodesById: { [string]: GeodeInstance }, geodeOrder: { string }, nowUnix: number?): { GeodeQueueEntry }
	local entries = {}

	for _, geodeInstanceId in ipairs(geodeOrder) do
		local instance = geodesById[geodeInstanceId]
		if instance ~= nil then
			table.insert(entries, GeodeState.toQueueEntry(instance, nowUnix))
		end
	end

	return entries
end

function GeodeState.migrateLegacyQueue(profile)
	if next(profile.geodesById) ~= nil then
		return false
	end

	for _, legacyEntry in ipairs(profile.geodeQueue or {}) do
		local geodeInstanceId = legacyEntry.id
		if geodeInstanceId ~= nil and profile.geodesById[geodeInstanceId] == nil then
			profile.geodesById[geodeInstanceId] = {
				id = geodeInstanceId,
				geodeTypeId = legacyEntry.geodeId,
				sizeId = nil,
				sizeValue = nil,
				status = legacyEntry.status or "queued",
				startedAt = legacyEntry.startedAt or 0,
				endsAt = legacyEntry.endsAt or 0,
				obtainedAt = legacyEntry.startedAt or 0,
				placement = nil,
			}
			table.insert(profile.geodeOrder, geodeInstanceId)
		end
	end

	return #profile.geodeOrder > 0
end

function GeodeState.getClaimableIds(profile, nowUnix: number, requestedGeodeId: string?)
	GeodeState.refreshStatuses(profile.geodesById, profile.geodeOrder, nowUnix)

	local claimableIds = {}
	for _, geodeInstanceId in ipairs(profile.geodeOrder) do
		local instance = profile.geodesById[geodeInstanceId]
		if instance ~= nil and instance.placement ~= nil and instance.status == "finished" then
			if requestedGeodeId == nil or requestedGeodeId == geodeInstanceId then
				table.insert(claimableIds, geodeInstanceId)
			end
		end
	end

	return claimableIds
end

function GeodeState.removeGeode(geodesById: { [string]: GeodeInstance }, geodeOrder: { string }, geodeInstanceId: string)
	geodesById[geodeInstanceId] = nil

	for index, existingId in ipairs(geodeOrder) do
		if existingId == geodeInstanceId then
			table.remove(geodeOrder, index)
			break
		end
	end
end

return GeodeState
