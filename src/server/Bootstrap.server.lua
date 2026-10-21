local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local MapGrid = require(Shared.MapGrid)
local WorldDefinition = require(Shared.WorldDefinition)
local MapService = require(script.Parent.MapService)

-- Strategic map mode does not need characters, physics or a physical cell field.
Players.CharacterAutoLoads = false
local started = os.clock()
local map = MapService.new(MapGrid.new(Config.Map, WorldDefinition))

local state = Instance.new("Folder")
state.Name = "WorldState"
state:SetAttribute("Version", Config.Version)
state:SetAttribute("MapVersion", Config.Map.Version)
state:SetAttribute("Stage", "MapFoundation")
state:SetAttribute("LandCells", map.Grid.LandCount)
state:SetAttribute("Width", map.Grid.Width)
state:SetAttribute("Height", map.Grid.Height)
state:SetAttribute("Ready", true)
state.Parent = ReplicatedStorage

-- Stage 1 exposes metadata only. No client can mutate geography or ownership.
-- NationService and the authoritative command gateway are the next stage.
print(string.format("[WorldMap %s] Ready: %d land cells in %.3fs",
    Config.Version, map.Grid.LandCount, os.clock() - started))
