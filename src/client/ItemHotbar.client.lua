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
root.Position = UDim2.new(.5, 0, 1, -14)
root.BackgroundTransparency = 1
root.Parent = gui

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = root

local slots = {}
local MAX_SLOTS = 8

local function makeSlot(index)
	local button = Instance.new("TextButton")
	button.Name = "Slot" .. index
	button.LayoutOrder = index
	button.AutoButtonColor = false
	button.Text = ""
	button.BackgroundColor3 = Color3.fromRGB(15, 20, 17)
	button.BackgroundTransparency = .12
	button.BorderSizePixel = 0
	button.Parent = root

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Name = "Stroke"
	stroke.Color = Color3.fromRGB(55, 70, 60)
	stroke.Transparency = .15
	stroke.Thickness = 1
	stroke.Parent = button

	local number = Instance.new("TextLabel")
	number.Name = "Number"
	number.Position = UDim2.fromOffset(5, 3)
	number.Size = UDim2.fromOffset(15, 14)
	number.BackgroundTransparency = 1
	number.Text = tostring(index)
	number.TextColor3 = Color3.fromRGB(135, 150, 140)
	number.Font = Enum.Font.GothamBold
	number.TextSize = 9
	number.TextXAlignment = Enum.TextXAlignment.Left
	number.Parent = button

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.AnchorPoint = Vector2.new(.5, .5)
	icon.Position = UDim2.fromScale(.5, .5)
	icon.Size = UDim2.fromScale(.68, .68)
	icon.BackgroundTransparency = 1
	icon.Image = ""
	icon.ScaleType = Enum.ScaleType.Fit
	icon.Parent = button

	local quantity = Instance.new("TextLabel")
	quantity.Name = "Quantity"
	quantity.AnchorPoint = Vector2.new(1, 1)
	quantity.Position = UDim2.new(1, -5, 1, -4)
	quantity.Size = UDim2.fromOffset(28, 15)
	quantity.BackgroundTransparency = 1
	quantity.Text = ""
	quantity.TextColor3 = Color3.fromRGB(238, 244, 240)
	quantity.Font = Enum.Font.GothamBold
	quantity.TextSize = 10
	quantity.TextXAlignment = Enum.TextXAlignment.Right
	quantity.Parent = button

	slots[index] = button
	return button
end

for i = 1, MAX_SLOTS do makeSlot(i) end

local selected = 1
local function selectSlot(index)
	if index < 1 or index > MAX_SLOTS then return end
	selected = index
	for i, slot in ipairs(slots) do
		local stroke = slot:FindFirstChild("Stroke")
		if i == selected then
			slot.BackgroundColor3 = Color3.fromRGB(25, 39, 30)
			stroke.Color = Color3.fromRGB(95, 255, 140)
			stroke.Thickness = 2
		else
			slot.BackgroundColor3 = Color3.fromRGB(15, 20, 17)
			stroke.Color = Color3.fromRGB(55, 70, 60)
			stroke.Thickness = 1
		end
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
	local sideMargin = width < 500 and 16 or 28
	local available = math.max(240, width - sideMargin * 2)
	local gap = math.clamp(math.floor(available * .012), 3, 8)
	local slotSize = math.clamp(math.floor((available - gap * (MAX_SLOTS - 1)) / MAX_SLOTS), 34, 62)
	local totalWidth = slotSize * MAX_SLOTS + gap * (MAX_SLOTS - 1)

	root.Size = UDim2.fromOffset(totalWidth, slotSize)
	layout.Padding = UDim.new(0, gap)
	for _, slot in ipairs(slots) do
		slot.Size = UDim2.fromOffset(slotSize, slotSize)
	end
end

local function watchCamera()
	if cameraConnection then cameraConnection:Disconnect() end
	local camera = workspace.CurrentCamera
	if camera then
		cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
	end
	resize()
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()
selectSlot(1)
