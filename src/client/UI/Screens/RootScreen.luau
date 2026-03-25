--!strict

local Players = game:GetService("Players")

local Panel = require(script.Parent.Parent.Components.Panel)

local RootScreen = {}
RootScreen.__index = RootScreen

function RootScreen.new(context)
	local palette = context.palette
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GemFactoryHud"
	screenGui.IgnoreGuiInset = false
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 50
	screenGui.Parent = playerGui

	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.AnchorPoint = Vector2.new(1, 0)
	backdrop.BackgroundColor3 = palette.background.page
	backdrop.BorderSizePixel = 0
	backdrop.Position = UDim2.new(1, -20, 0, 20)
	backdrop.Size = UDim2.new(0, 420, 1, -40)
	backdrop.Parent = screenGui

	local backdropCorner = Instance.new("UICorner")
	backdropCorner.CornerRadius = UDim.new(0, 18)
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
	headerCorner.CornerRadius = UDim.new(0, 18)
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
	collapseCorner.CornerRadius = UDim.new(0, 10)
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

	local shop = Panel.createCard(scroll, "Hourly Shop", palette, 2)
	local shopLabel = Panel.createLabel(shop.body, "Loading shop rotation...", palette, 1)
	local buyStarter = Panel.createButton(shop.body, "Buy Starter Geode", palette, 2)

	local geode = Panel.createCard(scroll, "Geode Inventory", palette, 3)
	local geodeLabel = Panel.createLabel(geode.body, "Waiting for geode data...", palette, 1)
	local placeGeode = Panel.createButton(geode.body, "Place Next Geode", palette, 2)
	local openReadyGeodes = Panel.createButton(geode.body, "Open Ready Geode", palette, 3)

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
	reopenButton.AnchorPoint = Vector2.new(1, 0)
	reopenButton.AutoButtonColor = true
	reopenButton.BackgroundColor3 = palette.accent
	reopenButton.BorderSizePixel = 0
	reopenButton.Position = UDim2.new(1, -20, 0, 20)
	reopenButton.Size = UDim2.new(0, 170, 0, 44)
	reopenButton.Visible = false
	reopenButton.Font = Enum.Font.GothamBold
	reopenButton.Text = "Open Gem HUD"
	reopenButton.TextColor3 = palette.shadow
	reopenButton.TextSize = 16
	reopenButton.Parent = screenGui

	local reopenCorner = Instance.new("UICorner")
	reopenCorner.CornerRadius = UDim.new(0, 12)
	reopenCorner.Parent = reopenButton

	local reopenStroke = Instance.new("UIStroke")
	reopenStroke.Color = palette.border
	reopenStroke.Thickness = 1
	reopenStroke.Transparency = 0.15
	reopenStroke.Parent = reopenButton

	local self = setmetatable({
		gui = screenGui,
		backdrop = backdrop,
		scroll = scroll,
		reopenButton = reopenButton,
		labels = {
			status = status,
			overview = overviewLabel,
			shop = shopLabel,
			geode = geodeLabel,
			daily = dailyLabel,
			offline = offlineLabel,
			plot = plotLabel,
			placement = placementLabel,
			notifications = notificationsLabel,
		},
		buttons = {
			buyStarter = buyStarter,
			placeGeode = placeGeode,
			openReadyGeodes = openReadyGeodes,
			claimDaily = claimDaily,
			claimOffline = claimOffline,
			placeStarterStation = placeStarterStation,
		},
		buttonColors = {
			buyStarter = buyStarter.BackgroundColor3,
			placeGeode = placeGeode.BackgroundColor3,
			openReadyGeodes = openReadyGeodes.BackgroundColor3,
			claimDaily = claimDaily.BackgroundColor3,
			claimOffline = claimOffline.BackgroundColor3,
			placeStarterStation = placeStarterStation.BackgroundColor3,
		},
		isOpen = true,
	}, RootScreen)

	local function setOpen(isOpen)
		self.isOpen = isOpen
		self.backdrop.Visible = isOpen
		self.reopenButton.Visible = not isOpen
	end

	collapseButton.Activated:Connect(function()
		setOpen(false)
	end)

	reopenButton.Activated:Connect(function()
		setOpen(true)
	end)

	self:setPlaceGeodeButton(false, "Place Next Geode")
	self:setOpenReadyGeodeButton(false, "Open Ready Geode")
	self:setOfflineButtonState(false, "Claim Offline Cache")
	self:setPlaceStarterStationButton(true, "Place Starter Station")
	return self
end

function RootScreen:setStatusText(text)
	self.labels.status.Text = text
end

function RootScreen:setOverviewText(text)
	self.labels.overview.Text = text
end

function RootScreen:setShopText(text)
	self.labels.shop.Text = text
end

function RootScreen:setGeodeText(text)
	self.labels.geode.Text = text
end

function RootScreen:setPlaceGeodeButton(enabled, text)
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

function RootScreen:setBuyStarterButton(enabled, text)
	self.buttons.buyStarter.Active = enabled
	self.buttons.buyStarter.AutoButtonColor = enabled
	self.buttons.buyStarter.Text = text
	self.buttons.buyStarter.BackgroundColor3 = if enabled then self.buttonColors.buyStarter else Color3.fromRGB(120, 120, 120)
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



