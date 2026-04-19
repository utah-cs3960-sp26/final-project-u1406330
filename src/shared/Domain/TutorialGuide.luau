--!strict

-- Shared tutorial copy and ordering for the future HUD guide so gameplay onboarding stays deterministic and easy to reuse.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Geodes = require(Shared.Config.Geodes)
local Pickaxes = require(Shared.Config.Pickaxes)

local TutorialGuide = {}

local function cloneValue(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, nestedValue in pairs(value) do
		copy[key] = cloneValue(nestedValue)
	end

	return copy
end

local defaultPickaxeId = Pickaxes.order[1] or "stone_pickaxe"
local defaultPickaxe = Pickaxes.catalog[defaultPickaxeId] or Pickaxes.catalog.stone_pickaxe
local starterGeode = Geodes.starter_geode

local CONTENT = {
	button = {
		label = "Tutorial",
		subtitle = "How to play",
	},
	header = {
		title = "Gem Factory Tutorial",
		subtitle = string.format(
			"Start with your %s, mine for coins and geodes, then build up your cave one reveal at a time.",
			tostring(defaultPickaxe.displayName or "starter pickaxe")
		),
	},
	steps = {
		{
			id = "equip_pickaxe",
			title = "1. Equip your pickaxe",
			summary = string.format("Use the %s from your backpack before you start mining.", tostring(defaultPickaxe.displayName or "starter pickaxe")),
			details = {
				"Mining only works while you have a pickaxe equipped.",
				"Your current pickaxe controls coin payouts, geode odds, and mining speed.",
			},
			focus = "Backpack and equipped tool",
		},
		{
			id = "mine_for_rewards",
			title = "2. Mine inside the cave",
			summary = "Stand in the mine and click to earn coins or geodes.",
			details = {
				"You must be inside the mine zone for mining rewards to count.",
				"Most swings give coins, and some swings drop geodes you can keep.",
			},
			focus = "Mine entrance and reward popups",
		},
		{
			id = "buy_pickaxe_upgrades",
			title = "3. Upgrade at the pickaxe shop",
			summary = "Spend coins on stronger pickaxes to improve mining results.",
			details = {
				"Better pickaxes raise geode chances and shift drops toward rarer finds.",
				"Buying an upgrade replaces your previous pickaxe instead of stacking another one.",
			},
			focus = "Pickaxe shop",
		},
		{
			id = "open_vault",
			title = "4. Open the Vault",
			summary = "Use the Vault button or the world prompt to manage geodes and resources.",
			details = {
				"Items stay in the Vault until you place or sell them.",
				"Resources from cracked geodes return to the Vault first, so you can decide what to do next.",
			},
			focus = "Vault button and Vault prompt",
		},
		{
			id = "place_geodes",
			title = "5. Place geodes on your plot",
			summary = string.format("Drop a geode like the %s onto your plot so it can start cracking.", tostring(starterGeode.displayName or "Starter Geode")),
			details = {
				"Placed geodes run on a timer before they become ready to open.",
				"Use your plot space carefully, because placed items occupy grid cells until you pick them up or crack them open.",
			},
			focus = "Plot and geode placement",
		},
		{
			id = "crack_and_collect",
			title = "6. Crack ready geodes",
			summary = "Click a ready geode on your plot to reveal a resource and possible attribute.",
			details = {
				"Ready geodes open in the world after their timer finishes.",
				"The revealed resource goes back into the Vault, where you can place it, keep it, or sell it.",
			},
			focus = "Ready geodes and reveal flow",
		},
		{
			id = "place_or_sell_resources",
			title = "7. Display or sell your finds",
			summary = "Place favorite resources on your plot or sell extras for more coins.",
			details = {
				"Placed resources show off your progress and can be picked back up later.",
				"Selling extra items funds the next pickaxe upgrade and keeps the loop moving.",
			},
			focus = "Vault inventory and plot displays",
		},
	},
	tips = {
		{
			id = "resource_guide_tip",
			title = "Check the Resource Guide",
			body = "Use the Resource Guide to see rarity info and track which resources and attributes you have already discovered.",
		},
		{
			id = "space_tip",
			title = "Keep plot space open",
			body = "If your plot feels crowded, pick up old displays or crack finished geodes before placing more.",
		},
		{
			id = "upgrade_tip",
			title = "Upgrade early",
			body = "Pickaxe upgrades improve both coin income and the odds of finding better geodes, so they speed up everything else.",
		},
	},
	rules = {
		{
			id = "mine_zone_rule",
			label = "Mine rewards are server-checked",
			description = "You have to be standing in the mine zone for valid mining swings.",
		},
		{
			id = "geode_source_rule",
			label = "Geodes come from mining",
			description = "The geode shop flow is gone, so mining is the way to earn geodes.",
		},
		{
			id = "vault_flow_rule",
			label = "The Vault is your item hub",
			description = "Geodes and resources live in the Vault until you place, crack, pick up, or sell them.",
		},
	},
}

local STEP_INDEX = {}
for index, step in ipairs(CONTENT.steps) do
	STEP_INDEX[step.id] = index
end

function TutorialGuide.getButtonCopy(): any
	return cloneValue(CONTENT.button)
end

function TutorialGuide.getHeader(): any
	return cloneValue(CONTENT.header)
end

function TutorialGuide.getSteps(): { any }
	return cloneValue(CONTENT.steps)
end

function TutorialGuide.getTips(): { any }
	return cloneValue(CONTENT.tips)
end

function TutorialGuide.getRules(): { any }
	return cloneValue(CONTENT.rules)
end

function TutorialGuide.getStepById(stepId: string?): any
	if type(stepId) ~= "string" then
		return nil
	end

	local index = STEP_INDEX[stepId]
	if index == nil then
		return nil
	end

	return cloneValue(CONTENT.steps[index])
end

function TutorialGuide.getGuide(): any
	return {
		button = TutorialGuide.getButtonCopy(),
		header = TutorialGuide.getHeader(),
		steps = TutorialGuide.getSteps(),
		tips = TutorialGuide.getTips(),
		rules = TutorialGuide.getRules(),
	}
end

return TutorialGuide
