--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Panel = require(script.Parent.Parent.Components.Panel)

local RootScreen = {}
RootScreen.__index = RootScreen

local SHOP_BASE_Z_INDEX = 60
local VAULT_BASE_Z_INDEX = 55
local POPUP_Z_INDEX = 80

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
	reopenCorner.CornerRadius = UDim.new(0, 8)
	reopenCorner.Parent = reopenButton

	local reopenStroke = Instance.new("UIStroke")
	reopenStroke.Color = palette.border
	reopenStroke.Thickness = 1
	reopenStroke.Transparency = 0.15
	reopenStroke.Parent = reopenButton

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

	local vaultItemsLayout = Instance.new("UIListLayout")
	vaultItemsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	vaultItemsLayout.Padding = UDim.new(0, 12)
	vaultItemsLayout.Parent = vaultItems

	local shopOverlay = Instance.new("Frame")
	shopOverlay.Name = "ShopOverlay"
	shopOverlay.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
	shopOverlay.BackgroundTransparency = 0.25
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
	shopPanel.BackgroundColor3 = palette.background.panel
	shopPanel.BorderSizePixel = 0
	shopPanel.Position = UDim2.fromScale(0.5, 0.5)
	shopPanel.Size = UDim2.new(0.92, 0, 0.84, 0)
	shopPanel.ZIndex = SHOP_BASE_Z_INDEX + 1
	shopPanel.Parent = shopOverlay

	local shopPanelCorner = Instance.new("UICorner")
	shopPanelCorner.CornerRadius = UDim.new(0, 8)
	shopPanelCorner.Parent = shopPanel

	local shopPanelStroke = Instance.new("UIStroke")
	shopPanelStroke.Color = palette.border
	shopPanelStroke.Thickness = 1
	shopPanelStroke.Transparency = 0.1
	shopPanelStroke.Parent = shopPanel

	local shopPanelConstraint = Instance.new("UISizeConstraint")
	shopPanelConstraint.MinSize = Vector2.new(320, 420)
	shopPanelConstraint.MaxSize = Vector2.new(560, 680)
	shopPanelConstraint.Parent = shopPanel

	local shopPadding = Instance.new("UIPadding")
	shopPadding.PaddingTop = UDim.new(0, 16)
	shopPadding.PaddingBottom = UDim.new(0, 16)
	shopPadding.PaddingLeft = UDim.new(0, 16)
	shopPadding.PaddingRight = UDim.new(0, 16)
	shopPadding.Parent = shopPanel

	local shopLayout = Instance.new("UIListLayout")
	shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
	shopLayout.Padding = UDim.new(0, 12)
	shopLayout.Parent = shopPanel

	local shopHeader = Instance.new("Frame")
	shopHeader.Name = "ShopHeader"
	shopHeader.BackgroundTransparency = 1
	shopHeader.LayoutOrder = 1
	shopHeader.Size = UDim2.new(1, 0, 0, 56)
	shopHeader.Parent = shopPanel

	local shopTitle = Instance.new("TextLabel")
	shopTitle.BackgroundTransparency = 1
	shopTitle.Size = UDim2.new(1, -56, 0, 24)
	shopTitle.Font = Enum.Font.GothamBold
	shopTitle.Text = "Pickaxe Shop"
	shopTitle.TextColor3 = palette.text
	shopTitle.TextSize = 22
	shopTitle.TextXAlignment = Enum.TextXAlignment.Left
	shopTitle.Parent = shopHeader

	local shopSubtitle = Instance.new("TextLabel")
	shopSubtitle.BackgroundTransparency = 1
	shopSubtitle.Position = UDim2.new(0, 0, 0, 28)
	shopSubtitle.Size = UDim2.new(1, -56, 0, 20)
	shopSubtitle.Font = Enum.Font.Gotham
	shopSubtitle.Text = "Press E at the forge to open the shop."
	shopSubtitle.TextColor3 = palette.muted
	shopSubtitle.TextSize = 14
	shopSubtitle.TextXAlignment = Enum.TextXAlignment.Left
	shopSubtitle.TextWrapped = true
	shopSubtitle.Parent = shopHeader

	local shopClose = Instance.new("TextButton")
	shopClose.Name = "CloseShopButton"
	shopClose.AnchorPoint = Vector2.new(1, 0)
	shopClose.AutoButtonColor = true
	shopClose.BackgroundColor3 = palette.accent
	shopClose.BorderSizePixel = 0
	shopClose.Position = UDim2.new(1, 0, 0, 0)
	shopClose.Size = UDim2.new(0, 40, 0, 32)
	shopClose.Font = Enum.Font.GothamBold
	shopClose.Text = "X"
	shopClose.TextColor3 = palette.shadow
	shopClose.TextSize = 18
	shopClose.ZIndex = 62
	shopClose.Parent = shopHeader

	local shopCloseCorner = Instance.new("UICorner")
	shopCloseCorner.CornerRadius = UDim.new(0, 8)
	shopCloseCorner.Parent = shopClose

	local shopCloseStroke = Instance.new("UIStroke")
	shopCloseStroke.Color = palette.border
	shopCloseStroke.Thickness = 1
	shopCloseStroke.Transparency = 0.15
	shopCloseStroke.Parent = shopClose

	local shopInfo = Instance.new("Frame")
	shopInfo.Name = "ShopInfo"
	shopInfo.BackgroundColor3 = palette.background.panelAlt
	shopInfo.BorderSizePixel = 0
	shopInfo.LayoutOrder = 2
	shopInfo.Size = UDim2.new(1, 0, 0, 64)
	shopInfo.Parent = shopPanel

	local shopInfoCorner = Instance.new("UICorner")
	shopInfoCorner.CornerRadius = UDim.new(0, 8)
	shopInfoCorner.Parent = shopInfo

	local shopInfoStroke = Instance.new("UIStroke")
	shopInfoStroke.Color = palette.border
	shopInfoStroke.Thickness = 1
	shopInfoStroke.Transparency = 0.18
	shopInfoStroke.Parent = shopInfo

	local shopInfoPadding = Instance.new("UIPadding")
	shopInfoPadding.PaddingTop = UDim.new(0, 10)
	shopInfoPadding.PaddingBottom = UDim.new(0, 10)
	shopInfoPadding.PaddingLeft = UDim.new(0, 12)
	shopInfoPadding.PaddingRight = UDim.new(0, 12)
	shopInfoPadding.Parent = shopInfo

	local shopInfoLabel = Instance.new("TextLabel")
	shopInfoLabel.BackgroundTransparency = 1
	shopInfoLabel.Size = UDim2.new(1, 0, 1, 0)
	shopInfoLabel.Font = Enum.Font.Gotham
	shopInfoLabel.Text = "Loading pickaxe stock..."
	shopInfoLabel.TextColor3 = palette.text
	shopInfoLabel.TextSize = 14
	shopInfoLabel.TextWrapped = true
	shopInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
	shopInfoLabel.TextYAlignment = Enum.TextYAlignment.Top
	shopInfoLabel.Parent = shopInfo

	local shopOfferScroll = Instance.new("ScrollingFrame")
	shopOfferScroll.Name = "ShopOffers"
	shopOfferScroll.BackgroundTransparency = 1
	shopOfferScroll.BorderSizePixel = 0
	shopOfferScroll.LayoutOrder = 3
	shopOfferScroll.ScrollBarThickness = 6
	shopOfferScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	shopOfferScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	shopOfferScroll.Size = UDim2.new(1, 0, 0, 214)
	shopOfferScroll.ZIndex = SHOP_BASE_Z_INDEX + 2
	shopOfferScroll.Parent = shopPanel

	local shopOfferPadding = Instance.new("UIPadding")
	shopOfferPadding.PaddingBottom = UDim.new(0, 4)
	shopOfferPadding.Parent = shopOfferScroll

	local shopOfferLayout = Instance.new("UIListLayout")
	shopOfferLayout.SortOrder = Enum.SortOrder.LayoutOrder
	shopOfferLayout.Padding = UDim.new(0, 10)
	shopOfferLayout.Parent = shopOfferScroll

	local rarityFrame = Instance.new("Frame")
	rarityFrame.Name = "RarityLadder"
	rarityFrame.BackgroundTransparency = 1
	rarityFrame.LayoutOrder = 4
	rarityFrame.Size = UDim2.new(1, 0, 0, 128)
	rarityFrame.Parent = shopPanel

	local rarityTitle = Instance.new("TextLabel")
	rarityTitle.BackgroundTransparency = 1
	rarityTitle.Size = UDim2.new(1, 0, 0, 20)
	rarityTitle.Font = Enum.Font.GothamBold
	rarityTitle.Text = "Pickaxe Tiers"
	rarityTitle.TextColor3 = palette.accentSoft
	rarityTitle.TextSize = 16
	rarityTitle.TextXAlignment = Enum.TextXAlignment.Left
	rarityTitle.Parent = rarityFrame

	local rarityGrid = Instance.new("Frame")
	rarityGrid.Name = "RarityGrid"
	rarityGrid.BackgroundTransparency = 1
	rarityGrid.Position = UDim2.new(0, 0, 0, 26)
	rarityGrid.Size = UDim2.new(1, 0, 1, -26)
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
		rarityChip.BackgroundColor3 = palette.background.panelAlt
		rarityChip.BorderSizePixel = 0
		rarityChip.Font = Enum.Font.GothamBold
		rarityChip.LayoutOrder = index
		rarityChip.Text = rarityName
		rarityChip.TextColor3 = palette.text
		rarityChip.TextSize = 13
		rarityChip.TextWrapped = false
		rarityChip.ZIndex = SHOP_BASE_Z_INDEX + 2
		rarityChip.Parent = rarityGrid

		local chipCorner = Instance.new("UICorner")
		chipCorner.CornerRadius = UDim.new(0, 8)
		chipCorner.Parent = rarityChip

		local chipStroke = Instance.new("UIStroke")
		chipStroke.Color = palette.border
		chipStroke.Thickness = 1
		chipStroke.Transparency = 0.2
		chipStroke.Parent = rarityChip

		table.insert(rarityLabels, rarityChip)
	end

	applyGuiZIndex(shopPanel, SHOP_BASE_Z_INDEX + 2)
	shopPanel.ZIndex = SHOP_BASE_Z_INDEX + 1
	shopOverlay.ZIndex = SHOP_BASE_Z_INDEX
	shopClose.ZIndex = SHOP_BASE_Z_INDEX + 4

	local miningPopupContainer = Instance.new("Frame")
	miningPopupContainer.Name = "MiningPopups"
	miningPopupContainer.AnchorPoint = Vector2.new(0.5, 0)
	miningPopupContainer.BackgroundTransparency = 1
	miningPopupContainer.BorderSizePixel = 0
	miningPopupContainer.Position = UDim2.new(0.5, 0, 0.22, 0)
	miningPopupContainer.Size = UDim2.new(0, 420, 0, 180)
	miningPopupContainer.ZIndex = POPUP_Z_INDEX
	miningPopupContainer.Parent = screenGui

	local miningPopupConstraint = Instance.new("UISizeConstraint")
	miningPopupConstraint.MinSize = Vector2.new(240, 120)
	miningPopupConstraint.MaxSize = Vector2.new(520, 220)
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
			offers = shopOfferScroll,
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

	shopClose.Activated:Connect(function()
		shopOverlay.Visible = false
	end)

	vaultButton.Activated:Connect(function()
		vaultOverlay.Visible = true
	end)

	vaultClose.Activated:Connect(function()
		vaultOverlay.Visible = false
	end)

	self:setShopMenuVisible(false)
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
	local popup = Instance.new("TextLabel")
	popup.Name = "MiningPopup"
	popup.AnchorPoint = Vector2.new(0.5, 0)
	popup.BackgroundColor3 = Color3.fromRGB(18, 17, 24)
	popup.BackgroundTransparency = 0.08
	popup.BorderSizePixel = 0
	popup.Size = UDim2.new(0.92, 0, 0, 48)
	popup.Font = Enum.Font.GothamBlack
	popup.Text = tostring(text)
	popup.TextColor3 = Color3.fromRGB(255, 246, 196)
	popup.TextSize = 24
	popup.TextWrapped = true
	popup.ZIndex = POPUP_Z_INDEX
	popup.Parent = self.miningPopupContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = popup

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(109, 231, 255)
	stroke.Thickness = 2
	stroke.Transparency = 0.05
	stroke.Parent = popup

	task.delay(1.4, function()
		if popup.Parent == nil then
			return
		end

		local tween = TweenService:Create(
			popup,
			TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				BackgroundTransparency = 1,
				TextTransparency = 1,
			}
		)
		tween:Play()
		tween.Completed:Connect(function()
			popup:Destroy()
		end)
	end)
end

function RootScreen:setShopMenuVisible(visible)
	self.shop.overlay.Visible = visible
end

function RootScreen:setVaultVisible(visible)
	self.vault.overlay.Visible = visible
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
		rarityLabel.Text = labels[index] or ""
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



