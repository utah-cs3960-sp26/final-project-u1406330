--!strict

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Geodes = require(Shared.Config.Geodes)
local Resources = require(Shared.Config.Resources)
local GeodePlacementGhost = require(script.Parent.GeodePlacementGhost)

local GeodeInteractionController = {}
GeodeInteractionController.__index = GeodeInteractionController

local CLICK_COOLDOWN_SECONDS = 0.35
local REVEAL_DURATION_SECONDS = 2.4

local function resolveGeodePart(target: BasePart?): BasePart?
	if target == nil then
		return nil
	end

	if string.sub(target.Name, -6) == "_Shell" then
		local parent = target.Parent
		if parent ~= nil then
			local siblingName = string.sub(target.Name, 1, -7)
			local sibling = parent:FindFirstChild(siblingName)
			if sibling ~= nil and sibling:IsA("BasePart") then
				return sibling
			end
		end
	end

	return target
end

local function findPlotModel(instance: Instance?): Model?
	local current: Instance? = instance
	while current ~= nil do
		if current:IsA("Model") and current:GetAttribute("PlotId") ~= nil then
			return current
		end
		current = current.Parent
	end

	return nil
end

local function getReadyStateLabel(geodePart: BasePart): string?
	local readyState = geodePart:GetAttribute("ReadyState")
	if readyState ~= nil then
		return tostring(readyState)
	end

	local geodeState = geodePart:GetAttribute("GeodeState")
	if geodeState ~= nil then
		return tostring(geodeState)
	end

	local marker = geodePart:FindFirstChildWhichIsA("BillboardGui")
	if marker ~= nil then
		local label = marker:FindFirstChildWhichIsA("TextLabel", true)
		if label ~= nil then
			return label.Text
		end
	end

	return nil
end

local function extractPrimaryResource(openResult: any)
	if type(openResult) ~= "table" then
		return nil
	end

	local createdResources = openResult.createdResources
	if type(createdResources) == "table" and type(createdResources[1]) == "table" then
		return createdResources[1]
	end

	return nil
end

local function createRevealPart(resourceTypeId: string?, origin: CFrame): BasePart
	local resourceDefinition = if resourceTypeId ~= nil then Resources[resourceTypeId] else nil
	local part = Instance.new("Part")
	part.Name = "RevealedResource"
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = if resourceDefinition ~= nil and resourceDefinition.color ~= nil
		then resourceDefinition.color
		else Color3.fromRGB(240, 240, 255)
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(0.4, 0.4, 0.4)
	part.CFrame = origin

	local light = Instance.new("PointLight")
	light.Range = 12
	light.Brightness = 0
	light.Color = part.Color
	light.Parent = part

	return part
end

local function playRevealAnimation(geodePart: BasePart, openResult: any)
	local shellPart = geodePart.Parent and geodePart.Parent:FindFirstChild(geodePart.Name .. "_Shell")
	local shellColor = if shellPart ~= nil and shellPart:IsA("BasePart") then shellPart.Color else geodePart.Color
	local shellSize = if shellPart ~= nil and shellPart:IsA("BasePart") then shellPart.Size else Vector3.new(3.2, 3.2, 3.2)
	local origin = geodePart.CFrame

	local effectFolder = Instance.new("Folder")
	effectFolder.Name = "GeodeRevealFx"
	effectFolder.Parent = Workspace
	Debris:AddItem(effectFolder, REVEAL_DURATION_SECONDS + 1)

	local leftShell = Instance.new("Part")
	leftShell.Name = "LeftShell"
	leftShell.Anchored = true
	leftShell.CanCollide = false
	leftShell.Material = Enum.Material.Slate
	leftShell.Color = shellColor
	leftShell.Size = Vector3.new(shellSize.X * 0.46, shellSize.Y, shellSize.Z)
	leftShell.CFrame = origin * CFrame.new(-0.8, 0, 0)
	leftShell.Parent = effectFolder

	local rightShell = leftShell:Clone()
	rightShell.Name = "RightShell"
	rightShell.CFrame = origin * CFrame.new(0.8, 0, 0)
	rightShell.Parent = effectFolder

	local openTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(leftShell, openTweenInfo, {
		CFrame = origin * CFrame.new(-2.4, 0.8, 0) * CFrame.Angles(0, 0, math.rad(-22)),
		Transparency = 0.2,
	}):Play()
	TweenService:Create(rightShell, openTweenInfo, {
		CFrame = origin * CFrame.new(2.4, 0.8, 0) * CFrame.Angles(0, 0, math.rad(22)),
		Transparency = 0.2,
	}):Play()

	local resource = extractPrimaryResource(openResult)
	local revealPart = createRevealPart(resource and resource.resourceTypeId or nil, origin)
	revealPart.Parent = effectFolder

	local revealLight = revealPart:FindFirstChildWhichIsA("PointLight")
	TweenService:Create(revealPart, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = Vector3.new(2.15, 2.15, 2.15),
		CFrame = origin * CFrame.new(0, 2.8, 0),
	}):Play()
	if revealLight ~= nil then
		TweenService:Create(revealLight, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Brightness = 2.5,
		}):Play()
	end

	task.spawn(function()
		task.wait(0.28)
		local startedAt = os.clock()
		local basePosition = origin.Position + Vector3.new(0, 2.8, 0)
		local connection
		connection = RunService.RenderStepped:Connect(function()
			local elapsed = os.clock() - startedAt
			if elapsed >= REVEAL_DURATION_SECONDS - 0.28 then
				connection:Disconnect()
				if revealLight ~= nil then
					TweenService:Create(revealLight, TweenInfo.new(0.2), {
						Brightness = 0,
					}):Play()
				end
				TweenService:Create(revealPart, TweenInfo.new(0.25), {
					Transparency = 1,
				}):Play()
				TweenService:Create(leftShell, TweenInfo.new(0.25), {
					Transparency = 1,
				}):Play()
				TweenService:Create(rightShell, TweenInfo.new(0.25), {
					Transparency = 1,
				}):Play()
				return
			end

			local bounceOffset = math.sin(elapsed * 7) * 0.45
			local yaw = elapsed * 2.2
			local scalePulse = 2.15 + (math.sin(elapsed * 10) * 0.12)
			revealPart.Size = Vector3.new(scalePulse, scalePulse, scalePulse)
			revealPart.CFrame = CFrame.new(basePosition + Vector3.new(0, bounceOffset, 0))
				* CFrame.Angles(0, yaw, 0)

			if revealLight ~= nil then
				revealLight.Brightness = 2.2 + (math.sin(elapsed * 12) * 0.6)
			end
		end)
	end)
end

function GeodeInteractionController.new(context)
	return setmetatable({
		context = context or {},
	}, GeodeInteractionController)
end

function GeodeInteractionController:start()
	local app = self.context.app
	local mouse = Players.LocalPlayer:GetMouse()
	local preview = GeodePlacementGhost.new()
	local lastClickAt = 0
	local activePlacementCellX: number? = nil
	local activePlacementCellY: number? = nil
	local activePlacementGeodeId: string? = nil
	local lastEquippedToolId: string? = nil

	local function getEquippedGeodeTool()
		local character = Players.LocalPlayer.Character
		if character == nil then
			return nil
		end

		local tool = character:FindFirstChildWhichIsA("Tool")
		if tool == nil then
			return nil
		end

		if tool:GetAttribute("GemFactoryGeodeTool") ~= true then
			return nil
		end

		local geodeInstanceId = tool:GetAttribute("GeodeInstanceId")
		local geodeTypeId = tool:GetAttribute("GeodeTypeId")
		if type(geodeInstanceId) ~= "string" or type(geodeTypeId) ~= "string" then
			return nil
		end

		return tool, geodeInstanceId, geodeTypeId
	end

	local function resolvePendingPlacement()
		local pendingGeodePlacementId = app:getPendingGeodePlacementId()
		if pendingGeodePlacementId == nil then
			return nil
		end

		local state = app:getState()
		local geode = state.profile and state.profile.geodesById and state.profile.geodesById[pendingGeodePlacementId] or nil
		if type(geode) ~= "table" or geode.placement ~= nil then
			return nil
		end

		if type(geode.geodeTypeId) ~= "string" then
			return nil
		end

		return pendingGeodePlacementId, geode.geodeTypeId
	end

	local function clearPreview()
		activePlacementCellX = nil
		activePlacementCellY = nil
		activePlacementGeodeId = nil
		preview:hide()
	end

	local function refreshPlacementPreview()
		local equippedTool, equippedGeodeInstanceId, equippedGeodeTypeId = getEquippedGeodeTool()
		local geodeInstanceId
		local geodeTypeId
		if equippedTool ~= nil then
			geodeInstanceId = equippedGeodeInstanceId
			geodeTypeId = equippedGeodeTypeId
		else
			local pendingId, pendingTypeId = resolvePendingPlacement()
			geodeInstanceId = pendingId
			geodeTypeId = pendingTypeId
		end

		if geodeInstanceId == nil or geodeTypeId == nil then
			clearPreview()
			if lastEquippedToolId ~= nil then
				lastEquippedToolId = nil
			end
			return
		end

		preview:setGeodeTypeId(geodeTypeId)
		local plotModel = findPlotModel(mouse.Target)
		if plotModel == nil then
			clearPreview()
			return
		end

		local ownerUserId = plotModel:GetAttribute("OwnerUserId")
		if ownerUserId ~= Players.LocalPlayer.UserId then
			clearPreview()
			return
		end

		local cellX, cellY, _ = preview:showAt(plotModel, mouse.Hit.Position)
		if cellX == nil or cellY == nil then
			clearPreview()
			return
		end

		activePlacementCellX = cellX
		activePlacementCellY = cellY
		activePlacementGeodeId = geodeInstanceId

		if equippedTool ~= nil and lastEquippedToolId ~= geodeInstanceId then
			lastEquippedToolId = geodeInstanceId
			local geodeDefinition = Geodes[geodeTypeId]
			if geodeDefinition ~= nil and geodeDefinition.displayName ~= nil then
				app:setStatus(string.format("Equipped %s. Click your plot to place it.", geodeDefinition.displayName))
			end
		elseif equippedTool == nil then
			lastEquippedToolId = nil
		end
	end

	RunService.RenderStepped:Connect(refreshPlacementPreview)

	local function handleClick()
		local now = os.clock()
		if now - lastClickAt < CLICK_COOLDOWN_SECONDS then
			return
		end
		lastClickAt = now

		if activePlacementGeodeId ~= nil and activePlacementCellX ~= nil and activePlacementCellY ~= nil then
			app:requestPlaceGeode(activePlacementGeodeId, activePlacementCellX, activePlacementCellY)
			return
		end

		local target = mouse.Target
		if target == nil or not target:IsA("BasePart") then
			return
		end

		local geodePart = resolveGeodePart(target)
		if geodePart == nil then
			return
		end

		local geodeId = geodePart:GetAttribute("GeodeId")
		local resolvedGeodeId = if geodeId ~= nil then tostring(geodeId) else geodePart.Name
		local readyState = getReadyStateLabel(geodePart)
		if readyState == nil then
			app:setStatus("That geode is not ready to crack yet.")
			return
		end

		local normalizedState = string.lower(readyState)
		if normalizedState ~= "ready" and normalizedState ~= "finished" then
			app:setStatus("That geode is still cracking.")
			return
		end

		local ok, result = app:requestOpenReadyGeode(resolvedGeodeId)
		if ok and type(result) == "table" and result.ok == true then
			playRevealAnimation(geodePart, result.open or result.claim)
		end
	end

	mouse.Button1Down:Connect(handleClick)
end

return GeodeInteractionController
