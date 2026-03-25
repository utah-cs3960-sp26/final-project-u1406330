--!strict

local Panel = {}

local function applyStroke(parent: Instance, palette)
	local stroke = Instance.new("UIStroke")
	stroke.Color = palette.border
	stroke.Thickness = 1
	stroke.Transparency = 0.15
	stroke.Parent = parent
	return stroke
end

function Panel.createCard(parent: Instance, title: string, palette, layoutOrder: number?)
	local card = Instance.new("Frame")
	card.Name = title .. "Card"
	card.BackgroundColor3 = palette.background.panel
	card.BorderSizePixel = 0
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.Size = UDim2.new(1, 0, 0, 0)
	card.LayoutOrder = layoutOrder or 0
	card.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = card

	applyStroke(card, palette)

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 14)
	padding.PaddingBottom = UDim.new(0, 14)
	padding.PaddingLeft = UDim.new(0, 14)
	padding.PaddingRight = UDim.new(0, 14)
	padding.Parent = card

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.new(1, 0, 0, 24)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = title
	titleLabel.TextColor3 = palette.accentSoft
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextSize = 18
	titleLabel.Parent = card

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.Position = UDim2.new(0, 0, 0, 30)
	body.Size = UDim2.new(1, 0, 0, 0)
	body.Parent = card

	local bodyLayout = Instance.new("UIListLayout")
	bodyLayout.Padding = UDim.new(0, 10)
	bodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
	bodyLayout.Parent = body

	return {
		frame = card,
		body = body,
		title = titleLabel,
	}
end

function Panel.createLabel(parent: Instance, text: string, palette, layoutOrder: number?)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.Size = UDim2.new(1, 0, 0, 0)
	label.LayoutOrder = layoutOrder or 0
	label.Font = Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = palette.text
	label.TextSize = 15
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Parent = parent
	return label
end

function Panel.createButton(parent: Instance, text: string, palette, layoutOrder: number?)
	local button = Instance.new("TextButton")
	button.BackgroundColor3 = palette.accent
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.AutomaticSize = Enum.AutomaticSize.Y
	button.Size = UDim2.new(1, 0, 0, 36)
	button.LayoutOrder = layoutOrder or 0
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = palette.shadow
	button.TextSize = 15
	button.TextWrapped = true
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	return button
end

return Panel
