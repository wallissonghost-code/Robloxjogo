local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "ItemHotbar"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 50
gui.Parent = player:WaitForChild("PlayerGui")

local root = Instance.new("Frame")
root.Name = "Root"
root.AnchorPoint = Vector2.new(.5, 1)
root.Position = UDim2.new(.5, 0, 1, -12)
root.BackgroundColor3 = Color3.fromRGB(12, 17, 14)
root.BackgroundTransparency = .08
root.BorderSizePixel = 0
root.ClipsDescendants = true
root.Parent = gui

local rootCorner = Instance.new("UICorner")
rootCorner.CornerRadius = UDim.new(0, 8)
rootCorner.Parent = root

local rootStroke = Instance.new("UIStroke")
rootStroke.Color = Color3.fromRGB(67, 82, 72)
rootStroke.Transparency = .08
rootStroke.Thickness = 1
rootStroke.Parent = root

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 0)
layout.Parent = root

local slots = {}
local MAX_SLOTS = 8

local function makeSlot(index)
	local button = Instance.new("TextButton")
	button.Name = "Slot" .. index
	button.LayoutOrder = index
	button.AutoButtonColor = false
	button.Text = ""
	button.BackgroundColor3 = Color3.fromRGB(16, 22, 18)
	button.BackgroundTransparency = .1
	button.BorderSizePixel = 0
	button.Parent = root

	if index > 1 then
		local divider = Instance.new("Frame")
		divider.Name = "Divider"
		divider.AnchorPoint = Vector2.new(0, .5)
		divider.Position = UDim2.new(0, 0, .5, 0)
		divider.Size = UDim2.new(0, 1, .72, 0)
		divider.BackgroundColor3 = Color3.fromRGB(64, 78, 69)
		divider.BackgroundTransparency = .28
		divider.BorderSizePixel = 0
		divider.ZIndex = 3
		divider.Parent = button
	end

	local selectedBorder = Instance.new("Frame")
	selectedBorder.Name = "SelectedBorder"
	selectedBorder.Size = UDim2.fromScale(1, 1)
	selectedBorder.BackgroundTransparency = 1
	selectedBorder.Visible = false
	selectedBorder.ZIndex = 4
	selectedBorder.Parent = button
	local selectedStroke = Instance.new("UIStroke")
	selectedStroke.Color = Color3.fromRGB(95, 255, 140)
	selectedStroke.Thickness = 2
	selectedStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	selectedStroke.Parent = selectedBorder

	local number = Instance.new("TextLabel")
	number.Name = "Number"
	number.Position = UDim2.fromOffset(4, 2)
	number.Size = UDim2.fromOffset(14, 12)
	number.BackgroundTransparency = 1
	number.Text = tostring(index)
	number.TextColor3 = Color3.fromRGB(135, 150, 140)
	number.Font = Enum.Font.GothamBold
	number.TextSize = 8
	number.TextXAlignment = Enum.TextXAlignment.Left
	number.ZIndex = 2
	number.Parent = button

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.AnchorPoint = Vector2.new(.5, .5)
	icon.Position = UDim2.fromScale(.5, .52)
	icon.Size = UDim2.fromScale(.68, .68)
	icon.BackgroundTransparency = 1
	icon.Image = ""
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = 2
	icon.Parent = button

	local quantity = Instance.new("TextLabel")
	quantity.Name = "Quantity"
	quantity.AnchorPoint = Vector2.new(1, 1)
	quantity.Position = UDim2.new(1, -4, 1, -3)
	quantity.Size = UDim2.fromOffset(25, 13)
	quantity.BackgroundTransparency = 1
	quantity.Text = ""
	quantity.TextColor3 = Color3.fromRGB(238, 244, 240)
	quantity.Font = Enum.Font.GothamBold
	quantity.TextSize = 9
	quantity.TextXAlignment = Enum.TextXAlignment.Right
	quantity.ZIndex = 2
	quantity.Parent = button

	slots[index] = button
end

for i = 1, MAX_SLOTS do makeSlot(i) end

local selected = 1
local function selectSlot(index)
	if index < 1 or index > MAX_SLOTS then return end
	selected = index
	for i, slot in ipairs(slots) do
		local border = slot:FindFirstChild("SelectedBorder")
		local active = i == selected
		slot.BackgroundColor3 = active and Color3.fromRGB(24, 37, 29) or Color3.fromRGB(16, 22, 18)
		if border then border.Visible = active end
	end
	gui:SetAttribute("SelectedSlot", selected)
end

for i, slot in ipairs(slots) do
	slot.Activated:Connect(function() selectSlot(i) end)
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	local n = tonumber(input.KeyCode.Name)
	if n and n >= 1 and n <= MAX_SLOTS then selectSlot(n) end
end)

local cameraConnection
local function resize()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local width = camera.ViewportSize.X
	local available = math.max(240, width - 24)
	local slotSize = math.clamp(math.floor(available / MAX_SLOTS), 32, 48)
	local totalWidth = slotSize * MAX_SLOTS
	root.Size = UDim2.fromOffset(totalWidth, slotSize)
	for _, slot in ipairs(slots) do
		slot.Size = UDim2.fromOffset(slotSize, slotSize)
	end
end

local function watchCamera()
	if cameraConnection then cameraConnection:Disconnect() end
	local camera = workspace.CurrentCamera
	if camera then cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
	resize()
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()
selectSlot(1)
