--!strict

-- Client controller for Shop Controller that coordinates UI, local input, and app-state updates for this slice.

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Pickaxes = require(Shared.Config.Pickaxes)
local PickaxeRules = require(Shared.Domain.PickaxeRules)
local RemoteNames = require(Shared.Net.RemoteNames)

local ShopController = {}
ShopController.__index = ShopController

local SHOP_PROMPT_ATTRIBUTE = "GemFactoryShopPrompt"
local SHOP_ROW_Z_INDEX = 62
local SHOP_TEXT_Z_INDEX = 63
local SHOP_BUTTON_Z_INDEX = 64
local SHOP_BADGE_Z_INDEX = 65

local function formatNumber(value: number): string
	local text = tostring(math.floor(value + 0.5))
	while true do
		local nextText = text:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		if nextText == text then
			break
		end
		text = nextText
	end
	return text
end

local function clearOfferRows(container: Instance)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("UIListLayout") or child:IsA("UIPadding") or child:IsA("UIGridLayout") then
			continue
		end
		child:Destroy()
	end
end

local function collectOffers()
	local offers = {}
	for _, pickaxeId in ipairs(Pickaxes.order) do
		local definition = Pickaxes.catalog[pickaxeId]
		if definition ~= nil then
			table.insert(offers, definition)
		end
	end
	return offers
end

local function collectRarityLabels()
	local labels = {}
	for _, pickaxeId in ipairs(Pickaxes.order) do
		local definition = Pickaxes.catalog[pickaxeId]
		if definition ~= nil then
			table.insert(labels, definition.rarity)
		end
	end
	return labels
end

local function getOfferTone(offer)
	local accent = if typeof(offer.displayColor) == "Color3" then offer.displayColor else Color3.fromRGB(255, 190, 97)
	local warmAccent = accent:Lerp(Color3.fromRGB(255, 214, 128), 0.42)
	return {
		card = accent:Lerp(Color3.fromRGB(255, 248, 226), 0.8),
		cardBorder = accent:Lerp(Color3.fromRGB(255, 255, 255), 0.2),
		header = warmAccent,
		headerText = Color3.fromRGB(97, 61, 18),
		bodyText = Color3.fromRGB(105, 71, 29),
		secondaryText = Color3.fromRGB(132, 95, 49),
		button = accent:Lerp(Color3.fromRGB(255, 223, 134), 0.16),
		buttonText = Color3.fromRGB(78, 47, 16),
		statBubble = accent:Lerp(Color3.fromRGB(255, 255, 255), 0.56),
		iconBubble = accent:Lerp(Color3.fromRGB(255, 255, 255), 0.7),
	}
end

local function getActionColors(offerTone, isEquipped: boolean, canPress: boolean)
	if isEquipped then
		return Color3.fromRGB(181, 227, 170), Color3.fromRGB(54, 97, 48), Color3.fromRGB(231, 255, 223)
	end

	if canPress then
		return offerTone.button, offerTone.buttonText, offerTone.cardBorder
	end

	return Color3.fromRGB(207, 188, 167), Color3.fromRGB(114, 88, 66), Color3.fromRGB(244, 233, 223)
end

local function buildOfferSummary(offer)
	return {
		string.format("%d-%d coins", offer.coinRewardMin, offer.coinRewardMax),
		string.format("%d%% geode luck", offer.geodeChance),
		string.format("%.2fs swing", offer.cooldownSeconds),
	}
end

local PICKAXE_TIER_MARKS = {
	stone_pickaxe = "STN",
	copper_pickaxe = "CPR",
	iron_pickaxe = "IRN",
	steel_pickaxe = "STL",
	gold_pickaxe = "GLD",
	platinum_pickaxe = "PLT",
	emerald_pickaxe = "EMR",
	obsidian_pickaxe = "OBS",
	lunar_pickaxe = "LUN",
	crown_pickaxe = "CRN",
}

local function getTierMark(offer)
	return PICKAXE_TIER_MARKS[offer.id] or string.upper(string.sub(offer.displayName, 1, 3))
end

local function createOfferRow(parent: Instance, offer, isOwned: boolean, isEquipped: boolean, canBuy: boolean, actionText: string, onBuy, onEquip)
	local offerTone = getOfferTone(offer)
	local canPress = not isEquipped and (isOwned or canBuy)
	local actionBackground, actionTextColor, actionStrokeColor = getActionColors(offerTone, isEquipped, canPress)

	local row = Instance.new("Frame")
	row.Name = offer.displayName .. "Row"
	row.BackgroundColor3 = offerTone.card
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, -4, 0, 158)
	row.ZIndex = SHOP_ROW_Z_INDEX
	row.Parent = parent

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 24)
	rowCorner.Parent = row

	local rowStroke = Instance.new("UIStroke")
	rowStroke.Color = offerTone.cardBorder
	rowStroke.Thickness = 3
	rowStroke.Transparency = 0.02
	rowStroke.Parent = row

	local rowGradient = Instance.new("UIGradient")
	rowGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, offerTone.card:Lerp(Color3.fromRGB(255, 255, 255), 0.16)),
		ColorSequenceKeypoint.new(1, offerTone.card:Lerp(Color3.fromRGB(255, 229, 185), 0.06)),
	})
	rowGradient.Rotation = 90
	rowGradient.Parent = row

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 14)
	padding.PaddingBottom = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.Parent = row

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Size = UDim2.fromScale(1, 1)
	body.ZIndex = SHOP_ROW_Z_INDEX
	body.Parent = row

	local bodyLayout = Instance.new("UIListLayout")
	bodyLayout.FillDirection = Enum.FillDirection.Horizontal
	bodyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
	bodyLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	bodyLayout.Padding = UDim.new(0, 12)
	bodyLayout.Parent = body

	local iconBubble = Instance.new("Frame")
	iconBubble.Name = "IconBubble"
	iconBubble.BackgroundColor3 = offerTone.iconBubble
	iconBubble.BorderSizePixel = 0
	iconBubble.LayoutOrder = 1
	iconBubble.Size = UDim2.new(0, 78, 0, 78)
	iconBubble.ZIndex = SHOP_ROW_Z_INDEX
	iconBubble.Parent = body

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(1, 0)
	iconCorner.Parent = iconBubble

	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = offerTone.cardBorder
	iconStroke.Thickness = 3
	iconStroke.Parent = iconBubble

	local iconLabel = Instance.new("TextLabel")
	iconLabel.BackgroundTransparency = 1
	iconLabel.Size = UDim2.fromScale(1, 1)
	iconLabel.Font = Enum.Font.FredokaOne
	-- Short tier marks make the shop easier to scan at a glance without relying on repeated placeholder text.
	iconLabel.Text = getTierMark(offer)
	iconLabel.TextColor3 = offerTone.headerText
	iconLabel.TextSize = 24
	iconLabel.ZIndex = SHOP_TEXT_Z_INDEX
	iconLabel.Parent = iconBubble

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.LayoutOrder = 2
	content.Size = UDim2.new(1, -226, 1, 0)
	content.ZIndex = SHOP_ROW_Z_INDEX
	content.Parent = body

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Padding = UDim.new(0, 6)
	contentLayout.Parent = content

	local rarityChip = Instance.new("TextLabel")
	rarityChip.BackgroundColor3 = offerTone.header
	rarityChip.BorderSizePixel = 0
	rarityChip.LayoutOrder = 1
	rarityChip.Size = UDim2.new(0, 120, 0, 28)
	rarityChip.Font = Enum.Font.FredokaOne
	rarityChip.Text = string.upper(offer.rarity)
	rarityChip.TextColor3 = offerTone.headerText
	rarityChip.TextSize = 14
	rarityChip.ZIndex = SHOP_BADGE_Z_INDEX
	rarityChip.Parent = content

	local rarityCorner = Instance.new("UICorner")
	rarityCorner.CornerRadius = UDim.new(0, 13)
	rarityCorner.Parent = rarityChip

	local rarityStroke = Instance.new("UIStroke")
	rarityStroke.Color = offerTone.cardBorder
	rarityStroke.Thickness = 2
	rarityStroke.Parent = rarityChip

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.LayoutOrder = 2
	title.Size = UDim2.new(1, 0, 0, 28)
	title.Font = Enum.Font.FredokaOne
	title.Text = offer.displayName
	title.TextColor3 = offerTone.headerText
	title.TextSize = 26
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = SHOP_TEXT_Z_INDEX
	title.Parent = content

	local statsRow = Instance.new("Frame")
	statsRow.Name = "StatsRow"
	statsRow.BackgroundTransparency = 1
	statsRow.LayoutOrder = 3
	statsRow.Size = UDim2.new(1, 0, 0, 32)
	statsRow.ZIndex = SHOP_ROW_Z_INDEX
	statsRow.Parent = content

	local statsLayout = Instance.new("UIListLayout")
	statsLayout.FillDirection = Enum.FillDirection.Horizontal
	statsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statsLayout.Padding = UDim.new(0, 6)
	statsLayout.Parent = statsRow

	-- Keep the stat chips fixed-height and wrapped in a horizontal row so narrow/mobile panels stay readable without overlapping the action button.
	for index, summaryText in ipairs(buildOfferSummary(offer)) do
		local statBubble = Instance.new("TextLabel")
		statBubble.Name = string.format("Stat%d", index)
		statBubble.BackgroundColor3 = offerTone.statBubble
		statBubble.BorderSizePixel = 0
		statBubble.LayoutOrder = index
		statBubble.Size = UDim2.new(0, if index == 1 then 102 else 92, 0, 30)
		statBubble.Font = Enum.Font.GothamBold
		statBubble.Text = summaryText
		statBubble.TextColor3 = offerTone.secondaryText
		statBubble.TextSize = 12
		statBubble.TextScaled = true
		statBubble.ZIndex = SHOP_TEXT_Z_INDEX
		statBubble.Parent = statsRow

		local statCorner = Instance.new("UICorner")
		statCorner.CornerRadius = UDim.new(0, 12)
		statCorner.Parent = statBubble

		local statStroke = Instance.new("UIStroke")
		statStroke.Color = offerTone.cardBorder
		statStroke.Thickness = 2
		statStroke.Parent = statBubble

		local statConstraint = Instance.new("UITextSizeConstraint")
		statConstraint.MaxTextSize = 12
		statConstraint.MinTextSize = 9
		statConstraint.Parent = statBubble
	end

	local price = Instance.new("TextLabel")
	price.BackgroundTransparency = 1
	price.LayoutOrder = 4
	price.Size = UDim2.new(1, 0, 0, 30)
	price.Font = Enum.Font.GothamBold
	price.Text = if isOwned
		then "Already riding with your tool belt."
		else string.format("%s %s to unlock", formatNumber(offer.price), string.lower(offer.currency))
	price.TextColor3 = offerTone.bodyText
	price.TextSize = 14
	price.TextWrapped = true
	price.TextXAlignment = Enum.TextXAlignment.Left
	price.TextYAlignment = Enum.TextYAlignment.Top
	price.ZIndex = SHOP_TEXT_Z_INDEX
	price.Parent = content

	local actionColumn = Instance.new("Frame")
	actionColumn.Name = "ActionColumn"
	actionColumn.BackgroundTransparency = 1
	actionColumn.LayoutOrder = 3
	actionColumn.Size = UDim2.new(0, 110, 1, 0)
	actionColumn.ZIndex = SHOP_ROW_Z_INDEX
	actionColumn.Parent = body

	local actionBadge = Instance.new("TextLabel")
	actionBadge.BackgroundTransparency = 1
	actionBadge.Position = UDim2.new(0, 0, 0, 14)
	actionBadge.Size = UDim2.new(1, 0, 0, 18)
	actionBadge.Font = Enum.Font.GothamBold
	actionBadge.Text = if isEquipped then "Current" elseif isOwned then "Owned" elseif canBuy then "Ready" else "Locked"
	actionBadge.TextColor3 = offerTone.secondaryText
	actionBadge.TextSize = 12
	actionBadge.TextXAlignment = Enum.TextXAlignment.Center
	actionBadge.ZIndex = SHOP_TEXT_Z_INDEX
	actionBadge.Parent = actionColumn

	local action = Instance.new("TextButton")
	action.Name = "ActionButton"
	action.AnchorPoint = Vector2.new(0.5, 0.5)
	action.AutoButtonColor = canPress
	action.Active = canPress
	action.BackgroundColor3 = actionBackground
	action.BorderSizePixel = 0
	action.Position = UDim2.new(0.5, 0, 0.5, 10)
	action.Size = UDim2.new(1, 0, 0, 62)
	action.Font = Enum.Font.FredokaOne
	action.Text = actionText
	action.TextColor3 = actionTextColor
	action.TextSize = 21
	action.TextWrapped = true
	action.ZIndex = SHOP_BUTTON_Z_INDEX
	action.Parent = actionColumn

	local actionCorner = Instance.new("UICorner")
	actionCorner.CornerRadius = UDim.new(0, 18)
	actionCorner.Parent = action

	local actionStroke = Instance.new("UIStroke")
	actionStroke.Color = actionStrokeColor
	actionStroke.Thickness = 3
	actionStroke.Transparency = 0.02
	actionStroke.Parent = action

	local actionGradient = Instance.new("UIGradient")
	actionGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, actionBackground:Lerp(Color3.fromRGB(255, 255, 255), 0.1)),
		ColorSequenceKeypoint.new(1, actionBackground:Lerp(Color3.fromRGB(255, 221, 169), 0.08)),
	})
	actionGradient.Rotation = 90
	actionGradient.Parent = action

	action.Activated:Connect(function()
		if isEquipped then
			return
		end

		if isOwned then
			onEquip(offer)
		elseif canBuy then
			onBuy(offer)
		end
	end)
end

function ShopController.new(context)
	return setmetatable({
		context = context or {},
	}, ShopController)
end

function ShopController:_openShop()
	self.context.screen:setShopMenuVisible(true)
	self.context.app:setStatus("Pickaxe Shop opened.")
end

function ShopController:_refresh(state)
	local screen = self.context.screen
	local app = self.context.app
	local profile = state.profile or {}
	local currencies = profile.currencies or {}
	local inventory = profile.inventory or {}
	local ownedPickaxes = inventory.pickaxes or {}
	local equippedPickaxeId = profile.progression and profile.progression.equippedPickaxeId or "stone_pickaxe"
	local equippedPickaxe = Pickaxes.catalog[equippedPickaxeId]
	local coinBalance = currencies.coins or 0

	screen:setShopText("Buy pickaxes at the forge. Better tiers swing faster, pull in more coins, and boost geode luck.")
	screen:setShopMenuSubtitle("Pick a bubbly upgrade and send your mining luck climbing.")
	screen:setShopMenuInfo(string.format(
		"Coin Pouch: %s\nCurrent Pickaxe Pal: %s",
		formatNumber(coinBalance),
		if equippedPickaxe ~= nil then equippedPickaxe.displayName else equippedPickaxeId
	))
	screen:setShopMenuRarities(collectRarityLabels())

	local offerContainer = screen:getShopOfferContainer()
	clearOfferRows(offerContainer)

	for _, offer in ipairs(collectOffers()) do
		local isOwned = ownedPickaxes[offer.id] == true
		local isEquipped = equippedPickaxeId == offer.id
		local isUpgrade = PickaxeRules.isStrictUpgrade(equippedPickaxeId, offer.id)
		local canBuy = not isOwned and isUpgrade and coinBalance >= offer.price
		local actionText = "Need coins"
		if isEquipped then
			actionText = "Equipped"
		elseif isOwned then
			actionText = "Equip"
		elseif not isUpgrade then
			actionText = "Old tier"
		elseif coinBalance >= offer.price then
			actionText = "Buy"
		end
		createOfferRow(
			offerContainer,
			offer,
			isOwned,
			isEquipped,
			canBuy,
			actionText,
			function(selectedOffer)
				local ok, result = app:invokeRemote(RemoteNames.RequestBuyPickaxe, selectedOffer.id)
				if ok and type(result) == "table" and result.ok == true then
					app:setStatus(string.format("%s bought and replaced your current pickaxe.", selectedOffer.displayName))
				else
					local errorText = type(result) == "table" and result.errorCode or result
					app:setStatus("Pickaxe purchase failed: " .. tostring(errorText))
				end
			end,
			function(selectedOffer)
				local ok, result = app:invokeRemote(RemoteNames.RequestEquipPickaxe, selectedOffer.id)
				if ok and type(result) == "table" and result.ok == true then
					app:setStatus(string.format("Equipped %s.", selectedOffer.displayName))
				else
					local errorText = type(result) == "table" and result.errorCode or result
					app:setStatus("Pickaxe equip failed: " .. tostring(errorText))
				end
			end
		)
	end
end

function ShopController:start()
	local app = self.context.app

	self.context.stateChanged:Connect(function(state)
		self:_refresh(state)
	end)

	self.context.screen.shop.closeButton.Activated:Connect(function()
		self.context.screen:setShopMenuVisible(false)
	end)

	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		if prompt ~= nil and prompt:IsA("ProximityPrompt") and prompt:GetAttribute(SHOP_PROMPT_ATTRIBUTE) == true then
			self:_openShop()
		end
	end)

	self.context.screen:setShopMenuVisible(false)
	self:_refresh(app:getState())
end

return ShopController
