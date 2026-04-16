--!strict

local PickaxeModelBuilder = {}

local MODEL_VERSION = 2
local HANDLE_COLOR = Color3.fromRGB(60, 45, 38)
local COLLAR_COLOR = Color3.fromRGB(91, 76, 68)
local DEFAULT_HEAD_COLOR = Color3.fromRGB(155, 164, 176)
local MODEL_PART_ATTRIBUTE = "GemFactoryPickaxeModelPart"

local function prepPart(part: BasePart)
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
end

local function clearExistingModel(tool: Tool)
	for _, child in ipairs(tool:GetChildren()) do
		if child:IsA("BasePart") or child:IsA("WeldConstraint") then
			child:Destroy()
		end
	end
end

local function weldToHandle(handle: BasePart, part: BasePart)
	local weld = Instance.new("WeldConstraint")
	weld.Name = part.Name .. "_Weld"
	weld.Part0 = handle
	weld.Part1 = part
	weld.Parent = handle
end

local function createPart(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	prepPart(part)
	part:SetAttribute(MODEL_PART_ATTRIBUTE, true)
	part.Parent = parent
	return part
end

local function createWedge(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3): WedgePart
	local wedge = Instance.new("WedgePart")
	wedge.Name = name
	wedge.Size = size
	wedge.CFrame = cframe
	wedge.Color = color
	wedge.Material = Enum.Material.Metal
	prepPart(wedge)
	wedge:SetAttribute(MODEL_PART_ATTRIBUTE, true)
	wedge.Parent = parent
	return wedge
end

function PickaxeModelBuilder.addHeldPickaxe(tool: Tool, definition: any?)
	clearExistingModel(tool)

	local headColor = DEFAULT_HEAD_COLOR
	if type(definition) == "table" and typeof(definition.displayColor) == "Color3" then
		headColor = definition.displayColor
	end

	local handle = createPart(
		tool,
		"Handle",
		Vector3.new(0.32, 3.45, 0.32),
		CFrame.new(0, -0.08, 0),
		HANDLE_COLOR,
		Enum.Material.Wood
	)

	local gripWrap = createPart(
		tool,
		"LowerGripWrap",
		Vector3.new(0.4, 0.62, 0.4),
		CFrame.new(0, -1.15, 0),
		COLLAR_COLOR,
		Enum.Material.Wood
	)
	weldToHandle(handle, gripWrap)

	local collar = createPart(
		tool,
		"HeadCollar",
		Vector3.new(0.58, 0.7, 0.52),
		CFrame.new(0, 1.48, 0),
		COLLAR_COLOR,
		Enum.Material.Metal
	)
	weldToHandle(handle, collar)

	local head = createPart(
		tool,
		"PickaxeHead",
		Vector3.new(2.45, 0.34, 0.46),
		CFrame.new(0, 1.72, 0),
		headColor,
		Enum.Material.Metal
	)
	weldToHandle(handle, head)

	local headRidge = createPart(
		tool,
		"PickaxeHeadRidge",
		Vector3.new(1.65, 0.16, 0.52),
		CFrame.new(-0.12, 1.93, 0),
		headColor:Lerp(Color3.new(1, 1, 1), 0.22),
		Enum.Material.Metal
	)
	weldToHandle(handle, headRidge)

	local leftPoint = createWedge(
		tool,
		"PickaxeLeftPoint",
		Vector3.new(0.58, 0.34, 0.46),
		CFrame.new(-1.46, 1.72, 0) * CFrame.Angles(0, 0, math.rad(180)),
		headColor
	)
	weldToHandle(handle, leftPoint)

	local rightPoint = createWedge(
		tool,
		"PickaxeRightPoint",
		Vector3.new(0.58, 0.34, 0.46),
		CFrame.new(1.46, 1.72, 0) * CFrame.Angles(0, math.rad(180), 0),
		headColor
	)
	weldToHandle(handle, rightPoint)

	local handleCap = createPart(
		tool,
		"HandleCap",
		Vector3.new(0.42, 0.18, 0.42),
		CFrame.new(0, -1.86, 0),
		COLLAR_COLOR,
		Enum.Material.Metal
	)
	weldToHandle(handle, handleCap)

	tool.RequiresHandle = true
	tool.Grip = CFrame.new(0, -0.95, -0.12) * CFrame.Angles(math.rad(12), math.rad(92), math.rad(-24))
	tool:SetAttribute("PickaxeModelVersion", MODEL_VERSION)

	return handle
end

function PickaxeModelBuilder.getModelVersion()
	return MODEL_VERSION
end

return PickaxeModelBuilder
