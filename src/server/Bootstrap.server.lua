local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local MapGrid = require(Shared.MapGrid)
local WorldDefinition = require(Shared.WorldDefinition)
local MapService = require(script.Parent.MapService)
local NationService = require(script.Parent.NationService)
local CommandService = require(script.Parent.CommandService)
local EconomyService = require(script.Parent.EconomyService)
local ExpansionService = require(script.Parent.ExpansionService)
local MatchService = require(script.Parent.MatchService)

-- Strategic map mode does not need characters, physics or a physical cell field.
Players.CharacterAutoLoads = false
local started = os.clock()
local map = MapService.new(MapGrid.new(Config.Map, WorldDefinition))
local economy = EconomyService.new(Config.Economy)
local nations = NationService.new(map, Config.Nations, economy)
local expansion = ExpansionService.new(nations, Config.Expansion, Config.SendPercentages)
local match = MatchService.new(nations, economy, expansion, Config.Tick)
local commands = CommandService.new(nations, Config.Network, nil, expansion)

local network = Instance.new("RemoteEvent")
network.Name = "NationProtocol"
network.OnServerEvent:Connect(function(player, action, cellId, requestId, percentage)
    if player.Parent ~= Players then return end
    -- Client arguments never provide actor identity, name, color or ownership.
    -- Handle/Create do not yield, so two requests cannot reserve the same cell.
    local reply, delta = commands:Handle(player.UserId, player.DisplayName, action, cellId, requestId, percentage)
    if delta then network:FireAllClients(delta) end
    if reply then network:FireClient(player, reply) end
end)
Players.PlayerRemoving:Connect(function(player)
    commands:Forget(player.UserId)
    expansion:Forget(player.UserId)
    local delta = nations:Remove(player.UserId)
    if delta then network:FireAllClients(delta) end
end)
network.Parent = ReplicatedStorage

local state = Instance.new("Folder")
state.Name = "WorldState"
state:SetAttribute("Version", Config.Version)
state:SetAttribute("MapVersion", Config.Map.Version)
state:SetAttribute("Stage", "ExpansionEconomy")
state:SetAttribute("LandCells", map.Grid.LandCount)
state:SetAttribute("Width", map.Grid.Width)
state:SetAttribute("Height", map.Grid.Height)
state:SetAttribute("Ready", true)
state.Parent = ReplicatedStorage

-- A single scheduler for the whole match; only changed state is broadcast.
task.spawn(function()
    local previous = os.clock()
    while true do
        task.wait(Config.Tick.ExpansionInterval)
        local now = os.clock()
        local delta = match:Step(now - previous)
        previous = now
        if delta then network:FireAllClients(delta) end
    end
end)
print(string.format("[WorldMap %s] Ready: %d land cells in %.3fs",
    Config.Version, map.Grid.LandCount, os.clock() - started))
