local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "GoldHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "Balance"
frame.AnchorPoint = Vector2.new(1, 0)
frame.Position = UDim2.new(1, -6, 0, 6)
frame.Size = UDim2.fromOffset(112, 38)
frame.BackgroundColor3 = Color3.fromRGB(13, 15, 18)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(72, 76, 84)
stroke.Transparency = 0.45
stroke.Thickness = 1
stroke.Parent = frame

local coin = Instance.new("Frame")
coin.Name = "Coin"
coin.AnchorPoint = Vector2.new(0, 0.5)
coin.Position = UDim2.new(0, 10, 0.5, 0)
coin.Size = UDim2.fromOffset(16, 16)
coin.BackgroundColor3 = Color3.fromRGB(255, 199, 47)
coin.BorderSizePixel = 0
coin.Parent = frame

local coinCorner = Instance.new("UICorner")
coinCorner.CornerRadius = UDim.new(1, 0)
coinCorner.Parent = coin

local coinInner = Instance.new("Frame")
coinInner.AnchorPoint = Vector2.new(0.5, 0.5)
coinInner.Position = UDim2.fromScale(0.5, 0.5)
coinInner.Size = UDim2.fromOffset(7, 7)
coinInner.BackgroundTransparency = 1
coinInner.BorderSizePixel = 0
coinInner.Parent = coin
local coinStroke = Instance.new("UIStroke")
coinStroke.Color = Color3.fromRGB(126, 88, 12)
coinStroke.Thickness = 1.5
coinStroke.Parent = coinInner
local coinInnerCorner = Instance.new("UICorner")
coinInnerCorner.CornerRadius = UDim.new(1, 0)
coinInnerCorner.Parent = coinInner

local amount = Instance.new("TextLabel")
amount.BackgroundTransparency = 1
amount.Position = UDim2.fromOffset(34, 0)
amount.Size = UDim2.new(1, -44, 1, 0)
amount.Font = Enum.Font.GothamBold
amount.TextColor3 = Color3.fromRGB(255, 211, 74)
amount.TextSize = 17
amount.TextXAlignment = Enum.TextXAlignment.Left
amount.TextYAlignment = Enum.TextYAlignment.Center
amount.Parent = frame

local function formatNumber(n)
	local s = tostring(math.floor(n))
	while true do
		local formatted, count = s:gsub("^(-?%d+)(%d%d%d)", "%1.%2")
		s = formatted
		if count == 0 then break end
	end
	return s
end

local gold = player:WaitForChild("leaderstats"):WaitForChild("Ouro")

local function update()
	local value = formatNumber(gold.Value)
	amount.Text = value
	local width = TextService:GetTextSize(value, amount.TextSize, amount.Font, Vector2.new(1000, 38)).X
	frame.Size = UDim2.fromOffset(math.max(86, math.ceil(width) + 52), 38)
end

update()
gold:GetPropertyChangedSignal("Value"):Connect(update)
