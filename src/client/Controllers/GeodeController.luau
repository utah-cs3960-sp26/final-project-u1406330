--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Geodes = require(Shared.Config.Geodes)
local Time = require(Shared.Util.Time)

local GeodeController = {}
GeodeController.__index = GeodeController

local function formatDuration(seconds: number): string
	local safeSeconds = math.max(0, math.floor(seconds))
	local hours = math.floor(safeSeconds / 3600)
	local minutes = math.floor((safeSeconds % 3600) / 60)
	local remaining = safeSeconds % 60
	return string.format("%02d:%02d:%02d", hours, minutes, remaining)
end

function GeodeController.new(context)
	return setmetatable({
		context = context or {},
	}, GeodeController)
end

function GeodeController:start()
	local screen = self.context.screen
	local app = self.context.app

	local function refresh(state, nowUnix)
		local queue = state.profile.geodeQueue
		local readyCount = 0
		if #queue == 0 then
			screen:setGeodeText("No geodes are cracking yet.\nBuy a geode from the shop to start the reveal loop.")
			screen:setClaimReadyGeodesButton(false, "Claim Ready Geodes")
			return
		end

		local lines = {}
		for index, entry in ipairs(queue) do
			if index > 4 then
				table.insert(lines, string.format("...and %d more", #queue - 4))
				break
			end

			local geodeDefinition = Geodes[entry.geodeId]
			local remaining = math.max(0, (entry.endsAt or nowUnix) - nowUnix)
			if remaining <= 0 or entry.status == "finished" then
				readyCount += 1
			end
			table.insert(lines, string.format(
				"%s - %s - %s",
				geodeDefinition and geodeDefinition.displayName or entry.geodeId,
				(remaining <= 0 or entry.status == "finished") and "ready to claim" or (entry.status == "queued" and "cracking" or (entry.status or "queued")),
				formatDuration(remaining)
			))
		end

		if readyCount > 0 then
			table.insert(lines, 1, string.format("%d geode%s ready to claim.", readyCount, if readyCount == 1 then "" else "s"))
		else
			table.insert(lines, 1, "Geodes are cracking. Claim them here when the timers finish.")
		end

		screen:setGeodeText(table.concat(lines, "\n"))
		screen:setClaimReadyGeodesButton(
			readyCount > 0,
			if readyCount > 0 then string.format("Claim Ready Geode%s", if readyCount == 1 then "" else "s") else "Claim Ready Geodes"
		)
	end

	screen.buttons.claimReadyGeodes.Activated:Connect(function()
		app:requestClaimFinishedGeodes()
	end)

	self.context.stateChanged:Connect(refresh)
	refresh(app:getState(), Time.nowUnix())
end

return GeodeController


