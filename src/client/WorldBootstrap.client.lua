local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local existing = playerGui:FindFirstChild("WorldBootstrap")
if existing then return end

local gui = Instance.new("ScreenGui")
gui.Name = "WorldBootstrap"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 2000
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local cover = Instance.new("Frame")
cover.Name = "Cover"
cover.Size = UDim2.fromScale(1, 1)
cover.BackgroundColor3 = Color3.fromRGB(7, 10, 8)
cover.BorderSizePixel = 0
cover.ZIndex = 2000
cover.Parent = gui

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(.5, .5)
label.Position = UDim2.fromScale(.5, .5)
label.Size = UDim2.new(.8, 0, 0, 34)
label.BackgroundTransparency = 1
label.Text = "CARREGANDO MUNDOS..."
label.TextColor3 = Color3.fromRGB(145, 160, 150)
label.Font = Enum.Font.GothamMedium
label.TextSize = 14
label.ZIndex = 2001
label.Parent = cover
