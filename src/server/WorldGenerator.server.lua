local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

Players.CharacterAutoLoads = false

local World = script.Parent:WaitForChild("World")
local TerrainShape = require(World.Terrain)
local Water = require(World.Water)
local Vegetation = require(World.Vegetation)
local Boundary = require(World.Boundary)
local WorldLighting = require(World.Lighting)
local SafeSpawn = require(World.SafeSpawn)

local terrain = Workspace.Terrain
terrain:Clear()

TerrainShape.generate(terrain)
Water.generate(terrain)
Vegetation.generate(Workspace)
Boundary.generate(Workspace)

local spawn = Workspace:FindFirstChild("SpawnLocation")
local safePosition = SafeSpawn.find(TerrainShape)
if spawn then
	spawn.CFrame = CFrame.new(safePosition)
end
Workspace:SetAttribute("WorldReady", true)

local function spawnPlayer(player)
	if game:GetAttribute("WorldId") == nil then return end
	if player.Character then return end
	player:LoadCharacter()
	local character = player.Character or player.CharacterAdded:Wait()
	character:PivotTo(CFrame.new(safePosition + Vector3.new(0, 3, 0)))
end

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(spawnPlayer, player)
end
Players.PlayerAdded:Connect(function(player)
	task.defer(spawnPlayer, player)
end)

WorldLighting.apply()
