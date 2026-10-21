local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local MapGrid = require(Shared.MapGrid)
local WorldDefinition = require(Shared.WorldDefinition)
local MapService = require(script.Parent.MapService)
local NationService = require(script.Parent.NationService)
local CommandService = require(script.Parent.CommandService)

-- Strategic map mode does not need characters, physics or a physical cell field.
Players.CharacterAutoLoads = false
local started = os.clock()
local map = MapService.new(MapGrid.new(Config.Map, WorldDefinition))
local nations = NationService.new(map, Config.Nations)
local commands = CommandService.new(nations, Config.Network)

local network = Instance.new("RemoteEvent")
network.Name = "NationProtocol"
network.OnServerEvent:Connect(function(player, action, cellId, requestId)
    if player.Parent ~= Players then return end
    -- Client arguments never provide actor identity, name, color or ownership.
    -- Handle/Create do not yield, so two requests cannot reserve the same cell.
    local reply, delta = commands:Handle(player.UserId, player.DisplayName, action, cellId, requestId)
    if delta then network:FireAllClients(delta) end
    if reply then network:FireClient(player, reply) end
end)
Players.PlayerRemoving:Connect(function(player)
    commands:Forget(player.UserId)
    local delta = nations:Remove(player.UserId)
    if delta then network:FireAllClients(delta) end
end)
network.Parent = ReplicatedStorage

local state = Instance.new("Folder")
state.Name = "WorldState"
state:SetAttribute("Version", Config.Version)
state:SetAttribute("MapVersion", Config.Map.Version)
state:SetAttribute("Stage", "NationFounding")
state:SetAttribute("LandCells", map.Grid.LandCount)
state:SetAttribute("Width", map.Grid.Width)
state:SetAttribute("Height", map.Grid.Height)
state:SetAttribute("Ready", true)
state.Parent = ReplicatedStorage

-- Geography and ownership remain separate; economy/expansion are not active yet.
print(string.format("[WorldMap %s] Ready: %d land cells in %.3fs",
    Config.Version, map.Grid.LandCount, os.clock() - started))
