--!strict

-- Screen-construction module for Root Screen that builds the main client HUD and exposes imperative UI hooks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Geodes = require(Shared.Config.Geodes)
local Resources = require(Shared.Config.Resources)
local Traits = require(Shared.Config.Traits)
local GeodePresentation = require(Shared.Domain.GeodePresentation)
local RewardPresentation = require(Shared.Domain.RewardPresentation)
local Panel = require(script.Parent.Parent.Components.Panel)

local RootScreen = {}
RootScreen.__index = RootScreen

local SHOP_BASE_Z_INDEX = 60
local VAULT_BASE_Z_INDEX = 55
local POPUP_Z_INDEX = 80
local POPUP_QUEUE_LIMIT = 6
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

	self:setShopMenuVisible(false)
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
	end

	return spec
end

local function makePopup(parent: Instance, backgroundColor: Color3, strokeColor: Color3, width: number, height: number)
	local popup = Instance.new("Frame")
	popup.Name = "CelebrationPopup"
	popup.AnchorPoint = Vector2.new(0.5, 0)
	popup.BackgroundColor3 = backgroundColor
	popup.BorderSizePixel = 0
	popup.ClipsDescendants = true
	popup.Position = UDim2.new(0.5, 0, 0, 0)
	popup.Size = UDim2.new(0, width, 0, height)
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
		local width = if isCoin then 160 elseif spec.compact == true then 300 elseif spec.showSlotMachine == true then 460 else 360
		local height = if isCoin then 36 elseif spec.compact == true then 68 elseif spec.showSlotMachine == true then 190 else 104
		if spec.kind == "geode_discovery" then
			local ri = math.clamp(spec.rarityIndex or 1, 1, 10)
			width = math.clamp(320 + (ri - 1) * 22, 320, 520)
			height = math.clamp(110 + (ri - 1) * 18, 110, 280)
		elseif spec.kind == "attribute" then
			height = 210
		elseif spec.kind == "resource" then
			height = if spec.showSlotMachine == true then 230 else 120
		elseif spec.kind == "geode" then
			height = if spec.showSlotMachine == true then 230 else 120
		end
		if spec.waitForClick == true then
			height += 34
		end

		local popup = makePopup(self.miningPopupContainer, tone.background, tone.accent, width, height)
		if isCoin then
			local popupStroke = popup:FindFirstChildWhichIsA("UIStroke")
			if popupStroke ~= nil then
				popupStroke:Destroy()
			end
			popup.BackgroundTransparency = 0.15
			local randX = 0.5 + (math.random() - 0.5) * 0.3
			local randY = math.random() * 0.08
			popup.Position = UDim2.new(randX, 0, 0, randY)
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
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Parent = popup

		local titleText = if isCoin then spec.headline else string.upper(spec.headline)
		local titleFontSize = if isCoin then 16 elseif spec.compact == true then 18 else 22
		if spec.kind == "geode_discovery" then
			local ri = math.clamp(spec.rarityIndex or 1, 1, 10)
			titleFontSize = math.clamp(24 + (ri - 1) * 3, 24, 48)
		end
		local titleHeight = if spec.compact == true then 22 else math.clamp(titleFontSize + 4, 24, 54)
		local title = createTextLabel(popup, titleText, titleFontSize, spec.textColor or tone.text, titleHeight)
		title.LayoutOrder = 1

		local reelRow
		local reelFinished = true
		local primaryLabel
		local detailLabel
		local badgeLabel
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

				local singleReel, singleReelLabel = createReel(reelRow, tone, "...")
				singleReel.Size = UDim2.new(1, 0, 1, 0)

				reelFinished = false
				task.spawn(function()
					local spinWords = spec.reelWords or GEODE_RARITY_ORDER
					local totalSteps = math.max(12, 8 + (spec.rarityIndex or 1) * 3)
					for spinStep = 1, totalSteps do
						local progress = spinStep / totalSteps
						local stepDelay = 0.06 + progress * 0.14
						local wordIndex = ((spinStep) % #spinWords) + 1
						singleReelLabel.Text = tostring(spinWords[wordIndex])
						task.wait(stepDelay)
					end
					singleReelLabel.Text = tostring(spec.reelFinal or spec.primary)
					reelFinished = true
					revealResolvedPopupText()
				end)
			end

			primaryLabel = createTextLabel(
				popup,
				if hideResolvedRevealText then "" else spec.primary,
				if spec.showSlotMachine == true then 26 else 28,
				spec.textColor or tone.text,
				if spec.showSlotMachine == true then 32 else 34
			)
			primaryLabel.LayoutOrder = if spec.showSlotMachine == true then 3 else 2
			primaryLabel.Visible = not hideResolvedRevealText

			if spec.detail ~= nil or spec.rarityLabel ~= nil then
				detailLabel = createTextLabel(
					popup,
					if hideResolvedRevealText then "" else resolvedDetailText,
					18,
					tone.text,
					if spec.showSlotMachine == true then 24 else 22
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
			local continueButton = Instance.new("TextButton")
			continueButton.Name = "CelebrationContinueButton"
			continueButton.AutoButtonColor = false
			continueButton.BackgroundTransparency = 1
			continueButton.BorderSizePixel = 0
			continueButton.Size = UDim2.new(1, 0, 1, 0)
			continueButton.Font = Enum.Font.FredokaOne
			continueButton.Text = ""
			continueButton.ZIndex = POPUP_Z_INDEX + 3
			continueButton.Parent = popup

			local continueLabel = Instance.new("TextLabel")
			continueLabel.Name = "CelebrationContinuePrompt"
			continueLabel.Active = false
			continueLabel.BackgroundTransparency = 1
			continueLabel.Size = UDim2.new(1, 0, 0, 22)
			continueLabel.Font = Enum.Font.FredokaOne
			continueLabel.Text = "Click anywhere to continue..."
			continueLabel.TextColor3 = tone.text
			continueLabel.TextSize = 14
			continueLabel.TextTransparency = 0.3
			continueLabel.ZIndex = POPUP_Z_INDEX + 4
			continueLabel.LayoutOrder = 99
			continueLabel.Parent = popup

			local clicked = false
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
						continueLabel.TextTransparency = 0.3 + math.sin(t * math.pi) * 0.4
						task.wait(0.04)
					end
				end
			end)

			while not clicked do
				task.wait(0.05)
			end

			inputConnection:Disconnect()
			continueButton:Destroy()
			continueLabel:Destroy()
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
