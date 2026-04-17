--!strict

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local SprintController = {}
SprintController.__index = SprintController

local DEFAULT_WALK_SPEED = 16
local SPRINT_WALK_SPEED = 28

function SprintController.new(context)
	return setmetatable({
		context = context or {},
	}, SprintController)
end

function SprintController:start()
	local function setSpeed(sprinting: boolean)
		local character = Players.LocalPlayer.Character
		if character == nil then
			return
		end
		local humanoid = character:FindFirstChildWhichIsA("Humanoid")
		if humanoid == nil then
			return
		end
		humanoid.WalkSpeed = if sprinting then SPRINT_WALK_SPEED else DEFAULT_WALK_SPEED
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.LeftShift then
			setSpeed(true)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift then
			setSpeed(false)
		end
	end)

	-- Reset speed on respawn
	Players.LocalPlayer.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid then
			(humanoid :: Humanoid).WalkSpeed = DEFAULT_WALK_SPEED
		end
	end)
end

return SprintController
