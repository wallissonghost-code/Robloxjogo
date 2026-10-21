local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

local function disableCore()
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false) end)
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health,false) end)
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false) end)
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu,false) end)
end
disableCore()

local playerScripts = player:WaitForChild("PlayerScripts")
local playerModule = require(playerScripts:WaitForChild("PlayerModule"))
local controls = playerModule:GetControls()
controls:Disable()

-- Explicitly disable mobile touch controls (joystick/jump).
local touchGui = player:WaitForChild("PlayerGui"):FindFirstChild("TouchGui")
if touchGui then touchGui.Enabled = false end
player.PlayerGui.ChildAdded:Connect(function(child)
    if child.Name == "TouchGui" and child:IsA("ScreenGui") then child.Enabled = false end
end)

local camera = workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = 50
camera.CFrame = CFrame.new(Vector3.new(0,170,125), Vector3.new(0,0,0))

local old = player.PlayerGui:FindFirstChild("PixelWarHUD")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "PixelWarHUD"
gui.ResetOnSpawn = false
gui.Parent = player.PlayerGui

local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(.5,0)
card.Position = UDim2.fromScale(.5,.055)
card.Size = UDim2.fromOffset(300,58)
card.BackgroundTransparency = 1
card.Parent = gui

local avatar = Instance.new("ImageLabel")
avatar.Size = UDim2.fromOffset(48,48)
avatar.Position = UDim2.fromOffset(0,5)
avatar.BackgroundTransparency = 1
avatar.Parent = card
local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1,0); corner.Parent = avatar
task.spawn(function()
    local image = Players:GetUserThumbnailAsync(player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)
    avatar.Image = image
end)

local name = Instance.new("TextLabel")
name.Position = UDim2.fromOffset(56,0); name.Size = UDim2.fromOffset(244,34)
name.BackgroundTransparency = 1; name.Font = Enum.Font.GothamBold; name.TextSize = 25
name.TextXAlignment = Enum.TextXAlignment.Left; name.TextColor3 = Color3.new(1,1,1)
name.TextStrokeTransparency = .15; name.Text = player.DisplayName; name.Parent = card

local troops = Instance.new("TextLabel")
troops.Position = UDim2.fromOffset(56,31); troops.Size = UDim2.fromOffset(244,23)
troops.BackgroundTransparency = 1; troops.Font = Enum.Font.GothamBold; troops.TextSize = 18
troops.TextXAlignment = Enum.TextXAlignment.Left; troops.TextColor3 = Color3.new(1,1,1)
troops.TextStrokeTransparency = .2; troops.Parent = card

local function fmt(v)
    v = tonumber(v) or 0
    if v >= 1e6 then return string.format("%.2fM",v/1e6) end
    if v >= 1e3 then return string.format("%.2fK",v/1e3) end
    return tostring(math.floor(v))
end
local function refresh() troops.Text = fmt(player:GetAttribute("Troops")) end
player:GetAttributeChangedSignal("Troops"):Connect(refresh)
refresh()
