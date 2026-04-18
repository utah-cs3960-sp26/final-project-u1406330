--!strict

-- Client controller for Mining Controller that coordinates UI, local input, and app-state updates for this slice.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Geodes = require(Shared.Config.Geodes)
local Pickaxes = require(Shared.Config.Pickaxes)
local RemoteNames = require(Shared.Net.RemoteNames)

local MiningController = {}
MiningController.__index = MiningController

local MINE_TARGET_ATTRIBUTE = "GemFactoryMineTarget"
local PICKAXE_TOOL_ATTRIBUTE = "GemFactoryPickaxeTool"
local MINE_COOLDOWN_SECONDS = 0.35
local MINE_REMOTE_NAME = (RemoteNames :: any).RequestMine or "RequestMine"
local SWING_WINDUP_TIME = 0.07
local SWING_STRIKE_TIME = 0.11
local SWING_RECOVER_TIME = 0.16
local SWING_WINDUP_OFFSET = CFrame.new(0.02, -0.05, 0.04) * CFrame.Angles(math.rad(-18), math.rad(-8), math.rad(20))
local SWING_STRIKE_OFFSET = CFrame.new(-0.04, 0.08, -0.1) * CFrame.Angles(math.rad(42), math.rad(10), math.rad(-34))

local activeSwingByTool = setmetatable({}, { __mode = "k" })
local GEODE_RARITY_BY_ID = {
	starter_geode = "Common",
	crystal_cavern_geode = "Uncommon",
	moonlit_geode = "Rare",
	ember_glass_geode = "Epic",
	verdant_rift_geode = "Mythic",
	aurora_shard_geode = "Legendary",
	thunder_core_geode = "Storm",
	fossil_vault_geode = "Ancient",
	prism_sun_geode = "Prismatic",
	sovereign_nova_geode = "Sovereign",
}
local GEODE_RARITY_ORDER = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Mythic",
	"Legendary",
	"Storm",
	"Ancient",
	"Prismatic",
	"Sovereign",
}

local GEODE_RARITY_INDEX_BY_NAME = {}
for index, rarityName in ipairs(GEODE_RARITY_ORDER) do
	GEODE_RARITY_INDEX_BY_NAME[rarityName] = index
end

local function getPickaxeDisplayName(tool: Tool): string
	local pickaxeTypeId = tool:GetAttribute("PickaxeTypeId")
	if type(pickaxeTypeId) == "string" and pickaxeTypeId ~= "" then
		local definition = Pickaxes.catalog[pickaxeTypeId]
		return if definition ~= nil then definition.displayName else pickaxeTypeId
	end

	local pickaxeId = tool:GetAttribute("PickaxeId")
	if type(pickaxeId) == "string" and pickaxeId ~= "" then
		local definition = Pickaxes.catalog[pickaxeId]
		return if definition ~= nil then definition.displayName else pickaxeId
	end

	return tool.Name
end

local function getGeodeCelebrationInfo(geodeTypeId: string?, geodeDisplayName: string?)
	local rarityName = if geodeTypeId ~= nil then GEODE_RARITY_BY_ID[geodeTypeId] else nil
	local geodeDefinition = if geodeTypeId ~= nil then Geodes[geodeTypeId] else nil
	local displayName
	if type(geodeDisplayName) == "string" then
		displayName = geodeDisplayName
	elseif geodeDefinition ~= nil and geodeDefinition.displayName ~= nil then
		displayName = geodeDefinition.displayName
	elseif geodeTypeId ~= nil then
		displayName = geodeTypeId
	else
		displayName = "Geode"
	end
	local rarityIndex = if type(rarityName) == "string" then GEODE_RARITY_INDEX_BY_NAME[rarityName] or 1 else 1

	return {
		geodeTypeId = geodeTypeId,
		geodeDisplayName = displayName,
		rarityLabel = rarityName or "Common",
		rarityIndex = rarityIndex,
		accentColor = if geodeDefinition ~= nil then geodeDefinition.displayColor else nil,
	}
end

local function isMineTarget(target: Instance?): BasePart?
	if target == nil or not target:IsA("BasePart") then
		return nil
	end

	if target:GetAttribute(MINE_TARGET_ATTRIBUTE) == true then
		return target
	end

	local ancestor = target.Parent
	while ancestor ~= nil do
		if ancestor:IsA("Model") and ancestor:GetAttribute("GemFactoryMine") == true then
			return target
		end
		ancestor = ancestor.Parent
	end

	return nil
end

local function playPickaxeSwing(tool: Tool)
	local baseGrip = tool:GetAttribute("GemFactoryBaseGrip")
	if typeof(baseGrip) ~= "CFrame" then
		baseGrip = tool.Grip
		tool:SetAttribute("GemFactoryBaseGrip", baseGrip)
	end

	local activeSwing = activeSwingByTool[tool]
	if activeSwing ~= nil then
		for _, tween in ipairs(activeSwing.tweens) do
			tween:Cancel()
		end
	end

	local swingToken = {}
	local windupGrip = baseGrip * SWING_WINDUP_OFFSET
	local strikeGrip = baseGrip * SWING_STRIKE_OFFSET
	local windupTween = TweenService:Create(
		tool,
		TweenInfo.new(SWING_WINDUP_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Grip = windupGrip }
	)
	local strikeTween = TweenService:Create(
		tool,
		TweenInfo.new(SWING_STRIKE_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{ Grip = strikeGrip }
	)
	local recoverTween = TweenService:Create(
		tool,
		TweenInfo.new(SWING_RECOVER_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Grip = baseGrip }
	)

	activeSwingByTool[tool] = {
		token = swingToken,
		tweens = { windupTween, strikeTween, recoverTween },
	}

	windupTween.Completed:Connect(function(playbackState)
		local currentSwing = activeSwingByTool[tool]
		if playbackState == Enum.PlaybackState.Completed and currentSwing ~= nil and currentSwing.token == swingToken then
			strikeTween:Play()
		end
	end)

	strikeTween.Completed:Connect(function(playbackState)
		local currentSwing = activeSwingByTool[tool]
		if playbackState == Enum.PlaybackState.Completed and currentSwing ~= nil and currentSwing.token == swingToken then
			recoverTween:Play()
		end
	end)

	recoverTween.Completed:Connect(function()
		local currentSwing = activeSwingByTool[tool]
		if currentSwing ~= nil and currentSwing.token == swingToken then
			activeSwingByTool[tool] = nil
			tool.Grip = baseGrip
		end
	end)

	tool.Grip = baseGrip
	windupTween:Play()
end

function MiningController.new(context)
	return setmetatable({
		context = context or {},
	}, MiningController)
end

function MiningController:start()
	local app = self.context.app
	local screen = self.context.screen
	local mouse = Players.LocalPlayer:GetMouse()
	local lastMineClickAt = 0
	local lastEquippedPickaxeId: string? = nil

	local function getEquippedPickaxeTool()
		local character = Players.LocalPlayer.Character
		if character == nil then
			return nil
		end

		local tool = character:FindFirstChildWhichIsA("Tool")
		if tool == nil then
			return nil
		end

		if tool:GetAttribute(PICKAXE_TOOL_ATTRIBUTE) ~= true then
			return nil
		end

		local pickaxeTypeId = tool:GetAttribute("PickaxeTypeId")
		if type(pickaxeTypeId) ~= "string" or pickaxeTypeId == "" then
			pickaxeTypeId = tool.Name
		end

		return tool, tostring(pickaxeTypeId)
	end

	local function refreshEquippedStatus()
		local equippedTool, pickaxeId = getEquippedPickaxeTool()
		if equippedTool ~= nil and pickaxeId ~= nil and lastEquippedPickaxeId ~= pickaxeId then
			lastEquippedPickaxeId = pickaxeId
			app:setStatus(string.format("Equipped %s. Click the mine to dig.", getPickaxeDisplayName(equippedTool)))
		elseif equippedTool == nil then
			lastEquippedPickaxeId = nil
		end
	end

	RunService.RenderStepped:Connect(refreshEquippedStatus)

	local function handleMineClick()
		local now = os.clock()
		if now - lastMineClickAt < MINE_COOLDOWN_SECONDS then
			return
		end
		lastMineClickAt = now

		local equippedTool, pickaxeId = getEquippedPickaxeTool()
		if equippedTool == nil then
			return
		end
		playPickaxeSwing(equippedTool)

		local mineTarget = isMineTarget(mouse.Target)
		if mineTarget == nil then
			return
		end

		local ok, result = app:invokeRemote(MINE_REMOTE_NAME, pickaxeId, mineTarget)
		if ok and type(result) == "table" and result.ok == true then
			local rewardText = nil
			local rewardPopup = nil
			if type(result.coins) == "number" and result.coins > 0 then
				local coinAmount = math.floor(result.coins + 0.5)
				rewardText = string.format("+%d Coins", coinAmount)
				rewardPopup = {
					kind = "coin",
					headline = rewardText,
					primary = rewardText,
					duration = 0.8,
					compact = true,
				}
			elseif type(result.geodeDisplayName) == "string" or type(result.geodeTypeId) == "string" then
				local displayName = result.geodeDisplayName or result.geodeTypeId
				rewardText = string.format("Unearthed %s.", tostring(displayName))
				rewardPopup = getGeodeCelebrationInfo(result.geodeTypeId, result.geodeDisplayName)
				rewardPopup.kind = "geode_discovery"
				rewardPopup.headline = "GEODE FOUND!"
				rewardPopup.primary = rewardPopup.geodeDisplayName
				rewardPopup.showSlotMachine = false
				rewardPopup.detail = rewardPopup.rarityLabel
			elseif type(result.rewardText) == "string" then
				rewardText = tostring(result.rewardText)
			end

			app:setStatus(rewardText or "Mining hit registered.")
			if screen ~= nil and screen.showMiningPopup ~= nil then
				screen:showMiningPopup(rewardPopup or rewardText or "Mining hit registered")
			end
		else
			local errorText = type(result) == "table" and result.errorCode or result
			if errorText == "mine_cooldown" then
				return
			end
			if errorText == "not_inside_mine" then
				app:setStatus("Stand inside the mine to mine.")
				if screen ~= nil and screen.showMiningPopup ~= nil then
					screen:showMiningPopup("Stand inside the mine")
				end
				return
			end
			app:setStatus("Mining failed: " .. tostring(errorText))
		end
	end

	mouse.Button1Down:Connect(handleMineClick)
end

return MiningController
