local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local TeleportService = game:GetService("TeleportService")

local Directory = require(script.Parent.World.WorldDirectory)
local occupancy = MemoryStoreService:GetSortedMap("WorldOccupancyV1")
local worldServers = DataStoreService:GetDataStore("WorldServersV1")
local playerHistory = DataStoreService:GetDataStore("WorldHistoryV1")
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
for _, world in ipairs(Directory.Worlds) do valid[world.id] = world end

local function slotKey(worldId, userId)
	return worldId .. ":" .. tostring(userId)
end

local function activeCount(worldId)
	local ok, items = pcall(function()
		return occupancy:GetRangeAsync(Enum.SortDirection.Ascending, 200)
	end)
	if not ok then return 0, false end
	local prefix, count = worldId .. ":", 0
	for _, item in ipairs(items) do
		if string.sub(item.key, 1, #prefix) == prefix then count += 1 end
	end
	return count, true
end

local function reserveSlot(worldId, userId)
	local count, ok = activeCount(worldId)
	if not ok or count >= Directory.MaxPlayers then return false end
	return pcall(function()
		occupancy:SetAsync(slotKey(worldId, userId), os.time(), TTL, os.time())
	end)
end

local function releaseSlot(worldId, userId)
	pcall(function() occupancy:RemoveAsync(slotKey(worldId, userId)) end)
end

local function getWorldServer(worldId)
	local ok, record = pcall(function() return worldServers:GetAsync(worldId) end)
	if ok and type(record) == "table" and type(record.accessCode) == "string" then return record end

	local reserved, accessCode, privateServerId = pcall(function()
		return TeleportService:ReserveServerAsync(game.PlaceId)
	end)
	if not reserved then return nil end

	local saved
	local wrote = pcall(function()
		saved = worldServers:UpdateAsync(worldId, function(existing)
			if type(existing) == "table" and type(existing.accessCode) == "string" then return existing end
			return { accessCode = accessCode, privateServerId = privateServerId }
		end)
	end)
	return wrote and saved or nil
end

local currentWorldId
local function configureArrival(player)
	local joinData = player:GetJoinData()
	local teleportData = joinData and joinData.TeleportData
	if type(teleportData) ~= "table" or not valid[teleportData.worldId] then return end
	currentWorldId = teleportData.worldId
	game:SetAttribute("WorldId", currentWorldId)
	player:SetAttribute("WorldId", currentWorldId)
	reserveSlot(currentWorldId, player.UserId)
end

Players.PlayerAdded:Connect(configureArrival)
for _, player in ipairs(Players:GetPlayers()) do configureArrival(player) end

Players.PlayerRemoving:Connect(function(player)
	if currentWorldId then releaseSlot(currentWorldId, player.UserId) end
end)

getWorlds.OnServerInvoke = function(player)
	local history = {}
	pcall(function()
		history = playerHistory:GetAsync(tostring(player.UserId)) or {}
	end)
	local result = {}
	for _, world in ipairs(Directory.Worlds) do
		local count, available = activeCount(world.id)
		table.insert(result, {
			id = world.id, name = world.name,
			players = math.min(count, Directory.MaxPlayers),
			maxPlayers = Directory.MaxPlayers, available = available,
			lastJoined = type(history) == "table" and history[world.id] or nil,
		})
	end
	return { inWorld = currentWorldId ~= nil, worlds = result }
end

joinWorld.OnServerInvoke = function(player, worldId)
	if currentWorldId then return { ok = false, message = "Você já está em um mundo." } end
	if type(worldId) ~= "string" or not valid[worldId] then
		return { ok = false, message = "Mundo inválido." }
	end
	if not reserveSlot(worldId, player.UserId) then
		return { ok = false, message = "Servidor lotado ou indisponível." }
	end

	pcall(function()
		playerHistory:UpdateAsync(tostring(player.UserId), function(history)
			history = type(history) == "table" and history or {}
			history[worldId] = os.time()
			return history
		end)
	end)

	local server = getWorldServer(worldId)
	if not server then
		releaseSlot(worldId, player.UserId)
		return { ok = false, message = "Não foi possível preparar o mundo." }
	end

	local options = Instance.new("TeleportOptions")
	options.ReservedServerAccessCode = server.accessCode
	options:SetTeleportData({ worldId = worldId })
	local ok = pcall(function()
		TeleportService:TeleportAsync(game.PlaceId, { player }, options)
	end)
	if not ok then
		releaseSlot(worldId, player.UserId)
		return { ok = false, message = "Falha ao entrar. Tente novamente." }
	end
	return { ok = true }
end

task.spawn(function()
	while task.wait(20) do
		if currentWorldId then
			for _, player in ipairs(Players:GetPlayers()) do
				pcall(function()
					occupancy:SetAsync(slotKey(currentWorldId, player.UserId), os.time(), TTL, os.time())
				end)
			end
		end
	end
end)
