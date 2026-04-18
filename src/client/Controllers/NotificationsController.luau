--!strict

-- Client controller for Notifications Controller that coordinates UI, local input, and app-state updates for this slice.

local NotificationsController = {}
NotificationsController.__index = NotificationsController

local function formatNumber(value)
	local text = tostring(math.floor((value or 0) + 0.5))
	while true do
		local nextText = text:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		if nextText == text then
			break
		end
		text = nextText
	end
	return text
end

function NotificationsController.new(context)
	return setmetatable({
		context = context or {},
	}, NotificationsController)
end

function NotificationsController:start()
	local screen = self.context.screen
	local app = self.context.app

	local function formatDuration(seconds: number): string
		local safeSeconds = math.max(0, math.floor(seconds))
		local hours = math.floor(safeSeconds / 3600)
		local minutes = math.floor((safeSeconds % 3600) / 60)
		local remaining = safeSeconds % 60
		return string.format("%02d:%02d:%02d", hours, minutes, remaining)
	end

	local function formatAnnouncementList(announcements)
		if #announcements == 0 then
			return "No announcements yet."
		end

		local lines = {}
		for index, announcement in ipairs(announcements) do
			if index > 3 then
				table.insert(lines, string.format("...and %d more", #announcements - 3))
				break
			end
			table.insert(lines, tostring(announcement))
		end

		return table.concat(lines, "\n")
	end

	local function refresh(state)
		local profile = state.profile
		local offlineReward = profile.unclaimedOfflineRewards
		local offlineText = "No offline cache ready yet."
		local offlineButtonText = "Claim Offline Cache"
		local offlineEnabled = false

		if offlineReward ~= nil then
			offlineText = string.format(
				"Offline coins: %s\nElapsed: %s\nFinished geodes: %d",
				formatNumber(offlineReward.coins),
				formatDuration(offlineReward.elapsedSeconds),
				#offlineReward.finishedGeodes
			)
			offlineButtonText = string.format("Claim Offline Cache (%s coins)", formatNumber(offlineReward.coins))
			offlineEnabled = true
		end

		screen:setOfflineText(offlineText)
		screen:setOfflineButtonState(offlineEnabled, offlineButtonText)
		screen:setNotificationsText(formatAnnouncementList(state.announcements))
	end

	screen.buttons.claimOffline.Activated:Connect(function()
		app:requestCollectOfflineRewards()
	end)

	self.context.stateChanged:Connect(refresh)
	refresh(app:getState())
end

return NotificationsController


