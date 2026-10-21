local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("WarShared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("WarRemotes")
local commandRemote = remotes:WaitForChild("Command")
local stateRemote = remotes:WaitForChild("State")

while not Workspace:GetAttribute("WarMapReady") do
	task.wait()
end

local grid = Workspace:WaitForChild("WorldGrid")
local camera = Workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = 45

local mapWidth = Config.Map.Columns * Config.Map.CellSize
local mapHeight = Config.Map.Rows * Config.Map.CellSize
local cameraCenter = Vector3.new(0, 0, 0)
local zoomHeight = math.max(285, mapWidth * 0.87)
local minZoom = 62
local maxZoom = math.max(420, mapWidth * 1.05)

local function clampCenter()
	local xLimit = mapWidth * 0.52
	local zLimit = mapHeight * 0.58
	cameraCenter = Vector3.new(
		math.clamp(cameraCenter.X, -xLimit, xLimit),
		0,
		math.clamp(cameraCenter.Z, -zLimit, zLimit)
	)
end

local function applyCamera()
	clampCenter()
	local position = Vector3.new(cameraCenter.X, zoomHeight, cameraCenter.Z)
	camera.CFrame = CFrame.lookAt(position, cameraCenter)
	camera.Focus = CFrame.new(cameraCenter)
end

applyCamera()

local function abbr(value)
	value = math.floor(tonumber(value) or 0)
	if value >= 1000000 then
		return string.format("%.2fM", value / 1000000)
	elseif value >= 1000 then
		return string.format("%.2fK", value / 1000)
	end
	return tostring(value)
end

local gui = Instance.new("ScreenGui")
gui.Name = "WarHUD"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 14)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(55, 67, 95)
	s.Thickness = thickness or 1.5
	s.Transparency = transparency or 0
	s.Parent = parent
	return s
end

local instruction = Instance.new("TextLabel")
instruction.AnchorPoint = Vector2.new(0.5, 0)
instruction.Position = UDim2.fromScale(0.5, 0.14)
instruction.Size = UDim2.new(0.58, 0, 0, 66)
instruction.BackgroundColor3 = Color3.fromRGB(19, 28, 48)
instruction.BackgroundTransparency = 0.08
instruction.TextColor3 = Color3.fromRGB(235, 240, 255)
instruction.TextXAlignment = Enum.TextXAlignment.Left
instruction.TextWrapped = true
instruction.Font = Enum.Font.GothamBold
instruction.TextSize = 18
instruction.Text = "ESCOLHA SUA LOCALIZAÇÃO INICIAL\nToque em qualquer terreno neutro para colocar sua capital."
instruction.Parent = gui
corner(instruction, 16)
stroke(instruction, Color3.fromRGB(48, 62, 91), 2)

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 18)
padding.PaddingRight = UDim.new(0, 18)
padding.Parent = instruction

local topStatus = Instance.new("TextLabel")
topStatus.AnchorPoint = Vector2.new(1, 0)
topStatus.Position = UDim2.new(0.985, 0, 0.025, 0)
topStatus.Size = UDim2.fromOffset(255, 50)
topStatus.BackgroundColor3 = Color3.fromRGB(18, 26, 45)
topStatus.BackgroundTransparency = 0.06
topStatus.TextColor3 = Color3.fromRGB(235, 240, 255)
topStatus.Font = Enum.Font.GothamBold
topStatus.TextSize = 18
topStatus.Text = "Território 0.00%"
topStatus.Parent = gui
corner(topStatus, 18)
stroke(topStatus, Color3.fromRGB(45, 58, 86), 2)

local feed = Instance.new("TextLabel")
feed.Position = UDim2.new(0.055, 0, 0.15, 0)
feed.Size = UDim2.fromOffset(390, 42)
feed.BackgroundColor3 = Color3.fromRGB(19, 28, 48)
feed.BackgroundTransparency = 0.08
feed.TextColor3 = Color3.fromRGB(237, 243, 255)
feed.TextXAlignment = Enum.TextXAlignment.Left
feed.Font = Enum.Font.GothamBold
feed.TextSize = 16
feed.Text = ""
feed.Visible = false
feed.Parent = gui
corner(feed, 14)
local feedPadding = Instance.new("UIPadding")
feedPadding.PaddingLeft = UDim.new(0, 14)
feedPadding.Parent = feed

local bar = Instance.new("Frame")
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 0.975, 0)
bar.Size = UDim2.new(0.76, 0, 0, 78)
bar.BackgroundColor3 = Color3.fromRGB(18, 26, 45)
bar.BackgroundTransparency = 0.04
bar.Parent = gui
corner(bar, 18)
stroke(bar, Color3.fromRGB(45, 58, 86), 2)

local barConstraint = Instance.new("UISizeConstraint")
barConstraint.MinSize = Vector2.new(540, 72)
barConstraint.MaxSize = Vector2.new(1040, 82)
barConstraint.Parent = bar

local stats = Instance.new("Frame")
stats.Size = UDim2.new(0.34, 0, 1, 0)
stats.BackgroundTransparency = 1
stats.Parent = bar

local troopsText = Instance.new("TextLabel")
troopsText.Position = UDim2.new(0.03, 0, 0.05, 0)
troopsText.Size = UDim2.new(0.46, 0, 0.48, 0)
troopsText.BackgroundTransparency = 1
troopsText.TextColor3 = Color3.fromRGB(238, 242, 255)
troopsText.Font = Enum.Font.GothamBold
troopsText.TextScaled = true
troopsText.TextXAlignment = Enum.TextXAlignment.Left
troopsText.Text = "120"
troopsText.Parent = stats

local rateText = Instance.new("TextLabel")
rateText.Position = UDim2.new(0.50, 0, 0.10, 0)
rateText.Size = UDim2.new(0.45, 0, 0.35, 0)
rateText.BackgroundTransparency = 1
rateText.TextColor3 = Color3.fromRGB(67, 220, 150)
rateText.Font = Enum.Font.GothamBold
rateText.TextScaled = true
rateText.TextXAlignment = Enum.TextXAlignment.Left
rateText.Text = "+0/s"
rateText.Parent = stats

local goldText = Instance.new("TextLabel")
goldText.Position = UDim2.new(0.03, 0, 0.53, 0)
goldText.Size = UDim2.new(0.92, 0, 0.36, 0)
goldText.BackgroundTransparency = 1
goldText.TextColor3 = Color3.fromRGB(247, 197, 71)
goldText.Font = Enum.Font.GothamBold
goldText.TextScaled = true
goldText.TextXAlignment = Enum.TextXAlignment.Left
goldText.Text = "Ouro 3.00K"
goldText.Parent = stats

local percentFrame = Instance.new("Frame")
percentFrame.Position = UDim2.new(0.34, 0, 0.10, 0)
percentFrame.Size = UDim2.new(0.48, 0, 0.80, 0)
percentFrame.BackgroundColor3 = Color3.fromRGB(28, 37, 60)
percentFrame.Parent = bar
corner(percentFrame, 14)

local percentButtons = {}
for index, pct in ipairs(Config.SendPercents) do
	local button = Instance.new("TextButton")
	button.Name = "P" .. tostring(math.floor(pct * 100))
	button.Position = UDim2.new((index - 1) * 0.20, 2, 0, 0)
	button.Size = UDim2.new(0.20, -4, 1, 0)
	button.BackgroundTransparency = 1
	button.Text = tostring(math.floor(pct * 100)) .. "%"
	button.TextColor3 = Color3.fromRGB(188, 198, 224)
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.Parent = percentFrame
	percentButtons[pct] = button
	button.Activated:Connect(function()
		commandRemote:FireServer("SetPercent", pct)
	end)
end

local buildButton = Instance.new("TextButton")
buildButton.Position = UDim2.new(0.83, 0, 0.10, 0)
buildButton.Size = UDim2.new(0.16, -8, 0.80, 0)
buildButton.BackgroundColor3 = Color3.fromRGB(35, 45, 69)
buildButton.TextColor3 = Color3.fromRGB(238, 242, 255)
buildButton.Text = "🏙\nCONSTRUIR"
buildButton.TextWrapped = true
buildButton.Font = Enum.Font.GothamBold
buildButton.TextScaled = true
buildButton.Parent = bar
corner(buildButton, 14)
stroke(buildButton, Color3.fromRGB(70, 82, 110), 1.5)

local buildPanel = Instance.new("Frame")
buildPanel.AnchorPoint = Vector2.new(0.5, 1)
buildPanel.Position = UDim2.new(0.5, 0, 0.865, 0)
buildPanel.Size = UDim2.new(0.56, 0, 0, 126)
buildPanel.BackgroundColor3 = Color3.fromRGB(24, 32, 53)
buildPanel.Visible = false
buildPanel.Parent = gui
corner(buildPanel, 18)
stroke(buildPanel, Color3.fromRGB(52, 64, 92), 2)

local buildConstraint = Instance.new("UISizeConstraint")
buildConstraint.MinSize = Vector2.new(460, 120)
buildConstraint.MaxSize = Vector2.new(820, 132)
buildConstraint.Parent = buildPanel

local buildingOrder = {"City", "Port", "Factory", "Defense"}
local selectedBuilding = nil
for index, buildingType in ipairs(buildingOrder) do
	local def = Config.Buildings[buildingType]
	local button = Instance.new("TextButton")
	button.Name = buildingType
	button.Position = UDim2.new((index - 1) * 0.25, 6, 0.10, 0)
	button.Size = UDim2.new(0.25, -12, 0.80, 0)
	button.BackgroundColor3 = Color3.fromRGB(39, 48, 72)
	button.TextColor3 = Color3.fromRGB(235, 240, 255)
	button.Text = def.DisplayName .. "\n" .. abbr(def.Cost) .. " ouro"
	button.TextWrapped = true
	button.Font = Enum.Font.GothamBold
	button.TextScaled = true
	button.Parent = buildPanel
	corner(button, 12)

	button.Activated:Connect(function()
		selectedBuilding = buildingType
		buildPanel.Visible = false
		instruction.Text = "CONSTRUÇÃO: " .. string.upper(def.DisplayName) .. "\nToque em uma célula do seu território para construir."
	end)
end

buildButton.Activated:Connect(function()
	if player:GetAttribute("WarHasCapital") then
		selectedBuilding = nil
		buildPanel.Visible = not buildPanel.Visible
	end
end)

local noticeToken = 0
local function showFeed(text, duration)
	noticeToken += 1
	local token = noticeToken
	feed.Text = "ⓘ  " .. tostring(text)
	feed.Visible = true
	feed.TextTransparency = 0
	feed.BackgroundTransparency = 0.08
	task.delay(duration or 3.5, function()
		if token ~= noticeToken then
			return
		end
		local tween = TweenService:Create(feed, TweenInfo.new(0.3), {
			TextTransparency = 1,
			BackgroundTransparency = 1,
		})
		tween:Play()
		tween.Completed:Wait()
		if token == noticeToken then
			feed.Visible = false
		end
	end)
end

stateRemote.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	if payload.type == "Notice" or payload.type == "Feed" then
		showFeed(payload.text, payload.type == "Feed" and 4.5 or 3.2)
	end
end)

local function updateHUD()
	local troops = player:GetAttribute("WarTroops") or 0
	local rate = player:GetAttribute("WarTroopRate") or 0
	local gold = player:GetAttribute("WarGold") or 0
	local pct = player:GetAttribute("WarTerritoryPct") or 0
	local selected = player:GetAttribute("WarSelectedPercent") or Config.DefaultSendPercent
	local hasCapital = player:GetAttribute("WarHasCapital") == true

	troopsText.Text = "⚔ " .. abbr(troops)
	rateText.Text = "+" .. abbr(rate) .. "/s"
	goldText.Text = "◉ " .. abbr(gold) .. " ouro"
	topStatus.Text = string.format("Território %.2f%%", pct)

	for value, button in pairs(percentButtons) do
		local active = math.abs(value - selected) < 0.001
		button.BackgroundTransparency = active and 0 or 1
		button.BackgroundColor3 = Color3.fromRGB(255, 180, 65)
		button.TextColor3 = active and Color3.fromRGB(25, 26, 32) or Color3.fromRGB(188, 198, 224)
		if active then
			corner(button, 10)
		end
	end

	if hasCapital and not selectedBuilding then
		instruction.Text = "DOMINE O MAPA\nToque em terra neutra na sua fronteira para expandir; toque em território inimigo para atacar."
	elseif not hasCapital then
		instruction.Text = "ESCOLHA SUA LOCALIZAÇÃO INICIAL\nToque em qualquer terreno neutro para colocar sua capital."
	end
end

for _, attr in ipairs({
	"WarTroops", "WarTroopRate", "WarGold", "WarTerritoryPct",
	"WarSelectedPercent", "WarHasCapital",
}) do
	player:GetAttributeChangedSignal(attr):Connect(updateHUD)
end
updateHUD()

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = {grid}
rayParams.IgnoreWater = true

local function clickMap(screenPosition)
	local ray = camera:ViewportPointToRay(screenPosition.X, screenPosition.Y)
	local result = Workspace:Raycast(ray.Origin, ray.Direction * 1500, rayParams)
	local cell = result and result.Instance
	if not cell or not cell:GetAttribute("GX") then
		return
	end
	local x = cell:GetAttribute("GX")
	local y = cell:GetAttribute("GY")
	if selectedBuilding then
		commandRemote:FireServer("Build", x, y, selectedBuilding)
		selectedBuilding = nil
		task.delay(0.25, updateHUD)
	else
		commandRemote:FireServer("ClaimOrAct", x, y)
	end
end

local activeTouch = nil
local touchStart = nil
local lastTouch = nil
local touchMoved = false
local pinching = false
local pinchStartZoom = zoomHeight

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.UserInputType == Enum.UserInputType.Touch and not activeTouch then
		activeTouch = input
		touchStart = input.Position
		lastTouch = input.Position
		touchMoved = false
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		clickMap(input.Position)
	end
end)

UserInputService.InputChanged:Connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		zoomHeight = math.clamp(zoomHeight - input.Position.Z * 18, minZoom, maxZoom)
		applyCamera()
		return
	end
	if processed or pinching then
		return
	end
	if activeTouch and input == activeTouch then
		local delta = input.Position - lastTouch
		lastTouch = input.Position
		if (input.Position - touchStart).Magnitude > 10 then
			touchMoved = true
		end
		if touchMoved then
			local scale = zoomHeight / 520
			cameraCenter += Vector3.new(-delta.X * scale, 0, -delta.Y * scale)
			applyCamera()
		end
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if input == activeTouch then
		if not processed and not touchMoved and not pinching then
			clickMap(input.Position)
		end
		activeTouch = nil
		touchStart = nil
		lastTouch = nil
		touchMoved = false
	end
end)

if UserInputService.TouchEnabled then
	UserInputService.TouchPinch:Connect(function(_touchPositions, scale, _velocity, state)
		if state == Enum.UserInputState.Begin then
			pinching = true
			pinchStartZoom = zoomHeight
		elseif state == Enum.UserInputState.Change then
			zoomHeight = math.clamp(pinchStartZoom / math.max(scale, 0.15), minZoom, maxZoom)
			applyCamera()
		elseif state == Enum.UserInputState.End then
			pinching = false
		end
	end)
end

Workspace:GetAttributeChangedSignal("WarMapReady"):Connect(applyCamera)
