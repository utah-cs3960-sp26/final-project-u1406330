--!strict

-- Spec coverage for World Label Presentation to keep deterministic gameplay behavior and regressions easy to verify.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local WorldLabelPresentation = require(Shared.Domain.WorldLabelPresentation)

return function()
	assert(
		WorldLabelPresentation.resolveHoveredResourceId("resource_123", nil) == "resource_123",
		"direct resource hovers should resolve from the targeted part"
	)
	assert(
		WorldLabelPresentation.resolveHoveredResourceId(nil, "resource_456") == "resource_456",
		"child-part hovers should resolve from an ancestor resource part"
	)
	assert(
		WorldLabelPresentation.resolveHoveredResourceId("", "resource_789") == "resource_789",
		"blank direct ids should safely fall back to the ancestor resource id"
	)
	assert(
		WorldLabelPresentation.shouldShowPlacedResourceLabel("resource_123", "resource_123") == true,
		"only the hovered resource should show its world label"
	)
	assert(
		WorldLabelPresentation.shouldShowPlacedResourceLabel("resource_123", "resource_999") == false,
		"other placed resources should stay hidden while a different one is hovered"
	)
	assert(
		WorldLabelPresentation.shouldShowPlacedResourceLabel(nil, "resource_123") == false,
		"resources without a valid id should fail closed and keep their label hidden"
	)
	local plainTitle, plainSubtitle = WorldLabelPresentation.getPlacedResourceLabelText("Quartz", nil, "Medium", "Common")
	assert(plainTitle == "Quartz", "medium plain resources should show their base display name")
	assert(plainSubtitle == "Common", "medium plain resources should show their rarity only")

	local traitedTitle, traitedSubtitle =
		WorldLabelPresentation.getPlacedResourceLabelText("Quartz", "Fiery", "Medium", "Common")
	assert(traitedTitle == "Fiery Quartz", "traited resources should prefix the trait name in the hover title")
	assert(traitedSubtitle == "Common - Fiery", "traited resources should mention the trait in the subtitle")

	local sizedTitle, sizedSubtitle =
		WorldLabelPresentation.getPlacedResourceLabelText("Astral Reliquary", "Void-Touched", "Colossal", "Legendary")
	assert(
		sizedTitle == "Colossal Void-Touched Astral Reliquary",
		"sized traited resources should include both size and trait in the hover title"
	)
	assert(
		sizedSubtitle == "Legendary - Void-Touched (Colossal)",
		"sized traited resources should include rarity, trait, and size in the hover subtitle"
	)

	local fallbackTitle, fallbackSubtitle = WorldLabelPresentation.getPlacedResourceLabelText(nil, "None", "", nil)
	assert(fallbackTitle == "Unknown Resource", "missing resource names should fall back safely in the hover title")
	assert(fallbackSubtitle == "Common", "missing rarity should fall back safely in the hover subtitle")
end
