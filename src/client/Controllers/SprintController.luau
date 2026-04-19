--!strict

-- Client controller that owns local sprint input and keeps humanoid walk speed in sync across respawns.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local SprintController = {}
SprintController.__index = SprintController

local DEFAULT_WALK_SPEED = 16
local SPRINT_WALK_SPEED = 36

local function findHumanoid(character: Model?): Humanoid?
	if character == nil then
		return nil
	end

	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if humanoid == nil then
		return nil
	end

	return humanoid :: Humanoid
end

local function getTargetWalkSpeed(isSprinting: boolean): number
	return if isSprinting then SPRINT_WALK_SPEED else DEFAULT_WALK_SPEED
end

function SprintController.new(context)
	return setmetatable({
		context = context or {},
		isSprinting = false,
	}, SprintController)
end

function SprintController:applyWalkSpeedForCharacter(character: Model?)
	local humanoid = findHumanoid(character)
	if humanoid == nil then
		return
	end

	humanoid.WalkSpeed = getTargetWalkSpeed(self.isSprinting)
end

function SprintController:setSprinting(isSprinting: boolean)
	if self.isSprinting == isSprinting then
		return
	end

	self.isSprinting = isSprinting
	self:applyWalkSpeedForCharacter(Players.LocalPlayer.Character)
end

function SprintController:start()
	self.isSprinting = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
	self:applyWalkSpeedForCharacter(Players.LocalPlayer.Character)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			self:setSprinting(true)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			self:setSprinting(false)
		end
	end)

	Players.LocalPlayer.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid then
			-- Reapply the active sprint state so respawns do not briefly desync movement speed.
			(humanoid :: Humanoid).WalkSpeed = getTargetWalkSpeed(self.isSprinting)
		end
	end)
end

return SprintController
