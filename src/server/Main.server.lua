local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- Must be set before players are allowed to receive a character.
Players.CharacterAutoLoads = false

local old = workspace:FindFirstChild("PixelWarMap")
if old then old:Destroy() end

local map = Instance.new("Folder")
map.Name = "PixelWarMap"
map.Parent = workspace

local ground = Instance.new("Part")
ground.Name = "TestArena"
ground.Anchored = true
ground.CanCollide = false
ground.Size = Vector3.new(Config.Map.Width * Config.Map.CellSize, Config.Map.CellHeight, Config.Map.Height * Config.Map.CellSize)
ground.Position = Config.Map.Origin
ground.Material = Enum.Material.SmoothPlastic
ground.Color = Color3.fromRGB(229,227,220)
ground.Parent = map

local function setupPlayer(player)
    player:SetAttribute("Troops", Config.Player.StartingTroops)
    if player.Character then player.Character:Destroy() end
    player.CharacterAdded:Connect(function(character)
        character:Destroy()
    end)
end

for _, player in Players:GetPlayers() do setupPlayer(player) end
Players.PlayerAdded:Connect(setupPlayer)
