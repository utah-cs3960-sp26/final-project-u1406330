--!strict

-- Shared type definitions for Player Profile so profile, item, and world data stay consistent across modules.

local ResourceTypes = require(script.Parent.ResourceTypes)
local StationTypes = require(script.Parent.StationTypes)
local GeodeTypes = require(script.Parent.GeodeTypes)
local GeodeState = require(script.Parent.Parent.Domain.GeodeState)
local PickaxeRules = require(script.Parent.Parent.Domain.PickaxeRules)
local TableUtil = require(script.Parent.Parent.Util.TableUtil)

export type ResourceInstance = ResourceTypes.ResourceInstance
export type StationInstance = StationTypes.StationInstance
export type PlacementRecord = StationTypes.PlacementRecord
export type GeodeInstance = GeodeTypes.GeodeInstance

export type OfflineRewardSummary = {
	coins: number,
	finishedGeodes: { string },
	elapsedSeconds: number,
	calculatedAt: number,
}

export type GeodeQueueEntry = {
	id: string,
	geodeId: string,
	startedAt: number,
	endsAt: number,
	status: string,
}

export type ResourceGuideDiscovery = {
	found: boolean,
	discoveredTraits: { [string]: boolean },
}

export type ResourceGuideProgress = {
	discoveredResources: { [string]: ResourceGuideDiscovery },
}

export type PlayerProfile = {
	currencies: {
		coins: number,
		gems: number,
		eventTokens: number,
	},
	resourcesById: { [string]: ResourceInstance },
	resourceOrder: { string },
	geodesById: { [string]: GeodeInstance },
	geodeOrder: { string },
	stationsById: { [string]: StationInstance },
	placedObjects: { [string]: PlacementRecord },
	inventory: {
		geodes: { [string]: number },
		items: { [string]: number },
		pickaxes: { [string]: boolean },
	},
	resourceGuide: ResourceGuideProgress,
	geodeQueue: { GeodeQueueEntry },
	unclaimedOfflineRewards: OfflineRewardSummary?,
	dailyRewards: {
		currentDay: number,
		lastClaimUnix: number?,
		streakCount: number,
	},
	progression: {
		unlockedZones: { string },
		prestigeCount: number,
		equippedPickaxeId: string,
	},
	plotState: {
		plotId: string?,
		gridOccupancy: { [string]: string },
	},
	session: {
		lastLogoutUnix: number?,
		lastPassiveTickUnix: number?,
		passiveCoinRemainder: number,
	},
	meta: {
		schemaVersion: number,
		createdAt: number,
		lastLoadedAt: number,
		lastSavedAt: number?,
	},
}

local PlayerProfile = {}
PlayerProfile.SCHEMA_VERSION = 3

local function createTemplate(nowUnix: number): PlayerProfile
	return {
		currencies = {
			coins = 250,
			gems = 10,
			eventTokens = 0,
		},
		resourcesById = {},
		resourceOrder = {},
		geodesById = {},
		geodeOrder = {},
		stationsById = {},
		placedObjects = {},
		inventory = {
			geodes = {},
			items = {},
			pickaxes = {
				stone_pickaxe = true,
			},
		},
		resourceGuide = {
			discoveredResources = {},
		},
		geodeQueue = {},
		unclaimedOfflineRewards = nil,
		dailyRewards = {
			currentDay = 1,
			lastClaimUnix = nil,
			streakCount = 0,
		},
		progression = {
			unlockedZones = { "crystal_cavern" },
			prestigeCount = 0,
			equippedPickaxeId = "stone_pickaxe",
		},
		plotState = {
			plotId = nil,
			gridOccupancy = {},
		},
		session = {
			lastLogoutUnix = nil,
			lastPassiveTickUnix = nowUnix,
			passiveCoinRemainder = 0,
		},
		meta = {
			schemaVersion = PlayerProfile.SCHEMA_VERSION,
			createdAt = nowUnix,
			lastLoadedAt = nowUnix,
			lastSavedAt = nil,
		},
	}
end

function PlayerProfile.new(nowUnix: number?): PlayerProfile
	local timestamp = nowUnix or 0
	return createTemplate(timestamp)
end

function PlayerProfile.reconcile(profile: any, nowUnix: number?): PlayerProfile
	local timestamp = nowUnix or 0
	local resolved = TableUtil.reconcile(createTemplate(timestamp), profile)
	resolved.inventory.pickaxes, resolved.progression.equippedPickaxeId = PickaxeRules.normalizeOwnedPickaxes(
		resolved.inventory.pickaxes,
		resolved.progression.equippedPickaxeId
	)
	GeodeState.migrateLegacyQueue(resolved)
	resolved.geodeQueue = GeodeState.buildQueueEntries(resolved.geodesById, resolved.geodeOrder, timestamp)
	resolved.meta.schemaVersion = PlayerProfile.SCHEMA_VERSION
	resolved.meta.lastLoadedAt = timestamp
	return resolved
end

return PlayerProfile
