--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")

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
			app:setStatus("Equip a pickaxe before mining.")
			if screen ~= nil and screen.showMiningPopup ~= nil then
				screen:showMiningPopup("Equip a pickaxe")
			end
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
			if type(result.coins) == "number" and result.coins > 0 then
				rewardText = string.format("Found %d coins in the mine.", math.floor(result.coins + 0.5))
			elseif type(result.geodeDisplayName) == "string" then
				rewardText = string.format("Unearthed %s.", tostring(result.geodeDisplayName))
			elseif type(result.geodeTypeId) == "string" then
				rewardText = string.format("Unearthed %s.", tostring(result.geodeTypeId))
			elseif type(result.rewardText) == "string" then
				rewardText = tostring(result.rewardText)
			end

			app:setStatus(rewardText or "Mining hit registered.")
			if screen ~= nil and screen.showMiningPopup ~= nil then
				screen:showMiningPopup(rewardText or "Mining hit registered")
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
