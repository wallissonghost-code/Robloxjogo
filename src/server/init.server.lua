-- Mundial War · server bootstrap. Builds the world from the modules and drives it from Heartbeat.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("MundialWarShared")
local Config = require(Shared.GameConfig)

Players.CharacterAutoLoads = false   -- the nation is the character; no avatar walks on the map

-- A published public instance hosts the lobby; a reserved server of this same
-- PlaceId hosts an independent match. VIP servers start in the lobby as well.
local reservedMatch = game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
local hasLobby = Config.Lobby and Config.Lobby.Enabled
local isLobby = hasLobby and not reservedMatch
ReplicatedStorage:SetAttribute("MW_SessionType", isLobby and "lobby" or "match")
if isLobby then
    require(script.LobbyService).start(Config)
    return
end

-- Reserved matches start directly in the mode chosen in the lobby.
if hasLobby and reservedMatch then
    Config.Match.VoteSeconds = 0
end

local World = require(script.World)
local NetworkService = require(script.NetworkService)

local world = World.new({
	Config = Config,
	MapData = require(Shared.MapData),
	MapGrid = require(Shared.MapGrid),
	BuildingStats = require(Shared.BuildingStats),
	Palette = require(Shared.Palette),
	Protocol = require(Shared.Protocol),
	random = math.random,
	Services = {
		Territory = require(script.TerritoryService),
		Nations = require(script.NationService),
		Economy = require(script.EconomyService),
		Combat = require(script.CombatService),
		Buildings = require(script.BuildingService),
		Expansion = require(script.ExpansionService),
		Naval = require(script.NavalService),
		Strategic = require(script.StrategicService),
		Diplomacy = require(script.DiplomacyService),
		Bots = require(script.BotService),
		Match = require(script.MatchService),
		Commands = require(script.CommandService),
	},
})

-- The first arriving player's trusted same-experience TeleportData chooses
-- the match mode before the simulation is allowed to start.
local modeReady = not (hasLobby and reservedMatch)
world.ctx.partyOfUser = {}
world.ctx.lobbyMatch = hasLobby and reservedMatch
local function acceptMatchArrival(player)
    if not (hasLobby and reservedMatch) then return end
    local ok, join = pcall(function() return player:GetJoinData() end)
    local data = ok and join and join.TeleportData
    if type(data) == "table" and data.mwSession == "match"
        and ok and join.SourcePlaceId == game.PlaceId then
        if not modeReady and Config.Modes[data.mode] then
            world.ctx.Match.setMode(data.mode)
        end
        local party = data.partyUserIds
        local id = data.partyId
        if type(id) == "string" and #id <= 100 and type(party) == "table" and #party <= 2 then
            for _, userId in ipairs(party) do
                if type(userId) == "number" and userId > 0 then
                    world.ctx.partyOfUser[userId] = id
                end
            end
        end
    end
    modeReady = true
end
Players.PlayerAdded:Connect(acceptMatchArrival)
for _, player in ipairs(Players:GetPlayers()) do acceptMatchArrival(player) end

world.ctx.connectedPlayers = function()
	local result = {}
	for _, player in ipairs(Players:GetPlayers()) do
		result[#result + 1] = { userId = player.UserId, name = player.DisplayName }
	end
	return result
end

NetworkService.start(world)

-- Tell clients whether image APIs are allowed here (the image map mode needs them).
task.spawn(function()
	local ok, probe = pcall(function()
		return game:GetService("AssetService"):CreateEditableImage({ Size = Vector2.new(4, 4) })
	end)
	ReplicatedStorage:SetAttribute("MW_ImageApis", ok and probe ~= nil)
	if ok and probe then pcall(function() probe:Destroy() end) end
end)

local failures = 0
RunService.Heartbeat:Connect(function(dt)
	dt = math.min(dt, 0.25)   -- a long server hitch must not fast-forward the whole match
	local ok, err = pcall(function()
		if modeReady then world:step(dt, #Players:GetPlayers(), os.clock) end
		NetworkService.flush(dt)
	end)
	if not ok then
		failures = failures + 1
		if failures <= 20 or failures % 100 == 0 then
			warn("[MundialWar] simulation error #" .. failures .. ": " .. tostring(err))
		end
	end
end)

if Config.DEBUG_MODE then
	task.spawn(function()
		while true do
			task.wait(10)
			local s = world.stats
			if s.simCount > 0 then
				print(string.format("[MundialWar] avg step %.2f ms, worst %.2f ms", s.simTime / s.simCount * 1000, s.worst * 1000))
				s.simTime, s.simCount, s.worst = 0, 0, 0
			end
		end
	end)
end
