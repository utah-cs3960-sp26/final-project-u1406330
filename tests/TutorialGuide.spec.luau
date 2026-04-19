--!strict

-- Spec coverage for the shared tutorial dataset so future HUD wiring can trust ordered onboarding copy without hard-coded text.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Geodes = require(Shared.Config.Geodes)
local Pickaxes = require(Shared.Config.Pickaxes)
local TutorialGuide = require(Shared.Domain.TutorialGuide)

return function()
	local buttonCopy = TutorialGuide.getButtonCopy()
	assert(buttonCopy.label == "Tutorial", "tutorial button copy should expose the button label for the HUD")
	assert(buttonCopy.subtitle == "How to play", "tutorial button copy should expose the short support label")

	local header = TutorialGuide.getHeader()
	local starterPickaxeName = Pickaxes.catalog[Pickaxes.order[1]].displayName
	assert(header.title == "Gem Factory Tutorial", "tutorial guide should expose a stable panel title")
	assert(
		string.find(header.subtitle, starterPickaxeName, 1, true) ~= nil,
		"tutorial header should mention the real starter pickaxe so the copy stays in sync with config"
	)

	local steps = TutorialGuide.getSteps()
	assert(#steps == 7, "tutorial guide should expose the full seven-step onboarding loop")
	assert(steps[1].id == "equip_pickaxe", "tutorial steps should start at tool equip")
	assert(steps[#steps].id == "place_or_sell_resources", "tutorial steps should end at the current resource display-or-sell loop")

	for index, step in ipairs(steps) do
		assert(type(step.id) == "string" and step.id ~= "", "each tutorial step should have a stable id")
		assert(type(step.title) == "string" and step.title ~= "", "each tutorial step should have a title")
		assert(type(step.summary) == "string" and step.summary ~= "", "each tutorial step should have a summary")
		assert(type(step.focus) == "string" and step.focus ~= "", "each tutorial step should name a UI or world focus point")
		assert(type(step.details) == "table" and #step.details >= 2, "each tutorial step should include support detail lines")
		assert(string.find(step.title, tostring(index), 1, true) ~= nil, "tutorial titles should preserve visible step numbering")
	end

	local geodeStep = TutorialGuide.getStepById("place_geodes")
	assert(geodeStep ~= nil, "tutorial guide should allow direct lookup for UI pagination")
	assert(
		string.find(geodeStep.summary, Geodes.starter_geode.displayName, 1, true) ~= nil,
		"the geode placement step should stay synced with the starter geode display name"
	)
	assert(TutorialGuide.getStepById("missing_step") == nil, "unknown step lookups should fail cleanly")
	assert(TutorialGuide.getStepById(nil) == nil, "nil step lookups should fail cleanly")

	local firstGuide = TutorialGuide.getGuide()
	firstGuide.steps[1].title = "Mutated"
	firstGuide.button.label = "Changed"
	firstGuide.tips[1].body = "Changed"

	local secondGuide = TutorialGuide.getGuide()
	assert(secondGuide.steps[1].title ~= "Mutated", "tutorial guide should return cloned steps so UI code can decorate safely")
	assert(secondGuide.button.label == "Tutorial", "tutorial guide should not leak button-copy mutations across callers")
	assert(secondGuide.tips[1].body ~= "Changed", "tutorial guide should clone support sections for each caller")

	local rules = TutorialGuide.getRules()
	assert(#rules == 3, "tutorial guide should expose a small set of rule reminders")
	assert(rules[2].id == "geode_source_rule", "tutorial rules should preserve stable ordering for UI layouts")

	local tips = TutorialGuide.getTips()
	assert(#tips >= 3, "tutorial guide should expose quick tips for the modal footer or side rail")
	assert(
		string.find(tips[1].body, "Resource Guide", 1, true) ~= nil,
		"tutorial tips should connect players back to the existing Resource Guide flow"
	)
end
