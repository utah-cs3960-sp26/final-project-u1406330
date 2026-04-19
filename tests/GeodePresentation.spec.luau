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

	assert(
		#GeodePresentation.getResourceRevealWords() >= 25,
		"resource reveal reels should have a full pool of resource names to spin through"
	)
	assert(
		GeodePresentation.getResourceRevealWords()[1] == "COPPER NUGGET",
		"resource reveal words should be deterministically sorted by rarity then name"
	)
	assert(
		GeodePresentation.getResourceRevealWords()[#GeodePresentation.getResourceRevealWords()] == "WORLDSEED",
		"resource reveal words should include the late legendary resources too"
	)
	assert(
		#GeodePresentation.getAttributeRevealWords() == 10,
		"attribute reveal reels should skip the none trait and include every collectible attribute"
	)
	assert(
		GeodePresentation.getAttributeRevealWords()[1] == "CELESTIAL",
		"attribute reveal words should be deterministic so the client reel does not depend on table iteration"
	)
	assert(
		GeodePresentation.shouldUseRevealSlotMachine("resource", 1) == true,
		"resource reveals should always use the reel, even for common resources"
	)
	assert(
		GeodePresentation.shouldUseRevealSlotMachine("attribute", 1) == true,
		"attribute reveals should always use the reel when an attribute popup exists"
	)
	assert(
		GeodePresentation.shouldUseRevealSlotMachine("geode", 1) == false,
		"low-rarity geode discovery popups should keep their non-reel presentation"
	)
	assert(
		GeodePresentation.getRevealResolvedHoldSeconds("resource", true) == 0.18,
		"resource reveals with a follow-up attribute should use the short auto-close handoff"
	)
	assert(
		GeodePresentation.getRevealResolvedHoldSeconds("resource", false) == nil,
		"resource-only reveals should keep their normal hold timing"
	)
	assert(
		GeodePresentation.getCelebrationPopupMinHeight("coin", false, true, nil) == 52,
		"coin popups should keep their lightweight text-burst height"
	)
	assert(
		GeodePresentation.getCelebrationPopupMinHeight("resource", true, false, 1) == 112,
		"common resource reels should keep the same compact popup baseline"
	)
	assert(
		GeodePresentation.getCelebrationPopupMinHeight("basic", false, true, nil) == 68,
		"compact popups should keep their short baseline height"
	)
	assert(
		GeodePresentation.getCelebrationPopupMinHeight("resource", true, false, 3) == 112,
		"resource reveal reels should start compact and grow only when content appears"
	)
	assert(
		GeodePresentation.getCelebrationPopupMinHeight("attribute", true, false, 5) == 112,
		"attribute reveal reels should not preallocate a footer-sized empty panel"
	)
	assert(
		GeodePresentation.getCelebrationPopupMinHeight("attribute", false, false, 5) == 222,
		"non-slot attribute popups should preserve their larger static layout"
	)
	assert(
		GeodePresentation.getCelebrationPopupMinHeight("geode_discovery", false, false, 10) == 272,
		"geode discovery popups should still scale up with rarity"
	)

	assert(
		GeodePresentation.getRevealAnimationGraceSeconds() == 0.6,
		"reveal animation grace timing should stay stable for the crack opener"
	)
	assert(
		GeodePresentation.shouldKeepRevealAnimationAlive(0.2, false, 0) == true,
		"reveal animation should stay alive through its opening grace beat"
	)
	assert(
		GeodePresentation.shouldKeepRevealAnimationAlive(0.7, true, 0) == true,
		"active reveal celebrations should keep the crack animation visible"
	)
	assert(
		GeodePresentation.shouldKeepRevealAnimationAlive(0.7, false, 2) == true,
		"queued follow-up celebrations should keep the crack animation alive between reels"
	)
	assert(
		GeodePresentation.shouldKeepRevealAnimationAlive(0.7, false, 0) == false,
		"the crack animation should end once the grace beat and reveal celebrations are done"
	)
end
