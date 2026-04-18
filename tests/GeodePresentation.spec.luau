--!strict

-- Spec coverage for Geode Presentation to keep deterministic gameplay behavior and regressions easy to verify.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local GeodePresentation = require(Shared.Domain.GeodePresentation)

return function()
	assert(GeodePresentation.formatCountdown(0) == "0:00", "zero seconds should show a zeroed countdown")
	assert(GeodePresentation.formatCountdown(125) == "2:05", "countdown formatting should pad seconds")

	assert(
		GeodePresentation.getWorldLabelText("cracking", 145, 140) == "Cracking 0:05",
		"unfinished geodes should show a live cracking countdown"
	)
	assert(
		GeodePresentation.getWorldLabelText("finished", 145, 140) == "Ready!",
		"finished geodes should show as ready immediately"
	)
	assert(
		GeodePresentation.getWorldLabelText("cracking", 145, 145) == "Ready!",
		"elapsed timers should be treated as ready even before a state sync"
	)

	assert(
		GeodePresentation.shouldHideResolvedRevealText("resource", true, false) == true,
		"resource names should stay hidden while the reveal reel is still spinning"
	)
	assert(
		GeodePresentation.shouldHideResolvedRevealText("attribute", true, false) == true,
		"attribute names should stay hidden while the reveal reel is still spinning"
	)
	assert(
		GeodePresentation.shouldHideResolvedRevealText("geode", true, false) == false,
		"geode popups should keep their current behavior"
	)
	assert(
		GeodePresentation.shouldHideResolvedRevealText("resource", true, true) == false,
		"resolved reveal text should appear once the reel has finished"
	)

	assert(
		GeodePresentation.shouldAdvanceRevealOnInput(Enum.UserInputType.MouseButton1) == true,
		"left click should advance reveal prompts"
	)
	assert(
		GeodePresentation.shouldAdvanceRevealOnInput(Enum.UserInputType.Touch) == true,
		"touch should still advance reveal prompts"
	)
	assert(
		GeodePresentation.shouldAdvanceRevealOnInput(Enum.UserInputType.MouseButton2) == false,
		"right click should not advance reveal prompts"
	)
end
