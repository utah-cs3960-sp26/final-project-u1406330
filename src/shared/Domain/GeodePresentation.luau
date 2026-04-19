--!strict

-- Deterministic shared rules for Geode Presentation so gameplay behavior can be reused by the server, client presentation, and specs.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Resources = require(Shared.Config.Resources)
local Traits = require(Shared.Config.Traits)
local RewardPresentation = require(Shared.Domain.RewardPresentation)

local GeodePresentation = {}

local RESOURCE_TO_ATTRIBUTE_HANDOFF_HOLD_SECONDS = 0.18

local function compareRevealWords(leftWord: string, rightWord: string): boolean
	return string.lower(leftWord) < string.lower(rightWord)
end

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

function GeodePresentation.getResourceRevealWords(): { string }
	local words = {}

	for resourceTypeId, resourceDefinition in pairs(Resources) do
		if type(resourceTypeId) == "string" and type(resourceDefinition) == "table" then
			table.insert(words, {
				displayName = tostring(resourceDefinition.displayName or resourceTypeId),
				rarityRank = RewardPresentation.getResourceRarityRank(resourceDefinition),
			})
		end
	end

	table.sort(words, function(leftEntry, rightEntry)
		if leftEntry.rarityRank ~= rightEntry.rarityRank then
			return leftEntry.rarityRank < rightEntry.rarityRank
		end

		return compareRevealWords(leftEntry.displayName, rightEntry.displayName)
	end)

	local revealWords = {}
	for _, entry in ipairs(words) do
		table.insert(revealWords, string.upper(entry.displayName))
	end

	return revealWords
end

function GeodePresentation.getAttributeRevealWords(): { string }
	local words = {}

	for _, traitDefinition in ipairs(Traits.order or {}) do
		if type(traitDefinition) == "table" and traitDefinition.id ~= "none" then
			table.insert(words, string.upper(tostring(traitDefinition.displayName or traitDefinition.id)))
		end
	end

	if #words == 0 then
		return { "BONUS" }
	end

	table.sort(words, compareRevealWords)
	return words
end

function GeodePresentation.shouldUseRevealSlotMachine(kind: string?, rarityIndex: number?): boolean
	if kind == "resource" or kind == "attribute" then
		return true
	end

	if kind == "geode" then
		return (rarityIndex or 1) > 1
	end

	return false
end

function GeodePresentation.getRevealResolvedHoldSeconds(kind: string?, hasFollowupReveal: boolean?): number?
	if kind == "resource" and hasFollowupReveal == true then
		return RESOURCE_TO_ATTRIBUTE_HANDOFF_HOLD_SECONDS
	end

	return nil
end

function GeodePresentation.getCelebrationPopupMinHeight(
	kind: string?,
	showSlotMachine: boolean?,
	compact: boolean?,
	rarityIndex: number?
): number
	if kind == "coin" then
		return 52
	end

	if kind == "geode_discovery" then
		local ri = math.clamp(rarityIndex or 1, 1, 10)
		return math.clamp(110 + (ri - 1) * 18, 110, 280)
	end

	if compact == true then
		return 68
	end

	if showSlotMachine == true then
		if kind == "resource" or kind == "attribute" then
			-- Start reveal reels at a compact height and let AutomaticSize grow them once
			-- the resolved labels or handoff footer actually become visible.
			return 112
		end

		if kind == "geode" then
			return 132
		end

		return 212
	end

	if kind == "attribute" then
		return 222
	end

	if kind == "resource" or kind == "geode" then
		return 132
	end

	return 104
end

function GeodePresentation.getRevealAnimationGraceSeconds(): number
	return 0.6
end

function GeodePresentation.shouldKeepRevealAnimationAlive(
	elapsedSeconds: number?,
	celebrationPlaying: boolean?,
	queuedCelebrationCount: number?
): boolean
	local elapsed = if type(elapsedSeconds) == "number" then math.max(0, elapsedSeconds) else 0
	if elapsed < GeodePresentation.getRevealAnimationGraceSeconds() then
		return true
	end

	if celebrationPlaying == true then
		return true
	end

	local queueCount = if type(queuedCelebrationCount) == "number" then queuedCelebrationCount else 0
	return queueCount > 0
end

return GeodePresentation
