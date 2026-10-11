local Players = game:GetService("Players")

local BUILD_VERSION = "V1"
local BUILD_NOTE = "Diagnostico visual + ATM em quarentena"

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "BuildDiagnostic"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10000
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Name = "OpenDiagnostic"
button.Size = UDim2.fromOffset(118, 34)
button.Position = UDim2.fromOffset(12, 12)
button.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
button.TextColor3 = Color3.fromRGB(235, 235, 240)
button.Text = "DIAGNOSTICO"
button.TextSize = 12
button.Font = Enum.Font.GothamBold
button.BorderSizePixel = 0
button.Parent = gui
local bc = Instance.new("UICorner")
bc.CornerRadius = UDim.new(0, 9)
bc.Parent = button

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(290, 150)
panel.Position = UDim2.fromOffset(12, 54)
panel.BackgroundColor3 = Color3.fromRGB(16, 16, 19)
panel.BackgroundTransparency = 0.04
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
local pc = Instance.new("UICorner")
pc.CornerRadius = UDim.new(0, 12)
pc.Parent = panel

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(14, 10)
title.Size = UDim2.new(1, -28, 0, 30)
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextColor3 = Color3.fromRGB(255, 211, 74)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "BUILD " .. BUILD_VERSION
title.Parent = panel

local info = Instance.new("TextLabel")
info.BackgroundTransparency = 1
info.Position = UDim2.fromOffset(14, 44)
info.Size = UDim2.new(1, -28, 1, -54)
info.Font = Enum.Font.Gotham
info.TextSize = 13
info.TextColor3 = Color3.fromRGB(225, 225, 230)
info.TextWrapped = true
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.Text = BUILD_NOTE .. "\n\nPlace: " .. tostring(game.PlaceId) .. "\nPlayer: " .. player.Name
info.Parent = panel

button.Activated:Connect(function()
	panel.Visible = not panel.Visible
	button.Text = panel.Visible and "FECHAR" or "DIAGNOSTICO"
end)
