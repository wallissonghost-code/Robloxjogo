local Workspace = game:GetService("Workspace")

local World = script.Parent:WaitForChild("World")
local TerrainShape = require(World.Terrain)
local Water = require(World.Water)
local Vegetation = require(World.Vegetation)
local Boundary = require(World.Boundary)
local WorldLighting = require(World.Lighting)

local terrain = Workspace.Terrain
terrain:Clear()

TerrainShape.generate(terrain)
Water.generate(terrain)
Vegetation.generate(Workspace)
Boundary.generate(Workspace)

local spawn = Workspace:FindFirstChild("SpawnLocation")
if spawn then
	spawn.CFrame = CFrame.new(0, TerrainShape.heightAt(0, 0) + 4, 0)
end

WorldLighting.apply()
