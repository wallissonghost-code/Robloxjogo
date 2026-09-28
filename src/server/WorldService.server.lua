local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MemoryStoreService = game:GetService("MemoryStoreService")
local TeleportService = game:GetService("TeleportService")

local Directory = require(script.Parent.World.WorldDirectory)
local occupancy = MemoryStoreService:GetSortedMap("WorldOccupancyV1")
local TTL = 75

local remotes = Instance.new("Folder")
remotes.Name = "WorldRemotes"
remotes.Parent = ReplicatedStorage

local getWorlds = Instance.new("RemoteFunction")
getWorlds.Name = "GetWorlds"
getWorlds.Parent = remotes

local joinWorld = Instance.new("RemoteFunction")
joinWorld.Name = "JoinWorld"
joinWorld.Parent = remotes

local valid = {}
for _, world in ipairs(Directory.Worlds) do
	valid[world.id] = world
end

local function key(worldId, userId)
	return worldId .. ":" .. tostring(userId)
end

local function activeCount(worldId)
	local ok, items = pcall(function()
		return occupancy:GetRangeAsync(Enum.SortDirection.Ascending, 200)
	end)
	if not ok then return 0, false end
	local prefix = worldId .. ":"
	local count = 0
	for _, item in ipairs(items) do
		if string.sub(item.key, 1, #prefix) == prefix then count += 1 end
	end
	return count, true
end

local function reserve(worldId, userId)
	local count, ok = activeCount(worldId)
	if not ok or count >= Directory.MaxPlayers then return false end
	local wrote = pcall(function()
		occupancy:SetAsync(key(worldId, userId), os.time(), TTL, os.time())
	end)
	return wrote
end

local function release(worldId, userId)
	pcall(function() occupancy:RemoveAsync(key(worldId, userId)) end)
end

local currentWorldId = game.PrivateServerId ~= "" and game:GetAttribute("WorldId") or nil

getWorlds.OnServerInvoke = function()
	local result = {}
	for _, world in ipairs(Directory.Worlds) do
		local count, available = activeCount(world.id)
		table.insert(result, {
			id = world.id,
			name = world.name,
			players = math.min(count, Directory.MaxPlayers),
			maxPlayers = Directory.MaxPlayers,
			available = available,
		})
	end
	return { inWorld = currentWorldId ~= nil, worlds = result }
end

joinWorld.OnServerInvoke = function(player, worldId)
	if currentWorldId then return { ok = false, message = "Você já está em um mundo." } end
	if type(worldId) ~= "string" or not valid[worldId] then
		return { ok = false, message = "Mundo inválido." }
	end
	if not reserve(worldId, player.UserId) then
		return { ok = false, message = "Servidor lotado ou indisponível." }
	end

	local options = Instance.new("TeleportOptions")
	options.ShouldReserveServer = true
	options:SetTeleportData({ worldId = worldId })
	local ok = pcall(function()
		TeleportService:TeleportAsync(game.PlaceId, { player }, options)
	end)
	if not ok then
		release(worldId, player.UserId)
		return { ok = false, message = "Falha ao entrar. Tente novamente." }
	end
	return { ok = true }
end

local joinData = Players.LocalPlayer == nil and nil
Players.PlayerAdded:Connect(function(player)
	local data = player:GetJoinData()
	local teleportData = data and data.TeleportData
	if type(teleportData) == "table" and valid[teleportData.worldId] then
		currentWorldId = teleportData.worldId
		game:SetAttribute("WorldId", currentWorldId)
		player:SetAttribute("WorldId", currentWorldId)
		reserve(currentWorldId, player.UserId)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if currentWorldId then release(currentWorldId, player.UserId) end
end)

task.spawn(function()
	while task.wait(20) do
		if currentWorldId then
			for _, player in ipairs(Players:GetPlayers()) do
				occupancy:SetAsync(key(currentWorldId, player.UserId), os.time(), TTL, os.time())
			end
		end
	end
end)
