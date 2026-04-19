--!strict

-- Screen-construction module for Root Screen that builds the main client HUD and exposes imperative UI hooks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Geodes = require(Shared.Config.Geodes)
local Resources = require(Shared.Config.Resources)
local Traits = require(Shared.Config.Traits)
local GeodePresentation = require(Shared.Domain.GeodePresentation)
local ResourceGuide = require(Shared.Domain.ResourceGuide)
local ResourceVisuals = require(Shared.Domain.ResourceVisuals)
local RewardPresentation = require(Shared.Domain.RewardPresentation)
local Panel = require(script.Parent.Parent.Components.Panel)

local RootScreen = {}
RootScreen.__index = RootScreen

local SHOP_BASE_Z_INDEX = 60
local VAULT_BASE_Z_INDEX = 55
local POPUP_Z_INDEX = 80
local POPUP_QUEUE_LIMIT = 6
local GUIDE_BASE_Z_INDEX = 58
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

local RARITY_TONES = {
	[1] = {
		background = Color3.fromRGB(255, 250, 214),
		accent = Color3.fromRGB(255, 204, 86),
		highlight = Color3.fromRGB(255, 231, 150),
		text = Color3.fromRGB(83, 54, 18),
	},
	[2] = {
		background = Color3.fromRGB(224, 247, 255),
		accent = Color3.fromRGB(109, 230, 255),
		highlight = Color3.fromRGB(182, 241, 255),
		text = Color3.fromRGB(30, 62, 84),
	},
	[3] = {
		background = Color3.fromRGB(255, 234, 237),
		accent = Color3.fromRGB(255, 126, 164),
		highlight = Color3.fromRGB(255, 202, 219),
		text = Color3.fromRGB(86, 29, 49),
	},
	[4] = {
		background = Color3.fromRGB(235, 255, 238),
		accent = Color3.fromRGB(120, 231, 184),
		highlight = Color3.fromRGB(202, 255, 216),
		text = Color3.fromRGB(32, 79, 52),
	},
	[5] = {
		background = Color3.fromRGB(239, 244, 255),
		accent = Color3.fromRGB(166, 194, 255),
		highlight = Color3.fromRGB(211, 225, 255),
		text = Color3.fromRGB(44, 53, 90),
	},
	[6] = {
		background = Color3.fromRGB(255, 241, 221),
		accent = Color3.fromRGB(255, 170, 92),
		highlight = Color3.fromRGB(255, 220, 183),
		text = Color3.fromRGB(89, 46, 16),
	},
	[7] = {
		background = Color3.fromRGB(225, 255, 251),
		accent = Color3.fromRGB(102, 224, 206),
		highlight = Color3.fromRGB(178, 255, 241),
		text = Color3.fromRGB(23, 74, 72),
	},
	[8] = {
		background = Color3.fromRGB(241, 255, 226),
		accent = Color3.fromRGB(166, 220, 102),
		highlight = Color3.fromRGB(219, 255, 176),
		text = Color3.fromRGB(49, 76, 25),
	},
	[9] = {
		background = Color3.fromRGB(250, 235, 255),
		accent = Color3.fromRGB(255, 145, 222),
		highlight = Color3.fromRGB(255, 205, 238),
		text = Color3.fromRGB(87, 31, 88),
	},
	[10] = {
		background = Color3.fromRGB(255, 248, 232),
		accent = Color3.fromRGB(255, 216, 113),
		highlight = Color3.fromRGB(255, 240, 185),
		text = Color3.fromRGB(92, 60, 18),
	},
}

local TRAIT_TONES = {
	prismatic = {
		background = Color3.fromRGB(240, 248, 255),
		accent = Color3.fromRGB(129, 220, 255),
		highlight = Color3.fromRGB(255, 170, 228),
		text = Color3.fromRGB(48, 63, 92),
	},
	celestial = {
		background = Color3.fromRGB(255, 250, 228),
		accent = Color3.fromRGB(255, 222, 111),
		highlight = Color3.fromRGB(255, 238, 179),
		text = Color3.fromRGB(90, 63, 20),
	},
	radiant = {
		background = Color3.fromRGB(232, 255, 250),
		accent = Color3.fromRGB(114, 237, 215),
		highlight = Color3.fromRGB(195, 255, 245),
		text = Color3.fromRGB(20, 84, 75),
	},
	void_touched = {
		background = Color3.fromRGB(236, 241, 255),
		accent = Color3.fromRGB(109, 171, 255),
		highlight = Color3.fromRGB(207, 225, 255),
		text = Color3.fromRGB(39, 53, 92),
	},
}

local AUDIO_LIBRARY = {
	pop = "rbxasset://sounds/action_jump.mp3",
	tick = "rbxasset://sounds/action_footsteps_plastic.mp3",
	land = "rbxasset://sounds/action_jump_land.mp3",
}

local function makeRarityIndexMap(order)
	local map = {}
	for index, name in ipairs(order) do
		map[name] = index
	end
	return map
end

local RARITY_INDEX_BY_NAME = makeRarityIndexMap(GEODE_RARITY_ORDER)

local function getRarityTone(index: number?, fallbackAccent: Color3?)
	local tone = if index ~= nil then RARITY_TONES[index] else nil
	if tone ~= nil then
		return tone
	end

	local accent = if fallbackAccent ~= nil then fallbackAccent else Color3.fromRGB(109, 230, 255)
	return {
		background = accent:Lerp(Color3.fromRGB(255, 255, 255), 0.72),
		accent = accent,
		highlight = accent:Lerp(Color3.fromRGB(255, 255, 255), 0.45),
		text = Color3.fromRGB(56, 40, 18),
	}
end

local function getRarityToneByName(rarityName: string?, fallbackAccent: Color3?)
	if rarityName == nil then
		return getRarityTone(1, fallbackAccent)
	end

	return getRarityTone(RARITY_INDEX_BY_NAME[rarityName], fallbackAccent)
end

local function getGeodeRarityIndex(geodeTypeId: string?)
	if geodeTypeId == nil then
		return 1
	end

	local rarityName = GEODE_RARITY_BY_ID[geodeTypeId]
	return if rarityName ~= nil then RARITY_INDEX_BY_NAME[rarityName] or 1 else 1
end

local function getResourceRarityIndex(resourceTypeId: string?)
	if resourceTypeId == nil then
		return 1
	end

	local definition = Resources[resourceTypeId]
	if definition == nil then
		return 1
	end

	local rarityName = definition.rarity
	return if type(rarityName) == "string" then RARITY_INDEX_BY_NAME[rarityName] or 1 else 1
end

local function getTraitRarityIndex(traitId: string?)
	if traitId == nil then
		return 0
	end

	local traitDefinition = Traits[traitId]
	return RewardPresentation.getTraitCelebrationTier(traitDefinition)
end

local function getTraitTone(traitId: string?)
	if traitId == nil then
		return nil
	end

	local staticTone = TRAIT_TONES[traitId]
	if staticTone ~= nil then
		return staticTone
	end

	local traitDefinition = Traits[traitId]
	if traitDefinition == nil then
		return nil
	end

	local accent = traitDefinition.accentColor or Color3.fromRGB(109, 230, 255)
	local highlight = traitDefinition.glowColor or accent:Lerp(Color3.fromRGB(255, 255, 255), 0.45)
	return {
		background = highlight:Lerp(Color3.fromRGB(255, 255, 255), 0.68),
		accent = accent,
		highlight = highlight,
		text = Color3.fromRGB(54, 45, 32),
	}
end

local function getTraitIdFromReelWord(word: string?)
	if word == nil then
		return nil
	end

	local normalizedWord = string.lower(word)
	for traitId, traitDefinition in pairs(Traits) do
		if type(traitId) == "string" and type(traitDefinition) == "table" then
			local displayName = string.lower(tostring(traitDefinition.displayName or traitId))
			if normalizedWord == displayName or normalizedWord == string.lower(traitId) then
				return traitId
			end
		end
	end

	return nil
end

local function getTraitReelWords()
	local words = {}
	for _, traitDefinition in ipairs(Traits.order or {}) do
		if traitDefinition ~= nil and traitDefinition.id ~= "none" then
			table.insert(words, string.upper(tostring(traitDefinition.displayName or traitDefinition.id)))
		end
	end

	if #words == 0 then
		return {
			"BONUS",
		}
	end

	return words
end

local function sanitizePromptText(value: any): string?
	if type(value) ~= "string" then
		return nil
	end

	local trimmed = string.match(value, "^%s*(.-)%s*$")
	if trimmed == nil or trimmed == "" then
		return nil
	end

	return trimmed
end

local function getSpinTone(spec, reelWord: string, fallbackTone)
	if spec.kind == "attribute" then
		local traitTone = getTraitTone(getTraitIdFromReelWord(reelWord))
		if traitTone ~= nil then
			return traitTone
		end
	end

	return getRarityToneByName(reelWord, spec.accentColor) or fallbackTone
end

local function playLocalUiSound(soundId: string, volume: number, playbackSpeed: number)
	local sound = Instance.new("Sound")
	sound.Name = "HudUiSound"
	sound.SoundId = soundId
	sound.Volume = volume
	sound.PlaybackSpeed = playbackSpeed
	sound.RollOffMaxDistance = 0
	sound.Parent = SoundService
	SoundService:PlayLocalSound(sound)
	Debris:AddItem(sound, 3)
end

local function playGuideButtonSound(opened: boolean)
	local playbackSpeed = if opened then 1.06 else 0.94
	playLocalUiSound(AUDIO_LIBRARY.pop, 0.22, playbackSpeed)
end

local function playCelebrationSound(spec)
	if spec.kind == "geode_discovery" then
		local rarityIndex = math.clamp(spec.rarityIndex or 1, 1, 10)
		playLocalUiSound(AUDIO_LIBRARY.pop, math.clamp(0.14 + (rarityIndex * 0.028), 0.14, 0.4), 0.96 + (rarityIndex * 0.03))
		if rarityIndex >= 4 then
			task.delay(0.07, function()
				playLocalUiSound(AUDIO_LIBRARY.land, math.clamp(0.1 + (rarityIndex * 0.02), 0.1, 0.28), 0.92 + (rarityIndex * 0.025))
			end)
		end
	elseif spec.kind == "resource" or spec.kind == "attribute" then
		local rarityIndex = math.clamp(spec.rarityIndex or 1, 1, 6)
		playLocalUiSound(AUDIO_LIBRARY.land, math.clamp(0.12 + (rarityIndex * 0.025), 0.12, 0.28), 1 + (rarityIndex * 0.04))
	end
end

local function createGuideRow(parent: Instance, rowData)
	local row = Instance.new("Frame")
	row.Name = rowData.rarity .. "Row"
	row.BackgroundColor3 = rowData.backgroundColor
	row.BorderSizePixel = 0
	row.LayoutOrder = rowData.layoutOrder
	row.Size = UDim2.new(1, 0, 0, 66)
	row.ZIndex = GUIDE_BASE_Z_INDEX + 2
	row.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = row

	local stroke = Instance.new("UIStroke")
	stroke.Color = rowData.highlightColor
	stroke.Thickness = 3
	stroke.Parent = row

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = row

	local chip = Instance.new("TextLabel")
	chip.BackgroundColor3 = rowData.accentColor
	chip.BorderSizePixel = 0
	chip.Size = UDim2.new(0, 118, 0, 44)
	chip.Font = Enum.Font.FredokaOne
	chip.Text = string.upper(rowData.rarity)
	chip.TextColor3 = Color3.fromRGB(78, 48, 18)
	chip.TextSize = 18
	chip.ZIndex = GUIDE_BASE_Z_INDEX + 3
	chip.Parent = row

	local chipCorner = Instance.new("UICorner")
	chipCorner.CornerRadius = UDim.new(0, 14)
	chipCorner.Parent = chip

	local chipStroke = Instance.new("UIStroke")
	chipStroke.Color = rowData.accentColor:Lerp(Color3.fromRGB(255, 255, 255), 0.4)
	chipStroke.Thickness = 3
	chipStroke.Parent = chip

	local percentLabel = Instance.new("TextLabel")
	percentLabel.BackgroundTransparency = 1
	percentLabel.AnchorPoint = Vector2.new(1, 0)
	percentLabel.Position = UDim2.new(1, 0, 0, 0)
	percentLabel.Size = UDim2.new(0, 92, 0, 24)
	percentLabel.Font = Enum.Font.FredokaOne
	percentLabel.Text = rowData.percentageText
	percentLabel.TextColor3 = Color3.fromRGB(82, 52, 18)
	percentLabel.TextSize = 24
	percentLabel.TextXAlignment = Enum.TextXAlignment.Right
	percentLabel.ZIndex = GUIDE_BASE_Z_INDEX + 3
	percentLabel.Parent = row

	local countLabel = Instance.new("TextLabel")
	countLabel.BackgroundTransparency = 1
	countLabel.AnchorPoint = Vector2.new(1, 1)
	countLabel.Position = UDim2.new(1, 0, 1, 0)
	countLabel.Size = UDim2.new(0, 150, 0, 18)
	countLabel.Font = Enum.Font.GothamBold
	countLabel.Text = rowData.countText
	countLabel.TextColor3 = Color3.fromRGB(120, 92, 56)
	countLabel.TextSize = 12
	countLabel.TextXAlignment = Enum.TextXAlignment.Right
	countLabel.ZIndex = GUIDE_BASE_Z_INDEX + 3
	countLabel.Parent = row

	local barFrame = Instance.new("Frame")
	barFrame.BackgroundColor3 = Color3.fromRGB(255, 247, 223)
	barFrame.BorderSizePixel = 0
	barFrame.Position = UDim2.new(0, 128, 0, 10)
	barFrame.Size = UDim2.new(1, -228, 0, 22)
	barFrame.ZIndex = GUIDE_BASE_Z_INDEX + 2
	barFrame.Parent = row

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = barFrame

	local barFill = Instance.new("Frame")
	barFill.BackgroundColor3 = rowData.accentColor
	barFill.BorderSizePixel = 0
	barFill.Size = UDim2.new(math.clamp(rowData.barFillShare or rowData.share, 0.04, 1), 0, 1, 0)
	barFill.ZIndex = GUIDE_BASE_Z_INDEX + 3
	barFill.Parent = barFrame

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = barFill
end

local function rebuildGuideRows(guideRows: ScrollingFrame, rowDataList: { any }, hintText: string)
	for _, child in ipairs(guideRows:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end

	local guideHint = Instance.new("TextLabel")
	guideHint.BackgroundColor3 = Color3.fromRGB(255, 239, 186)
	guideHint.BorderSizePixel = 0
	guideHint.LayoutOrder = 0
	guideHint.Size = UDim2.new(1, 0, 0, 56)
	guideHint.Font = Enum.Font.GothamBold
	guideHint.Text = hintText
	guideHint.TextColor3 = Color3.fromRGB(94, 71, 28)
	guideHint.TextSize = 13
	guideHint.TextWrapped = true
	guideHint.ZIndex = GUIDE_BASE_Z_INDEX + 3
	guideHint.Parent = guideRows

	local guideHintCorner = Instance.new("UICorner")
	guideHintCorner.CornerRadius = UDim.new(0, 16)
	guideHintCorner.Parent = guideHint

	local guideHintStroke = Instance.new("UIStroke")
	guideHintStroke.Color = Color3.fromRGB(255, 251, 217)
	guideHintStroke.Thickness = 3
	guideHintStroke.Parent = guideHint

	for _, rowData in ipairs(rowDataList) do
		createGuideRow(guideRows, rowData)
	end
end

local function createGuideTabButton(parent: Instance, text: string, layoutOrder: number)
	local button = Instance.new("TextButton")
	button.AutoButtonColor = true
	button.BackgroundColor3 = Color3.fromRGB(255, 234, 172)
	button.BorderSizePixel = 0
	button.LayoutOrder = layoutOrder
	button.Size = UDim2.new(0, 156, 1, 0)
	button.Font = Enum.Font.FredokaOne
	button.Text = text
	button.TextColor3 = Color3.fromRGB(101, 72, 26)
	button.TextSize = 20
	button.ZIndex = GUIDE_BASE_Z_INDEX + 3
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 248, 216)
	stroke.Thickness = 3
	stroke.Parent = button

	return button
end

local function setGuideTabButtonState(button: TextButton, isActive: boolean)
	button.BackgroundColor3 = if isActive then Color3.fromRGB(131, 230, 214) else Color3.fromRGB(255, 234, 172)
	button.TextColor3 = if isActive then Color3.fromRGB(38, 76, 72) else Color3.fromRGB(101, 72, 26)
	local stroke = button:FindFirstChildWhichIsA("UIStroke")
	if stroke ~= nil then
		stroke.Color = if isActive then Color3.fromRGB(218, 255, 246) else Color3.fromRGB(255, 248, 216)
		stroke.Thickness = if isActive then 4 else 3
	end
end

local function createCollectionBubbleVisual(parent: Instance, slotData)
	local visual = Instance.new("Frame")
	visual.Name = "Visual"
	visual.BackgroundColor3 = if slotData.isFound then Color3.fromRGB(255, 248, 232) else Color3.fromRGB(32, 32, 38)
	visual.BorderSizePixel = 0
	visual.Position = UDim2.new(0.5, 0, 0, 8)
	visual.AnchorPoint = Vector2.new(0.5, 0)
	visual.Size = UDim2.new(0, 72, 0, 62)
	visual.ZIndex = GUIDE_BASE_Z_INDEX + 4
	visual.Parent = parent

	local visualCorner = Instance.new("UICorner")
	visualCorner.CornerRadius = UDim.new(0, 18)
	visualCorner.Parent = visual

	local visualStroke = Instance.new("UIStroke")
	visualStroke.Color = if slotData.isFound then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(76, 76, 82)
	visualStroke.Thickness = 2
	visualStroke.Parent = visual

	local baseDefinitions = ResourceVisuals.getOreCrystalDefinitions(slotData.variantId)
	local pieceColor = if slotData.isFound then (slotData.color or Color3.fromRGB(220, 230, 240)) else Color3.fromRGB(0, 0, 0)

	for index, definition in ipairs(baseDefinitions) do
		if index > 5 then
			break
		end

		local shard = Instance.new("Frame")
		shard.Name = "Shard" .. tostring(index)
		shard.AnchorPoint = Vector2.new(0.5, 1)
		shard.BackgroundColor3 = pieceColor:Lerp(Color3.fromRGB(255, 255, 255), if slotData.isFound then math.clamp((definition.tint or 0) * 0.5, 0, 0.24) else 0)
		shard.BackgroundTransparency = if slotData.isFound then 0 else 0.08
		shard.BorderSizePixel = 0
		shard.Position = UDim2.new(
			0.5 + math.clamp((definition.x or 0) * 0.18, -0.22, 0.22),
			0,
			0.9,
			0
		)
		shard.Rotation = (definition.yaw or 0) + ((definition.roll or 0) * 0.2)
		shard.Size = UDim2.new(
			0,
			math.max(10, math.floor((definition.width or 0.4) * 18)),
			0,
			math.max(14, math.floor((definition.height or 1) * 16))
		)
		shard.ZIndex = GUIDE_BASE_Z_INDEX + 5
		shard.Parent = visual

		local shardCorner = Instance.new("UICorner")
		shardCorner.CornerRadius = UDim.new(0, if slotData.variantId == "ingot" then 5 else 8)
		shardCorner.Parent = shard

		local shardStroke = Instance.new("UIStroke")
		shardStroke.Color = if slotData.isFound then pieceColor:Lerp(Color3.fromRGB(255, 255, 255), 0.35) else Color3.fromRGB(20, 20, 20)
		shardStroke.Thickness = 1.5
		shardStroke.Parent = shard
	end
end

local function updateCollectionHoverCard(guideState, slotData)
	if slotData == nil then
		guideState.hoverTitle.Text = "Hover a bubble"
		guideState.hoverRarity.Text = "Move your mouse over a slot to peek into your collection."
		guideState.hoverAttributes.Text = "Attributes: waiting for a closer look."
		return
	end

	guideState.hoverTitle.Text = slotData.hoverTitle
	guideState.hoverRarity.Text = if slotData.isFound
		then string.format("%s rarity", slotData.rarity)
		else "Unknown treasure"
	guideState.hoverAttributes.Text = "Attributes: " .. tostring(slotData.hoverAttributesText)
end

local function createCollectionSlot(parent: Instance, slotData, guideState)
	local slotButton = Instance.new("TextButton")
	slotButton.Name = slotData.resourceId .. "Slot"
	slotButton.AutoButtonColor = true
	slotButton.BackgroundColor3 = if slotData.isFound
		then Color3.fromRGB(255, 239, 188)
		else Color3.fromRGB(71, 71, 78)
	slotButton.BorderSizePixel = 0
	slotButton.LayoutOrder = slotData.layoutOrder
	slotButton.Size = UDim2.new(0, 124, 0, 120)
	slotButton.Text = ""
	slotButton.ZIndex = GUIDE_BASE_Z_INDEX + 3
	slotButton.Parent = parent

	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0, 22)
	slotCorner.Parent = slotButton

	local slotStroke = Instance.new("UIStroke")
	slotStroke.Color = if slotData.isFound
		then (slotData.color or Color3.fromRGB(255, 255, 255)):Lerp(Color3.fromRGB(255, 255, 255), 0.35)
		else Color3.fromRGB(120, 120, 126)
	slotStroke.Thickness = 3
	slotStroke.Parent = slotButton

	createCollectionBubbleVisual(slotButton, slotData)

	local rarityChip = Instance.new("TextLabel")
	rarityChip.BackgroundColor3 = if slotData.isFound
		then (slotData.color or Color3.fromRGB(255, 226, 122)):Lerp(Color3.fromRGB(255, 255, 255), 0.24)
		else Color3.fromRGB(29, 29, 34)
	rarityChip.BorderSizePixel = 0
	rarityChip.Position = UDim2.new(0.5, 0, 0, 64)
	rarityChip.AnchorPoint = Vector2.new(0.5, 0)
	rarityChip.Size = UDim2.new(0, 88, 0, 20)
	rarityChip.Font = Enum.Font.FredokaOne
	rarityChip.Text = string.upper(slotData.rarity)
	rarityChip.TextColor3 = if slotData.isFound then Color3.fromRGB(88, 58, 24) else Color3.fromRGB(184, 184, 194)
	rarityChip.TextSize = 10
	rarityChip.ZIndex = GUIDE_BASE_Z_INDEX + 4
	rarityChip.Parent = slotButton

	local rarityCorner = Instance.new("UICorner")
	rarityCorner.CornerRadius = UDim.new(0, 10)
	rarityCorner.Parent = rarityChip

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0, 8, 0, 86)
	title.Size = UDim2.new(1, -16, 0, 28)
	title.Font = Enum.Font.GothamBold
	title.Text = if slotData.isFound then slotData.realDisplayName else "???"
	title.TextColor3 = if slotData.isFound then Color3.fromRGB(76, 52, 24) else Color3.fromRGB(223, 223, 230)
	title.TextSize = 12
	title.TextWrapped = true
	title.ZIndex = GUIDE_BASE_Z_INDEX + 4
	title.Parent = slotButton

	local function showSlotDetails()
		updateCollectionHoverCard(guideState, slotData)
	end

	slotButton.MouseEnter:Connect(showSlotDetails)
	slotButton.Activated:Connect(showSlotDetails)

	return slotButton
end

local function rebuildCollectionGrid(collectionGrid: ScrollingFrame, slotDataList: { any }, guideState)
	for _, child in ipairs(collectionGrid:GetChildren()) do
		if not child:IsA("UIGridLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end

	for _, slotData in ipairs(slotDataList) do
		createCollectionSlot(collectionGrid, slotData, guideState)
	end

	updateCollectionHoverCard(guideState, nil)
end

local function applyGuiZIndex(root, zIndex)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("GuiObject") then
			descendant.ZIndex = zIndex
		end
	end
end

local function clearContainer(container)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("UIListLayout") or child:IsA("UIPadding") or child:IsA("UIGridLayout") or child:IsA("UICorner") or child:IsA("UIStroke") then
			continue
		end
		child:Destroy()
	end
end

function RootScreen.new(context)
	local palette = context.palette
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GemFactoryHud"
	screenGui.IgnoreGuiInset = false
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 50
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	screenGui.Parent = playerGui

	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.AnchorPoint = Vector2.new(1, 0)
	backdrop.BackgroundColor3 = palette.background.page
	backdrop.BorderSizePixel = 0
	backdrop.Position = UDim2.new(1, -20, 0, 20)
	backdrop.Size = UDim2.new(0, 420, 1, -40)
	backdrop.Visible = false
	backdrop.Parent = screenGui

	local backdropCorner = Instance.new("UICorner")
	backdropCorner.CornerRadius = UDim.new(0, 8)
	backdropCorner.Parent = backdrop

	local backdropStroke = Instance.new("UIStroke")
	backdropStroke.Color = palette.border
	backdropStroke.Thickness = 1
	backdropStroke.Transparency = 0.15
	backdropStroke.Parent = backdrop

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.BackgroundColor3 = palette.background.panelAlt
	header.BorderSizePixel = 0
	header.Size = UDim2.new(1, 0, 0, 72)
	header.Parent = backdrop

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 8)
	headerCorner.Parent = header

	local headerStroke = Instance.new("UIStroke")
	headerStroke.Color = palette.border
	headerStroke.Thickness = 1
	headerStroke.Transparency = 0.2
	headerStroke.Parent = header

	local headerPadding = Instance.new("UIPadding")
	headerPadding.PaddingTop = UDim.new(0, 14)
	headerPadding.PaddingBottom = UDim.new(0, 14)
	headerPadding.PaddingLeft = UDim.new(0, 18)
	headerPadding.PaddingRight = UDim.new(0, 18)
	headerPadding.Parent = header

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -200, 0, 24)
	title.Font = Enum.Font.GothamBold
	title.Text = "Gem Factory"
	title.TextColor3 = palette.text
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	local status = Instance.new("TextLabel")
	status.BackgroundTransparency = 1
	status.Position = UDim2.new(0, 0, 0, 28)
	status.Size = UDim2.new(1, -200, 0, 18)
	status.Font = Enum.Font.Gotham
	status.Text = "Loading crystal cavern..."
	status.TextColor3 = palette.muted
	status.TextSize = 14
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Parent = header

	local collapseButton = Instance.new("TextButton")
	collapseButton.Name = "CollapseButton"
	collapseButton.AnchorPoint = Vector2.new(1, 0.5)
	collapseButton.AutoButtonColor = true
	collapseButton.BackgroundColor3 = palette.accent
	collapseButton.BorderSizePixel = 0
	collapseButton.Position = UDim2.new(1, -4, 0.5, 0)
	collapseButton.Size = UDim2.new(0, 44, 0, 32)
	collapseButton.Font = Enum.Font.GothamBold
	collapseButton.Text = "X"
	collapseButton.TextColor3 = palette.shadow
	collapseButton.TextSize = 18
	collapseButton.Parent = header

	local collapseCorner = Instance.new("UICorner")
	collapseCorner.CornerRadius = UDim.new(0, 8)
	collapseCorner.Parent = collapseButton

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Position = UDim2.new(0, 18, 0, 90)
	scroll.Size = UDim2.new(1, -36, 1, -108)
	scroll.ScrollBarThickness = 6
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.Parent = backdrop

	local scrollPadding = Instance.new("UIPadding")
	scrollPadding.PaddingBottom = UDim.new(0, 14)
	scrollPadding.Parent = scroll

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 14)
	layout.Parent = scroll

	local overview = Panel.createCard(scroll, "Crystal Cavern Overview", palette, 1)
	local overviewLabel = Panel.createLabel(overview.body, "Loading crystal cavern statistics...", palette, 1)

	local shop = Panel.createCard(scroll, "Merchant Stall", palette, 2)
	local shopLabel = Panel.createLabel(shop.body, "Loading pickaxe stock...", palette, 1)
	local shopHint = Panel.createLabel(shop.body, "Visit the forge at the far edge to browse pickaxes.", palette, 2)
	shop.frame.Visible = false

	local geode = Panel.createCard(scroll, "Geode Inventory", palette, 3)
	geode.frame.Visible = false
	local geodeLabel = Panel.createLabel(geode.body, "Waiting for geode data...", palette, 1)
	local placeGeode = Panel.createButton(geode.body, "Place Next Geode", palette, 2)
	local openReadyGeodes = Panel.createButton(geode.body, "Open Ready Geode", palette, 3)
	placeGeode.Visible = false

	local daily = Panel.createCard(scroll, "Daily Rewards", palette, 4)
	local dailyLabel = Panel.createLabel(daily.body, "Waiting for daily reward data...", palette, 1)
	local claimDaily = Panel.createButton(daily.body, "Claim Daily Reward", palette, 2)

	local offline = Panel.createCard(scroll, "Offline Cache", palette, 5)
	local offlineLabel = Panel.createLabel(offline.body, "No offline rewards ready yet.", palette, 1)
	local claimOffline = Panel.createButton(offline.body, "Claim Offline Cache", palette, 2)

	local plot = Panel.createCard(scroll, "Cavern Plot", palette, 6)
	local plotLabel = Panel.createLabel(plot.body, "Waiting for plot assignment...", palette, 1)

	local placement = Panel.createCard(scroll, "Placement Grid", palette, 7)
	local placementLabel = Panel.createLabel(placement.body, "Preparing starter station placement...", palette, 1)
	local placeStarterStation = Panel.createButton(placement.body, "Place Starter Station", palette, 2)

	local notifications = Panel.createCard(scroll, "Cavern Announcements", palette, 8)
	local notificationsLabel = Panel.createLabel(notifications.body, "No announcements yet.", palette, 1)

	local reopenButton = Instance.new("TextButton")
	reopenButton.Name = "OpenHudButton"
	reopenButton.Visible = false
	reopenButton.Parent = screenGui

	local hudDock = Instance.new("Frame")
	hudDock.Name = "BubblyHudDock"
	hudDock.AnchorPoint = Vector2.new(0, 1)
	hudDock.BackgroundTransparency = 1
	hudDock.BorderSizePixel = 0
	hudDock.Position = UDim2.new(0, 20, 1, -20)
	hudDock.Size = UDim2.new(0, 260, 0, 132)
	hudDock.Parent = screenGui

	local dockLayout = Instance.new("UIListLayout")
	dockLayout.SortOrder = Enum.SortOrder.LayoutOrder
	dockLayout.Padding = UDim.new(0, 10)
	dockLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	dockLayout.Parent = hudDock

	local vaultButton = Instance.new("TextButton")
	vaultButton.Name = "VaultButton"
	vaultButton.AutoButtonColor = true
	vaultButton.BackgroundColor3 = Color3.fromRGB(255, 210, 82)
	vaultButton.BorderSizePixel = 0
	vaultButton.LayoutOrder = 1
	vaultButton.Size = UDim2.new(0, 210, 0, 54)
	vaultButton.Font = Enum.Font.FredokaOne
	vaultButton.Text = "Vault"
	vaultButton.TextColor3 = Color3.fromRGB(80, 45, 10)
	vaultButton.TextSize = 32
	vaultButton.Parent = hudDock

	local vaultButtonCorner = Instance.new("UICorner")
	vaultButtonCorner.CornerRadius = UDim.new(0, 16)
	vaultButtonCorner.Parent = vaultButton

	local vaultButtonStroke = Instance.new("UIStroke")
	vaultButtonStroke.Color = Color3.fromRGB(255, 246, 174)
	vaultButtonStroke.Thickness = 4
	vaultButtonStroke.Parent = vaultButton

	local coinCounter = Instance.new("Frame")
	coinCounter.Name = "CoinCounter"
	coinCounter.BackgroundColor3 = Color3.fromRGB(255, 238, 123)
	coinCounter.BorderSizePixel = 0
	coinCounter.LayoutOrder = 2
	coinCounter.Size = UDim2.new(0, 250, 0, 68)
	coinCounter.Parent = hudDock

	local coinCorner = Instance.new("UICorner")
	coinCorner.CornerRadius = UDim.new(0, 18)
	coinCorner.Parent = coinCounter

	local coinStroke = Instance.new("UIStroke")
	coinStroke.Color = Color3.fromRGB(255, 255, 230)
	coinStroke.Thickness = 5
	coinStroke.Parent = coinCounter

	local coinIcon = Instance.new("TextLabel")
	coinIcon.BackgroundTransparency = 1
	coinIcon.Position = UDim2.new(0, 12, 0, 8)
	coinIcon.Size = UDim2.new(0, 52, 0, 52)
	coinIcon.Font = Enum.Font.FredokaOne
	coinIcon.Text = "$"
	coinIcon.TextColor3 = Color3.fromRGB(246, 143, 42)
	coinIcon.TextSize = 44
	coinIcon.Parent = coinCounter

	local coinLabel = Instance.new("TextLabel")
	coinLabel.Name = "CoinLabel"
	coinLabel.BackgroundTransparency = 1
	coinLabel.Position = UDim2.new(0, 66, 0, 4)
	coinLabel.Size = UDim2.new(1, -78, 1, -8)
	coinLabel.Font = Enum.Font.FredokaOne
	coinLabel.Text = "0"
	coinLabel.TextColor3 = Color3.fromRGB(76, 49, 16)
	coinLabel.TextScaled = true
	coinLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinLabel.Parent = coinCounter

	local guideDock = Instance.new("Frame")
	guideDock.Name = "GuideDock"
	guideDock.AnchorPoint = Vector2.new(1, 1)
	guideDock.BackgroundTransparency = 1
	guideDock.BorderSizePixel = 0
	guideDock.Position = UDim2.new(1, -20, 1, -20)
	guideDock.Size = UDim2.new(0, 236, 0, 64)
	guideDock.Parent = screenGui

	local guideButton = Instance.new("TextButton")
	guideButton.Name = "GuideButton"
	guideButton.AutoButtonColor = true
	guideButton.BackgroundColor3 = Color3.fromRGB(131, 230, 214)
	guideButton.BorderSizePixel = 0
	guideButton.Size = UDim2.new(1, 0, 1, 0)
	guideButton.Font = Enum.Font.FredokaOne
	guideButton.Text = "Resource Guide"
	guideButton.TextColor3 = Color3.fromRGB(38, 76, 72)
	guideButton.TextSize = 28
	guideButton.Parent = guideDock

	local guideButtonCorner = Instance.new("UICorner")
	guideButtonCorner.CornerRadius = UDim.new(0, 18)
	guideButtonCorner.Parent = guideButton

	local guideButtonStroke = Instance.new("UIStroke")
	guideButtonStroke.Color = Color3.fromRGB(218, 255, 246)
	guideButtonStroke.Thickness = 5
	guideButtonStroke.Parent = guideButton

	local guideOverlay = Instance.new("Frame")
	guideOverlay.Name = "GuideOverlay"
	guideOverlay.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
	guideOverlay.BackgroundTransparency = 0.35
	guideOverlay.BorderSizePixel = 0
	guideOverlay.Size = UDim2.fromScale(1, 1)
	guideOverlay.Visible = false
	guideOverlay.ZIndex = GUIDE_BASE_Z_INDEX
	guideOverlay.Parent = screenGui

	local guidePanel = Instance.new("Frame")
	guidePanel.Name = "GuidePanel"
	guidePanel.AnchorPoint = Vector2.new(0.5, 0.5)
	guidePanel.BackgroundColor3 = Color3.fromRGB(255, 248, 225)
	guidePanel.BorderSizePixel = 0
	guidePanel.Position = UDim2.fromScale(0.5, 0.5)
	guidePanel.Size = UDim2.new(0.94, 0, 0.84, 0)
	guidePanel.ZIndex = GUIDE_BASE_Z_INDEX + 1
	guidePanel.Parent = guideOverlay

	local guidePanelCorner = Instance.new("UICorner")
	guidePanelCorner.CornerRadius = UDim.new(0, 22)
	guidePanelCorner.Parent = guidePanel

	local guidePanelStroke = Instance.new("UIStroke")
	guidePanelStroke.Color = Color3.fromRGB(131, 230, 214)
	guidePanelStroke.Thickness = 5
	guidePanelStroke.Parent = guidePanel

	local guideConstraint = Instance.new("UISizeConstraint")
	guideConstraint.MinSize = Vector2.new(420, 420)
	guideConstraint.MaxSize = Vector2.new(920, 760)
	guideConstraint.Parent = guidePanel

	local guidePadding = Instance.new("UIPadding")
	guidePadding.PaddingTop = UDim.new(0, 18)
	guidePadding.PaddingBottom = UDim.new(0, 18)
	guidePadding.PaddingLeft = UDim.new(0, 18)
	guidePadding.PaddingRight = UDim.new(0, 18)
	guidePadding.Parent = guidePanel

	local guideHeader = Instance.new("Frame")
	guideHeader.Name = "GuideHeader"
	guideHeader.BackgroundTransparency = 1
	guideHeader.Size = UDim2.new(1, 0, 0, 118)
	guideHeader.ZIndex = GUIDE_BASE_Z_INDEX + 2
	guideHeader.Parent = guidePanel

	local guideTitle = Instance.new("TextLabel")
	guideTitle.BackgroundTransparency = 1
	guideTitle.Size = UDim2.new(1, -52, 0, 34)
	guideTitle.Font = Enum.Font.FredokaOne
	guideTitle.Text = "Resource Guide"
	guideTitle.TextColor3 = Color3.fromRGB(64, 48, 22)
	guideTitle.TextSize = 34
	guideTitle.TextXAlignment = Enum.TextXAlignment.Left
	guideTitle.ZIndex = GUIDE_BASE_Z_INDEX + 2
	guideTitle.Parent = guideHeader

	local guideSubtitle = Instance.new("TextLabel")
	guideSubtitle.BackgroundTransparency = 1
	guideSubtitle.Position = UDim2.new(0, 0, 0, 36)
	guideSubtitle.Size = UDim2.new(1, -56, 0, 30)
	guideSubtitle.Font = Enum.Font.GothamBold
	guideSubtitle.Text = "Current resource catalog share by rarity tier."
	guideSubtitle.TextColor3 = Color3.fromRGB(107, 94, 72)
	guideSubtitle.TextSize = 14
	guideSubtitle.TextWrapped = true
	guideSubtitle.TextXAlignment = Enum.TextXAlignment.Left
	guideSubtitle.TextYAlignment = Enum.TextYAlignment.Top
	guideSubtitle.ZIndex = GUIDE_BASE_Z_INDEX + 2
	guideSubtitle.Parent = guideHeader

	local guideTabs = Instance.new("Frame")
	guideTabs.Name = "GuideTabs"
	guideTabs.BackgroundTransparency = 1
	guideTabs.Position = UDim2.new(0, 0, 0, 74)
	guideTabs.Size = UDim2.new(1, -56, 0, 36)
	guideTabs.ZIndex = GUIDE_BASE_Z_INDEX + 2
	guideTabs.Parent = guideHeader

	local guideTabsLayout = Instance.new("UIListLayout")
	guideTabsLayout.FillDirection = Enum.FillDirection.Horizontal
	guideTabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	guideTabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	guideTabsLayout.Padding = UDim.new(0, 10)
	guideTabsLayout.Parent = guideTabs

	local chartTabButton = createGuideTabButton(guideTabs, "Rarity Chart", 1)
	local collectionTabButton = createGuideTabButton(guideTabs, "Collection", 2)

	local guideClose = Instance.new("TextButton")
	guideClose.Name = "CloseGuideButton"
	guideClose.AnchorPoint = Vector2.new(1, 0)
	guideClose.BackgroundColor3 = Color3.fromRGB(255, 136, 121)
	guideClose.BorderSizePixel = 0
	guideClose.Position = UDim2.new(1, 0, 0, 2)
	guideClose.Size = UDim2.new(0, 44, 0, 40)
	guideClose.Font = Enum.Font.FredokaOne
	guideClose.Text = "X"
	guideClose.TextColor3 = Color3.fromRGB(92, 32, 24)
	guideClose.TextSize = 24
	guideClose.ZIndex = GUIDE_BASE_Z_INDEX + 3
	guideClose.Parent = guideHeader

	local guideCloseCorner = Instance.new("UICorner")
	guideCloseCorner.CornerRadius = UDim.new(0, 12)
	guideCloseCorner.Parent = guideClose

	local guideRows = Instance.new("ScrollingFrame")
	guideRows.Name = "GuideRows"
	guideRows.BackgroundTransparency = 1
	guideRows.BorderSizePixel = 0
	guideRows.Position = UDim2.new(0, 0, 0, 126)
	guideRows.Size = UDim2.new(1, 0, 1, -126)
	guideRows.ScrollBarThickness = 7
	guideRows.AutomaticCanvasSize = Enum.AutomaticSize.Y
	guideRows.CanvasSize = UDim2.new(0, 0, 0, 0)
	guideRows.ZIndex = GUIDE_BASE_Z_INDEX + 2
	guideRows.Parent = guidePanel

	local guideRowsPadding = Instance.new("UIPadding")
	guideRowsPadding.PaddingBottom = UDim.new(0, 4)
	guideRowsPadding.Parent = guideRows

	local guideRowsLayout = Instance.new("UIListLayout")
	guideRowsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	guideRowsLayout.Padding = UDim.new(0, 10)
	guideRowsLayout.Parent = guideRows

	local guideCollectionFrame = Instance.new("Frame")
	guideCollectionFrame.Name = "GuideCollectionFrame"
	guideCollectionFrame.BackgroundTransparency = 1
	guideCollectionFrame.Position = UDim2.new(0, 0, 0, 126)
	guideCollectionFrame.Size = UDim2.new(1, 0, 1, -126)
	guideCollectionFrame.Visible = false
	guideCollectionFrame.ZIndex = GUIDE_BASE_Z_INDEX + 2
	guideCollectionFrame.Parent = guidePanel

	local guideCollectionGrid = Instance.new("ScrollingFrame")
	guideCollectionGrid.Name = "GuideCollectionGrid"
	guideCollectionGrid.BackgroundTransparency = 1
	guideCollectionGrid.BorderSizePixel = 0
	guideCollectionGrid.Position = UDim2.new(0, 0, 0, 0)
	guideCollectionGrid.Size = UDim2.new(1, -214, 1, 0)
	guideCollectionGrid.ScrollBarThickness = 7
	guideCollectionGrid.AutomaticCanvasSize = Enum.AutomaticSize.Y
	guideCollectionGrid.CanvasSize = UDim2.new(0, 0, 0, 0)
	guideCollectionGrid.ZIndex = GUIDE_BASE_Z_INDEX + 2
	guideCollectionGrid.Parent = guideCollectionFrame

	local guideCollectionPadding = Instance.new("UIPadding")
	guideCollectionPadding.PaddingBottom = UDim.new(0, 4)
	guideCollectionPadding.PaddingRight = UDim.new(0, 10)
	guideCollectionPadding.Parent = guideCollectionGrid

	local guideCollectionLayout = Instance.new("UIGridLayout")
	guideCollectionLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	guideCollectionLayout.CellSize = UDim2.new(0, 124, 0, 120)
	guideCollectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
	guideCollectionLayout.Parent = guideCollectionGrid

	local guideHoverCard = Instance.new("Frame")
	guideHoverCard.Name = "GuideHoverCard"
	guideHoverCard.AnchorPoint = Vector2.new(1, 0)
	guideHoverCard.BackgroundColor3 = Color3.fromRGB(255, 239, 188)
	guideHoverCard.BorderSizePixel = 0
	guideHoverCard.Position = UDim2.new(1, 0, 0, 0)
	guideHoverCard.Size = UDim2.new(0, 196, 0, 194)
	guideHoverCard.ZIndex = GUIDE_BASE_Z_INDEX + 3
	guideHoverCard.Parent = guideCollectionFrame

	local guideHoverCorner = Instance.new("UICorner")
	guideHoverCorner.CornerRadius = UDim.new(0, 18)
	guideHoverCorner.Parent = guideHoverCard

	local guideHoverStroke = Instance.new("UIStroke")
	guideHoverStroke.Color = Color3.fromRGB(255, 252, 235)
	guideHoverStroke.Thickness = 4
	guideHoverStroke.Parent = guideHoverCard

	local guideHoverPadding = Instance.new("UIPadding")
	guideHoverPadding.PaddingTop = UDim.new(0, 14)
	guideHoverPadding.PaddingBottom = UDim.new(0, 14)
	guideHoverPadding.PaddingLeft = UDim.new(0, 14)
	guideHoverPadding.PaddingRight = UDim.new(0, 14)
	guideHoverPadding.Parent = guideHoverCard

	local guideHoverTitle = Instance.new("TextLabel")
	guideHoverTitle.BackgroundTransparency = 1
	guideHoverTitle.Size = UDim2.new(1, 0, 0, 34)
	guideHoverTitle.Font = Enum.Font.FredokaOne
	guideHoverTitle.Text = "Hover a bubble"
	guideHoverTitle.TextColor3 = Color3.fromRGB(76, 52, 24)
	guideHoverTitle.TextSize = 24
	guideHoverTitle.TextWrapped = true
	guideHoverTitle.TextXAlignment = Enum.TextXAlignment.Left
	guideHoverTitle.TextYAlignment = Enum.TextYAlignment.Top
	guideHoverTitle.ZIndex = GUIDE_BASE_Z_INDEX + 4
	guideHoverTitle.Parent = guideHoverCard

	local guideHoverRarity = Instance.new("TextLabel")
	guideHoverRarity.BackgroundTransparency = 1
	guideHoverRarity.Position = UDim2.new(0, 0, 0, 42)
	guideHoverRarity.Size = UDim2.new(1, 0, 0, 42)
	guideHoverRarity.Font = Enum.Font.GothamBold
	guideHoverRarity.Text = "Move your mouse over a slot to peek into your collection."
	guideHoverRarity.TextColor3 = Color3.fromRGB(110, 90, 55)
	guideHoverRarity.TextSize = 14
	guideHoverRarity.TextWrapped = true
	guideHoverRarity.TextXAlignment = Enum.TextXAlignment.Left
	guideHoverRarity.TextYAlignment = Enum.TextYAlignment.Top
	guideHoverRarity.ZIndex = GUIDE_BASE_Z_INDEX + 4
	guideHoverRarity.Parent = guideHoverCard

	local guideHoverAttributes = Instance.new("TextLabel")
	guideHoverAttributes.BackgroundTransparency = 1
	guideHoverAttributes.Position = UDim2.new(0, 0, 0, 100)
	guideHoverAttributes.Size = UDim2.new(1, 0, 1, -100)
	guideHoverAttributes.Font = Enum.Font.GothamBold
	guideHoverAttributes.Text = "Attributes: waiting for a closer look."
	guideHoverAttributes.TextColor3 = Color3.fromRGB(94, 71, 28)
	guideHoverAttributes.TextSize = 15
	guideHoverAttributes.TextWrapped = true
	guideHoverAttributes.TextXAlignment = Enum.TextXAlignment.Left
	guideHoverAttributes.TextYAlignment = Enum.TextYAlignment.Top
	guideHoverAttributes.ZIndex = GUIDE_BASE_Z_INDEX + 4
	guideHoverAttributes.Parent = guideHoverCard

	local initialGuideSummary = ResourceGuide.getGuideSummary(ResourceGuide.getDefaultPickaxeId())
	rebuildGuideRows(guideRows, ResourceGuide.getGuideRows(initialGuideSummary.pickaxeId), initialGuideSummary.hintText)
	rebuildCollectionGrid(guideCollectionGrid, ResourceGuide.getCollectionSlots(nil), {
		hoverTitle = guideHoverTitle,
		hoverRarity = guideHoverRarity,
		hoverAttributes = guideHoverAttributes,
	})
	setGuideTabButtonState(chartTabButton, true)
	setGuideTabButtonState(collectionTabButton, false)

	local vaultOverlay = Instance.new("Frame")
	vaultOverlay.Name = "VaultOverlay"
	vaultOverlay.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
	vaultOverlay.BackgroundTransparency = 0.35
	vaultOverlay.BorderSizePixel = 0
	vaultOverlay.Size = UDim2.fromScale(1, 1)
	vaultOverlay.Visible = false
	vaultOverlay.ZIndex = VAULT_BASE_Z_INDEX
	vaultOverlay.Parent = screenGui

	local vaultPanel = Instance.new("Frame")
	vaultPanel.Name = "VaultPanel"
	vaultPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	vaultPanel.BackgroundColor3 = Color3.fromRGB(255, 249, 224)
	vaultPanel.BorderSizePixel = 0
	vaultPanel.Position = UDim2.fromScale(0.5, 0.5)
	vaultPanel.Size = UDim2.new(0.9, 0, 0.78, 0)
	vaultPanel.ZIndex = VAULT_BASE_Z_INDEX + 1
	vaultPanel.Parent = vaultOverlay

	local vaultPanelCorner = Instance.new("UICorner")
	vaultPanelCorner.CornerRadius = UDim.new(0, 18)
	vaultPanelCorner.Parent = vaultPanel

	local vaultPanelStroke = Instance.new("UIStroke")
	vaultPanelStroke.Color = Color3.fromRGB(255, 207, 72)
	vaultPanelStroke.Thickness = 5
	vaultPanelStroke.Parent = vaultPanel

	local vaultConstraint = Instance.new("UISizeConstraint")
	vaultConstraint.MinSize = Vector2.new(320, 360)
	vaultConstraint.MaxSize = Vector2.new(620, 700)
	vaultConstraint.Parent = vaultPanel

	local vaultPadding = Instance.new("UIPadding")
	vaultPadding.PaddingTop = UDim.new(0, 18)
	vaultPadding.PaddingBottom = UDim.new(0, 18)
	vaultPadding.PaddingLeft = UDim.new(0, 18)
	vaultPadding.PaddingRight = UDim.new(0, 18)
	vaultPadding.Parent = vaultPanel

	local vaultHeader = Instance.new("Frame")
	vaultHeader.Name = "VaultHeader"
	vaultHeader.BackgroundTransparency = 1
	vaultHeader.Size = UDim2.new(1, 0, 0, 58)
	vaultHeader.ZIndex = VAULT_BASE_Z_INDEX + 2
	vaultHeader.Parent = vaultPanel

	local vaultTitle = Instance.new("TextLabel")
	vaultTitle.BackgroundTransparency = 1
	vaultTitle.Size = UDim2.new(1, -52, 1, 0)
	vaultTitle.Font = Enum.Font.FredokaOne
	vaultTitle.Text = "Vault"
	vaultTitle.TextColor3 = Color3.fromRGB(82, 52, 18)
	vaultTitle.TextSize = 36
	vaultTitle.TextXAlignment = Enum.TextXAlignment.Left
	vaultTitle.ZIndex = VAULT_BASE_Z_INDEX + 2
	vaultTitle.Parent = vaultHeader

	local vaultClose = Instance.new("TextButton")
	vaultClose.Name = "CloseVaultButton"
	vaultClose.AnchorPoint = Vector2.new(1, 0)
	vaultClose.BackgroundColor3 = Color3.fromRGB(255, 116, 116)
	vaultClose.BorderSizePixel = 0
	vaultClose.Position = UDim2.new(1, 0, 0, 6)
	vaultClose.Size = UDim2.new(0, 44, 0, 40)
	vaultClose.Font = Enum.Font.FredokaOne
	vaultClose.Text = "X"
	vaultClose.TextColor3 = Color3.fromRGB(82, 24, 24)
	vaultClose.TextSize = 24
	vaultClose.ZIndex = VAULT_BASE_Z_INDEX + 3
	vaultClose.Parent = vaultHeader

	local vaultCloseCorner = Instance.new("UICorner")
	vaultCloseCorner.CornerRadius = UDim.new(0, 12)
	vaultCloseCorner.Parent = vaultClose

	local vaultItems = Instance.new("ScrollingFrame")
	vaultItems.Name = "VaultItems"
	vaultItems.BackgroundTransparency = 1
	vaultItems.BorderSizePixel = 0
	vaultItems.Position = UDim2.new(0, 0, 0, 66)
	vaultItems.Size = UDim2.new(1, 0, 1, -66)
	vaultItems.ScrollBarThickness = 8
	vaultItems.AutomaticCanvasSize = Enum.AutomaticSize.Y
	vaultItems.CanvasSize = UDim2.new(0, 0, 0, 0)
	vaultItems.ZIndex = VAULT_BASE_Z_INDEX + 2
	vaultItems.Parent = vaultPanel

	local vaultItemsPadding = Instance.new("UIPadding")
	vaultItemsPadding.PaddingTop = UDim.new(0, 6)
	vaultItemsPadding.PaddingBottom = UDim.new(0, 6)
	vaultItemsPadding.PaddingLeft = UDim.new(0, 6)
	vaultItemsPadding.PaddingRight = UDim.new(0, 6)
	vaultItemsPadding.Parent = vaultItems

	local vaultItemsLayout = Instance.new("UIListLayout")
	vaultItemsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	vaultItemsLayout.Padding = UDim.new(0, 12)
	vaultItemsLayout.Parent = vaultItems

	local shopOverlay = Instance.new("Frame")
	shopOverlay.Name = "ShopOverlay"
	shopOverlay.BackgroundColor3 = Color3.fromRGB(25, 36, 52)
	shopOverlay.BackgroundTransparency = 0.24
	shopOverlay.BorderSizePixel = 0
	shopOverlay.Size = UDim2.fromScale(1, 1)
	shopOverlay.Visible = false
	shopOverlay.ZIndex = SHOP_BASE_Z_INDEX
	shopOverlay.Parent = screenGui

	local shopOverlayStroke = Instance.new("UIStroke")
	shopOverlayStroke.Color = Color3.fromRGB(0, 0, 0)
	shopOverlayStroke.Transparency = 1
	shopOverlayStroke.Parent = shopOverlay

	local shopPanel = Instance.new("Frame")
	shopPanel.Name = "ShopPanel"
	shopPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	shopPanel.BackgroundColor3 = Color3.fromRGB(255, 247, 223)
	shopPanel.BorderSizePixel = 0
	shopPanel.Position = UDim2.fromScale(0.5, 0.5)
	shopPanel.Size = UDim2.new(0.94, 0, 0.88, 0)
	shopPanel.ZIndex = SHOP_BASE_Z_INDEX + 1
	shopPanel.Parent = shopOverlay

	local shopPanelCorner = Instance.new("UICorner")
	shopPanelCorner.CornerRadius = UDim.new(0, 28)
	shopPanelCorner.Parent = shopPanel

	local shopPanelStroke = Instance.new("UIStroke")
	shopPanelStroke.Color = Color3.fromRGB(177, 235, 225)
	shopPanelStroke.Thickness = 5
	shopPanelStroke.Transparency = 0.02
	shopPanelStroke.Parent = shopPanel

	local shopPanelGradient = Instance.new("UIGradient")
	shopPanelGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 252, 238)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 239, 196)),
	})
	shopPanelGradient.Rotation = 90
	shopPanelGradient.Parent = shopPanel

	local shopPanelConstraint = Instance.new("UISizeConstraint")
	shopPanelConstraint.MinSize = Vector2.new(360, 460)
	shopPanelConstraint.MaxSize = Vector2.new(760, 760)
	shopPanelConstraint.Parent = shopPanel

	local shopPadding = Instance.new("UIPadding")
	shopPadding.PaddingTop = UDim.new(0, 20)
	shopPadding.PaddingBottom = UDim.new(0, 20)
	shopPadding.PaddingLeft = UDim.new(0, 20)
	shopPadding.PaddingRight = UDim.new(0, 20)
	shopPadding.Parent = shopPanel

	local shopLayout = Instance.new("UIListLayout")
	shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
	shopLayout.Padding = UDim.new(0, 14)
	shopLayout.Parent = shopPanel

	local shopHeader = Instance.new("Frame")
	shopHeader.Name = "ShopHeader"
	shopHeader.BackgroundColor3 = Color3.fromRGB(131, 230, 214)
	shopHeader.BorderSizePixel = 0
	shopHeader.LayoutOrder = 1
	shopHeader.Size = UDim2.new(1, 0, 0, 96)
	shopHeader.Parent = shopPanel

	local shopHeaderCorner = Instance.new("UICorner")
	shopHeaderCorner.CornerRadius = UDim.new(0, 24)
	shopHeaderCorner.Parent = shopHeader

	local shopHeaderStroke = Instance.new("UIStroke")
	shopHeaderStroke.Color = Color3.fromRGB(218, 255, 246)
	shopHeaderStroke.Thickness = 4
	shopHeaderStroke.Parent = shopHeader

	local shopHeaderGradient = Instance.new("UIGradient")
	shopHeaderGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(149, 240, 223)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(111, 217, 212)),
	})
	shopHeaderGradient.Rotation = 18
	shopHeaderGradient.Parent = shopHeader

	local shopSparkle = Instance.new("TextLabel")
	shopSparkle.Name = "ShopSparkle"
	shopSparkle.BackgroundTransparency = 1
	shopSparkle.Position = UDim2.new(0, 16, 0, 10)
	shopSparkle.Size = UDim2.new(0, 48, 0, 32)
	shopSparkle.Font = Enum.Font.FredokaOne
	shopSparkle.Text = "*"
	shopSparkle.TextColor3 = Color3.fromRGB(255, 244, 162)
	shopSparkle.TextSize = 30
	shopSparkle.Rotation = -12
	shopSparkle.Parent = shopHeader

	local shopTitle = Instance.new("TextLabel")
	shopTitle.BackgroundTransparency = 1
	shopTitle.Position = UDim2.new(0, 56, 0, 12)
	shopTitle.Size = UDim2.new(1, -88, 0, 30)
	shopTitle.Font = Enum.Font.FredokaOne
	shopTitle.Text = "Pickaxe Shop"
	shopTitle.TextColor3 = Color3.fromRGB(38, 76, 72)
	shopTitle.TextSize = 31
	shopTitle.TextXAlignment = Enum.TextXAlignment.Left
	shopTitle.Parent = shopHeader

	local shopSubtitle = Instance.new("TextLabel")
	shopSubtitle.BackgroundTransparency = 1
	shopSubtitle.Position = UDim2.new(0, 56, 0, 46)
	shopSubtitle.Size = UDim2.new(1, -116, 0, 36)
	shopSubtitle.Font = Enum.Font.GothamBold
	shopSubtitle.Text = "Press E at the forge to open the shop."
	shopSubtitle.TextColor3 = Color3.fromRGB(57, 104, 96)
	shopSubtitle.TextSize = 15
	shopSubtitle.TextXAlignment = Enum.TextXAlignment.Left
	shopSubtitle.TextWrapped = true
	shopSubtitle.Parent = shopHeader

	local shopClose = Instance.new("TextButton")
	shopClose.Name = "CloseShopButton"
	shopClose.AnchorPoint = Vector2.new(1, 0)
	shopClose.AutoButtonColor = true
	shopClose.BackgroundColor3 = Color3.fromRGB(255, 189, 136)
	shopClose.BorderSizePixel = 0
	shopClose.Position = UDim2.new(1, -10, 0, 10)
	shopClose.Size = UDim2.new(0, 46, 0, 40)
	shopClose.Font = Enum.Font.FredokaOne
	shopClose.Text = "X"
	shopClose.TextColor3 = Color3.fromRGB(117, 62, 26)
	shopClose.TextSize = 22
	shopClose.ZIndex = 62
	shopClose.Parent = shopHeader

	local shopCloseCorner = Instance.new("UICorner")
	shopCloseCorner.CornerRadius = UDim.new(0, 16)
	shopCloseCorner.Parent = shopClose

	local shopCloseStroke = Instance.new("UIStroke")
	shopCloseStroke.Color = Color3.fromRGB(255, 236, 213)
	shopCloseStroke.Thickness = 3
	shopCloseStroke.Transparency = 0.02
	shopCloseStroke.Parent = shopClose

	local shopInfo = Instance.new("Frame")
	shopInfo.Name = "ShopInfo"
	shopInfo.BackgroundColor3 = Color3.fromRGB(255, 232, 170)
	shopInfo.BorderSizePixel = 0
	shopInfo.LayoutOrder = 2
	shopInfo.Size = UDim2.new(1, 0, 0, 88)
	shopInfo.Parent = shopPanel

	local shopInfoCorner = Instance.new("UICorner")
	shopInfoCorner.CornerRadius = UDim.new(0, 22)
	shopInfoCorner.Parent = shopInfo

	local shopInfoStroke = Instance.new("UIStroke")
	shopInfoStroke.Color = Color3.fromRGB(255, 248, 216)
	shopInfoStroke.Thickness = 3
	shopInfoStroke.Transparency = 0.02
	shopInfoStroke.Parent = shopInfo

	local shopInfoGradient = Instance.new("UIGradient")
	shopInfoGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 241, 198)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 223, 144)),
	})
	shopInfoGradient.Rotation = 18
	shopInfoGradient.Parent = shopInfo

	local shopInfoPadding = Instance.new("UIPadding")
	shopInfoPadding.PaddingTop = UDim.new(0, 10)
	shopInfoPadding.PaddingBottom = UDim.new(0, 10)
	shopInfoPadding.PaddingLeft = UDim.new(0, 12)
	shopInfoPadding.PaddingRight = UDim.new(0, 12)
	shopInfoPadding.Parent = shopInfo

	local shopInfoLabel = Instance.new("TextLabel")
	shopInfoLabel.BackgroundTransparency = 1
	shopInfoLabel.Size = UDim2.new(1, 0, 1, 0)
	shopInfoLabel.Font = Enum.Font.FredokaOne
	shopInfoLabel.Text = "Loading pickaxe stock..."
	shopInfoLabel.TextColor3 = Color3.fromRGB(103, 66, 23)
	shopInfoLabel.TextSize = 18
	shopInfoLabel.TextWrapped = true
	shopInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
	shopInfoLabel.TextYAlignment = Enum.TextYAlignment.Top
	shopInfoLabel.Parent = shopInfo

	local shopOfferScroll = Instance.new("ScrollingFrame")
	shopOfferScroll.Name = "ShopOffers"
	shopOfferScroll.BackgroundTransparency = 1
	shopOfferScroll.BorderSizePixel = 0
	shopOfferScroll.LayoutOrder = 3
	shopOfferScroll.ScrollBarThickness = 10
	shopOfferScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	shopOfferScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	shopOfferScroll.ElasticBehavior = Enum.ElasticBehavior.Never
	shopOfferScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	shopOfferScroll.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	shopOfferScroll.Size = UDim2.new(1, 0, 1, -232)
	shopOfferScroll.ZIndex = SHOP_BASE_Z_INDEX + 2
	shopOfferScroll.Parent = shopPanel

	local shopOfferPadding = Instance.new("UIPadding")
	shopOfferPadding.PaddingTop = UDim.new(0, 4)
	shopOfferPadding.PaddingBottom = UDim.new(0, 12)
	shopOfferPadding.PaddingLeft = UDim.new(0, 3)
	shopOfferPadding.PaddingRight = UDim.new(0, 12)
	shopOfferPadding.Parent = shopOfferScroll

	local shopCatalogContent = Instance.new("Frame")
	shopCatalogContent.Name = "CatalogContent"
	shopCatalogContent.AutomaticSize = Enum.AutomaticSize.Y
	shopCatalogContent.BackgroundTransparency = 1
	shopCatalogContent.BorderSizePixel = 0
	shopCatalogContent.Size = UDim2.new(1, -2, 0, 0)
	shopCatalogContent.ZIndex = SHOP_BASE_Z_INDEX + 2
	shopCatalogContent.Parent = shopOfferScroll

	local shopCatalogLayout = Instance.new("UIListLayout")
	shopCatalogLayout.SortOrder = Enum.SortOrder.LayoutOrder
	shopCatalogLayout.Padding = UDim.new(0, 12)
	shopCatalogLayout.Parent = shopCatalogContent

	local shopOfferRows = Instance.new("Frame")
	shopOfferRows.Name = "OfferRows"
	shopOfferRows.AutomaticSize = Enum.AutomaticSize.Y
	shopOfferRows.BackgroundTransparency = 1
	shopOfferRows.BorderSizePixel = 0
	shopOfferRows.LayoutOrder = 1
	shopOfferRows.Size = UDim2.new(1, 0, 0, 0)
	shopOfferRows.ZIndex = SHOP_BASE_Z_INDEX + 2
	shopOfferRows.Parent = shopCatalogContent

	local shopOfferLayout = Instance.new("UIListLayout")
	shopOfferLayout.SortOrder = Enum.SortOrder.LayoutOrder
	shopOfferLayout.Padding = UDim.new(0, 12)
	shopOfferLayout.Parent = shopOfferRows

	local rarityFrame = Instance.new("Frame")
	rarityFrame.Name = "RarityLadder"
	rarityFrame.BackgroundColor3 = Color3.fromRGB(255, 243, 207)
	rarityFrame.BorderSizePixel = 0
	rarityFrame.LayoutOrder = 2
	rarityFrame.Size = UDim2.new(1, 0, 0, 164)
	rarityFrame.Parent = shopCatalogContent

	local rarityFrameCorner = Instance.new("UICorner")
	rarityFrameCorner.CornerRadius = UDim.new(0, 22)
	rarityFrameCorner.Parent = rarityFrame

	local rarityFrameStroke = Instance.new("UIStroke")
	rarityFrameStroke.Color = Color3.fromRGB(255, 248, 216)
	rarityFrameStroke.Thickness = 3
	rarityFrameStroke.Parent = rarityFrame

	local rarityFrameGradient = Instance.new("UIGradient")
	rarityFrameGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 248, 224)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 233, 185)),
	})
	rarityFrameGradient.Rotation = 90
	rarityFrameGradient.Parent = rarityFrame

	local rarityTitle = Instance.new("TextLabel")
	rarityTitle.BackgroundTransparency = 1
	rarityTitle.Position = UDim2.new(0, 14, 0, 10)
	rarityTitle.Size = UDim2.new(1, -28, 0, 26)
	rarityTitle.Font = Enum.Font.FredokaOne
	rarityTitle.Text = "Pickaxe Tiers"
	rarityTitle.TextColor3 = Color3.fromRGB(110, 72, 26)
	rarityTitle.TextSize = 20
	rarityTitle.TextXAlignment = Enum.TextXAlignment.Left
	rarityTitle.Parent = rarityFrame

	local rarityHint = Instance.new("TextLabel")
	rarityHint.Name = "RarityHint"
	rarityHint.BackgroundTransparency = 1
	rarityHint.Position = UDim2.new(0, 14, 0, 34)
	rarityHint.Size = UDim2.new(1, -28, 0, 18)
	rarityHint.Font = Enum.Font.GothamBold
	rarityHint.Text = "Higher tiers hit faster and pull rarer geodes."
	rarityHint.TextColor3 = Color3.fromRGB(151, 111, 59)
	rarityHint.TextSize = 12
	rarityHint.TextXAlignment = Enum.TextXAlignment.Left
	rarityHint.Parent = rarityFrame

	local rarityGrid = Instance.new("Frame")
	rarityGrid.Name = "RarityGrid"
	rarityGrid.BackgroundTransparency = 1
	rarityGrid.Position = UDim2.new(0, 12, 0, 58)
	rarityGrid.Size = UDim2.new(1, -24, 1, -70)
	rarityGrid.Parent = rarityFrame

	local rarityLayout = Instance.new("UIGridLayout")
	rarityLayout.CellPadding = UDim2.new(0, 6, 0, 6)
	rarityLayout.CellSize = UDim2.new(0.2, -5, 0.5, -3)
	rarityLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rarityLayout.Parent = rarityGrid

	local rarityLabels = {}
	local rarityNames = {
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

	for index, rarityName in ipairs(rarityNames) do
		local rarityChip = Instance.new("TextLabel")
		rarityChip.Name = string.format("Rarity%d", index)
		rarityChip.BackgroundColor3 = Color3.fromRGB(255, 224, 154)
		rarityChip.BorderSizePixel = 0
		rarityChip.Font = Enum.Font.FredokaOne
		rarityChip.LayoutOrder = index
		rarityChip.Text = rarityName
		rarityChip.TextColor3 = Color3.fromRGB(110, 70, 22)
		rarityChip.TextSize = 12
		rarityChip.TextWrapped = false
		rarityChip.ZIndex = SHOP_BASE_Z_INDEX + 2
		rarityChip.Parent = rarityGrid

		local chipCorner = Instance.new("UICorner")
		chipCorner.CornerRadius = UDim.new(0, 14)
		chipCorner.Parent = rarityChip

		local chipStroke = Instance.new("UIStroke")
		chipStroke.Color = Color3.fromRGB(255, 246, 214)
		chipStroke.Thickness = 2
		chipStroke.Transparency = 0.02
		chipStroke.Parent = rarityChip

		table.insert(rarityLabels, rarityChip)
	end

	applyGuiZIndex(shopPanel, SHOP_BASE_Z_INDEX + 2)
	shopPanel.ZIndex = SHOP_BASE_Z_INDEX + 1
	shopOverlay.ZIndex = SHOP_BASE_Z_INDEX
	shopClose.ZIndex = SHOP_BASE_Z_INDEX + 4
	applyGuiZIndex(guidePanel, GUIDE_BASE_Z_INDEX + 2)
	guidePanel.ZIndex = GUIDE_BASE_Z_INDEX + 1
	guideOverlay.ZIndex = GUIDE_BASE_Z_INDEX
	guideClose.ZIndex = GUIDE_BASE_Z_INDEX + 4

	local miningPopupContainer = Instance.new("Frame")
	miningPopupContainer.Name = "MiningPopups"
	miningPopupContainer.AnchorPoint = Vector2.new(0.5, 0)
	miningPopupContainer.BackgroundTransparency = 1
	miningPopupContainer.BorderSizePixel = 0
	miningPopupContainer.Position = UDim2.new(0.5, 0, 0.22, 0)
	miningPopupContainer.Size = UDim2.new(0, 460, 0, 300)
	miningPopupContainer.ZIndex = POPUP_Z_INDEX
	miningPopupContainer.Parent = screenGui

	local miningPopupConstraint = Instance.new("UISizeConstraint")
	miningPopupConstraint.MinSize = Vector2.new(240, 120)
	miningPopupConstraint.MaxSize = Vector2.new(540, 360)
	miningPopupConstraint.Parent = miningPopupContainer

	local miningPopupLayout = Instance.new("UIListLayout")
	miningPopupLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	miningPopupLayout.SortOrder = Enum.SortOrder.LayoutOrder
	miningPopupLayout.Padding = UDim.new(0, 8)
	miningPopupLayout.Parent = miningPopupContainer

	local self = setmetatable({
		gui = screenGui,
		backdrop = backdrop,
		scroll = scroll,
		reopenButton = reopenButton,
		shop = {
			overlay = shopOverlay,
			panel = shopPanel,
			title = shopTitle,
			subtitle = shopSubtitle,
			info = shopInfoLabel,
			offers = shopOfferRows,
			rarity = rarityGrid,
			rarityLabels = rarityLabels,
			closeButton = shopClose,
		},
		vault = {
			overlay = vaultOverlay,
			items = vaultItems,
			button = vaultButton,
			closeButton = vaultClose,
			coinLabel = coinLabel,
		},
		guide = {
			overlay = guideOverlay,
			button = guideButton,
			closeButton = guideClose,
			rows = guideRows,
			collectionFrame = guideCollectionFrame,
			collectionGrid = guideCollectionGrid,
			hoverTitle = guideHoverTitle,
			hoverRarity = guideHoverRarity,
			hoverAttributes = guideHoverAttributes,
			subtitle = guideSubtitle,
			chartTabButton = chartTabButton,
			collectionTabButton = collectionTabButton,
			activeTab = "chart",
			chartSubtitleText = initialGuideSummary.subtitleText,
			collectionSubtitleText = "Collect resources to light up your guide bubbles.",
		},
		miningPopupContainer = miningPopupContainer,
		labels = {
			status = status,
			overview = overviewLabel,
			shop = shopLabel,
			shopHint = shopHint,
			geode = geodeLabel,
			daily = dailyLabel,
			offline = offlineLabel,
			plot = plotLabel,
			placement = placementLabel,
			notifications = notificationsLabel,
		},
		buttons = {
			placeGeode = placeGeode,
			openReadyGeodes = openReadyGeodes,
			claimDaily = claimDaily,
			claimOffline = claimOffline,
			placeStarterStation = placeStarterStation,
		},
		buttonColors = {
			placeGeode = placeGeode.BackgroundColor3,
			openReadyGeodes = openReadyGeodes.BackgroundColor3,
			claimDaily = claimDaily.BackgroundColor3,
			claimOffline = claimOffline.BackgroundColor3,
			placeStarterStation = placeStarterStation.BackgroundColor3,
		},
		celebrationQueue = {},
		celebrationPlaying = false,
		isOpen = true,
	}, RootScreen)

	shopClose.Activated:Connect(function()
		shopOverlay.Visible = false
	end)

	vaultButton.Activated:Connect(function()
		vaultOverlay.Visible = not vaultOverlay.Visible
	end)

	vaultClose.Activated:Connect(function()
		vaultOverlay.Visible = false
	end)

	guideButton.Activated:Connect(function()
		local nextVisible = not guideOverlay.Visible
		guideOverlay.Visible = nextVisible
		playGuideButtonSound(nextVisible)
	end)

	chartTabButton.Activated:Connect(function()
		self:setResourceGuideTab("chart")
	end)

	collectionTabButton.Activated:Connect(function()
		self:setResourceGuideTab("collection")
	end)

	guideClose.Activated:Connect(function()
		if guideOverlay.Visible then
			guideOverlay.Visible = false
			playGuideButtonSound(false)
		end
	end)

	self:setShopMenuVisible(false)
	self:setResourceGuideVisible(false)
	self:setResourceGuideTab("chart")
	self:setOpenReadyGeodeButton(false, "Open Ready Geode")
	self:setOfflineButtonState(false, "Claim Offline Cache")
	self:setPlaceStarterStationButton(true, "Place Starter Station")
	return self
end

local function normalizeCelebrationSpec(inputValue)
	if type(inputValue) == "string" then
		return {
			kind = "basic",
			headline = inputValue,
			primary = inputValue,
			compact = true,
		}
	end

	if type(inputValue) ~= "table" then
		return {
			kind = "basic",
			headline = tostring(inputValue),
			primary = tostring(inputValue),
			compact = true,
		}
	end

	local spec = {
		kind = tostring(inputValue.kind or inputValue.mode or "basic"),
		headline = tostring(inputValue.headline or inputValue.title or inputValue.text or "Reward!"),
		primary = tostring(inputValue.primary or inputValue.itemName or inputValue.resourceName or inputValue.geodeName or inputValue.resourceDisplayName or inputValue.geodeDisplayName or inputValue.headline or inputValue.title or inputValue.text or "Reward!"),
		detail = inputValue.detail,
		rarityLabel = inputValue.rarityLabel or inputValue.rarity or nil,
		rarityIndex = if type(inputValue.rarityIndex) == "number" then inputValue.rarityIndex else nil,
		traitId = if type(inputValue.traitId) == "string" then inputValue.traitId else nil,
		resourceTypeId = if type(inputValue.resourceTypeId) == "string" then inputValue.resourceTypeId else nil,
		geodeTypeId = if type(inputValue.geodeTypeId) == "string" then inputValue.geodeTypeId else nil,
		accentColor = if typeof(inputValue.accentColor) == "Color3" then inputValue.accentColor else nil,
		highlightColor = if typeof(inputValue.highlightColor) == "Color3" then inputValue.highlightColor else nil,
		textColor = if typeof(inputValue.textColor) == "Color3" then inputValue.textColor else nil,
		duration = if type(inputValue.duration) == "number" then inputValue.duration else nil,
		reelWords = if type(inputValue.reelWords) == "table" then inputValue.reelWords else nil,
		reelFinal = if type(inputValue.reelFinal) == "string" then inputValue.reelFinal else nil,
		showSlotMachine = inputValue.showSlotMachine == true,
		compact = inputValue.compact == true,
		waitForClick = inputValue.waitForClick == true,
		continuePrompt = sanitizePromptText(inputValue.continuePrompt),
	}

	if spec.rarityIndex == nil then
		if spec.kind == "attribute" then
			spec.rarityIndex = getTraitRarityIndex(spec.traitId)
		elseif spec.kind == "geode" then
			spec.rarityIndex = getGeodeRarityIndex(spec.geodeTypeId)
		elseif spec.kind == "resource" then
			spec.rarityIndex = getResourceRarityIndex(spec.resourceTypeId)
		else
			spec.rarityIndex = 1
		end
	end

	if spec.rarityLabel == nil then
		if spec.kind == "attribute" and spec.traitId ~= nil then
			local traitDefinition = Traits[spec.traitId]
			spec.rarityLabel = if traitDefinition ~= nil then traitDefinition.displayName else spec.traitId
		elseif spec.kind == "geode" and spec.geodeTypeId ~= nil then
			spec.rarityLabel = GEODE_RARITY_BY_ID[spec.geodeTypeId] or "Common"
		elseif spec.kind == "resource" and spec.resourceTypeId ~= nil then
			local resourceDefinition = Resources[spec.resourceTypeId]
			spec.rarityLabel = if resourceDefinition ~= nil then resourceDefinition.rarity else "Common"
		else
			spec.rarityLabel = "Common"
		end
	end

	if spec.reelWords == nil then
		if spec.kind == "attribute" then
			spec.reelWords = getTraitReelWords()
		else
			spec.reelWords = GEODE_RARITY_ORDER
		end
	end

	if spec.reelFinal == nil then
		spec.reelFinal = spec.primary
	end

	if spec.kind == "geode_discovery" then
		spec.showSlotMachine = false
	elseif spec.showSlotMachine ~= true then
		spec.showSlotMachine = (spec.kind == "geode" or spec.kind == "resource" or spec.kind == "attribute")
			and (spec.rarityIndex or 1) > 1
	end

	if spec.kind == "coin" then
		spec.compact = true
		if spec.textColor == nil then
			spec.textColor = Color3.fromRGB(255, 249, 214)
		end
	end

	if spec.waitForClick == true and spec.continuePrompt == nil then
		if spec.kind == "resource" then
			spec.continuePrompt = "Click to roll attribute!"
		elseif spec.kind == "geode" then
			spec.continuePrompt = "Click to reveal resource!"
		else
			spec.continuePrompt = "Click anywhere to continue!"
		end
	end

	return spec
end

local function makePopup(parent: Instance, backgroundColor: Color3, strokeColor: Color3, width: number, minHeight: number)
	local popup = Instance.new("Frame")
	popup.Name = "CelebrationPopup"
	popup.AnchorPoint = Vector2.new(0.5, 0)
	popup.BackgroundColor3 = backgroundColor
	popup.BorderSizePixel = 0
	-- Let the popup grow only when the handoff footer is actually shown so reveal reels do not reserve a giant empty panel.
	popup.AutomaticSize = Enum.AutomaticSize.Y
	popup.ClipsDescendants = false
	popup.Position = UDim2.new(0.5, 0, 0, 0)
	popup.Size = UDim2.new(0, width, 0, minHeight)
	popup.ZIndex = POPUP_Z_INDEX
	popup.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = popup

	local stroke = Instance.new("UIStroke")
	stroke.Color = strokeColor
	stroke.Thickness = 3
	stroke.Parent = popup

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, backgroundColor:Lerp(Color3.fromRGB(255, 255, 255), 0.16)),
		ColorSequenceKeypoint.new(1, backgroundColor:Lerp(Color3.fromRGB(255, 255, 255), 0.38)),
	})
	gradient.Rotation = 20
	gradient.Parent = popup

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = popup

	return popup
end

local function createTextLabel(parent: Instance, text: string, fontSize: number, textColor: Color3, height: number)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, height)
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextColor3 = textColor
	label.TextSize = fontSize
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = POPUP_Z_INDEX + 1
	label.Parent = parent

	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MaxTextSize = fontSize
	constraint.MinTextSize = math.max(12, fontSize - 8)
	constraint.Parent = label

	return label
end

local function createFittedPopupLabel(parent: Instance, text: string, fontSize: number, textColor: Color3, height: number, minTextSize: number)
	local label = createTextLabel(parent, text, fontSize, textColor, height)
	label.TextScaled = true

	local constraint = label:FindFirstChildWhichIsA("UITextSizeConstraint")
	if constraint ~= nil then
		constraint.MaxTextSize = fontSize
		constraint.MinTextSize = minTextSize
	end

	return label
end

local function createReel(parent: Instance, tone, initialText: string)
	local reel = Instance.new("Frame")
	reel.BackgroundColor3 = tone.highlight
	reel.BorderSizePixel = 0
	reel.Size = UDim2.new(1, 0, 1, 0)
	reel.ZIndex = POPUP_Z_INDEX + 1
	reel.Parent = parent

	local reelCorner = Instance.new("UICorner")
	reelCorner.CornerRadius = UDim.new(0, 8)
	reelCorner.Parent = reel

	local reelStroke = Instance.new("UIStroke")
	reelStroke.Color = tone.accent
	reelStroke.Thickness = 2
	reelStroke.Parent = reel

	local reelLabel = createTextLabel(reel, initialText, 14, tone.text, 38)
	reelLabel.Position = UDim2.fromScale(0, 0)
	reelLabel.Size = UDim2.new(1, -4, 1, -2)
	reelLabel.TextScaled = true

	return reel, reelLabel
end

local function applyCelebrationTone(
	popup: Frame,
	tone,
	titleLabel: TextLabel?,
	reelFrame: Frame?,
	reelLabel: TextLabel?,
	primaryLabel: TextLabel?,
	detailLabel: TextLabel?,
	badgeLabel: TextLabel?,
	continueFrame: Frame?,
	continueLabel: TextLabel?
)
	popup.BackgroundColor3 = tone.background

	local popupStroke = popup:FindFirstChildWhichIsA("UIStroke")
	if popupStroke ~= nil then
		popupStroke.Color = tone.accent
	end

	if titleLabel ~= nil then
		titleLabel.TextColor3 = tone.text
	end

	if reelFrame ~= nil then
		reelFrame.BackgroundColor3 = tone.highlight
		local reelStroke = reelFrame:FindFirstChildWhichIsA("UIStroke")
		if reelStroke ~= nil then
			reelStroke.Color = tone.accent
		end
	end

	if reelLabel ~= nil then
		reelLabel.TextColor3 = tone.text
	end

	if primaryLabel ~= nil then
		primaryLabel.TextColor3 = tone.text
	end

	if detailLabel ~= nil then
		detailLabel.TextColor3 = tone.text
	end

	if badgeLabel ~= nil then
		badgeLabel.BackgroundColor3 = tone.highlight
		badgeLabel.TextColor3 = tone.text
		local badgeStroke = badgeLabel:FindFirstChildWhichIsA("UIStroke")
		if badgeStroke ~= nil then
			badgeStroke.Color = tone.accent
		end
	end

	if continueFrame ~= nil then
		continueFrame.BackgroundColor3 = tone.highlight
		local continueStroke = continueFrame:FindFirstChildWhichIsA("UIStroke")
		if continueStroke ~= nil then
			continueStroke.Color = tone.accent
		end
	end

	if continueLabel ~= nil then
		continueLabel.TextColor3 = tone.text
	end
end

function RootScreen:_pumpCelebrationQueue()
	if self.celebrationPlaying or #self.celebrationQueue == 0 then
		return
	end

	self.celebrationPlaying = true
	local spec = table.remove(self.celebrationQueue, 1)

	task.spawn(function()
		local tone = getRarityTone(spec.rarityIndex, spec.accentColor)
		if spec.kind == "attribute" and spec.traitId ~= nil then
			local traitTone = getTraitTone(spec.traitId)
			if traitTone ~= nil then
				tone = traitTone
			end
		end

		local isCoin = spec.kind == "coin"
		local width = if isCoin then 260 elseif spec.compact == true then 300 elseif spec.showSlotMachine == true then 460 else 360
		local height = if isCoin then 52 elseif spec.compact == true then 68 elseif spec.showSlotMachine == true then 212 else 104
		if spec.kind == "geode_discovery" then
			local ri = math.clamp(spec.rarityIndex or 1, 1, 10)
			width = math.clamp(320 + (ri - 1) * 22, 320, 520)
			height = math.clamp(110 + (ri - 1) * 18, 110, 280)
		elseif spec.kind == "attribute" then
			height = if spec.showSlotMachine == true then 276 else 222
		elseif spec.kind == "resource" then
			height = if spec.showSlotMachine == true then 276 else 132
		elseif spec.kind == "geode" then
			height = if spec.showSlotMachine == true then 260 else 132
		end
		local popup = makePopup(self.miningPopupContainer, tone.background, tone.accent, width, height)
		if isCoin then
			local popupStroke = popup:FindFirstChildWhichIsA("UIStroke")
			if popupStroke ~= nil then
				popupStroke:Destroy()
			end
			local popupGradient = popup:FindFirstChildWhichIsA("UIGradient")
			if popupGradient ~= nil then
				popupGradient:Destroy()
			end
			popup.BackgroundTransparency = 1
			-- Let coin bursts roam across a wider center band so repeated mining does not stack every reward in one narrow lane.
			local randX = 0.5 + (math.random() - 0.5) * 0.64
			local randY = 0.34 + ((math.random() - 0.5) * 0.24)
			popup.Position = UDim2.new(randX, 0, randY, 0)
		end
		if spec.kind == "geode_discovery" then
			local ri = math.clamp(spec.rarityIndex or 1, 1, 10)
			local popupStroke = popup:FindFirstChildWhichIsA("UIStroke")
			if popupStroke ~= nil then
				popupStroke.Thickness = math.clamp(3 + (ri - 1) * 0.5, 3, 7)
			end
			local popupCorner = popup:FindFirstChildWhichIsA("UICorner")
			if popupCorner ~= nil then
				popupCorner.CornerRadius = UDim.new(0, math.clamp(10 + (ri - 1) * 2, 10, 24))
			end
		end
		local scale = Instance.new("UIScale")
		scale.Scale = 0.86
		scale.Parent = popup

		local layout = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 6)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Top
		layout.Parent = popup

		local titleText = if isCoin then spec.headline else string.upper(spec.headline)
		local titleFontSize = if isCoin then 30 elseif spec.compact == true then 18 else 22
		if spec.kind == "geode_discovery" then
			local ri = math.clamp(spec.rarityIndex or 1, 1, 10)
			titleFontSize = math.clamp(24 + (ri - 1) * 3, 24, 48)
		end
		local titleHeight = if isCoin then 42 elseif spec.compact == true then 22 else math.clamp(titleFontSize + 8, 24, 58)
		local title = createTextLabel(popup, titleText, titleFontSize, spec.textColor or tone.text, titleHeight)
		title.LayoutOrder = 1
		if isCoin then
			title.Rotation = math.random(-8, 8)
			title.TextStrokeTransparency = 0.36
			title.TextStrokeColor3 = Color3.fromRGB(172, 112, 28)
		end

		local reelRow
		local reelFrame
		local reelLabel
		local reelFinished = true
		local primaryLabel
		local detailLabel
		local badgeLabel
		local continueButton
		local continueLabel
		local continueFrame
		local hideResolvedRevealText = GeodePresentation.shouldHideResolvedRevealText(spec.kind, spec.showSlotMachine, false)
		local resolvedDetailText = if spec.detail ~= nil then tostring(spec.detail) else tostring(spec.rarityLabel or "")
		local resolvedBadgeText = if spec.rarityLabel ~= nil then tostring(spec.rarityLabel):upper() else nil

		local function revealResolvedPopupText()
			if not hideResolvedRevealText then
				return
			end

			if primaryLabel ~= nil then
				primaryLabel.Text = spec.primary
				primaryLabel.Visible = true
			end

			if detailLabel ~= nil then
				detailLabel.Text = resolvedDetailText
				detailLabel.Visible = true
			end

			if badgeLabel ~= nil then
				badgeLabel.Text = resolvedBadgeText or ""
				badgeLabel.Visible = true
			end
		end

		local function createContinuePrompt()
			if continueFrame ~= nil or spec.waitForClick ~= true then
				return
			end

			continueFrame = Instance.new("Frame")
			continueFrame.Name = "CelebrationPromptFrame"
			continueFrame.BackgroundColor3 = tone.highlight
			continueFrame.BorderSizePixel = 0
			continueFrame.LayoutOrder = 99
			continueFrame.Size = UDim2.new(0.92, 0, 0, 42)
			continueFrame.ZIndex = POPUP_Z_INDEX + 3
			continueFrame.Parent = popup

			local continueCorner = Instance.new("UICorner")
			continueCorner.CornerRadius = UDim.new(0, 14)
			continueCorner.Parent = continueFrame

			local continueStroke = Instance.new("UIStroke")
			continueStroke.Color = tone.accent
			continueStroke.Thickness = 2
			continueStroke.Parent = continueFrame

			continueLabel = Instance.new("TextLabel")
			continueLabel.Name = "CelebrationContinuePrompt"
			continueLabel.Active = false
			continueLabel.BackgroundTransparency = 1
			continueLabel.Size = UDim2.new(1, -14, 1, 0)
			continueLabel.Position = UDim2.new(0, 7, 0, 0)
			continueLabel.Font = Enum.Font.FredokaOne
			continueLabel.Text = spec.continuePrompt or "Click anywhere to continue!"
			continueLabel.TextColor3 = tone.text
			continueLabel.TextSize = 18
			continueLabel.TextScaled = true
			continueLabel.TextTransparency = 0.28
			continueLabel.ZIndex = POPUP_Z_INDEX + 4
			continueLabel.Parent = continueFrame

			local continueConstraint = Instance.new("UITextSizeConstraint")
			continueConstraint.MaxTextSize = 18
			continueConstraint.MinTextSize = 11
			continueConstraint.Parent = continueLabel

			continueButton = Instance.new("TextButton")
			continueButton.Name = "CelebrationContinueButton"
			continueButton.Active = false
			continueButton.AutoButtonColor = false
			continueButton.BackgroundTransparency = 1
			continueButton.BorderSizePixel = 0
			continueButton.Visible = false
			continueButton.Size = UDim2.new(1, 0, 1, 0)
			continueButton.Font = Enum.Font.FredokaOne
			continueButton.Text = ""
			continueButton.ZIndex = POPUP_Z_INDEX + 3
			continueButton.Parent = popup
		end

		if spec.kind == "geode_discovery" then
			local ri = math.clamp(spec.rarityIndex or 1, 1, 10)
			local nameFontSize = math.clamp(22 + (ri - 1) * 2, 22, 40)
			primaryLabel = createTextLabel(popup, spec.primary, nameFontSize, spec.textColor or tone.text, nameFontSize + 6)
			primaryLabel.LayoutOrder = 2

			local badgeFontSize = math.clamp(14 + (ri - 1) * 1, 14, 24)
			badgeLabel = Instance.new("TextLabel")
			badgeLabel.BackgroundColor3 = tone.highlight
			badgeLabel.BorderSizePixel = 0
			badgeLabel.Size = UDim2.new(0, math.clamp(100 + ri * 10, 100, 200), 0, math.clamp(22 + (ri - 1) * 2, 22, 36))
			badgeLabel.Font = Enum.Font.FredokaOne
			badgeLabel.Text = tostring(spec.rarityLabel or ""):upper()
			badgeLabel.TextColor3 = tone.text
			badgeLabel.TextSize = badgeFontSize
			badgeLabel.ZIndex = POPUP_Z_INDEX + 1
			badgeLabel.LayoutOrder = 3
			badgeLabel.Parent = popup

			local badgeCorner = Instance.new("UICorner")
			badgeCorner.CornerRadius = UDim.new(0, 10)
			badgeCorner.Parent = badgeLabel

			local badgeStroke = Instance.new("UIStroke")
			badgeStroke.Color = tone.accent
			badgeStroke.Thickness = math.clamp(2 + math.floor((ri - 1) * 0.4), 2, 5)
			badgeStroke.Parent = badgeLabel

			if ri >= 5 then
				local subtitleText = if ri >= 8 then "INCREDIBLE FIND!" elseif ri >= 6 then "AMAZING!" else "RARE FIND!"
				detailLabel = createTextLabel(popup, subtitleText, math.clamp(14 + (ri - 3), 14, 22), tone.text, math.clamp(18 + (ri - 3), 18, 28))
				detailLabel.LayoutOrder = 4
			end
		elseif spec.compact ~= true then
			if spec.showSlotMachine == true then
				reelRow = Instance.new("Frame")
				reelRow.BackgroundTransparency = 1
				reelRow.BorderSizePixel = 0
				reelRow.LayoutOrder = 2
				reelRow.Size = UDim2.new(0.85, 0, 0, 48)
				reelRow.Parent = popup

				reelFrame, reelLabel = createReel(reelRow, tone, "...")
				reelFrame.Size = UDim2.new(1, 0, 1, 0)

				local spinWords = spec.reelWords or GEODE_RARITY_ORDER
				if #spinWords == 0 then
					spinWords = { spec.primary }
				end
				local initialSpinWord = tostring(spinWords[1] or spec.primary)
				if reelLabel ~= nil then
					reelLabel.Text = initialSpinWord
				end
				applyCelebrationTone(
					popup,
					getSpinTone(spec, initialSpinWord, tone),
					title,
					reelFrame,
					reelLabel,
					primaryLabel,
					detailLabel,
					badgeLabel,
					continueFrame,
					continueLabel
				)

				reelFinished = false
				task.spawn(function()
					local totalSteps = math.max(12, 8 + (spec.rarityIndex or 1) * 3)
					for spinStep = 1, totalSteps do
						local progress = spinStep / totalSteps
						local stepDelay = 0.06 + progress * 0.14
						local wordIndex = ((spinStep) % #spinWords) + 1
						local spinWord = tostring(spinWords[wordIndex])
						if reelLabel ~= nil then
							reelLabel.Text = spinWord
						end
						applyCelebrationTone(
							popup,
							getSpinTone(spec, spinWord, tone),
							title,
							reelFrame,
							reelLabel,
							primaryLabel,
							detailLabel,
							badgeLabel,
							continueFrame,
							continueLabel
						)
						if spinStep == 1 or spinStep % 3 == 0 then
							playLocalUiSound(
								AUDIO_LIBRARY.tick,
								math.clamp(0.05 + ((spec.rarityIndex or 1) * 0.015), 0.05, 0.12),
								1.08 + (progress * 0.28)
							)
						end
						task.wait(stepDelay)
					end
					if reelLabel ~= nil then
						reelLabel.Text = tostring(spec.reelFinal or spec.primary)
					end
					applyCelebrationTone(
						popup,
						tone,
						title,
						reelFrame,
						reelLabel,
						primaryLabel,
						detailLabel,
						badgeLabel,
						continueFrame,
						continueLabel
					)
					playCelebrationSound(spec)
					reelFinished = true
					revealResolvedPopupText()
				end)
			end

			primaryLabel = createFittedPopupLabel(
				popup,
				if hideResolvedRevealText then "" else spec.primary,
				if spec.showSlotMachine == true then 26 else 28,
				spec.textColor or tone.text,
				if spec.showSlotMachine == true then 38 else 34,
				if spec.showSlotMachine == true then 16 else 20
			)
			primaryLabel.LayoutOrder = if spec.showSlotMachine == true then 3 else 2
			primaryLabel.Visible = not hideResolvedRevealText

			if spec.detail ~= nil or spec.rarityLabel ~= nil then
				detailLabel = createFittedPopupLabel(
					popup,
					if hideResolvedRevealText then "" else resolvedDetailText,
					18,
					tone.text,
					if spec.showSlotMachine == true then 28 else 22,
					12
				)
				detailLabel.LayoutOrder = if spec.showSlotMachine == true then 4 else 3
				detailLabel.Visible = not hideResolvedRevealText
			end

			if spec.rarityLabel ~= nil and spec.compact ~= true then
				badgeLabel = Instance.new("TextLabel")
				badgeLabel.BackgroundColor3 = tone.highlight
				badgeLabel.BorderSizePixel = 0
				badgeLabel.Size = UDim2.new(0, math.clamp(100 + ((spec.rarityIndex or 1) * 6), 100, 170), 0, 22)
				badgeLabel.Font = Enum.Font.FredokaOne
				badgeLabel.Text = if hideResolvedRevealText then "" else (resolvedBadgeText or "")
				badgeLabel.TextColor3 = tone.text
				badgeLabel.TextSize = 14
				badgeLabel.ZIndex = POPUP_Z_INDEX + 1
				badgeLabel.LayoutOrder = if spec.showSlotMachine == true then 5 else 4
				badgeLabel.Visible = not hideResolvedRevealText
				badgeLabel.Parent = popup

				local badgeCorner = Instance.new("UICorner")
				badgeCorner.CornerRadius = UDim.new(0, 8)
				badgeCorner.Parent = badgeLabel

				local badgeStroke = Instance.new("UIStroke")
				badgeStroke.Color = tone.accent
				badgeStroke.Thickness = 2
				badgeStroke.Parent = badgeLabel
			end
		else
			if isCoin then
				-- coin popup only shows the title (e.g. "+6 Coins"), no extra label
			elseif spec.kind ~= "basic" or spec.detail ~= nil then
				primaryLabel = createTextLabel(popup, spec.primary, 20, tone.text, 22)
				primaryLabel.LayoutOrder = 2
				detailLabel = createTextLabel(popup, spec.detail ~= nil and tostring(spec.detail) or "Sweet!", 14, tone.text, 16)
				detailLabel.LayoutOrder = 3
			end
		end

		applyCelebrationTone(
			popup,
			tone,
			title,
			reelFrame,
			reelLabel,
			primaryLabel,
			detailLabel,
			badgeLabel,
			continueFrame,
			continueLabel
		)

		if spec.showSlotMachine ~= true and spec.kind ~= "coin" then
			playCelebrationSound(spec)
		end

		local popInTime = 0.2
		local popInTarget = 1
		if spec.kind == "geode_discovery" then
			local ri = math.clamp(spec.rarityIndex or 1, 1, 10)
			popInTime = math.clamp(0.22 + (ri - 1) * 0.02, 0.22, 0.38)
			popInTarget = math.clamp(1 + (ri - 1) * 0.04, 1, 1.32)
			scale.Scale = 0.5
		end
		local popIn = TweenService:Create(
			scale,
			TweenInfo.new(popInTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = popInTarget }
		)
		popIn:Play()

		if reelRow ~= nil and spec.showSlotMachine == true then
			while not reelFinished do
				task.wait(0.05)
			end
		end

		local holdDuration
		if spec.duration ~= nil then
			holdDuration = spec.duration
		elseif spec.kind == "geode_discovery" then
			local ri = math.clamp(spec.rarityIndex or 1, 1, 10)
			holdDuration = math.clamp(1.6 + (ri - 1) * 0.3, 1.6, 4.3)
		elseif spec.compact == true then
			holdDuration = 0.92
		elseif spec.showSlotMachine == true then
			holdDuration = 3.0
		else
			holdDuration = 2.0
		end
		task.wait(holdDuration)

		if spec.waitForClick == true then
			-- Only create the footer once the current reel has fully settled so the resource-to-attribute handoff does not show as empty space.
			createContinuePrompt()
			applyCelebrationTone(
				popup,
				tone,
				title,
				reelFrame,
				reelLabel,
				primaryLabel,
				detailLabel,
				badgeLabel,
				continueFrame,
				continueLabel
			)
		end

		if spec.waitForClick == true and continueButton ~= nil and continueLabel ~= nil then
			continueButton.Visible = true
			continueButton.Active = true
			continueLabel.TextTransparency = 0.12
			local clicked = false
			local autoAdvanceDelay = if spec.kind == "resource" then 0.85 else nil
			local function setClicked()
				clicked = true
			end

			continueButton.Activated:Connect(function()
				setClicked()
			end)

			local inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
				if gameProcessedEvent then
					return
				end
				if GeodePresentation.shouldAdvanceRevealOnInput(input.UserInputType) then
					setClicked()
				end
			end)

			task.spawn(function()
				while not clicked do
					for t = 0, 1, 0.05 do
						if clicked then
							break
						end
						continueLabel.TextTransparency = 0.08 + math.sin(t * math.pi) * 0.2
						task.wait(0.04)
					end
				end
			end)

			if autoAdvanceDelay ~= nil then
				task.delay(autoAdvanceDelay, function()
					if not clicked then
						setClicked()
					end
				end)
			end

			while not clicked do
				task.wait(0.05)
			end

			inputConnection:Disconnect()
			continueButton:Destroy()
			continueLabel:Destroy()
			if continueFrame ~= nil then
				continueFrame:Destroy()
			end
		end

		local fadeTween = TweenService:Create(
			popup,
			TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				BackgroundTransparency = 1,
			}
		)
		fadeTween:Play()

		for _, descendant in ipairs(popup:GetDescendants()) do
			if descendant:IsA("TextLabel") then
				TweenService:Create(
					descendant,
					TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						TextTransparency = 1,
					}
				):Play()
			elseif descendant:IsA("UIStroke") then
				TweenService:Create(
					descendant,
					TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Transparency = 1,
					}
				):Play()
			end
		end

		task.wait(0.24)
		popup:Destroy()
		self.celebrationPlaying = false
		self:_pumpCelebrationQueue()
	end)
end

function RootScreen:setStatusText(text)
	self.labels.status.Text = text
end

function RootScreen:setOverviewText(text)
	self.labels.overview.Text = text
end

function RootScreen:setCoinCounterText(text)
	self.vault.coinLabel.Text = text
end

function RootScreen:setShopText(text)
	self.labels.shop.Text = text
end

function RootScreen:setGeodeText(text)
	self.labels.geode.Text = text
end

function RootScreen:setPlaceGeodeButton(enabled, text)
	self.buttons.placeGeode.Visible = false
	self.buttons.placeGeode.Active = enabled
	self.buttons.placeGeode.AutoButtonColor = enabled
	self.buttons.placeGeode.Text = text
	self.buttons.placeGeode.BackgroundColor3 = if enabled then self.buttonColors.placeGeode else Color3.fromRGB(120, 120, 120)
end

function RootScreen:setOpenReadyGeodeButton(enabled, text)
	self.buttons.openReadyGeodes.Active = enabled
	self.buttons.openReadyGeodes.AutoButtonColor = enabled
	self.buttons.openReadyGeodes.Text = text
	self.buttons.openReadyGeodes.BackgroundColor3 = if enabled then self.buttonColors.openReadyGeodes else Color3.fromRGB(120, 120, 120)
end

function RootScreen:setDailyText(text)
	self.labels.daily.Text = text
end

function RootScreen:setOfflineText(text)
	self.labels.offline.Text = text
end

function RootScreen:setPlotText(text)
	self.labels.plot.Text = text
end

function RootScreen:setPlacementText(text)
	self.labels.placement.Text = text
end

function RootScreen:setPlaceStarterStationButton(enabled, text)
	self.buttons.placeStarterStation.Active = enabled
	self.buttons.placeStarterStation.AutoButtonColor = enabled
	self.buttons.placeStarterStation.Text = text
	self.buttons.placeStarterStation.BackgroundColor3 = if enabled then self.buttonColors.placeStarterStation else Color3.fromRGB(120, 120, 120)
end

function RootScreen:setNotificationsText(text)
	self.labels.notifications.Text = text
end

function RootScreen:showMiningPopup(text)
	local spec = normalizeCelebrationSpec(text)
	if spec.compact == true or spec.kind == "coin" then
		local i = 1
		while i <= #self.celebrationQueue do
			local queued = self.celebrationQueue[i]
			if queued.compact == true or queued.kind == "coin" then
				table.remove(self.celebrationQueue, i)
			else
				i += 1
			end
		end
	end
	table.insert(self.celebrationQueue, spec)
	while #self.celebrationQueue > POPUP_QUEUE_LIMIT do
		table.remove(self.celebrationQueue, 1)
	end
	self:_pumpCelebrationQueue()
end

function RootScreen:showRewardCelebration(data)
	self:showMiningPopup(data)
end

function RootScreen:setShopMenuVisible(visible)
	self.shop.overlay.Visible = visible
end

function RootScreen:setVaultVisible(visible)
	self.vault.overlay.Visible = visible
end

function RootScreen:setResourceGuideTab(tabId: string)
	local activeTab = if tabId == "collection" then "collection" else "chart"
	self.guide.activeTab = activeTab
	self.guide.rows.Visible = activeTab == "chart"
	self.guide.collectionFrame.Visible = activeTab == "collection"
	self.guide.subtitle.Text = if activeTab == "collection"
		then self.guide.collectionSubtitleText
		else self.guide.chartSubtitleText
	setGuideTabButtonState(self.guide.chartTabButton, activeTab == "chart")
	setGuideTabButtonState(self.guide.collectionTabButton, activeTab == "collection")
end

function RootScreen:setResourceGuideVisible(visible)
	self.guide.overlay.Visible = visible
end

function RootScreen:setResourceGuideData(pickaxeId: string?, collectionState: any?)
	local summary = ResourceGuide.getGuideSummary(pickaxeId)
	local collectionSlots = ResourceGuide.getCollectionSlots(collectionState)
	local foundCount = 0
	for _, slotData in ipairs(collectionSlots) do
		if slotData.isFound then
			foundCount += 1
		end
	end

	self.guide.chartSubtitleText = summary.subtitleText
	self.guide.collectionSubtitleText = string.format(
		"Collected %d of %d resources. Hover a bubble to see what attributes you've discovered.",
		foundCount,
		#collectionSlots
	)
	self.guide.subtitle.Text = if self.guide.activeTab == "collection"
		then self.guide.collectionSubtitleText
		else self.guide.chartSubtitleText
	rebuildGuideRows(self.guide.rows, ResourceGuide.getGuideRows(summary.pickaxeId), summary.hintText)
	rebuildCollectionGrid(self.guide.collectionGrid, collectionSlots, {
		hoverTitle = self.guide.hoverTitle,
		hoverRarity = self.guide.hoverRarity,
		hoverAttributes = self.guide.hoverAttributes,
	})
end

function RootScreen:getVaultItemContainer()
	return self.vault.items
end

function RootScreen:clearVaultRows()
	clearContainer(self.vault.items)
end

function RootScreen:getShopOfferContainer()
	return self.shop.offers
end

function RootScreen:getShopRarityContainer()
	return self.shop.rarity
end

function RootScreen:setShopMenuSubtitle(text)
	self.shop.subtitle.Text = text
end

function RootScreen:setShopMenuInfo(text)
	self.shop.info.Text = text
end

function RootScreen:setShopMenuRarities(labels)
	for index, rarityLabel in ipairs(self.shop.rarityLabels) do
		local resolvedLabel = labels[index] or ""
		local tone = getRarityToneByName(resolvedLabel, Color3.fromRGB(255, 210, 120))
		rarityLabel.Text = resolvedLabel
		rarityLabel.BackgroundColor3 = tone.background
		rarityLabel.TextColor3 = tone.text
		local stroke = rarityLabel:FindFirstChildWhichIsA("UIStroke")
		if stroke ~= nil then
			stroke.Color = tone.accent
		end
	end
end

function RootScreen:clearShopOfferRows()
	clearContainer(self.shop.offers)
end

function RootScreen:setDailyButtonState(enabled, text)
	self.buttons.claimDaily.Active = enabled
	self.buttons.claimDaily.AutoButtonColor = enabled
	self.buttons.claimDaily.Text = text
	self.buttons.claimDaily.BackgroundColor3 = if enabled then self.buttonColors.claimDaily else Color3.fromRGB(120, 120, 120)
end

function RootScreen:setOfflineButtonState(enabled, text)
	self.buttons.claimOffline.Active = enabled
	self.buttons.claimOffline.AutoButtonColor = enabled
	self.buttons.claimOffline.Text = text
	self.buttons.claimOffline.BackgroundColor3 = if enabled then self.buttonColors.claimOffline else Color3.fromRGB(120, 120, 120)
end

function RootScreen:destroy()
	self.gui:Destroy()
end

return RootScreen
