--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Geodes = require(Shared.Config.Geodes)
local Time = require(Shared.Util.Time)

local GeodeController = {}
GeodeController.__index = GeodeController

local function getGeodeDisplayName(geodeTypeId: string?): string
	local geodeDefinition = geodeTypeId ~= nil and Geodes[geodeTypeId] or nil
	if geodeDefinition ~= nil and geodeDefinition.displayName ~= nil then
		return geodeDefinition.displayName
	end

	return geodeTypeId or "Unknown Geode"
end

local function getInventoryCounts(profile: any): { [string]: number }
	local counts = {}
	local inventory = profile.inventory
	local inventoryGeodes = type(inventory) == "table" and inventory.geodes or nil
	local foundInventoryData = false

	if type(inventoryGeodes) == "table" then
		for geodeTypeId, amount in pairs(inventoryGeodes) do
			if type(geodeTypeId) == "string" and type(amount) == "number" and amount > 0 then
				counts[geodeTypeId] = amount
				foundInventoryData = true
			end
		end
	end

	if foundInventoryData then
		return counts
	end

	for _, geodeId in ipairs(profile.geodeOrder or {}) do
		local geode = profile.geodesById[geodeId]
		if type(geode) == "table" and geode.placement == nil then
			local geodeTypeId = geode.geodeTypeId
			if type(geodeTypeId) == "string" then
				counts[geodeTypeId] = (counts[geodeTypeId] or 0) + 1
			end
		end
	end

	return counts
end

local function getGeodeSummary(profile: any, nowUnix: number)
	local geodesById = profile.geodesById or {}
	local geodeOrder = profile.geodeOrder or {}
	local summary = {
		totalCount = 0,
		onPlotCount = 0,
		inventoryCount = 0,
		readyCount = 0,
		crackingCount = 0,
		firstUnplacedGeodeId = nil,
		firstReadyGeodeId = nil,
		inventoryCounts = getInventoryCounts(profile),
	} :: any

	for _, geodeId in ipairs(geodeOrder) do
		local geode = geodesById[geodeId]
		if type(geode) == "table" then
			local endsAt = geode.endsAt or nowUnix
			local isReady = geode.status == "ready" or geode.status == "finished" or endsAt <= nowUnix
			local isPlaced = geode.placement ~= nil

			summary.totalCount += 1
			if isPlaced then
				summary.onPlotCount += 1
				if isReady and summary.firstReadyGeodeId == nil then
					summary.firstReadyGeodeId = geode.id
				end
			else
				summary.inventoryCount += 1
				if summary.firstUnplacedGeodeId == nil then
					summary.firstUnplacedGeodeId = geode.id
				end
			end

			if isReady then
				summary.readyCount += 1
			else
				summary.crackingCount += 1
			end
		end
	end

	if summary.totalCount == 0 then
		for _, amount in pairs(summary.inventoryCounts) do
			summary.totalCount += amount
		end
		summary.inventoryCount = summary.totalCount
	end

	return summary
end

local function buildInventoryLines(summary)
	local entries = {}
	for geodeTypeId, amount in pairs(summary.inventoryCounts) do
		table.insert(entries, {
			geodeTypeId = geodeTypeId,
			amount = amount,
		})
	end

	table.sort(entries, function(a, b)
		return getGeodeDisplayName(a.geodeTypeId) < getGeodeDisplayName(b.geodeTypeId)
	end)

	local lines = {}
	for index, entry in ipairs(entries) do
		if index > 3 then
			table.insert(lines, string.format("...and %d more geode type%s", #entries - 3, if #entries - 3 == 1 then "" else "s"))
			break
		end

		table.insert(lines, string.format("%s x%d", getGeodeDisplayName(entry.geodeTypeId), entry.amount))
	end

	return lines
end

local function getGeodeDisplayNameFromProfile(profile: any, geodeId: string?): string
	if geodeId == nil then
		return "Geode"
	end

	local geode = profile.geodesById ~= nil and profile.geodesById[geodeId] or nil
	if type(geode) == "table" then
		return getGeodeDisplayName(geode.geodeTypeId)
	end

	return "Geode"
end

function GeodeController.new(context)
	return setmetatable({
		context = context or {},
	}, GeodeController)
end

function GeodeController:start()
	local screen = self.context.screen
	local app = self.context.app
	local latestPlaceGeodeId: string? = nil
	local latestOpenGeodeId: string? = nil
	local latestCanPlaceGeode: boolean = false
	local latestCanOpenGeode: boolean = false

	local function refresh(state, nowUnix)
		local profileAny = state.profile :: any
		local plotAssigned = profileAny.plotState ~= nil and profileAny.plotState.plotId ~= nil
		local summary = getGeodeSummary(profileAny, nowUnix)
		local lines = {
			string.format(
				"Inventory: %d | On plot: %d | Cracking: %d | Ready: %d",
				summary.inventoryCount,
				summary.onPlotCount,
				summary.crackingCount,
				summary.readyCount
			),
			"Bought geodes stay in your inventory until you place them.",
			"Click a ready geode on the plot to crack it open.",
		}

		local inventoryLines = buildInventoryLines(summary)
		if #inventoryLines > 0 then
			table.insert(lines, "Stored geodes:")
			for _, inventoryLine in ipairs(inventoryLines) do
				table.insert(lines, inventoryLine)
			end
		end

		if summary.totalCount == 0 then
			screen:setGeodeText("No geodes are active yet.\nBuy a geode from the shop and it will stay in your inventory until you place it.")
			latestPlaceGeodeId = nil
			latestOpenGeodeId = nil
			latestCanPlaceGeode = false
			latestCanOpenGeode = false
			screen:setPlaceGeodeButton(false, "Place Next Geode")
			screen:setOpenReadyGeodeButton(false, "Open Ready Geode")
			return
		end

		screen:setGeodeText(table.concat(lines, "\n"))
		latestPlaceGeodeId = if plotAssigned then summary.firstUnplacedGeodeId else nil
		latestOpenGeodeId = summary.firstReadyGeodeId
		latestCanPlaceGeode = latestPlaceGeodeId ~= nil
		latestCanOpenGeode = latestOpenGeodeId ~= nil

		local placeLabel = "Place Next Geode"
		if latestPlaceGeodeId ~= nil then
			placeLabel = string.format("Place %s", getGeodeDisplayNameFromProfile(profileAny, latestPlaceGeodeId))
		end
		local openLabel = "Open Ready Geode"
		if latestOpenGeodeId ~= nil then
			openLabel = string.format("Open %s", getGeodeDisplayNameFromProfile(profileAny, latestOpenGeodeId))
		end

		screen:setPlaceGeodeButton(latestCanPlaceGeode, placeLabel)
		screen:setOpenReadyGeodeButton(
			latestCanOpenGeode,
			if latestCanOpenGeode then openLabel else "Open Ready Geode"
		)
	end

	screen.buttons.placeGeode.Activated:Connect(function()
		if latestCanPlaceGeode and latestPlaceGeodeId ~= nil then
			app:beginGeodePlacement(latestPlaceGeodeId)
		end
	end)

	screen.buttons.openReadyGeodes.Activated:Connect(function()
		if latestCanOpenGeode and latestOpenGeodeId ~= nil then
			app:requestOpenReadyGeode(latestOpenGeodeId)
		end
	end)

	self.context.stateChanged:Connect(refresh)
	refresh(app:getState(), Time.nowUnix())
end

return GeodeController


