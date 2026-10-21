local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local MapGrid = require(Shared.MapGrid)
local WorldDefinition = require(Shared.WorldDefinition)
local MapView = require(script.Parent.MapView)
local MapController = require(script.Parent.MapController)
local NationClient = require(script.Parent.NationClient)

local gui = Instance.new("ScreenGui")
gui.Name = "WorldMap"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.fromScale(1, 1)
background.BorderSizePixel = 0
background.BackgroundColor3 = Color3.fromRGB(12, 25, 37)
background.Parent = gui

local function label(parent, text, position, size, textSize)
    local item = Instance.new("TextLabel")
    item.BackgroundTransparency = 1
    item.Position, item.Size = position, size
    item.Font = Enum.Font.GothamMedium
    item.TextColor3 = Color3.fromRGB(230, 238, 242)
    item.TextSize = textSize
    item.TextWrapped = true
    item.Text = text
    item.Parent = parent
    return item
end
label(background, "DOMÍNIO MUNDIAL", UDim2.fromOffset(8, 4), UDim2.new(1, -16, 0, 30), 19)
local status = label(background, "Carregando mapa…", UDim2.fromOffset(8, 34), UDim2.new(1, -16, 0, 30), 12)
local viewport = Instance.new("Frame")
viewport.Name = "MapViewport"
viewport.Position = UDim2.fromOffset(0, 68)
viewport.Size = UDim2.new(1, 0, 1, -206)
viewport.BorderSizePixel = 0
viewport.BackgroundColor3 = Color3.fromRGB(table.unpack(Config.View.WaterColor))
viewport.ClipsDescendants = true
viewport.Active = true
viewport.Parent = background

local hint = label(background, "Arraste para mover • Pinça para ampliar", UDim2.new(0, 8, 1, -136), UDim2.new(1, -16, 0, 36), 12)
local action = Instance.new("TextButton")
action.Name = "FoundCapital"
action.AnchorPoint = Vector2.new(0.5, 1)
action.Position = UDim2.new(0.5, 0, 1, -52)
action.Size = UDim2.fromOffset(260, 44)
action.BorderSizePixel = 0
action.Font = Enum.Font.GothamBold
action.TextSize = 16
action.TextColor3 = Color3.fromRGB(235, 243, 248)
action.Text = "Sincronizando…"
action.Active = false
action.Parent = background
local actionCorner = Instance.new("UICorner")
actionCorner.CornerRadius = UDim.new(0, 8)
actionCorner.Parent = action
local controls = Instance.new("Frame")
controls.BackgroundTransparency = 1
controls.AnchorPoint = Vector2.new(0.5, 1)
controls.Position = UDim2.new(0.5, 0, 1, -4)
controls.Size = UDim2.fromOffset(260, 44)
controls.Parent = background

local state = ReplicatedStorage:WaitForChild("WorldState", 30)
if not state or not state:GetAttribute("Ready") then
    status.Text = "O servidor não carregou o mapa. Entre novamente."
    return
end
if state:GetAttribute("MapVersion") ~= Config.Map.Version or state:GetAttribute("Version") ~= Config.Version then
    status.Text = "Versão do mapa diferente do servidor. Entre novamente."
    return
end

local grid = MapGrid.new(Config.Map, WorldDefinition)
if grid.LandCount ~= state:GetAttribute("LandCells") then
    status.Text = "Falha na verificação do mapa. Entre novamente."
    return
end
local view = MapView.new(viewport, grid, Config.View)
status.Text = Config.Version

local function button(text, x, width, action)
    local item = Instance.new("TextButton")
    item.Text = text
    item.TextSize = 17
    item.Font = Enum.Font.GothamBold
    item.TextColor3 = Color3.fromRGB(235, 243, 248)
    item.BackgroundColor3 = Color3.fromRGB(34, 62, 79)
    item.BorderSizePixel = 0
    item.Position = UDim2.fromOffset(x, 0)
    item.Size = UDim2.fromOffset(width, 44)
    item.Parent = controls
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = item
    item.Activated:Connect(action)
end
button("−", 0, 52, function() view:SetZoom(view.Zoom / Config.View.ZoomStep) end)
button("Ver mundo", 60, 140, function() view:Reset() end)
button("+", 208, 52, function() view:SetZoom(view.Zoom * Config.View.ZoomStep) end)

local nations = NationClient.new(view, grid, Config, status, hint, action)
local disconnect = MapController.connect(view, function(position)
    local id = view:CellAt(position)
    if not id then return end
    nations:Inspect(id)
end)
gui.Destroying:Connect(function()
    disconnect()
    nations:Destroy()
    view:Destroy()
end)
