local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = false

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local TroopService = require(script.Parent:WaitForChild("TroopService"))
local TerritoryService = require(script.Parent:WaitForChild("TerritoryService"))
local Remotes = require(script.Parent:WaitForChild("Remotes"))

TroopService.Init(Config)
TerritoryService.Init(Config, TroopService)
Remotes.Init()
TerritoryService.BuildMap()
TroopService.Start()

local function setupPlayer(player)
    TroopService.SetupPlayer(player)
    if player.Character then player.Character:Destroy() end
    player.CharacterAdded:Connect(function(character)
        character:Destroy()
    end)

    player:GetAttributeChangedSignal("Troops"):Connect(function()
        TerritoryService.RefreshTroops(player)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(TerritoryService.RemovePlayer)

Remotes.MapCommand.OnServerEvent:Connect(function(player, cellPart, sendPercent)\n    TerritoryService.ExpandToward(player, cellPart, sendPercent)\nend)
