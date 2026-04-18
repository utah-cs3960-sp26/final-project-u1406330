--!strict

-- Client controller for Geode Interaction Controller that coordinates UI, local input, and app-state updates for this slice.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Geodes = require(Shared.Config.Geodes)
local World = require(Shared.Config.World)
local GeodePresentation = require(Shared.Domain.GeodePresentation)
local ResourceVisuals = require(Shared.Domain.ResourceVisuals)
local WorldLabelPresentation = require(Shared.Domain.WorldLabelPresentation)
local Time = require(Shared.Util.Time)
local GeodePlacementGhost = require(script.Parent.GeodePlacementGhost)
local ResourcePlacementGhost = require(script.Parent.ResourcePlacementGhost)

local GeodeInteractionController = {}
GeodeInteractionController.__index = GeodeInteractionController

local CLICK_COOLDOWN_SECONDS = 0.35
local REVEAL_DURATION_SECONDS = 2.4

local function resolveGeodePart(target: BasePart?): BasePart?
	if target == nil then
		return nil
	end

	if target:GetAttribute("GeodeId") ~= nil then
		return target
	end

	local parent = target.Parent
	if parent ~= nil and parent:IsA("BasePart") and parent:GetAttribute("GeodeId") ~= nil then
		return parent
	end

	return target
end

local function resolveResourcePart(target: BasePart?): BasePart?
	local current: Instance? = target
	while current ~= nil do
		if current:IsA("BasePart") and current:GetAttribute("ResourceId") ~= nil then
			return current
		end
		current = current.Parent
	end

	return nil
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

local function getGeodeMarkerLabel(geodePart: BasePart): TextLabel?
	local marker = geodePart:FindFirstChildWhichIsA("BillboardGui")
	if marker == nil then
		return nil
	end

	local label = marker:FindFirstChildWhichIsA("TextLabel", true)
	if label ~= nil then
		return label
	end

	return nil
end

local function getResourceMarker(resourcePart: BasePart): BillboardGui?
	local marker = resourcePart:FindFirstChildWhichIsA("BillboardGui")
	if marker ~= nil then
		return marker
	end

	local titleValue = resourcePart:GetAttribute("ResourceLabelTitle")
	local subtitleValue = resourcePart:GetAttribute("ResourceLabelSubtitle")
	if type(titleValue) ~= "string" or titleValue == "" then
		local displayName = resourcePart:GetAttribute("ResourceDisplayName")
		local traitDisplayName = resourcePart:GetAttribute("TraitDisplayName")
		local sizeIdValue = resourcePart:GetAttribute("SizeId")
		local rarityValue = resourcePart:GetAttribute("ResourceRarity")
		local sizeDisplayName = if type(sizeIdValue) == "string" and sizeIdValue ~= ""
			then sizeIdValue:gsub("^%l", string.upper)
			else nil
		local resolvedTitle, resolvedSubtitle = WorldLabelPresentation.getPlacedResourceLabelText(
			if type(displayName) == "string" then displayName else nil,
			if type(traitDisplayName) == "string" then traitDisplayName else nil,
			sizeDisplayName,
			if type(rarityValue) == "string" then rarityValue else nil
		)
		titleValue = resolvedTitle
		subtitleValue = resolvedSubtitle
		resourcePart:SetAttribute("ResourceLabelTitle", resolvedTitle)
		resourcePart:SetAttribute("ResourceLabelSubtitle", resolvedSubtitle)
	end

	local rarityRankValue = resourcePart:GetAttribute("ResourceRarityRank")
	local rarityRank = if type(rarityRankValue) == "number" then rarityRankValue else 1
	local accentColor = resourcePart.Color

	local fallbackMarker = Instance.new("BillboardGui")
	fallbackMarker.Name = resourcePart.Name .. "_Marker"
	fallbackMarker.Size = UDim2.fromOffset(188 + (rarityRank * 4), 54 + (rarityRank > 3 and 6 or 0))
	fallbackMarker.StudsOffset = Vector3.new(0, 2.8 + (rarityRank * 0.08), 0)
	fallbackMarker.AlwaysOnTop = true
	fallbackMarker.Enabled = false
	fallbackMarker.Parent = resourcePart

	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Color3.fromRGB(30, 26, 40)
	frame.BackgroundTransparency = 0.12
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = fallbackMarker

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 8)
	frameCorner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = accentColor
	stroke.Thickness = 2
	stroke.Transparency = 0.05
	stroke.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 0)
	layout.Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.LayoutOrder = 1
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.new(1, 0, 0, 26)
	titleLabel.Font = Enum.Font.FredokaOne
	titleLabel.Text = titleValue
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextStrokeColor3 = Color3.fromRGB(22, 18, 30)
	titleLabel.TextStrokeTransparency = 0.55
	titleLabel.TextScaled = true
	titleLabel.TextWrapped = true
	titleLabel.Parent = frame

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.LayoutOrder = 2
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Size = UDim2.new(1, 0, 0, 16)
	subtitleLabel.Font = Enum.Font.FredokaOne
	subtitleLabel.Text = if type(subtitleValue) == "string" and subtitleValue ~= "" then subtitleValue else "Common"
	subtitleLabel.TextColor3 = accentColor
	subtitleLabel.TextStrokeColor3 = Color3.fromRGB(22, 18, 30)
	subtitleLabel.TextStrokeTransparency = 0.7
	subtitleLabel.TextScaled = true
	subtitleLabel.TextWrapped = true
	subtitleLabel.Parent = frame

	return fallbackMarker
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

local function blendColor(baseColor: Color3, targetColor: Color3, alpha: number): Color3
	return baseColor:Lerp(targetColor, alpha)
end

local function createEffectPart(
	parent: Instance,
	className: "Part" | "WedgePart",
	name: string,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	transparency: number
): BasePart
	local part = Instance.new("Part")
	if className == "WedgePart" then
		part = Instance.new("WedgePart")
	end
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Size = size
	part.Color = color
	part.Material = material
	part.Transparency = transparency
	part.Parent = parent
	return part
end

local function createBurstEmitter(
	parent: Instance,
	name: string,
	texture: string,
	colorA: Color3,
	colorB: Color3,
	sizeStart: number,
	sizeEnd: number,
	speedMin: number,
	speedMax: number,
	lifetimeMin: number,
	lifetimeMax: number
): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = name
	emitter.Texture = texture
	emitter.Color = ColorSequence.new(colorA, colorB)
	emitter.LightEmission = 1
	emitter.Lifetime = NumberRange.new(lifetimeMin, lifetimeMax)
	emitter.Speed = NumberRange.new(speedMin, speedMax)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, sizeStart),
		NumberSequenceKeypoint.new(1, sizeEnd),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.08),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Drag = 2
	emitter.RotSpeed = NumberRange.new(-60, 60)
	emitter.Rate = 0
	emitter.Enabled = false
	emitter.Parent = parent
	return emitter
end

local function setModelTransparency(model: Model, transparency: number)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name ~= "RevealRoot" then
			descendant.Transparency = transparency
		end
	end
end

local function tweenModelToTargetTransparency(model: Model, duration: number)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name ~= "RevealRoot" then
			local targetTransparency = descendant:GetAttribute("TargetTransparency")
			if type(targetTransparency) == "number" then
				TweenService:Create(
					descendant,
					TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Transparency = targetTransparency }
				):Play()
			end
		end
	end
end

local function createRevealModel(resourceTypeId: string?, traitId: string?): (Model, PointLight, ParticleEmitter, ParticleEmitter, any)
	local profile = ResourceVisuals.resolveRevealProfile(resourceTypeId, traitId, nil, nil)
	local revealScale = profile.scale * (0.96 + ((profile.burstScale - 1) * 0.1))
	local model = Instance.new("Model")
	model.Name = "RevealedResource"

	local root = createEffectPart(model, "Part", "RevealRoot", Vector3.new(0.35, 0.35, 0.35), profile.glowColor, Enum.Material.SmoothPlastic, 1)
	root.Transparency = 1
	model.PrimaryPart = root

	local light = Instance.new("PointLight")
	light.Range = 0
	light.Brightness = 0
	light.Color = profile.traitGlowColor
	light.Parent = root

	local burstAttachment = Instance.new("Attachment")
	burstAttachment.Name = "BurstAttachment"
	burstAttachment.Parent = root

	local sparkleEmitter = createBurstEmitter(
		burstAttachment,
		"RevealSparkles",
		"rbxasset://textures/particles/sparkles_main.dds",
		profile.accentColor,
		profile.traitGlowColor,
		0.18 * revealScale,
		0.02 * revealScale,
		1.6,
		4.6 + profile.rarityRank,
		0.45,
		0.9
	)
	local mistEmitter = createBurstEmitter(
		burstAttachment,
		"RevealMist",
		"rbxasset://textures/particles/smoke_main.dds",
		profile.traitAccentColor,
		profile.glowColor,
		0.4 * revealScale,
		0.9 * revealScale,
		0.25,
		1.0,
		0.55,
		1.05
	)

	local rootYaw = math.rad((profile.hash % 360) - 180)
	local rootCFrame = CFrame.new() * CFrame.Angles(0, rootYaw, 0)
	local baseSize = Vector3.new(2.2, 0.34, 1.72) * revealScale
	local baseYOffset = -0.42 * revealScale

	local base = createEffectPart(
		model,
		"Part",
		"OreBase",
		baseSize,
		blendColor(profile.baseColor, Color3.fromRGB(26, 24, 32), 0.72),
		Enum.Material.Slate,
		0
	)
	base.CFrame = rootCFrame * CFrame.new(0, baseYOffset, 0)
	base:SetAttribute("TargetTransparency", 0)

	local lip = createEffectPart(
		model,
		"Part",
		"OreBaseHighlight",
		Vector3.new(1.58, 0.08, 1.08) * revealScale,
		blendColor(profile.baseColor, profile.accentColor, 0.18),
		Enum.Material.Slate,
		0.18
	)
	lip.CFrame = rootCFrame * CFrame.new(0, baseYOffset + (baseSize.Y * 0.5) + (0.035 * revealScale), 0)
	lip:SetAttribute("TargetTransparency", 0.18)

	for index, shard in ipairs(ResourceVisuals.getOreCrystalDefinitions(profile.variantId)) do
		local height = shard.height * revealScale
		local width = shard.width * revealScale
		local depth = shard.depth * revealScale
		local shardColor = blendColor(profile.baseColor, profile.traitGlowColor, shard.tint or 0.18)
		local shardCFrame = rootCFrame
			* CFrame.new(
				(shard.x or 0) * revealScale,
				baseYOffset + (baseSize.Y * 0.5) + (height * 0.5) - (0.04 * revealScale),
				(shard.z or 0) * revealScale
			)
			* CFrame.Angles(math.rad(shard.pitch or 0), math.rad(shard.yaw or 0), math.rad(shard.roll or 0))

		local body = createEffectPart(
			model,
			"Part",
			string.format("OreShard_%d", index),
			Vector3.new(width, height, depth),
			shardColor,
			Enum.Material.Glass,
			0.08
		)
		body.Reflectance = 0.12 + (profile.shineStrength * 0.03)
		body.CFrame = shardCFrame
		body:SetAttribute("TargetTransparency", 0.08)

		local capHeight = math.max(0.22, height * 0.22)
		local cap = createEffectPart(
			model,
			"WedgePart",
			string.format("OreShardTip_%d", index),
			Vector3.new(width * 1.05, capHeight, depth * 1.06),
			blendColor(shardColor, profile.traitGlowColor, 0.28),
			Enum.Material.Glass,
			0.02
		)
		cap.Reflectance = 0.16 + (profile.shineStrength * 0.04)
		cap.CFrame = shardCFrame * CFrame.new(0, (height * 0.5) + (capHeight * 0.28), 0)
		cap:SetAttribute("TargetTransparency", 0.02)

		local frontFacet = createEffectPart(
			model,
			"Part",
			string.format("OreFacetFront_%d", index),
			Vector3.new(width * 0.18, height * 0.7, 0.035 * revealScale),
			blendColor(profile.traitAccentColor, profile.traitGlowColor, 0.36),
			Enum.Material.Neon,
			0.38
		)
		frontFacet.CFrame = shardCFrame * CFrame.new(width * -0.24, height * 0.02, -(depth * 0.51))
		frontFacet:SetAttribute("TargetTransparency", 0.38)

		local sideFacet = createEffectPart(
			model,
			"Part",
			string.format("OreFacetSide_%d", index),
			Vector3.new(0.035 * revealScale, height * 0.58, depth * 0.42),
			blendColor(profile.baseColor, Color3.fromRGB(255, 255, 255), 0.24),
			Enum.Material.Neon,
			0.5
		)
		sideFacet.CFrame = shardCFrame * CFrame.new(width * 0.51, height * -0.02, depth * 0.08)
		sideFacet:SetAttribute("TargetTransparency", 0.5)
	end

	setModelTransparency(model, 1)
	return model, light, sparkleEmitter, mistEmitter, profile
end

local function playRevealAnimation(geodePart: BasePart, openResult: any)
	local corePart = geodePart:FindFirstChild("GeodeCore")
	local shellColor = if corePart ~= nil and corePart:IsA("BasePart") then corePart.Color else geodePart.Color
	local shellSize = if corePart ~= nil and corePart:IsA("BasePart") then corePart.Size else Vector3.new(3.35, 3.35, 3.35)
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

	local shellChip = Instance.new("WedgePart")
	shellChip.Name = "ShellChip"
	shellChip.Anchored = true
	shellChip.CanCollide = false
	shellChip.CanQuery = false
	shellChip.CanTouch = false
	shellChip.CastShadow = false
	shellChip.Material = Enum.Material.Slate
	shellChip.Color = shellColor
	shellChip.Size = Vector3.new(shellSize.X * 0.24, shellSize.Y * 0.42, shellSize.Z * 0.2)
	shellChip.CFrame = origin * CFrame.new(0, shellSize.Y * 0.16, -shellSize.Z * 0.18) * CFrame.Angles(0, math.rad(10), math.rad(20))
	shellChip.Parent = effectFolder

	local shellChipRight = shellChip:Clone()
	shellChipRight.Name = "ShellChipRight"
	shellChipRight.CFrame = origin * CFrame.new(0.2, shellSize.Y * 0.12, shellSize.Z * 0.22) * CFrame.Angles(0, math.rad(-18), math.rad(-20))
	shellChipRight.Parent = effectFolder

	local openTweenInfo = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(leftShell, openTweenInfo, {
		CFrame = origin * CFrame.new(-2.8, 1.05, -0.15) * CFrame.Angles(math.rad(-8), math.rad(-14), math.rad(-30)),
		Transparency = 0.28,
	}):Play()
	TweenService:Create(rightShell, openTweenInfo, {
		CFrame = origin * CFrame.new(2.8, 1.05, 0.15) * CFrame.Angles(math.rad(8), math.rad(14), math.rad(30)),
		Transparency = 0.28,
	}):Play()
	TweenService:Create(shellChip, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = origin * CFrame.new(-1.2, 1.45, -0.5) * CFrame.Angles(math.rad(25), math.rad(22), math.rad(38)),
		Transparency = 0.35,
	}):Play()
	TweenService:Create(shellChipRight, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = origin * CFrame.new(1.15, 1.3, 0.55) * CFrame.Angles(math.rad(-20), math.rad(-28), math.rad(-42)),
		Transparency = 0.35,
	}):Play()

	local resource = extractPrimaryResource(openResult)
	local revealModel, revealLight, sparkleEmitter, mistEmitter, profile = createRevealModel(
		resource and resource.resourceTypeId or nil,
		resource and resource.traitId or nil
	)
	revealModel.Parent = effectFolder
	revealModel:PivotTo(origin * CFrame.new(0, 0.55, 0))

	tweenModelToTargetTransparency(revealModel, 0.22)
	sparkleEmitter:Emit(10 + (profile.rarityRank * 4))
	mistEmitter:Emit(6 + math.max(0, math.floor((profile.burstScale - 1) * 6)))
	TweenService:Create(revealLight, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Brightness = 2.8,
		Range = 12,
	}):Play()

	task.spawn(function()
		task.wait(0.06)
		local startedAt = os.clock()
		local baseHeight = 2.55 + (profile.rarityRank * 0.16) + ((profile.burstScale - 1) * 0.25)
		local baseYaw = math.rad((profile.hash % 360) - 180)
		local connection
		connection = RunService.RenderStepped:Connect(function()
			local elapsed = os.clock() - startedAt
			local fadeLead = 0.38
			if elapsed >= REVEAL_DURATION_SECONDS - fadeLead then
				connection:Disconnect()
				TweenService:Create(revealLight, TweenInfo.new(0.2), {
					Brightness = 0,
					Range = 0,
				}):Play()
				for _, descendant in ipairs(revealModel:GetDescendants()) do
					if descendant:IsA("BasePart") and descendant.Name ~= "RevealRoot" then
						TweenService:Create(
							descendant,
							TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ Transparency = 1 }
						):Play()
					end
				end
				TweenService:Create(leftShell, TweenInfo.new(0.25), {
					Transparency = 1,
				}):Play()
				TweenService:Create(rightShell, TweenInfo.new(0.25), {
					Transparency = 1,
				}):Play()
				TweenService:Create(shellChip, TweenInfo.new(0.22), {
					Transparency = 1,
				}):Play()
				TweenService:Create(shellChipRight, TweenInfo.new(0.22), {
					Transparency = 1,
				}):Play()
				return
			end

			local riseAlpha = math.clamp(elapsed / 0.32, 0, 1)
			local easedRise = 1 - ((1 - riseAlpha) * (1 - riseAlpha))
			local bobOffset = math.sin((elapsed * 5.5) + 0.6) * 0.22
			local swayOffset = math.sin(elapsed * 2.6) * 0.16
			local yaw = baseYaw + (elapsed * (1.15 + ((profile.burstScale - 1) * 0.25)))
			local pitch = math.sin(elapsed * 2.3) * math.rad(4 + profile.rarityRank)
			local roll = math.sin(elapsed * 3.4) * math.rad(3)

			revealModel:PivotTo(
				CFrame.new(origin.Position + Vector3.new(swayOffset, (1.15 * (1 - easedRise)) + baseHeight + bobOffset, 0))
					* CFrame.Angles(pitch, yaw, roll)
			)
			revealLight.Brightness = 2.25 + (math.sin(elapsed * 8) * (0.18 + (profile.shineStrength * 0.22)))
			revealLight.Range = 11.5 + (math.sin(elapsed * 5.2) * 0.45)
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
	local resourcePreview = ResourcePlacementGhost.new()
	local lastClickAt = 0
	local activePlacementCellX: number? = nil
	local activePlacementCellY: number? = nil
	local activePlacementGeodeId: string? = nil
	local activePlacementResourceId: string? = nil
	local lastEquippedToolId: string? = nil
	local lastCountdownRefreshAt = 0
	local hoveredResourcePart: BasePart? = nil

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
		activePlacementResourceId = nil
		preview:hide()
		resourcePreview:hide()
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

		local pendingResourceId = app:getPendingResourcePlacementId()
		if geodeInstanceId == nil or geodeTypeId == nil then
			if pendingResourceId ~= nil then
				local state = app:getState()
				local resource = state.profile
					and state.profile.resourcesById
					and state.profile.resourcesById[pendingResourceId]
					or nil
				if type(resource) ~= "table" or resource.placement ~= nil or type(resource.resourceTypeId) ~= "string" then
					clearPreview()
					return
				end

				resourcePreview:setResourceTypeId(resource.resourceTypeId, resource.sizeId, resource.sizeValue)
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

				local cellX, cellY, _ = resourcePreview:showAt(plotModel, mouse.Hit.Position)
				if cellX == nil or cellY == nil then
					clearPreview()
					return
				end

				preview:hide()
				activePlacementCellX = cellX
				activePlacementCellY = cellY
				activePlacementGeodeId = nil
				activePlacementResourceId = pendingResourceId
				lastEquippedToolId = nil
				return
			end

			clearPreview()
			if lastEquippedToolId ~= nil then
				lastEquippedToolId = nil
			end
			return
		end

		local state = app:getState()
		local geode = state.profile and state.profile.geodesById and state.profile.geodesById[geodeInstanceId] or nil
		local geodeSizeId = if type(geode) == "table" then geode.sizeId else nil
		local geodeSizeValue = if type(geode) == "table" then geode.sizeValue else nil
		preview:setGeodeTypeId(geodeTypeId, geodeSizeId, geodeSizeValue)
		resourcePreview:hide()
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
		activePlacementResourceId = nil

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

	local function refreshGeodeCountdowns()
		local nowUnix = Time.nowUnix()
		local worldFolder = Workspace:FindFirstChild(World.worldFolderName)
		if worldFolder == nil then
			return
		end

		for _, descendant in ipairs(worldFolder:GetDescendants()) do
			if not descendant:IsA("BasePart") or descendant:GetAttribute("GeodeId") == nil then
				continue
			end

			local endsAt = descendant:GetAttribute("EndsAt")
			local readyState = getReadyStateLabel(descendant)
			local nextText = GeodePresentation.getWorldLabelText(
				readyState,
				if type(endsAt) == "number" then endsAt else nil,
				nowUnix
			)
			local label = getGeodeMarkerLabel(descendant)
			if label ~= nil and label.Text ~= nextText then
				label.Text = nextText
				label.TextColor3 = if nextText == "Ready!"
					then Color3.fromRGB(255, 255, 255)
					else Color3.fromRGB(184, 196, 214)
			end

			local nextState = if nextText == "Ready!" then "ready" else "cracking"
			if descendant:GetAttribute("ReadyState") ~= nextState then
				descendant:SetAttribute("ReadyState", nextState)
			end
			if descendant:GetAttribute("GeodeState") ~= nextState then
				descendant:SetAttribute("GeodeState", nextState)
			end
		end
	end

	local function setResourceMarkerEnabled(resourcePart: BasePart?, enabled: boolean)
		if resourcePart == nil then
			return
		end

		local marker = getResourceMarker(resourcePart)
		if marker ~= nil and marker.Enabled ~= enabled then
			marker.Enabled = enabled
		end
	end

	local function refreshHoveredResourceLabel()
		local target = mouse.Target
		local nextHoveredPart = if target ~= nil and target:IsA("BasePart") then resolveResourcePart(target) else nil
		local nextHoveredPartResourceId = if nextHoveredPart ~= nil and type(nextHoveredPart:GetAttribute("ResourceId")) == "string"
			then nextHoveredPart:GetAttribute("ResourceId") :: string
			else nil
		local nextHoveredResourceId = if nextHoveredPart ~= nil
			then WorldLabelPresentation.resolveHoveredResourceId(
				nextHoveredPartResourceId,
				nil
			)
			else nil

		if hoveredResourcePart ~= nextHoveredPart then
			setResourceMarkerEnabled(hoveredResourcePart, false)
			hoveredResourcePart = nil
		end

		if nextHoveredPart == nil then
			return
		end

		local shouldShowLabel = WorldLabelPresentation.shouldShowPlacedResourceLabel(
			nextHoveredPartResourceId,
			nextHoveredResourceId
		)
		setResourceMarkerEnabled(nextHoveredPart, shouldShowLabel)
		if shouldShowLabel then
			hoveredResourcePart = nextHoveredPart
		end
	end

	RunService.RenderStepped:Connect(function()
		refreshPlacementPreview()
		refreshHoveredResourceLabel()

		local now = os.clock()
		if now - lastCountdownRefreshAt >= 0.2 then
			lastCountdownRefreshAt = now
			refreshGeodeCountdowns()
		end
	end)

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

		if activePlacementResourceId ~= nil and activePlacementCellX ~= nil and activePlacementCellY ~= nil then
			app:requestPlaceResource(activePlacementResourceId, activePlacementCellX, activePlacementCellY)
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
			local openResult = result.open or result.claim
			playRevealAnimation(geodePart, openResult)
		end
	end

	mouse.Button1Down:Connect(handleClick)
end

return GeodeInteractionController
