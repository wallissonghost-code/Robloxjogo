local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local MapGrid = require(Shared.MapGrid)
local WorldDefinition = require(Shared.WorldDefinition)
local MapView = require(script.Parent.MapView)
local MapController = require(script.Parent.MapController)
local NationClient = require(script.Parent.NationClient)
local StrategyHud = require(script.Parent.StrategyHud)

local gui = Instance.new("ScreenGui")
gui.Name = "WorldMap"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
local hud = StrategyHud.new(gui, Config)
local state = ReplicatedStorage:WaitForChild("WorldState", 30)
if not state or not state:GetAttribute("Ready") then
    hud.Status.Text = "O servidor não carregou o mapa. Entre novamente."
    return
end
if state:GetAttribute("MapVersion") ~= Config.Map.Version or state:GetAttribute("Version") ~= Config.Version then
    hud.Status.Text = "Versão do mapa diferente do servidor. Entre novamente."
    return
end
local grid = MapGrid.new(Config.Map, WorldDefinition)
if grid.LandCount ~= state:GetAttribute("LandCells") then
    hud.Status.Text = "Falha na verificação do mapa. Entre novamente."
    return
end
local view = MapView.new(hud.Viewport, grid, Config.View)
hud.Minus.Activated:Connect(function() view:SetZoom(view.Zoom / Config.View.ZoomStep) end)
hud.Reset.Activated:Connect(function() view:Reset() end)
hud.Plus.Activated:Connect(function() view:SetZoom(view.Zoom * Config.View.ZoomStep) end)
local nations = NationClient.new(view, grid, Config, hud.Status, hud.Hint, hud.Action, hud)
local disconnect = MapController.connect(view, function(position)
    local id = view:CellAt(position)
    if id then nations:Inspect(id) end
end)
gui.Destroying:Connect(function()
    disconnect()
    nations:Destroy()
    hud:Destroy()
    view:Destroy()
end)
