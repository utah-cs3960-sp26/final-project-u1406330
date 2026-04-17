--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Geodes = require(Shared.Config.Geodes)
local Resources = require(Shared.Config.Resources)
local Traits = require(Shared.Config.Traits)
local SizeRules = require(Shared.Domain.SizeRules)
local VaultMath = require(Shared.Domain.VaultMath)

local VaultController = {}
VaultController.__index = VaultController

local RESOURCE_SWATCH_COLORS = {
	quartz = Color3.fromRGB(230, 238, 245),
	amethyst = Color3.fromRGB(160, 100, 230),
	emerald_cluster = Color3.fromRGB(50, 190, 130),
	diamond_core = Color3.fromRGB(120, 220, 255),
	star_shard = Color3.fromRGB(255, 200, 60),
}

local function createRow(parent, titleText, detailText, tint, layoutOrder, itemKind, resourceTypeId)
	local isResource = itemKind == "resource"
	local bgColor = if isResource then Color3.fromRGB(248, 255, 250) else Color3.fromRGB(250, 248, 255)

	local row = Instance.new("Frame")
	row.Name = titleText .. "Row"
	row.BackgroundColor3 = bgColor
	row.BorderSizePixel = 0
	row.LayoutOrder = layoutOrder
	row.Size = UDim2.new(1, -8, 0, 92)
	row.ZIndex = 58
	row.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = row

	local stroke = Instance.new("UIStroke")
	stroke.Color = tint
	stroke.Thickness = 3
	stroke.Parent = row

	local swatchColor = tint
	if isResource and resourceTypeId ~= nil and RESOURCE_SWATCH_COLORS[resourceTypeId] ~= nil then
		swatchColor = RESOURCE_SWATCH_COLORS[resourceTypeId]
	end

	local swatch = Instance.new("Frame")
	swatch.Name = "Swatch"
	swatch.BackgroundColor3 = swatchColor
	swatch.BorderSizePixel = 0
	swatch.Position = UDim2.new(0, 12, 0.5, -24)
	swatch.Size = UDim2.new(0, 48, 0, 48)
	swatch.ZIndex = 59
	swatch.Parent = row

	if isResource then
		local swatchCorner = Instance.new("UICorner")
		swatchCorner.CornerRadius = UDim.new(0, 6)
		swatchCorner.Parent = swatch
		swatch.Rotation = 45

		local innerGem = Instance.new("Frame")
		innerGem.BackgroundColor3 = swatchColor:Lerp(Color3.fromRGB(255, 255, 255), 0.4)
		innerGem.BorderSizePixel = 0
		innerGem.AnchorPoint = Vector2.new(0.5, 0.5)
		innerGem.Position = UDim2.fromScale(0.5, 0.5)
		innerGem.Size = UDim2.new(0, 22, 0, 22)
		innerGem.ZIndex = 60
		innerGem.Parent = swatch

		local innerCorner = Instance.new("UICorner")
		innerCorner.CornerRadius = UDim.new(0, 4)
		innerCorner.Parent = innerGem
	else
		local swatchCorner = Instance.new("UICorner")
		swatchCorner.CornerRadius = UDim.new(0.5, 0)
		swatchCorner.Parent = swatch

		local innerCircle = Instance.new("Frame")
		innerCircle.BackgroundColor3 = swatchColor:Lerp(Color3.fromRGB(255, 255, 255), 0.35)
		innerCircle.BorderSizePixel = 0
		innerCircle.AnchorPoint = Vector2.new(0.5, 0.5)
		innerCircle.Position = UDim2.fromScale(0.5, 0.5)
		innerCircle.Size = UDim2.new(0, 24, 0, 24)
		innerCircle.ZIndex = 60
		innerCircle.Parent = swatch

		local innerCircleCorner = Instance.new("UICorner")
		innerCircleCorner.CornerRadius = UDim.new(0.5, 0)
		innerCircleCorner.Parent = innerCircle
	end

	local typeBadge = Instance.new("TextLabel")
	typeBadge.BackgroundColor3 = if isResource then Color3.fromRGB(210, 245, 225) else Color3.fromRGB(220, 215, 240)
	typeBadge.BorderSizePixel = 0
	typeBadge.Position = UDim2.new(0, 72, 0, 8)
	typeBadge.Size = UDim2.new(0, if isResource then 66 else 54, 0, 18)
	typeBadge.Font = Enum.Font.GothamBold
	typeBadge.Text = if isResource then "RESOURCE" else "GEODE"
	typeBadge.TextColor3 = if isResource then Color3.fromRGB(36, 100, 60) else Color3.fromRGB(70, 50, 110)
	typeBadge.TextSize = 10
	typeBadge.ZIndex = 59
	typeBadge.Parent = row

	local typeBadgeCorner = Instance.new("UICorner")
	typeBadgeCorner.CornerRadius = UDim.new(0, 6)
	typeBadgeCorner.Parent = typeBadge

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0, 72, 0, 28)
	title.Size = UDim2.new(1, -220, 0, 24)
	title.Font = Enum.Font.FredokaOne
	title.Text = titleText
	title.TextColor3 = Color3.fromRGB(71, 48, 20)
	title.TextSize = 20
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.ZIndex = 59
	title.Parent = row

	local detail = Instance.new("TextLabel")
	detail.BackgroundTransparency = 1
	detail.Position = UDim2.new(0, 72, 0, 53)
	detail.Size = UDim2.new(1, -220, 0, 30)
	detail.Font = Enum.Font.GothamBold
	detail.Text = detailText
	detail.TextColor3 = Color3.fromRGB(112, 84, 45)
	detail.TextSize = 13
	detail.TextWrapped = true
	detail.TextXAlignment = Enum.TextXAlignment.Left
	detail.ZIndex = 59
	detail.Parent = row

	return row
end

local function createActionButton(parent, text, color, xOffset)
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Position = UDim2.new(1, xOffset, 0.5, -17)
	button.Size = UDim2.new(0, 78, 0, 34)
	button.Font = Enum.Font.FredokaOne
	button.Text = text
	button.TextColor3 = Color3.fromRGB(48, 34, 14)
	button.TextSize = 16
	button.ZIndex = 60
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	return button
end

local function getGeodeLabel(geode)
	local definition = geode ~= nil and Geodes[geode.geodeTypeId] or nil
	return definition and definition.displayName or "Geode"
end

local function getResourceLabel(resource)
	local definition = resource ~= nil and Resources[resource.resourceTypeId] or nil
	local trait = resource ~= nil and Traits[resource.traitId or "none"] or nil
	local displayName = definition and definition.displayName or "Treasure"
	if trait ~= nil and trait.id ~= "none" then
		return trait.displayName .. " " .. displayName
	end
	return displayName
end

local function getSizeDetail(item)
	if type(item) ~= "table" then
		return "Size: Medium (1.00x)"
	end

	return "Size: " .. SizeRules.getDisplayText(item.sizeId, item.sizeValue)
end

function VaultController.new(context)
	return setmetatable({
		context = context or {},
	}, VaultController)
end

function VaultController:start()
	local screen = self.context.screen
	local app = self.context.app

	local function refresh(state)
		local profile = state.profile
		screen:clearVaultRows()

		local rows = {}
		for _, geodeId in ipairs(profile.geodeOrder or {}) do
			local geode = profile.geodesById[geodeId]
			if geode ~= nil then
				local definition = Geodes[geode.geodeTypeId]
				table.insert(rows, {
					kind = "geode",
					id = geode.id,
					title = getGeodeLabel(geode),
					detail = string.format(
						"%s %s",
						getSizeDetail(geode),
						if geode.placement ~= nil then "On plot. Crack it when ready or sell it." else "In Vault. Place it or sell it."
					),
					tint = definition and definition.displayColor or Color3.fromRGB(180, 190, 210),
					canPlace = geode.placement == nil,
					sellValue = VaultMath.getGeodeSellValue(definition),
					resourceTypeId = nil,
				})
			end
		end

		for _, resourceId in ipairs(profile.resourceOrder or {}) do
			local resource = profile.resourcesById[resourceId]
			if resource ~= nil then
				local definition = Resources[resource.resourceTypeId]
				local trait = Traits[resource.traitId or "none"] or Traits.none
				local sizeDefinition = SizeRules.resolveDefinition(resource.sizeId, resource.sizeValue)
				table.insert(rows, {
					kind = "resource",
					id = resource.id,
					title = getResourceLabel(resource),
					detail = string.format(
						"%s %s",
						getSizeDetail(resource),
						if resource.placement ~= nil then "On plot. Sell it anytime." else "In Vault. Place it or sell it."
					),
					tint = definition and definition.color or Color3.fromRGB(240, 240, 255),
					canPlace = resource.placement == nil and resource.stationId == nil,
					sellValue = VaultMath.getResourceSellValue(definition, trait, sizeDefinition),
					resourceTypeId = resource.resourceTypeId,
				})
			end
		end

		table.sort(rows, function(a, b)
			if a.kind == b.kind then
				return a.title < b.title
			end
			return a.kind < b.kind
		end)

		if #rows == 0 then
			local empty = Instance.new("TextLabel")
			empty.BackgroundTransparency = 1
			empty.Size = UDim2.new(1, -8, 0, 120)
			empty.Font = Enum.Font.FredokaOne
			empty.Text = "Mine geodes to fill this Vault."
			empty.TextColor3 = Color3.fromRGB(82, 52, 18)
			empty.TextSize = 26
			empty.TextWrapped = true
			empty.ZIndex = 58
			empty.Parent = screen:getVaultItemContainer()
			return
		end

		for index, rowData in ipairs(rows) do
			local row = createRow(
				screen:getVaultItemContainer(),
				rowData.title,
				string.format("%s Sell: %d coins", rowData.detail, rowData.sellValue),
				rowData.tint,
				index,
				rowData.kind,
				rowData.resourceTypeId
			)

			local place = createActionButton(row, "Place", Color3.fromRGB(122, 231, 184), -174)
			place.Active = rowData.canPlace
			place.AutoButtonColor = rowData.canPlace
			place.BackgroundColor3 = if rowData.canPlace then Color3.fromRGB(122, 231, 184) else Color3.fromRGB(180, 180, 180)
			place.Activated:Connect(function()
				if not rowData.canPlace then
					return
				end
				screen:setVaultVisible(false)
				if rowData.kind == "geode" then
					app:beginGeodePlacement(rowData.id)
				else
					app:beginResourcePlacement(rowData.id)
				end
			end)

			local sell = createActionButton(row, "Sell", Color3.fromRGB(255, 195, 91), -88)
			sell.Activated:Connect(function()
				app:requestSellVaultItem(rowData.kind, rowData.id)
			end)
		end
	end

	self.context.stateChanged:Connect(refresh)
	refresh(app:getState())
end

return VaultController
