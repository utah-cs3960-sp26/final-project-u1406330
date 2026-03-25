--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Shops = require(Shared.Config.Shops)

local ShopController = {}
ShopController.__index = ShopController

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

local function formatDuration(seconds: number): string
	local safeSeconds = math.max(0, math.floor(seconds))
	local hours = math.floor(safeSeconds / 3600)
	local minutes = math.floor((safeSeconds % 3600) / 60)
	local remaining = safeSeconds % 60
	return string.format("%02d:%02d:%02d", hours, minutes, remaining)
end

function ShopController.new(context)
	return setmetatable({
		context = context or {},
	}, ShopController)
end

function ShopController:start()
	local screen = self.context.screen
	local app = self.context.app
	local starterOffer = Shops.starterOffers[1]

	local function profileCoins(state)
		return state.profile.currencies.coins or 0
	end

	local function refresh(state)
		local shopState = state.shop
		local currentOffer = shopState.currentOffer or shopState.starterOffer or starterOffer
		local secondsRemaining = shopState.secondsRemaining or 0

		screen:setShopText(string.format(
			"Limited offer: %s\nPrice: %s %s\nRefreshes in: %s\nStarter geodes stay available from the button below.",
			currentOffer.displayName or currentOffer.offerId or "Unknown Offer",
			formatNumber(currentOffer.price or starterOffer.price),
			string.lower(currentOffer.currency or starterOffer.currency or "coins"),
			formatDuration(secondsRemaining)
		))

		screen:setBuyStarterButton(
			(profileCoins(state) >= starterOffer.price),
			string.format("Buy Starter Geode (%s coins)", formatNumber(starterOffer.price))
		)
	end

	screen.buttons.buyStarter.Activated:Connect(function()
		app:requestBuyStarterGeode()
	end)

	self.context.stateChanged:Connect(refresh)
	refresh(app:getState())
end

return ShopController

