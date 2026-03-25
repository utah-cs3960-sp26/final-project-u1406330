--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Shops = require(Shared.Config.Shops)
local ShopRotation = require(Shared.Domain.ShopRotation)
local TableUtil = require(Shared.Util.TableUtil)

local ShopService = {}
ShopService.__index = ShopService

function ShopService.new(dependencies)
	return setmetatable({
		dependencies = dependencies or {},
	}, ShopService)
end

function ShopService:getHourlyOffer(nowUnix)
	local offers = Shops.hourlyRotation
	local state = ShopRotation.getHourlyState(nowUnix, #offers)
	return offers[state.index], state.index, state.secondsRemaining
end

function ShopService:getOffer(offerId, nowUnix)
	for _, offer in ipairs(Shops.starterOffers) do
		if offer.offerId == offerId then
			local copy = TableUtil.deepCopy(offer)
			copy.source = "starter"
			return copy
		end
	end

	local hourlyOffer, hourlyIndex, secondsRemaining = self:getHourlyOffer(nowUnix)
	if hourlyOffer ~= nil and hourlyOffer.offerId == offerId then
		local copy = TableUtil.deepCopy(hourlyOffer)
		copy.source = "hourly"
		copy.rotationIndex = hourlyIndex
		copy.secondsRemaining = secondsRemaining
		return copy
	end

	return nil
end

function ShopService:getShopState(nowUnix)
	local hourlyOffer, hourlyIndex, secondsRemaining = self:getHourlyOffer(nowUnix)
	local currentHourlyOffer = nil
	if hourlyOffer ~= nil then
		currentHourlyOffer = TableUtil.deepCopy(hourlyOffer)
		currentHourlyOffer.source = "hourly"
		currentHourlyOffer.rotationIndex = hourlyIndex
		currentHourlyOffer.secondsRemaining = secondsRemaining
	end

	return {
		starterOffer = TableUtil.deepCopy(Shops.starterOffers[1]),
		currentOffer = currentHourlyOffer,
		offerIndex = hourlyIndex,
		secondsRemaining = secondsRemaining,
	}
end

function ShopService:start()
	print("[GemFactory] ShopService ready")
end

return ShopService

