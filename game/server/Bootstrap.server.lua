local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

Players.CharacterAutoLoads = false

local Config = require(ReplicatedStorage:WaitForChild("WarShared"):WaitForChild("Config"))
local MapService = require(script.Parent:WaitForChild("MapService"))
local NationService = require(script.Parent:WaitForChild("NationService"))
local TerritoryService = require(script.Parent:WaitForChild("TerritoryService"))
local BotService = require(script.Parent:WaitForChild("BotService"))

local oldRemotes = ReplicatedStorage:FindFirstChild("WarRemotes")
if oldRemotes then
	oldRemotes:Destroy()
end

local remotes = Instance.new("Folder")
remotes.Name = "WarRemotes"
remotes.Parent = ReplicatedStorage

local commandRemote = Instance.new("RemoteEvent")
commandRemote.Name = "Command"
commandRemote.Parent = remotes

local stateRemote = Instance.new("RemoteEvent")
stateRemote.Name = "State"
stateRemote.Parent = remotes

MapService.Init(Config)
NationService.Init(Config, MapService)
TerritoryService.Init(Config, MapService, NationService, stateRemote)
BotService.Init(Config, MapService, NationService, TerritoryService)

local lastCommand = {}

local function setupPlayer(player)
	local state = NationService.CreateForPlayer(player)
	stateRemote:FireClient(player, {
		type = "Notice",
		text = "Escolha qualquer área neutra do mapa para posicionar sua capital.",
		kind = "Info",
	})
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

Players.PlayerRemoving:Connect(function(player)
	lastCommand[player] = nil
	NationService.RemovePlayer(player)
end)

commandRemote.OnServerEvent:Connect(function(player, action, a, b, c)
	local now = os.clock()
	if action ~= "SetPercent" then
		local previous = lastCommand[player] or 0
		if now - previous < 0.075 then
			return
		end
		lastCommand[player] = now
	end

	local state = NationService.GetForPlayer(player)
	if not state then
		return
	end

	if action == "SetPercent" then
		NationService.SetSelectedPercent(state, a)
		return
	end

	local cell = MapService.GetCell(a, b)
	if not cell then
		return
	end

	if action == "ClaimOrAct" then
		TerritoryService.Act(state, cell)
	elseif action == "Build" and type(c) == "string" then
		TerritoryService.Build(state, cell, c)
	end
end)

local accumulator = 0
RunService.Heartbeat:Connect(function(dt)
	accumulator += dt
	if accumulator >= 1 then
		local step = accumulator
		accumulator = 0
		NationService.Step(step)
	end
end)

BotService.Start()

print("[WorldWarPixel] V1 inicializada: mapa, território, economia, combate, construções e bots.")
