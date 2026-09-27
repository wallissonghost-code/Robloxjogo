local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local island = Workspace:WaitForChild("StarterIsland")
local breakBlock = ReplicatedStorage:WaitForChild("BreakBlock")

local MAX_DISTANCE = 14
local HOLD_TIME = 0.7

local selectedBlock = nil
local holding = false
local holdToken = 0

local highlight = Instance.new("Highlight")
highlight.Name = "BlockTargetHighlight"
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.FillTransparency = 1
highlight.OutlineColor = Color3.new(1, 1, 1)
highlight.OutlineTransparency = 0.35
highlight.Enabled = false
highlight.Parent = Workspace

local gui = Instance.new("ScreenGui")
gui.Name = "MiningUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local crosshair = Instance.new("TextLabel")
crosshair.Name = "Crosshair"
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.fromScale(0.5, 0.5)
crosshair.Size = UDim2.fromOffset(28, 28)
crosshair.BackgroundTransparency = 1
crosshair.Text = "+"
crosshair.TextColor3 = Color3.new(1, 1, 1)
crosshair.TextTransparency = 0.15
crosshair.TextStrokeTransparency = 0.65
crosshair.TextScaled = true
crosshair.Font = Enum.Font.GothamMedium
crosshair.Parent = gui

local button = Instance.new("TextButton")
button.Name = "BreakButton"
button.AnchorPoint = Vector2.new(1, 1)
button.Position = UDim2.new(1, -28, 1, -110)
button.Size = UDim2.fromOffset(78, 78)
button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
button.BackgroundTransparency = 0.18
button.Text = "⛏"
button.TextColor3 = Color3.new(1, 1, 1)
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.AutoButtonColor = false
button.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = button

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.new(1, 1, 1)
stroke.Transparency = 0.55
stroke.Thickness = 2
stroke.Parent = button

local progress = Instance.new("Frame")
progress.Name = "HoldProgress"
progress.AnchorPoint = Vector2.new(0.5, 1)
progress.Position = UDim2.new(0.5, 0, 1, -5)
progress.Size = UDim2.new(0, 0, 0, 4)
progress.BackgroundColor3 = Color3.new(1, 1, 1)
progress.BorderSizePixel = 0
progress.Parent = button

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(1, 0)
progressCorner.Parent = progress

local function updateButtonLayout()
	local viewport = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
	local isTouch = UserInputService.TouchEnabled
	local isTablet = isTouch and math.min(viewport.X, viewport.Y) >= 600

	if isTablet then
		button.Size = UDim2.fromOffset(72, 72)
		button.Position = UDim2.new(1, -150, 1, -118)
	elseif isTouch then
		button.Size = UDim2.fromOffset(68, 68)
		button.Position = UDim2.new(1, -122, 1, -96)
	else
		button.Size = UDim2.fromOffset(70, 70)
		button.Position = UDim2.new(1, -28, 1, -110)
	end
end

updateButtonLayout()
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(updateButtonLayout)

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function isIslandBlock(instance)
	return instance
		and instance:IsA("BasePart")
		and instance.Parent == island
		and string.match(instance.Name, "^Block_%d+$") ~= nil
end

local function cancelHold()
	holding = false
	holdToken += 1
	TweenService:Create(progress, TweenInfo.new(0.08), {Size = UDim2.new(0, 0, 0, 4)}):Play()
end

button.MouseButton1Down:Connect(function()
	if holding or not selectedBlock then
		return
	end

	holding = true
	holdToken += 1
	local token = holdToken
	local target = selectedBlock
	progress.Size = UDim2.new(0, 0, 0, 4)

	local tween = TweenService:Create(progress, TweenInfo.new(HOLD_TIME, Enum.EasingStyle.Linear), {
		Size = UDim2.new(0.82, 0, 0, 4),
	})
	tween:Play()

	task.delay(HOLD_TIME, function()
		if holding and token == holdToken and selectedBlock == target and target.Parent == island then
			breakBlock:FireServer(target)
			holding = false
			progress.Size = UDim2.new(0, 0, 0, 4)
		end
	end)
end)

button.MouseButton1Up:Connect(cancelHold)
button.MouseLeave:Connect(function()
	if holding then
		cancelHold()
	end
end)

RunService.RenderStepped:Connect(function()
	local camera = Workspace.CurrentCamera
	if not camera then
		selectedBlock = nil
		highlight.Enabled = false
		return
	end

	local character = player.Character
	raycastParams.FilterDescendantsInstances = character and { character } or {}

	local viewport = camera.ViewportSize
	local ray = camera:ViewportPointToRay(viewport.X * 0.5, viewport.Y * 0.5)
	local result = Workspace:Raycast(ray.Origin, ray.Direction * MAX_DISTANCE, raycastParams)
	local nextBlock = result and isIslandBlock(result.Instance) and result.Instance or nil

	if nextBlock ~= selectedBlock then
		if holding then
			cancelHold()
		end
		selectedBlock = nextBlock
	end

	highlight.Adornee = selectedBlock
	highlight.Enabled = selectedBlock ~= nil
	crosshair.TextTransparency = selectedBlock and 0 or 0.35
	button.BackgroundTransparency = selectedBlock and 0.18 or 0.55
end)
