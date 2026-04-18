--!strict

-- Deterministic shared rules for Geode Presentation so gameplay behavior can be reused by the server, client presentation, and specs.

local GeodePresentation = {}

function GeodePresentation.formatCountdown(remainingSeconds: number?): string
	local safeRemaining = math.max(0, math.floor(remainingSeconds or 0))
	local minutes = math.floor(safeRemaining / 60)
	local seconds = safeRemaining % 60
	return string.format("%d:%02d", minutes, seconds)
end

function GeodePresentation.getWorldLabelText(readyState: string?, endsAt: number?, nowUnix: number?): string
	local normalizedState = if type(readyState) == "string" then string.lower(readyState) else nil
	local currentUnix = if type(nowUnix) == "number" then nowUnix else 0

	if normalizedState == "ready" or normalizedState == "finished" then
		return "Ready!"
	end

	if type(endsAt) == "number" and endsAt <= currentUnix then
		return "Ready!"
	end

	if type(endsAt) == "number" then
		return string.format("Cracking %s", GeodePresentation.formatCountdown(endsAt - currentUnix))
	end

	return "Cracking..."
end

function GeodePresentation.shouldHideResolvedRevealText(
	kind: string?,
	showSlotMachine: boolean?,
	reelFinished: boolean?
): boolean
	if showSlotMachine ~= true or reelFinished == true then
		return false
	end

	return kind == "resource" or kind == "attribute"
end

function GeodePresentation.shouldAdvanceRevealOnInput(inputType: Enum.UserInputType?): boolean
	return inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch
end

return GeodePresentation
