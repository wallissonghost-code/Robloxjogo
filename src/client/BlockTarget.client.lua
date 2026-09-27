local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local island = Workspace:WaitForChild("StarterIsland")
local breakBlock = ReplicatedStorage:WaitForChild("BreakBlock")

local MAX_DISTANCE = 14
local HOLD_TIME = 0.7

local selectedBlock = nil
local mining = false
local miningTarget = nil
local miningStartedAt = 0
local activeInput = nil

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
crosshair.TextTransparency = 0.35
crosshair.TextStrokeTransparency = 0.65
crosshair.TextScaled = true
crosshair.Font = Enum.Font.GothamMedium
crosshair.Parent = gui

local progressRing = Instance.new("Frame")
progressRing.Name = "MiningProgress"
progressRing.AnchorPoint = Vector2.new(0.5, 0.5)
progressRing.Position = UDim2.fromScale(0.5, 0.5)
progressRing.Size = UDim2.fromOffset(42, 42)
progressRing.BackgroundTransparency = 1
progressRing.Visible = false
progressRing.Parent = gui

local ringCorner = Instance.new("UICorner")
ringCorner.CornerRadius = UDim.new(1, 0)
ringCorner.Parent = progressRing

local ringStroke = Instance.new("UIStroke")
ringStroke.Color = Color3.new(1, 1, 1)
ringStroke.Transparency = 0.3
ringStroke.Thickness = 2
ringStroke.Parent = progressRing

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function isIslandBlock(instance)
	return instance
		and instance:IsA("BasePart")
		and instance.Parent == island
		and string.match(instance.Name, "^Block_%d+$") ~= nil
end

local function cancelMining()
	mining = false
	miningTarget = nil
	activeInput = nil
	progressRing.Visible = false
	progressRing.Size = UDim2.fromOffset(42, 42)
end

local function beginMining(input)
	if mining or not selectedBlock then
		return
	end

	mining = true
	miningTarget = selectedBlock
	miningStartedAt = os.clock()
	activeInput = input
	progressRing.Visible = true
	progressRing.Size = UDim2.fromOffset(42, 42)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
		beginMining(input)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if mining and input == activeInput then
		cancelMining()
	end
end)

RunService.RenderStepped:Connect(function()
	local camera = Workspace.CurrentCamera
	if not camera then
		selectedBlock = nil
		highlight.Enabled = false
		cancelMining()
		return
	end

	local character = player.Character
	raycastParams.FilterDescendantsInstances = character and { character } or {}

	local viewport = camera.ViewportSize
	local ray = camera:ViewportPointToRay(viewport.X * 0.5, viewport.Y * 0.5)
	local result = Workspace:Raycast(ray.Origin, ray.Direction * MAX_DISTANCE, raycastParams)
	local nextBlock = result and isIslandBlock(result.Instance) and result.Instance or nil

	if nextBlock ~= selectedBlock then
		selectedBlock = nextBlock
		if mining and selectedBlock ~= miningTarget then
			cancelMining()
		end
	end

	highlight.Adornee = selectedBlock
	highlight.Enabled = selectedBlock ~= nil
	crosshair.TextTransparency = selectedBlock and 0 or 0.35

	if mining then
		if not miningTarget or miningTarget.Parent ~= island or selectedBlock ~= miningTarget then
			cancelMining()
			return
		end

		local progress = math.clamp((os.clock() - miningStartedAt) / HOLD_TIME, 0, 1)
		local size = 42 + progress * 12
		progressRing.Size = UDim2.fromOffset(size, size)
		ringStroke.Transparency = 0.3 * (1 - progress)

		if progress >= 1 then
			local target = miningTarget
			cancelMining()
			breakBlock:FireServer(target)
		end
	end
end)
