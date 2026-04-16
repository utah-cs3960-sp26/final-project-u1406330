--!strict

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Pickaxes = require(Shared.Config.Pickaxes)
local RemoteNames = require(Shared.Net.RemoteNames)

local ShopController = {}
ShopController.__index = ShopController

local SHOP_PROMPT_ATTRIBUTE = "GemFactoryShopPrompt"
local SHOP_ROW_Z_INDEX = 62
local SHOP_TEXT_Z_INDEX = 63
local SHOP_BUTTON_Z_INDEX = 64

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

local function createOfferRow(parent: Instance, palette, offer, isOwned: boolean, isEquipped: boolean, canAfford: boolean, onBuy, onEquip)
	local row = Instance.new("Frame")
	row.Name = offer.displayName .. "Row"
	row.BackgroundColor3 = palette.background.panelAlt
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, 102)
	row.ZIndex = SHOP_ROW_Z_INDEX
	row.Parent = parent

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent = row

	local rowStroke = Instance.new("UIStroke")
	rowStroke.Color = palette.border
	rowStroke.Thickness = 1
	rowStroke.Transparency = 0.15
	rowStroke.Parent = row

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = row

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -132, 0, 22)
	title.Font = Enum.Font.GothamBold
	title.Text = offer.displayName
	title.TextColor3 = palette.text
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = SHOP_TEXT_Z_INDEX
	title.Parent = row

	local subtitle = Instance.new("TextLabel")
	subtitle.BackgroundTransparency = 1
	subtitle.Position = UDim2.new(0, 0, 0, 24)
	subtitle.Size = UDim2.new(1, -132, 0, 46)
	subtitle.Font = Enum.Font.Gotham
	subtitle.Text = string.format(
		"%s pickaxe\nCoins %d-%d | Geode chance %d%%",
		offer.rarity,
		offer.coinRewardMin,
		offer.coinRewardMax,
		offer.geodeChance
	)
	subtitle.TextColor3 = palette.muted
	subtitle.TextSize = 14
	subtitle.TextWrapped = true
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.TextYAlignment = Enum.TextYAlignment.Top
	subtitle.ZIndex = SHOP_TEXT_Z_INDEX
	subtitle.Parent = row

	local price = Instance.new("TextLabel")
	price.BackgroundTransparency = 1
	price.Position = UDim2.new(0, 0, 0, 76)
	price.Size = UDim2.new(1, -132, 0, 16)
	price.Font = Enum.Font.Gotham
	price.Text = if isOwned then "Owned" else string.format("%s %s", formatNumber(offer.price), string.lower(offer.currency))
	price.TextColor3 = palette.accentSoft
	price.TextSize = 12
	price.TextXAlignment = Enum.TextXAlignment.Left
	price.ZIndex = SHOP_TEXT_Z_INDEX
	price.Parent = row

	local action = Instance.new("TextButton")
	action.Name = "ActionButton"
	action.AnchorPoint = Vector2.new(1, 0.5)
	action.AutoButtonColor = not isEquipped and (isOwned or canAfford)
	action.Active = not isEquipped and (isOwned or canAfford)
	action.BackgroundColor3 = if isEquipped then Color3.fromRGB(120, 120, 120) elseif isOwned or canAfford then palette.accent else Color3.fromRGB(110, 110, 110)
	action.BorderSizePixel = 0
	action.Position = UDim2.new(1, 0, 0.5, 0)
	action.Size = UDim2.new(0, 112, 0, 40)
	action.Font = Enum.Font.GothamBold
	action.Text = if isEquipped then "Equipped" elseif isOwned then "Equip" else if canAfford then "Buy" else "Need coins"
	action.TextColor3 = palette.shadow
	action.TextSize = 14
	action.ZIndex = SHOP_BUTTON_Z_INDEX
	action.Parent = row

	local actionCorner = Instance.new("UICorner")
	actionCorner.CornerRadius = UDim.new(0, 8)
	actionCorner.Parent = action

	action.Activated:Connect(function()
		if isEquipped then
			return
		end

		if isOwned then
			onEquip(offer)
		elseif canAfford then
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
	local coinBalance = currencies.coins or 0

	screen:setShopText("Pickaxes are sold at the forge. Better pickaxes improve coin payouts and rare geode odds when mining.")
	screen:setShopMenuSubtitle("Press E at the forge to browse pickaxes.")
	screen:setShopMenuInfo(string.format("Coins: %s | Equipped: %s", formatNumber(coinBalance), equippedPickaxeId))
	screen:setShopMenuRarities(collectRarityLabels())

	local offerContainer = screen:getShopOfferContainer()
	clearOfferRows(offerContainer)

	for _, offer in ipairs(collectOffers()) do
		local isOwned = ownedPickaxes[offer.id] == true
		local isEquipped = equippedPickaxeId == offer.id
		createOfferRow(
			offerContainer,
			app.context.palette,
			offer,
			isOwned,
			isEquipped,
			coinBalance >= offer.price,
			function(selectedOffer)
				local ok, result = app:invokeRemote(RemoteNames.RequestBuyPickaxe, selectedOffer.id)
				if ok and type(result) == "table" and result.ok == true then
					app:setStatus(string.format("%s bought and added to your backpack.", selectedOffer.displayName))
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
