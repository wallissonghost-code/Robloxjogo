local Players = game:GetService("Players")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "GoldHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "Balance"
frame.AnchorPoint = Vector2.new(1, 0)
frame.Position = UDim2.new(1, -18, 0, 18)
frame.Size = UDim2.fromOffset(220, 72)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 23)
frame.BackgroundTransparency = 0.08
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Transparency = 0.55
stroke.Thickness = 1
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(16, 8)
title.Size = UDim2.new(1, -32, 0, 22)
title.Font = Enum.Font.GothamMedium
title.Text = "SALDO DE OURO"
title.TextColor3 = Color3.fromRGB(190, 190, 195)
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local amount = Instance.new("TextLabel")
amount.BackgroundTransparency = 1
amount.Position = UDim2.fromOffset(16, 29)
amount.Size = UDim2.new(1, -32, 0, 32)
amount.Font = Enum.Font.GothamBold
amount.TextColor3 = Color3.fromRGB(255, 211, 74)
amount.TextSize = 24
amount.TextXAlignment = Enum.TextXAlignment.Left
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
	amount.Text = "●  " .. formatNumber(gold.Value)
end

update()
gold:GetPropertyChangedSignal("Value"):Connect(update)
